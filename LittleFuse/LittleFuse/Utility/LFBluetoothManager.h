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
- (void)showScannedDevices:(NSMutableArray *)devicesArray;

- (void)showCharacterstics:(NSMutableArray *)charactersticsArray;

- (void)showAlertWithText:(NSString *)msg;

- (void)showOperationCompletedAlert;

- (void) configureServiceWithValue:(NSData *)data;

- (void)getFaultVoltageData:(NSData *)data;

- (void)getFaultCurrentData:(NSData *)data;

- (void)getFaultPowerData:(NSData *)data;

- (void)getFaultOtherData:(NSData *)data;

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

@property (weak, nonatomic) id<BlutoothSharedDataDelegate> delegate;

@property (strong, nonatomic) NSString *selectedDevice;

@property (strong, nonatomic) NSString *selectedTag;

@property (assign, nonatomic, getter=isDisplayCharacterstics) BOOL displayCharacterstics;

@property (assign, nonatomic, getter=isConfig) BOOL config;

@property (assign, nonatomic) BOOL realtime;

@property (assign, nonatomic) BOOL isWriting;

+ (LFBluetoothManager *)sharedManager;

- (void)createObjects;

- (void)scan;

- (void)stopScan;

- (void)connectToDevice:(NSInteger)indexOfObj;

- (void)connectToCharactertics:(CBCharacteristic *)characterstic;

- (void)writeConfigData:(NSData *)data;

- (NSMutableArray *)getcharactersticsList;

- (NSMutableArray *)getDevicesList;

- (void)disconnectPeripheral;

- (void)fetchRealTimeValues;

- (void)updateConfig;

- (void)disconnectDevice;

@end
