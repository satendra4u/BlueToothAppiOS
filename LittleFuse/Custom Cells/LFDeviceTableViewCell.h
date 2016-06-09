//
//  DeviceTableViewCell.h
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFPeripheral.h"

@interface LFDeviceTableViewCell : UITableViewCell


- (void)updateCellWithDict:(LFPeripheral *)peripheral;
@end
