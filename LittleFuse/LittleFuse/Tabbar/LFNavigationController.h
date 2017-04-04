//
//  LFNavigationController.h
//  LittleFuse
//
//  Created by Kranthi on 27/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol LFNavigationDelegate <NSObject>
@required
- (void)navigationBackAction;
@end
@interface LFNavigationController : UINavigationController
@property (weak, nonatomic) id<LFNavigationDelegate> navigationDelegate;
@end
