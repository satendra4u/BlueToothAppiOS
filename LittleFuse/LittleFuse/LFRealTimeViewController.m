//
//  LFRealTimeViewController.m
//  LittleFuse
//
//  Created by Kranthi on 22/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFRealTimeViewController.h"
#import "LFTabbarController.h"
#import "LFCharactersticDisplayCell.h"
#import "LFBluetoothManager.h"
#import "LFNavigationBar.h"
#import "LFDisplay.h"
#import "LFNavigationController.h"
#import "LFEditingViewController.h"
#import "LFAuthUtils.h"

@interface LFRealTimeViewController () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate, BlutoothSharedDataDelegate,EditingDelegate>
{
    
    BOOL canContinueTimer;
    
    __weak IBOutlet UITableView *tblDisplay;
    __weak IBOutlet UILabel *lblDeviceName;
    
    NSMutableArray *configArr;
    NSMutableArray *sectionArray;
    
    NSData *unbalanceCurrentData;
    NSInteger refreshTimeInterval;
    CGPoint currentContentOffset;
    
    //NSString *passwordVal;
    //NSString *macString;
    
    //NSData *configSeedData;
    NSData *prevWrittenData;


    BOOL isFetchingMacOrSeedData;
    BOOL isWrite;
    BOOL isReRead;
    BOOL isVerifyingPassword;


    LFAuthUtils *authUtils;
    
    LFEditingViewController *editing;
}
@end

@implementation LFRealTimeViewController

const char realMemMap[] = { 0x56, 0x5e,0x0076};
const char realMemFieldLens[] = { 0x02, 0x02,0x02};


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sectionArray = [[NSMutableArray alloc] initWithObjects:@[], @[], @[], @[], nil];
    configArr = [[NSMutableArray alloc] initWithCapacity:0];
    refreshTimeInterval = 1;
    NSString *name = [[LFBluetoothManager sharedManager] selectedDevice];
    name = [name substringToIndex:name.length-4];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Device ID: %@", name]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(10, string.length-10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:AERIAL_REGULAR size:15.0] range:NSMakeRange(0, 10)];
    lblDeviceName.attributedText = string;

    _lblSystemStatus.adjustsFontSizeToFitWidth = YES;
    
    
    [self readCharactisticsWithIndex:2];

    [tblDisplay registerNib:[UINib nibWithNibName:@"LFCharactersticDisplayCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:CHARACTER_DISPLAY_CELL_ID];
    [tblDisplay setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [LittleFuseNotificationCenter addObserver:self selector:@selector(getCurrentData:) name:CURRENT_NOTIFICATION object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(getPowerData:) name:POWER_NOTIFICATION object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(getVoltageData:) name:VOLTAGE_NOTIFICATION object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(getTimersData:) name:REAL_TIME_CONFIGURATION object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(getEquipmentData:) name:EQUIPMENT_NOTIFICATION object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(peripheralDisconnected) name:PeripheralDidDisconnect object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

/**
 * This method is called when app enters background.
 * Then, the peripheral is disconnected from the mobile device.
 */
- (void)appEnteredBackground {
    [[LFBluetoothManager  sharedManager] disconnectDevice];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[LFBluetoothManager sharedManager] setDelegate:nil];
    [[LFBluetoothManager sharedManager] setDelegate:self];
    LFTabbarController *tabBarController = (LFTabbarController *)self.tabBarController;
    [tabBarController setEnableRefresh:NO];
    canContinueTimer = YES;
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    if (batteryLevel > 0.20) {
        refreshTimeInterval = 1;
    }
    else {
        refreshTimeInterval = 600;
    }
    //refreshTimeInterval = 600;
    currentContentOffset = tblDisplay.contentOffset;
    [self refreshCurrentController];
    
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:10];
   /* if ([LFBluetoothManager sharedManager].macData) {
        [self receivedDeviceMacWithData:[LFBluetoothManager sharedManager].macData];
    }*/
   
}


- (void)updateFaultData {
    if(canContinueTimer) {
        [LFBluetoothManager sharedManager].tCurIndex = 0;
        [LFBluetoothManager sharedManager].canContinueTimer = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[LFBluetoothManager sharedManager] readFaultData];
        });
        [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:180];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    canContinueTimer = NO;
    [[LFBluetoothManager sharedManager] setRealtime:NO];

    [[LFBluetoothManager sharedManager] stopFaultTimer];
   // [[LFBluetoothManager sharedManager] setDelegate:nil];

   //
}
- (void)viewDidDisappear:(BOOL)animated
{
   // [[LFBluetoothManager sharedManager] setDelegate:nil];
}


- (void)refreshCurrentController {
    /*if (!canContinueTimer) {
        return;
    }*/
    currentContentOffset = tblDisplay.contentOffset;
    [[LFBluetoothManager sharedManager] fetchRealTimeValues];
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    if (batteryLevel > 0.20) {
        refreshTimeInterval = 1;
    }
    else {
        refreshTimeInterval = 600;
    }
     //refreshTimeInterval = 600;
    if (!canContinueTimer) {
        return;
    }
    [self performSelector:@selector(refreshCurrentController) withObject:nil afterDelay:refreshTimeInterval];

}

/**
 * This method is called once Voltage data is received from device.
 */
- (void)getVoltageData:(NSNotification *)notification
{
    if (!canContinueTimer) {
        return;
    }
    [self voltageCharcterstics:[notification object]];
}

/**
 * This method is called once Current data is received from device.
 */
- (void)getCurrentData:(NSNotification *)notification
{
    if (!canContinueTimer) {
        return;
    }
    [self currentCharcterstics:[notification object]];
    
}

/**
 * This method is called once equipment data is received from device.
 */
- (void)getEquipmentData:(NSNotification *)notificaition
{
    if (!canContinueTimer) {
        return;
    }
    [self equipmentStatus:[notificaition object]];
}

/**
 * This method is called once power data is received from device.
 */
- (void)getPowerData:(NSNotification *)notification
{
    if (!canContinueTimer) {
        return;
    }
    [self powerCharacterstics:[notification object]];
}

- (void)voltageCharcterstics:(NSData *)data
{
    if (!canContinueTimer) {
        return;
    }
    //Reverse the data
    
    NSInteger len = 4;
    NSData *data0, *data1, *data2, *data3, *data4, *data5, *data6;
    NSRange range = NSMakeRange(0, len);
    
    data0 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data1 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data2 = [data subdataWithRange:range];
    len = 2;
    range = NSMakeRange(range.location + range.length, len);
    data3 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data4 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data5 = [data subdataWithRange:range];
    len = 1;
    range = NSMakeRange(range.location + range.length, len);
    data6 = [data subdataWithRange:range];
    
    DLog(@" Voltage %@\t%@ \t%@ \t%@ \t %@ \t %@ \t%@", data0,data1, data2, data3, data4, data5, data6);
    
    NSInteger vrms0 = [LFUtilities getValueFromHexData:data0];
    
    NSInteger vrms1 = [LFUtilities getValueFromHexData:data1];
    
    NSInteger vrms2 = [LFUtilities getValueFromHexData:data2];
    
    NSInteger vunb = [LFUtilities getValueFromHexData:data3];
    
    unbalanceCurrentData = data4;
    
    
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"L1-L2" Value:[NSString stringWithFormat:@"%ld VAC", lroundf(vrms0/100.0)] Code:@"L1-L2"];
    
    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"L2-L3" Value:[NSString stringWithFormat:@"%ld VAC", lroundf(vrms1/100.0)] Code:@"L2-L3"];
    
    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"L3-L1" Value:[NSString stringWithFormat:@"%ld VAC", lroundf(vrms2/100.0)] Code:@"L3-L1"];
    
    LFDisplay *vunbaised = [[LFDisplay alloc] initWithKey:@"Voltage Unbalance" Value:[NSString stringWithFormat:@"%0.1f %%", (vunb/100.0)] Code:@"VUB"];

    NSArray *voltgaeDetails = @[aTob, bToc, cToa, vunbaised];
    [sectionArray replaceObjectAtIndex:0 withObject:voltgaeDetails];
}

- (void)currentCharcterstics:(NSData *)data
{
    if (!canContinueTimer) {
        return;
    }
    NSInteger len = 4;
    NSData *data0, *data1, *data2, *data3, *data4, *data5;
    NSRange range = NSMakeRange(0, len);
    
    data0 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data1 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data2 = [data subdataWithRange:range];
    len = 2;
    range = NSMakeRange(range.location + range.length, len);
    data3 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data4 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data5 = [data subdataWithRange:range];
    
    DLog(@" Current %@\t%@ \t%@ \t%@ \t %@ \t %@ ", data0,data1, data2, data3, data4, data5);
    
    NSInteger vrms0 = [LFUtilities getValueFromHexData:data0];
    
    NSInteger vrms1 = [LFUtilities getValueFromHexData:data1];
    
    NSInteger vrms2 = [LFUtilities getValueFromHexData:data2];
    
    
    NSInteger vunb = [LFUtilities getValueFromHexData:unbalanceCurrentData];

    NSString *type = [LFUtilities conversionJFormate:data3];
    
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Ø A" Value:[NSString stringWithFormat:@"%@", [self changeCurrentAsRequired:vrms0/100.0]] Code:@"A"];
    
    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"Ø B" Value:[NSString stringWithFormat:@"%@", [self changeCurrentAsRequired:vrms1/100.0]] Code:@"B"];
    
    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"Ø C" Value:[NSString stringWithFormat:@"%@", [self changeCurrentAsRequired:vrms2/100.0]] Code:@"C"];
    
    LFDisplay *vunbaised = [[LFDisplay alloc] initWithKey:@"Current Unbalance" Value:[NSString stringWithFormat:@"%0.1f %%", (vunb/100.0)] Code:@"CUB"];
    
    LFDisplay *pfa = [[LFDisplay alloc] initWithKey:@"Power Factor" Value:type Code:@"PF"];
    
    NSArray *currentDetails = @[aTob, bToc, cToa, vunbaised];
    NSArray *powerDetails = @[pfa];
    if (!sectionArray) {
        sectionArray = [[NSMutableArray alloc] initWithObjects:@[], @[], @[], @[], nil];
    }
    if (sectionArray.count == 1) {
        sectionArray[1] = @[];
    }
    if (sectionArray.count == 2) {
        sectionArray[2] = @[];
    }
    [sectionArray replaceObjectAtIndex:1 withObject:currentDetails];
    [sectionArray replaceObjectAtIndex:2 withObject:powerDetails];
}

- (NSString *)changeCurrentAsRequired:(float)val
{
    NSString *convertedString;
    
    if (val < 5) {
        convertedString = [NSString stringWithFormat:@"%0.2f amps", val];
    } else if (val >= 5 && val < 20) {
        convertedString = [NSString stringWithFormat:@"%0.1f amps", val];
        if (val >= 19.95) {
            convertedString = @"20 amps";
        }
    } else {
        convertedString = [NSString stringWithFormat:@"%ld amps", lroundf(val)];
    }
    return convertedString;
}

- (void)powerCharacterstics:(NSData *)data
{
    if (!canContinueTimer) {
        return;
    }
    NSInteger len = 4;
    NSData *data0, *data1, *data2, *data3, *data4;
    NSRange range = NSMakeRange(0, len);
    
    data0 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data1 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    
    data2 = [data subdataWithRange:range];
    range = NSMakeRange(range.location + range.length, len);
    
    data3 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data4 = [data subdataWithRange:range];
    
    NSInteger vrms0 = [LFUtilities getValueFromHexData:data0];
    
    NSInteger vrms1 = [LFUtilities getValueFromHexData:data1];
    
    NSInteger vrms2 = [LFUtilities getValueFromHexData:data2];
    
    CGFloat totalVal = (vrms0 + vrms1 + vrms2)/1000.0f;
    
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Power" Value:[NSString stringWithFormat:@"%.3f KW", totalVal/100.0] Code:@"P"];
    
//    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"Power B" Value:[NSString stringWithFormat:@"%.2f watts", vrms1/100.0] Code:@"PB"];
//    
//    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"Power C" Value:[NSString stringWithFormat:@"%.2f watts", vrms2/100.0] Code:@"PC"];
    NSMutableArray *powerDetails = [NSMutableArray arrayWithArray:sectionArray[2]];
    [powerDetails insertObject:aTob atIndex:0];
    [sectionArray replaceObjectAtIndex:2 withObject:powerDetails];
}


- (void)equipmentStatus:(NSData *)data
{
    if (!canContinueTimer) {
        return;
    }
    DLog(@"Equipment data = %@", data);
    BOOL isFaultPresent = YES;
    NSString *dataString = [self getDataStringFromData:[data subdataWithRange:NSMakeRange(0, 4)]];
    NSString *faultError = @"OK";
    faultError = [self getFaultValueForDataString:dataString];
    if ([faultError isEqualToString:@"OK"]) {
        isFaultPresent = NO;
        dataString = [self getDataStringFromData:[data subdataWithRange:NSMakeRange(4, 4)]];
        faultError = [self getCorrectStringForWarningString:dataString];
    }
    else {
        isFaultPresent = YES;
    }
    UIColor *applicableColor;
    if ([faultError isEqualToString:@"OK"]) {
        applicableColor = [UIColor greenColor];
    }
    else {
        if (!isFaultPresent) {
            if ([faultError isEqualToString:@"OK"]) {
                applicableColor = [UIColor greenColor];
            }
            else {
            applicableColor = [UIColor orangeColor];
            }
        }
        else {
            if ([faultError isEqualToString:@"OK"]) {
                applicableColor = [UIColor greenColor];
            }
            else {
            applicableColor = [UIColor redColor];
            }
        }
    }
    if (faultError) {
        NSMutableAttributedString *mutAttrStr = [[NSMutableAttributedString alloc]initWithString:@"System Status:"];
        NSAttributedString *attrStr = [[NSAttributedString alloc]initWithString:faultError attributes:@{
                                                                                                        NSBackgroundColorAttributeName: applicableColor ,
                                                                                                        NSForegroundColorAttributeName: [UIColor whiteColor]
                                                                                                            }];
        [mutAttrStr appendAttributedString:attrStr];
        [self.lblSystemStatus setAttributedText:mutAttrStr];
    }
    NSData *data1, *data2;
    data1 = [data subdataWithRange:NSMakeRange(18, 2)];
    data2 = [data subdataWithRange:NSMakeRange(12, 2)];
    NSMutableData *combinedData = [[NSMutableData alloc]init];
    NSData *tData1 = [data subdataWithRange:NSMakeRange(14, 2)];
    NSData *tData2 = [data subdataWithRange:NSMakeRange(16, 2)];
    [combinedData appendData:tData1];
    [combinedData appendData:tData2];

    NSInteger val1 = [LFUtilities getValueFromHexData:combinedData];
    NSInteger val2 = [LFUtilities getValueFromHexData:data1];
    NSInteger vunb = [LFUtilities getValueFromHexData:data2];
    
    LFDisplay *vunbaised = [[LFDisplay alloc] initWithKey:@"Thermal Capacity Used" Value:[NSString stringWithFormat:@"%0.2f %%", (vunb/100.0)] Code:@"TCU"];
    NSInteger hours = val1/3600; //Hours
    NSInteger minutesVal = val1%3600;
    NSInteger minutes = minutesVal/60; //Minutes
    
    NSInteger seconds = minutesVal%60; //Seconds
    
    LFDisplay *mst = [[LFDisplay alloc] initWithKey:@"Run Time in Hours" Value:[NSString stringWithFormat:@"%02d:%02d:%02d hrs", (int)hours, (int)minutes, (int)seconds] Code:@"RT"];
    LFDisplay *scnt = [[LFDisplay alloc] initWithKey:@"Start Count - Number of starts that have occurred" Value:[NSString stringWithFormat:@"%d", (int)val2] Code:@"SCNT"];
    NSArray *arr = @[mst, scnt,vunbaised];
    [sectionArray replaceObjectAtIndex:3 withObject:arr];
    [tblDisplay reloadData];
    tblDisplay.contentOffset = currentContentOffset;
}

- (NSString *)getFaultValueForDataString:(NSString *)dataString {
    NSString *codeVal = @"OK";
    if ([dataString isEqualToString:@"00000000"]) {
        codeVal = @"OK";
    } else if ([dataString isEqualToString:@"00000001"]) {
        codeVal = @"Over Current";
    } else if ([dataString isEqualToString:@"00000002"]) {
        codeVal = @"Under Current";
    } else if ([dataString isEqualToString:@"00000004"]) {
        codeVal = @"Current Unbalance";
    } else if ([dataString isEqualToString:@"00000008"]) {
        codeVal = @"Current Single Phasing";
    } else if ([dataString isEqualToString:@"00000010"]) {
        codeVal = @"Contactor Failure";
    } else if ([dataString isEqualToString:@"00000020"]) {
        codeVal = @"Ground Fault";
    } else if ([dataString isEqualToString:@"00000040"]) {
        codeVal = @"High Power Fault";
    } else if ([dataString isEqualToString:@"00000080"]) {
        codeVal = @"Low Power Fault";
    } else if ([dataString isEqualToString:@"00000100"]) {
        codeVal = @"Power Outage Fault";
    } else if ([dataString isEqualToString:@"00000200"]) {
        codeVal = @"Trip or holdoff due to PTC fault";
    } else if ([dataString isEqualToString:@"00000400"]) {
        codeVal = @"Tripped triggered from remote source";
    } else if ([dataString isEqualToString:@"00010000"]) {
        codeVal = @"Low Voltage Holdoff";
    } else if ([dataString isEqualToString:@"00020000"]) {
        codeVal = @"High Voltage Holdoff";
    } else if ([dataString isEqualToString:@"00040000"]) {
        codeVal = @"Voltage Unbalanced";
    } else if ([dataString isEqualToString:@"00008000"]) {
        codeVal = @"Undefined trip condition";
    } else if ([dataString isEqualToString:@"00080000"]) {
        codeVal = @"Phase Sequence";
    } else if ([dataString isEqualToString:@"00000800"]) {
        codeVal = @"Linear Over Current";
    } else if ([dataString isEqualToString:@"00100000"]) {
        codeVal = @"Undefined trip condition";
    }
    
    return codeVal;
}

- (NSString *)getCorrectStringForWarningString:(NSString *)dataString {
    NSString *errorVal = @"OK";
    if ([dataString isEqualToString:@"00000000"]) {
        errorVal = @"OK";
    } else if ([dataString isEqualToString:@"00000001"]) {
        errorVal = @"Warning on overcurrent";
    } else if ([dataString isEqualToString:@"00000002"]) {
        errorVal = @"Warning on undercurrent ";
    } else if ([dataString isEqualToString:@"00000004"]) {
        errorVal = @"Warning on current unbalance";
    } else if ([dataString isEqualToString:@"00000020"]) {
        errorVal = @"Warning on ground fault";
    } else if ([dataString isEqualToString:@"00000040"]) {
        errorVal = @"Warning on High Power Fault";
    } else if ([dataString isEqualToString:@"00000080"]) {
        errorVal = @"Warning on low power fault ";
    } else if ([dataString isEqualToString:@"00008000"]) {
        errorVal = @"Undefined Warning condition";
    }
    return errorVal;
}

- (NSString *)getDataStringFromData:(NSData *)data {
    uint8_t *bytesArr = (uint8_t*)[data bytes];
    NSMutableString *dataString = [[NSMutableString alloc] init];
    for (NSInteger i = [data length]-1; i >= 0; i-- ) {
        [dataString appendFormat:@"%02x", bytesArr[i]];
    }
    return dataString;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (sectionArray.count) {
        NSArray *rowsarr = [sectionArray firstObject];
        if (rowsarr.count) {
            return sectionArray.count;
        }
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[sectionArray objectAtIndex:section] count]?[[sectionArray objectAtIndex:section] count]:0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tableView dequeueReusableCellWithIdentifier:CHARACTER_DISPLAY_CELL_ID forIndexPath:indexPath];
    if (sectionArray.count && [sectionArray[indexPath.section] count]) {
        NSArray *tArr =[sectionArray objectAtIndex:indexPath.section];
        if (tArr && tArr.count && tArr.count > indexPath.row) {
            LFDisplay *display = [[sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
            if (display) {
                [cell updateValues:display];
            }
        }

    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *aView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 40)];
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 280, 40)];
    switch (section) {
        case 0:
            aLabel.text = @"Voltage";
            break;
        case 1:
            aLabel.text = @"Current";
            break;
        case 2:
            aLabel.text = @"Power";
            break;
        case 3:
            aLabel.text = @"Equipment Status";
            break;
        default:
            break;
    }
    aLabel.font = [UIFont fontWithName:AERIAL_BOLD size:14.0];
    aLabel.textColor = [UIColor colorWithRed:17.0/255 green:17.0/255 blue:17.0/255 alpha:1.0];
    aLabel.backgroundColor = [UIColor clearColor];
    aView.backgroundColor = [UIColor colorWithRed:236.0/255 green:237.0/255 blue:241.0/255 alpha:1.0];
    [aView addSubview:aLabel];
    return aView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40.0f;
}

- (void)dealloc
{
    configArr = nil;
    sectionArray = nil;
    [LittleFuseNotificationCenter removeObserver:self];
}

- (void)readCharactisticsWithIndex:(NSInteger)index
{
    
    /*if (!canContinueTimer) {
        return;
    }*/
    Byte data[20];
    for (int i=0; i < 20; i++) {
        if (i== 8) {
            data[i] = realMemMap[index];
        } else if (i == 10){
            data[i] = realMemFieldLens[index];
        }  else {
            data[i] = (Byte)0x00;
        }
    }
    
    [[LFBluetoothManager sharedManager] setConfig:YES];
    NSData *data1 = [NSData dataWithBytes:data length:20];
    [[LFBluetoothManager sharedManager] writeConfigData:data1];
}

- (void)readCharactistic:(CBCharacteristic *)charactistic
{
    
    
   /* Byte data[20];
    for (int i=0; i < 20; i++) {
        if (i== 8) {
            data[i] = realMemMap[index];
        } else if (i == 10){
            data[i] = realMemFieldLens[index];
        }  else {
            data[i] = (Byte)0x00;
        }
    }
    
    [[LFBluetoothManager sharedManager] setConfig:YES];
    NSData *data1 = [NSData dataWithBytes:data length:20];
    [[LFBluetoothManager sharedManager] writeConfigData:data1];*/
    
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] readValueForCharacteristic:charactistic];
    
}
/**
 *Calculates timers data received from device.
 */
- (void)getTimersData:(NSNotification *)notification
{
    if (!canContinueTimer) {
        return;
    }
    CBCharacteristic *characteristic = (CBCharacteristic *)notification.object;
    NSData *data = characteristic.value;
    
    NSRange range = NSMakeRange(0, 4);
    
    data = [data subdataWithRange:range];
    
    NSUInteger val = [LFUtilities getValueFromHexData:data];
    //    NSArray *section3 = @[@{@"code" : @"MST", @"name" : @"Motor Run Time in Seconds", @"value" : @""}, @{@"code" : @"SCNT", @"name" : @"Start Count - Number of starts that have occurred", @"value" : @""} ];
    if (configArr.count == 0 ) {
        LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Run Time in Hours" Value:[NSString stringWithFormat:@"%.f hrs", val/3600.0] Code:@"RT"];
        [configArr addObject:aTob];
        [self readCharactisticsWithIndex:1];
    } else {
        LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Start Count - Number of starts that have occurred" Value:[NSString stringWithFormat:@"%d", (int)val] Code:@"SCNT"];
        [configArr addObject:aTob];
        [sectionArray replaceObjectAtIndex:3 withObject:[configArr copy]];
        [configArr removeAllObjects];
        [tblDisplay beginUpdates];
        [tblDisplay reloadRowsAtIndexPaths:[tblDisplay indexPathsForVisibleRows]
                          withRowAnimation:UITableViewRowAnimationNone];
        [tblDisplay endUpdates];
    }


}

#pragma mark Peripheral Disconnected Notification
- (void)peripheralDisconnected {
    if (!canContinueTimer) {
        return;
    }
 [self showAlertViewWithCancelButtonTitle:kOK withMessage:kDevice_Disconnected withTitle:kApp_Name otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
     if ([alert isKindOfClass:[UIAlertController class]]) {
         [alert dismissViewControllerAnimated:NO completion:nil];
         [self.navigationController popToRootViewControllerAnimated:NO];
     }
 }];
}

#pragma mark Action Methods

- (IBAction)resetRelayAction:(id)sender {
    
    canContinueTimer = NO;
    [[LFBluetoothManager sharedManager] stopFaultTimer];
    
    if (![LFBluetoothManager sharedManager].isPasswordVerified) {
        isVerifyingPassword = YES;
        LFNavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingNavigationController"];
        editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
        editing.selectedText = @"password";
        self.providesPresentationContextTransitionStyle = YES;
        self.definesPresentationContext = YES;
        [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        
       // editing.selectedText = cell.lblKey.text;
        editing.delegate = self;
        
        
        editing.showAuthentication = YES;//YES to show the password screen.
        [navController setViewControllers:@[editing]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:navController animated:NO completion:nil];
        });
    }
    else{
        
        [self writeRelayData];
    }
}
#pragma mark -Editing Delegate

- (void)checkPassword:(NSString *)passwordStr {
    // TODO: Ask aswin to y it is
   // isVerifyingPassword = YES;
    if (passwordStr != nil) {
        [[LFBluetoothManager sharedManager] setPasswordString:passwordStr] ;
    }
    
    
    if(! ([[LFBluetoothManager sharedManager] getConfigSeedData] && [LFBluetoothManager sharedManager].macData) ){
        [self readDeviceMacAndAuthSeed];
    }
    else{
        
        [editing authDoneWithStatus:YES shouldDismissView:YES];
        
        [self showAlertToResetRelay];

       // [self writeRelayData];
        
       // [self showAlertToResetRelay];
       
    }
}
- (void)showAlertToResetRelay{
    [self showAlertViewWithCancelButtonTitle:kCancel withMessage:kResetRelay_motorStarts withTitle:APP_NAME otherButtons:@[kContinue] clickedAtIndexWithBlock:^(id alert, NSInteger index) {
        if ([alert isKindOfClass:[UIAlertController class]]) {
            if (index == 1) {
                
                 [self writeRelayData];
            }
            else{
                canContinueTimer = YES;
                [self refreshCurrentController];
                
            }
            [alert dismissViewControllerAnimated:NO completion:nil];
        }
    }];
}

-(void)writeRelayData
{
    Byte data[20];
    NSInteger convertedVal = 9;
    char *bytes = (char *) malloc(8);
    memset(bytes, 0, 8);
    memcpy(bytes, (char *) &convertedVal, 2);//8
    
    for (int i = 0; i < 20; i++) {
        if (i < 8) {
            data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
        } else {
            if (i == 8) {
                data[i] = 0x0076;//register address
            } else if (i == 10){
                data[i] = 0x02;//length of the data
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            }
            else {
                data[i] = (Byte)0x00;
            }
        }
    }
    
    NSData *data1 = [NSData dataWithBytes:data length:20];
    
    
    NSData *lengthVal = [data1 subdataWithRange:NSMakeRange(10, 1)];
    char buff;
    [lengthVal getBytes:&buff length:1];
    int myLen = buff;
    NSData *addressVal = [data1 subdataWithRange:NSMakeRange(8, 1)];
    char addrBuff;
    [addressVal getBytes:&addrBuff length:1];
    int myAddr = addrBuff;
    NSData *resultData = [self getEncryptedPasswordDataFromString:@"" data:[data1 subdataWithRange:NSMakeRange(0, 8)] address:myAddr size:myLen];
    data1 = [data1 subdataWithRange:NSMakeRange(0, 12)];
    NSMutableData *mutData = [NSMutableData dataWithData:data1];
    for (int i = 0; i< 8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    
    isWrite = YES;
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] writeConfigData:mutData];
    prevWrittenData = mutData;

}

- (void)showOperationCompletedAlertWithStatus:(BOOL)isSuccess withCharacteristic:(CBCharacteristic *)characteristic
{
    //isWrite = NO;
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    [self removeIndicator];
    if (isSuccess) {
        [self readCharactistic:characteristic];
        //[self readCharactisticsWithIndex:2];//2 for index of reset relay address and length
        //canContinueTimer = YES;

        }
    else {
        //Error occured while writing data to device.
        [self showAlertViewWithCancelButtonTitle:kOK withMessage:kProblem_Saving withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
        }];
    }
}
#pragma mark Generate Excrypted Data

- (NSData *)getEncryptedPasswordDataFromString:(NSString *)newPassword data:(NSData *)writeData address:(short)address size:(short)size{
    
    if (authUtils == nil) {
        authUtils = [[LFAuthUtils alloc]init];
    }
    NSLog(@"Password is %@",[[LFBluetoothManager sharedManager] getPasswordString] );
    NSLog(@"mac string is %@",[[LFBluetoothManager sharedManager] getMacString] );
    NSLog(@"configseed data is %@",[[LFBluetoothManager sharedManager] getConfigSeedData] );

    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {

        [authUtils initWithPassKey:[[LFBluetoothManager sharedManager] getPasswordString] andMacAddress:[[LFBluetoothManager sharedManager] getMacString] andSeed:[[LFBluetoothManager sharedManager] getConfigSeedData].bytes];
    }
    NSData * authCode = [authUtils computeAuthCode:writeData.bytes address:address size:size];
    
    return authCode;
}

- (void)showCharacterstics:(NSMutableArray *)charactersticsArray
{
    CBCharacteristic *charactestic = (CBCharacteristic *)charactersticsArray[2];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
}
#pragma mark Read Mac Data

- (void)receivedDeviceMacWithData:(NSData *)data {
    [LFBluetoothManager sharedManager].macData = data;
    isFetchingMacOrSeedData = NO;
    NSString *tString = [[NSString alloc] initWithData:data
                                              encoding:NSASCIIStringEncoding];
    NSMutableString *tMutStr = [[NSMutableString alloc]init];
    for (int i = 0; i < tString.length; i++) {
        NSString *tSubStr = [tString substringWithRange:NSMakeRange(i, 1)];
        [tMutStr appendString:tSubStr];
        if (i != 0 && i % 2 != 0 && i != tString.length-1) {
            [tMutStr appendString:@":"];
        }
    }
    [LFBluetoothManager sharedManager].macString = tString;
    [self performSelector:@selector(getSeedData) withObject:nil afterDelay:2];
}
- (void)getSeedData {
    isFetchingMacOrSeedData = YES;
    NSArray *charsArr = [LFBluetoothManager sharedManager].discoveredPeripheral.services[1].characteristics;
    CBCharacteristic *charactestic = (CBCharacteristic *)charsArr[4];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
}

#pragma mark read value delegate

- (void)configureServiceWithValue:(NSData *)data
{
     [self updateCharactersticsData:data];
    return;
}
- (BOOL)isDataUpdatedCorrectlyWithPrevData:(NSData *)writtenData withNewData:(NSData *)newData {
    NSData *prevVal = [writtenData subdataWithRange:NSMakeRange(0, 8)];
    NSData *newVal = [newData subdataWithRange:NSMakeRange(0, 8)];
    if ([prevVal isEqualToData:newVal]) {
        return YES;
    }
    return NO;
}

- (void)readDeviceMacAndAuthSeed {
    isFetchingMacOrSeedData = YES;
    [editing authDoneWithStatus:YES shouldDismissView:YES];
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    [[LFBluetoothManager sharedManager] discoverCharacteristicsForAuthentication];

}

- (void) updateCharactersticsData:(NSData *) data {
    
    NSData *tData = data;
      
    if (isFetchingMacOrSeedData) {
        isFetchingMacOrSeedData = NO;
        NSMutableData *mutData = [[NSMutableData alloc]init];
        for (int i=12; i<=19; i++) {
            [mutData appendData:[data subdataWithRange:NSMakeRange(i, 1)]];
        }
        for (int j = 0; j<24; j++) {
            NSInteger convertedVal = 0;
            char* zeroBytes = (char*) &convertedVal;
            [mutData appendBytes:zeroBytes length:1];
        }
        [[LFBluetoothManager sharedManager] setConfigSeedData:mutData];
        [self removeIndicator];
        [[LFBluetoothManager sharedManager] resetConfigurationCharacteristics];
        
        [self performSelector:@selector(showAlertToResetRelay) withObject:nil afterDelay:1];
        return;
    }
    
    if (isWrite && !isReRead) { // //TODO Data is read after writing to the device.Now we should show alert here and remove check after delay for showing alert if no callback is received.
        [self removeIndicator];
        isWrite = NO;
        NSData *stData = [tData subdataWithRange:NSMakeRange(11, 1)];
        const char *byteVal = [stData bytes];
        
        int stVal = 0x0000000F & ((Byte)byteVal[0] >> 4); // this for getting response st val
        NSString *alertMessage;
        
        switch (stVal) {
            case 0:
                isReRead = NO;
                isWrite = YES;
              
                break;
            case 1:
              
                alertMessage = kSave_Success;
               // isReRead = YES;
                [authUtils nextAuthCode];
                isVerifyingPassword = NO;
               // DLog(@"Authentication done successfully.");
                //[editing authDoneWithStatus:YES shouldDismissView:YES];
                [LFBluetoothManager sharedManager].isPasswordVerified = YES;
                
                //[self showAlertToResetRelay];

                break;
            case 2:
                alertMessage = kEnter_Correct_Password;
                isReRead = NO;
                break;
            case 3:
                isReRead = NO;
                alertMessage = kPermision_Error;
                break;
            case 4:
                isReRead = NO;
                alertMessage = kOutOf_Range;
                break;
            case 5:
                isReRead = NO;
                alertMessage = kPassword_Changed;
                break;
                
            default:
                break;
        }
        if (stVal != 0) {
            [self showAlertViewWithCancelButtonTitle:kOK withMessage:alertMessage withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                if ([alert isKindOfClass:[UIAlertController class]]) {
                    [alert dismissViewControllerAnimated:NO completion:nil];
                }
            }];
        }
        //[self readCharactisticsWithIndex:2];
        return;
    }
    
    
    //////////////////////////////   re reading process   starts /////////////////////////
    if (isReRead) {
        [self removeIndicator];
        isReRead = NO;

        if (![self isDataUpdatedCorrectlyWithPrevData:prevWrittenData withNewData:tData]) { /// if authentication fails
            if (isVerifyingPassword) {
                isVerifyingPassword = NO;
                [editing authDoneWithStatus:NO shouldDismissView:NO];
                DLog(@"Authentication failed");
                return;
            }
            
            return;
        }
       // [authUtils nextAuthCode];
        if (isVerifyingPassword) {
            isVerifyingPassword = NO;
            DLog(@"Authentication done successfully.");
            [editing authDoneWithStatus:YES shouldDismissView:YES];
            [LFBluetoothManager sharedManager].isPasswordVerified = YES;
            
            [self showAlertToResetRelay];
            return;
        }
        [self readCharactisticsWithIndex:2];
        return;
    }
    //////////////////////////////   re reading process   ends /////////////////////////
    
    
}

@end
