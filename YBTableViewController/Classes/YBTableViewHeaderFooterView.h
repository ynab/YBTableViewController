//
//  YBTableViewHeaderFooterView.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/26/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 @abstract Should be used in `YBTableViewController` to support header view reording.
 @discussion Shows similar UI to that of `UITableViewCell`.
 */
@interface YBTableViewHeaderFooterView : UITableViewHeaderFooterView

/**
 @abstract Indicates that the receiver is in an editing state.
 */
@property (nonatomic, assign, getter=isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

/**
 @abstract Determines if the receiver can show the reorder control when editing.
 @discussion This property is very similar to `UITableViewCell`'s `showsReorderControl` property.
 */
@property (nonatomic, assign) BOOL showsReorderControl;

@end
