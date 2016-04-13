//
//  LFEditingViewController.h
//  LittleFuse
//
//  Created by Kranthi on 29/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditingDelegate <NSObject>

- (void)selectedValue:(NSString *)txt;

@optional

- (void)toggleSelectedWithSuccess:(BOOL)isSuccess;

@end

@interface LFEditingViewController : LFBaseViewController

@property (nonatomic, assign) BOOL showPicker;
@property (nonatomic, assign) BOOL showSlider;

@property (nonatomic, weak) id<EditingDelegate> delegate;

@property (nonatomic, strong) NSString *selectedText;

@property (nonatomic, assign) BOOL showAuthentication;
@property (nonatomic,assign) BOOL isAdvConfig;


@end
