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
#define ThirdNameRegAddr 0x0076   // this is for imediate name reflction on hardware
#define FirstNameRegLen 0x08
#define SecondNameRegLen 0x04
#define ThirdNameRegLen 0x02  // this is for imediate name reflction on hardware
#define ThirdNameVal 0x0053 //write this value for the friendly name.

#pragma mark Info regarding sections in the table.

#define BasicSectionVoltageSetting 3
#define BasicSectionCurrentSetting 4
#define BasicSectionTimerSetting 4
#define BasicSectionRestartAttemptsSetting 2
#define AdvancedSection0RowsCount 12
#define AdvancedSectionFeaturesCount 8
#define AdvancedSectionHardwareConfigurationCount 5

#define OFFString @"0=Off"
#define Background_Fault_Refresh_Interval 20

typedef enum : NSInteger {
    FriendlyNameFirstWrite = -1,
    FriendlyNameSecondWrite = -2,
    FriendlyNameThirdWrite = -3,
    ChangePasswordWrite = -4,
    ResetPasswordWrite = -5,
} ActionOprations;

typedef enum : NSUInteger {
    Advanced_CT = 0,
    Advanced_PT,
    Advanced_ULTD,
    Advanced_LINTD,
    Advanced_GFTC,
    Advanced_GFTD,
    Advanced_LKW,
    Advanced_HKW,
    Advanced_HPTD,
    Advanced_STLP,
    Advanced_STTD,
    Advanced_STID,
    // feature enable and
    Advanced_GFT,
    Advanced_VUBT,
    Advanced_CUBT,
    Advanced_UCT,
    Advanced_OCT,
    Advanced_LINT,
    Advanced_LPRT,
    Advanced_HPRT,
    // hardware Configuration
    Advanced_SPM,
    Advanced_SPT,
    Advanced_PTC,
    Advanced_ACB,
    Advanced_GMFT,
} AdvancedConfiguration;

typedef enum : NSUInteger {
    // VOLTAGE SETTINGS
    Basic_LV = 0,
    Basic_HV,
    Basic_VUB,
    // CURRENT SETTINGS
    Basic_OC,
    Basic_UC,
    Basic_CUB,
    Basic_TC,
    // TIMER SETTINGS
    Basic_RD0,
    Basic_RD1,
    Basic_RD2,
    Basic_RD3,
    // RESTART ATTEMPTS
    Basic_RU,
    Basic_RF,
} BasicConfigurartion;


@interface LFConfigurationViewController () < EditingDelegate, BlutoothSharedDataDelegate, ToggleTappedProtocol, LFTabbarRefreshDelegate>
{
    
    LFAuthUtils *authUtils;
    __weak IBOutlet UITableView *tblConfigDisplay;
    NSMutableArray *basicConfigDetails;
    NSMutableArray *advanceConfigDetails;
    NSMutableArray *advanceConfigFeatureDetails;
    NSMutableArray *basicValuesArray;
    
    NSArray  *basicFormateArray;
    NSArray *advancedFormateArray;
    NSArray *advancedFormateWithoutMaskArray;
    
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
    //BOOL isChangingPassword;
    BOOL isResettingSeed;
    BOOL isInitialReading;
    BOOL isResetPassword;
    NSInteger curPassWriteIndex;
   // NSString *macString;
    //NSData *configSeedData;
    NSData *prevWrittenData;
    NSMutableData *completePasswordData;
    //NSString *passwordVal;
    NSString *friendlyNameStr;
    
    NSInteger currentIndex;
    NSInteger selectedTag;
    NSString *previousSelected;
    NSInteger prevEnteredVal;//Used to compare previously entered value.
    
    UIView *changePasswordView;
    UIButton *changePasswordButton;
    LFEditingViewController *editing;
    NSTimer *timer;
    NSUInteger stFieldSuccessCount;
    BOOL isFirstTimeAuthenticate;
    NSString *newPasswordStr;
    BOOL isToggleCell; //This is for authentication validation process for toggle cell
    
}
@property (nonatomic) NSUInteger hardwareConfigVal;
@property (nonatomic) NSUInteger featureEndisVal;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UILabel *deviceId;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (nonatomic, assign) BOOL isSTFieldSuccess;
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
const char advance_feature_MemMap[] = {0x06, 0x08, 0x1E,/* 0x22,*/ 0x24, 0x3A, 0x3E,/* 0x40,*/
    0x42, 0x46, 0x4A, 0x4C, 0x4E, 0x50,/* 0x56,0x56,0x56,0x56,0x56,0x56,0x56,0x56,*/0x5A,0x5A,0x5A,0x5A,0x5A/*,0x5A,0x5A,0x5A,0x5A*/};
const char advance_feature_MemMapFieldLens[] = {0x2, 0x2, 0x2,/* 0x2,*/ 0x2, 0x4, 0x2,/* 0x2,*/ 0x4, 0x4, 0x2, 0x2, 0x2, 0x2,/* 0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,*/0x04, 0x04,0x04, 0x04, 0x04/*,0x04, 0x04,0x04,0x04*/};
const char changePassword_AddrArr[]  = {0x94, 0x9C, 0xA4, 0xAC, 0xB4, 0xBC, 0xC4, 0xCC};

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setEnableRefresh:YES];
    isInitialReading = YES;
    [[LFBluetoothManager sharedManager] setIsPassWordChange:NO];
    curPassWriteIndex = 0;
    stFieldSuccessCount = 0;
    isInitialLaunch = YES;
    isFirstTimeAuthenticate = NO;
    completePasswordData = [[NSMutableData alloc] initWithCapacity:64];
    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"ChangePasswordView"
                                                      owner:self
                                                    options:nil];
    changePasswordView = nibViews[0];
    [changePasswordView setFrame: CGRectMake(0, 0, CGRectGetWidth(self.view.window.frame), CGRectGetHeight(changePasswordView.frame))];
    // Do any additional setup after loading the view.
    advanceConfigDetails = [[NSMutableArray alloc] initWithCapacity:0];
    advanceConfigFeatureDetails = [[NSMutableArray alloc] initWithCapacity:0];
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
    [[LFBluetoothManager sharedManager] setDelegate:nil];
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
    LFDisplay *restartAttemptsUCTrips = [[LFDisplay alloc] initWithKey:@"Restart attempts for under load trips" Value:@"" Code:@"RU"];
    LFDisplay *restartAttemptsOtherTrips = [[LFDisplay alloc] initWithKey:@"Restart attempts for all other trips" Value:@"" Code:@"RF"];
    
                /**************************# ADVANCED CONFIGURATION #*************************/
    
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
    LFDisplay *spm = [[LFDisplay alloc] initWithKey:@"Single Phase Motor" Value:@"" Code:@"SPM"];
     LFDisplay *spt = [[LFDisplay alloc] initWithKey:@"Single PT" Value:@"" Code:@"SPT"];
    LFDisplay *ptc = [[LFDisplay alloc] initWithKey:@"PTC Enabled" Value:@"" Code:@"PTC"];
    LFDisplay *acb = [[LFDisplay alloc] initWithKey:@"Enable ACB phase rotation" Value:@"" Code:@"ACB"];
    LFDisplay *gmft = [[LFDisplay alloc] initWithKey:@"Ground Fault Motor Trip OR Alarm" Value:@"" Code:@"GMFT"];


    /*  wiill be used later
    LFDisplay *configBitSix = [[LFDisplay alloc] initWithKey:@"Single PT Connected" Value:@"" Code:@"SPTC"];
    LFDisplay *configBitSeven = [[LFDisplay alloc] initWithKey:@"Single Phase current" Value:@"" Code:@"SPC"];
    LFDisplay *configBitEight = [[LFDisplay alloc] initWithKey:@"Disable RP" Value:@"" Code:@"RP"];
    LFDisplay *configBitNine = [[LFDisplay alloc] initWithKey:@"Low Control voltage trip" Value:@"" Code:@"LCVT"];
    LFDisplay *configBitTen = [[LFDisplay alloc] initWithKey:@"Stall 1" Value:@"" Code:@"STAL"];
    LFDisplay *configBitEleven = [[LFDisplay alloc] initWithKey:@"Low KV mode" Value:@"" Code:@"LKV"];
     */
    
    basicConfigDetails = [[NSMutableArray alloc] initWithObjects:lowVoltage, highVoltage, voltageUnb, overCurrent, underCurrent, currentUnb, tripClass, powerUpTimer, rapidTimer, motorCoolDown,  dryWellRecover,restartAttemptsUCTrips,restartAttemptsOtherTrips,nil];
    
    advanceConfigDetails = [[NSMutableArray alloc] initWithObjects:currentTansformer, pt, ultd/*, cutd*/, lin, gftc, gftd,/* gfib,*/ lkw, hkw, hptd, stallPercenage, stallTripDelay, stallInhibt, bitZero, bitOne, bitTwo, bitThree, bitFour, bitFive, bitSix, bitSeven, spm, /*configBitSix, configBitSeven, configBitEight, configBitNine, configBitTen, configBitEleven,*/ ptc, acb, gmft, nil];
    advanceConfigFeatureDetails = [[NSMutableArray alloc] initWithObjects:currentTansformer, pt, ultd/*, cutd*/, lin, gftc, gftd,/* gfib,*/ lkw, hkw, hptd, stallPercenage, stallTripDelay, stallInhibt, /*bitZero, bitOne, bitTwo, bitThree, bitFour, bitFive, bitSix, bitSeven,*/ spm,spt, /*configBitSix, configBitSeven, configBitEight, configBitNine, configBitTen, configBitEleven,*/ ptc, acb, gmft, nil];
    
    basicFormateArray = @[@"H", @"H", @"G", @"B", @"B", @"G",  @"B",  @"L", @"L", @"L", @"L",@"B",@"B"];
    advancedFormateArray = @[@"B", @"B", @"L",/* @"Q",*/ @"L", @"H", @"Q",/* @"L",*/ @"K", @"K", @"L", @"B", @"Q", @"Q", @"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C"/*,@"C", @"C",@"C", @"C"*/];
    advancedFormateWithoutMaskArray = @[@"B", @"B", @"L",/* @"Q",*/ @"L", @"H", @"Q",/* @"L",*/ @"K", @"K", @"L", @"B", @"Q", @"Q", /*@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",*/@"C",@"C", @"C",@"C", @"C"/*,@"C", @"C",@"C", @"C"*/];
    
    basicUnitsArray = @[@"VAC", @"VAC", @"%", @"amps", @"amps", @"%", @"",@"sec", @"sec", @"sec", @"sec",@"",@""];
    advUnitsArray = @[@"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", @""/*, @"", @""*/];
    
    currentIndex = 0;
    isBasic = YES;

    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    canContinueTimer = NO;
    [self removeIndicator];
    [[LFBluetoothManager sharedManager] stopFaultTimer];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[LFBluetoothManager sharedManager] setDelegate:nil];
    [[LFBluetoothManager sharedManager] setDelegate:self];
    LFTabbarController *tabBarController = (LFTabbarController *)self.tabBarController;
    [self setEnableRefresh:YES];
    tabBarController.tabBarDelegate = self;
    [[LFBluetoothManager sharedManager] setConfig:YES];
    canContinueTimer = YES;
    if (isInitialLaunch) {
       // isReadingData = YES;
        [self readCharactisticsWithIndex:currentIndex];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    if (isInitialLaunch) {
        isInitialLaunch = NO;
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];

    }
    [self performSelector:@selector(stopIndicator) withObject:nil afterDelay:5.5];
    if ([[LFBluetoothManager sharedManager] getConfigSeedData] != nil) {
        [self updateFaultData];
    }
}

- (void)showCharacterstics:(NSMutableArray *)charactersticsArray
{
    CBCharacteristic *charactestic = (CBCharacteristic *)charactersticsArray[2];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
}

#pragma  mark - Base Controller Methods
-(void)navigationBackAction
{
    self.tabBarController.selectedIndex = 0;
}
-(void)refreshContentAction{
    if (!canContinueTimer) {
        return;
    }
    isInitialReading = YES;
    [[LFBluetoothManager sharedManager] setIsPassWordChange:NO];
    canContinueTimer = YES;
    currentIndex = 0;
    [self removeIndicator];
    [self readCharactisticsWithIndex:currentIndex];
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    [self performSelector:@selector(stopIndicator) withObject:nil afterDelay:5.5];
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
    [[LFBluetoothManager sharedManager] setMacString:tString];
    [self performSelector:@selector(getSeedData) withObject:nil afterDelay:2];
}

- (void)getSeedData {
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
        [authUtils initWithPassKey:[[LFBluetoothManager sharedManager] getPasswordString] andMacAddress:[[LFBluetoothManager sharedManager] getMacString] andSeed: [[LFBluetoothManager sharedManager] getConfigSeedData].bytes ];
    }
    NSData * authCode = [authUtils computeAuthCode:writeData.bytes address:address size:size];
    DLog( @"auth code:%@",authCode);
    return authCode;
}

- (void)stopIndicator {
    if (isBasic && currentIndex == 0) {
        [self removeIndicator];
    } else {
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
       // [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:180];
    }
}





#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (isBasic) {
        return 4;
    } else {
        BOOL status = [self isNeedToRemoveFeatureEnableMaskSection];
        if (status) {
            return 2;
        }
        return 3;
    };
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isBasic) {
        if (section == 0) {
            return BasicSectionVoltageSetting;
        } else if (section == 1) {
            return BasicSectionCurrentSetting;
        } else if (section == 2) {
            return BasicSectionTimerSetting;
        } else if (section == 3) {
            return BasicSectionRestartAttemptsSetting;
        }
        return 0;
        
    } else {
        if (section == 0) {
            return  AdvancedSection0RowsCount;
        } else if (section == 1) {
            BOOL status = [self isNeedToRemoveFeatureEnableMaskSection];
            if (status) {
                return AdvancedSectionHardwareConfigurationCount + 1;
            }
            return AdvancedSectionFeaturesCount;
        } else if (section == 2) {
            return AdvancedSectionHardwareConfigurationCount;
        }
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Last cell to be shown.
    if (!isBasic  && indexPath.section == 1 && indexPath.row == AdvancedSectionHardwareConfigurationCount   ) {
        LFConfigureButtonsCell *cell = (LFConfigureButtonsCell *)[tableView dequeueReusableCellWithIdentifier:BUTTON_CELL_ID forIndexPath:indexPath];
        [cell.btnCommunication addTarget:self action:@selector(showCommunication:) forControlEvents:UIControlEventTouchUpInside];
        [cell.btnRTD addTarget:self action:@selector(showRTD:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    //toggle cell
    if (!isBasic && indexPath.section != 0) {
        LFCharactersticBitDisplayCell *cell = (LFCharactersticBitDisplayCell *)[tableView dequeueReusableCellWithIdentifier:TOGGLE_CELL_ID forIndexPath:indexPath];
        cell.path = indexPath;
        cell.toggleDelegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if ([self isNeedToRemoveFeatureEnableMaskSection]) {
            if (indexPath.section == 1) {
                [cell updateValues:advanceConfigFeatureDetails[indexPath.row + AdvancedSection0RowsCount]];
                return cell;
            }
        } else {
            if (indexPath.section == 1) {
                [cell updateValues:advanceConfigDetails[indexPath.row + AdvancedSection0RowsCount]];
                return cell;
            } else if(indexPath.section == 2){
                [cell updateValues:advanceConfigDetails[indexPath.row + AdvancedSection0RowsCount + AdvancedSectionFeaturesCount]];
                return cell;
            }
        }
       
    }
    //Normal cell
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tableView dequeueReusableCellWithIdentifier:CHARACTER_DISPLAY_CELL_ID forIndexPath:indexPath];
    if (isBasic) {
        NSInteger cont = 0;
        for (NSInteger i = 0; i < indexPath.section; i++) {
            cont += [tableView numberOfRowsInSection:i];
        }
        cont += indexPath.row;
        [self checkFeatureValuesWith:YES andIndex:cont];
        [cell updateValues:[basicConfigDetails objectAtIndex:cont]];
        
    } else {

        [self checkFeatureValuesWith:NO andIndex:indexPath.row];
        LFDisplay *display = ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails objectAtIndex:indexPath.row] : [advanceConfigDetails objectAtIndex:indexPath.row]);
        [cell updateValues:display];
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
                if ([self isNeedToRemoveFeatureEnableMaskSection]) {
                    aLabel.text = @"Hardware Configuration Fields";
                } else {
                aLabel.text = @"Feature enable/disable mask";
                }
                break;
            case 2: aLabel.text = @"Hardware Configuration Fields";
                break;
                
            default:
                break;
        }
    } else {
        
        switch (section) {
            case 0:  aLabel.text = @"Voltage Settings";
                break;
            case 1:  aLabel.text = @"Current Settings";
                break;
            case 2:  aLabel.text = @"Timer  Settings";
                break;
            case 3:  aLabel.text = @"Restart Attempts";
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
    // adding longpress for reset password
    UILongPressGestureRecognizer *passwordResetGesture = [[UILongPressGestureRecognizer alloc] init];
    [passwordResetGesture addTarget:self action:@selector(resetPasswordction:)];
    [changePasswordButton addGestureRecognizer:passwordResetGesture];
    changePasswordButton.layer.cornerRadius = 4.0f;
    if (!isBasic) {
        tblConfigDisplay.tableFooterView = changePasswordView;
    } else {
        tblConfigDisplay.tableFooterView = nil;
    }
}
//Displays the popup to enter new value for the selected field.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    isToggleCell = NO;
    //    curCell set
    if (!isBasic && indexPath.section != 0) {
        return;
    }
    NSInteger cont = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        cont += [tableView numberOfRowsInSection:i];
    }
    selectedTag = cont + indexPath.row; // this is for knowing current cell
    
    [self showPasswordScreenWithIndexpath:indexPath];
}

- (void) showPasswordScreenWithIndexpath:(NSIndexPath *) indexPath {
    
    LFCharactersticDisplayCell *cell = (LFCharactersticDisplayCell *)[tblConfigDisplay cellForRowAtIndexPath:indexPath];
    
//    if (editing) {
//        return;
//    }
    LFNavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingNavigationController"];
    editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
    
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    
    if (indexPath.row == FriendlyNameFirstWrite) {
        editing.selectedText = kFriendly_deviceName_title;
    } else if (indexPath.row == ChangePasswordWrite) {
        editing.selectedText = kAuthentication_title;

    } else if (indexPath.row == ResetPasswordWrite) {
      editing.selectedText = kResetPassword_title;

    } else {
        editing.selectedText = cell.lblKey.text;

    }
    editing.delegate = self;
   
    if ([LFBluetoothManager sharedManager].isPasswordVerified || indexPath.row == ResetPasswordWrite) {
        editing.showAuthentication = NO;
        if (indexPath.row == ChangePasswordWrite) {
        editing.isChangePassword = YES;
                    }
    } else {
        if (indexPath.row == ChangePasswordWrite) {
            editing.isChangePassword = YES;
        }
        editing.showAuthentication = YES;//YES to show the password screen.
    }
    editing.isAdvConfig = !isBasic;
    [navController setViewControllers:@[editing]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController presentViewController:navController animated:NO completion:nil];
    });
}

// toggeling delegate

- (void)toggledTappedAtIndexPath:(NSIndexPath *)indexPath {
    
    isToggleCell = YES;
    if (indexPath.section == 1) {
        selectedTag = indexPath.row + AdvancedSection0RowsCount;
    } else if (indexPath.section == 2) {
        selectedTag = indexPath.row + AdvancedSection0RowsCount + AdvancedSectionFeaturesCount;
    }
    else if (indexPath.row == -1) {
        //For edit action.
        selectedTag = -1;
    }

    if ([LFBluetoothManager sharedManager].isPasswordVerified) {
        [self toggleSelectedWithSuccess:YES andPassword:nil];
    } else {
        [self showPasswordScreenWithIndexpath:indexPath];
    }
}

- (void) resetPasswordction:(UILongPressGestureRecognizer*)sender {
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"UIGestureRecognizerStateEnded");
        //Do Whatever You want on End of Gesture
        currentIndex = ResetPasswordWrite;
        selectedTag = ResetPasswordWrite;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ResetPasswordWrite inSection:0];
        [self showPasswordScreenWithIndexpath:indexPath];

    }
    
    
}
- (IBAction)changePwdAction:(id)sender {
    //pass indexpath as -4.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:ChangePasswordWrite inSection:0];
    [self tableView:tblConfigDisplay didSelectRowAtIndexPath:indexPath];
}

- (IBAction)editAction:(id)sender {
    
    //Show authentication.
    //passing row as -1 for edit action.
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:FriendlyNameFirstWrite inSection:0];
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
        
        [[LFBluetoothManager sharedManager] setDelegate:self];
    } else {
        [[LFBluetoothManager sharedManager] setDelegate:self];
        isBasic = NO;
        if (!isAdvanceLoded) {
            [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
            [self readCharactisticsWithIndex:currentIndex];
            isAdvanceLoded = YES;
             isInitialReading = YES;
        }
    }
    
    [tblConfigDisplay reloadData];
    [self setUpTableViewFooter];
}

- (void) updateCharactersticsData:(NSData *) data {
    if (isResetPassword) {
        return;
    }
    
    NSData *tData = data;
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
        DLog(@"seed data:%@", mutData);
        
        [[LFBluetoothManager sharedManager] setConfigSeedData:mutData];
        [self removeIndicator];
        [[LFBluetoothManager sharedManager] resetConfigurationCharacteristics];
        if (isResettingSeed) {
            [authUtils initWithPassKey:[[LFBluetoothManager sharedManager] getPasswordString] andMacAddress:[[LFBluetoothManager sharedManager] getMacString] andSeed:[[LFBluetoothManager sharedManager] getConfigSeedData].bytes];
            isResettingSeed = NO;
        }
        return;
    }
    
    if (isWrite && !isReRead) { // //TODO Data is read after writing to the device.Now we should show alert here and remove check after delay for showing alert if no callback is received.
            [self removeIndicator];
            isWrite = NO;
            NSData *stData = [tData subdataWithRange:NSMakeRange(11, 1)];
            const char *byteVal = [stData bytes];
            
            int stVal = 0x0000000F & ((Byte)byteVal[0] >> 4); // this for getting response st val
            NSString *alertMessage;
                DLog(@"\n\n\n\n Success status : %d\n\n\n\n", stVal);
            BOOL shouldHideAlert = NO;
            switch (stVal) {
                case 0:
                    isReRead = NO;
                    isWrite = YES;

                    // run timer for sending 10 times read for isSTFieldSuccess set to YES
                    // set stFieldSuccessCount  set 0 on every write
                    if (isResetPassword) {
                        isResetPassword = NO;
                    }
                    if (stFieldSuccessCount == 10) {
                        self.isSTFieldSuccess = NO;
                        stFieldSuccessCount = 0;
                        return;
                    }
                    alertMessage = kUpdateFailed;
                    if (isVerifyingPassword && isFirstTimeAuthenticate) {
                        [self removeIndicator];
                        self.isSTFieldSuccess = YES;
                        return;
                    }
                    break;
                case 1:
                    [authUtils nextAuthCode];
                    [self removeIndicator];
                    self.isSTFieldSuccess = NO;
                    if (isResetPassword) {
                        isResetPassword = NO;
                        // need to disconnect after 10 seconds
                        [self performSelector:@selector(appEnteredBackground) withObject:nil afterDelay:10];
                    }
                    if (isReadingFriendlyName && !isVerifyingPassword) {
                        if (selectedTag == FriendlyNameSecondWrite) {
                            selectedTag = FriendlyNameThirdWrite;
                            [self changeFriendlyNameProcess];
                            return;
                        } if (selectedTag == FriendlyNameThirdWrite) {
                            isReadingFriendlyName = NO;
                            DLog(@"my friendly name: %@\n\n\n\n", friendlyNameStr );
                            [self setDeviceName:friendlyNameStr];
                            return;
                        }
                    }
                    if (isReadingFriendlyName && currentIndex == FriendlyNameFirstWrite && !isVerifyingPassword) {
                        selectedTag = FriendlyNameSecondWrite;
                        [self changeFriendlyNameProcess];
                        return;
                    }
                    
                    /////////////////   change password Process     //////////////////
                    
                    if ([LFBluetoothManager sharedManager].isPassWordChange) {
                        if (curPassWriteIndex < 7) {
                            curPassWriteIndex += 1;
                            [self writeNewPasswordDataWithIndex:curPassWriteIndex];
                            return;
                        }
                        isFirstTimeAuthenticate = NO;
                        [LFBluetoothManager sharedManager].isPasswordVerified = NO;
                        [self removeIndicator];
                        alertMessage = kAuthenticationFailed;
                        isReRead = YES;
                        return;
                    }
                    else{
                        /////////////////                               ///////////
                        alertMessage = kSave_Success;
                        isReRead = YES;
                        if (isVerifyingPassword) {
                            shouldHideAlert = YES;
                        }
                    }
                break;
                case 2:
                    [editing authDoneWithStatus:NO shouldDismissView:YES];
                    [[LFBluetoothManager sharedManager] setIsPassWordChange:NO];
                    alertMessage = kAuthenticationFailed;
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
                    curPassWriteIndex = 0;
                    currentIndex = 0;
                    isVerifyingPassword = NO;
                    [authUtils nextAuthCode];
                    isReRead = YES;
                    isResettingSeed = YES;
                    [[LFBluetoothManager sharedManager] setIsPassWordChange:NO];
                    alertMessage = kPassword_Changed;
                    [[LFBluetoothManager sharedManager] setPasswordString:newPasswordStr];
                    [LFBluetoothManager sharedManager].isPasswordVerified = YES;
                    
                    [self removeIndicator];
                     [self readDeviceMacAndAuthSeed];
                    break;
                    
                default:
                    break;
            }
            if (stVal != 0) {
            [self removeIndicator];
                if (!shouldHideAlert) {
                    [self showAlertViewWithCancelButtonTitle:kOK withMessage:alertMessage withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                        if ([alert isKindOfClass:[UIAlertController class]]) {
                            [alert dismissViewControllerAnimated:NO completion:nil];
                        }
                    }];
                }
                
            }
            [self readCharactisticsWithIndex:currentIndex];
            return;
        }
        
    if (![LFBluetoothManager sharedManager].isPassWordChange && currentIndex >= 0) {
        NSString *formate = isBasic ? basicFormateArray[currentIndex] : ([self isNeedToRemoveFeatureEnableMaskSection] ? advancedFormateWithoutMaskArray[currentIndex] :  advancedFormateArray[currentIndex]);
        
        NSRange range = NSMakeRange(0, 4);
        
        data = [data subdataWithRange:range];
        
        [self getValuesFromData:data withForamte:formate];
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
                    currentIndex = selectedTag;
                    return;
                }
               /* if (isChangingPassword) {
                    isChangingPassword = NO;
                    currentIndex = 0;
                }*/
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
                isFirstTimeAuthenticate = YES;
                DLog(@"Authentication done successfully.");
                [editing authDoneWithStatus:YES shouldDismissView:isToggleCell];
                currentIndex = selectedTag;
                [LFBluetoothManager sharedManager].isPasswordVerified = YES;
                if (isToggleCell) {
                    [self toggleSelectedWithSuccess:YES andPassword:nil];
                    isToggleCell = NO;
                }
                return;
            }
            
           
            return;
        }
        //////////////////////////////   re reading process   ends /////////////////////////
        
        
        //////////////////////////////  this is for only for first reading      ///////////////////////
    if (isInitialReading) {
       
        currentIndex = currentIndex + 1;
        if (isBasic) {
            if (currentIndex > basicConfigDetails.count - 1) {
                currentIndex = 0;
                [self removeIndicator];
                [self readDeviceMacAndAuthSeed];
                 isInitialReading = NO;
                return;
            }
        } else {
            if ([self isNeedToRemoveFeatureEnableMaskSection]) {
                if (currentIndex > advanceConfigFeatureDetails.count - 1) {
                    currentIndex = 0;
                    [self removeIndicator];
                     isInitialReading = NO;
                    return;
                }
            }
            else{
                if (currentIndex > advanceConfigDetails.count - 1) {
                    currentIndex = 0;
                    [self removeIndicator];
                     isInitialReading = NO;
                    return;
                }
            }
            
        }
        [self readCharactisticsWithIndex:currentIndex];

    }
}

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


#pragma mark Fetch Device Mac and Seed

- (void)readDeviceMacAndAuthSeed {
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    [self getMac];
}

- (void)getMac {
    isFetchingMacOrSeedData = YES;
    [[LFBluetoothManager sharedManager] discoverCharacteristicsForAuthentication];
}

- (void)readCharactisticsWithIndex:(NSInteger)index
{
    Byte data[20];
    for (int i = 0; i < 20; i++) {
        if (i == 8) {
            if (index == FriendlyNameFirstWrite) {
                data[i] = FirstNameRegAddr;
            } else if (index == FriendlyNameSecondWrite) {
                data[i] = SecondNameRegAddr;
            } else if (index == FriendlyNameThirdWrite) {
                data[i] = ThirdNameRegAddr;
            } else if (index == ChangePasswordWrite) {
                data[i] = changePassword_AddrArr[curPassWriteIndex];
            } else if (index == ResetPasswordWrite) {
                
            } else {
                data[i] = isBasic ? basicMemMap[index] :([self isNeedToRemoveFeatureEnableMaskSection] ? advance_feature_MemMap[index] : advance_MemMap[index]);
            }
        } else if (i == 10){
            if (index == FriendlyNameFirstWrite) {
                data[i] = FirstNameRegLen;
            } else if (index == FriendlyNameSecondWrite) {
                data[i] = SecondNameRegLen;
            } else if(index == FriendlyNameThirdWrite) {
                data[i] = ThirdNameRegLen;
            } else if (index == ChangePasswordWrite) {
                data[i] = (Byte)0x08;
            } else if (index == ResetPasswordWrite) {
                
            } else {
                data[i] = isBasic ? basicMemFieldLens[index] : ([self isNeedToRemoveFeatureEnableMaskSection] ? advance_feature_MemMapFieldLens[index]:  advance_MemMapFieldLens[index]);
            }

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


- (void)readCharactisticData:(CBCharacteristic *)characteristic
{
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    [[LFBluetoothManager sharedManager] readValueForCharacteristic:characteristic];
    
   // NSData *data1 = [NSData dataWithBytes:data length:20];
   // [[LFBluetoothManager sharedManager] setSelectedTag:[NSString stringWithFormat:@"%d", (int)index]];
   // [[LFBluetoothManager sharedManager] writeConfigData:data1];
}
- (NSString *)getConvertedStringForValue:(NSUInteger) dataVal {
    
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
                } else {
                    if (currentIndex == 2 || currentIndex == 5) {
                        convertedVal = [NSString stringWithFormat:@"%0.1f %@", (float)val, basicUnitsArray[currentIndex]];
                    } else {
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
               /* if (currentIndex == 4) { //if(currentIndex == 5) {
                    convertedVal = [self getConvertedStringForValue:val];
                } else {*/
                  //  convertedVal = [NSString stringWithFormat:@"%.2f", val/100.0];
               // }
                
                if (currentIndex == Advanced_GFTC) {
                    convertedVal =  [self getConvertedStringForValue:val];
                }
                else{
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
            if (currentIndex == Advanced_GFTD) {
                convertedVal = [NSString stringWithFormat:@"%.1f sec", (float)val/10.0];
            } else{
              convertedVal = [NSString stringWithFormat:@"%d sec", (int)val];
            }
            
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
        LFDisplay *display = ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails objectAtIndex:currentIndex] :[advanceConfigDetails objectAtIndex:currentIndex]);
            if (currentIndex == AdvancedSection0RowsCount ) {
                if ([self isNeedToRemoveFeatureEnableMaskSection]) {
                    _hardwareConfigVal = val;
                } else{
                    _featureEndisVal = val;
                }
            } else if (currentIndex == AdvancedSection0RowsCount + AdvancedSectionFeaturesCount ) {
                _hardwareConfigVal = val;
            }
        if ([self isNeedToRemoveFeatureEnableMaskSection]) {
            switch ((AdvancedConfiguration)currentIndex+AdvancedSectionFeaturesCount) {
                case Advanced_SPM:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 5))? 1:0];
                    break;
                case Advanced_SPT:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 6))? 1:0];
                    break;
                case Advanced_PTC:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 9))? 1:0];
                    break;
                case Advanced_ACB:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 12))? 1:0];
                    break;
                case Advanced_GMFT:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 0))? 1:0];
                    break;
                    
                default:
                    display.value = convertedVal;
                    break;
            }
        } else {
            switch ((AdvancedConfiguration)currentIndex) {
                case Advanced_GFT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 0))? 1:0];
                    break;
                case Advanced_VUBT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 1))? 1:0];
                    break;
                case Advanced_CUBT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 2))? 1:0];
                    break;
                case Advanced_UCT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 3))? 1:0];
                    break;
                case Advanced_OCT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 4))? 1:0];
                    break;
                case Advanced_LINT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 5))? 1:0];
                    break;
                case Advanced_LPRT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 6))? 1:0];
                    break;
                case Advanced_HPRT:
                    display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 7))? 1:0];
                    break;
                case Advanced_SPM:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 5))? 1:0];
                    break;
                case Advanced_SPT:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 6))? 1:0];
                    break;
                case Advanced_PTC:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 9))? 1:0];
                    break;
                case Advanced_ACB:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 12))? 1:0];
                    break;
                case Advanced_GMFT:
                    display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 0))? 1:0];
                    break;
                    
                    //            case AdvancedSection0RowsCount+9:
                    //                //ptc
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 6))? 1:0];
                    //                break;
                    //            case AdvancedSection0RowsCount+10:
                    //                //ACB
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 7))? 1:0];
                    //                break;
                    //            case AdvancedSection0RowsCount+11:
                    //                // GMFT
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 8))? 1:0];
                    //                break;
                    //            case AdvancedSection0RowsCount+12:
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 9))? 1:0];
                    //                break;
                    //            case AdvancedSection0RowsCount+13:
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 10))? 1:0];
                    //                break;
                    //            case AdvancedSection0RowsCount+14:
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 11))? 1:0];
                    //                break;
                    //            case AdvancedSection0RowsCount+15:
                    //                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 12))? 1:0];
                    //                break;
                default:
                    display.value = convertedVal;
                    break;
            }
 
        }
        
        
        ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails replaceObjectAtIndex:currentIndex withObject:display] : [advanceConfigDetails replaceObjectAtIndex:currentIndex withObject:display]);
        
    }
    
    [tblConfigDisplay reloadData];
    //All the data is fetched after index = 28. Now fault refresh can be started to avoid blocking.
    
}


- (void)writeDataToIndex:(NSInteger)index withValue:(double)val
{
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    isWrite = YES;
    currentIndex = index;
    NSString *formate = isBasic ? basicFormateArray[currentIndex]: ([self isNeedToRemoveFeatureEnableMaskSection] ? advancedFormateWithoutMaskArray[currentIndex]: advancedFormateArray[currentIndex]);
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
            val = val * (100*1000);
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
                data[i] = isBasic ? basicMemMap[index] : ([self isNeedToRemoveFeatureEnableMaskSection] ? advance_feature_MemMap[index] : advance_MemMap[index]);
            } else if (i == 10){
                data[i] = isBasic ? basicMemFieldLens[index] : ([self isNeedToRemoveFeatureEnableMaskSection] ? advance_feature_MemMapFieldLens[index] :advance_MemMapFieldLens[index]);
            } else if (i == 11) {
                data[i] = (Byte)0x01;//write byte == 1
            } else {
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
    for (int i = 0; i<8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    prevWrittenData = mutData;
    [[LFBluetoothManager sharedManager] writeConfigData:mutData];
    canRefresh = YES;
    
}

#pragma mark Writing TimeOut Method.
- (void)checkTimeOut {
    if (!canRefresh || (([[LFBluetoothManager sharedManager] getConfigSeedData] == nil) && currentIndex == -1 )) {
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
    isReadingFriendlyName = YES;
    selectedTag = FriendlyNameFirstWrite;
    [self changeFriendlyNameProcess];
    
}

- (void)saveFriendlyNameDataToDevice:(NSData *)data {
    isWrite = YES;
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
    for (int i = 0; i< 8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    
    prevWrittenData = mutData;
    DLog(@"FriendlyName data:%@", mutData);
    canRefresh = YES;
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] writeConfigData:mutData];
}


- (void) changeFriendlyNameProcess {
    switch (selectedTag) {
        case FriendlyNameFirstWrite:
            // writing friendly name first eight bytes
            if (friendlyNameStr.length > 8) {
                NSData *firstStrData = [[friendlyNameStr substringToIndex:8] dataUsingEncoding:NSUTF8StringEncoding];
                NSData *firstData = [self getFriendlyNameData:firstStrData isFirstPart:YES];
                [self saveFriendlyNameDataToDevice:firstData];
            }
            else {
                NSData *firstStrData = [[friendlyNameStr substringToIndex:friendlyNameStr.length] dataUsingEncoding:NSUTF8StringEncoding];
                NSData *firstData = [self getFriendlyNameData:firstStrData isFirstPart:YES];
                [self saveFriendlyNameDataToDevice:firstData];
            }
            
            break;
        case FriendlyNameSecondWrite:
            
        {
            [authUtils nextAuthCode];
            NSData *secondStrData;
            if (friendlyNameStr.length > 8 ) {
                secondStrData = [[friendlyNameStr substringFromIndex:8] dataUsingEncoding:NSUTF8StringEncoding];
            } else if (friendlyNameStr.length <= 8) {
                Byte emptyData[4];
                for (int i = 0; i<4; i++) {
                    emptyData[i] = 0x00;
                }
                secondStrData = [NSData dataWithBytes:emptyData length:4];
            }
            NSData *secondData = [self getFriendlyNameData:secondStrData isFirstPart:NO];
            [self saveFriendlyNameDataToDevice:secondData];
            
        }
            break;
        case FriendlyNameThirdWrite:
        {
            [authUtils nextAuthCode];
            Byte data[20];
            NSInteger convertedVal = 83;
            char *bytes = (char *) malloc(8);
            memset(bytes, 0, 8);
            memcpy(bytes, (char *) &convertedVal, 8);
            
            for (int i = 0; i < 20; i++) {
                if (i < 8) {
                    data[i] = (Byte)bytes[i];// Save the data whatever we are entered here
                } else {
                    if (i == 8) {
                        data[i] = ThirdNameRegAddr;
                    } else if (i == 10){
                        data[i] = ThirdNameRegLen;
                    } else if (i == 11) {
                        data[i] = (Byte)0x01;//write byte == 1
                    }
                    else {
                        data[i] = (Byte)0x00;
                    }
                }
            }
            
            NSData *data1 = [NSData dataWithBytes:data length:20];
            [self saveFriendlyNameDataToDevice:data1];
            
        }
            break;
            
        default:
            break;
    }
}

- (NSData *)getFriendlyNameData:(NSData *)data isFirstPart:(BOOL)isFirstPart {
    NSMutableData *mutData = [[NSMutableData alloc] initWithData:data];
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
    // for authentication process we need to write any data to hardware on on success we need to check authentication process.
    isVerifyingPassword = YES;
    //passwordVal = passwordStr;
    [[LFBluetoothManager sharedManager] setPasswordString:passwordStr];
    LFDisplay *ctVal = (isBasic ? [basicConfigDetails objectAtIndex:0] : ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails objectAtIndex:0] : [advanceConfigDetails objectAtIndex:0])); //([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails objectAtIndex:0] : [advanceConfigDetails objectAtIndex:0]);
    [self writeDataToIndex:0 withValue:ctVal.value.doubleValue];
}

- (void)selectedValue:(NSString *)txt andPassword:(NSString *)password
{
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        if (password != nil) {
            [[LFBluetoothManager sharedManager] setPasswordString:password];
           // passwordVal = password;
        }
    }
    if (selectedTag == ResetPasswordWrite) {
        [self writeResetPasswordDataWithText:txt];
        return;
    }
    if (selectedTag == FriendlyNameFirstWrite || selectedTag == FriendlyNameSecondWrite) {
        [self saveNewFriendlyNameWithValue:txt];
        return;
    }
    else if (selectedTag == ChangePasswordWrite) {
        if ((txt.length == 0) || (txt == nil)) {
            [self showAlertWithText:kEnter_Valid_Password];
            return;
        }
        [self changePasswordWithNewValue:txt];
        return;
    }
    
    if (txt.length == 0) {
        txt = @"";
    }
    LFDisplay *display;
    if (isBasic) {
        display = [basicConfigDetails objectAtIndex:selectedTag];
        if (selectedTag == 3 || selectedTag == 4 ) {
            CGFloat curVal = txt.floatValue;
            display.value = [NSString stringWithFormat:@"%0.2f", (float)curVal*100.0f];
            txt = display.value;
        } else {
            display.value = txt;
        }
        [basicConfigDetails replaceObjectAtIndex:selectedTag withObject:display];
    } else {
        display = ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails objectAtIndex:selectedTag] : [advanceConfigDetails objectAtIndex:selectedTag]);
        if (selectedTag == Advanced_GFTD) {
            txt = [NSString stringWithFormat:@"%.2f",[txt floatValue] * 10.0] ;
        }
        display.value = txt;
        
        ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails replaceObjectAtIndex:selectedTag withObject:display] : [advanceConfigDetails replaceObjectAtIndex:selectedTag withObject:display]);
    }
    
    [self writeDataToIndex:selectedTag withValue:txt.doubleValue];
}

- (void)toggleSelectedWithSuccess:(BOOL)isSuccess andPassword:(NSString *)password{
    if (!isToggleCell) {
        return;
    }
    if (!isSuccess) {
        [tblConfigDisplay reloadData];
        return;
    }
    
    LFDisplay *display = ([self isNeedToRemoveFeatureEnableMaskSection] ? advanceConfigFeatureDetails[selectedTag] :advanceConfigDetails[selectedTag]);
    display.value = [NSString stringWithFormat:@"%d", !display.value.boolValue];
    ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails replaceObjectAtIndex:selectedTag withObject:display] :[advanceConfigDetails replaceObjectAtIndex:selectedTag withObject:display]);
    
    if (!isBasic) {
        if ([self isNeedToRemoveFeatureEnableMaskSection]) {
               if (selectedTag >= AdvancedSection0RowsCount && selectedTag <= AdvancedSection0RowsCount + AdvancedSectionHardwareConfigurationCount - 1){// here 1 for last index for buttons cell
                switch (selectedTag + AdvancedSectionFeaturesCount) {
                    case Advanced_SPM:
                        _hardwareConfigVal  ^= 1 << 5;
                        break;
                    case Advanced_SPT:
                        _hardwareConfigVal  ^= 1 << 6;
                        break;
                    case Advanced_PTC:
                        _hardwareConfigVal  ^= 1 << 9;
                        break;
                    case Advanced_ACB:
                        _hardwareConfigVal  ^= 1 << 12;
                        break;
                    case Advanced_GMFT:
                        _hardwareConfigVal  ^= 1 << 0;
                        break;
                     default:
                        break;
                }
                [self writeDataToIndex:selectedTag withValue:(float)_hardwareConfigVal];
            }
        }
        else{
            
            if (selectedTag >= AdvancedSection0RowsCount && selectedTag <= AdvancedSection0RowsCount + AdvancedSectionFeaturesCount - 1) {
                switch (selectedTag) {
                    case Advanced_GFT:
                        _featureEndisVal  ^= 1 << 0;
                        break;
                    case Advanced_VUBT:
                        _featureEndisVal  ^= 1 << 1;
                        break;
                    case Advanced_CUBT:
                        _featureEndisVal  ^= 1 << 2;
                        break;
                    case Advanced_UCT:
                        _featureEndisVal  ^= 1 << 3;
                        break;
                    case Advanced_OCT:
                        _featureEndisVal  ^= 1 << 4;
                        break;
                    case Advanced_LINT:
                        _featureEndisVal  ^= 1 << 5;
                        break;
                    case Advanced_LPRT:
                        _featureEndisVal  ^= 1 << 6;
                        break;
                    case Advanced_HPRT:
                        _featureEndisVal  ^= 1 << 7;
                        break;
                    default:
                        break;
                }
                [self writeDataToIndex:selectedTag withValue:(float)_featureEndisVal];
            }
            else if (selectedTag >= AdvancedSection0RowsCount+AdvancedSectionFeaturesCount && selectedTag <= AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+AdvancedSectionHardwareConfigurationCount - 1) {// here 1 for last index for buttons cell
                switch (selectedTag) {
                    case Advanced_SPM:
                        _hardwareConfigVal  ^= 1 << 5;
                        break;
                    case Advanced_SPT:
                        _hardwareConfigVal  ^= 1 << 6;
                        break;
                    case Advanced_PTC:
                        _hardwareConfigVal  ^= 1 << 9;
                        break;
                    case Advanced_ACB:
                        _hardwareConfigVal  ^= 1 << 12;
                        break;
                    case Advanced_GMFT:
                        _hardwareConfigVal  ^= 1 << 0;
                        break;
                        
                        // below fields will be enable in future
                        
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+1:
                        //                    _hardwareConfigVal  ^= 1 << 6;
                        //                    break;
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+2:
                        //                    _hardwareConfigVal  ^= 1 << 7;
                        //                    break;
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+3:
                        //                    _hardwareConfigVal  ^= 1 << 8;
                        //                    break;
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+4:
                        //                    _hardwareConfigVal  ^= 1 << 9;
                        //                    break;
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+5:
                        //                    _hardwareConfigVal  ^= 1 << 10;
                        //                    break;
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+6:
                        //                    _hardwareConfigVal  ^= 1 << 11;
                        //                    break;
                        //                case AdvancedSection0RowsCount+AdvancedSectionFeaturesCount+7:
                        //                    _hardwareConfigVal  ^= 1 << 12;
                        //                    break;
                    default:
                        break;
                }
                [self writeDataToIndex:selectedTag withValue:(float)_hardwareConfigVal];
            }
        }
       
    }
    
    [tblConfigDisplay reloadData];
}

- (void)showOperationCompletedAlertWithStatus:(BOOL)isSuccess withCharacteristic:(CBCharacteristic *)characteristic
{
    if(isResetPassword) return;
    [[LFBluetoothManager sharedManager] setIsWriting:NO];
    [self removeIndicator];
    if (isSuccess) {
        [self readCharactisticData:characteristic];
        /*
        if (isVerifyingPassword) {
            [self readCharactisticsWithIndex:0];
        }
        else if (isChangingPassword) {
            [self readCharactisticsWithIndex:ChangePasswordWrite];
        }
        else {
            [self readCharactisticsWithIndex:selectedTag];
        }*/
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

#pragma  Mark - Reset password
- (void) writeResetPasswordDataWithText:(NSString *) text {
    
    [self  showIndicatorOn:self.tabBarController.view withText:@"Reseting Password..."];

    isWrite = YES;
    isResetPassword = YES;
    NSData *passData = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encriptedData = [[LFBluetoothManager sharedManager] getCommandEncriptedDataForResetPasswordWithValue:passData andAddress:(Byte)0x00d4 andLength:(Byte)0x04];
    

   // NSData *encriptedData = [[LFBluetoothManager sharedManager] getCommandEncriptedDataWithValue:passData andAddress:(Byte)0x00d4 andLength:(Byte)0x04];
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    DLog(@"password Data writing to device = %@", encriptedData);
    prevWrittenData = encriptedData;
    [[LFBluetoothManager sharedManager] writeConfigData:encriptedData];
    canRefresh = YES;
    [self performSelector:@selector(resetPasswordCompletionAction) withObject:nil afterDelay:10];
   
}
#pragma mark Change Password Methods.
-(void)resetPasswordCompletionAction
{
    [self removeIndicator];
   // [self.navigationController popToRootViewControllerAnimated:NO];
    LFTabbarController *tabController = (LFTabbarController *)self.tabBarController;
    [tabController moveToDevicesListController];
}
- (void)changePasswordWithNewValue:(NSString *)newPassword {
    // TODO: for present requirements  we got 32 bits remining 32 bite data fill with zeros
    [self showIndicatorOn:self.tabBarController.view withText:@"Changing password..."];
    if (authUtils == nil) {
        authUtils = [[LFAuthUtils alloc]init];
        //[authUtils initWithPassKey:[[LFBluetoothManager sharedManager] getPasswordString] andMacAddress:[[LFBluetoothManager sharedManager] getMacString] andSeed: [[LFBluetoothManager sharedManager] getConfigSeedData].bytes ];
    }
   /* if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        [authUtils initWithPassKey:[[LFBluetoothManager sharedManager] getPasswordString] andMacAddress:[[LFBluetoothManager sharedManager] getMacString] andSeed: [[LFBluetoothManager sharedManager] getConfigSeedData].bytes ];
    }*/
    
    
    
    char *filledData = (char *) malloc(32);
    memset(filledData, 0, 32);
    newPasswordStr = newPassword;
    completePasswordData = [authUtils getNewPassKeydata:newPassword];
    [completePasswordData appendBytes:filledData length:32];
    [[LFBluetoothManager sharedManager] setIsPassWordChange:YES];
    curPassWriteIndex = 0;
    [self writeNewPasswordDataWithIndex:0];
}

- (void)writeNewPasswordDataWithIndex:(NSInteger)passIndex {
    
    NSData *passData = [completePasswordData subdataWithRange:NSMakeRange(passIndex*8, 8)];
    isWrite = YES;
    
    NSData *encriptedData = [self getCommandEncriptedDataWithValue:passData andAddress:changePassword_AddrArr[curPassWriteIndex] andLength:(Byte)0x08];
    
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    DLog(@"password Data writing to device = %@", encriptedData);
    prevWrittenData = encriptedData;
    [[LFBluetoothManager sharedManager] writeConfigData:encriptedData];
    canRefresh = YES;
    
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
   NSData *resultData =   [self getEncryptedPasswordDataFromString:@"" data:[data1 subdataWithRange:NSMakeRange(0, 8)] address:address size:length];
  //  NSData *resultData = [self getEncryptedPasswordData:[data1 subdataWithRange:NSMakeRange(0, 8)] address:address size:length];
    NSMutableData *mutData = [NSMutableData dataWithData:data1];
    for (int i = 0; i<8;i++) {
        NSData *subdata = [resultData subdataWithRange:NSMakeRange(i, 1)];
        [mutData appendData:subdata];
    }
    return mutData;


}
#pragma  mark MEthods for Feature enable mask chacking

- (void) checkFeatureValuesWith:(BOOL) isBasicSettings andIndex:(NSUInteger) index {
    if (isBasicSettings) {
        LFDisplay *display = basicConfigDetails[index];
        switch (index) {
            case Basic_VUB:
                display.value = [self getDisplayValueForDisplay:display];
                break;
                case Basic_CUB:
                display.value = [self getDisplayValueForDisplay:display];
                break;
                case Basic_UC:
                display.value = [self getDisplayValueForDisplay:display];
                break;
                
            default:
                break;
        }
        [basicConfigDetails replaceObjectAtIndex:index withObject:display];
        
    } else {
        
        LFDisplay *display = ([self isNeedToRemoveFeatureEnableMaskSection] ? advanceConfigFeatureDetails[index] : advanceConfigDetails[index]);
              switch (index) {
               case Advanced_GFTC:
                   display.value = [self getDisplayValueForDisplay:display];
//                   if ((display.value.length > 0) && [[display.value substringToIndex:1] isEqualToString:@"0"]) {
//                       display.value = @"0=Off";
//                   }
                   break;
                   case Advanced_LKW:
                   display.value = [self getDisplayValueForDisplay:display];

                   break;
                   case Advanced_LINTD:
                   display.value = [self getDisplayValueForDisplay:display];

                   break;
                   case Advanced_HKW:
                   display.value = [self getDisplayValueForDisplay:display];

                   break;
               case Advanced_STLP:
                   display.value = [self getDisplayValueForDisplay:display];
 
                   break;
               default:
                   break;
           }
        ([self isNeedToRemoveFeatureEnableMaskSection] ? [advanceConfigFeatureDetails replaceObjectAtIndex:index withObject:display] : [advanceConfigDetails replaceObjectAtIndex:index withObject:display]);
    }
}

-(NSString *)getDisplayValueForDisplay:(LFDisplay *)display
{
    NSString *valueString = OFFString;
    if ((display.value.length > 0) ) {
        if (![display.value isEqualToString:OFFString]) {
            NSArray *valuesArray = [display.value componentsSeparatedByString:@" "];
            NSString *value = (valuesArray.count > 1 ? [valuesArray objectAtIndex:0] : display.value);
            valueString = ([value floatValue]>0.0 ? display.value : OFFString);
        }
    }
    return valueString;
}
- (BOOL) isNeedToRemoveFeatureEnableMaskSection {
    
    return YES;  //Please remove return if client ask for feature enabled disabled section
    // FIXME: refacter this code
    /* THIS METHOD CHECKING CONFIGURATION FEATURED VALUES EXCEPT */
  /*  if (!((basicConfigDetails != nil && basicConfigDetails.count > 0) && (advanceConfigDetails != nil && advanceConfigDetails.count > 0))) {
        return NO;
    }
    BOOL basicStatus = YES;
    for (int index = 0; index < 3; index++) {
        LFDisplay *display;
        switch (index) {
            case 0:
                display = basicConfigDetails[Basic_VUB];
                break;
            case 1:
                display = basicConfigDetails[Basic_CUB];
                break;
            case 2:
                display = basicConfigDetails[Basic_UC];
                break;
            default:
                break;
        }
        if (!((display.value.length > 0) && [[display.value substringToIndex:1] isEqualToString:@"0"])) {
            basicStatus = NO;
        }
    }
    BOOL advancedStatus = YES;
    for (int index = 0; index < 5; index++) {
        LFDisplay *display;
        switch (index) {
            case 0:
                display = advanceConfigDetails[Advanced_GFTC];
                break;
            case 1:
                display = advanceConfigDetails[Advanced_LKW];
                break;
            case 2:
                display = advanceConfigDetails[Advanced_LINTD];
                break;
            case 3:
                display = advanceConfigDetails[Advanced_HKW];
                break;
            case 4:
                display = advanceConfigDetails[Advanced_STLP];
                break;
            default:
                break;
                

        }
        if (!((display.value.length > 0) && [[display.value substringToIndex:1] isEqualToString:@"0"])) {
            advancedStatus = NO;
        }
    }
    
    return (basicStatus && advancedStatus);*/
}

#pragma mark Setter Methods

- (void) setIsSTFieldSuccess:(BOOL)isSTFieldSuccess {
    if (timer != nil && [timer isValid]) {
        [timer invalidate];
        timer = nil;
    }
    if (isSTFieldSuccess) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(readForFailureData) userInfo:nil repeats:YES];
    }
    _isSTFieldSuccess = isSTFieldSuccess;
}

#pragma  mark - timer methods

- (void) readForFailureData {
   // this method call till st field get success response upto 10 times
    
    if (stFieldSuccessCount != 10) {
        //[self showIndicatorOn:self.tabBarController.view withText:@"data loading..."];
        [self readCharactisticsWithIndex:currentIndex];
    } else {
        [self removeIndicator];
        [self showAlertViewWithCancelButtonTitle:kOK withMessage:kUpdateFailed withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
        }];
        self.isSTFieldSuccess = NO;
        stFieldSuccessCount = 0;
    }
    stFieldSuccessCount++ ;
}

-(void)restartFaultLoading
{
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:Background_Fault_Refresh_Interval];
    
}
#pragma mark Peripheral Disconnected Notification

- (void)peripheralDisconnected {
    [self removeIndicator];
    if (!canContinueTimer) {
        return;
    }
    [editing authDoneWithStatus:YES shouldDismissView:YES];
    [self showAlertViewWithCancelButtonTitle:kOK withMessage:kDevice_Disconnected withTitle:kApp_Name otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
        if ([alert isKindOfClass:[UIAlertController class]]) {
            [alert dismissViewControllerAnimated:NO completion:nil];
            
            LFTabbarController *tabController = (LFTabbarController *)self.tabBarController;
            [tabController moveToDevicesListController];
            
           // [self.navigationController popToRootViewControllerAnimated:NO];
        }
    }];
}



@end
