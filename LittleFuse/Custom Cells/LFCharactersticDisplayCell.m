//
//  CharactersticDisplayCell.m
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFCharactersticDisplayCell.h"

@implementation LFCharactersticDisplayCell

- (void)updateValuesWithDict:(NSDictionary *)dict
{
    self.lblKey.text = [[dict allKeys] lastObject];
    self.lblValue.text = [[dict allValues] lastObject];
    self.lblprefix.text = [[[dict allKeys] lastObject] stringByReplacingOccurrencesOfString:@"Ø " withString:@""];
    if (self.lblprefix.text.length > 3) {
        self.lblprefix.text = @"Unb";
    }
}

- (void)updateCellWithDict:(NSDictionary *)dict withVal:(NSString *)val
{
    self.lblKey.text = dict[@"name"];
    self.lblValue.text = val;
    self.lblprefix.text = dict[@"code"];

}

- (void)updateValues:(LFDisplay *)display
{
    self.lblKey.text = display.key;
    self.lblValue.text = display.value;
    self.lblprefix.text = display.code;
}


@end
