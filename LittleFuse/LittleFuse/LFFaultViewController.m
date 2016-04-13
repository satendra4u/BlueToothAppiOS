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


@interface LFFaultViewController () <BlutoothSharedDataDelegate>
{
    NSMutableArray *sectionArray;
    NSMutableDictionary *faultDict;
    NSInteger currentIndex;
    LFFaultData *currentData;
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
    
    currentIndex = 1;
    
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
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [_btnSelectedDate setImageEdgeInsets:UIEdgeInsetsMake(0, CGRectGetWidth(self.btnSelectedDate.frame)-30, 0, 0)];

}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[LFBluetoothManager sharedManager] setConfig:NO];
    [[LFBluetoothManager sharedManager] setDelegate:self];
    NSDate *date = [NSDate date];
    
    
    [self.btnSelectedDate setTitle:[self convertDateToString:date] forState:UIControlStateNormal];

    [self fetchDataWithDate:date];

}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";
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
        currentData = nil;
        currentData = [[LFFaultData alloc] init];
        
        [self  readFaultData];
    } else {
        currentIndex = (currentIndex-1) + [[LFDataManager sharedManager] getTotalFaultsCount];
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
    
    [faultDict removeAllObjects];
    _noDataLabel.hidden = YES;
    [_tblFaults reloadData];

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
    [[LFBluetoothManager sharedManager] writeConfigData:data1];
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
        case 1:
            error = @"OC";
            break;
        case 2:
            error = @"UC";
            break;
        case 3:
            error = @"CUB";
            break;
        case 4:
            error = @"CSP";
            break;
        case 5:
            error = @"CF";
            break;
        case 6:
            error = @"GF";
            break;
        case 7:
            error = @"HP";
            break;
        case 8:
            error = @"LP";
            break;
        case 9:
            error = @"LCV";
            break;
        case 10:
            error = @"PTC";
            break;
            
            
        default:
            break;
    }
    return error;
}


- (NSString *)faultWithCode:(NSInteger)code
{
    NSString *error = @"";
    switch (code) {
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
            error = @"High Power";
            break;
        case 8:
            error = @"Low Power";
            break;
        case 9:
            error = @"Low Control Voltage";
            break;
        case 10:
            error = @"PTC";
            break;
//        case 11:// uncomment data
//            error = @"PTC";
//            break;
//        case 100:
//            error = @"PTC";
//            break;
//        case 101:
//            error = @"PTC";
//            break;
//        case 102:
//            error = @"PTC";
//            break;
//        case 61166:
//            error = @"PTC";
//            break;
//            

    
        default:
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
    [sectionArray removeAllObjects];
    if (arr.count) {
        for (LFFaultData *fault in arr) {
            [faultDict removeAllObjects];
            currentData = fault;
            [self showData:fault.voltage];
        }
        currentIndex = 1;
        [self readFaultData];

    } else {
        [sectionArray removeAllObjects];
        [self.tblFaults reloadData];

        currentIndex = 1;
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
@end
