//
//  ConfigurationViewController.h
//  LittleFuse
//
//  Created by Kranthi on 27/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFConfigurationViewController : LFBaseViewController

/**
 * Stop the loading indicator which is displayed on the screen.
 */
- (void)stopIndicator;

/**
 * Performs background loading of faults in the background thread and repeats it after a time interval.
 */
- (void)updateFaultData;



/**
 * This method reads characteristic data for a given index
 * @param: index: The index for which characteristics are to be read.
 */
- (void)readCharactisticsWithIndex:(NSInteger)index;

/**
 * This method rounds off the given value according to the desired format and returns the new value.
 * @param: dataVal: The value which is to be rounded off.
 * @return: Value after rounding off.
 */
- (NSString *)getConvertedStringForValue:(NSUInteger)dataVal;

/**
 * This method calculates the value to be displayed to the user based on the given data and format of the data to be displayed.
 * @param: data: The data which is to be converted.
 * @param: formate: The format of the converted data to be shown.
 */
- (void)getValuesFromData:(NSData *)data withForamte:(NSString *)formate;

/**
 * This method is used to write to the BLE hardware after updating value at a particular index.
 * @param: index: The index for which data is to be read.
 * @param: val: Value to be written to the hardware.
 */
- (void)writeDataToIndex:(NSInteger)index withValue:(double)val;

/**
 * This method is used in the case when we do not receive a callback from device when we update the data, but still data is updated.
 * @discussion Here, we verify if we recieve a callback after a time interval, and if we do not recieve callback, then we remove the loading screen and read the same data again from the device.
 */
- (void)checkTimeOut;

/**
 * This method is called when ever a device is disconnected from the mobile.Then app is moved to the advertising/device list screen.
 */
- (void)peripheralDisconnected;
@end
