//
//  LFTabbarController.m
//  LittleFuse
//
//  Created by Kranthi on 22/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFTabbarController.h"
#import "LFBluetoothManager.h"
#import "UIImage+LFImage.h"
#import "LFTabbarItem.h"

@implementation LFTabbarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tabBar setTintColor:[UIColor whiteColor]];
    UIImage *image = [UIImage imageNamed:@"header-logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    self.navigationItem.titleView = imageView;
    self.navigationItem.title = @"";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];

}

- (void)refreshContent {
    if (_tabBarDelegate && [_tabBarDelegate respondsToSelector:@selector(refreshContentInCurrentController)]) {
        [_tabBarDelegate refreshContentInCurrentController];
    }
}

//Setter method hide/unhide refresh button
- (void)setEnableRefresh:(BOOL)enableRefresh {
    if (!enableRefresh) {
        self.navigationItem.rightBarButtonItems = @[];
    }
    else {
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"scan_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshContent)];
        self.navigationItem.rightBarButtonItems = @[refreshButton];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    DLog(@"Tab bar view disappeared");
}

// method signature
- (void)rotated:(NSNotification *)notification {
   /*     NSArray *items =  self.tabBar.items;
    for (int i =0; i<items.count; i++) {
       // LFTabbarItem *item = items[i];
       // [item setItemSize];
    }*/
    
}

@end
