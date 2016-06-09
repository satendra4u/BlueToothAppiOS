//
//  ViewController.h
//  LittleFuse
//  Advertising Screen/DeviceList screen
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFDevicesListController : LFBaseViewController

/**
 * This method performs rescan to find BLE devices and gets called after a specific time interval.
 */
- (void)reloadDevicesList;
/**
 * Removes all the alert which are currently visible on the screen.
 */
- (void)hideAllAlerts;

/**
 * This method is called when user taps on the device and characteristics are read.Then user is taken to the configuration screen or real time screen, based on whether device is configured or unconfigured.
 */
- (void)navigateToDislay:(NSNotification *)notification;
@end

