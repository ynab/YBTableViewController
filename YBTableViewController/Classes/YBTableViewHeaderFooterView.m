//
//  YBTableViewHeaderFooterView.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 8/26/16.
//  Copyright © 2016 You Need a Budget, LLC. All rights reserved.
//

#import "YBTableViewHeaderFooterView.h"
#import "YBTableViewHeaderFooterView+Private.h"
#import "YBTableViewController.h"
#import "YBAnimationUtilities.h"

@interface YBTableViewHeaderFooterView ()

@property (nonatomic, assign) BOOL showGrabber;
- (void)setShowGrabber:(BOOL)showGrabber animated:(BOOL)animated;
@property (nonatomic, strong) UIImageView *grabberView;

/// Indicates that the receiver is animating/
@property (nonatomic, readonly, getter=isAnimating) BOOL animating;

/// The number of inlight animations.
@property (nonatomic, assign) NSInteger numberOfAnimations;

@end

@implementation YBTableViewHeaderFooterView

#pragma mark - Properties

- (BOOL)isAnimating {
    return self.numberOfAnimations > 0;
}

- (void)setEditing:(BOOL)editing {
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (_editing != editing) {
        _editing = editing;
        
        [self updateContentViewAnimated:animated];
    }
}

- (void)setShowGrabber:(BOOL)showGrabber {
    [self setShowGrabber:showGrabber animated:NO];
}

+ (UIImage *)grabberImage {
    static UIImage *grabberImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        grabberImage = [UIImage imageNamed:@"grabber" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    });
    
    return grabberImage;
}

- (void)setShowGrabber:(BOOL)showGrabber animated:(BOOL)animated {
    if (_showGrabber != showGrabber) {
        _showGrabber = showGrabber;
        
        if (!_grabberView && _showGrabber && self.showsReorderControl) {
            [UIView performWithoutAnimation:^{
                _grabberView = [[UIImageView alloc] initWithImage:[[self class] grabberImage]];
                _grabberView.backgroundColor = [UIColor whiteColor];
                _grabberView.contentMode = UIViewContentModeCenter;
                _grabberView.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 12, 0, 52, CGRectGetHeight(self.contentView.frame));;
                
                [self insertSubview:_grabberView belowSubview:self.contentView];
            }];
        }

        [self updateContentViewAnimated:animated];
    }
}

#pragma mark - UITableViewHeaderFooterView Overrides

- (void)layoutSubviews {
    if (!self.isAnimating) {
        [super layoutSubviews];
        [self updateContentView];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.editing = NO;
    self.showGrabber = NO;
    self.hidden = NO;
}

#pragma mark - Helper

- (void)updateContentViewAnimated:(BOOL)animated {
    if (!animated) {
        // No animation required, update the content view frame and return early
        [self updateContentView];
        return;
    }
    
    self.numberOfAnimations++;
    [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
        [self updateContentView];
    } completion:^(BOOL finished) {
        self.numberOfAnimations--;
    }];
}

- (void)updateContentView {
    CGRect contentFrame = self.bounds;
    
    if (self.isEditing) {
        if (self.showGrabber && self.showsReorderControl) {
            contentFrame.size.width -= 40;
        }
    }
    
    self.contentView.frame = contentFrame;
    self.grabberView.frame = CGRectMake(CGRectGetWidth(contentFrame) - 12, 0, 52, CGRectGetHeight(self.contentView.frame));;
}

@end
