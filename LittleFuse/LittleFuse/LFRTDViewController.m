//
//  LFRTDViewController.m
//  Littlefuse
//
//  Created by Kranthi on 17/03/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFRTDViewController.h"

@interface LFRTDViewController ()

@end

@implementation LFRTDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma  mark - Base Controller Methods
-(void)navigationBackAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
