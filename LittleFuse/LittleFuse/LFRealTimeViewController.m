//
//  LFRealTimeViewController.m
//  LittleFuse
//
//  Created by Kranthi on 22/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFRealTimeViewController.h"
#import "LFCharactersticDisplayCell.h"
#import "LFBluetoothManager.h"
#import "LFNavigationBar.h"
#import "LFDisplay.h"

@interface LFRealTimeViewController ()
{
    NSMutableArray *sectionArray;
    NSData *unbalanceCurrentData;
    __weak IBOutlet UITableView *tblDisplay;
    __weak IBOutlet UILabel *lblDeviceName;
    NSMutableArray *configArr;
}
@end

@implementation LFRealTimeViewController

const char realMemMap[] = { 0x56, 0x5e};

const char realMemFieldLens[] = { 0x02, 0x02};


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sectionArray = [[NSMutableArray alloc] initWithObjects:@[], @[], @[], @[], nil];
    configArr = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSString *name = [[LFBluetoothManager sharedManager] selectedDevice];
    name = [name substringToIndex:name.length-4];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Device ID: %@", name]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(10, string.length-10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:AERIAL_REGULAR size:15.0] range:NSMakeRange(0, 10)];
    lblDeviceName.attributedText = string;

    
    [tblDisplay registerNib:[UINib nibWithNibName:@"LFCharactersticDisplayCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:CHARACTER_DISPLAY_CELL_ID];
    [tblDisplay setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrentData:) name:CURRENT_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getPowerData:) name:POWER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getVoltageData:) name:VOLTAGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getTimersData:) name:REAL_TIME_CONFIGURATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getEquipmentData:) name:EQUIPMENT_NOTIFICATION object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(peripheralDisconnected) name:PeripheralDidDisconnect object:nil];


}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[LFBluetoothManager sharedManager] fetchRealTimeValues];
    
}

- (void)getVoltageData:(NSNotification *)notification
{
    [self voltageCharcterstics:[notification object]];
}

- (void)getCurrentData:(NSNotification *)notification
{
    [self currentCharcterstics:[notification object]];
    
}

- (void)getEquipmentData:(NSNotification *)notificaition
{
    [self equipmentStatus:[notificaition object]];
}

- (void)getPowerData:(NSNotification *)notification
{
    [self powerCharacterstics:[notification object]];
}

- (void)voltageCharcterstics:(NSData *)data
{
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
    
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"L1-L2" Value:[NSString stringWithFormat:@"%d VAC", (int)(vrms0/100.0)] Code:@"L1-L2"];
    
    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"L2-L3" Value:[NSString stringWithFormat:@"%d VAC", (int)(vrms1/100.0)] Code:@"L2-L3"];
    
    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"L3-L1" Value:[NSString stringWithFormat:@"%d VAC", (int)(vrms2/100.0)] Code:@"L3-L1"];
    
    LFDisplay *vunbaised = [[LFDisplay alloc] initWithKey:@"Voltage Unbalance" Value:[NSString stringWithFormat:@"%0.1f %%", (vunb/100.0)] Code:@"VUB"];

    NSArray *voltgaeDetails = @[aTob, bToc, cToa, vunbaised];
    [sectionArray replaceObjectAtIndex:0 withObject:voltgaeDetails];
    
    [tblDisplay reloadData];
    
}
- (void)currentCharcterstics:(NSData *)data
{
    
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
    [sectionArray replaceObjectAtIndex:1 withObject:currentDetails];
    [sectionArray replaceObjectAtIndex:2 withObject:powerDetails];
    
    [tblDisplay reloadData];
    
}
- (NSString *)changeCurrentAsRequired:(float)val
{
    NSString *convertedString;
    
    if (val < 5) {
        convertedString = [NSString stringWithFormat:@"%0.2f amps", val];
    } else if (val >= 5 && val < 20) {
        NSString *strVal = [NSNumber numberWithFloat:val].stringValue;
        convertedString = [NSString stringWithFormat:@"%@ amps", [strVal substringToIndex:strVal.length-1]];
    } else {
        convertedString = [NSString stringWithFormat:@"%d amps", (int)val];
    }
    return convertedString;
}

- (void)powerCharacterstics:(NSData *)data
{
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
    
    CGFloat totalVal = (vrms0 + vrms1 + vrms2)/1000;
    
    
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Power" Value:[NSString stringWithFormat:@"%.3f KW", totalVal/100.0] Code:@"P"];
    
//    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"Power B" Value:[NSString stringWithFormat:@"%.2f watts", vrms1/100.0] Code:@"PB"];
//    
//    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"Power C" Value:[NSString stringWithFormat:@"%.2f watts", vrms2/100.0] Code:@"PC"];
    
    NSMutableArray *powerDetails = [NSMutableArray arrayWithArray:sectionArray[2]];
    [powerDetails insertObject:aTob atIndex:0];
    [sectionArray replaceObjectAtIndex:2 withObject:powerDetails];
    
    [tblDisplay reloadData];
    
}

- (void)equipmentStatus:(NSData *)data
{
    NSLog(@"Equipment data = %@", data);
    BOOL isFaultPresent = YES;
    NSString *dataString = [self getDataStringFromData:[data subdataWithRange:NSMakeRange(0, 4)]];
    NSString *faultError;
    NSInteger code = [self getCorrectCodeForFaultString:dataString];
    if (code == 0) {
        isFaultPresent = NO;
        dataString = [self getDataStringFromData:[data subdataWithRange:NSMakeRange(4, 4)]];
        faultError = [self getCorrectStringForWarningString:dataString];
        
    }
    else {
        faultError = [self faultWithCode:code];
    }
    UIColor *applicableColor;
    if ([faultError isEqualToString:@"OK"]) {
        applicableColor = [UIColor greenColor];
    }
    else {
        if (!isFaultPresent) {
            applicableColor = [UIColor yellowColor];
        }
        else {
            applicableColor = [UIColor redColor];
        }
    }
//    NSString *faultError = [self faultWithCode:code];
    if (faultError) {
        NSMutableAttributedString *mutAttrStr = [[NSMutableAttributedString alloc]initWithString:@"System Status:"];
        NSAttributedString *attrStr = [[NSAttributedString alloc]initWithString:faultError attributes:@{
                                                                                                        NSBackgroundColorAttributeName: applicableColor ,
                                                                                                        NSForegroundColorAttributeName: [UIColor whiteColor]
                                                                                                            }];
        [mutAttrStr appendAttributedString:attrStr];
        [self.lblSystemStatus setAttributedText:mutAttrStr];
    }
    NSData *data0, *data1, *data2;
    data0 = [data subdataWithRange:NSMakeRange(14, 4)];
    data1 = [data subdataWithRange:NSMakeRange(18, 2)];
    data2 = [data subdataWithRange:NSMakeRange(12, 2)];
    NSInteger val1 = [LFUtilities getValueFromHexData:data0];
    NSInteger val2 = [LFUtilities getValueFromHexData:data1];
    NSInteger vunb = [LFUtilities getValueFromHexData:data2];
    
    LFDisplay *vunbaised = [[LFDisplay alloc] initWithKey:@"Thermal Capacity Remaining" Value:[NSString stringWithFormat:@"%0.1f %%", (vunb/100.0)] Code:@"TCR"];
    NSInteger hours = val1/3600; //Hours
    NSInteger minutesVal = val1%3600;
    NSInteger minutes = minutesVal/60; //Minutes
    
    NSInteger seconds = minutesVal%60; //Seconds
    
    
    
    LFDisplay *mst = [[LFDisplay alloc] initWithKey:@"Run Time in Hours" Value:[NSString stringWithFormat:@"%02d:%02d:%02d hrs", (int)hours, (int)minutes, (int)seconds] Code:@"RT"];
    LFDisplay *scnt = [[LFDisplay alloc] initWithKey:@"Start Count - Number of starts that have occurred" Value:[NSString stringWithFormat:@"%d", (int)val2] Code:@"SCNT"];
    NSArray *arr = @[mst, scnt,vunbaised];
    [sectionArray replaceObjectAtIndex:3 withObject:arr];
    [tblDisplay reloadData];

}

- (NSInteger)getCorrectCodeForFaultString:(NSString *)dataString {
    NSInteger codeVal = 0;
    if ([dataString isEqualToString:@"00000000"]) {
        codeVal = 0;
    }
    else if ([dataString isEqualToString:@"00000001"]) {
        codeVal = 1;
    }
    else if ([dataString isEqualToString:@"00000002"]) {
        codeVal = 2;
    }
    else if ([dataString isEqualToString:@"00000004"]) {
        codeVal = 3;
    }
    else if ([dataString isEqualToString:@"00000008"]) {
        codeVal = 4;
    }
    else if ([dataString isEqualToString:@"00000010"]) {
        codeVal = 5;
    }
    else if ([dataString isEqualToString:@"00000020"]) {
        codeVal = 6;
    }
    else if ([dataString isEqualToString:@"00000040"]) {
        codeVal = 7;
    }
    else if ([dataString isEqualToString:@"00000080"]) {
        codeVal = 8;
    }
    else if ([dataString isEqualToString:@"00000100"]) {
        codeVal = 9;
    }
    else if ([dataString isEqualToString:@"00000200"]) {
        codeVal = 10;
    }
    else if ([dataString isEqualToString:@"00000400"]) {
        codeVal = 11;
    }
    else if ([dataString isEqualToString:@"00010000"]) {
        codeVal = 100;
    }
    else if ([dataString isEqualToString:@"00020000"]) {
        codeVal = 101;
    }
    else if ([dataString isEqualToString:@"00040000"]) {
        codeVal = 102;
    }
    else if ([dataString isEqualToString:@"00008000"]) {
        codeVal = 61166;
    }
    return codeVal;
}

- (NSString *)getCorrectStringForWarningString:(NSString *)dataString {
    NSString *errorVal = @"OK";
    if ([dataString isEqualToString:@"00000000"]) {
        errorVal = @"OK";
    }
    else if ([dataString isEqualToString:@"00000001"]) {
        errorVal = @"Warning on overcurrent";
    }
    else if ([dataString isEqualToString:@"00000002"]) {
        errorVal = @"Warning on undercurrent ";
    }
    else if ([dataString isEqualToString:@"00000004"]) {
        errorVal = @"Warning on current unbalance";
    }
    else if ([dataString isEqualToString:@"00000020"]) {
        errorVal = @"Warning on ground fault";
    }
    else if ([dataString isEqualToString:@"00000040"]) {
        errorVal = @"Warning on High Power Fault";
    }
    else if ([dataString isEqualToString:@"00000080"]) {
        errorVal = @"Warning on low power fault ";
    }
    else if ([dataString isEqualToString:@"00008000"]) {
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

- (NSString *)faultWithCode:(NSInteger)code
{
    NSString *error = @"";
    switch (code) {
        case 0:
            error = @"OK";
            break;
        case 1:
            error = @"Tripped on overcurrent";
            break;
        case 2:
            error = @"Tripped on undercurrent";
            break;
        case 3:
            error = @"Tripped on current unbalance";
            break;
        case 4:
            error = @"Tripped on current single-phasing";
            break;
        case 5:
            error = @"Tripped on contactor failure";
            break;
        case 6:
            error = @"Tripped on ground fault";
            break;
        case 7:
            error = @"Tripped on High Power Fault";
            break;
        case 8:
            error = @"Tripped on low power fault";
            break;
        case 9:
            error = @"Power Outage fault";
            break;
        case 10:
            error = @"Trip or holdoff due to PTC fault";
            break;
        case 11:
            error = @"Tripped triggered from remote source";
            break;
        case 100:
            error = @"Low voltage Holdoff";
            break;
        case 101:
            error = @"High Voltage Holdoff";
            break;
        case 102:
            error = @"Voltage Unbalanced Holdoff";
            break;
        case 61166:
            error = @"Undefined trip condition";
            break;
        default:
            break;
    }
    return error;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSArray *rowsarr = [sectionArray firstObject];
    if (rowsarr.count) {
        return sectionArray.count;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[sectionArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tableView dequeueReusableCellWithIdentifier:CHARACTER_DISPLAY_CELL_ID forIndexPath:indexPath];
    [cell updateValues:[[sectionArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]];
    // Configure the cell...
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)readCharactisticsWithIndex:(NSInteger)index
{
    //    DLog(@"writing data  to %c %c ", mapArray[currentIndex], basicMemMap[currentIndex], basicMemFieldLens[currentIndex]);
    Byte data[20];
    for (int i=0; i < 20; i++) {
        if (i== 8) {
            data[i] = realMemMap[index];
        } else if (i == 10){
            data[i] = realMemFieldLens[index];
        } else {
            data[i] = (Byte)0x00;
        }
    }
    
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] setRealtime:YES];
    NSData *data1 = [NSData dataWithBytes:data length:20];
    [[LFBluetoothManager sharedManager] writeConfigData:data1];
}


- (void)getTimersData:(NSNotification *)notification
{
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
        [tblDisplay reloadData];
    }


}

#pragma Peripheral Disconnected Notification

- (void)peripheralDisconnected {
 [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Device Disconnected" withTitle:@"Little Fuse" otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
     if ([alert isKindOfClass:[UIAlertController class]]) {
         [alert dismissViewControllerAnimated:NO completion:nil];
     }
 }];
}


@end
