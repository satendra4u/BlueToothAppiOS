//
//  LFPeripheral.h
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreData/CoreData.h>

@interface LFPeripheral : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *rssi;
@property (nonatomic, assign, getter=isPaired) BOOL paired;
@property (nonatomic, assign, getter=isConfigured) BOOL configured;
@property (nonatomic, copy) CBPeripheral *peripheral;
@property (nonatomic, copy) NSString *identifer;
@property (nonatomic, assign) BOOL isDeviceBusy;

- (id)initWithDict:(NSDictionary *)dict;
- (id)initWithManagedObject:(NSManagedObject *)obj;
@end
