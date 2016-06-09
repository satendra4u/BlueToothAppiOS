//
//  LFCharactersticBitDisplayCell.h
//  Littlefuse
//
//  Created by ram on 07/04/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFDisplay.h"

@protocol ToggleTappedProtocol <NSObject>

/**
 * This method is called when Feature Enable/Disable or Hardware Configuration fields are toggled.
 * @param: indexPath: The indexpath for the item tapped.
 */
- (void)toggledTappedAtIndexPath:(NSIndexPath *) indexPath;

@end
@interface LFCharactersticBitDisplayCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblPrefix;
@property (weak, nonatomic) IBOutlet UILabel *lblKey;
@property (weak, nonatomic) IBOutlet UISwitch *switchValue;
@property (nonatomic,strong) NSIndexPath *path;
@property (weak, nonatomic) id <ToggleTappedProtocol> toggleDelegate;


- (void)updateValuesWithDict:(NSDictionary *)dict;

- (void)updateCellWithDict:(NSDictionary *)dict withVal:(NSString *)val;

- (void)updateValues:(LFDisplay *)display;

- (IBAction)changeSwitchValueAction:(id)sender;


@end
