
//
//  LFTabbarItem.m
//  Littlefuse
//
//  Created by SivaRamaKrishna on 22/03/17.
//  Copyright © 2017 XcubeLabs. All rights reserved.
//

#import "LFTabbarItem.h"
#import "UIImage+LFImage.h"

@interface LFTabbarItem ()
@property (nonatomic, strong) UIView *view;
@end

@implementation LFTabbarItem

-(void)setItemSize
{
    CGRect frame = self.view.frame;
    if (([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait) || ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown)) {
        frame.size.width = CGRectGetWidth(self.view.window.frame)/3;

    }
    else{
        frame.size.width = CGRectGetWidth(self.view.window.frame)/3;
    }
   // [self setSelectedImage:[UIImage imageFromColor:APP_THEME_COLOR withSize:CGSizeMake(frame.size.width, 50)]];
   // self.view.backgroundColor = [UIColor yellowColor];
    // [self setSelectedImage:[UIImage imageFromColor:APP_THEME_COLOR withSize:CGSizeMake(frame.size.width, 50)]];
    //self.selectedImage = [UIImage imageFromColor:APP_THEME_COLOR withSize:CGSizeMake(frame.size.width, 50)];
   // self.image = [UIImage imageFromColor:[UIColor redColor] withSize:CGSizeMake(frame.size.width, 50)];
   // self.view.tintColor = [UIColor redColor];
    frame.size.width= 20;
    self.view.frame = frame;
    
}
@end
