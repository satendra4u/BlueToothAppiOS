//
//  BluetoothSharedData.m
//  BluetoothSample
//
//  Created by Kranthi on 18/01/16.
//  Copyright © 2016 Kranthi. All rights reserved.
//

#import "LFBluetoothManager.h"

#define DEVICE_UUID @"6D70"
#define kLocalName  @"kCBAdvDataLocalName"
#define kAdvertiseData @"kCBAdvDataManufacturerData"

static LFBluetoothManager *sharedData = nil;


@implementation LFBluetoothManager

@synthesize discoveredPeripheral;
@synthesize centralManager, selectedPeripheral;

+ (LFBluetoothManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedData = [[self alloc] init];
    });
    return sharedData;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)createObjects
{
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    devicesList = [[NSMutableArray alloc] initWithCapacity:0];
    charactersticsList = [[NSMutableArray alloc] initWithCapacity:0];
    savedPeripheralsDB = [[NSMutableArray alloc] initWithCapacity:0];
    self.curFaultData = [[LFFaultData alloc]init];
    
}
- (void)destroyObjects {
    centralManager = nil;
    devicesList = nil;
    charactersticsList = nil;
    savedPeripheralsDB = nil;
    discoveredPeripheral = nil;
    selectedPeripheral = nil;
    self.curFaultData = nil;
    
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

- (void)scan
{
    if (discoveredPeripheral && discoveredPeripheral.state == CBPeripheralStateConnected) {
        [centralManager cancelPeripheralConnection:discoveredPeripheral];
    }
    [devicesList removeAllObjects];
    discoveredPeripheral = nil;
    savedPeripheralsDB = [[LFDataManager sharedManager] fetchSavedPeripherals];
    [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:DEVICE_UUID]]
                                           options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}]; //@[[CBUUID UUIDWithString:DEVICE_UUID]]
}

- (void)stopScan
{
    [centralManager stopScan];
}

- (void)cleanup
{
    
    // See if we are subscribed to a characteristic on the peripheral
    if (discoveredPeripheral.services != nil) {
        for (CBService *service in discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    // It is notifying, so unsubscribe
                    [discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                    
                    // And we're done.
                    //return;
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [centralManager cancelPeripheralConnection:discoveredPeripheral];
    
}

#pragma mark CBCentralManager Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        //        if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
        //            [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
        //        }
        return;
    }
    
    [self scan];
    
}

extern BOOL userIsAuthorized;

/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // We are on the device list (advertising) page. So disable any authorization that was previously granted.
    userIsAuthorized = FALSE;
    
    // Reject any where the value is above reasonable range
    
    if (RSSI.integerValue > 0) {
        return;
    }
    NSString *uuidString = [NSString stringWithFormat:@"%@", [[peripheral identifier] UUIDString]];
    
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[[CBUUID UUIDWithString:uuidString]]];
    // // // NSLog(@"><><><><><><saved devices identifers %@><><><><><", peripherals);
    peripheral = [peripherals firstObject];
    
    // // // NSLog(@"Discovered %@ %@at %@", peripheral.name, peripheral.identifier, RSSI);
    NSString *name = peripheral.name;
    if (advertisementData[kLocalName]) {
        name = advertisementData[kLocalName];
    }
    NSData *advData ;
    if (advertisementData[kAdvertiseData]) {
        advData = advertisementData[kAdvertiseData];
        NSRange range = NSMakeRange(3, 1);
        
        advData = [advData subdataWithRange:range];
        // // // NSLog(@"data %@", advData);
        
    }
    if (!name || !advData) {
        return;
    }
    Byte notConfigByte[1], configByte[1];
    BOOL isConfigured;
    notConfigByte[0] = 0x00;
    configByte[0] = 0x01;
    if ([advData isEqualToData:[[NSData alloc] initWithBytes:notConfigByte length:1]]) {
        isConfigured = NO;
    } else if ([advData isEqualToData:[[NSData alloc] initWithBytes:configByte length:1]]) {
        isConfigured = YES;
    }
    NSInteger rssiVal = RSSI.integerValue + 100;
    NSDictionary *dict = @{kPeripheral : peripheral, kRssi : [NSNumber numberWithInteger:rssiVal], kName : name, kIdentifier : peripheral.identifier.UUIDString, kConfigStatus : @(isConfigured)};
//    DLog(@"Discovered device property dict = %@", dict);
    LFPeripheral *discoveredDevice = [[LFPeripheral alloc] initWithDict:dict];
    //This code is fetching data from local cache where data is saved.So configuration status is not correct.
    //    LFPeripheral *savedVal = [[LFDataManager sharedManager] getDeviceWithIdentifier:discoveredDevice];
    //    if (savedVal) {
    //        discoveredDevice.paired = savedVal.isPaired;
    //        discoveredDevice.configured = savedVal.isConfigured;
    //    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.identifer MATCHES[cd] %@ ", peripheral.identifier.UUIDString];
    NSArray *fileteredArr = [devicesList filteredArrayUsingPredicate:predicate];
    if ([fileteredArr count]) {
        LFPeripheral *previousSavedDevice = [fileteredArr firstObject];
        NSInteger index = [devicesList indexOfObject:previousSavedDevice];
        discoveredDevice.configured = previousSavedDevice.isConfigured;
        discoveredDevice.paired = previousSavedDevice.isPaired;
        
        [devicesList replaceObjectAtIndex:index withObject:discoveredDevice];
    } else {
        [devicesList addObject:discoveredDevice];
        
    }
    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"rssi" ascending:NO]];
    [devicesList sortUsingDescriptors:sortDescriptors];
    
    if (_delegate && [_delegate respondsToSelector:@selector(showScannedDevices:)]) {
        [_delegate showScannedDevices:devicesList];
    }
    //If Bluetooth lost connection it should connect after scan
    if (self.isDisplayCharacterstics && [discoveredPeripheral isEqual:peripheral]) {
        [centralManager connectPeripheral:peripheral options:nil];
    }
}



/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // // // NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    NSLog(@"Peripheral Connected");
    [[NSNotificationCenter defaultCenter] postNotificationName:PeripheralDidConnect object:nil];
    // Stop scanning
    [centralManager stopScan];
    // // // NSLog(@"Scanning stopped");
    
    discoveredPeripheral = peripheral;
    // Make sure we get the discovery callbacks
    discoveredPeripheral.delegate = self;
    
    selectedPeripheral.peripheral = discoveredPeripheral;
    [[LFDataManager sharedManager] savePeripheralDetails:selectedPeripheral];
    // Search only for services that match our UUID
    //    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    [discoveredPeripheral discoverServices:nil];
    
}

/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    discoveredPeripheral = nil;
    [devicesList removeAllObjects];
//    if (_delegate && [_delegate respondsToSelector:@selector(showScannedDevices:)]) {
//        [_delegate showScannedDevices:devicesList];
//    }//It causes the flickering effect.
    //
    //    // We're disconnected, so start scanning again
    [self scan];
    //    [centralManager connectPeripheral:discoveredPeripheral options:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:PeripheralDidDisconnect object:nil];
    
}


#pragma mark - CBPeripheral Delegate


- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state {
    
    
    discoveredPeripheral = [state[CBCentralManagerRestoredStatePeripheralsKey] firstObject];
    discoveredPeripheral.delegate = self;
    // // // NSLog(@"%s.. %@", __func__, discoveredPeripheral.name);
    
    //    NSString *str = [NSString stringWithFormat: @"%@ %@", @"Device: ", discoveredPeripheral.identifier.UUIDString];
    //    [self sendNotification:str];
}

/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        // // // NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    CBService *service = [peripheral.services lastObject];
    discoveredPeripheral = peripheral;
    [discoveredPeripheral discoverCharacteristics:nil forService:service];
    
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        // // // NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    discoveredPeripheral = peripheral;
    discoveredPeripheral.delegate = self;
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        [discoveredPeripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
    
    // Once this is complete, we just need to wait for the data to come in.
    [charactersticsList removeAllObjects];
    charactersticsList = [service.characteristics mutableCopy];
    if (_delegate && [_delegate respondsToSelector:@selector(showCharacterstics:)]) {
        [_delegate showCharacterstics:charactersticsList];
    }
}

/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//           NSLog(@"%s", __func__);
    if (error) {
        if (error.code == 15 && [error.localizedDescription isEqualToString:@"Encryption is insufficient."]) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:[error localizedDescription]];
                [self scan];
                return;
            }
        }
        if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
            [_delegate showAlertWithText:[error localizedDescription]];
            [self scan];
        }
        return;
    }
    NSData *readdata = [characteristic value];
    if (![self isDisplayCharacterstics]) {
        //        if ([characteristic.UUID.UUIDString containsString:CONFIGURATION_CHARACTERSTICS]) {
        //            [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_CONFIG_VALUES object:readdata];
        //        } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:DISPLAY_TABBAR object:nil];
       
        //        }
        return;
    }
    if ([characteristic.UUID.UUIDString containsString:VOLTAGE_CHARACTERSTICS]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VOLTAGE_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:CURRENT_CHARACTERSTICS]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:POWER_CHARACTERSTICS]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:POWER_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:STATUS_CHARACTERSTICS]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:EQUIPMENT_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:CONFIGURATION_CHARACTERSTICS]) {
        if (_delegate && [_delegate respondsToSelector:@selector(configureServiceWithValue:)]) {
            [_delegate configureServiceWithValue:readdata];
        }
    } else if ([characteristic.UUID.UUIDString containsString:FAULT_CHARACTERSTICS]) {
        NSData *data = characteristic.value;
        uint8_t *bytesArr = (uint8_t*)[data bytes];
        if (bytesArr[1] == 0x01) {
            [self displayFaults];
        }
        
    } else if ([characteristic.UUID.UUIDString containsString:VOLATAGE_FAULT_CHARACTERSTIC]) {
        if (_delegate && [_delegate respondsToSelector:@selector(getFaultVoltageData:)]) {
            [_delegate getFaultVoltageData:readdata];
        }
        else {
            if (!self.curFaultData) {
                self.curFaultData = [[LFFaultData alloc]init];
            }
            NSRange range = NSMakeRange(2, 4);
            
            NSData *data1 = [readdata subdataWithRange:range];
            
            NSInteger dateandTime = [LFUtilities getValueFromHexData:data1];
            
            NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:(dateandTime)];
            
            _curFaultData.date = date;
            
            _curFaultData.voltage = readdata;
        }
        
    } else if ([characteristic.UUID.UUIDString containsString:CURRENT_FAULT_CHARACTERSTIC]) {
        if (_delegate && [_delegate respondsToSelector:@selector(getFaultCurrentData:)]) {
            [_delegate getFaultCurrentData:readdata];
        }
        else {
            if (!_curFaultData) {
                _curFaultData = [[LFFaultData alloc]init];
            }
            _curFaultData.current = readdata;
        }
        
    } else if ([characteristic.UUID.UUIDString containsString:POWER_FAULT_CHARACTERSTIC]) {
        if (_delegate && [_delegate respondsToSelector:@selector(getFaultPowerData:)]) {
            [_delegate getFaultPowerData:readdata];
        }
        else {
            if (!_curFaultData) {
                _curFaultData = [[LFFaultData alloc]init];
            }
            _curFaultData.power = readdata;
        }
        
    } else if ([characteristic.UUID.UUIDString containsString:OTHER_FAULT_CHARACTERSTIC]) {
        if (!_canContinueTimer) {
            return;
        }
        if (_delegate && [_delegate respondsToSelector:@selector(getFaultOtherData:)]) {
            [_delegate getFaultOtherData:readdata];
        }
        else {
            [self getFaultOtherData:readdata];
        }
        
    }
}

- (void)getFaultOtherData:(NSData *)data
{
    _curFaultData.other = data;
    // To save the Data
    if (![self isCurrentDataSameWithPreviousSavedOne]) {
            [[LFDataManager sharedManager] saveFaultDetails:_curFaultData WithPeripheral:selectedPeripheral];
        _curFaultData = nil;
        _curFaultData = [[LFFaultData alloc] init];
        [self  readFaultData];
    } else {
        _tCurIndex = (_tCurIndex-1) + [[LFDataManager sharedManager] getTotalFaultsCount];
        [self readFaultData];
    }

}

- (BOOL)isCurrentDataSameWithPreviousSavedOne
{
    LFFaultData *fault = [[LFDataManager sharedManager] getSavedDataWithDate:_curFaultData.date];
    if ([fault.voltage isEqualToData:_curFaultData.voltage] ) {
        return YES;
    }
    return NO;
    
}


- (void)readFaultData
{
    if (!_canContinueTimer) {
        _tCurIndex = 1;
        return;
    }
    [[LFBluetoothManager sharedManager] setConfig:NO];
    if (_tCurIndex > 1000) {
        return;
    }
    DLog(@"Reading Fault Data of %d", (int)_tCurIndex);
    Byte data[20];
    char* bytes = (char*) &_tCurIndex;
    int convertedLen = sizeof(bytes)/2;
    
    for (int i = 0; i < 20; i++) {
        if (i > 1 && (i-2)<convertedLen) {
            data[i] = (Byte)bytes[i-2];
        } else {
            if (i== 0 ) {
                data[i] = (Byte)0x01;
            }  else {
                data[i] = (Byte)0x00;
            }
        }
    }
    
    NSData *data1 = [NSData dataWithBytes:data length:20];
//    [[LFBluetoothManager sharedManager] writeConfigData:data1];//Old code

    [[LFBluetoothManager sharedManager] writeConfigDataForFaultsList:data1];
    _tCurIndex += 1;
}

- (void)restartFaultData {
    _tCurIndex = 1;
    [self readFaultData];
}

- (void)stopFaultTimer {
    _tCurIndex = 1001;
    _canContinueTimer = NO;
}

/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // // // NSLog(@"%s", __func__);
    if (error) {
        // // // NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//       NSLog(@"%s", __func__);
    
    if (error) {
        // // // NSLog(@"error %@", error.localizedDescription);
        if (_isWriting) {
            DLog(@"Error occured while writing data to hardware. Error is = %@", error);
            if (_delegate && [_delegate respondsToSelector:@selector(showOperationCompletedAlertWithStatus:)]) {
                [_delegate showOperationCompletedAlertWithStatus:NO];
            }
        }
        
        return;
    }
    discoveredPeripheral = peripheral;
    discoveredPeripheral.delegate = self;
    if (_isWriting) {
        if (_delegate && [_delegate respondsToSelector:@selector(showOperationCompletedAlertWithStatus:)]) {
            [_delegate showOperationCompletedAlertWithStatus:YES];
        }
    } else {
        [discoveredPeripheral readValueForCharacteristic:characteristic];
    }
    
    
    
    
}
#pragma mark Custom methods
- (NSMutableArray *)getcharactersticsList
{
    return charactersticsList;
}
- (void)connectToCharactertics:(CBCharacteristic *)characterstic
{
    discoveredPeripheral.delegate = self;
    [discoveredPeripheral readValueForCharacteristic:characterstic];
}

- (void)connectToDevice:(NSInteger)indexOfObj
{
    discoveredPeripheral = nil;
    
    if (devicesList.count > indexOfObj) {
        LFPeripheral *device = devicesList[indexOfObj];
        selectedPeripheral = device;
        CBPeripheral *peripheral = device.peripheral;
        self.selectedDevice = device.name;
        discoveredPeripheral = peripheral;
        
        device.paired = YES;
        [devicesList replaceObjectAtIndex:indexOfObj withObject:device];
        // And connect
        // // // NSLog(@"Connecting to peripheral %@", peripheral);
        [centralManager connectPeripheral:peripheral options:nil];
    }
}


- (void)writeConfigData:(NSData *)data
{
    //    // // // NSLog(@"=======================================================");
    //    // // // NSLog(@"%s data-->%@", __func__, data);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isConfig]) {
            [discoveredPeripheral writeValue:data forCharacteristic:charactersticsList[4] type:CBCharacteristicWriteWithResponse];
        } else {
            [discoveredPeripheral writeValue:data forCharacteristic:charactersticsList[5] type:CBCharacteristicWriteWithResponse];
        }
        
    });
    
}

- (void)writeConfigDataForFaultsList:(NSData *)data {
    dispatch_async(dispatch_get_main_queue(), ^{
        [discoveredPeripheral writeValue:data forCharacteristic:charactersticsList[5] type:CBCharacteristicWriteWithResponse];
    });
}

- (void)disconnectPeripheral
{
    [self cleanup];
}

- (void)fetchRealTimeValues
{
    [charactersticsList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CBCharacteristic *charactestic = charactersticsList[idx];
        [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
        if (idx == 3) {
            *stop = YES;
        }
        
    }];
    
}

- (NSMutableArray *)getDevicesList
{
    return devicesList;
}


- (void)displayFaults
{
    for (int i = 6; i < charactersticsList.count; i++) {
        CBCharacteristic *charactestic = charactersticsList[i];
        [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
        
    }
}

- (void)updateConfig
{
    NSInteger index = [devicesList indexOfObject:selectedPeripheral];
    
    selectedPeripheral.configured = YES;
    
    [devicesList replaceObjectAtIndex:index withObject:selectedPeripheral];
    [[LFDataManager sharedManager] updatePeripheralDetails:selectedPeripheral];
    
}

- (void)disconnectDevice
{
    if (centralManager.state == CBCentralManagerStatePoweredOn &&discoveredPeripheral && discoveredPeripheral.state == CBPeripheralStateConnected) {
        [self cleanup];
        //        [centralManager cancelPeripheralConnection:discoveredPeripheral];
    } else if (centralManager.state == CBCentralManagerStatePoweredOn){
        if (devicesList.count) {
            [devicesList removeAllObjects];
        }
//        if (_delegate && [_delegate respondsToSelector:@selector(showScannedDevices:)]) {
//            [_delegate showScannedDevices:devicesList];
//        }
        [self scan];
    } else {
        if (centralManager.state == CBCentralManagerStatePoweredOff) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
            }
        }
        else if (centralManager.state == CBCentralManagerStateUnsupported) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"Your device does not support the Bluetooth Low Energy (BLE) services. Please try with a different device."];
            }
        }
        else if (centralManager.state == CBCentralManagerStateResetting) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"The bluetooth connection is being reset.Please try again."];
            }
        }
        else if (centralManager.state == CBCentralManagerStateUnauthorized) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"Please authorize the application to use the bluetooth services."];
            }
        }
        else if (centralManager.state == CBCentralManagerStateUnknown) {
            if (selectedPeripheral) {
                if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                    [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
                }
            }
        }
        
    }
}

@end
