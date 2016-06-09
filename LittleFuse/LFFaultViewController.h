//
//  LFFaultViewController.h
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFFaultViewController : LFBaseViewController

/**
 * This method performs the background loading of faults once in a given time interval and checks for any new faults.
 */
- (void)updateFaultData;

/**
 * This method converts a given data to string format.
 * @param: date: The data which is to be converted.
 * @return: The converted string.
 */
- (NSString *)convertDateToString:(NSDate *)date;

/**
 * This method displays the fault details from the data received from device.
 * @param: data: The fault data received from the device.
 */
- (void)showData:(NSData *)data;

/**
* This method verifies if present data received from the device is already received in previous reads.
 * @return: A Boolean value specifying if the data matches with the previous one.
 */
- (BOOL)isCurrentDataSameWithPreviousSavedOne;

/**
 * This method is called to read the fault data from the device.
 */
- (void)readFaultData;

/**
 * This method fetches the fault code associated with a given value.
 * @param: code: The value of fault received from the device.
 * @return: The corresponding fault code for the given integer value.
 */
- (NSString *)faultCodeWithCode:(NSInteger)code;

/**
 * This method fetches the fault status associated with a given value.
 * @param: code: The value of fault received from the device.
 * @return: The corresponding fault status for the given integer value.
 */
- (NSString *)faultWithCode:(NSInteger)code;

/**
 * This method fetches the fault records for a given date.
 * @param: date: The date for which faults are to be fetched.
 */
- (void)fetchDataWithDate:(NSDate *)date;

/**
 * This method is called when a peripheral is being disconnected from the mobile device.
 */
- (void)peripheralDisconnected;
@end
