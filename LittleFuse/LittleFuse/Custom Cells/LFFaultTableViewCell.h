//
//  LFFaultTableViewCell.h
//  Littlefuse
//
//  Created by Kranthi on 10/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFFaultTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lblFaultDescrption;
@property (weak, nonatomic) IBOutlet UILabel *lblFaultDate;
@property (weak, nonatomic) IBOutlet UILabel *lblPrefix;

- (void)updateDetailsWithDict:(NSDictionary *)dict;

@end
