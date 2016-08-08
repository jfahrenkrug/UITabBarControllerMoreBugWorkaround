//
//  LeafViewController.m
//  UITabBarControllerMoreBugWorkaround
//
//  Created by Fahrenkrug, Johannes on 8/8/16.
//  Copyright © 2016 Springenwerk. All rights reserved.
//

#import "LeafViewController.h"

@implementation LeafViewController {
    UIColor *_color;
}

- (instancetype)initWithColor:(UIColor *)color
{
    self = [super init];
    
    if (self) {
        _color = color;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = _color;
}

@end
