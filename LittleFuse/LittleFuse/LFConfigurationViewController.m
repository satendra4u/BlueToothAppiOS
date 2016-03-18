//
//  ConfigurationViewController.m
//  LittleFuse
//
//  Created by Kranthi on 27/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFConfigurationViewController.h"
#import "LFBluetoothManager.h"
#import "LFCharactersticDisplayCell.h"
#import "LFDisplay.h"
#import "LFEditingViewController.h"
#import "LFNavigationController.h"
#import "LFConfigureButtonsCell.h"
#import "LFCommunicationSettingsController.h"
#import "LFRTDViewController.h"

#define BUTTON_CELL_ID @"LFConfigureButtonsCellID"
@interface LFConfigurationViewController () < EditingDelegate, BlutoothSharedDataDelegate>
{
    
    __weak IBOutlet UITableView *tblConfigDisplay;
    NSMutableArray *basicConfigDetails;
    NSMutableArray *advanceConfigDetails;
    NSArray  *basicFormateArray;
    NSArray *advancedFormateArray;
    BOOL isBasic;
    NSInteger currentIndex;
    NSMutableArray *basicValuesArray;
    NSArray *basicUnitsArray, *advUnitsArray;
    
    NSInteger selectedTag;
    BOOL isWrite;
    NSString *previousSelected;
    BOOL isAdvanceLoded;

    
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UILabel *deviceId;

- (IBAction)segmentControlAction:(UISegmentedControl *)sender;

@end

@implementation LFConfigurationViewController

const char basicMemMap[] = {0x0A,
    0x0E, 0x12, 0x16, 0x1A, 0x20, 0x14, 0x26, 0x2A, 0x2E, 0x32};

const char basicMemFieldLens[] = { 0x04, 0x04, 0x02, 0x04, 0x04, 0x02, 0x02, 0x04, 0x04, 0x04, 0x04
};

const char advance_MemMap[] = {0x06, 0x08, 0x1E, 0x22, 0x24, 0x3A, 0x3E, 0x40,
    0x42, 0x46, 0x4A, 0x4C, 0x4E, 0x50, 0x56, 0x5A};
const char advance_MemMapFieldLens[] = {0x2, 0x2, 0x2, 0x2, 0x2, 0x4, 0x2, 0x2, 0x4, 0x4, 0x2, 0x2, 0x2, 0x2, 0x4, 0x04};


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    advanceConfigDetails = [[NSMutableArray alloc] initWithCapacity:0];
    basicValuesArray = [[NSMutableArray alloc] initWithCapacity:0];

    [tblConfigDisplay registerNib:[UINib nibWithNibName:@"LFCharactersticDisplayCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:CHARACTER_DISPLAY_CELL_ID];
    [tblConfigDisplay registerNib:[UINib nibWithNibName:@"LFConfigureButtonsCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:BUTTON_CELL_ID];

    tblConfigDisplay.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    NSString *name = [[LFBluetoothManager sharedManager] selectedDevice];
    name = [name substringToIndex:name.length-4];
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Device ID: %@", name]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(10, string.length-10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:AERIAL_REGULAR size:15.0] range:NSMakeRange(0, 10)];
    _deviceId.attributedText = string;
    
    [self configArr];
    previousSelected = @"";
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [[LFBluetoothManager sharedManager] setConfig:YES];
//    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
//    [self readCharactisticsWithIndex:currentIndex];

}

- (void)configArr
{
    LFDisplay *lowVoltage = [[LFDisplay alloc] initWithKey:@"Low Voltage" Value:@"" Code:@"LV"];
    LFDisplay *highVoltage = [[LFDisplay alloc] initWithKey:@"High Voltage" Value:@"" Code:@"HV"];
    LFDisplay *voltageUnb = [[LFDisplay alloc] initWithKey:@"Voltage  Unbalance" Value:@"" Code:@"VUB"];
    
    LFDisplay *overCurrent = [[LFDisplay alloc] initWithKey:@"Over Current" Value:@"" Code:@"OC"];
    LFDisplay *underCurrent = [[LFDisplay alloc] initWithKey:@"Under Current" Value:@"" Code:@"UC"];
    LFDisplay *currentUnb = [[LFDisplay alloc] initWithKey:@"Current  Unbalance" Value:@"" Code:@"CUB"];
    LFDisplay *tripClass = [[LFDisplay alloc] initWithKey:@"Trip Class" Value:@"" Code:@"TC"];
    
    LFDisplay *powerUpTimer = [[LFDisplay alloc] initWithKey:@"Power up timer" Value:@"" Code:@"RD0"];

    LFDisplay *rapidTimer = [[LFDisplay alloc] initWithKey:@"Rapid-cycle timer" Value:@"" Code:@"RD1"];
    LFDisplay *motorCoolDown = [[LFDisplay alloc] initWithKey:@"Motor cool-down timer" Value:@"" Code:@"RD2"];
    LFDisplay *dryWellRecover = [[LFDisplay alloc] initWithKey:@"Dry-well recovery timer" Value:@"" Code:@"RD3"];
    
    basicUnitsArray = @[@"VAC", @"VAC", @"%", @"amps", @"amps", @"%", @"",@"sec", @"sec", @"sec", @"sec"];
    advUnitsArray = @[@"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @""];
    
    basicConfigDetails = [[NSMutableArray alloc] initWithObjects:lowVoltage, highVoltage, voltageUnb, overCurrent, underCurrent, currentUnb, tripClass, powerUpTimer, rapidTimer, motorCoolDown,  dryWellRecover,nil];
    
    LFDisplay *currentTansformer = [[LFDisplay alloc] initWithKey:@"Current Transformer Ratio" Value:@"" Code:@"CT"];
    LFDisplay *pt = [[LFDisplay alloc] initWithKey:@"Potential Transformer Ratio" Value:@"" Code:@"PT"];
    LFDisplay *uctd = [[LFDisplay alloc] initWithKey:@"Undercurrent Trip Delay" Value:@"" Code:@"UCTD"];
    LFDisplay *cutd = [[LFDisplay alloc] initWithKey:@"Current Unbalance Trip Delay" Value:@"" Code:@"CUTD"];
    
    LFDisplay *lin = [[LFDisplay alloc] initWithKey:@"Linear Over Current Trip Delay" Value:@"" Code:@"LIN"];
    LFDisplay *gftc = [[LFDisplay alloc] initWithKey:@"Ground Fault Trip Current" Value:@"" Code:@"GFTC"];
    LFDisplay *gftd = [[LFDisplay alloc] initWithKey:@"Ground Fault Trip Delay" Value:@"" Code:@"GFTD"];
    LFDisplay *gfib = [[LFDisplay alloc] initWithKey:@"Ground Fault Inhibit Delay" Value:@"" Code:@"GFIB"];
    LFDisplay *lkw = [[LFDisplay alloc] initWithKey:@"Low Power Trip Limit" Value:@"" Code:@"LKW"];
    
    LFDisplay *hkw = [[LFDisplay alloc] initWithKey:@"High Power Trip Limit" Value:@"" Code:@"HKW"];
    LFDisplay *hptd = [[LFDisplay alloc] initWithKey:@"High Power Trip Delay" Value:@"" Code:@"HPTD"];
    
    
    LFDisplay *stallPercenage = [[LFDisplay alloc] initWithKey:@"Stall Percentage" Value:@"" Code:@"STLP"];
    LFDisplay *stallTripDelay = [[LFDisplay alloc] initWithKey:@"Stall Trip Delay" Value:@"" Code:@"STTD"];
    
    LFDisplay *stallInhibt = [[LFDisplay alloc] initWithKey:@"Stall Inhibit Delay" Value:@"" Code:@"STID"];
    LFDisplay *fetaure = [[LFDisplay alloc] initWithKey:@"Feature enable/disable Mask" Value:@"" Code:@"ENDIS"];

    LFDisplay *cnfg = [[LFDisplay alloc] initWithKey:@"Hardware Configuration Fields" Value:@"00000000" Code:@"CNFG"];
    
    //"Stall Percentage", "Stall Trip Delay", "Stall Inhibit Delay", "Feature enable/disable Mask"
    
    advanceConfigDetails = [[NSMutableArray alloc] initWithObjects:currentTansformer, pt, uctd, cutd, lin, gftc, gftd, gfib, lkw, hkw, hptd, stallPercenage, stallTripDelay, stallInhibt, fetaure, cnfg, nil];
    
    isBasic = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureServiceWithValue:) name:CONFIGURATION_NOTIFICATION object:nil];
    
    
    basicFormateArray = @[@"H", @"H", @"B", @"H", @"H", @"B",  @"B",  @"L", @"L", @"L", @"L"];
    advancedFormateArray = @[@"B", @"B", @"L", @"Q", @"L", @"H", @"Q", @"L", @"K", @"K", @"L", @"B", @"Q", @"Q", @"C", @"C"];
    currentIndex = 0;

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    [self readCharactisticsWithIndex:currentIndex];
    isAdvanceLoded = NO;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isBasic) {
        return 3;
    };
    return 1;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isBasic) {
        if (section == 0) {
            return 3;
        } else if (section == 1) {
            return 4;
        } else if (section == 2) {
            return 4;
        }
        return 0;

    } else {
        return  advanceConfigDetails.count+1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!isBasic  && indexPath.row == advanceConfigDetails.count) {
        LFConfigureButtonsCell *cell = (LFConfigureButtonsCell *)[tableView dequeueReusableCellWithIdentifier:BUTTON_CELL_ID forIndexPath:indexPath];
        [cell.btnCommunication addTarget:self action:@selector(showCommunication:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnRTD addTarget:self action:@selector(showRTD:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tableView dequeueReusableCellWithIdentifier:CHARACTER_DISPLAY_CELL_ID forIndexPath:indexPath];
    if (isBasic) {
        NSInteger cont = 0;
        for (NSInteger i = 0; i < indexPath.section; i++) {
            cont += [tableView numberOfRowsInSection:i];
        }
        cont += indexPath.row;
        [cell updateValues:[basicConfigDetails objectAtIndex:cont]];

    } else {
        [cell updateValues:[advanceConfigDetails objectAtIndex:indexPath.row]];
    }
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!isBasic) {
        return nil;
    }
    
    UIView *aView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 40)];
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, 40)];
    switch (section) {
        case 0:
            aLabel.text = @"Voltage Settings";
            break;
        case 1:
            aLabel.text = @"Current Settings";
            break;
        case 2:
            aLabel.text = @"Timer  Settings";
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!isBasic && indexPath.row == advanceConfigDetails.count) {
        return 80.0;
    }
    return 75.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (isBasic) {
        return 44.0;
    }
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!isBasic && advanceConfigDetails.count == indexPath.row) {
        return;
    }
    NSInteger cont = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        cont += [tableView numberOfRowsInSection:i];
    }
    selectedTag = cont + indexPath.row;
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tblConfigDisplay cellForRowAtIndexPath:indexPath];
    
    LFNavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingNavigationController"];
    LFEditingViewController *editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
    
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    
    editing.selectedText = cell.lblKey.text;
    editing.delegate = self;
    editing.showAuthentication = YES;
    [navController setViewControllers:@[editing]];
    [self.navigationController presentViewController:navController animated:NO completion:nil];
    
}

- (IBAction)segmentControlAction:(UISegmentedControl *)sender
{
    [[LFBluetoothManager sharedManager] setDelegate:nil];
    currentIndex = 0;
    previousSelected = @"";
    if (sender.selectedSegmentIndex == 0) {
        isBasic = YES;
    } else {
        isBasic = NO;
        if (!isAdvanceLoded) {
            [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
            [self readCharactisticsWithIndex:currentIndex];
            isAdvanceLoded = YES;
        }
    }

    [tblConfigDisplay reloadData];
}

- (void)configureServiceWithValue:(NSData *)data
{
    NSLog(@"%s", __func__);

//    NSDictionary *dict = notification.object;
//    NSString *selectedVal = dict[@"tag"];
//    if ([previousSelected isEqualToString:selectedVal]) {
//        return;
//    }
//    previousSelected = selectedVal;
//    NSData *data = dict[@"val"];
    NSString *formate = isBasic ? basicFormateArray[currentIndex] : advancedFormateArray[currentIndex];

    NSRange range = NSMakeRange(0, 4);
    
    data = [data subdataWithRange:range];

    
    [self getValuesFromData:data withForamte:formate];
    
    if (isWrite) {
        isWrite = NO;
        currentIndex = 0;
        return;
    }
    
    currentIndex = currentIndex + 1;
    if (isBasic) {
        if (currentIndex > basicConfigDetails.count - 1) {
            currentIndex = 0;
            [self removeIndicator];
            return;
        }
    } else {
        if (currentIndex > advanceConfigDetails.count - 1) {
            currentIndex = 0;
            [self removeIndicator];
            return;
        }
    }
    [self readCharactisticsWithIndex:currentIndex];

    
}

- (void)readCharactisticsWithIndex:(NSInteger)index;
{
    [[LFBluetoothManager sharedManager] setDelegate:self];

      Byte data[20];
    for (int i=0; i < 20; i++) {
        if (i== 8) {
            data[i] = isBasic ? basicMemMap[index] : advance_MemMap[index];
        } else if (i == 10){
            data[i] = isBasic ? basicMemFieldLens[index] : advance_MemMapFieldLens[index];
        } else {
            data[i] = (Byte)0x00;
        }
    }
    
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    NSData *data1 = [NSData dataWithBytes:data length:20];
    [[LFBluetoothManager sharedManager] setSelectedTag:[NSString stringWithFormat:@"%d", (int)index]];
    [[LFBluetoothManager sharedManager] writeConfigData:data1];
}

- (void)getValuesFromData:(NSData *)data withForamte:(NSString *)formate
{
    
    NSUInteger val = [LFUtilities getValueFromHexData:data];
    
    unichar c = [formate characterAtIndex:0];
    
    NSString *convertedVal = [NSString stringWithFormat:@"%0.2lu", (unsigned long)val];
    
    switch (c) {
        case 'B':
            if (isBasic) {
                convertedVal = [NSString stringWithFormat:@"%d %@", (int)val, basicUnitsArray[currentIndex]];
            } else {
                convertedVal = [NSString stringWithFormat:@"%d", (int)val];
            }
            break;
        case 'H':
        case 'I':
        {
            if (isBasic) {
                if (currentIndex == 0 || currentIndex == 1) {
                    convertedVal = [NSString stringWithFormat:@"%d %@", (int)(val/100),basicUnitsArray[currentIndex]];
                } else {
                    NSString *strVal = [NSNumber numberWithFloat:val/100.0].stringValue;
                    convertedVal = [NSString stringWithFormat:@"%@ %@", [strVal substringToIndex:strVal.length-1], basicUnitsArray[currentIndex]];

                }
            } else {
                 convertedVal = [NSString stringWithFormat:@"%.2f", val/100.0];
            }
        }
            break;
        case 'D':
        {
            convertedVal = [LFUtilities convertToDFormate:val];
            
        }
            break;
        case 'C':
        {
            convertedVal = [LFUtilities convertToCFormate:data];
            break;
        }
        case 'L' :
        {
            convertedVal = [LFUtilities convertToLFormate:val];

        }
            break;
        case 'Q' :
        {
            convertedVal = [NSString stringWithFormat:@"%d sec", (int)val];
        }

            break;
        case 'K': //formate H with Kilo Wats conversion
        {
            convertedVal = [NSString stringWithFormat:@"%.3f KW", val/(100.0*1000)];
        }
            break;

        default:
            break;
    }
    
    //I and B are Same
    if (isBasic) {
        LFDisplay *display = [basicConfigDetails objectAtIndex:currentIndex];
        display.value = convertedVal;
        [basicConfigDetails replaceObjectAtIndex:currentIndex withObject:display];
    } else {
        LFDisplay *display = [advanceConfigDetails objectAtIndex:currentIndex];
        display.value = convertedVal;
        [advanceConfigDetails replaceObjectAtIndex:currentIndex withObject:display];

    }
    
    DLog(@"data %@", data);
    [tblConfigDisplay reloadData];
    
}


- (void)writeDataToIndex:(NSInteger)index withValue:(float)val
{
    isWrite = YES;
    currentIndex = index;
    NSString *formate = isBasic ? basicFormateArray[currentIndex]: advancedFormateArray[currentIndex];
    unichar c = [formate characterAtIndex:0];

    switch (c) {
        case 'B':
            val = val;
            break;
        case 'H':
        case 'I':
            val = val*100;
            break;
        case 'L':
        case 'Q':
            val = val;
            break;
        case 'K': //formate H with Kilo Wats conversion
        {
            val = val * (100.0*1000);
        }
            break;
        default:
            break;
    }
    Byte data[20];
    
    NSInteger convertedVal = (NSInteger)val;
    char* bytes = (char*) &convertedVal;
    
    for (int i=0; i < 20; i++) {
        if (i < 8) {
            data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
        } else {
            if (i== 8) {
                data[i] = isBasic ? basicMemMap[index] : advance_MemMap[index];
            } else if (i == 10){
                data[i] = isBasic ? basicMemFieldLens[index] : advance_MemMapFieldLens[index];
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            } else {
                data[i] = (Byte)0x00;
            }
        }
    
    }

    NSData *data1 = [NSData dataWithBytes:data length:20];
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] writeConfigData:data1];

}


#pragma mark -Editing Delegate
- (void)selectedValue:(NSString *)txt
{
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    if (txt.length == 0) {
        txt = @"";
    }

    LFDisplay *display;
    if (isBasic) {
        display = [basicConfigDetails objectAtIndex:selectedTag];
        display.value = txt;
        [basicConfigDetails replaceObjectAtIndex:selectedTag withObject:display];
    } else {
        display = [advanceConfigDetails objectAtIndex:selectedTag];
        display.value = txt;
        [advanceConfigDetails replaceObjectAtIndex:selectedTag withObject:display];

    }
    
    [self writeDataToIndex:selectedTag withValue:txt.floatValue];
}

 - (void)showOperationCompletedAlert
{
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    [self readCharactisticsWithIndex:selectedTag];
    [self removeIndicator];
    [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Data saved successfully." withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
        if ([alert isKindOfClass:[UIAlertController class]]) {
            [alert dismissViewControllerAnimated:NO completion:nil];
        }
        [tblConfigDisplay reloadData];
    }];
}

- (void)showCommunication:(UIButton *)btn
{
    LFCommunicationSettingsController *communication = (LFCommunicationSettingsController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LFCommunicationSettingsControllerID"];
    [self.navigationController pushViewController:communication animated:YES];
}

- (void)showRTD:(UIButton *)btn
{
    LFRTDViewController *rtd = (LFRTDViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LFRTDViewControllerID"];
    [self.navigationController pushViewController:rtd animated:YES];
    
}

- (void)dealloc
{
    NSLog(@"%s", __func__);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
