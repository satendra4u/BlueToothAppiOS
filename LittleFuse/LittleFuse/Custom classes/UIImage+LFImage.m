//
//  UIImage+LFImage.m
//  Littlefuse
//
//  Created by Kranthi on 15/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "UIImage+LFImage.h"

@implementation UIImage (LFImage)


+ (UIImage *)imageFromColor:(UIColor *)color withSize:(CGSize)size {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
