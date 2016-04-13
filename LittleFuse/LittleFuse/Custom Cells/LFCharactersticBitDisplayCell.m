//
//  LFCharactersticBitDisplayCell.m
//  Littlefuse
//
//  Created by ram on 07/04/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFCharactersticBitDisplayCell.h"

@implementation LFCharactersticBitDisplayCell
- (void)updateValuesWithDict:(NSDictionary *)dict
{
    self.lblKey.text = [[dict allKeys] lastObject];
   // self.lblValue.text = [[dict allValues] lastObject];
    self.lblPrefix.text = [[[dict allKeys] lastObject] stringByReplacingOccurrencesOfString:@"Ø " withString:@""];
    if (self.lblPrefix.text.length > 3) {
        self.lblPrefix.text = @"Unb";
    }
}

- (void)updateCellWithDict:(NSDictionary *)dict withVal:(NSString *)val
{
    self.lblKey.text = dict[@"name"];
  //  self.lblValue.text = val;
    self.lblPrefix.text = dict[@"code"];
    
}

- (void)updateValues:(LFDisplay *)display
{
    self.lblKey.text = display.key;
 //   self.lblValue.text = display.value;
    [self.switchValue setOn:display.value.boolValue animated:NO];
    self.lblPrefix.text = display.code;
}

- (IBAction)changeSwitchValueAction:(id)sender {
    if (_toggleDelegate && [_toggleDelegate respondsToSelector:@selector(toggledTappedAtIndexPath:)]) {
        [_toggleDelegate toggledTappedAtIndexPath:self.path];
    }
}

@end
