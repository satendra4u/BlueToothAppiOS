//
//  BluetoothSharedData.h
//  BluetoothSample
//
//  Created by Kranthi on 18/01/16.
//  Copyright © 2016 Kranthi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFConstants.h"
#import "LFUtilities.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "LFPeripheral.h"

@protocol BlutoothSharedDataDelegate <NSObject>

@optional

/**
 * This method displays the devices found after scanning for new devices.
 * @param: devicesArray: List of devices found after scanning.
 */
- (void)showScannedDevices:(NSMutableArray *)devicesArray;

/**
 * This method displays characteristics discovered from the device.
 * @param: characteristicsArray: List of characteristics.
 */
- (void)showCharacterstics:(NSMutableArray *)charactersticsArray;

/**
 * This method displays an alert with a given message.
 * @param: msg: The message to be shown in the alert.
 */
- (void)showAlertWithText:(NSString *)msg;

/**
 * This method alert after writing data to device.
 * @param: isSuccess: Specifies if the write is success or not.
 */
- (void)showOperationCompletedAlertWithStatus:(BOOL)isSuccess;

/**
 * This method is called when configuration data is received for a given index.
 * @param: data: Data received from peripheral.
 */
- (void) configureServiceWithValue:(NSData *)data;

/**
 * This method is used to calculate the fault voltage values from the given data.
 * @param: data: The data received from the device to be converted.
 */
- (void)getFaultVoltageData:(NSData *)data;

/**
 * This method is used to calculate the fault current values from the given data.
 * @param: data: The data received from the device to be converted.
 */
- (void)getFaultCurrentData:(NSData *)data;

/**
 * This method is used to calculate the fault power values from the given data.
 * @param: data: The data received from the device to be converted.
 */
- (void)getFaultPowerData:(NSData *)data;

/**
 * This method is used to calculate the fault other values from the given data.
 * @param: data: The data received from the device to be converted.
 */
- (void)getFaultOtherData:(NSData *)data;

- (void)receivedDeviceMacWithData:(NSData*)data;

@end

@interface LFBluetoothManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    CBCentralManager *centralManager;
    CBPeripheral *discoveredPeripheral;
    
    NSMutableArray *devicesList;
    NSMutableArray *charactersticsList;
    
    
    NSMutableArray *savedPeripheralsDB;
}
/*
 @Description : It will assign by current Visible ViewController
 */
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *discoveredPeripheral;

@property (strong, nonatomic) LFPeripheral *selectedPeripheral;

@property (strong, nonatomic) LFFaultData *curFaultData;
@property (nonatomic) NSInteger tCurIndex;

@property (weak, nonatomic) id<BlutoothSharedDataDelegate> delegate;

@property (strong, nonatomic) NSString *selectedDevice;

@property (strong, nonatomic) NSString *selectedTag;

@property (nonatomic) BOOL  canContinueTimer;

@property (assign, nonatomic, getter=isDisplayCharacterstics) BOOL displayCharacterstics;

@property (assign, nonatomic, getter=isConfig) BOOL config;

@property (assign, nonatomic) BOOL realtime;

@property (assign, nonatomic) BOOL isWriting;

@property (assign, nonatomic) NSData *macData;
@property (strong, nonatomic) NSString *macString;
@property (strong, nonatomic) NSString *passwordVal;


@property (assign, nonatomic) BOOL isPasswordVerified;
@property (assign, nonatomic) NSData *configSeedData;


+ (LFBluetoothManager *)sharedManager;

- (void)createObjects;
- (void)destroyObjects;
/**
 * Performs the scan operation for peripherals.
 */
- (void)scan;

/**
 * Stops the scan operation.
 */
- (void)stopScan;

/**
 * This method connects mobile device to a peripheral at an index from the list of discovered peripherals.
 * @param: indexOfObj: Index of selected peripheral.
 */
- (void)connectToDevice:(NSInteger)indexOfObj;

/**
 * This method connects to the characteristics discovered for a particular device.
 * @param: characteristic: The Characteristic discovered.
 */
- (void)connectToCharactertics:(CBCharacteristic *)characterstic;

/**
 * This method writes configuration data to the peripheral.
 * @param data: The data to be written.
 */
- (void)writeConfigData:(NSData *)data;

/**
 * This method writes fault data to the peripheral.
 * @param data: The data to be written.
 */
- (void)writeConfigDataForFaultsList:(NSData *)data;

/**
 * @return: The characteristics list for a device.
 */
- (NSMutableArray *)getcharactersticsList;

/**
 *  @return: List of devices discovered.
 */
- (NSMutableArray *)getDevicesList;

/**
 * This method disconnected the peripheral which is connected to the mobile device.
 */
- (void)disconnectPeripheral;

/**
 * This method gets the all the real time values for the connected peripheral.
 */
- (void)fetchRealTimeValues;

/**
 * This method updates the configuration value.
 */
- (void)updateConfig;

/**
 * This method disconnects the device from the mobile.
 */
- (void)disconnectDevice;

/**
 * This method loads the faults for the connected peripheral in the background.
 */
- (void)readFaultData;

/**
 * This method stops the background loading of faults.
 */
- (void)stopFaultTimer;

/**
 * This method gets called whenever pairing is cancelled for a device after tapping.
 */
- (void)pairingCancelledForDeviceAtIndex:(NSInteger)indexOfObj;

- (void)discoverCharacteristicsForAuthentication;

- (void)resetConfigurationCharacteristics;

@end
