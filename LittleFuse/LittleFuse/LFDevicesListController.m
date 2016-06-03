//
//  ViewController.m
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFDevicesListController.h"
#import "LFBluetoothManager.h"
#import "LFDeviceTableViewCell.h"
#import "LFTabbarController.h"
#import "LFConstants.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "UIImage+LFImage.h"
#import <CoreBluetooth/CoreBluetooth.h>


#define kDeviceCellID  @"DeviceCellID"

@interface LFDevicesListController () <BlutoothSharedDataDelegate, UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray *peripheralsList;
    NSMutableArray *charactersticsList;
    __weak IBOutlet UITableView *tblDevices;
    __weak IBOutlet UILabel *lblScanning;
    NSInteger selectedIndex;
    NSInteger refreshTimeInterval;
    __weak IBOutlet UILabel *lblVersion;
    BOOL isPopupOpened;
    BOOL isInitialLaunch;
    BOOL canRefresh;
    BOOL isDeviceSelected;
    BOOL isScanDataFound;
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
}

- (void)appEnteredBackground {
    [[LFBluetoothManager  sharedManager] disconnectDevice];
}

- (void)becameActive {
    [self reloadDevicesList];
}

- (void)willBecomeInActive {
    canRefresh = YES;
}

- (void)peripheralConnected {
    isPopupOpened = YES;
}

- (void)peripheralDisconnnected {
    isPopupOpened = NO;
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    isPopupOpened = NO;
    isDeviceSelected = NO;
    self.navigationItem.title = @"";
    [[LFBluetoothManager sharedManager] setDelegate:self];
    [[LFBluetoothManager sharedManager] setDisplayCharacterstics:NO];
    if ([[LFBluetoothManager sharedManager] getDevicesList]) {
        peripheralsList = [[LFBluetoothManager sharedManager] getDevicesList];
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
    [super viewDidAppear:YES];
//    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
//    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
//    if (batteryLevel > 0.20) {
//        refreshTimeInterval = 5;
//    }
//    else {
//        refreshTimeInterval = 600;
//    }
//    [self reloadDevicesList];
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

- (void)showScannedDevices:(NSMutableArray *)devicesArray
{
    if (devicesArray.count) {
        isScanDataFound = YES;
    }
    peripheralsList = [devicesArray mutableCopy];
    [tblDevices reloadData];
}

- (void)showCharacterstics:(NSMutableArray *)charactersticsArray
{
    charactersticsList = charactersticsArray;
    CBCharacteristic *charactestic = (CBCharacteristic *)[charactersticsArray firstObject];
    [[LFBluetoothManager sharedManager] connectToCharactertics:charactestic];
    
}

#pragma mark - Private methods -

- (IBAction)scanAction:(id)sender
{
    isScanDataFound = NO;
    [self performSelector:@selector(verifyDeviceCount) withObject:nil afterDelay:3];
    [[LFBluetoothManager sharedManager] disconnectDevice];
}

- (void)verifyDeviceCount {
    if (!isScanDataFound) {
        [peripheralsList removeAllObjects];
        [tblDevices reloadData];
    }
}

- (void)navigateToDislay:(NSNotification *)notification
{
    if (!isDeviceSelected) {
        return;
    }
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

- (void)showAlertWithText:(NSString *)msg
{
    if ([msg isEqualToString:@"Encryption is insufficient."]) {
        isPopupOpened = NO;
        [self hideAllAlerts];
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

@end
