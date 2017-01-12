//
//  LFFaultViewController.m
//  LittleFuse
//
//  Created by Kranthi on 28/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFFaultViewController.h"
#import "LFCharactersticDisplayCell.h"
#import "LFBluetoothManager.h"
#import "LFDisplay.h"
#import "LFFaultHeaderView.h"
#import "LFFaultTableViewCell.h"
#import "LFFaultData.h"
#import "LFFaultsDetailsController.h"
#import "LFTabbarController.h"

#define Background_Fault_Refresh_Interval 180


@interface LFFaultViewController () <BlutoothSharedDataDelegate, UITableViewDataSource, UITableViewDelegate>
{
    BOOL canContinueTimer;
    NSInteger currentIndex;
    NSMutableArray *sectionArray;
    NSMutableDictionary *faultDict;
    LFFaultData *currentData;
    LFFaultData *prevFaultData;
    NSDate *selectedDate;
    
}
@property (strong, nonatomic) IBOutlet UIDatePicker *datepicker;
@property (weak, nonatomic) IBOutlet UITextField *tfPicker;
@property (weak, nonatomic) IBOutlet UITableView *tblFaults;
@property (weak, nonatomic) IBOutlet UILabel *lblDevice;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectedDate;
@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;

@property (weak, nonatomic) IBOutlet UILabel *noDataLabel;
- (IBAction)cancelAction:(id)sender;

- (IBAction)doneAction:(id)sender;
- (IBAction)selectDate:(UIButton *)sender;
- (IBAction)dateChanged:(UIDatePicker *)sender;

@end

@implementation LFFaultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    currentIndex = 0;
    
    currentData = [[LFFaultData alloc] init];
    faultDict = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    sectionArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSString *name = [[LFBluetoothManager sharedManager] selectedDevice];
    name = [name substringToIndex:name.length-4];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Device ID: %@", name]];
    
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(10, string.length-10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:AERIAL_REGULAR size:15.0] range:NSMakeRange(0, 10)];
    _lblDevice.attributedText = string;
    _tblFaults.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _datepicker.maximumDate = [NSDate date];
    canContinueTimer = YES;
    [LittleFuseNotificationCenter addObserver:self selector:@selector(peripheralDisconnected) name:PeripheralDidDisconnect object:nil];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)appEnteredBackground {
    [[LFBluetoothManager  sharedManager] disconnectDevice];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [_btnSelectedDate setImageEdgeInsets:UIEdgeInsetsMake(0, CGRectGetWidth(self.btnSelectedDate.frame)-30, 0, 0)];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[LFBluetoothManager sharedManager] setConfig:NO];
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [LFBluetoothManager sharedManager].canContinueTimer = NO;
    LFTabbarController *tabBarController = (LFTabbarController *)self.tabBarController;
    [tabBarController setEnableRefresh:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    canContinueTimer = NO;
    [[LFBluetoothManager sharedManager] setConfig:YES];
     self.navigationItem.title = @"";
    [[LFBluetoothManager sharedManager] stopFaultTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    canContinueTimer = YES;
    [LFBluetoothManager sharedManager].canContinueTimer = YES;
    NSDate *date = [NSDate date];
    [self.btnSelectedDate setTitle:[self convertDateToString:date] forState:UIControlStateNormal];
    [self fetchDataWithDate:date];
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:Background_Fault_Refresh_Interval];
}

- (void)updateFaultData {
    if(!canContinueTimer) {
        return;
    }
    [LFBluetoothManager sharedManager].tCurIndex = 0;
    currentIndex = 0;
    [LFBluetoothManager sharedManager].canContinueTimer = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[LFBluetoothManager sharedManager] readFaultData];
    });
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:Background_Fault_Refresh_Interval];
}

- (void)dealloc {
    sectionArray = nil;
    faultDict = nil;
    [LittleFuseNotificationCenter removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)convertDateToString:(NSDate *)date
{
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    [dateformat setTimeZone:[NSTimeZone localTimeZone]];
    [dateformat setDateFormat:@"MMMM dd, YYYY"];
    selectedDate = date;
    NSString *dateString = [dateformat stringFromDate:date];
    [dateformat setDateFormat:@"yyyy-MM-dd"];
    return dateString;
}

- (void)getFaultVoltageData:(NSData *)data
{
    NSRange range = NSMakeRange(2, 4);
    
    NSData *data1 = [data subdataWithRange:range];
    
    NSInteger dateandTime = [LFUtilities getValueFromHexData:data1];
    
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:(dateandTime)];
    
    currentData.date = date;
    currentData.voltage = data;
}

- (void)getFaultCurrentData:(NSData *)data
{
    currentData.current = data;
}

- (void)getFaultPowerData:(NSData *)data
{
    currentData.power = data;
}

- (void)getFaultOtherData:(NSData *)data
{
    currentData.other = data;
    // To save the Data
    if (![self isCurrentDataSameWithPreviousSavedOne]) {
        if (currentData.date && [currentData.date compare:selectedDate ] == NSOrderedAscending) {
            [self showData:currentData.voltage];
        } else {
            _noDataLabel.hidden = NO;
        }
        
        [[LFDataManager sharedManager] saveFaultDetails:currentData WithPeripheral:[[LFBluetoothManager sharedManager] selectedPeripheral]];
        prevFaultData = currentData;
        currentData = nil;
        currentData = [[LFFaultData alloc] init];
        [self  readFaultData];
    } else {
        currentIndex = (currentIndex-1) + [[LFDataManager sharedManager] getTotalFaultsCount];
//        currentIndex = sectionArray.count + 1;;
//        currentIndex += 1;
        [self readFaultData];
        if (sectionArray.count == 0) {
            _noDataLabel.hidden = NO;
        } else {
            _noDataLabel.hidden = YES;
        }
        [_tblFaults reloadData];
    }

}


- (void)showData:(NSData *)data
{
    if (!data || data.length == 0) {
        return;
    }
    NSInteger code = [LFUtilities getValueFromHexData:[data subdataWithRange:NSMakeRange(0, 2)]];
    NSString *faultError = [self faultWithCode:code];
    
    NSString *faultCode = [self faultCodeWithCode:code];
    
    NSInteger dateandTime = [LFUtilities getValueFromHexData:[data subdataWithRange:NSMakeRange(2, 4)]];
    
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:(dateandTime)];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    
    [df setDateFormat:@"MMM dd, yyyy hh:mm a"];
    
    NSString *faultdate = [df stringFromDate:date];
    
    [faultDict setValue:faultdate forKey:FAULT_DATE];
    [faultDict setValue:faultError forKey:FAULT_ERROR];
    
    [faultDict setValue:currentData forKey:FAULT_DETAILS];
    [faultDict setValue:faultCode forKey:FAULT_CODE];
    
    [sectionArray addObject:[faultDict copy]];
    DLog(@"Show data  = %@ current count = %ld", data, (long)sectionArray.count);
    [faultDict removeAllObjects];
    _noDataLabel.hidden = YES;
    if (sectionArray.count >= 10) {
        [_tblFaults beginUpdates];
        [_tblFaults insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sectionArray.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [_tblFaults endUpdates];
    }
    else {
        [_tblFaults reloadData];
    }

}

- (BOOL)isCurrentDataSameWithPreviousSavedOne
{
    LFFaultData *fault = [[LFDataManager sharedManager] getSavedDataWithDate:currentData.date];
    if ([fault.voltage isEqualToData:currentData.voltage] ) {
        return YES;
    }
    return NO;
    
}


- (void)readFaultData
{
    if (!canContinueTimer) {
        return;
    }
    if (currentIndex > 1000) {
        return;
    }
    DLog(@"Reading Fault Data of %d", (int)currentIndex);
    Byte data[20];
    char* bytes = (char*) &currentIndex;
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
    [[LFBluetoothManager sharedManager] writeConfigDataForFaultsList:data1]; //New code
    currentIndex += 1;
    
    
}


#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFFaultTableViewCell *cell = (LFFaultTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LFFaultTableViewCellID" forIndexPath:indexPath];
    // Configure the cell...
    [cell updateDetailsWithDict:[sectionArray objectAtIndex:indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFFaultsDetailsController *faultDeatil = (LFFaultsDetailsController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LFFaultsDetailsControllerID"];
    NSDictionary *dict = [sectionArray objectAtIndex:indexPath.row];
    faultDeatil.errorType = dict[FAULT_ERROR];
    faultDeatil.faultData = dict[FAULT_DETAILS];
    faultDeatil.errorDate = dict[FAULT_DATE];
    
    [self.navigationController pushViewController:faultDeatil animated:YES];
}

- (NSString *)faultCodeWithCode:(NSInteger)code
{
    NSString *error = @"";
    switch (code) {
        case 0:
            error = @"NOFAULT";
            break;
        case 1:
            error = @"OCF";
            break;
        case 2:
            error = @"UCF";
            break;
        case 3:
            error = @"CUBF";
            break;
        case 4:
            error = @"CSPF";
            break;
        case 5:
            error = @"CTCF";
            break;
        case 6:
            error = @"GFF";
            break;
        case 7:
            error = @"HPF";
            break;
        case 8:
            error = @"LPF";
            break;
        case 9:
            error = @"POF";
            break;
        case 10:
            error = @"PTCF";
            break;
        case 11:
            error = @"RMTF";
            break;
        case 100:
            error = @"LVH";
            break;
        case 101:
            error = @"HVH";
            break;
        case 102:
            error = @"VUBH";
            break;
        case 103:
            error = @"PHSQ";
            break;
        case 61166:
            error = @"UNDEFF";
            break;
        default:
            error = @"UNDEFF";
            break;
    }
    return error;
}


- (NSString *)faultWithCode:(NSInteger)code
{
    NSString *error = @"";
    switch (code) {
        case 0:
            error = @"No fault or warning condition";
            break;
        case 1:
            error = @"Over Current";
            break;
        case 2:
            error = @"Under Current";
            break;
        case 3:
            error = @"Current unbalanced";
            break;
        case 4:
            error = @"Current Single Phasing";
            break;
        case 5:
            error = @"Contactor Failure";
            break;
        case 6:
            error = @"Ground Fault";
            break;
        case 7:
            error = @"High Power Fault";
            break;
        case 8:
            error = @"Low Power Fault";
            break;
        case 9:
            error = @"Power Outage Fault";
            break;
        case 10:
            error = @"PTC Fault";
            break;
        case 11:
            error = @"Tripped Triggered From Remote Source";
            break;
        case 100:
            error = @"Low Voltage Holdoff";
            break;
        case 101:
            error = @"High Voltage Holdofff";
            break;
        case 102:
            error = @"Voltage Unbalanced Holdoff";
            break;
        case 103:
            error = @"Phase Sequence";
            break;
        case 61166:
            error = @"Undefined trip condition";
            break;
        default:
            error = @"Undefined trip condition";
            break;
    }
    return error;
}
- (IBAction)cancelAction:(id)sender
{
    [_tfPicker resignFirstResponder];
}

- (IBAction)doneAction:(id)sender
{
    NSString *dateStr = [self convertDateToString:_datepicker.date];
    [self.btnSelectedDate setTitle:dateStr forState:UIControlStateNormal];
    
    [_tfPicker resignFirstResponder];
    
    [self fetchDataWithDate:_datepicker.date];
}

- (void)fetchDataWithDate:(NSDate *)date
{
    NSDate *tomorrow = [NSDate dateWithTimeInterval:(24*60*60) sinceDate:date];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSIntegerMax fromDate:tomorrow];
    [components setHour:5];
    [components setMinute:30];
    [components setSecond:0];
    NSArray *arr = [[LFDataManager sharedManager] getFaultDataForSelectedDate:[components date]];
    NSInteger faultsCount  = sectionArray.count;
    [sectionArray removeAllObjects];
    if (faultsCount > 0) {
        [_tblFaults reloadData];
    }
    if (arr.count) {
        for (LFFaultData *fault in arr) {
            [faultDict removeAllObjects];
            currentData = fault;
            [self showData:fault.voltage];
        }
        currentIndex = 0;
        [self readFaultData];
        
    } else {
        [self.tblFaults reloadData];
        currentIndex = 0;
        [self readFaultData];
    }
    
}

- (IBAction)selectDate:(UIButton *)sender
{
    _tfPicker.inputView = _datepicker;
    _tfPicker.inputAccessoryView = _toolBar;
    [_tfPicker becomeFirstResponder];
    
}
- (IBAction)dateChanged:(UIDatePicker *)sender
{
    
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
