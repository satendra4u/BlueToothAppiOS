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
@interface LFTabbarController () <UITabBarDelegate>
@end

@implementation LFTabbarController 

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tabBar setTintColor:[UIColor whiteColor]];
    self.navigationController.navigationBar.hidden= YES;
   /*
    UIImage *image = [UIImage imageNamed:@"header-logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    self.navigationItem.titleView = imageView;
    self.navigationItem.title = @"";
    self.navigationController.navigationBar.hidden = YES;*/
    //[self.navigationItem setHidesBackButton:YES];


}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    DLog(@"Tab bar view disappeared");
}
-(void)moveToDevicesListController
{
    [self.navigationController popViewControllerAnimated:YES];
}



@end
