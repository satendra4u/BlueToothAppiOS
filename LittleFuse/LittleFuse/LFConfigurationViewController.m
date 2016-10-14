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

#define BUTTON_CELL_ID @"LFConfigureButtonsCellID"
#define TOGGLE_CELL_ID @"LFCharactersticBitDisplayCell"

#define FirstNameRegAddr 0x6A
#define SecondNameRegAddr 0x72
#define FirstNameRegLen 0x08
#define SecondNameRegLen 0x04

#pragma mark Info regarding sections in the table.

#define BasicSection0RowsCount 3
#define BasicSection1RowsCount 4
#define BasicSection2RowsCount 4
#define BasicSection3RowsCount 2
#define AdvancedSection0RowsCount 12
#define AdvancedSection1RowsCount 7
#define AdvancedSection2RowsCount 9

@interface LFConfigurationViewController () < EditingDelegate, BlutoothSharedDataDelegate, ToggleTappedProtocol, LFTabbarRefreshDelegate>
{
    
    __weak IBOutlet UITableView *tblConfigDisplay;
    NSMutableArray *basicConfigDetails;
    NSMutableArray *advanceConfigDetails;
    NSMutableArray *basicValuesArray;

    NSArray  *basicFormateArray;
    NSArray *advancedFormateArray;
    NSArray *basicUnitsArray, *advUnitsArray;
    
    BOOL isBasic;
    BOOL isWrite;
    BOOL isAdvanceLoded;
    BOOL canContinueTimer;
    BOOL isInitialLaunch;
    
    NSInteger currentIndex;
    NSInteger selectedTag;
    NSString *previousSelected;
    NSInteger prevEnteredVal;//Used to compare previously entered value.
    
    UIView *changePasswordView;
    UIButton *changePasswordButton;
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
    0x42, 0x46, 0x4A, 0x4C, 0x4E, 0x50, 0x56,0x56,0x56,0x56,0x56,0x56,0x56 ,0x5A,0x5A,0x5A,0x5A,0x5A,0x5A,0x5A,0x5A};
const char advance_MemMapFieldLens[] = {0x2, 0x2, 0x2,/* 0x2,*/ 0x2, 0x4, 0x2,/* 0x2,*/ 0x4, 0x4, 0x2, 0x2, 0x2, 0x2, 0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04, 0x04,0x04};


- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self setUpTableViewFooter];
    [tblConfigDisplay reloadData];
}

- (void)setDeviceName:(NSString *)deviceName {
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Device ID: %@", deviceName]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(10, string.length-10)];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:AERIAL_REGULAR size:15.0] range:NSMakeRange(0, 10)];
    _deviceId.attributedText = string;}

- (void)appEnteredBackground {
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
    LFDisplay *lin = [[LFDisplay alloc] initWithKey:@"Linear Over Current Trip Delay" Value:@"" Code:@"LIN"];
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
    LFDisplay *bitSix = [[LFDisplay alloc] initWithKey:@"LPR Trip" Value:@"" Code:@"LPRT"];
    LFDisplay *bitSeven = [[LFDisplay alloc] initWithKey:@"HPR Trip" Value:@"" Code:@"HPRT"];
    LFDisplay *configBitFive = [[LFDisplay alloc] initWithKey:@"Zero L2 and L3 voltages" Value:@"" Code:@"ZV"];
    LFDisplay *configBitSix = [[LFDisplay alloc] initWithKey:@"Single Phase voltage" Value:@"" Code:@"SPV"];
    LFDisplay *configBitSeven = [[LFDisplay alloc] initWithKey:@"Single Phase current" Value:@"" Code:@"SPC"];
    LFDisplay *configBitEight = [[LFDisplay alloc] initWithKey:@"Disable RP" Value:@"" Code:@"RP"];
    LFDisplay *configBitNine = [[LFDisplay alloc] initWithKey:@"Low Control voltage trip" Value:@"" Code:@"LCVT"];
    LFDisplay *configBitTen = [[LFDisplay alloc] initWithKey:@"Stall 1" Value:@"" Code:@"STAL"];
    LFDisplay *configBitEleven = [[LFDisplay alloc] initWithKey:@"Low KV mode" Value:@"" Code:@"LKV"];
    LFDisplay *configBitTwelve = [[LFDisplay alloc] initWithKey:@"CBA phase rotation" Value:@"" Code:@"CBA"];
    
    
    //"Stall Percentage", "Stall Trip Delay", "Stall Inhibit Delay", "Feature enable/disable Mask"
    
    advanceConfigDetails = [[NSMutableArray alloc] initWithObjects:currentTansformer, pt, ultd/*, cutd*/, lin, gftc, gftd,/* gfib,*/ lkw, hkw, hptd, stallPercenage, stallTripDelay, stallInhibt, bitZero, bitOne, bitTwo, bitThree, bitFour, bitSix, bitSeven, configBitFive, configBitSix, configBitSeven, configBitEight, configBitNine, configBitTen, configBitEleven, configBitTwelve, nil];
    
    isBasic = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureServiceWithValue:) name:CONFIGURATION_NOTIFICATION object:nil];
    basicFormateArray = @[@"H", @"H", @"G", @"B", @"B", @"G",  @"B",  @"L", @"L", @"L", @"L",@"B",@"B"];
    advancedFormateArray = @[@"B", @"B", @"L",/* @"Q",*/ @"L", @"H", @"Q",/* @"L",*/ @"K", @"K", @"L", @"B", @"Q", @"Q", @"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C", @"C",@"C"];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self performSelector:@selector(stopIndicator) withObject:nil afterDelay:5.5];
    [self performSelector:@selector(updateFaultData) withObject:nil afterDelay:2];
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
        [LFBluetoothManager sharedManager].tCurIndex = 1;
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
    [changePasswordButton addTarget:self action:@selector(changePwdAction:) forControlEvents:UIControlEventTouchUpInside];
    changePasswordButton.layer.cornerRadius = 4.0f;
    tblConfigDisplay.tableFooterView = changePasswordView;
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
    LFEditingViewController *editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
    
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    
    if (indexPath.row == -1) {
        editing.selectedText = @"Name";
    }
    else {
        editing.selectedText = cell.lblKey.text;
    }
    editing.delegate = self;
    editing.showAuthentication = YES;
    [navController setViewControllers:@[editing]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController presentViewController:navController animated:NO completion:nil];
    });
}

- (void)toggledTappedAtIndexPath:(NSIndexPath *)indexPath {
    LFNavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingNavigationController"];
    LFEditingViewController *editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
    if (indexPath.section == 1) {
        selectedTag = indexPath.row+AdvancedSection0RowsCount;
    } else if (indexPath.section == 2) {
        selectedTag = indexPath.row + AdvancedSection0RowsCount + AdvancedSection1RowsCount;
    }
    else if (indexPath.row == -1) {
        //For edit action.
        selectedTag = -1;
    }
    
    self.providesPresentationContextTransitionStyle = YES;
    self.definesPresentationContext = YES;
    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
    editing.delegate = self;
    editing.showAuthentication = YES;
    editing.isAdvConfig = YES;
    [navController setViewControllers:@[editing]];
    [self.navigationController presentViewController:navController animated:NO completion:nil];
    
}


- (IBAction)changePwdAction:(id)sender {
    
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
    if (currentIndex == -1) {
        NSRange range = NSMakeRange(0, 8);
        
        data = [data subdataWithRange:range];
        NSString *nameVal = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        DLog(@"Entered name  is %@", nameVal);
        return;
    }
    else {
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
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 6))? 1:0];
                break;
            case AdvancedSection0RowsCount+6:
                display.value = [NSString stringWithFormat:@"%d", (_featureEndisVal & (1 << 7))? 1:0];
                break;
            case AdvancedSection0RowsCount+7:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 5))? 1:0];
                break;
            case AdvancedSection0RowsCount+8:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 6))? 1:0];
                break;
            case AdvancedSection0RowsCount+9:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 7))? 1:0];
                break;
            case AdvancedSection0RowsCount+10:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 8))? 1:0];
                break;
            case AdvancedSection0RowsCount+11:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 9))? 1:0];
                break;
            case AdvancedSection0RowsCount+12:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 10))? 1:0];
                break;
            case AdvancedSection0RowsCount+13:
                display.value = [NSString stringWithFormat:@"%d", (_hardwareConfigVal & (1 << 11))? 1:0];
                break;
            case AdvancedSection0RowsCount+14:
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
    char* bytes = (char*) &convertedVal;
    
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
    [self performSelector:@selector(checkTimeOut) withObject:nil afterDelay:1];
    [tblConfigDisplay reloadData];
    
}

#pragma mark Writing TimeOut Method.
- (void)checkTimeOut {
    if (isWrite) {
        [[LFBluetoothManager sharedManager] setIsWriting:NO];
        [self readCharactisticsWithIndex:selectedTag];
        [self removeIndicator];
        isWrite = NO;
        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Data saved successfully." withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
            [tblConfigDisplay reloadData];
        }];
    }
}

#pragma mark Name change action.
- (void)saveNewFriendlyNameWithValue:(NSString *)txt {
    if (txt == nil || txt.length == 0) {
        return;
    }
    currentIndex = -1;
    NSData *data1;
    if (txt.length > 8) {
        const char *firstEightBytes = [[txt substringToIndex:8] UTF8String];
        NSData *firstData = [self getFirstEightBytesOfData:firstEightBytes];
        selectedTag = -1;
        [self saveDataToDevice:firstData];
       const char *lastFourBytes = [[txt substringFromIndex:8] UTF8String];
        NSData *lastData = [self getLastFourBytesOfData:lastFourBytes];
        selectedTag = -2;
        [self saveDataToDevice:lastData];
    }
    else {
        const char *bytes = [txt UTF8String];
        data1 = [self getFirstEightBytesOfData:bytes];
        selectedTag = -1;
        [self saveDataToDevice:data1];
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
    [[LFBluetoothManager sharedManager] setIsWriting:YES];
    [[LFBluetoothManager sharedManager] setRealtime:NO];
    [[LFBluetoothManager sharedManager] setConfig:YES];
    [[LFBluetoothManager sharedManager] writeConfigData:data];
    [self performSelector:@selector(checkTimeOut) withObject:nil afterDelay:1];
}

- (NSData *)getFirstEightBytesOfData:(const char *)bytes {
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
                data[i] = FirstNameRegAddr;
            } else if (i == 10){
                data[i] = FirstNameRegLen;
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
- (void)selectedValue:(NSString *)txt
{
    [self showIndicatorOn:self.tabBarController.view withText:@"Loading Configuration..."];
    if (selectedTag == -1 || selectedTag == -2) {
        [self saveNewFriendlyNameWithValue:txt];
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

- (void)toggleSelectedWithSuccess:(BOOL)isSuccess {
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
                    _featureEndisVal  ^= 1 << 6;
                    break;
                case AdvancedSection0RowsCount+6:
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
    if (selectedTag == -1 || selectedTag == -2) {
        [self readNameValueAfterUpdating];
    }
    else {
        [self readCharactisticsWithIndex:selectedTag];
    }
    [self removeIndicator];
    if (isSuccess) {
        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Data saved successfully." withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
            [tblConfigDisplay reloadData];
        }];
    }
    else {
        //Error occured while writing data to device.
        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"There is a problem saving data." withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    if (!canContinueTimer) {
        return;
    }
    [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Device Disconnected" withTitle:@"Littelfuse" otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
        if ([alert isKindOfClass:[UIAlertController class]]) {
            [alert dismissViewControllerAnimated:NO completion:nil];
            [self.navigationController popToRootViewControllerAnimated:NO];
        }
    }];
}
@end
