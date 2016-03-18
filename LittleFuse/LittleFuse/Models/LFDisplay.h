//
//  LFDisplay.h
//  LittleFuse
//
//  Created by Kranthi on 29/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFDisplay : NSObject

@property (strong, nonatomic) NSString *code;
@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) NSString *value;
@property (strong, nonatomic) NSString *units;

- (id)initWithKey:(NSString *)key Value:(NSString *)val Code:(NSString *)code;
@end
