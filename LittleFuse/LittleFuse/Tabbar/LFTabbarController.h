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
//This method is called when refresh button is tapped in the configuration controller.

@end

@interface LFTabbarController : UITabBarController

//@property (nonatomic,assign) BOOL enableRefresh;//Used to handle refresh button in configuration screen.

@property (weak, nonatomic) id <LFTabbarRefreshDelegate> tabBarDelegate;

-(void)moveToDevicesListController;

@end
