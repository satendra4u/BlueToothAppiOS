//
//  LFPeripheral.m
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFPeripheral.h"
#import "LFConstants.h"


@implementation LFPeripheral

- (id)init
{
    self = [super init];
    if (self) {
        self.name = [[NSString alloc] init];
        self.rssi = [[NSString alloc] init];
        self.paired = NO;
        self.configured = NO;

        
    }
    return self;
}

- (id)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.name = dict[kName];
        self.rssi = dict[kRssi];
        self.paired = NO;
        self.peripheral = dict[kPeripheral];
        self.configured = [dict[kConfigStatus] boolValue];
        self.identifer = dict[kIdentifier];
    }
    return self;
}
- (id)initWithManagedObject:(NSManagedObject *)obj
{
    self = [super init];
    if (self) {
        self.name = [obj valueForKey:attiribute_name];
        self.rssi = [obj valueForKey:attiribute_rssi];
        self.paired = [[obj valueForKey:attiribute_paired] boolValue];
        self.configured = [[obj valueForKey:attiribute_config] boolValue];
        self.identifer = [obj valueForKey:attiribute_identifier];

    }
    return self;
}

@end
