//
//  LFDisplay.m
//  LittleFuse
//
//  Created by Kranthi on 29/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFDisplay.h"

@implementation LFDisplay

- (id)init
{
    self = [super init];
    if (self) {
        _code = [[NSString alloc] init];
        _key = [[NSString alloc] init];
        _value = [[NSString alloc] init];
        _units = [[NSString alloc] init];
    }
    return self;
}
- (id)initWithKey:(NSString *)key Value:(NSString *)val Code:(NSString *)code
{
    self = [super init];
    if (self) {
        self.key = key;
        self.value = val;
        self.code = code;

    }
    return self;
}

@end
