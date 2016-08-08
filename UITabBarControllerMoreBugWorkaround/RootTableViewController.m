//
//  RootTableViewController.m
//  UITabBarControllerMoreBugWorkaround
//
//  Created by Fahrenkrug, Johannes on 8/8/16.
//  Copyright © 2016 Springenwerk. All rights reserved.
//

#import "RootTableViewController.h"
#import "LeafViewController.h"

@interface RootTableViewController ()

@end

@implementation RootTableViewController

static NSString * const kCellReuseIdentifier = @"reuseCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellReuseIdentifier];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    NSString *title = nil;
    
    switch (indexPath.row) {
        case 0:
            title = @"Red";
            break;
            
        case 1:
            title = @"Green";
            break;
            
        case 2:
            title = @"Blue";
            
        default:
            break;
    }
    
    cell.textLabel.text = title;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = nil;
    
    switch (indexPath.row) {
        case 0:
            color = [UIColor redColor];
            break;
            
        case 1:
            color = [UIColor greenColor];
            break;
            
        case 2:
            color = [UIColor blueColor];
            
        default:
            break;
    }
    
    LeafViewController *leafVC = [[LeafViewController alloc] initWithColor:color];
    
    [self.navigationController pushViewController:leafVC animated:YES];
}


@end
