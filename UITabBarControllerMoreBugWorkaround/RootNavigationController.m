//
//  RootNavigationController.m
//  UITabBarControllerMoreBugWorkaround
//
//  Created by Fahrenkrug, Johannes on 8/8/16.
//  Copyright © 2016 Springenwerk. All rights reserved.
//

#import "RootNavigationController.h"

@implementation RootNavigationController

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    NSArray *result = [super popToRootViewControllerAnimated:animated];
    
    /*
     There's another bug where sometimes popToRootViewControllerAnimated: does not restore to the original 
     rootViewController. If that's the case, you can re-create the intended rootVC here and set it.
     */
    
    return result;
}

@end
