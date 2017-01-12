//
//  LFFaultTableViewCell.m
//  Littlefuse
//
//  Created by Kranthi on 10/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFFaultTableViewCell.h"

@interface LFFaultTableViewCell ()
@end

@implementation LFFaultTableViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)updateDetailsWithDict:(NSDictionary *)dict
{
    NSString *fualtDate = dict[FAULT_DATE];
    NSString *date = [fualtDate substringToIndex:fualtDate.length-9];
    NSString *time = [fualtDate substringFromIndex:fualtDate.length-9];
    fualtDate = [NSString stringWithFormat:@"%@\n%@", date, time];
    self.lblFaultDate.text = fualtDate;
    self.lblFaultDescrption.text = dict[FAULT_ERROR];
    self.lblPrefix.text = dict[FAULT_CODE];
}




@end
