# UITabBarControllerMoreBugWorkaround

There's a bug in UITabBarController when you have more than 5 tabs, the view controllers beyond the 4th one include at least one UINavigationController and your trait collection changes at runtime (iOS 9 multitasking or iPhone 6+).

When you are on a tab beyond the 4th one while in compact width and you push one or more view controllers onto the stack and then change back to regular width, only the top most view controller will be added back onto the stack.
     
This happens because the stack of your UINavigationController is removed from it and put into the private UIMoreNavigationController. But upon rotating back to regular width, that stack is not correctly put back into its original UINavigationViewController. 

See http://www.openradar.me/25393521

See https://forums.developer.apple.com/thread/25124

The workaround lives in FixedTabBarController.m's willTransitionToTraitCollection:withTransitionCoordinator: method.


     