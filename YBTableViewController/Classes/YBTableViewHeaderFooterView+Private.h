//
//  YBTableViewHeaderFooterView+Private.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/31/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableViewHeaderFooterView.h"

@interface YBTableViewHeaderFooterView (Private)

/// Used by `YBTableViewController` to show and hide the grabber.
@property (nonatomic, assign) BOOL showGrabber;

/// The grabber image view.
@property (nonatomic, strong) UIImageView *grabberView;

@end
