//
//  LFAuthUtils.h
//  Littlefuse
//
//  Created by Ashwin on 10/31/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#define TAG @"MP8KAUTH"

@interface LFAuthUtils : NSObject
- (void)initWithPassKey:(NSString *)passKey andMacAddress:(NSString *)macAddress andSeed:(const char *)seed;
- (NSMutableData *)getNewPassKeydata:(NSString *)passKey;
- (NSMutableData *)computeAuthCode:(const char *)byteData address:(short)address size:(short)size;
- (void)nextAuthCode;
@end
