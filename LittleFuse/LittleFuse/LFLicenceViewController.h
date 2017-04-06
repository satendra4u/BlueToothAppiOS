//
//  LFLicenceViewController.h
//  Littlefuse
//
//  Created by SivaRamaKrishna on 05/04/17.
//  Copyright © 2017 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, LFLicenceButtonType) {
    LFLicenceButtonTypeAgree= 0,
    LFLicenceButtonTypeCancel
};

typedef  void (^LFLicenceAgreementCompletionHandler)(LFLicenceButtonType selectedButton);
@interface LFLicenceViewController : LFBaseViewController
//- (void)configureLicenceWithAgreementCompletionHandler:(LFLicenceAgreementCompletionHandler)licenceAgreementCompletionBlock;
@end
