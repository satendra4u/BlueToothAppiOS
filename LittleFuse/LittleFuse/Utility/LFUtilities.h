//
//  LFUtilities.h
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LFUtilities : NSObject

+ (NSUInteger)getValueFromHexData:(NSData *)data;

+ (NSString *)conversionJFormate:(NSData *)data;

+ (NSString *)convertToBFormate:(float)val;

+ (NSString *)convertToCFormate:(NSData *)data;

+ (NSString *)convertToDFormate:(float)val;

+ (NSString *)convertToHFormate:(float)val;

+ (NSString *)convertToLFormate:(float)val;

@end
