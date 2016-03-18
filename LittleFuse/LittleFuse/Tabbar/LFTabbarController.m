//
//  LFTabbarController.m
//  LittleFuse
//
//  Created by Kranthi on 22/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFTabbarController.h"

@implementation LFTabbarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tabBar setTintColor:[UIColor whiteColor]];
    UIImage *image = [UIImage imageNamed:@"header-logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    //    [self.topItem setTitleView:imageView];
    self.navigationItem.titleView = imageView;
    self.navigationItem.title = @"";
    
}


@end
