//
//  LFNavigationBar.m
//  LittleFuse
//
//  Created by Kranthi on 27/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFNavigationBar.h"

@implementation LFNavigationBar

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)awakeFromNib
{
    UIImage *image = [UIImage imageNamed:@"header-logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//    [self.topItem setTitleView:imageView];
    self.topItem.titleView = imageView;

}

@end
