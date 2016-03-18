//
//  LFFaultsDetailsController.h
//  Littlefuse
//
//  Created by Kranthi on 08/03/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFBaseViewController.h"
#import "LFFaultData.h"

@interface LFFaultsDetailsController : LFBaseViewController

@property (strong, nonatomic) LFFaultData *faultData;
@property (strong, nonatomic) NSString *errorType;
@property (strong, nonatomic) NSString *errorDate;


@end
