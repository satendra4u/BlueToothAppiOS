//
//  LFFaultData.h
//  Littlefuse
//
//  Created by Kranthi on 12/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFFaultData : NSObject

@property (nonatomic, strong) NSData *voltage;
@property (nonatomic, strong) NSData *current;
@property (nonatomic, strong) NSData *power;
@property (nonatomic, strong) NSData *other;
@property (nonatomic, strong) NSDate *date;

- (id)initWithManagedObject:(NSManagedObject *)obj;


@end
