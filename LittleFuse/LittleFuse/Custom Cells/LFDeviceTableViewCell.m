//
//  DeviceTableViewCell.m
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFDeviceTableViewCell.h"
#import "LFConstants.h"

@interface LFDeviceTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *lblDeviceName;
@property (weak, nonatomic) IBOutlet UILabel *lblRange;
@property (weak, nonatomic) IBOutlet UILabel *lblPairedStatus;
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UIImageView *imgRange;
@property (weak, nonatomic) IBOutlet UILabel *lblDeviceLocalName;


@end
@implementation LFDeviceTableViewCell



- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateCellWithDict:(LFPeripheral *)peripheral
{
    self.lblRange.text = [NSString stringWithFormat:@"%@", peripheral.rssi];//dBm
    
//    int rssiPercent = (int) (100.0f * (127.0f + peripheral.rssi.integerValue) / (127.0f + 20.0f));
    
  //  DLog(@"rssiPercent %d", rssiPercent);
    self.lblDeviceName.text = [NSString stringWithFormat:@"MAC XXXX%@", [peripheral.name substringFromIndex:peripheral.name.length-4]];
    self.lblDeviceLocalName.text = [peripheral.name substringToIndex:peripheral.name.length-4];
    self.lblPairedStatus.text = peripheral.isPaired ? PAIRED :  UNPAIRED;
    if (peripheral.isPaired) {
        if (peripheral.isConfigured) {
            self.lblPairedStatus.text = CONFIGURED;
            self.bgView.backgroundColor = GREEN_COLOR;
        } else {
            self.bgView.backgroundColor = RED_COLOR;
            self.lblPairedStatus.text = NOT_CONFIGURED;
        }
    }
    else {
        self.bgView.backgroundColor = BLUE_COLOR;
        self.lblPairedStatus.text = UNPAIRED;
//        if (peripheral.isConfigured) {
//            self.lblPairedStatus.text = CONFIGURED;
//            self.bgView.backgroundColor = GREEN_COLOR;
//        } else {
//            self.bgView.backgroundColor = RED_COLOR;
//            self.lblPairedStatus.text = NOT_CONFIGURED;
//        }
    }
    
}


@end
