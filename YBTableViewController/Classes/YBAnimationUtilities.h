//
//  YBAnimationUtilities.h
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/26/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableViewController.h"

/**
 @abstract Convenience method that returns the default animation duration.
 @discussion If `animated` is `NO`, this function returns 0. Otherwise,
 it returns the inherited duration (if it exists), and if all else fails
 it returns the standard 0.25.
 */
NSTimeInterval YBDefaultAnimationDuration(BOOL animated);