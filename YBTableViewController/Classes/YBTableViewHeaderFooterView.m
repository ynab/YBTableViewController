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
@property (nonatomic, strong) UIImageView *grabberView;

@end

@implementation YBTableViewHeaderFooterView

#pragma mark - Properties

- (void)setEditing:(BOOL)editing {
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (_editing != editing) {
        _editing = editing;
        [self setNeedsLayout];
        
        if (!animated) {
            return;
        }
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self layoutIfNeeded];
        [UIView commitAnimations];
    }
}

- (void)setShowGrabber:(BOOL)showGrabber {
    if (_showGrabber != showGrabber) {
        _showGrabber = showGrabber;
        
        if (!_grabberView && _showGrabber && self.showsReorderControl) {
            [UIView performWithoutAnimation:^{
                _grabberView = [[UIImageView alloc] initWithImage:[[self class] grabberImage]];
                _grabberView.contentMode = UIViewContentModeCenter;
                _grabberView.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 12, 0, 52, CGRectGetHeight(self.contentView.frame));;
                
                [self insertSubview:_grabberView belowSubview:self.contentView];
            }];
        }
        [self setNeedsLayout];
    }
}

+ (UIImage *)grabberImage {
    static UIImage *grabberImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        grabberImage = [UIImage imageNamed:@"grabber" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    });
    
    return grabberImage;
}

#pragma mark - UITableViewHeaderFooterView Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentFrame = self.bounds;
    
    if (self.isEditing) {
        if (self.showGrabber && self.showsReorderControl) {
            contentFrame.size.width -= 40;
        }
    }
    
    self.contentView.frame = contentFrame;
    self.grabberView.frame = CGRectMake(CGRectGetWidth(contentFrame) - 12, 0, 52, CGRectGetHeight(self.contentView.frame));;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.editing = NO;
    self.showGrabber = NO;
    self.hidden = NO;
}

@end
