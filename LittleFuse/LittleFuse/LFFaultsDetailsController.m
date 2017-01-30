//
//  LFFaultsDetailsController.m
//  Littlefuse
//
//  Created by Kranthi on 08/03/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFFaultsDetailsController.h"
#import "LFCharactersticDisplayCell.h"
#import "LFBluetoothManager.h"


@interface LFFaultsDetailsController ()
{
    BOOL canContinueTimer;
    NSMutableArray *detailsArr;
    NSMutableDictionary *faultDict;
}

@property (weak, nonatomic) IBOutlet UILabel *faultName;
@property (weak, nonatomic) IBOutlet UITableView *faultDetails;
@property (weak, nonatomic) IBOutlet UILabel *faultDate;


@end

@implementation LFFaultsDetailsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    detailsArr = [[NSMutableArray alloc] initWithCapacity:0];
    [_faultDetails registerNib:[UINib nibWithNibName:@"LFCharactersticDisplayCell" bundle:nil] forCellReuseIdentifier:CHARACTER_DISPLAY_CELL_ID];
    [_faultDetails setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.faultName.text = _errorType;
    self.faultDate.text = _errorDate;
    canContinueTimer = YES;
    [LittleFuseNotificationCenter addObserver:self selector:@selector(peripheralDisconnected) name:PeripheralDidDisconnect object:nil];

    [self convertFaultData];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)appEnteredBackground {
    [[LFBluetoothManager  sharedManager] disconnectDevice];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    canContinueTimer = NO;
    self.navigationItem.title = @"";
    [[LFBluetoothManager sharedManager] stopFaultTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    canContinueTimer = YES;
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:180];
    
}

- (void)updateFaultData {
    if(!canContinueTimer) {
        return;
    }
    [LFBluetoothManager sharedManager].tCurIndex = 1;
    [LFBluetoothManager sharedManager].canContinueTimer = YES;
    [[LFBluetoothManager sharedManager] readFaultData];
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:180];
}

- (void)convertFaultData
{
    faultDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    [self convertDataToVoltageDisplay:_faultData.voltage];
    [self convertDataToCurrentDisplay:_faultData.current];
    [self convertToPowerDisplay:_faultData.power];
    [self convertToOtherData:_faultData.other];
    [detailsArr removeAllObjects];
    [detailsArr addObject:faultDict[FAULT_VOLTAGE_DETAILS]];
    [detailsArr addObject:faultDict[FAULT_CURRENT_DETAILS]];
    [detailsArr addObject:faultDict[FAULT_POWER_DETAILS]];
    [detailsArr addObject:faultDict[OTHER_FAULTS]];
    [self.faultDetails reloadData];
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return detailsArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [detailsArr[section] count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tableView dequeueReusableCellWithIdentifier:CHARACTER_DISPLAY_CELL_ID forIndexPath:indexPath];
    [cell updateValues:detailsArr[indexPath.section][indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *aView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 40)];
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 100, 40)];
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
            aLabel.text = @"Other";
            break;
            
            
        default:
            break;
    }
    aLabel.font = [UIFont fontWithName:AERIAL_BOLD size:14.0];
    aLabel.textColor = [UIColor colorWithRed:17.0/255 green:17.0/255 blue:17.0/255 alpha:1.0];
    aLabel.backgroundColor = [UIColor clearColor];
    aView.backgroundColor = [UIColor colorWithRed:244.0/255 green:244.0/255 blue:244.0/255 alpha:1.0];
    [aView addSubview:aLabel];
    return aView;
}

#pragma mark Conversions
- (void)convertDataToVoltageDisplay:(NSData *)data
{
    NSInteger len = 2;
    NSData *data0, *data1, *data2, *data3, *data4, *data5;
    NSRange range = NSMakeRange(0, len);
    data0 = [data subdataWithRange:range];
    len = 4;
    
    range = NSMakeRange(range.location + range.length, len);
    data1 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data2 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data3 = [data subdataWithRange:range];
    
    range = NSMakeRange(range.location + range.length, len);
    data4 = [data subdataWithRange:range];
    len = 2;
    range = NSMakeRange(range.location + range.length, len);
    data5 = [data subdataWithRange:range];
    
    DLog(@" Voltage %@\t%@ \t%@ \t%@ \t %@ \t %@", data0,data1, data2, data3, data4, data5);
    
    
    NSInteger dateandTime = [LFUtilities getValueFromHexData:data1];
    
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:(dateandTime)];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"yyyy-MM-dd HH:mm a"];
    
    NSString *faultdate = [df stringFromDate:date];
    DLog(@"Fault date = %@", faultdate);
    
    NSInteger Vab = [LFUtilities getValueFromHexData:data2];
    
    NSInteger Vbc = [LFUtilities getValueFromHexData:data3];
    
    NSInteger Vca = [LFUtilities getValueFromHexData:data4];
    
    NSInteger tcrVal = [LFUtilities getValueFromHexData:data5];
//    NSLog(@"Voltage 1 = %d \n Voltage 2 = %d \n Voltage 3 = %d", Vab, Vbc, Vca);
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"L1-L2" Value:[NSString stringWithFormat:@"%ld VAC", lroundf(Vab/100.0f)] Code:@"L1-L2"];
    
    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"L2-L3" Value:[NSString stringWithFormat:@"%ld VAC", lroundf(Vbc/100.0f)] Code:@"L2-L3"];
    
    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"L3-L1" Value:[NSString stringWithFormat:@"%ld VAC", lroundf(Vca/100.0f)] Code:@"L3-L1"];
    
    LFDisplay *tcr = [[LFDisplay alloc] initWithKey:@"Thermal Capacity Used" Value:[NSString stringWithFormat:@"%0.2f %%", (tcrVal/100.0)] Code:@"TCU"];;
    
    NSArray *voltgaeDetails = @[aTob, bToc, cToa];
    
    NSArray *otherDetails = @[tcr];
    
    
    [faultDict setValue:faultdate forKey:FAULT_DATE];
    [faultDict setValue:voltgaeDetails forKey:FAULT_VOLTAGE_DETAILS];
    [faultDict setValue:otherDetails forKey:OTHER_FAULTS];
    
}

- (void)convertDataToCurrentDisplay:(NSData *)data
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
    
    
    DLog(@" Voltage %@\t%@ \t%@ \t%@ \t %@ ", data0,data1, data2, data3, data4);
    
    NSInteger Ia = [LFUtilities getValueFromHexData:data0];
    
    NSInteger Ib = [LFUtilities getValueFromHexData:data1];
    
    NSInteger Ic = [LFUtilities getValueFromHexData:data2];
    
    NSInteger runtime = [LFUtilities getValueFromHexData:data3];
    
    NSInteger groundCurrent = [LFUtilities getValueFromHexData:data4];
    
    NSInteger hours = runtime/3600; //Hours
    NSInteger minutesVal = runtime%3600;
    NSInteger minutes = minutesVal/60; //Minutes
    
    NSInteger seconds = minutesVal%60; //Seconds
    
    
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Ø A" Value:[NSString stringWithFormat:@"%@", [self changeCurrentAsRequired:Ia/100.0]] Code:@"A"];
    
    LFDisplay *bToc = [[LFDisplay alloc] initWithKey:@"Ø B" Value:[NSString stringWithFormat:@"%@", [self changeCurrentAsRequired:Ib/100.0]] Code:@"B"];
    
    LFDisplay *cToa = [[LFDisplay alloc] initWithKey:@"Ø C" Value:[NSString stringWithFormat:@"%@", [self changeCurrentAsRequired:Ic/100.0]] Code:@"C"];
    
    LFDisplay *RTSLS = [[LFDisplay alloc] initWithKey:@"Run Time Since Last Start" Value:[NSString stringWithFormat:@"%02d:%02d:%02d hrs", (int)hours, (int)minutes, (int)seconds] Code:@"RT"];
    
    LFDisplay *groundFault = [[LFDisplay alloc] initWithKey:@"Ground Fault Current" Value:[NSString stringWithFormat:@"%.2f amps", groundCurrent/100.0] Code:@"GFC"];
    
    
    NSArray *currentDetails = @[aTob, bToc, cToa];
    
    NSMutableArray *otherDetails = [[NSMutableArray alloc] initWithArray:faultDict[OTHER_FAULTS]];
    
    [otherDetails addObjectsFromArray:@[RTSLS, groundFault]];
    
    [faultDict setValue:currentDetails forKey:FAULT_CURRENT_DETAILS];
    
    [faultDict setValue:otherDetails forKey:OTHER_FAULTS];
    
}

- (void)convertToPowerDisplay:(NSData *)data
{
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
    
    
    DLog(@" Voltage %@\t%@ \t%@ \t%@ \t %@\t %@ \t %@ ", data0,data1, data2, data3, data4, data5, data6);
    
    NSInteger Pa = [LFUtilities getValueFromHexData:data0];
    
    NSInteger Pb = [LFUtilities getValueFromHexData:data1];
    
    NSInteger Pc = [LFUtilities getValueFromHexData:data2];
    
    NSInteger seq = [LFUtilities getValueFromHexData:data6];
    
    
    NSString *type = [LFUtilities conversionJFormate:data3];
    
    
    CGFloat totalPower = (Pa + Pb + Pc)/100000.0f;
    LFDisplay *aTob = [[LFDisplay alloc] initWithKey:@"Power" Value:[NSString stringWithFormat:@"%.3f KW", totalPower] Code:@"P"];
    
    LFDisplay *pfa = [[LFDisplay alloc] initWithKey:@"Power Factor" Value:type Code:@"PF"];
    
    
    LFDisplay *phaseSequence = [[LFDisplay alloc] initWithKey:@"Phase Sequence" Value:[NSString stringWithFormat:@"%d", (int)seq] Code:@"PS"];
    if (seq == 0) {
        phaseSequence.value = @"ABC";
    } else {
        phaseSequence.value = @"ACB";
    }
    
    NSArray *powerDetails = @[aTob, pfa];
    
    NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:faultDict[OTHER_FAULTS]];
    
    [arr addObject:phaseSequence];
    
    
    [faultDict setValue:powerDetails forKey:FAULT_POWER_DETAILS];
    
    [faultDict setValue:arr forKey:OTHER_FAULTS];
    
}


- (void)convertToOtherData:(NSData *)data
{
    NSInteger len = 2;
    NSData *data0, *data1, *data2;
    NSRange range = NSMakeRange(0, len);
    data0 = [data subdataWithRange:range];
    range = NSMakeRange(range.location + range.length, len);
    data1 = [data subdataWithRange:range];
    range = NSMakeRange(range.location + range.length, len);
    data2 = [data subdataWithRange:range];
    DLog(@"Other Data: %@", data);
    NSInteger vub = [LFUtilities getValueFromHexData:data0];
    NSInteger cub = [LFUtilities getValueFromHexData:data1];
    NSInteger freq = [LFUtilities getValueFromHexData:data2];
    DLog(@"Voltage unbalance = %ld", (long)vub);
    DLog(@"Current Unbalance = %ld", (long)cub);
    LFDisplay *vubVal = [[LFDisplay alloc] initWithKey:@"Voltage Unbalance" Value:[NSString stringWithFormat:@"%.1f %%", vub/100.0] Code:@"VUB"];
    LFDisplay *cubVal = [[LFDisplay alloc] initWithKey:@"Current Unbalance" Value:[NSString stringWithFormat:@"%.1f %%", cub/100.0] Code:@"CUB"];
    
    LFDisplay *mf = [[LFDisplay alloc] initWithKey:@"Measured Frequency" Value:[NSString stringWithFormat:@"%.02f Hz", freq/10.0] Code:@"MF"];
    
    NSMutableArray *voltDetails = [[NSMutableArray alloc] initWithArray:faultDict[FAULT_VOLTAGE_DETAILS]];
    [voltDetails addObject:vubVal];
    
    NSMutableArray *currentDetails = [[NSMutableArray alloc] initWithArray:faultDict[FAULT_CURRENT_DETAILS]];
    [currentDetails addObject:cubVal];
    
    NSMutableArray *other = [[NSMutableArray alloc] initWithArray:faultDict[OTHER_FAULTS]];
    
    [other addObject:mf];
    
    
    [faultDict setValue:voltDetails forKey:FAULT_VOLTAGE_DETAILS];
    [faultDict setValue:currentDetails forKey:FAULT_CURRENT_DETAILS];
    [faultDict setValue:other forKey:OTHER_FAULTS];
    
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

#pragma mark Device Disconnected Notification
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

@end
