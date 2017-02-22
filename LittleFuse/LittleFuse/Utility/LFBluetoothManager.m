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
#import "LFAuthUtils.h"

static LFBluetoothManager *sharedData = nil;

@interface LFBluetoothManager() {
    LFAuthUtils *authUtils;
    NSString *macString;
    NSData *configSeedData;
    NSString *password;
}
@end
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
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    if(discoveredPeripheral)
    {
        [centralManager cancelPeripheralConnection:discoveredPeripheral];
    }

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
    if(discoveredPeripheral)
    {
        [centralManager cancelPeripheralConnection:discoveredPeripheral];
    }
}

#pragma mark CBCentralManager Delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED < 10
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        //        if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
        //            [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
        //        }
        return;
    }

    #endif
    if (central.state != CBManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        //        if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
        //            [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
        //        }
        return;
    }
    
    [self scan];
    
}

/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
//    DLog(@"The name of the device is = %@", advertisementData[kLocalName]);
    if (RSSI.integerValue > 0) {
        return;
    }
    NSString *uuidString = [NSString stringWithFormat:@"%@", [[peripheral identifier] UUIDString]];
    
    NSArray *peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:@[[CBUUID UUIDWithString:uuidString]]];
    // // // DLog(@"><><><><><><saved devices identifers %@><><><><><", peripherals);
    if (peripherals.count > 0) {
        peripheral = [peripherals firstObject];
    }
    
    // // // DLog(@"Discovered %@ %@at %@", peripheral.name, peripheral.identifier, RSSI);
    NSString *name = peripheral.name;
    if (advertisementData[kLocalName]) {
        name = advertisementData[kLocalName];
    }
    NSData *advData ;
    if (advertisementData[kAdvertiseData]) {
        advData = advertisementData[kAdvertiseData];
        NSRange range = NSMakeRange(3, 1);
        
        advData = [advData subdataWithRange:range];
        // // // DLog(@"data %@", advData);
        
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
        LFPeripheral *savedVal = [[LFDataManager sharedManager] getDeviceWithIdentifier:discoveredDevice];
        if (savedVal) {
            discoveredDevice.paired = savedVal.isPaired;
            //discoveredDevice.configured = savedVal.isConfigured;
        }
    discoveredDevice.configured =isConfigured;

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
    // // // DLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    
    [self cleanup];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    DLog(@"Peripheral Connected");
    [LittleFuseNotificationCenter postNotificationName:PeripheralDidConnect object:nil];
    // Stop scanning
    [centralManager stopScan];
    // // // DLog(@"Scanning stopped");
    
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
    [LittleFuseNotificationCenter postNotificationName:PeripheralDidDisconnect object:nil];
    
    [[LFBluetoothManager sharedManager] setMacString:nil];
    [[LFBluetoothManager sharedManager] setMacData:nil];
    [[LFBluetoothManager sharedManager] setConfigSeedData:nil];

    if (_delegate && [_delegate respondsToSelector:@selector(deviceDisconnected)]) {
        [_delegate deviceDisconnected];
    }
    
}


#pragma mark - CBPeripheral Delegate


- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state {
    
    
    discoveredPeripheral = [state[CBCentralManagerRestoredStatePeripheralsKey] firstObject];
    discoveredPeripheral.delegate = self;
    // // // DLog(@"%s.. %@", __func__, discoveredPeripheral.name);
    
    //    NSString *str = [NSString stringWithFormat: @"%@ %@", @"Device: ", discoveredPeripheral.identifier.UUIDString];
    //    [self sendNotification:str];
}

/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        // // // DLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
   
    CBService *service = [peripheral.services lastObject];
    discoveredPeripheral = peripheral;
    [discoveredPeripheral discoverCharacteristics:nil forService:service];
    
}


- (void)discoverCharacteristicsForAuthentication {
        CBService *service = [discoveredPeripheral.services firstObject];
        [discoveredPeripheral discoverCharacteristics:nil forService:service];
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        // // // DLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    discoveredPeripheral = peripheral;
    discoveredPeripheral.delegate = self;
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        [discoveredPeripheral setNotifyValue:YES forCharacteristic:characteristic];
        DLog(@"charecterstics for notify: %@ \n\n",characteristic);
    }
    
    // Once this is complete, we just need to wait for the data to come in.
    NSMutableArray *uuidArr = [[NSMutableArray alloc]init];
    for (CBService *tService in discoveredPeripheral.services) {
        [uuidArr addObject:tService.UUID.UUIDString];
    }
    [charactersticsList removeAllObjects];
    charactersticsList = [service.characteristics mutableCopy];
    if (_delegate && [_delegate respondsToSelector:@selector(showCharacterstics:)]) {
        [_delegate showCharacterstics:charactersticsList];
    }
}

- (void)resetConfigurationCharacteristics {
    [charactersticsList removeAllObjects];
    [charactersticsList addObjectsFromArray:[discoveredPeripheral.services lastObject].characteristics];
}

/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//           DLog(@"%s", __func__);
    // called on read response
    if (error) {
        
       /* if (error.code == 15 && [error.localizedDescription isEqualToString:@"Encryption is insufficient."]) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
//                DLog(@"Canncelled pairing of the device");
                [_delegate showAlertWithText:[error localizedDescription]];
                [self scan];
                return;
            }
        }*/
        if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
            [_delegate showAlertWithText:[error localizedDescription]];
            //[self scan];
        }
        return;
    }
    NSData *readdata = [characteristic value];
    DLog(@"Reading data %@\n", readdata);
    if (![self isDisplayCharacterstics]) {
        //        if ([characteristic.UUID.UUIDString containsString:CONFIGURATION_CHARACTERSTICS]) {
        //            [LittleFuseNotificationCenter postNotificationName:SAVE_CONFIG_VALUES object:readdata];
        //        } else {
        [LittleFuseNotificationCenter postNotificationName:DISPLAY_TABBAR object:nil];
       
        //        }
        return;
    }
    if ([characteristic.UUID.UUIDString containsString:VOLTAGE_CHARACTERSTICS]) {
        [LittleFuseNotificationCenter postNotificationName:VOLTAGE_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:CURRENT_CHARACTERSTICS]) {
        [LittleFuseNotificationCenter postNotificationName:CURRENT_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:POWER_CHARACTERSTICS]) {
        [LittleFuseNotificationCenter postNotificationName:POWER_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:STATUS_CHARACTERSTICS]) {
        [LittleFuseNotificationCenter postNotificationName:EQUIPMENT_NOTIFICATION object:readdata];
        
    } else if ([characteristic.UUID.UUIDString containsString:CONFIGURATION_CHARACTERSTICS]) {
        if (_delegate && [_delegate respondsToSelector:@selector(configureServiceWithValue:)]) {
            [_delegate configureServiceWithValue:readdata];
        }
    } else if ([characteristic.UUID.UUIDString containsString:FAULT_CHARACTERSTICS]) {
        NSData *data = characteristic.value;
        uint8_t *bytesArr = (uint8_t*)[data bytes];
        if (bytesArr[1] == 0x01) { //success
            [self displayFaults];
        }
        else if (bytesArr[1] == 0x00) // polling
        {
            if (_faultPollingCount <10) {
                _faultPollingCount += 1;
                [self readValueForCharacteristic:characteristic];
                NSLog(@"\n========================== polling called ========================= ");
               

            }
            _faultPollingCount = 0;

        }
        else if (bytesArr[1] == 0x10) // end
        {
            if (_delegate && [_delegate respondsToSelector:@selector(restartFaultLoading)]) {
                [_delegate restartFaultLoading];
            }
            NSLog(@"\n========================== fault count ended ========================= ");
        }
         return;
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
    else if ([characteristic.UUID.UUIDString containsString:DEVICE_SERIAL_NUMBER_CHARACTERISTIC]) {
        if (_delegate && [_delegate respondsToSelector:@selector(receivedDeviceMacWithData:)]) {
            [_delegate receivedDeviceMacWithData:characteristic.value];
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
        //[self  readFaultData];
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(restartFaultLoading)]) {
            [_delegate restartFaultLoading];
        }
        NSLog(@"\n========================== fault count ended ========================= ");

      //  _tCurIndex = (_tCurIndex-1) + [[LFDataManager sharedManager] getTotalFaultsCount];
       // [self readFaultData];
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
    return;
    if (!_canContinueTimer) {
        _tCurIndex = 0;
        return;
    }
    [[LFBluetoothManager sharedManager] setConfig:NO];
    if (_tCurIndex > 1000) {
        return;
    }
   // DLog(@"Reading Fault Data of %d", (int)_tCurIndex);
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
    [[LFBluetoothManager sharedManager] setFaultPollingCount:0];

    [[LFBluetoothManager sharedManager] writeConfigDataForFaultsList:data1];
    _tCurIndex += 1;
}

- (void)restartFaultData {
    _tCurIndex = 0;
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
    // // // DLog(@"%s", __func__);
    if (error) {
         DLog(@"Error changing notification state: %@", error.localizedDescription);
        return;
    }
    if (characteristic.isNotifying) {
        DLog(@"Notification began on %@", characteristic);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // this method call after peripheral write response
//       DLog(@" %s", __func__);
    
    if (error) {
        if (_isWriting) {
            DLog(@"Error occured while writing data to hardware. Error is = %@", error);
            if (_delegate && [_delegate respondsToSelector:@selector(showOperationCompletedAlertWithStatus:withCharacteristic:)]) {
                [_delegate showOperationCompletedAlertWithStatus:NO withCharacteristic:characteristic];
            }
        }
        
        return;
    }
    discoveredPeripheral = peripheral;
    discoveredPeripheral.delegate = self;
    if (_isWriting) {
        if (_isPassWordChange) {
            [discoveredPeripheral readValueForCharacteristic:characteristic];
        }
         else if (_delegate && [_delegate respondsToSelector:@selector(showOperationCompletedAlertWithStatus:withCharacteristic:)]) {
            [_delegate showOperationCompletedAlertWithStatus:YES withCharacteristic:characteristic];
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
        selectedPeripheral = devicesList[indexOfObj];
        self.selectedDevice = selectedPeripheral.name;
        discoveredPeripheral = selectedPeripheral.peripheral;
        
        selectedPeripheral.paired = YES;
        [devicesList replaceObjectAtIndex:indexOfObj withObject:selectedPeripheral];
        [[LFDataManager sharedManager] updatePeripheralDetails:selectedPeripheral];
        // // // DLog(@"Connecting to peripheral %@", peripheral);
        [centralManager connectPeripheral:discoveredPeripheral options:nil];
    }
}

- (void)pairingCancelledForDeviceAtIndex:(NSInteger)indexOfObj {
    
    if (devicesList.count > indexOfObj) {
        LFPeripheral *device = devicesList[indexOfObj];
        device.paired = NO;
        selectedPeripheral = device;
        CBPeripheral *peripheral = device.peripheral;
        self.selectedDevice = device.name;
        discoveredPeripheral = peripheral;
        
        [devicesList replaceObjectAtIndex:indexOfObj withObject:device];
        // And connect
        // // // DLog(@"Connecting to peripheral %@", peripheral);
//        [[LFDataManager sharedManager] savePeripheralDetails:selectedPeripheral];
        [[LFDataManager sharedManager] updatePeripheralDetails:selectedPeripheral];
        // Search only for services that match our UUID
        //    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
//        [discoveredPeripheral discoverServices:nil];

        if (_delegate && [_delegate respondsToSelector:@selector(showScannedDevices:)]) {
            [_delegate showScannedDevices:devicesList];
        }
    }

}
- (void)writeConfigData:(NSData *)data
{
    //    // // // DLog(@"=======================================================");
           DLog(@"Writing data %@\n",  data);
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
//    DLog(@"Update config");
    [[LFDataManager sharedManager] updatePeripheralDetails:selectedPeripheral];
    
}

- (void)disconnectDevice
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 10
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
        else if (centralManager.state == CBCentralManagerStateUnknown) {//CBCentralManagerStateUnknown
            if (selectedPeripheral) {
                if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                    [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
                }
            }
        }
        
    }

#endif
    
    if (centralManager.state == CBManagerStatePoweredOn &&discoveredPeripheral && discoveredPeripheral.state == CBPeripheralStateConnected) {
        [self cleanup];
        //        [centralManager cancelPeripheralConnection:discoveredPeripheral];
    } else if (centralManager.state == CBManagerStatePoweredOn){
        if (devicesList.count) {
            [devicesList removeAllObjects];
        }
//        if (_delegate && [_delegate respondsToSelector:@selector(showScannedDevices:)]) {
//            [_delegate showScannedDevices:devicesList];
//        }
        [self scan];
    } else {
        if (centralManager.state == CBManagerStatePoweredOff) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
            }
        }
        else if (centralManager.state == CBManagerStateUnsupported) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"Your device does not support the Bluetooth Low Energy (BLE) services. Please try with a different device."];
            }
        }
        else if (centralManager.state == CBManagerStateResetting) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"The bluetooth connection is being reset.Please try again."];
            }
        }
        else if (centralManager.state == CBManagerStateUnauthorized) {
            if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                [_delegate showAlertWithText:@"Please authorize the application to use the bluetooth services."];
            }
        }
        else if (centralManager.state == CBManagerStateUnknown) {//CBCentralManagerStateUnknown
            if (selectedPeripheral) {
                if (_delegate && [_delegate respondsToSelector:@selector(showAlertWithText:)]) {
                    [_delegate showAlertWithText:@"Please switch on your bluetooth to communicate with the hardware."];
                }
            }
        }
        
    }
}


#pragma Mark - Data Conversion Methods


- (NSData *)getEncryptedPasswordData:(NSData *)writeData address:(short)address size:(short)size {
    if (authUtils == nil) {
        authUtils = [[LFAuthUtils alloc]init];
    }
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        [authUtils initWithPassKey:password andMacAddress:macString andSeed:configSeedData.bytes];
    }
    NSData * authCode = [authUtils computeAuthCode:writeData.bytes address:address size:size];
    
    return authCode;
}

- (NSData *) getCommandEncriptedDataWithValue:(NSData *) valueData andAddress:(Byte) address andLength:(Byte) length {
   
    Byte data[12];
    const char *bytes = [valueData bytes];
    
    for (int i = 0; i < 12; i++) {
        if (i < 8) {
            data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
        } else {
            if (i == 8) {
                data[i] = address;
            } else if (i == 10){
                data[i] = length;
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            } else {
                data[i] = (Byte)0x00;
            }
        }
    }
    
    NSData *data1 = [NSData dataWithBytes:data length:12];
    NSData *resultData = [self getEncryptedPasswordData:[data1 subdataWithRange:NSMakeRange(0, 8)] address:address size:length];
    NSMutableData *mutData = [NSMutableData dataWithData:data1];
    for (int i = 0; i<8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    return mutData;
}
- (NSData *) getCommandEncriptedDataForResetPasswordWithValue:(NSData *) valueData andAddress:(Byte) address andLength:(Byte) length {
    
    Byte data[12];
    const char *bytes = [valueData bytes];
    
    for (int i = 0; i < 12; i++) {
        if (i < 8) {
            data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
        } else {
            if (i == 8) {
                data[i] = address;
            } else if (i == 10){
                data[i] = length;
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            } else {
                data[i] = (Byte)0x00;
            }
        }
    }
    
    NSData *data1 = [NSData dataWithBytes:data length:12];
        return data1;
}
- (void) setPasswordString:(NSString *) passwordString {
    password = passwordString;
}
- (void) setConfigSeedData:(NSData *) seedData {
    configSeedData = seedData;
}
- (void) setMacString:(NSString *) macStr {
    macString = macStr;
}

- (NSData *) getConfigSeedData {
    return configSeedData;
}
- (NSString *) getMacString
{
    return macString;
}
- (NSString *) getPasswordString {
    return password;
}

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic{
    [discoveredPeripheral readValueForCharacteristic:characteristic];

}

@end
