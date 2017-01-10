//
//  ViewController.m
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFDevicesListController.h"
#import "LFNavigationController.h"
#import "LFEditingViewController.h"
#import "LFBluetoothManager.h"
#import "LFDeviceTableViewCell.h"
#import "LFTabbarController.h"
#import "LFConstants.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "UIImage+LFImage.h"
#import <CoreBluetooth/CoreBluetooth.h>


#define kDeviceCellID  @"DeviceCellID"

@interface LFDevicesListController () <BlutoothSharedDataDelegate, UITableViewDelegate, UITableViewDataSource, EditingDelegate>
{
    BOOL isPopupOpened;
    BOOL isInitialLaunch;
    BOOL canRefresh;
    BOOL isDeviceSelected;
    BOOL isScanDataFound;
    
    NSInteger selectedIndex;
    NSInteger refreshTimeInterval;
    
    NSMutableArray *peripheralsList;
    NSMutableArray *charactersticsList;
    
    __weak IBOutlet UITableView *tblDevices;
    __weak IBOutlet UILabel *lblScanning;
    __weak IBOutlet UILabel *lblVersion;
}
@property (strong, nonatomic) CBCentralManager *centralManager;

@end


@implementation LFDevicesListController

- (void)viewDidLoad
{
    [super viewDidLoad];
    isInitialLaunch = YES;
    isDeviceSelected = NO;
    isScanDataFound = NO;
    // Do any additional setup after loading the view, typically from a nib.
    peripheralsList = [[NSMutableArray alloc] initWithCapacity:0];
    charactersticsList = [[NSMutableArray alloc] initWithCapacity:0];
    
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [[LFBluetoothManager sharedManager] createObjects];

    [LFBluetoothManager sharedManager].centralManager = [[CBCentralManager alloc] initWithDelegate:[LFBluetoothManager sharedManager] queue:nil];
    
    [tblDevices setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navigateToDislay:) name:DISPLAY_TABBAR object:nil];
    lblVersion.text = [NSString stringWithFormat:@"Version:%@",  [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(peripheralConnected) name:PeripheralDidConnect object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(peripheralDisconnnected) name:PeripheralDidDisconnect object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becameActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBecomeInActive) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self performSelector:@selector(checkForNoDevices) withObject:nil afterDelay:5];
}

/**
 * This method is called when app enters background.
 */
- (void)appEnteredBackground {
    [[LFBluetoothManager  sharedManager] disconnectDevice];
}

/**
 * This method is called when app comes into active state.
 */
- (void)becameActive {
    [self reloadDevicesList];
}

/**
 * This method is called when app is going to become active.
 */
- (void)willBecomeInActive {
    canRefresh = YES;
}

/**
 * This method is called when a peripheral is connected to the mobile device.
 */
- (void)peripheralConnected {
    isPopupOpened = YES;
}

/**
 * This method is called when device is disconnected from the hardware.
 */
- (void)peripheralDisconnnected {
    isPopupOpened = NO;
}

- (void)checkForNoDevices {
    if (!canRefresh) {
        return;
    }
    if (peripheralsList.count == 0) {
        lblScanning.text = @"No devices found.";
    }
    else {
        lblScanning.text = @"Scanning for MP8000 devices...";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    if ([[LFBluetoothManager sharedManager] discoveredPeripheral] != nil) {
//        [[LFBluetoothManager sharedManager] disconnectPeripheral];
//    }
//    else {
        [self initialSetup];
//    }
   }

- (void)initialSetup{
    [LFBluetoothManager sharedManager].isPasswordVerified = NO;
    //    NSLog(@"%s",__func__);
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    isPopupOpened = NO;
    isDeviceSelected = NO;
    self.navigationItem.title = @"";
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [[LFBluetoothManager sharedManager] setDisplayCharacterstics:NO];
    if ([[LFBluetoothManager sharedManager] getDevicesList]) {
        peripheralsList = [[LFBluetoothManager sharedManager] getDevicesList];
        //        NSLog(@"%s", __func__);
        [tblDevices reloadData];
    }
    canRefresh = YES;
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    if (batteryLevel > 0.20) {
        refreshTimeInterval = 5;
    }
    else {
        refreshTimeInterval = 600;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadDevicesList];
    });
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    [LFBluetoothManager sharedManager].isPasswordVerified = NO;
}



- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    isPopupOpened = NO;
    self.navigationItem.title = @"";
    canRefresh = NO;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (void)reloadDevicesList {
    if (!canRefresh) {
        return;
    }
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    if (batteryLevel > 0.20) {
        refreshTimeInterval = 5;
    }
    else {
        refreshTimeInterval = 600;
    }
    if (!isPopupOpened) {
        [self scanAction:nil];
    }
    [self performSelector:@selector(reloadDevicesList) withObject:nil afterDelay:refreshTimeInterval];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Delegate -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    lblScanning.hidden = [peripheralsList count] ? YES : NO;
    return peripheralsList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LFDeviceTableViewCell *cell = (LFDeviceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kDeviceCellID];
    
    LFPeripheral *dict = peripheralsList[indexPath.row];
    cell.tag = indexPath.row;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    [cell updateCellWithDict:dict];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedIndex = indexPath.row;
    isPopupOpened = YES;
    isDeviceSelected = YES;
    [[LFBluetoothManager sharedManager] connectToDevice:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Blutooth Shared Data Delegate -
/**
 * This method is called to display discovered devices to the user.
 */
- (void)showScannedDevices:(NSMutableArray *)devicesArray
{
    if (devicesArray.count) {
        isScanDataFound = YES;
    }
    peripheralsList = [devicesArray mutableCopy];
//    NSLog(@"%s", __func__);
    [tblDevices reloadData];
}

/**
 * This method is called after receiving characteristics from the BLE device.
 */
- (void)showCharacterstics:(NSMutableArray *)charactersticsArray
{
    charactersticsList = charactersticsArray;
    CBCharacteristic *charactestic = (CBCharacteristic *)charactersticsArray[4];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
    
}

#pragma mark - Private methods -

- (IBAction)scanAction:(id)sender
{
    isScanDataFound = NO;
    [self performSelector:@selector(verifyDeviceCount) withObject:nil afterDelay:3];
    [[LFBluetoothManager sharedManager] disconnectDevice];
}

/**
 * This method checks if there are any devices available to connect.
 */
- (void)verifyDeviceCount {
    if (!isScanDataFound) {
        [peripheralsList removeAllObjects];
//        NSLog(@"%s", __func__);
        [tblDevices reloadData];
    }
}

- (void)navigateToDislay:(NSNotification *)notification
{
    if (!isDeviceSelected) {
        return;
    }
    
    
//    //Display authentication popup.After successfully entering the password, then execute the code below.
//    LFNavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingNavigationController"];
//    LFEditingViewController *editing = [self.storyboard instantiateViewControllerWithIdentifier:@"LFEditingViewControllerID"];
//    
//    self.providesPresentationContextTransitionStyle = YES;
//    self.definesPresentationContext = YES;
//    [editing setModalPresentationStyle:UIModalPresentationOverCurrentContext];
//    [navController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
//    editing.delegate = self;
//    editing.isFromDevicesList = YES;
//    editing.showAuthentication = YES;
//    [navController setViewControllers:@[editing]];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.navigationController presentViewController:navController animated:NO completion:nil];
//    });
//
    
    [self continueAfterPasswordAuthentication];
    
   }


- (void)continueAfterPasswordAuthentication {
    isPopupOpened = YES;
    LFPeripheral *peripheral = peripheralsList[selectedIndex];
    LFTabbarController *tabbar = (LFTabbarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
    
    if (!peripheral.isConfigured) { //(LV > HV)
        NSMutableArray *viewControllers = [tabbar.viewControllers mutableCopy];
        [self showAlertViewWithCancelButtonTitle:@"Configure" withMessage:@"" withTitle:NSLocalizedString(@"This MP8000 has not yet been Configured. Configure this MP8000 now?", (@"This MP8000 has not yet been Configured. Configure this MP8000 now?", )) otherButtons:@[@"No", @"Cancel"] clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            NSInteger numberOfControllers = 3;
            switch (index) {
                case 2:
                {
                    if ([alert isKindOfClass:[UIAlertController class]]) {
                        [alert dismissViewControllerAnimated:YES completion:nil];
                        isPopupOpened = NO;
                        isDeviceSelected = NO;
                    }
                }
                    return;
                    break;
                case 1:
                {
                    
                    numberOfControllers = 2;
                    [viewControllers removeLastObject];
                    if ([alert isKindOfClass:[UIAlertController class]]) {
                        [alert dismissViewControllerAnimated:YES completion:nil];
                    }
                    isPopupOpened = NO;
                    isDeviceSelected = NO;
                    
                }
                    break;
                case 0:
                {
                    numberOfControllers = 3;
                    
                    if ([alert isKindOfClass:[UIAlertController class]]) {
                        [alert dismissViewControllerAnimated:YES completion:nil];
                    }
                    [tabbar setSelectedIndex:1];
                    isPopupOpened = NO;
                    isDeviceSelected = NO;
                    
                }
                    break;
                    
                default:
                    break;
                    
            }
            
            tabbar.viewControllers = viewControllers;
            float width = CGRectGetWidth(self.view.frame)/numberOfControllers;
            
            [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageFromColor:APP_THEME_COLOR withSize:CGSizeMake(width, 50)]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![[self.navigationController.viewControllers lastObject] isKindOfClass:[LFTabbarController class]]) {
                    [self.navigationController pushViewController:tabbar animated:YES];
                }
                [[LFBluetoothManager sharedManager] setDisplayCharacterstics:YES];
                
            });
            
        }];
        
    } else {
        float width = CGRectGetWidth(self.view.frame)/3;
        
        [[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageFromColor:APP_THEME_COLOR withSize:CGSizeMake(width, 50)]];
        
        if (![[self.navigationController.viewControllers lastObject] isKindOfClass:[LFTabbarController class]]) {
            [self.navigationController pushViewController:tabbar animated:YES];
        }
        [[LFBluetoothManager sharedManager] setDisplayCharacterstics:YES];
        
    }

}


/**
 * This method displays an alert with a given message.
 */
- (void)showAlertWithText:(NSString *)msg
{
    if (([msg caseInsensitiveCompare:@"Encryption is insufficient."] == NSOrderedSame) || ([msg caseInsensitiveCompare:@"Encryption is insufficient"] == NSOrderedSame)) {
        isPopupOpened = NO;
        [self hideAllAlerts];
        [[LFBluetoothManager sharedManager] pairingCancelledForDeviceAtIndex:selectedIndex];
//        NSLog(@"%s", __func__);
        [tblDevices reloadData];
    }
    [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:msg withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
        if ([alert isKindOfClass:[UIAlertController class]]) {
            [alert dismissViewControllerAnimated:YES completion:nil];
            
        }
    }];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)hideAllAlerts {
    for (UIWindow* window in [UIApplication sharedApplication].windows) {
        NSArray* subviews = window.subviews;
        if ([subviews count] > 0) {
            for (UIView *tView in subviews) {
                if ([tView isKindOfClass:[UIAlertController class]]) {
                    UIAlertController *tAlert = (UIAlertController *)tView;
                    [tAlert dismissViewControllerAnimated:NO completion:nil];
                }
            }
        }
    }
}


#pragma mark Authentication Delegate
- (void)authenticationDoneWithStatus:(BOOL)isSuccess {
    if (isSuccess) {
        [self continueAfterPasswordAuthentication];
    }
}

@end
