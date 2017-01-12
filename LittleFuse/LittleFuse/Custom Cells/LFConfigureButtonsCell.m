//
//  LFConfigureButtonsCell.m
//  Littlefuse
//
//  Created by Kranthi on 17/03/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFConfigureButtonsCell.h"

@implementation LFConfigureButtonsCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    _btnCommunication.titleLabel.numberOfLines = 0;
    [_btnCommunication.titleLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
