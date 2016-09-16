//
//  YBTableView.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/31/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YBTableViewController;
@class YBTableViewDataSourceProxy;
@class YBTableViewDelegateProxy;

/**
 @abstract Special `UITableView` subclass used by `YBTableViewController`.
 @discussion This view has been designed to be used strictly by `YBTableViewController`. Uses outside
 of this view controller is not supported.
 
 This table view reroutes the suer's data source and delegate to a proxy object responsible for
 diverting certain callbacks to the `YBTableViewController` while it is in the middle of a header 
 view move.
 */
@interface YBTableView : UITableView

/**
 @abstract The view controller to forward the proxied calls to.
 @discussion This should be a weakly held property as to avoid a strong circular reference betwee
 `YBTableViewController` and the receiver.
 */
@property (nonatomic, weak) YBTableViewController *viewController;

/**
 @abstract The data source proxy object.
 @discussion This diverts some call backs to the receiver's `viewController`.
 Otherwise, invocations are forwarded to the real data source.
 */
@property (nonatomic, strong) YBTableViewDataSourceProxy *dataSourceProxy;

/**
 @abstract The delegate proxy object.
 @discussion This diverts some call backs to the receiver's `viewController`.
 Otherwise, invocations are forwarded to the real delegate.
 */
@property (nonatomic, strong) YBTableViewDelegateProxy *delegateProxy;

@end

/**
 @abstract Proxy that diverts `UITableViewDataSource` calls.
 */
@interface YBTableViewDataSourceProxy : NSObject

/**
 @abstract The real data source.
 @discussion The table view's real data source. This is the object that
 will get the data source calls if/when the `UITableViewController` does
 not need to intercept them.
 */
@property (nonatomic, weak) id<UITableViewDataSource> dataSource;

@end


/**
 @abstract Proxy that diverts `UITableViewDelegate` calls.
 */
@interface YBTableViewDelegateProxy : NSObject

/**
 @abstract The real delegate.
 @discussion The table view's real delegate. This is the object that
 will get the delegate calls if/when the `UITableViewController` does
 not need to intercept them.
 */
@property (nonatomic, weak) id<UITableViewDelegate> delegate;

@end
