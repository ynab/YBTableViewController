//
//  YBTableViewMovingSectionHeaderState.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/31/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableViewMovingSectionHeaderState.h"

@interface YBTableViewMovingSectionHeaderState ()

// Redeclared as private setters
@property (nonatomic, readwrite, strong) UIView *snapShotView;
@property (nonatomic, readwrite) NSUInteger sourceIndex;

/// The offset to use when computing the `snapShotView` new position. This is based on the `originalPoint` and the header
/// view's original center point.
@property (nonatomic) CGPoint reorderTouchOffset;

@end

@implementation YBTableViewMovingSectionHeaderState

#pragma mark - Initialization

- (instancetype)initWithView:(UIView *)view sourceIndex:(NSUInteger)sourceIndex originalPoint:(CGPoint)point initialSnapShotFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        _sourceIndex = _proposedDestinationIndex = sourceIndex;
        _snapShotView = [[self class] snapShotView:view];
        _snapShotView.frame = frame;

        CGPoint snapShotViewCenter = _snapShotView.center;
        _reorderTouchOffset = CGPointMake(snapShotViewCenter.x, point.y - snapShotViewCenter.y);
    }
    
    return self;
}

- (void)dealloc {
    [self invalidate];
}

#pragma mark - Moving the Snapshot

- (void)moveToPoint:(CGPoint)point {
    [UIView performWithoutAnimation:^{
        self.snapShotView.center = CGPointMake(self.reorderTouchOffset.x, point.y - self.reorderTouchOffset.y);
    }];
}

- (void)invalidate {
    [self.snapShotView removeFromSuperview];
    self.snapShotView = nil;
}

#pragma mark - Helper

/// Returns a snap shot of the the specified view
+ (UIImage *)snapShotImageOfView:(UIView *)view {
    // Create a new graphics context and take a snapshot of the header view's layer
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

/// Creates a snapshot of the specified view.
+ (UIView *)snapShotView:(UIView *)headerView {
    // NOTE: The following code was inspired by https://github.com/LavaSlider/UITableView-Reorder
    // Original code can be found here: https://github.com/LavaSlider/UITableView-Reorder/blob/decb003d8ad4b757b11c362b58c79556c832df30/UITableView%2BReorder/UITableView%2BReorder.m#L565
    //
    //
    
    // Construct a new view that returns the appropriate top and bottom shadows with the snapshot in the middle
    UIView *resultView = [[UIView alloc] initWithFrame:headerView.frame];
    resultView.clipsToBounds = NO;
    
    // Add top shadow
    CGRect topShadowRect = resultView.bounds;
    topShadowRect.origin.y -= 9.5;
    topShadowRect.size.height = 9.5;
    
    UIView *topShadowView = [[UIView alloc] initWithFrame:topShadowRect];
    topShadowView.backgroundColor = [UIColor clearColor];
    topShadowView.opaque = NO;
    topShadowView.clipsToBounds = YES;
    
    UIBezierPath *topShadowPath = [UIBezierPath bezierPathWithRect:CGRectOffset(CGRectInset(topShadowView.bounds, -10, 0), 0, CGRectGetHeight(topShadowRect) + 1)];
    topShadowView.layer.shadowPath = topShadowPath.CGPath;
    topShadowView.layer.shadowOpacity = 1.0;
    topShadowView.layer.shadowOffset = CGSizeMake(0, -1);
    topShadowView.layer.shadowRadius = CGRectGetHeight(topShadowRect) / 2;
    [resultView addSubview:topShadowView];
    
    // Add center snapshot image
    UIImageView *centerContentView = [[UIImageView alloc] initWithFrame:resultView.bounds];
    centerContentView.image = [self snapShotImageOfView:headerView];
    centerContentView.alpha = 0.8;
    [resultView addSubview:centerContentView];
    
    // Add bottom shadow
    CGRect bottomShadowRect = resultView.bounds;
    bottomShadowRect.origin.y = CGRectGetMaxY(bottomShadowRect);
    bottomShadowRect.size.height = 9.5;
    
    UIView *bottomShadowView = [[UIView alloc] initWithFrame:bottomShadowRect];
    bottomShadowView.backgroundColor = [UIColor clearColor];
    bottomShadowView.opaque = NO;
    bottomShadowView.clipsToBounds = YES;
    
    UIBezierPath *bottomShadowPath = [UIBezierPath bezierPathWithRect:CGRectOffset(CGRectInset(bottomShadowView.bounds, -10, 0), 0, -CGRectGetHeight(bottomShadowRect) - 1)];
    bottomShadowView.layer.shadowPath = bottomShadowPath.CGPath;
    bottomShadowView.layer.shadowOpacity = 1.0;
    bottomShadowView.layer.shadowOffset = CGSizeMake(0, 1);
    bottomShadowView.layer.shadowRadius = CGRectGetHeight(bottomShadowRect) / 2;
    [resultView addSubview:bottomShadowView];
    
    return resultView;
}

@end

