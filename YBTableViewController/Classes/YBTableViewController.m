//
//  YBTableViewController.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/23/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableViewController.h"
#import "YBTableViewController+Private.h"
#import "YBTableViewHeaderFooterView.h"
#import "YBTableViewHeaderFooterView+Private.h"
#import "YBAnimationUtilities.h"
#import "YBTableViewMovingSectionHeaderState.h"
#import "YBTableView.h"

/// Limits a number between a lower and upper bound.
#define LIMIT(A, L, U)  ({ __typeof__(A) __a = (A); __typeof__(L) __l = (L); __typeof__(U) __u = (U); (__a < __l ? __l : (__a > __u ? __u : __a)); })

/// Auto scroll rate should be betwee [0..1]
#define MIN_AUTO_SCROLL_RATE                        0.
#define MAX_AUTO_SCROLL_RATE                        1.

/// At a scroll rate of 1, we should only move the table view by 10 points
#define MAX_AUTO_SCROLL_OFFSET                      10

/// The table view's scroll position should be reevulated at every frame
#define AUTO_SCROLL_INTERVAL                        (1. / 60.)

// The following durations were selected after analyzing QuickTime recordings of what the
// operating system does. The numerator expresses the number of actual frames the animation
// lasted
#define REORDER_TAP_AND_HOLD_GESTURE_DURATION       (10. / 60.)
#define SNAP_DRAGGING_ROW_BACK_ANIMATION_DURATION   (21. / 60.)

#pragma mark -

@interface YBTableViewController () <UITableViewDelegate, UIGestureRecognizerDelegate>

// Redeclared for private access
@property (nonatomic, strong) YBTableView *tableView;

/// The current state of the moving section header. Originally all of these properties
/// were here but it started to become too much to manage here.
@property (nonatomic, strong) YBTableViewMovingSectionHeaderState *movingSectionHeaderState;

/// The rate at which we scroll the table view
@property (nonatomic) CGFloat autoScrollRate;

/// The timer that reevaluates the table view's offset. This is nonnull only when the
/// snapshot view is near the top or bottom and scrolling is possible.
@property (nonatomic) NSTimer *autoScrollTimer;

@end

#pragma mark -

@implementation YBTableViewController

#pragma mark - Properties

- (BOOL)isMovingSectionHeader {
    return self.movingSectionHeaderState != nil;
}

#pragma mark - UIViewController Override

- (UITableView *)tableView {
    if (!self.isViewLoaded) {
        [self loadViewIfNeeded];
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup our secret sauce so we can hijack the table view's delegate and data source -- this is what lets us
    // do our magic
    YBTableView *tableView = [[YBTableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.viewController = self;
    tableView.sectionHeaderHeight = 48;

    // Setup a gesture recognizer so that we can detect a long press on the section header's grabber icon
    UILongPressGestureRecognizer *tapAndHoldRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(sectionReorderGesture:)];
    tapAndHoldRecognizer.delegate = self;
    tapAndHoldRecognizer.numberOfTapsRequired = 0;
    tapAndHoldRecognizer.minimumPressDuration = REORDER_TAP_AND_HOLD_GESTURE_DURATION;
    [tableView addGestureRecognizer:tapAndHoldRecognizer];
    
    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (self.isEditing != editing) {
        // We want to atomically animate the table view's rows and header views showing
        // their editing & reorder controls
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];

        [super setEditing:editing animated:animated];
        [self.tableView setEditing:editing animated:animated];
        [self setEditingForVisibleSectionHeaderViews:editing animated:animated];
        [UIView commitAnimations];
    }
}

#pragma mark - UIGestureRecognizerDelegate 

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (!self.isEditing) {
        // Return if we're not currently editing
        return NO;
    }

    // The following code attempts to determine if the touch was over a header
    // view's grabber icon.
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    NSUInteger section = [self headerViewForSectionWithPoint:point];
    if (section == NSNotFound) {
        // The point is not for a header view, lets get out of here
        return NO;
    }
    
    YBTableViewHeaderFooterView *headerView = (YBTableViewHeaderFooterView *)[self.tableView headerViewForSection:section];
    if (![headerView isKindOfClass:[YBTableViewHeaderFooterView class]]) {
        // The header view under the point is not a subclass of `YBTableViewHeaderFooterView`
        // there isn't much we can do, so lets return early
        return NO;
    }
    
    if (!headerView.showGrabber) {
        // Return early if the header view is not showing a grabber
        return NO;
    }
    
    // There has to be a better way of doing this, but I didn't have an elegant solution.
    // Basically we're checking to see if the point lies within the grabber view's
    // frame. Ideally, I'd point a method on `YBTableViewHeaderFootView` that queries
    // itself if the point is in the grabber view instead of exposing the grabber view.
    CGPoint pointInGrabberView = [headerView.grabberView convertPoint:point fromView:self.tableView];
    if (CGRectContainsPoint(headerView.grabberView.bounds, pointInGrabberView)) {
        return YES;
    }
    
    return NO;
}

- (void)sectionReorderGesture:(UIGestureRecognizer *)recognizer {
    UIGestureRecognizerState state = recognizer.state;
    CGPoint point = [recognizer locationInView:self.tableView];
    switch (state) {
        case UIGestureRecognizerStatePossible:
            // Nothing to do, this is the default state of the recognizer and we should
            // never get here
            break;
            
        case UIGestureRecognizerStateBegan:
            // The recognizer has started, lets capture which of the section headers will be
            // moving
            [self willStartMovingSectionHeaderAtPoint:point];
            break;

        case UIGestureRecognizerStateChanged:
            // The user has moved their finger
            [self didMoveSectionHeaderToPoint:point];
            break;
            
        case UIGestureRecognizerStateCancelled:
            // The user has moved their finger off screen or the table view has been removed from the hiearchy
            [self didEndMovingSectionHeader];
            break;
            
        case UIGestureRecognizerStateEnded:
            // The user has lifted their finger from the screen
            [self didEndMovingSectionHeader];
            break;
            
        case UIGestureRecognizerStateFailed:
            // I'm not sure what conditions would make use fall through to here
            break;
    }
}

#pragma mark - Private Methods

/// Called by the `YBTableViewDelegateProxy` when a header view is about to be displayed
/// this is where we can dittle the header view's properties to show the edit and gropper
/// icons.
- (void)willDisplayHeaderView:(YBTableViewHeaderFooterView *)view forSection:(NSInteger)section {
    [self configureHeaderViewEditAndGrabberState:view forSection:section animated:NO];
}

#pragma mark - Moving Section Headers Around

/// Called when the section  will start moving
- (void)willStartMovingSectionHeaderAtPoint:(CGPoint)point {
    // Lets create an instance of `YBTableViewMovingSectionHeaderState` to help us keep track of the
    // section header that is moving
    NSInteger sourceIndex = [self headerViewForSectionWithPoint:point];
    UIView *headerView = [self.tableView headerViewForSection:sourceIndex];;
    
    // The snapshot will be added to the receiver's view (isntead of the tableView), this is so that
    // the snahsot header view floats above the table view, so we need to make sure we use the
    // receiver's view's coordinate space
    CGPoint pointInView = [self.view convertPoint:point fromView:self.tableView];
    CGRect initialSnapShotFrame = [self.view convertRect:headerView.bounds fromView:headerView];
    
    self.movingSectionHeaderState = [[YBTableViewMovingSectionHeaderState alloc] initWithView:headerView
                                                                                  sourceIndex:sourceIndex
                                                                                originalPoint:pointInView
                                                                         initialSnapShotFrame:initialSnapShotFrame];
    headerView.hidden = YES;
    [self.view addSubview:self.movingSectionHeaderState.snapShotView];
    
    // Collapse all fo the sections
    NSArray *indexPaths = [self indexPathsForAllRows];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];

    // Scroll the table view to something more reasonable
    CGRect sectionRect = [self.tableView rectForSection:self.movingSectionHeaderState.proposedDestinationIndex];
    CGPoint newOffset = self.tableView.contentOffset;

    CGFloat contentOffsetMinY = -self.tableView.contentInset.top;
    CGFloat contentOffsetMaxY = self.tableView.contentSize.height - CGRectGetHeight(self.tableView.bounds);

    // Lets modify the offset so that the snapshot view (which is hovering over the table view) visually
    // attempts to be the same spot that we started the reorder from
    CGFloat offsetY = CGRectGetMinY(initialSnapShotFrame) - CGRectGetMinY(self.tableView.frame);
    newOffset.y = CGRectGetMinY(sectionRect) - offsetY;
    if (newOffset.y < contentOffsetMinY) {
        // We can't set the offset above the first row
        newOffset.y = contentOffsetMinY;
    }
    else if (newOffset.y > contentOffsetMaxY) {
        // We can't set the offset beyond the last row
        newOffset.y = contentOffsetMaxY;
    }
    
    // Wrapping the the setter for the content offset with `-beginUpdates` and `-endUpdates` ensures that
    // the table view's metrics are updated by the time we try to calculate the porposed destination index
    [self.tableView beginUpdates];
    self.tableView.contentOffset = newOffset;
    [self.tableView endUpdates];
    
    // The rows have collapsed and its possible for the floating header to be below the last section
    // lets make sure we update the propsed destination index to reflect this fact
    [self updateProposedDestinationIndex];
}

/// Called when the section has moved
- (void)didMoveSectionHeaderToPoint:(CGPoint)point {
    // Inform the section header that its moved (within the receiver's view's coordinate space)
    CGPoint pointInView = [self.view convertPoint:point fromView:self.tableView];
    [self.movingSectionHeaderState moveToPoint:pointInView];

    // Auto scroll the table view, if it's needed
    [self updateAutoScrollRateAndStartTimerIfNeeded];
    
    // Update the proposed destination index based on the specified point
    [self updateProposedDestinationIndex];
}

/// Called when the section finished moving
- (void)didEndMovingSectionHeader {
    [self stopAutoScrollTimerIfNeeded];
    
    // Lets snap the snap shot view to its final resting place
    NSInteger proposedDestinationIndex = self.movingSectionHeaderState.proposedDestinationIndex;
    CGRect headerRect = [self.view convertRect:[self.tableView rectForHeaderInSection:proposedDestinationIndex] fromView:self.tableView];
    [self dataSourceMoveHeaderFromSection:self.movingSectionHeaderState.sourceIndex toSection:proposedDestinationIndex];
    [UIView animateWithDuration:SNAP_DRAGGING_ROW_BACK_ANIMATION_DURATION animations:^{
        // Do the animation
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        self.movingSectionHeaderState.snapShotView.frame = headerRect;
    } completion:^(BOOL finished) {
        // Restore the section's visibility
        UIView *headerView = [self.tableView headerViewForSection:proposedDestinationIndex];
        headerView.hidden = NO;
        
        // Invalidate the state
        [self.movingSectionHeaderState invalidate];
        self.movingSectionHeaderState = nil;
        
        // Expand all of the sections
        NSArray *indexPaths = [self indexPathsForAllRows];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        [self.tableView endUpdates];

        // Scroll the table view to something reasonable
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:proposedDestinationIndex]
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
    }];
}

#pragma mark - Auto Scrolling

/// Starts the auto scroll timer if its needed
- (void)startAutoScrollTimerIfNeeded {
    if (self.autoScrollTimer) {
        return;
    }
 
    // Update the scroll view 60x per second
    self.autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_INTERVAL
                                                            target:self
                                                          selector:@selector(autoScrollTimerDidFire:)
                                                          userInfo:nil
                                                           repeats:YES];
}

/// Stops / invalidates the auto scroll timer if its been created
- (void)stopAutoScrollTimerIfNeeded {
    if (!self.autoScrollTimer) {
        return;
    }
    
    self.autoScrollRate = 0.0;
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
}

/// Returns an auto scroll rate between -1..1, where 0 is no scroll and 1 is max scroll.
- (CGFloat)autoScrollRate {
    UIEdgeInsets contentInset = self.tableView.contentInset;
    CGPoint contentOffset = self.tableView.contentOffset;
    
    CGFloat scrollZoneHeight = 6;
    CGRect rect = CGRectInset(UIEdgeInsetsInsetRect(self.tableView.frame, contentInset), 0, scrollZoneHeight);
    CGRect snapShotRect = self.movingSectionHeaderState.snapShotView.frame;

    if (CGRectContainsRect(rect, snapShotRect)) {
        // The snapshot is fully enclosed by the table view's bounds (excluding the "auto scroll" zones
        return 0;
    }
    
    CGFloat rectMidY = CGRectGetMidY(rect);
    if (CGRectGetMinY(snapShotRect) < rectMidY) {
        // If snap shot is near the top, lets scroll upwards
        CGFloat contentOffsetMinY = -contentInset.top;
        if (contentOffset.y == contentOffsetMinY) {
            // We're already at the top, we can't go any further
            return 0;
        }

        return -LIMIT((CGRectGetMinY(rect) - CGRectGetMinY(snapShotRect)) / scrollZoneHeight, MIN_AUTO_SCROLL_RATE, MAX_AUTO_SCROLL_RATE);
    }
    
    CGFloat contentOffsetMaxY = self.tableView.contentSize.height - CGRectGetHeight(self.tableView.bounds);
    if (contentOffset.y == contentOffsetMaxY) {
        // We're already at the bottom, we can't go any further
        return 0;
    }

    return LIMIT((CGRectGetMaxY(snapShotRect) - CGRectGetMaxY(rect)) / scrollZoneHeight, MIN_AUTO_SCROLL_RATE, MAX_AUTO_SCROLL_RATE);
}

/// Triggered by the auto scroll timer, used to update the table view's scroll position, update the proposed destination
// index and evaluate if the the imer should be stopped.
- (void)autoScrollTimerDidFire:(NSTimer *)timer {
    CGPoint currentOffset = self.tableView.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.autoScrollRate * MAX_AUTO_SCROLL_OFFSET);
    CGFloat contentOffsetMinY = -self.tableView.contentInset.top;
    CGFloat contentOffsetMaxY = self.tableView.contentSize.height - CGRectGetHeight(self.tableView.bounds);
    
    if (self.autoScrollRate < 0 && newOffset.y <= contentOffsetMinY) {
        // We've reached the top
        newOffset.y = contentOffsetMinY;
        [self stopAutoScrollTimerIfNeeded];
    }
    else if (self.autoScrollRate > 0 && newOffset.y >= contentOffsetMaxY) {
        // We've reached the bottom
        newOffset.y = contentOffsetMaxY;
        [self stopAutoScrollTimerIfNeeded];
    }
    
    self.tableView.contentOffset = newOffset;
    [self updateProposedDestinationIndex];
}

/// Evaluates whether the table view can be scrolled and if we need to start the auto scroll timer
- (void)updateAutoScrollRateAndStartTimerIfNeeded {
    if (self.tableView.contentSize.height <= CGRectGetHeight(self.tableView.bounds)) {
        // The content of the table view fits perfectly within the view's bounds. Nothing to do
        return;
    }
    
    self.autoScrollRate = [self autoScrollRate];
    if (self.autoScrollRate == 0) {
        // We're already at the top or bottom and no more scrolling is necessary, lets get out of here.
        [self stopAutoScrollTimerIfNeeded];
        return;
    }
    
    [self startAutoScrollTimerIfNeeded];
}

#pragma mark - Helper

/// Return the section index for the specified point, point is in the table view's coordinate space.
- (NSInteger)headerViewForSectionWithPoint:(CGPoint)point {
    NSInteger numberOfSections = self.tableView.numberOfSections;
    if (numberOfSections == 0) {
        // There are no sections
        return -1;
    }
    
    // Lets first check all of the visible sections
    NSSet<NSNumber *> *visibleSections = [NSSet setWithArray:[self.tableView.indexPathsForVisibleRows valueForKeyPath:@"@distinctUnionOfObjects.section"]];;
    if (visibleSections) {
        // We probably want one of the visible sections, lets see if thats it
        for (NSNumber *section in visibleSections) {
            UITableViewHeaderFooterView *view = [self.tableView headerViewForSection:section.integerValue];
            if (CGRectContainsPoint(view.frame, point)) {
                return section.integerValue;
            }
        }
    }
    
    // First check to see if the point falls in the first or last sections, or above or below them respectively
    CGRect firstRect = [self.tableView rectForHeaderInSection:0];
    CGRect lastRect = [self.tableView rectForHeaderInSection:numberOfSections - 1];
    if (CGRectContainsPoint(firstRect, point)) {
        // The point intersects the first section
        return 0;
    }
    
    if (CGRectContainsPoint(lastRect, point)) {
        // The point intersects the last section
        return numberOfSections - 1;
    }
    
    if (point.y < CGRectGetMinY(firstRect)) {
        // The point falls above the first section
        return -1;
    }
    
    if (point.y > CGRectGetMinY(lastRect)) {
        // The point falls below the last section
        return numberOfSections;
    }
    
    // Perform a binary search of the point in question
    NSInteger minIndex = 1;                     // We already checked the first section
    NSInteger maxIndex = numberOfSections - 2;  // We already checked the last section
    while (maxIndex >= minIndex) {
        NSInteger midIndex = minIndex + ((maxIndex - minIndex) / 2);
        CGRect rect = [self.tableView rectForHeaderInSection:midIndex];
        if (CGRectContainsPoint(rect, point)) {
            return midIndex;
        }
        else if (point.y < CGRectGetMinY(rect)) {
            maxIndex = midIndex - 1;
        }
        else {
            minIndex = midIndex + 1;
        }
    }
    
    // We should never get here, but in case we do, return an index past the end
    return numberOfSections;
}

/// Returns an adjusted section index, if we're in the middle of a moving a section header
- (NSInteger)adjustedSectionForSection:(NSInteger)section {
    if (self.isMovingSectionHeader) {
        // We're not in the middle of a move operation, there is nothing to adjust
        return section;
    }
    
    if (self.movingSectionHeaderState.sourceIndex == self.movingSectionHeaderState.proposedDestinationIndex) {
        // The source and destination are the same, there is nothing to adjust
        return section;
    }
    
    if (section == self.movingSectionHeaderState.proposedDestinationIndex) {
        // If the section we want is where the destination index is, thats actually where we want the
        // source section to move to -- therefore, the data for this section is actually the source section
        return self.movingSectionHeaderState.sourceIndex;
    }
    
    // Identify which indexes actually need to be adjusted
    NSRange affectedIndexes;
    if (self.movingSectionHeaderState.sourceIndex < self.movingSectionHeaderState.proposedDestinationIndex) {
        affectedIndexes = NSMakeRange(self.movingSectionHeaderState.sourceIndex, self.movingSectionHeaderState.proposedDestinationIndex - self.movingSectionHeaderState.sourceIndex + 1);
    }
    else {
        affectedIndexes = NSMakeRange(self.movingSectionHeaderState.proposedDestinationIndex, self.movingSectionHeaderState.sourceIndex - self.movingSectionHeaderState.proposedDestinationIndex + 1);
    }
    
    if (!NSLocationInRange(section, affectedIndexes)) {
        // Any sections that are not in the affected range do not need to be adjusted
        return section;
    }
    
    if (self.movingSectionHeaderState.proposedDestinationIndex < self.movingSectionHeaderState.sourceIndex) {
        // If the destination is before the source, the table view actually wants the data for the previous row
        return section - 1;
    }
    
    // If the destination is after the source, the table view actually wants the data for the next row
    return section + 1;
}

/// Updates the propsed destination index and placeholder position based on the specified point
- (void)updateProposedDestinationIndex {
    NSInteger numberOfSections = self.tableView.numberOfSections;
    CGRect snapShotRect = [self.tableView convertRect:self.movingSectionHeaderState.snapShotView.frame fromView:self.view];
    CGPoint point = CGPointMake(CGRectGetMinX(snapShotRect), CGRectGetMidY(snapShotRect));
    NSInteger newSectionIndex = [self delegateTargetSectionForMoveFromHeaderInSection:self.movingSectionHeaderState.sourceIndex
                                                          toProposedSection:LIMIT([self headerViewForSectionWithPoint:point], 0, numberOfSections - 1)];
    if (newSectionIndex == self.movingSectionHeaderState.proposedDestinationIndex) {
        // Return early if the point is still within the destination section
        return;
    }

    // Shift the placeholder section around so we can show a gap, this gap signals the user that
    // this is where the section header would drop if they were to let go
    [self.tableView beginUpdates];
    [self.tableView moveSection:self.movingSectionHeaderState.proposedDestinationIndex toSection:newSectionIndex];
    [self.tableView endUpdates];
    
    self.movingSectionHeaderState.proposedDestinationIndex = newSectionIndex;
}

/// Updates all of the visible section header views to the specified editing state
- (void)setEditingForVisibleSectionHeaderViews:(BOOL)editing animated:(BOOL)animated {
    NSIndexSet *visibleSections = [self indexesOfVisibleSections];
    [visibleSections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
        YBTableViewHeaderFooterView *header = (YBTableViewHeaderFooterView *)[self.tableView headerViewForSection:section];
        [self configureHeaderViewEditAndGrabberState:header forSection:section animated:animated];
    }];
}

/// Returns an `NSIndexSet` of all the visible sections
- (NSIndexSet *)indexesOfVisibleSections {
    NSInteger numberOfSections = self.tableView.numberOfSections;
    if (numberOfSections == 0) {
        // There are no sections, return an empty set
        return [NSIndexSet indexSet];
    }
    
    CGRect visibleRect = self.tableView.bounds;
    NSInteger firstPossibleSection = [[self.tableView.indexPathsForVisibleRows firstObject] section];
    NSInteger lastPossibleSection = [[self.tableView.indexPathsForVisibleRows lastObject] section];
    
    // It is possible that the first visible section is not reported by `-indexPathsForVisibleRows`
    // so lets take the first reported section and look backwards for a section that is no longer
    // visible
    NSInteger firstIndex = NSNotFound;
    for (NSInteger section = firstPossibleSection; section >= 0; section--) {
        UIView *headerView = [self.tableView headerViewForSection:section];
        CGRect sectionRect = CGRectZero;
        if (headerView) {
            sectionRect = headerView.frame;
        }
        else {
            sectionRect = [self.tableView rectForHeaderInSection:section];
        }
        
        if (CGRectIntersectsRect(sectionRect, visibleRect)) {
            if (CGRectGetHeight(sectionRect) != 0) {
                firstIndex = section;
            }
        }
        else {
            break;
        }
    }

    if (firstIndex == NSNotFound) {
        for (NSInteger section = firstPossibleSection + 1; section < numberOfSections; section++) {
            UIView *headerView = [self.tableView headerViewForSection:section];
            CGRect sectionRect = CGRectZero;
            if (headerView) {
                sectionRect = headerView.frame;
            }
            else {
                sectionRect = [self.tableView rectForHeaderInSection:section];
            }
            
            if (CGRectIntersectsRect(sectionRect, visibleRect)) {
                if (CGRectGetHeight(sectionRect) != 0) {
                    firstIndex = section;
                    if (lastPossibleSection < firstIndex) {
                        lastPossibleSection = firstIndex;
                    }
                    break;
                }
            }
        }
    }
    
    if (firstIndex == NSNotFound) {
        return [NSIndexSet new];
    }
    
    // It is possible that the last visible section is not reported by `-indexPathsForVisibleRows`
    // so lets take the last reported section and look forwards for a section that is no longer
    // visible
    NSInteger lastIndex = firstIndex;
    for (NSInteger section = lastPossibleSection; section < numberOfSections; section++) {
        UIView *headerView = [self.tableView headerViewForSection:section];
        CGRect sectionRect = CGRectZero;
        if (headerView) {
            sectionRect = headerView.frame;
        }
        else {
            sectionRect = [self.tableView rectForHeaderInSection:section];
        }
        
        if (CGRectIntersectsRect(sectionRect, visibleRect)) {
            if (CGRectGetHeight(sectionRect) != 0) {
                lastIndex = section;
            }
        }
        else {
            break;
        }
    }
    
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstIndex, lastIndex - firstIndex + 1)];
}

/// Returns an array of `NSIndexPath` of all of the rows for each category, this is done by querying
/// the data source directly for this information
- (NSArray<NSIndexPath *> *)indexPathsForAllRows {
    NSMutableArray *indexPaths = [NSMutableArray new];
    NSUInteger numberOfSections = self.tableView.numberOfSections;
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSUInteger numberOfRowsInSection = [self numberOfRowsInSection:section];
        for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    
    return [indexPaths copy];
}

/// Queries the actual data source for the number of rows, if we're in the middle of a move operation we
/// don't want to query the proxy as it will return 0, instead, we want to query the actual data source.
- (NSUInteger)numberOfRowsInSection:(NSUInteger)section {
    YBTableViewDataSourceProxy *dataSourceProxy = self.tableView.dataSource;
    id<UITableViewDataSource> dataSource = dataSourceProxy.dataSource;

    if ([dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        return [dataSource tableView:self.tableView numberOfRowsInSection:section];
    }
    else {
        return 0;
    }
}

/// Configures the header view's edit and grabber state.
- (void)configureHeaderViewEditAndGrabberState:(YBTableViewHeaderFooterView *)view forSection:(NSInteger)section animated:(BOOL)animated {
    if ([view isKindOfClass:[YBTableViewHeaderFooterView class]]) {
        BOOL canEdit = self.isEditing && [self dataSourceCanEditHeaderInSection:section];
        BOOL canReorder = canEdit && [self dataSourceCanMoveHeaderInSection:section];
        
        view.showGrabber = canReorder;
        [view setEditing:canEdit animated:animated];
    }
    
    if (self.isMovingSectionHeader && section == self.movingSectionHeaderState.proposedDestinationIndex) {
        view.hidden = YES;
    }
}

#pragma mark UITableViewDelegate Helpers

/// Queries the data source for what the target section should be, this is done by hot rodding `UITableViewDelegate`'s
/// existing `-tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:` and only providing a single index
/// the "section"
- (NSUInteger)delegateTargetSectionForMoveFromHeaderInSection:(NSUInteger)sourceSection toProposedSection:(NSUInteger)destinationSection {
    id<UITableViewDelegate> delegate = self.tableView.delegate;
    if ([delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) {
        return [[delegate tableView:self.tableView targetIndexPathForMoveFromRowAtIndexPath:[NSIndexPath indexPathWithIndex:sourceSection] toProposedIndexPath:[NSIndexPath indexPathWithIndex:destinationSection]] indexAtPosition:0];
    }
    else {
        return destinationSection;
    }
}

#pragma mark UITableViewDataSource Helpers

/// Informs the data source that the section header has moved
- (void)dataSourceMoveHeaderFromSection:(NSUInteger)sourceSection toSection:(NSUInteger)destinationSection {
    id<UITableViewDataSource> dataSource = self.tableView.dataSource;
    if ([dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]) {
        [dataSource tableView:self.tableView moveRowAtIndexPath:[NSIndexPath indexPathWithIndex:sourceSection] toIndexPath:[NSIndexPath indexPathWithIndex:destinationSection]];
    }
}

/// Queries the data surce if section's header can be edited, this is done by hot rodding `UITableViewDataSource`'s
/// existing '-tableView:canEditRowAtIndexPath:` and only providing a single index, the "section"
- (BOOL)dataSourceCanEditHeaderInSection:(NSUInteger)section {
    id<UITableViewDataSource> dataSource = self.tableView.dataSource;
    if ([dataSource respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)]) {
        return [dataSource tableView:self.tableView canEditRowAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    }
    else {
        return NO;
    }
}

/// Queries the data surce if section's header can be moved, this is done by hot rodding `UITableViewDataSource`'s
/// existing '-tableView:canMoveRowAtIndexPath:` and only providing a single index, the "section"
- (BOOL)dataSourceCanMoveHeaderInSection:(NSUInteger)section {
    id<UITableViewDataSource> dataSource = self.tableView.dataSource;
    if ([dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]) {
        return [dataSource tableView:self.tableView canMoveRowAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    }
    else {
        return NO;
    }
}

@end

