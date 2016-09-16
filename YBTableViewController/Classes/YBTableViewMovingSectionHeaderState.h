//
//  YBTableViewMovingSectionHeaderState.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/31/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YBTableViewHeaderFooterView;

/**
 @abstract State information for the table view controller while a header view is moving.
 @discussion This information was originally a part of `YBTableViewController` but I thought
 it'd be nicer to split this off into its own class.
 */
@interface YBTableViewMovingSectionHeaderState : NSObject

#pragma mark - Properties

/**
 @abstract A snapshot of the header view that is moving.
 @discussion This snapshot is captured when the receiver is instantiated. `YBTableViewController`
 is responsible for inserting this `snapShotView` into it's view heiarchy (above the `UITableView`).
 */
@property (nonatomic, readonly, strong) UIView *snapShotView;

/**
 @abstract The source section index.
 @discussion This is the index of the original header view. This is where the header view came from.
 */
@property (nonatomic, readonly) NSUInteger sourceIndex;

/**
 @abstract The proposed destination section index.
 @discussion This is where we think the header view should go. This value is updated by 
 `YBTableViewController`.
 */
@property (nonatomic, readwrite) NSUInteger proposedDestinationIndex;

#pragma mark - Initialization

/**
 @abstract Initializes the receiver with the header view.
 @discussion This will initialize the receiver with a snap shot of the original header view and
 latch / compute any pertinent values needed for the rest of the move operation.
 */
- (instancetype)initWithView:(UIView *)view sourceIndex:(NSUInteger)sourceIndex originalPoint:(CGPoint)point initialSnapShotFrame:(CGRect)frame;

#pragma mark - Moving the Snapshot

/**
 @abstract Called to indicate that snapshot view has moved.
 @discussion This will compute and set the new snapshot view's location.
 */
- (void)moveToPoint:(CGPoint)point;

/**
 @abstract Invalidates the receiver.
 @discussion This removes the snapshot view from its superview and invalidates any internal state.
 This method should be called once the move operation has concluded.
 */
- (void)invalidate;

@end


@interface YBTableViewMovingSectionHeaderState (Unavailable)

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end