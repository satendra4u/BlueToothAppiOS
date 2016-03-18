//
//  LFCommunicationSettingsController.m
//  Littlefuse
//
//  Created by Kranthi on 17/03/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFCommunicationSettingsController.h"

@interface LFCommunicationSettingsController ()

@end

@implementation LFCommunicationSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellId = [NSString stringWithFormat:@"cell %d", (int)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    return cell;
}


@end
