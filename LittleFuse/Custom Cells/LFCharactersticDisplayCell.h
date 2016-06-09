//
//  CharactersticDisplayCell.h
//  LittleFuse
//
//  Created by Kranthi on 21/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFDisplay.h"

@interface LFCharactersticDisplayCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lblprefix;
@property (weak, nonatomic) IBOutlet UILabel *lblKey;
@property (weak, nonatomic) IBOutlet UILabel *lblValue;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *prefixLblLeadingConstraint;


- (void)updateValuesWithDict:(NSDictionary *)dict;

- (void)updateCellWithDict:(NSDictionary *)dict withVal:(NSString *)val;

- (void)updateValues:(LFDisplay *)display;

@end
