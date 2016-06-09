//
//  LFRealTimeViewController.h
//  LittleFuse
//
//  Created by Kranthi on 22/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFRealTimeViewController : LFBaseViewController
@property (weak, nonatomic) IBOutlet UILabel *lblSystemStatus;

/**
 * This method performs background loading of faults and repeats to check for any new faults after a specific time interval.
 */
- (void)updateFaultData;

/**
 * This method reloads the real time information once in a given time interval.
 */
- (void)refreshCurrentController;

/**
 * Calculate voltage values from data
 */
- (void)voltageCharcterstics:(NSData *)data;

/**
 * Calculate current characteristics from received data
 */
- (void)currentCharcterstics:(NSData *)data;

/**
 * This method rounds off the given value as per the required format
 */
- (NSString *)changeCurrentAsRequired:(float)val;

/**
 * Calculates the power characteristics from the received data
 */
- (void)powerCharacterstics:(NSData *)data;

/**
 * Calculates the equipment characteristics from the received data and handles the fault or warning status received, if any.
 */
- (void)equipmentStatus:(NSData *)data;

/**
 * This method retrieves the corresponding fault value for a given fault code.
 * @param: dataString: This contains the value of the fault data received from the device.
 * @return: The fault string for the provided fault value.
 */
- (NSString *)getFaultValueForDataString:(NSString *)dataString;

/**
 * This method returns the warning status for a given data.
 * @param: dataString: This contains the warning data from the device.
 * @return: Warning status for the given data.
 */
- (NSString *)getCorrectStringForWarningString:(NSString *)dataString;

/**
 * Changes the endian of the given hexadecimal data.
 * @param: data: Data to be converted to other endian.
 * @return: Hex val with opposite endian.
 */
- (NSString *)getDataStringFromData:(NSData *)data;

/**
 * Read characteristics from the BLE for a given index.
 * @param: index: This contains the index for which characteristics are to be read.
 */
- (void)readCharactisticsWithIndex:(NSInteger)index;

/**
 * This is a callback received once the hardware gets disconnected from the mobile device.
 */
- (void)peripheralDisconnected;



@end
