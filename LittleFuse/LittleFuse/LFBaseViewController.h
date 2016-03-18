//
//  LFBaseViewController.h
//  Littlefuse
//
//  Created by Kranthi on 01/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFBaseViewController : UIViewController

@property (nonatomic,strong)UIView *indicatorView;
@property (nonatomic, strong) UIView *blankView;

- (void)showAlertViewWithCancelButtonTitle:(NSString *) cancelTitle
                               withMessage:(NSString *)message
                                 withTitle:(NSString *)AlertTitle
                              otherButtons:(NSArray *)otherButtons
                   clickedAtIndexWithBlock:(void(^)(id alert, NSInteger index))block;


- (void)showIndicatorOn:(UIView*)superView withText:(NSString *)msg;
- (void)removeIndicator;


@end
