//
//  FixedTabBarController.m
//  UITabBarControllerMoreBugWorkaround
//
//  Created by Fahrenkrug, Johannes on 8/8/16.
//  Copyright © 2016 Springenwerk. All rights reserved.
//

#import "FixedTabBarController.h"
#import "RootNavigationController.h"
#import "RootTableViewController.h"

@interface FixedTabBarController ()

@end

@implementation FixedTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *viewControllers = [[NSMutableArray alloc] initWithCapacity:6];
    
    for (NSInteger i = 0; i < 6; i++) {
        RootNavigationController *rootNav = [[RootNavigationController alloc] initWithRootViewController:[[RootTableViewController alloc] init]];
        rootNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:[NSString stringWithFormat:@"Tab %li", i + 1] image:[UIImage imageNamed:@"first"] tag:i];
        [viewControllers addObject:rootNav];
    }
    
    [self setViewControllers:viewControllers animated:NO];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    //#define MORE_TAB_DEBUG 1
#ifdef MORE_TAB_DEBUG
#define MoreTabDLog(fmt, ...) NSLog((@"[More Tab Debug] " fmt), ##__VA_ARGS__);
#else
#define MoreTabDLog(...)
#endif
    
    MoreTabDLog(@"-- before willTransitionToTraitCollection");
    
    /*
     There is a bug when going in and out of the compact size class when a tab bar
     controller has more than 5 tabs. See http://www.openradar.me/25393521
     
     It comes down to this: When you have more than 5 tabs and a view controller on a tab
     beyond the 4th tab is a UINavigationController, you have a problem.
     When you are on this tab in compact and push one or more VCs onto the stack and then
     change back to regular width, only the top most view controller will be added back onto the
     stack.
     
     This happens because the stack of your UINavigationController is taken out of that NavVC and put
     into the private UIMoreNavigationController. But upon rotating back to regular, that stack is not
     correctly put back into your own NavVC.
     
     We have 3 cases we have to handle:
     
     1) We are on the "More" tab in compact and are looking at the UIMoreListController and then change to
     regular size.
     2) While in compact width, we are on a tab greater than the 4th and are changing to regular width.
     3) While in regular width, we are on a tab greater than the 4th and are changing to compact width.
     */
    
    if ((self.traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass) ||
        (self.traitCollection.verticalSizeClass != newCollection.verticalSizeClass))
    {
        /*
         Case 1: We are on the "More" tab in compact and are looking at the UIMoreListController and then change to regular size.
         */
        if ([self.selectedViewController isKindOfClass:[UINavigationController class]] && [NSStringFromClass([self.selectedViewController class]) hasPrefix:@"UIMore"]) {
            // We are on the root of the MoreViewController in compact, going into regular.
            // That means we have to pop all the viewControllers in the MoreViewController to root
#ifdef MORE_TAB_DEBUG
            UINavigationController *moreNavigationController = (UINavigationController *)self.selectedViewController;
            
            UIViewController *moreRootViewController = [moreNavigationController topViewController];
            
            MoreTabDLog(@"-- going OUT of compact while on UIMoreList");
            MoreTabDLog(@"moreRootViewController: %@", moreRootViewController);
#endif
            
            for (NSInteger overflowVCIndex = 4; overflowVCIndex < [self.viewControllers count]; overflowVCIndex++) {
                if ([self.viewControllers[overflowVCIndex] isKindOfClass:[UINavigationController class]]) {
                    UINavigationController *navigationController = (UINavigationController *)self.viewControllers[overflowVCIndex];
                    MoreTabDLog(@"popping %@ to root", navigationController);
                    [navigationController popToRootViewControllerAnimated:NO];
                }
            }
        } else {
            BOOL isPotentiallyInOverflow = [self.viewControllers indexOfObject:self.selectedViewController] >= 4;
            
            MoreTabDLog(@"isPotentiallyInOverflow: %i", isPotentiallyInOverflow);
            
            if (isPotentiallyInOverflow && [self.selectedViewController isKindOfClass:[UINavigationController class]]) {
                UINavigationController *selectedNavController = (UINavigationController *)self.selectedViewController;
                NSArray<UIViewController *> *selectedNavControllerStack = [selectedNavController viewControllers];
                
                MoreTabDLog(@"Selected Nav: %@, selectedNavStack: %@", selectedNavController, selectedNavControllerStack);
                UIViewController *lastChildVCOfTabBar = [[self childViewControllers] lastObject];
                
                if ([lastChildVCOfTabBar isKindOfClass:[UINavigationController class]] && [NSStringFromClass([lastChildVCOfTabBar class]) hasPrefix:@"UIMore"]) {
                    /*
                     Case 2: While in compact width, we are on a tab greater than the 4th and are changing to regular width.
                     
                     We are going OUT of compact
                     */
                    UINavigationController *moreNavigationController = (UINavigationController *)lastChildVCOfTabBar;
                    
                    NSArray *moreNavigationControllerStack = [moreNavigationController viewControllers];
                    
                    MoreTabDLog(@"--- going OUT of compact");
                    MoreTabDLog(@"moreNav: %@, moreNavStack: %@, targetNavStack: %@", moreNavigationController, moreNavigationControllerStack, selectedNavControllerStack);
                    
                    if ([moreNavigationControllerStack count] > 1) {
                        NSArray *fixedTargetStack = [moreNavigationControllerStack subarrayWithRange:NSMakeRange(1, moreNavigationControllerStack.count - 1)];
                        
                        MoreTabDLog(@"fixedTargetStack: %@", fixedTargetStack);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSArray *correctVCList = [NSArray arrayWithArray:self.viewControllers];
                            [selectedNavController willMoveToParentViewController:self];
                            [selectedNavController setViewControllers:fixedTargetStack animated:NO];
                            // We need to do this because without it, the selectedNavController doesn't
                            // have a parentViewController anymore.
                            [self addChildViewController:selectedNavController];
                            
                            // We need to do this because otherwise the previous call will cause the given
                            // Tab to show up twice in the UIMoreListController.
                            [self setViewControllers:correctVCList];
                            
                            // This is needed for the navigationBar to update.
                            // Without this, it might display the nav items of the root view controller,
                            // not of the top view controller
                            selectedNavController.navigationBarHidden = YES;
                            selectedNavController.navigationBarHidden = NO;
                        });
                    } else {
                        MoreTabDLog(@"popping to root");
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [selectedNavController popToRootViewControllerAnimated:NO];
                        });
                    }
                } else {
                    /*
                     Case 3: While in regular width, we are on a tab greater than the 4th and are changing to compact width.
                     
                     We are going INTO compact
                     */
                    
                    MoreTabDLog(@"-- going INTO compact");
                    
                    if ([selectedNavControllerStack count] > 0) {
                        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                            // no op
                        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                            UIViewController *parentViewControllerOfTopVC = [[selectedNavControllerStack lastObject] parentViewController];
                            
                            MoreTabDLog(@"parentViewControllerOfTopVC: %@", parentViewControllerOfTopVC);
                            
                            if ([parentViewControllerOfTopVC isKindOfClass:[UINavigationController class]] && [NSStringFromClass([parentViewControllerOfTopVC class]) hasPrefix:@"UIMore"]) {
                                UINavigationController *moreNavigationController = (UINavigationController *)parentViewControllerOfTopVC;
                                
                                NSArray *moreNavigationControllerStack = [moreNavigationController viewControllers];
                                
                                BOOL isOriginalRootVCInMoreStack = [moreNavigationControllerStack containsObject:[selectedNavControllerStack firstObject]];
                                
                                MoreTabDLog(@"moreNav: %@, moreNavStack: %@, isOriginalRootVCInMoreStack: %i", moreNavigationController, moreNavigationControllerStack, isOriginalRootVCInMoreStack);
                                
                                if (!isOriginalRootVCInMoreStack) {
                                    NSArray *fixedMoreStack = [@[moreNavigationControllerStack[0]] arrayByAddingObjectsFromArray:selectedNavControllerStack];
                                    
                                    MoreTabDLog(@"fixedMoreStack: %@", fixedMoreStack);
                                    
                                    [selectedNavController setViewControllers:selectedNavControllerStack animated:NO];
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [moreNavigationController setViewControllers:fixedMoreStack animated:NO];
                                    });
                                }
                            }
                        }];
                    }
                }
            }
        }
        
    }
    
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    MoreTabDLog(@"-- after willTransitionToTraitCollection");
}

@end
