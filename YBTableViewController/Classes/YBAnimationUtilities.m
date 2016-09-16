//
//  YBAnimationUtilities.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/26/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBAnimationUtilities.h"

NSTimeInterval YBDefaultAnimationDuration(BOOL animated) {
    if (!animated || ![UIView areAnimationsEnabled]) {
        // Return early if animations are disabled
        return 0;
    }
    
    NSTimeInterval result = [UIView inheritedAnimationDuration];
    if (result > 0) {
        // Return the inherited animation duration, if it exists
        return result;
    }
    
    result = [CATransaction animationDuration];
    if (result > 0) {
        // Return the inherited animation duration, if it exists
        return result;
    }
    
    // Return the default value
    return 0.25;
}

