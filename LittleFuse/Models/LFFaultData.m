//
//  LFFaultData.m
//  Littlefuse
//
//  Created by Kranthi on 12/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFFaultData.h"

@implementation LFFaultData

- (id)init
{
    self = [super init];
    if (self) {
        _voltage = [[NSData alloc] init];
        _current = [[NSData alloc] init];
        _power = [[NSData alloc] init];
        _date = [[NSDate alloc] init];
        _other = [[NSData alloc] init];
    }
    return self;
}

- (id)initWithManagedObject:(NSManagedObject *)obj
{
    self = [super init];
    if (self) {
        self.date = [obj valueForKey:attribute_date];
        self.current = [obj valueForKey:attribute_current];
        self.power = [obj valueForKey:attribute_power];
        self.voltage = [obj valueForKey:attribute_voltage];
        self.other = [obj valueForKey:attribute_other];
    }
    return self;
}

@end
