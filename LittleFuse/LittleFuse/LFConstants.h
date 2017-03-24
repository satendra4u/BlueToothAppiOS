//
//  LFConstants.h
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#ifndef LFConstants_h
#define LFConstants_h


#define APP_NAME @"MP8000"

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] >>>>" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif


#define kPeripheral @"peripheral"
#define kRssi @"RSSI"
#define kName @"name"
#define kIdentifier @"identifier"
#define kConfigStatus @"configStatus"

#define CHARACTER_DISPLAY_CELL_ID @"CharacterDisplayCellID"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define VOLTAGE_CHARACTERSTICS          @"F001"
#define CURRENT_CHARACTERSTICS          @"F002"
#define POWER_CHARACTERSTICS            @"F003"
#define STATUS_CHARACTERSTICS           @"F101"
#define CONFIGURATION_CHARACTERSTICS    @"F201"
#define FAULT_CHARACTERSTICS            @"F301"
#define VOLATAGE_FAULT_CHARACTERSTIC    @"F302"
#define CURRENT_FAULT_CHARACTERSTIC     @"F303"
#define POWER_FAULT_CHARACTERSTIC       @"F304"
#define OTHER_FAULT_CHARACTERSTIC       @"F305"
#define DEVICE_SERIAL_NUMBER_CHARACTERISTIC @"2A25"

#define DISPLAY_TABBAR                  @"DisplayScreen"
#define SAVE_CONFIG_VALUES              @"SaveValuesToConfig"
#define VOLTAGE_NOTIFICATION            @"VoltageNotification"
#define CURRENT_NOTIFICATION            @"CurrentNotification"
#define EQUIPMENT_NOTIFICATION          @"equipmentNotification"
#define POWER_NOTIFICATION              @"PowerNotification"
#define REAL_TIME_CONFIGURATION         @"RealTimeConfigNotification"
#define CONFIGURATION_NOTIFICATION      @"ConfigureServices"

#define FAULT_NOTIFICATION              @"FalutServices"
#define VOLATAGE_FAULT_NOTIFICATION     @"FalutVoltage"
#define CURRENT_FAULT_NOTIFICATION      @"FalutCurrent"
#define POWER_FAULT_NOTIFICATION        @"FalutPower"

#define FAULT_VOLTAGE_DETAILS           @"CurrentFaults"
#define FAULT_CURRENT_DETAILS           @"PowerFaults"
#define OTHER_FAULTS                    @"otherFaults"
#define FAULT_POWER_DETAILS             @"VoltageFaults"
#define FAULT_DATE                      @"ErrorDate"
#define FAULT_ERROR                     @"ErrorDesc"
#define FAULT_DETAILS                   @"faultDetails"
#define FAULT_CODE                      @"faultCode"

#define GREEN_COLOR                      [UIColor colorWithRed:98/255.0 green:192.0/255 blue:85.0/255 alpha:1.0]
#define RED_COLOR                        [UIColor colorWithRed:245/255.0 green:80.0/255 blue:80.0/255 alpha:1.0]
#define BLUE_COLOR                       [UIColor colorWithRed:75.0/255.0 green:147.0/255 blue:207.0/255 alpha:1.0]

#define APP_THEME_COLOR                       [UIColor colorWithRed:0.0 green:107.0/255 blue:58.0/255 alpha:1.0]

#define AERIAL_REGULAR                    @"Arial"
#define AERIAL_BOLD                       @"Arial-BoldMT"

#define CONFIGURED                          @"CONFIGURED"
#define NOT_CONFIGURED                     @"NOT CONFIGURED"
#define UNPAIRED                           @"UNPAIRED"
#define PAIRED                              @"PAIRED"

#define PERIPHERAL_ENTITY                   @"PeripheralEntity"
#define FAULT_ENTITY                        @"FaultDataEntity"

#define PERIPHERAL_FAULT_RELATION           @"faultDataRelation"

#pragma mark Core Data
#define attiribute_name         @"name"
#define attiribute_rssi         @"rssi"
#define attiribute_identifier   @"identifier"
#define attiribute_config       @"configurated"
#define attiribute_paired       @"paired"

#define attribute_date      @"date"
#define attribute_current   @"current"
#define attribute_power     @"power"
#define attribute_voltage   @"voltage"
#define attribute_other     @"other"

#define PeripheralDidDisconnect @"PeripheralDidDisconnectNotification"
#define PeripheralDidConnect    @"PeripheralDidConnectNotification"
#define LittleFuseNotificationCenter [NSNotificationCenter defaultCenter]

// ------------------------------------------------------------------------------------------
//                              ***** Alert titles *****
// ------------------------------------------------------------------------------------------

#pragma mark Alert Titles

#define  kApp_Name  @"Littelfuse"
#define  kConfigure @"CONFIGURE"
#define  kFriendly_deviceName_title  @"Friendly Device Name"
#define  kAuthentication_title @"Authentication"
#define  kResetPassword_title @"Password Reset"


// ------------------------------------------------------------------------------------------
//                              ***** Alert body constants *****
// ------------------------------------------------------------------------------------------


#pragma mark Alert Body

#define  kDevice_Disconnected @"Device Disconnected"
#define  kWriting_Failed @"Writing data failed."
#define  kEnter_Correct_Password @"Please enter correct password and try again."
#define  kSave_Success @"Data saved successfully"
#define  kProblem_Saving @"There is a problem saving data."
#define  kNot_Configured @"This MP8000 has not yet configured. Would you like to configure this device now?"
#define  kEnter_Valid_Password @"Please enter password"
#define  kPermision_Error @"Read or Write Permission Error"
#define  kOutOf_Range @"Out of Range Error"
#define  kPassword_Changed @"Password Changed Successfully"
#define  kAuthenticationFailed @"User Authorization Failed"
#define  kUpdateFailed @"Update Failed due to Timeout"
#define  kResetRelay_motorStarts @"Caution:Motor May Start!"
#define  kReset_success @"Device reset successfully"
#define  kFriendly_deviceName_message  @"Please enter the friendly device name to change the device name"
#define  kAuthentication_message  @"Please enter the password to edit the configuration settings"
#define  kResetPassword_message  @"Please enter reset code"



// ------------------------------------------------------------------------------------------
//                              ***** Alert button titles *****
// ------------------------------------------------------------------------------------------

#pragma mark Alert Button Titles

#define kOK  @"OK"
#define kNo @"NO"
#define kCancel @"CANCEL"
#define kContinue @"CONTINUE"





#endif /* LFConstants_h */
