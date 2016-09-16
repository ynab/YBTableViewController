//
//  YBViewController.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 09/16/2016.
//  Copyright (c) 2016 Enrique Osuna. All rights reserved.
//

#import "YBViewController.h"
#import "ExampleTableViewController.h"

@interface YBViewController ()

@property (nonatomic, strong) UINavigationController *navigationController;

@end

@implementation YBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:[ExampleTableViewController new]];
    [self.navigationController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:self.navigationController.view];
}

@end
