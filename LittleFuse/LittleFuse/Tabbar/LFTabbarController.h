//
//  LFTabbarController.h
//  LittleFuse
//
//  Created by Kranthi on 22/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFTabbarRefreshDelegate <NSObject>

@optional
- (void)refreshContentInCurrentController;

@end

@interface LFTabbarController : UITabBarController

@property (nonatomic,assign) BOOL enableRefresh;

@property (weak, nonatomic) id <LFTabbarRefreshDelegate> tabBarDelegate;

@end
