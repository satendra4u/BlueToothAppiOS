//
//  LFFaultsDetailsController.h
//  Littlefuse
//
//  Created by Kranthi on 08/03/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFBaseViewController.h"
#import "LFFaultData.h"

@interface LFFaultsDetailsController : LFBaseViewController

@property (strong, nonatomic) LFFaultData *faultData;
@property (strong, nonatomic) NSString *errorType;
@property (strong, nonatomic) NSString *errorDate;

/**
 * This method performs the background loading of the faults and checks for new faults after a specific time intertval.
 */
- (void)updateFaultData;

/**
 * This method converts the currently displaying fault data into required format to display on the screen.
 */
- (void)convertFaultData;

/**
 * This method converts the voltage data for the displaying fault into the required format to be shown on the screen.
 * @param: data: The data to be converted.
 */
- (void)convertDataToVoltageDisplay:(NSData *)data;

/**
 * This method converts the current data for the displaying fault into the required format to be shown on the screen.
 * @param: data: The data to be converted.
 */
- (void)convertDataToCurrentDisplay:(NSData *)data;

/**
 * This method converts the power data for the displaying fault into the required format to be shown on the screen.
 * @param: data: The data to be converted.
 */
- (void)convertToPowerDisplay:(NSData *)data;

/**
 * This method converts the other data for the displaying fault into the required format to be shown on the screen.
 * @param: data: The data to be converted.
 */
- (void)convertToOtherData:(NSData *)data;

/**
 * This method rounds off the given current value and returns the converted value.
 * @param: val: The value to be rounded off.
 * @return: The converted value.
 */
- (NSString *)changeCurrentAsRequired:(float)val;

/**
 * This method is called when hardware gets disconnected from the mobile device.
 */
- (void)peripheralDisconnected;
@end
