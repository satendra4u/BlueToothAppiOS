//
//  LFDataManager.m
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFDataManager.h"
#import "LFConstants.h"
#import "LFPeripheral.h"
#import "LFBluetoothManager.h"

static LFDataManager *dataManager = nil;

@implementation LFDataManager

#pragma mark - SharedManager

/**
 @abstract sharedAPIManager
 @discussion Used to create a singleInstance for the APIManger.
 @param none
 @return HPSAPIManager reference object
 */

+ (LFDataManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataManager = [[self alloc] init];
    });
    return dataManager;
}

- (void)savePeripheralDetails:(LFPeripheral *)peripheral;
{
    if (![self checkWeatherDeviceExistsInDB:peripheral]) {
        NSManagedObject *userInfoObj = [NSEntityDescription insertNewObjectForEntityForName:PERIPHERAL_ENTITY  inManagedObjectContext:_managedObjectContext];
        [userInfoObj setValue:peripheral.name forKey:attiribute_name];
        [userInfoObj setValue:[NSString stringWithFormat:@"%@", peripheral.rssi] forKey:attiribute_rssi];
        [userInfoObj setValue:peripheral.identifer forKey:attiribute_identifier];
        [userInfoObj setValue:[NSNumber numberWithBool:peripheral.isPaired] forKey:attiribute_paired];
        [userInfoObj setValue:[NSNumber numberWithBool:peripheral.isConfigured] forKey:attiribute_config];
        
        NSError *error;
        // Save the object to persistent store
        if (![_managedObjectContext save:&error]) {
            DLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        }
        

    }
}

- (NSMutableArray *)fetchSavedPeripherals
{
    NSMutableArray *savedArray = [[NSMutableArray alloc] initWithCapacity:0];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *obj in fetchedObjects) {
        LFPeripheral *peripheral = [[LFPeripheral alloc] initWithManagedObject:obj];
        [savedArray addObject:peripheral];
    }
    return savedArray;
}

- (void)updatePeripheralDetails:(LFPeripheral *)peripheral
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSManagedObject *peripheralObj = [eventObjects firstObject];
    
    //updating new data
    [peripheralObj setValue:[NSNumber numberWithBool:peripheral.isConfigured] forKey:attiribute_config];
    [peripheralObj setValue:[NSNumber numberWithBool:peripheral.isPaired] forKey:attiribute_paired];
    
    // Save the object to persistent store
    if (![_managedObjectContext save:&error]) {
        DLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
    }
}

- (BOOL)checkWeatherDeviceExistsInDB:(LFPeripheral *)peripheral
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if ([eventObjects count]) {
        return YES;
    } else {
        return NO;
    }

}


- (LFPeripheral *)getDeviceWithIdentifier:(LFPeripheral *)peripheral
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@", peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if ([eventObjects count]) {
        LFPeripheral *peripheral = [[LFPeripheral alloc] initWithManagedObject:[eventObjects firstObject]];
        return peripheral;
    } else {
        return nil;
    }
    
}

- (void)deleteCompleteData
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext]];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error;
    NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    //error handling goes here
    for (NSManagedObject *obj in fetchedObjects) {
        [_managedObjectContext deleteObject:obj];
    }
    NSError *saveError = nil;
    [_managedObjectContext save:&saveError];

}

#pragma mark FAULT DATA

- (NSManagedObject *)saveFaultData:(LFFaultData *)data {
    NSManagedObject *productInfoObj = [NSEntityDescription insertNewObjectForEntityForName:FAULT_ENTITY inManagedObjectContext:_managedObjectContext];
    [productInfoObj setValue:data.current forKey:attribute_current];
    [productInfoObj setValue:data.date forKey:attribute_date];
    [productInfoObj setValue:data.power forKey:attribute_power];
    [productInfoObj setValue:data.voltage forKey:attribute_voltage];
    [productInfoObj setValue:data.other forKey:attribute_other];
   
    return productInfoObj;
}

- (void)saveFaultDetails:(LFFaultData *)data WithPeripheral:(LFPeripheral *)peripheral;
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSManagedObject *peripheralObj = [eventObjects firstObject];
    
    NSMutableSet *muteSet=[peripheralObj mutableSetValueForKey:PERIPHERAL_FAULT_RELATION];
    [muteSet addObject:[self saveFaultData:data]];
     [peripheralObj setValue:muteSet forKey:PERIPHERAL_FAULT_RELATION];
     
     // Save the object to persistent store
     if (![_managedObjectContext save:&error]) {
         DLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
     }
}


- (NSMutableArray *)getFaultDataForSelectedDate:(NSDate *)date
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    LFPeripheral *peripheral = [[LFBluetoothManager sharedManager] selectedPeripheral];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSMutableArray *faultArr = [[NSMutableArray alloc] initWithCapacity:0];
    if (eventObjects.count > 0) {
        NSManagedObject *peripheralObj = [eventObjects firstObject];
        
        NSSet *faultList = [peripheralObj valueForKey:PERIPHERAL_FAULT_RELATION];
        
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"(date <= %@)", date];
        
        NSSet *filteredSet = [faultList filteredSetUsingPredicate:filter];
        
        for (NSManagedObject *fault in filteredSet) {
            LFFaultData *faultData = [[LFFaultData alloc]initWithManagedObject:fault];
            [faultArr addObject:faultData];
        }
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        [faultArr sortUsingDescriptors:sortDescriptors];

    }
    return faultArr;

}

- (NSArray *)getAllFaults {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    LFPeripheral *peripheral = [[LFBluetoothManager sharedManager] selectedPeripheral];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSMutableArray *faultArr = [[NSMutableArray alloc] initWithCapacity:0];
    if (eventObjects.count > 0) {
        NSManagedObject *peripheralObj = [eventObjects firstObject];
        
        NSSet *faultList = [peripheralObj valueForKey:PERIPHERAL_FAULT_RELATION];
//        
//        NSPredicate *filter = [NSPredicate predicateWithFormat:@"(date <= %@)", date];
//        
//        NSSet *filteredSet = [faultList filteredSetUsingPredicate:filter];
//        
        for (NSManagedObject *fault in faultList) {
            LFFaultData *faultData = [[LFFaultData alloc]initWithManagedObject:fault];
            [faultArr addObject:faultData];
        }
//        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
//        [faultArr sortUsingDescriptors:sortDescriptors];
        
    }
    return faultArr;
}


- (LFFaultData *)getSavedDataWithDate:(NSDate *)date;
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    LFPeripheral *peripheral = [[LFBluetoothManager sharedManager] selectedPeripheral];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    LFFaultData *faultData;
    if (eventObjects.count > 0) {
        NSManagedObject *peripheralObj = [eventObjects firstObject];
        
        NSSet *faultList = [peripheralObj valueForKey:PERIPHERAL_FAULT_RELATION];
        
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"date == %@ ", date];
        
        NSSet *filteredSet = [faultList filteredSetUsingPredicate:filter];
//        if (filteredSet.count > 0) {
//            NSLog(@"Count of filtered set = %ld", (long)filteredSet.count);
//            NSLog(@"Items in filtered set = %@", filteredSet);
//        }
        NSManagedObject *fault = [[filteredSet allObjects] firstObject];
       faultData = [[LFFaultData alloc]initWithManagedObject:fault];
    }
    return faultData;
}

- (NSInteger)getTotalFaultsCount
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:PERIPHERAL_ENTITY inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    LFPeripheral *peripheral = [[LFBluetoothManager sharedManager] selectedPeripheral];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier matches[c] %@",peripheral.identifer]];
    NSError *error;
    NSArray *eventObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSInteger faultsCount = 0;
    if (eventObjects.count > 0) {
        NSManagedObject *peripheralObj = [eventObjects firstObject];
        
        NSSet *faultList = [peripheralObj valueForKey:PERIPHERAL_FAULT_RELATION];
        return faultList.count;
        
    }
    return faultsCount;

}

@end
