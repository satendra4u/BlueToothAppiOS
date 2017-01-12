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
#import "LFCharactersticBitDisplayCell.h"
#import "LFTabbarController.h"
#import "LFAuthUtils.h"

#define BUTTON_CELL_ID @"LFConfigureButtonsCellID"
#define TOGGLE_CELL_ID @"LFCharactersticBitDisplayCell"

#define FirstNameRegAddr 0x006A
#define SecondNameRegAddr 0x0072
#define FirstNameRegLen 0x08
#define SecondNameRegLen 0x04

#pragma mark Info regarding sections in the table.

#define BasicSection0RowsCount 3
#define BasicSection1RowsCount 4
#define BasicSection2RowsCount 4
#define BasicSection3RowsCount 2
#define AdvancedSection0RowsCount 12
#define AdvancedSection1RowsCount 8
#define AdvancedSection2RowsCount 9

@interface LFConfigurationViewController () < EditingDelegate, BlutoothSharedDataDelegate, ToggleTappedProtocol, LFTabbarRefreshDelegate>
{
    
    LFAuthUtils *authUtils;
    __weak IBOutlet UITableView *tblConfigDisplay;
    NSMutableArray *basicConfigDetails;
    NSMutableArray *advanceConfigDetails;
    NSMutableArray *basicValuesArray;
    
    NSArray  *basicFormateArray;
    NSArray *advancedFormateArray;
    NSArray *basicUnitsArray, *advUnitsArray;
    NSArray *characteristicsList;
    
    BOOL isBasic;
    BOOL isWrite;
    BOOL isAdvanceLoded;
    BOOL canContinueTimer;
    BOOL isInitialLaunch;
    BOOL isFetchingMacOrSeedData;
    BOOL isReRead;
    BOOL canRefresh;
    BOOL isReadingFriendlyName;
    BOOL isVerifyingPassword;
    BOOL isChangingPassword;
    NSInteger curPassWriteIndex;
    NSString *macString;
    NSData *configSeedData;
    NSData *prevWrittenData;
    NSData *completePasswordData;
    NSString *passwordVal;
    NSString *friendlyNameStr;
    
    NSInteger currentIndex;
    NSInteger selectedTag;
    NSString *previousSelected;
    NSInteger prevEnteredVal;//Used to compare previously entered value.
    
    UIView *changePasswordView;
    UIButton *changePasswordButton;
    LFEditingViewController *editing;
    
}
@property (nonatomic) NSUInteger hardwareConfigVal;
@property (nonatomic) NSUInteger featureEndisVal;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UILabel *deviceId;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
- (IBAction)editAction:(id)sender;

- (IBAction)segmentControlAction:(UISegmentedControl *)sender;

@end

@implementation LFConfigurationViewController

const char basicMemMap[] = {0x0A,
    0x0E, 0x12, 0x16, 0x1A, 0x20, 0x14, 0x26, 0x2A, 0x2E, 0x32, 0x36, 0x38};

const char basicMemFieldLens[] = { 0x04, 0x04, 0x02, 0x04, 0x04, 0x02, 0x02, 0x04, 0x04, 0x04, 0x04, 0x02, 0x02
};

const char advance_MemMap[] = {0x06, 0x08, 0x1E,/* 0x22,*/ 0x24, 0x3A, 0x3E,/* 0x40,*/
    0x42, 0x46, 0x4A, 0x4C, 0x4E, 0x50, 0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x5A,0x5A,0x5A,0x5A,0x5A,0x5A,0x5A,0x5A};
const char advance_MemMapFieldLens[] = {0x2, 0x2, 0x2,/* 0x2,*/ 0x2, 0x4, 0x2,/* 0x2,*/ 0x4, 0x4, 0x2, 0x2, 0x2, 0x2, 0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04,0x04};

const char changePassword_AddrArr[] = {0x0094, 0x009C, 0x00A4, 0x00AC, 0x00B4, 0x00BC, 0x00C4, 0x00CC};

- (void)viewDidLoad
{
    [super viewDidLoad];
    curPassWriteIndex = 0;
    isInitialLaunch = YES;
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"ChangePasswordView"
                                                      owner:self
                                                    options:nil];
    changePasswordView = nibViews[0];
    [changePasswordView setFrame: CGRectMake(0, 0, CGRectGetWidth(self.view.window.frame), CGRectGetHeight(changePasswordView.frame))];
    // Do any additional setup after loading the view.
    advanceConfigDetails = [[NSMutableArray alloc] initWithCapacity:0];
    basicValuesArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    [tblConfigDisplay registerNib:[UINib nibWithNibName:@"LFCharactersticDisplayCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:CHARACTER_DISPLAY_CELL_ID];
    [tblConfigDisplay registerNib:[UINib nibWithNibName:@"LFCharactersticBitDisplayCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:TOGGLE_CELL_ID];
    [tblConfigDisplay registerNib:[UINib nibWithNibName:@"LFConfigureButtonsCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:BUTTON_CELL_ID];
    
    tblConfigDisplay.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    NSString *name = [[LFBluetoothManager sharedManager] selectedDevice];
    name = [name substringToIndex:name.length-4];
    [self setDeviceName:name];
    [self configArr];
    previousSelected = @"";
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [LittleFuseNotificationCenter addObserver:self selector:@selector(peripheralDisconnected) name:PeripheralDidDisconnect object:nil];
    isAdvanceLoded = NO;
    [LittleFuseNotificationCenter addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self setUpTableViewFooter];
    [tblConfigDisplay reloadData];
}

- (void)setDeviceName:(NSString *)deviceName {
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Device ID: %@", deviceName]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(10, string.length-10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:AERIAL_REGULAR size:15.0] range:NSMakeRange(0, 10)];
    _deviceId.attributedText = string;}

- (void)appEnteredBackground {
    DLog(@"App entered background");
    [[LFBluetoothManager  sharedManager] disconnectDevice];
}

/**
 * This method sets up configuration data to display
 */
- (void)configArr
{
    basicUnitsArray = @[@"VAC", @"VAC", @"%", @"amps", @"amps", @"%", @"",@"sec", @"sec", @"sec", @"sec",@"",@""];
    advUnitsArray = @[@"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @""/*, @"", @""*/];
    // Voltage Settings
    LFDisplay *lowVoltage = [[LFDisplay alloc] initWithKey:@"Low Voltage" Value:@"" Code:@"LV"];
    LFDisplay *highVoltage = [[LFDisplay alloc] initWithKey:@"High Voltage" Value:@"" Code:@"HV"];
    LFDisplay *voltageUnb = [[LFDisplay alloc] initWithKey:@"Voltage  Unbalance" Value:@"" Code:@"VUB"];
    
    // Current Settings
    LFDisplay *overCurrent = [[LFDisplay alloc] initWithKey:@"Over Current" Value:@"" Code:@"OC"];
    LFDisplay *underCurrent = [[LFDisplay alloc] initWithKey:@"Under Current" Value:@"" Code:@"UC"];
    LFDisplay *currentUnb = [[LFDisplay alloc] initWithKey:@"Current  Unbalance" Value:@"" Code:@"CUB"];
    LFDisplay *tripClass = [[LFDisplay alloc] initWithKey:@"Trip Class" Value:@"" Code:@"TC"];
    
    // Timer Settings
    LFDisplay *powerUpTimer = [[LFDisplay alloc] initWithKey:@"Power up timer" Value:@"" Code:@"RD0"];
    LFDisplay *rapidTimer = [[LFDisplay alloc] initWithKey:@"Rapid-cycle timer" Value:@"" Code:@"RD1"];
    LFDisplay *motorCoolDown = [[LFDisplay alloc] initWithKey:@"Motor cool-down timer" Value:@"" Code:@"RD2"];
    LFDisplay *dryWellRecover = [[LFDisplay alloc] initWithKey:@"Dry-well recovery timer" Value:@"" Code:@"RD3"];
    
    // Restart Attempts
    LFDisplay *restartAttemptsUCTrips = [[LFDisplay alloc] initWithKey:@"Restart attempts for undercurrent trips" Value:@"" Code:@"RU"];
    LFDisplay *restartAttemptsOtherTrips = [[LFDisplay alloc] initWithKey:@"Restart attempts for all other trips" Value:@"" Code:@"RF"];
    
    
    
    basicConfigDetails = [[NSMutableArray alloc] initWithObjects:lowVoltage, highVoltage, voltageUnb, overCurrent, underCurrent, currentUnb, tripClass, powerUpTimer, rapidTimer, motorCoolDown,  dryWellRecover,restartAttemptsUCTrips,restartAttemptsOtherTrips,nil];
    
    LFDisplay *currentTansformer = [[LFDisplay alloc] initWithKey:@"Current Transformer Ratio" Value:@"" Code:@"CT"];
    LFDisplay *pt = [[LFDisplay alloc] initWithKey:@"Potential Transformer Ratio" Value:@"" Code:@"PT"];
    LFDisplay *ultd = [[LFDisplay alloc] initWithKey:@"Under Load Trip Delay" Value:@"" Code:@"ULTD"];
    //    LFDisplay *cutd = [[LFDisplay alloc] initWithKey:@"Current Unbalance Trip Delay" Value:@"" Code:@"CUTD"];
    //Commented as per client requirement .Can be uncommented to add at 4th position.
    LFDisplay *lin = [[LFDisplay alloc] initWithKey:@"Linear Over Current Trip Delay" Value:@"" Code:@"LINTD"];
    LFDisplay *gftc = [[LFDisplay alloc] initWithKey:@"Ground Fault Trip Current" Value:@"" Code:@"GFTC"];
    LFDisplay *gftd = [[LFDisplay alloc] initWithKey:@"Ground Fault Trip Delay" Value:@"" Code:@"GFTD"];
    //    LFDisplay *gfib = [[LFDisplay alloc] initWithKey:@"Ground Fault Inhibit Delay" Value:@"" Code:@"GFIB"];
    //Commented as per client requirement .Can be uncommented to add at 8th position.
    LFDisplay *lkw = [[LFDisplay alloc] initWithKey:@"Low Power Trip Limit" Value:@"" Code:@"LKW"];
    
    LFDisplay *hkw = [[LFDisplay alloc] initWithKey:@"High Power Trip Limit" Value:@"" Code:@"HKW"];
    LFDisplay *hptd = [[LFDisplay alloc] initWithKey:@"High Power Trip Delay" Value:@"" Code:@"HPTD"];
    
    
    LFDisplay *stallPercenage = [[LFDisplay alloc] initWithKey:@"Stall Percentage" Value:@"" Code:@"STLP"];
    LFDisplay *stallTripDelay = [[LFDisplay alloc] initWithKey:@"Stall Trip Delay" Value:@"" Code:@"STTD"];
    
    LFDisplay *stallInhibt = [[LFDisplay alloc] initWithKey:@"Stall Inhibit Delay" Value:@"" Code:@"STID"];
    
    LFDisplay *bitZero = [[LFDisplay alloc] initWithKey:@"GF Trip" Value:@"" Code:@"GFT"];
    LFDisplay *bitOne = [[LFDisplay alloc] initWithKey:@"VUB Trip" Value:@"" Code:@"VUBT"];
    LFDisplay *bitTwo = [[LFDisplay alloc] initWithKey:@"CUB Trip" Value:@"" Code:@"CUBT"];
    LFDisplay *bitThree = [[LFDisplay alloc] initWithKey:@"UC Trip" Value:@"" Code:@"UCT"];
    LFDisplay *bitFour = [[LFDisplay alloc] initWithKey:@"OC Trip" Value:@"" Code:@"OCT"];
    LFDisplay *bitFive = [[LFDisplay alloc] initWithKey:@"Linear Overcurrent Trip" Value:@"" Code:@"LINT"];
    LFDisplay *bitSix = [[LFDisplay alloc] initWithKey:@"LPR Trip" Value:@"" Code:@"LPRT"];
    LFDisplay *bitSeven = [[LFDisplay alloc] initWithKey:@"HPR Trip" Value:@"" Code:@"HPRT"];
    LFDisplay *configBitFive = [[LFDisplay alloc] initWithKey:@"Single Phase Motor" Value:@"" Code:@"SPM"];
    LFDisplay *configBitSix = [[LFDisplay alloc] initWithKey:@"Single PT Connected" Value:@"" Code:@"SPTC"];
    LFDisplay *configBitSeven = [[LFDisplay alloc] initWithKey:@"Single Phase current" Value:@"" Code:@"SPC"];
    LFDisplay *configBitEight = [[LFDisplay alloc] initWithKey:@"Disable RP" Value:@"" Code:@"RP"];
    LFDisplay *configBitNine = [[LFDisplay alloc] initWithKey:@"Low Control voltage trip" Value:@"" Code:@"LCVT"];
    LFDisplay *configBitTen = [[LFDisplay alloc] initWithKey:@"Stall 1" Value:@"" Code:@"STAL"];
    LFDisplay *configBitEleven = [[LFDisplay alloc] initWithKey:@"Low KV mode" Value:@"" Code:@"LKV"];
    LFDisplay *configBitTwelve = [[LFDisplay alloc] initWithKey:@"Enable ACB phase rotation" Value:@"" Code:@"ACB"];
    
    
    //"Stall Percentage", "Stall Trip Delay", "Stall Inhibit Delay", "Feature enable/disable Mask"
    
    advanceConfigDetails = [[NSMutableArray alloc] initWithObjects:currentTansformer, pt, ultd/*, cutd*/, lin, gftc, gftd,/* gfib,*/ lkw, hkw, hptd, stallPercenage, stallTripDelay, stallInhibt, bitZero, bitOne, bitTwo, bitThree, bitFour, bitFive, bitSix, bitSeven, configBitFive, configBitSix, configBitSeven, configBitEight, configBitNine, configBitTen, configBitEleven, configBitTwelve, nil];
    
    isBasic = YES;
    
    [LittleFuseNotificationCenter addObserver:self selector:@selector(configureServiceWithValue:) name:CONFIGURATION_NOTIFICATION object:nil];
    basicFormateArray = @[@"H", @"H", @"G", @"B", @"B", @"G",  @"B",  @"L", @"L", @"L", @"L",@"B",@"B"];
    advancedFormateArray = @[@"B", @"B", @"L",/* @"Q",*/ @"L", @"H", @"Q",/* @"L",*/ @"K", @"K", @"L", @"B", @"Q", @"Q", @"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C"];
    currentIndex = 0;
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    canContinueTimer = NO;
    [self removeIndicator];
    [[LFBluetoothManager sharedManager] stopFaultTimer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    LFTabbarController *tabBarController = (LFTabbarController *)self.tabBarController;
    [tabBarController setEnableRefresh:YES];
    tabBarController.tabBarDelegate = self;
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] setDelegate:self];
    canContinueTimer = YES;
    if (isInitialLaunch) {
        isInitialLaunch = NO;
        [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
        [self readCharactisticsWithIndex:currentIndex];
    }
    
    
}

- (void)showCharacterstics:(NSMutableArray *)charactersticsArray
{
    CBCharacteristic *charactestic = (CBCharacteristic *)charactersticsArray[2];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
}

#pragma mark Read Mac Data
- (void)receivedDeviceMacWithData:(NSData *)data {
    NSLog(@"%s", __func__);
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
    macString = tString;
    [self performSelector:@selector(getSeedData) withObject:nil afterDelay:2];
}

- (void)getSeedData {
    NSLog(@"%s", __func__);
    isFetchingMacOrSeedData = YES;
    NSArray *charsArr = [LFBluetoothManager sharedManager].discoveredPeripheral.services[1].characteristics;
    CBCharacteristic *charactestic = (CBCharacteristic *)charsArr[4];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
}

#pragma mark Generate Excrypted Data
- (NSData *)getEncryptedPasswordDataFromString:(NSString *)newPassword data:(NSData *)writeData address:(short)address size:(short)size{
    if (authUtils == nil) {
        authUtils = [[LFAuthUtils alloc]init];
    }
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        [authUtils initWithPassKey:passwordVal andMacAddress:macString andSeed:configSeedData.bytes];
    }
    NSData * authCode = [authUtils computeAuthCode:writeData.bytes address:address size:size];
    
    return authCode;
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self performSelector:@selector(stopIndicator) withObject:nil afterDelay:5.5];
    if (configSeedData != nil) {
        [self updateFaultData];
    }
//    updateFaultData
}

- (void)stopIndicator {
    if (isBasic && currentIndex == 0) {
        [self removeIndicator];
    }
    else {
        if (isAdvanceLoded && currentIndex == 0) {
            [self removeIndicator];
        }
    }
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Tab bar Delegate Refresh Method

- (void)refreshContentInCurrentController {
    if (!canContinueTimer) {
        return;
    }
    canContinueTimer = YES;
    currentIndex = 0;
    [self removeIndicator];
    [self readCharactisticsWithIndex:currentIndex];
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    [self performSelector:@selector(stopIndicator) withObject:nil afterDelay:5.5];
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isBasic) {
        return 4;
    } else {
        return 3;
    };
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isBasic) {
        if (section == 0) {
            return BasicSection0RowsCount;
        } else if (section == 1) {
            return BasicSection1RowsCount;
        } else if (section == 2) {
            return BasicSection2RowsCount;
        } else if (section == 3) {
            return BasicSection3RowsCount;
        }
        return 0;
        
    } else {
        if (section == 0) {
            return  AdvancedSection0RowsCount;
        } else if (section == 1) {
            return AdvancedSection1RowsCount;
        } else if (section == 2) {
            return AdvancedSection2RowsCount;
        }
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"Cell for row at index path = %ld, section= %ld", (long)indexPath.row, (long)indexPath.section);
    //Last cell to be shown.
    if (!isBasic  && indexPath.section == 2 && indexPath.row == 8) {
        LFConfigureButtonsCell *cell = (LFConfigureButtonsCell *)[tableView dequeueReusableCellWithIdentifier:BUTTON_CELL_ID forIndexPath:indexPath];
        [cell.btnCommunication addTarget:self action:@selector(showCommunication:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnRTD addTarget:self action:@selector(showRTD:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    //Normal cell
    if (!isBasic && indexPath.section != 0) {
        LFCharactersticBitDisplayCell *cell = (LFCharactersticBitDisplayCell *)[tableView dequeueReusableCellWithIdentifier:TOGGLE_CELL_ID forIndexPath:indexPath];
        cell.path = indexPath;
        cell.toggleDelegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.section == 1) {
            [cell updateValues:advanceConfigDetails[indexPath.row + AdvancedSection0RowsCount]];
            return cell;
        }
        else if(indexPath.section == 2){
            [cell updateValues:advanceConfigDetails[indexPath.row + AdvancedSection0RowsCount + AdvancedSection1RowsCount]];
            return cell;
        }
    }
    //Toggle cell
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
    UIView *aView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 40)];
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, CGRectGetWidth(tableView.frame), 40)];
    
    if (!isBasic) {
        switch (section) {
            case 0:
                return nil;
            case 1:
                aLabel.text = @"Feature enable/disable mask";
                break;
            case 2:
                aLabel.text = @"Hardware Configuration Fields";
                break;
                
            default:
                break;
        }
    } else {
        
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
            case 3:
                aLabel.text = @"Restart Attempts";
                
                
            default:
                break;
        }
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
    if (!isBasic && indexPath.section == 2 && indexPath.row == 8) {
        return 80.0;
    }
    return 75.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (isBasic) {
        return 44.0;
    }
    if (section == 0) {
        return 0.01;
    }
    return 44.0;
}

- (void)setUpTableViewFooter {
    changePasswordButton = [changePasswordView viewWithTag:1];
    UIButton *friendlyNameButton = [changePasswordView viewWithTag:2];
    [friendlyNameButton addTarget:self action:@selector(editAction:) forControlEvents:UIControlEventTouchUpInside];
    [changePasswordButton addTarget:self action:@selector(changePwdAction:) forControlEvents:UIControlEventTouchUpInside];
    changePasswordButton.layer.cornerRadius = 4.0f;
    if (!isBasic) {
        tblConfigDisplay.tableFooterView = changePasswordView;
    }
    else {
        tblConfigDisplay.tableFooterView = nil;
    }
}
//Displays the popup to enter new value for the selected field.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    curCell set
    if (!isBasic && indexPath.section != 0) {
        return;
    }
    NSInteger cont = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        cont += [tableView numberOfRowsInSection:i];
    }
    selectedTag = cont + indexPath.row;
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tblConfigDisplay cellForRowAtIndexPath:indexPath];
    
    LFNavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingNavigationController"];
    editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
    
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    
    if (indexPath.row == -1) {
        editing.selectedText = @"Name";
    }
    else if (indexPath.row == -3) {
        editing.selectedText = @"password";
    }
    else {
        editing.selectedText = cell.lblKey.text;
    }
    editing.delegate = self;
    if ([LFBluetoothManager sharedManager].isPasswordVerified) {
        editing.showAuthentication = NO;
    }
    else {
        editing.showAuthentication = YES;//YES to show the password screen.
    }
    [navController setViewControllers:@[editing]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController presentViewController:navController animated:NO completion:nil];
    });
}

- (void)toggledTappedAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        selectedTag = indexPath.row+AdvancedSection0RowsCount;
    } else if (indexPath.section == 2) {
        selectedTag = indexPath.row + AdvancedSection0RowsCount + AdvancedSection1RowsCount;
    }
    else if (indexPath.row == -1) {
        //For edit action.
        selectedTag = -1;
    }
    
    [self toggleSelectedWithSuccess:YES andPassword:nil];
    
    //    self.providesPresentationContextTransitionStyle = YES;
    //    self.definesPresentationContext = YES;
    //    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    //    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    //    editing.delegate = self;
    //    editing.showAuthentication = NO;
    //    editing.isAdvConfig = YES;
    //    [navController setViewControllers:@[editing]];
    //    [self.navigationController presentViewController:navController animated:NO completion:nil];
    
}


- (IBAction)changePwdAction:(id)sender {
    //pass indexpath as -3.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:-3 inSection:0];
    [self tableView:tblConfigDisplay didSelectRowAtIndexPath:indexPath];
}

- (IBAction)editAction:(id)sender {
    
    //Show authentication.
    //passing row as -1 for edit action.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:-1 inSection:0];
    [self tableView:tblConfigDisplay didSelectRowAtIndexPath:indexPath];
    
}

/**
 * This method switches between Basic and Advanced Configuration Screens.
 */
- (IBAction)segmentControlAction:(UISegmentedControl *)sender
{
    [[LFBluetoothManager sharedManager] setDelegate:nil];
    [[LFBluetoothManager sharedManager] resetConfigurationCharacteristics];
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
    [self setUpTableViewFooter];
}



- (void)configureServiceWithValue:(NSData *)data
{
    
    if (isReadingFriendlyName && !isVerifyingPassword) {
//        NSLog(@"Friendly name data final = %@", data);
        if (selectedTag == -2) {
            isReadingFriendlyName = NO;
            return;
        }
        selectedTag = -2;
        [self readCharactisticsWithIndex:-2];
        return;
    }
    if (selectedTag == -2 && currentIndex == 0&& !isVerifyingPassword) {
//        NSLog(@"Friendly name data = %@", data);
        isReadingFriendlyName = YES;
        selectedTag = -1;
        [self readCharactisticsWithIndex:-1];
        return;
    }
    NSData *tData = data;
    canRefresh = NO;
    if (isFetchingMacOrSeedData && currentIndex == 0 && !isVerifyingPassword) {
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
        configSeedData = mutData;
        
//        NSLog(@"Mac Address = %@", macString);
//        NSLog(@"Seed data = %@", configSeedData);
        [self removeIndicator];
        
        [[LFBluetoothManager sharedManager] resetConfigurationCharacteristics];
//        [self updateFaultData];
        return;
    }
    
    if (currentIndex == -1 && !isVerifyingPassword) {
        [authUtils nextAuthCode];
        [LFBluetoothManager sharedManager].isPasswordVerified = YES;
        isFetchingMacOrSeedData = NO;
        NSRange range = NSMakeRange(0, 8);
        data = [data subdataWithRange:range];
//        NSString *nameVal = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//        DLog(@"Entered name  is %@", nameVal);
        NSData *secondStrData;
        if (friendlyNameStr.length > 8 && selectedTag == -1) {
            secondStrData = [[friendlyNameStr substringFromIndex:8] dataUsingEncoding:NSUTF8StringEncoding];
        }
        else if (selectedTag == -1 && friendlyNameStr.length <= 8) {
            Byte emptyData[4];
            for (int i = 0; i<4; i++) {
                emptyData[i] = 0x00;
            }
            secondStrData = [NSData dataWithBytes:emptyData length:4];
        }
        NSData *secondData = [self getFriendlyNameData:secondStrData isFirstPart:NO];
        selectedTag = -2;
        
        [self saveDataToDevice:secondData];
        currentIndex = 0;
        return;
    }
    else {
        
        if (!isChangingPassword) {
            NSString *formate = isBasic ? basicFormateArray[currentIndex] : advancedFormateArray[currentIndex];
            
            NSRange range = NSMakeRange(0, 4);
            
            data = [data subdataWithRange:range];
            
            [self getValuesFromData:data withForamte:formate];
        }
      
        if (isWrite && !isReRead) {
            [self removeIndicator];
            isWrite = NO;
            //            currentIndex = 0;
            //TODO Data is read after writing to the device.Now we should show alert here and remove check after delay for showing alert if no callback is received.
            NSData *stData = [tData subdataWithRange:NSMakeRange(11, 1)];
//            NSLog(@"Full char data = %@", tData);
//            NSLog(@"Write response st data = %@", stData);
            const char *byteVal = [stData bytes];
            Byte stVal = (Byte)byteVal[0];
            //TODO: check error status
            
            switch (stVal) {
                case 0x01:
                case 0x00:
                    isReRead = NO;
                    [self showAlertViewWithCancelButtonTitle:kOK withMessage:kWriting_Failed withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                        if ([alert isKindOfClass:[UIAlertController class]]) {
                            [alert dismissViewControllerAnimated:NO completion:nil];
                        }
                    }];
                    return;
                case 0x02:
                    isReRead = NO;
                    [self showAlertViewWithCancelButtonTitle:kOK withMessage:kEnter_Correct_Password withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                        if ([alert isKindOfClass:[UIAlertController class]]) {
                            [alert dismissViewControllerAnimated:NO completion:nil];
                        }
                    }];
                    return;
                case 0x11:
                case 0x10:
                    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
                    isReRead = YES;
                    [self readCharactisticsWithIndex:currentIndex];
                    return;
                default:
                    break;
            }
        }
        if (isReRead) {
            [self removeIndicator];
//            if (!isChangingPassword) {
//                currentIndex = 0;
//            }
            isReRead = NO;
            if (![self isDataUpdatedCorrectlyWithPrevData:prevWrittenData withNewData:tData]) {
                if (isVerifyingPassword) {
                    isVerifyingPassword = NO;
                    [editing authDoneWithStatus:NO];
                    DLog(@"Authentication failed");
                    currentIndex = selectedTag;
                    return;
                }
                if (isChangingPassword) {
                    isChangingPassword = NO;
                    currentIndex = 0;
                }
                [self showAlertViewWithCancelButtonTitle:kOK withMessage:kWriting_Failed withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                    if ([alert isKindOfClass:[UIAlertController class]]) {
                        [alert dismissViewControllerAnimated:NO completion:nil];
                    }
                }];
                return;
            }
            [authUtils nextAuthCode];
            if (isVerifyingPassword) {
                isVerifyingPassword = NO;
                DLog(@"Authentication done successfully.");
                [editing authDoneWithStatus:YES];
                currentIndex = selectedTag;
                [LFBluetoothManager sharedManager].isPasswordVerified = YES;
                return;
            }
            if (isChangingPassword) {
                if (curPassWriteIndex < 7) {
                    curPassWriteIndex += 1;
                    currentIndex = -3;
                    [self writeNewPasswordDataWithIndex:curPassWriteIndex];
                    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
                    return;
                }
                [LFBluetoothManager sharedManager].isPasswordVerified = NO;
                [self removeIndicator];
            }
            [self showAlertViewWithCancelButtonTitle:kOK withMessage:kSave_Success withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                if ([alert isKindOfClass:[UIAlertController class]]) {
                    [alert dismissViewControllerAnimated:NO completion:nil];
                }
            }];
            return;
        }
        
        currentIndex = currentIndex + 1;
        if (isBasic) {
            if (currentIndex > basicConfigDetails.count - 1) {
                currentIndex = 0;
                [self removeIndicator];
                [self readDeviceMacAndAuthSeed];
                return;
            }
        } else {
            if (currentIndex > advanceConfigDetails.count - 1) {
                currentIndex = 0;
                [self removeIndicator];
                //                [self readDeviceMacAndAuthSeed];
                return;
            }
        }
        
    }
    //    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    [self readCharactisticsWithIndex:currentIndex];
}

- (BOOL)isDataUpdatedCorrectlyWithPrevData:(NSData *)writtenData withNewData:(NSData *)newData {
    NSData *prevVal = [writtenData subdataWithRange:NSMakeRange(0, 8)];
    NSData *newVal = [newData subdataWithRange:NSMakeRange(0, 8)];
    if ([prevVal isEqualToData:newVal]) {
        return YES;
    }
    return NO;
}


#pragma mark Fetch Device Mac and Seed

- (void)readDeviceMacAndAuthSeed {
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    //    [self performSelector:@selector(getMac) withObject:nil afterDelay:1];
    [self getMac];
}

- (void)getMac {
    isFetchingMacOrSeedData = YES;
    
    [[LFBluetoothManager sharedManager] discoverCharacteristicsForAuthentication];
}

- (void)readCharactisticsWithIndex:(NSInteger)index
{
    [[LFBluetoothManager sharedManager] setDelegate:self];
    
    Byte data[20];
    for (int i=0; i < 20; i++) {
        if (i== 8) {
            if (index == -1) {
                data[i] = FirstNameRegAddr;
            }
            else if (index == -2) {
                data[i] = SecondNameRegAddr;
            }
            else if (index == -3) {
                data[i] = changePassword_AddrArr[curPassWriteIndex];
            }
            else {
                data[i] = isBasic ? basicMemMap[index] : advance_MemMap[index];
            }
        } else if (i == 10){
            if (index == -1) {
                data[i] = FirstNameRegLen;
            }
            else if (index == -2) {
                data[i] = SecondNameRegLen;
            }
            else if (index == -3) {
                data[i] = (Byte)0x08;
            }
            else {
                data[i] = isBasic ? basicMemFieldLens[index] : advance_MemMapFieldLens[index];
            }

        } else {
            data[i] = (Byte)0x00;
        }
    }
    
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    NSData *data1 = [NSData dataWithBytes:data length:20];
//    NSLog(@"Data while reading back the data = %@ \n at index = %ld", data1, (long)index);
    [[LFBluetoothManager sharedManager] setSelectedTag:[NSString stringWithFormat:@"%d", (int)index]];
    [[LFBluetoothManager sharedManager] writeConfigData:data1];
}

- (NSString *)getConvertedStringForValue:(NSUInteger)dataVal {
    NSString *strVal = [NSString stringWithFormat:@"%0.2lu", (unsigned long)dataVal];
    if (dataVal < 500) {
        strVal = [NSString stringWithFormat:@"%0.2f", dataVal/100.0f];
    }
    else if (dataVal >= 500 && dataVal < 2000) {
        strVal = [NSString stringWithFormat:@"%0.1f", dataVal/100.0f];
        if (dataVal >= 1995) {
            strVal = @"20";
        }
    }
    else if (dataVal >= 2000) {
        strVal = [NSString stringWithFormat:@"%ld", lroundf(dataVal/100.0f)];
    }
    NSString *convertedVal = [NSString stringWithFormat:@"%@", strVal];
    return convertedVal;
}

- (void)getValuesFromData:(NSData *)data withForamte:(NSString *)formate
{
    NSUInteger val = [LFUtilities getValueFromHexData:data];
    
    unichar c = [formate characterAtIndex:0];
    
    NSString *convertedVal = [NSString stringWithFormat:@"%0.2lu", (unsigned long)val];
    
    switch (c) {
        case 'B':
            if (isBasic) {
                if (currentIndex == 3 || currentIndex == 4) {
                    NSString *strVal = [self getConvertedStringForValue:val];
                    convertedVal = [NSString stringWithFormat:@"%@ %@", strVal, basicUnitsArray[currentIndex]];
                }
                else {
                    if (currentIndex == 2 || currentIndex == 5) {
                        convertedVal = [NSString stringWithFormat:@"%0.1f %@", (float)val, basicUnitsArray[currentIndex]];
                    }
                    else {
                        convertedVal = [NSString stringWithFormat:@"%d %@", (int)val, basicUnitsArray[currentIndex]];
                    }
                }
            } else {
                convertedVal = [NSString stringWithFormat:@"%d", (int)val];
            }
            break;
        case 'H':
        case 'I':
        {
            if (isBasic) {
                if (currentIndex == 0 || currentIndex == 1) {
                    convertedVal = [NSString stringWithFormat:@"%ld %@", lroundf(val/100.0f),basicUnitsArray[currentIndex]];
                } else {
                    NSString *strVal = [NSNumber numberWithFloat:val/100.0].stringValue;
                    convertedVal = [NSString stringWithFormat:@"%@ %@", [strVal substringToIndex:strVal.length-1], basicUnitsArray[currentIndex]];
                    
                }
            } else {
                if (currentIndex == 4) { //if(currentIndex == 5) {
                    convertedVal = [self getConvertedStringForValue:val];
                }
                else {
                    convertedVal = [NSString stringWithFormat:@"%.2f", val/100.0];
                }
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
            convertedVal = [NSString stringWithFormat:@"%.3f KW", ((float)val/100000.0)];
        }
            break;
        case 'G':
            convertedVal = [NSString stringWithFormat:@"%0.1f %@", (float)val/100.0f, basicUnitsArray[currentIndex]];
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
        if (!isBasic) {
            if (currentIndex == AdvancedSection0RowsCount ) {
                _featureEndisVal = val;
            }
            else if (currentIndex == AdvancedSection0RowsCount+AdvancedSection1RowsCount ) {
                _hardwareConfigVal = val;
            }
        }
        switch (currentIndex) {
            case AdvancedSection0RowsCount:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 0))? 1:0];
                break;
            case AdvancedSection0RowsCount+1:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 1))? 1:0];
                break;
            case AdvancedSection0RowsCount+2:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 2))? 1:0];
                break;
            case AdvancedSection0RowsCount+3:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 3))? 1:0];
                break;
            case AdvancedSection0RowsCount+4:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 4))? 1:0];
                break;
            case AdvancedSection0RowsCount+5:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 5))? 1:0];
                break;
            case AdvancedSection0RowsCount+6:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 6))? 1:0];
                break;
            case AdvancedSection0RowsCount+7:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 7))? 1:0];
                break;
            case AdvancedSection0RowsCount+8:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 5))? 1:0];
                break;
            case AdvancedSection0RowsCount+9:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 6))? 1:0];
                break;
            case AdvancedSection0RowsCount+10:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 7))? 1:0];
                break;
            case AdvancedSection0RowsCount+11:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 8))? 1:0];
                break;
            case AdvancedSection0RowsCount+12:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 9))? 1:0];
                break;
            case AdvancedSection0RowsCount+13:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 10))? 1:0];
                break;
            case AdvancedSection0RowsCount+14:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 11))? 1:0];
                break;
            case AdvancedSection0RowsCount+15:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 12))? 1:0];
                break;
            default:
                display.value = convertedVal;
                break;
        }
        
        [advanceConfigDetails replaceObjectAtIndex:currentIndex withObject:display];
        
    }
    
    [tblConfigDisplay reloadData];
    //All the data is fetched after index = 28. Now fault refresh can be started to avoid blocking.
    
}


- (void)writeDataToIndex:(NSInteger)index withValue:(double)val
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
        case 'G':
            val = val*100;
            break;
        default:
            break;
    }
    Byte data[20];
    NSInteger convertedVal = (NSInteger)val;
    char *bytes = (char *) malloc(8);
    memset(bytes, 0, 8);
    memcpy(bytes, (char *) &convertedVal, 4);
    
    for (int i = 0; i < 20; i++) {
        if (i < 8) {
            data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
        } else {
            if (i == 8) {
                data[i] = isBasic ? basicMemMap[index] : advance_MemMap[index];
            } else if (i == 10){
                data[i] = isBasic ? basicMemFieldLens[index] : advance_MemMapFieldLens[index];
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
    NSData *resultData = [self getEncryptedPasswordDataFromString:[NSString stringWithFormat:@"%f", (double)val] data:[data1 subdataWithRange:NSMakeRange(0, 8)] address:myAddr size:myLen];
    data1 = [data1 subdataWithRange:NSMakeRange(0, 12)];
    NSMutableData *mutData = [NSMutableData dataWithData:data1];
    for (int i = 0; i<8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
//    NSLog(@"Data writing to device = %@", mutData);
    prevWrittenData = mutData;
    [[LFBluetoothManager sharedManager] writeConfigData:mutData];
    canRefresh = YES;
    [self performSelector:@selector(checkTimeOut) withObject:nil afterDelay:3];
    //    [self checkTimeOut];
    
}

#pragma mark Writing TimeOut Method.
- (void)checkTimeOut {
    if (!canRefresh || ((configSeedData == nil) && currentIndex == -1 )) {
        return;
    }
    
    if (isWrite) {
        isReRead = YES;
        [[LFBluetoothManager sharedManager] setIsWriting:NO];
        [self readCharactisticsWithIndex:selectedTag];
        [self removeIndicator];
        isWrite = NO;
    }
}

#pragma mark Name change action.
- (void)saveNewFriendlyNameWithValue:(NSString *)txt {
    if (txt == nil || txt.length == 0) {
        return;
    }
    friendlyNameStr = txt;
    currentIndex = -1;
    if (txt.length > 8) {
        NSData *firstStrData = [[txt substringToIndex:8] dataUsingEncoding:NSUTF8StringEncoding];
        NSData *firstData = [self getFriendlyNameData:firstStrData isFirstPart:YES];
        selectedTag = -1;
        [self saveDataToDevice:firstData];
    }
    else {
        NSData *firstStrData = [[txt substringToIndex:txt.length] dataUsingEncoding:NSUTF8StringEncoding];
        NSData *firstData = [self getFriendlyNameData:firstStrData isFirstPart:YES];
        selectedTag = -1;
        [self saveDataToDevice:firstData];
    }
    //Code to update the new name in UI and local DB.
    //    NSString *newName;
    //    if (txt.length > 12) {
    //        newName = [txt substringToIndex:12];
    //    }
    //    else {
    //        newName = [txt substringToIndex:txt.length];
    //    }
    //    [LFBluetoothManager sharedManager].selectedDevice = newName;
    //    [self setDeviceName:newName];
    
}

- (void)saveDataToDevice:(NSData *)data {
    NSData *lengthVal = [data subdataWithRange:NSMakeRange(10, 1)];
    char buff;
    [lengthVal getBytes:&buff length:1];
    int myLen = buff;
    NSData *addressVal = [data subdataWithRange:NSMakeRange(8, 1)];
    char addrBuff;
    [addressVal getBytes:&addrBuff length:1];
    int myAddr = addrBuff;
    NSData *resultData = [self getEncryptedPasswordDataFromString:@"" data:[data subdataWithRange:NSMakeRange(0, 8)] address:myAddr size:myLen];
    data = [data subdataWithRange:NSMakeRange(0, 12)];
    NSMutableData *mutData = [NSMutableData dataWithData:data];
    for (int i = 0; i<8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
//    NSLog(@"Data writing to device = %@", mutData);
    prevWrittenData = mutData;
    canRefresh = YES;
    //    [self performSelector:@selector(checkTimeOut) withObject:nil afterDelay:3];
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] writeConfigData:mutData];
    //    [self performSelector:@selector(checkTimeOut) withObject:nil afterDelay:1];
}

- (NSData *)getFriendlyNameData:(NSData *)data isFirstPart:(BOOL)isFirstPart{
    NSMutableData *mutData = [[NSMutableData alloc]initWithData:data];
    if (data.length < 8) {
        for (NSInteger i = data.length; i < 8; i++) {
            Byte tByte[1];
            tByte[0]= (Byte)0x00;
            [mutData appendBytes:tByte length:1];
            
        }
    }
    Byte finalData[12];
    for (int i = 8; i < 20; i++) {
        if (i == 8) {
            finalData[i-8] = isFirstPart?FirstNameRegAddr:SecondNameRegAddr;
        } else if (i == 10){
            finalData[i-8] = isFirstPart?FirstNameRegLen:SecondNameRegLen;
        } else if (i == 11) {
            finalData[i-8] = (Byte)0x01;//write byte == 1
        } else {
            finalData[i-8] = (Byte)0x00;
        }
        
    }
    
    [mutData appendBytes:finalData length:12];
    
    return mutData;
}

- (NSData *)getLastFourBytesOfData:(const char *)bytes {
    Byte data[20];
    for (int i = 0; i < 20; i++) {
        if (i < 8) {
            if(strlen(bytes) <= i) {
                data[i] = 0x00;
            }
            else {
                data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
            }
        } else {
            if (i == 8) {
                data[i] = SecondNameRegAddr;
            } else if (i == 10){
                data[i] = SecondNameRegLen;
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            } else {
                data[i] = (Byte)0x00;
            }
        }
        
    }
    NSData *data1 = [NSData dataWithBytes:data length:20];
    return data1;
}


#pragma mark -Editing Delegate

- (void)checkPassword:(NSString *)passwordStr {
    isVerifyingPassword = YES;
    passwordVal = passwordStr;
    LFDisplay *ctVal = [advanceConfigDetails objectAtIndex:0];
    [self writeDataToIndex:0 withValue:ctVal.value.doubleValue];
}

- (void)selectedValue:(NSString *)txt andPassword:(NSString *)password
{
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        if (password != nil) {
            passwordVal = password;
        }
    }
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    if (selectedTag == -1 || selectedTag == -2) {
        [self saveNewFriendlyNameWithValue:txt];
        return;
    }
    else if (selectedTag == -3) {
//        changePasswordWithNewValue
        if ((txt.length == 0) || (txt == nil)) {
            [self showAlertWithText:@"Please enter a valid password"];
            return;
        }
        [self changePasswordWithNewValue:txt];
        return;
    }
    
    if (txt.length == 0) {
        txt = @"";
    }
    //
    
    
    LFDisplay *display;
    if (isBasic) {
        display = [basicConfigDetails objectAtIndex:selectedTag];
        if (selectedTag == 3 || selectedTag == 4 ) {
            CGFloat curVal = txt.floatValue;
            display.value = [NSString stringWithFormat:@"%0.2f", (float)curVal*100.0f];
            txt = display.value;
        }
        else {
            display.value = txt;
        }
        [basicConfigDetails replaceObjectAtIndex:selectedTag withObject:display];
    } else {
        display = [advanceConfigDetails objectAtIndex:selectedTag];
        display.value = txt;
        [advanceConfigDetails replaceObjectAtIndex:selectedTag withObject:display];
    }
    
    [self writeDataToIndex:selectedTag withValue:txt.doubleValue];
}

- (void)toggleSelectedWithSuccess:(BOOL)isSuccess andPassword:(NSString *)password{
    if (!isSuccess) {
        [tblConfigDisplay reloadData];
        return;
    }
    
    LFDisplay *display = advanceConfigDetails[selectedTag];
    display.value = [NSString stringWithFormat:@"%d", !display.value.boolValue];
    [advanceConfigDetails replaceObjectAtIndex:selectedTag withObject:display];
    
    if (!isBasic) {
        if (selectedTag >= AdvancedSection0RowsCount && selectedTag <= AdvancedSection0RowsCount + AdvancedSection1RowsCount - 1) {
            switch (selectedTag) {
                case AdvancedSection0RowsCount:
                    _featureEndisVal  ^= 1 << 0;
                    break;
                case AdvancedSection0RowsCount+1:
                    _featureEndisVal  ^= 1 << 1;
                    break;
                case AdvancedSection0RowsCount+2:
                    _featureEndisVal  ^= 1 << 2;
                    break;
                case AdvancedSection0RowsCount+3:
                    _featureEndisVal  ^= 1 << 3;
                    break;
                case AdvancedSection0RowsCount+4:
                    _featureEndisVal  ^= 1 << 4;
                    break;
                case AdvancedSection0RowsCount+5:
                    _featureEndisVal  ^= 1 << 5;
                    break;
                case AdvancedSection0RowsCount+6:
                    _featureEndisVal  ^= 1 << 6;
                    break;
                case AdvancedSection0RowsCount+7:
                    _featureEndisVal  ^= 1 << 7;
                    break;
                default:
                    break;
            }
            [self writeDataToIndex:selectedTag withValue:(float)_featureEndisVal];
        } else if (selectedTag >= AdvancedSection0RowsCount+AdvancedSection1RowsCount && selectedTag <= AdvancedSection0RowsCount+AdvancedSection1RowsCount+AdvancedSection2RowsCount - 2) {
            switch (selectedTag) {
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount:
                    _hardwareConfigVal  ^= 1 << 5;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+1:
                    _hardwareConfigVal  ^= 1 << 6;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+2:
                    _hardwareConfigVal  ^= 1 << 7;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+3:
                    _hardwareConfigVal  ^= 1 << 8;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+4:
                    _hardwareConfigVal  ^= 1 << 9;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+5:
                    _hardwareConfigVal  ^= 1 << 10;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+6:
                    _hardwareConfigVal  ^= 1 << 11;
                    break;
                case AdvancedSection0RowsCount+AdvancedSection1RowsCount+7:
                    _hardwareConfigVal  ^= 1 << 12;
                    break;
                default:
                    break;
            }
            [self writeDataToIndex:selectedTag withValue:(float)_hardwareConfigVal];
        }
    }
    
    [tblConfigDisplay reloadData];
}

- (void)showOperationCompletedAlertWithStatus:(BOOL)isSuccess
{
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    [self removeIndicator];
    if (isSuccess) {
        if (isVerifyingPassword) {
            [self readCharactisticsWithIndex:0];
        }
        else if (isChangingPassword) {
            [self readCharactisticsWithIndex:-3];
        }
        else {
            [self readCharactisticsWithIndex:selectedTag];
        }
    }
    else {
        //Error occured while writing data to device.
        [self showAlertViewWithCancelButtonTitle:kOK withMessage:kProblem_Saving withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
            [tblConfigDisplay reloadData];
        }];
    }
    
}

/**
 * Displays the communication controller.
 */
- (void)showCommunication:(UIButton *)btn
{
    LFCommunicationSettingsController *communication = (LFCommunicationSettingsController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LFCommunicationSettingsControllerID"];
    [self.navigationController pushViewController:communication animated:YES];
}

/**
 * Displays RTD controller.
 */
- (void)showRTD:(UIButton *)btn
{
    LFRTDViewController *rtd = (LFRTDViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LFRTDViewControllerID"];
    [self.navigationController pushViewController:rtd animated:YES];
    
}

- (void)dealloc
{
    [LittleFuseNotificationCenter removeObserver:self];
}

#pragma mark read name after writing

- (void)readNameValueAfterUpdating {
    //Add logic to re read the saved information for friendly name in both the addresses.So there should be two reads.
    //
    //    [[LFBluetoothManager sharedManager] setDelegate:self];
    //
    //    Byte data[20];
    //    for (int i=0; i < 20; i++) {
    //        if (i== 8) {
    //            data[i] = selectedTag == -1?FirstNameRegAddr:SecondNameRegAddr;
    //        } else if (i == 10){
    //            data[i] = selectedTag == -1?FirstNameRegLen:SecondNameRegLen;
    //        } else {
    //            data[i] = (Byte)0x00;
    //        }
    //    }
    //
    //    [[LFBluetoothManager sharedManager] setRealtime:NO];
    //    [[LFBluetoothManager sharedManager] setConfig:YES];
    //    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    //    NSData *data1 = [NSData dataWithBytes:data length:20];
    //    [[LFBluetoothManager sharedManager] setSelectedTag:[NSString stringWithFormat:@"%d", selectedTag]];
    //    [[LFBluetoothManager sharedManager] writeConfigData:data1];
    
}

#pragma mark Peripheral Disconnected Notification

- (void)peripheralDisconnected {
    [self removeIndicator];
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



#pragma mark Change Password Methods.

- (void)changePasswordWithNewValue:(NSString *)newPassword {
    completePasswordData = [authUtils getNewPassKeydata:newPassword];
    isChangingPassword = YES;
    curPassWriteIndex = 0;
    [self writeNewPasswordDataWithIndex:0];
}

- (void)writeNewPasswordDataWithIndex:(NSInteger)passIndex {
    NSData *passData = [completePasswordData subdataWithRange:NSMakeRange(passIndex*8, 8)];
    isWrite = YES;
    currentIndex = -3;
    Byte data[20];
    NSMutableData *data1 = [[NSMutableData alloc]init];
    
    for (int i = 0; i < 20; i++) {
        if (i < 8) {
            NSData *tData = [passData subdataWithRange:NSMakeRange(i, 1)];
            const char *tBytes = [tData bytes];
            data[i] = (Byte)tBytes[0];// Save the data whatever we are entered here
        } else {
            if (i == 8) {
                data[i] = changePassword_AddrArr[curPassWriteIndex];
            } else if (i == 10){
                data[i] = 0x08;
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            }
            else {
                data[i] = (Byte)0x00;
            }
        }
        
    }
    
    [data1 appendBytes:data length:20];
    
    NSData *lengthVal = [data1 subdataWithRange:NSMakeRange(10, 1)];
    char buff;
    [lengthVal getBytes:&buff length:1];
    int myLen = buff;
    NSData *addressVal = [data1 subdataWithRange:NSMakeRange(8, 1)];
    char addrBuff;
    [addressVal getBytes:&addrBuff length:1];
    int myAddr = addrBuff;
    NSData *resultData = [self getEncryptedPasswordDataFromString:@"" data:[data1 subdataWithRange:NSMakeRange(0, 8)] address:myAddr size:myLen];
    data1 = [NSMutableData dataWithData:[data1 subdataWithRange:NSMakeRange(0, 12)]];
    NSMutableData *mutData = [NSMutableData dataWithData:data1];
    for (int i = 0; i<8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
//    NSLog(@"Data writing to device = %@", mutData);
    prevWrittenData = mutData;
    [[LFBluetoothManager sharedManager] writeConfigData:mutData];
    canRefresh = YES;
    [self performSelector:@selector(checkTimeOut) withObject:nil afterDelay:3];
    
}


@end
