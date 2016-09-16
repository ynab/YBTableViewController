//
//  ExampleTableViewController.m
//  YBTableViewController
//
//  Created by Enrique Osuna <enrique@youneedabudget.com> on 09/16/2016.
//  Copyright (c) 2016 Enrique Osuna. All rights reserved.
//

#import "ExampleTableViewController.h"
#import "YBTableViewHeaderFooterView.h"

@class MasterRow;
@class SubRow;

@interface MasterRow : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<SubRow *> *subRows;

@end

@interface SubRow : NSObject

@property (nonatomic, copy) NSString *name;

@end

@implementation MasterRow

+ (instancetype)rowWithName:(NSString *)name subrows:(NSArray<SubRow *> *)subRows {
    id result = [[self alloc] init];
    [result setName:name];
    [result setSubRows:subRows];
    return result;
}


@end

@implementation SubRow

+ (instancetype)rowWithName:(NSString *)name {
    id result = [[self alloc] init];
    [result setName:name];
    return result;
}

@end


@interface ExampleTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<MasterRow *> *data;

@end

@implementation ExampleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray<MasterRow *> *data = [NSMutableArray new];
    NSInteger numberOfSections = 20;
    for (NSInteger section = 0; section < numberOfSections; section++) {
        NSMutableArray<SubRow *> *rows = [NSMutableArray new];
        NSInteger numberOfRows = (rand() % 3) + 1;
        for (NSInteger row = 0; row < numberOfRows; row++) {
            [rows addObject:[SubRow rowWithName:[NSString stringWithFormat:@"Row %ld.%ld", (long)section, (long)row]]];
        }
        
        [data addObject:[MasterRow rowWithName:[NSString stringWithFormat:@"Section %ld", (long)section]
                                       subrows:[rows copy]]];
    }
    self.data = [data copy];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.navigationItem.title = @"Table View";
    [self updateRightBarButtonItem];
}

- (void)updateRightBarButtonItem {
    if (self.isEditing) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toggleEditing:)];
    }
    else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(toggleEditing:)];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self updateRightBarButtonItem];
}

- (void)toggleEditing:(id)sender {
    [self setEditing:!self.isEditing animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.showsReorderControl = YES;
    cell.shouldIndentWhileEditing = NO;
    cell.textLabel.text = self.data[indexPath.section].subRows[indexPath.row].name;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    YBTableViewHeaderFooterView *header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Header"];
    if (!header) {
        header = [[YBTableViewHeaderFooterView alloc] initWithReuseIdentifier:@"Header"];
    }
    header.showsReorderControl = YES;
    header.textLabel.text = self.data[section].name;
    return header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data[section].subRows.count;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if ([sourceIndexPath isEqual:destinationIndexPath]) {
        return;
    }

    if (sourceIndexPath.length == 1) {
        // We're move section headers
        NSInteger sourceSection = [sourceIndexPath indexAtPosition:0];
        NSInteger destinationSection = [destinationIndexPath indexAtPosition:0];
        
        NSMutableArray *data = [self.data mutableCopy];
        MasterRow *sourceMasterRow = data[sourceSection];
        [data removeObjectAtIndex:sourceSection];
        [data insertObject:sourceMasterRow atIndex:destinationSection];
        self.data = [data copy];
    }
    else if (sourceIndexPath.section != destinationIndexPath.section) {
        // We're moving rows between sections
        MasterRow *sourceMasterRow = self.data[sourceIndexPath.section];
        MasterRow *destinationMasterRow = self.data[destinationIndexPath.section];
        SubRow *sourceSubRow = sourceMasterRow.subRows[sourceIndexPath.row];
        
        NSMutableArray *sourceSubRows = [sourceMasterRow.subRows mutableCopy];
        NSMutableArray *destinationSubRows = [destinationMasterRow.subRows mutableCopy];
        
        [sourceSubRows removeObjectAtIndex:sourceIndexPath.row];
        [destinationSubRows insertObject:sourceSubRow atIndex:destinationIndexPath.row];
    }
    else {
        // We're moving rows in the same section
        MasterRow *masterRow = self.data[sourceIndexPath.section];
        SubRow *sourceSubRow = masterRow.subRows[sourceIndexPath.row];
        
        NSMutableArray *sourceSubRows = [masterRow.subRows mutableCopy];
        [sourceSubRows removeObjectAtIndex:sourceIndexPath.row];
        [sourceSubRows insertObject:sourceSubRow atIndex:destinationIndexPath.row];
    }
}

@end
