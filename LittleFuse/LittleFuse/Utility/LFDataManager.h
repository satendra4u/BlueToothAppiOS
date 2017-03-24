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

/**
 * This method saves the details of a peripheral to the core data.
 * @param: peripheral: The device which is to be saved.
 */
- (void)savePeripheralDetails:(LFPeripheral *)peripheral;

/**
 @return: List of saved peripheral devices.
 */
- (NSMutableArray *)fetchSavedPeripherals;

/**
 * This method updates the details of existing peripheral with new values.
 * @param: peripheral: The peripheral which is to be updated containing the updated values.
 */
- (void)updatePeripheralDetails:(LFPeripheral *)peripheral;

/**
 * @return: The peripheral with a given identifier.
 * @param: peripheral: The peripheral object containing the identifier.
 */
- (LFPeripheral *)getDeviceWithIdentifier:(LFPeripheral *)peripheral;

/**
 * This method deletes all the data stores in locally.
 */
- (void)deleteCompleteData;

/**
 * This method saves fault details for a given peripheral.
 * @param: data: The data to be stored for the peripheral.
 * @param: peripheral: The device for which data is to be stored.
 */
- (void)saveFaultDetails:(LFFaultData *)data WithPeripheral:(LFPeripheral *)peripheral;

/**
 * This method retrieves the list of faults for a given date.
 * @param: date: The date for which faults are to be retrieved.
 * @return: Array containing list of faults for the given date.
 */
- (NSMutableArray *)getFaultDataForSelectedDate:(NSDate *)date;
/**
 @discussion Get Least or Max date saved object

 @param ascend  BOOL (YES - Ascending order; NO - Descending order)
 @return LFFaultData object
 */
- (LFFaultData *)getSavedDataWithDate:(NSDate *)date;

/**
 * Returns the total number of faults.
 */
- (NSInteger)getTotalFaultsCount;

- (NSArray *)getAllFaults;

@end
