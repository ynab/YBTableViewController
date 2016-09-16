//
//  YBTableView.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/31/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableView.h"
#import "YBTableViewController.h"
#import "YBTableViewController+Private.h"
#import "YBTableViewHeaderFooterView.h"
#import "YBTableViewHeaderFooterView+Private.h"

@implementation YBTableView

- (YBTableViewDataSourceProxy *)dataSourceProxy {
    if (!_dataSourceProxy) {
        // Lazily load the proxy
        _dataSourceProxy = [[YBTableViewDataSourceProxy alloc] init];
        _dataSourceProxy.dataSource = self.dataSource;
    }
    
    return _dataSourceProxy;
}

- (YBTableViewDelegateProxy *)delegateProxy {
    if (!_delegateProxy) {
        // Lazily load the proxy
        _delegateProxy = [[YBTableViewDelegateProxy alloc] init];
        _delegateProxy.delegate = self.delegate;
    }
    
    return _delegateProxy;
}

- (void)setDataSource:(id<UITableViewDataSource>)dataSource {
    // Update the proxy and update the super with our proxy object
    self.dataSourceProxy.dataSource = dataSource;
    [super setDataSource:(id<UITableViewDataSource>)self.dataSourceProxy];
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
    // Update the proxy and update the super with our proxy object
    self.delegateProxy.delegate = delegate;
    [super setDelegate:(id<UITableViewDelegate>)self.delegateProxy];
}

@end

#pragma mark -

@implementation YBTableViewDataSourceProxy

#pragma mark - NSObject

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        // Return early if the receiver responds to this selector
        return YES;
    }

    // Ask the data source if it responds to this selector
    return [self.dataSource respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    // We don't know how to deal with this selector ourselves, forward it
    // to the data source
    return self.dataSource;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(YBTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.viewController.isMovingSectionHeader) {
        // Return early if the view controller is moving a header view
        return 0;
    }

    NSInteger result = 0;
    if ([self.dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        // Go ahead and directly query the data source for this information
        result = [self.dataSource tableView:tableView numberOfRowsInSection:section];
    }
    
    return result;
}

@end

#pragma mark -

@implementation YBTableViewDelegateProxy

#pragma mark - NSObject

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        // Return early if the receiver responds to this selector
        return YES;
    }
    
    // Ask the delegate if it responds to this selector
    return [self.delegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    // We don't know how to deal with this selector ourselves, forward it
    // to the delegate
    return self.delegate;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(YBTableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // Forward this call to the delegate but with an adjusted section index.
    NSInteger adjustedSection = [tableView.viewController adjustedSectionForSection:section];
    if ([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        // Go ahead and directly query the data source for this information
        return [self.delegate tableView:tableView viewForHeaderInSection:adjustedSection];
    }
    else {
        return nil;
    }
}

- (void)tableView:(YBTableView *)tableView willDisplayHeaderView:(YBTableViewHeaderFooterView *)view forSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(tableView:willDisplayHeaderView:forSection:)]) {
        // Always forward this call to the delegate
        [self.delegate tableView:tableView willDisplayHeaderView:view forSection:section];
    }
    
    if ([view isKindOfClass:[YBTableViewHeaderFooterView class]]) {
        // And also forward this call to the view controller
        [tableView.viewController willDisplayHeaderView:view forSection:section];
    }
}

@end