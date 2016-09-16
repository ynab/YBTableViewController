//
//  YBTableViewController.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/23/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 @abstract Responsible for the lifecycle of a table view that supports header view reordering.
 @discussion This view controller allows the user to reoder header views. Header views should
 be subclasses of `YBTableViewHeaderFooterView`. Similar to `UITableViewCell` if you want to 
 show the reorder controls you need to enable `showsReorderControl`.
 */
@interface YBTableViewController : UIViewController

/**
 @abstract The table view that the receiver manages.
 @discussion This table view is special and should not be dittled with, outside
 of this class. If you mess around and try to return / set a different instance
 of `UITableView` the reording stuff may not work as you expect it to.
 */
@property (nonatomic, readonly) UITableView *tableView;

/**
 @abstract Indicates that the user is curring in a section header move.
 @discussion This value will be set to `YES` if the user is actively moving 
 a header view. `NO` otherwise.
 */
@property (nonatomic, readonly, getter=isMovingSectionHeader) BOOL movingSectionHeader;

@end

