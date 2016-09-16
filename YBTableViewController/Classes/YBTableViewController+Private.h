//
//  YBTableViewController+Private.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 9/1/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableViewController.h"

@class YBTableViewHeaderFooterView;

@interface YBTableViewController (Private)

/// Returns an adjusted section index, if we're in the middle of a moving a section header
- (NSInteger)adjustedSectionForSection:(NSInteger)section;

/// Notifies the view controller that the specified header view will be displayed
- (void)willDisplayHeaderView:(YBTableViewHeaderFooterView *)view forSection:(NSInteger)section;

@end

