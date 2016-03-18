//
//  LFDataManager.h
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LFPeripheral.h"
#import "LFFaultData.h"

@interface LFDataManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

+ (LFDataManager *)sharedManager;


- (void)savePeripheralDetails:(LFPeripheral *)peripheral;

- (NSMutableArray *)fetchSavedPeripherals;

- (void)updatePeripheralDetails:(LFPeripheral *)peripheral;

- (LFPeripheral *)getDeviceWithIdentifier:(LFPeripheral *)peripheral;

- (void)deleteCompleteData;

- (void)saveFaultDetails:(LFFaultData *)data WithPeripheral:(LFPeripheral *)peripheral;

- (NSMutableArray *)getFaultDataForSelectedDate:(NSDate *)date;
/**
 @discussion Get Least or Max date saved object

 @param ascend  BOOL (YES - Ascending order; NO - Descending order)
 @return LFFaultData object
 */


- (LFFaultData *)getSavedDataWithDate:(NSDate *)date;

- (NSInteger)getTotalFaultsCount;


@end
