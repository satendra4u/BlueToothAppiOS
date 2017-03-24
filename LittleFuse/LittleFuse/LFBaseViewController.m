
//
//  LFBaseViewController.m
//  Littlefuse
//
//  Created by Kranthi on 01/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFBaseViewController.h"


#define INDICATOR_WIDTH_HT  37.0

typedef void(^LFAlertBlock)(id alert, NSInteger index);

@interface LFBaseViewController ()
{
    LFAlertBlock alertBlock;
}
@end

@implementation LFBaseViewController
@synthesize indicatorView, blankView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *image = [UIImage imageNamed:@"header-logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    self.navigationItem.titleView = imageView;
    
    
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


- (void)showAlertViewWithCancelButtonTitle:(NSString *)cancelTitle
                               withMessage:(NSString *)message
                                 withTitle:(NSString *)AlertTitle
                              otherButtons:(NSArray *)otherButtons
                   clickedAtIndexWithBlock:(void(^)(id alert, NSInteger index))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        alertBlock = block;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 9
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AlertTitle message:message delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
        
        for (NSString *strings in otherButtons) {
            [alert addButtonWithTitle:strings];
        }
        [alert show];
#endif
        
        UIAlertController *alertcontroller = [UIAlertController alertControllerWithTitle:AlertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        
        [alertcontroller addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            alertBlock (alertcontroller, 0);
            
        }]];
        for (NSString *button in otherButtons) {
            [alertcontroller addAction:[UIAlertAction actionWithTitle:button style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                alertBlock (alertcontroller, [otherButtons indexOfObject:button]+1);
                
            }]];
        }
        [self presentViewController:alertcontroller animated:YES completion:nil];
        
    });
    
}
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 9
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertBlock) {
        alertBlock(alertView, buttonIndex);
    }
}
#endif


#pragma mark -
- (void)showIndicatorOn:(UIView*)superView withText:(NSString *)msg
{
    CGRect viewFrame = superView.bounds;
    indicatorView = [[UIView alloc] initWithFrame:self.view.bounds];
    UIView *aView = [[UIView alloc] initWithFrame:CGRectMake(10, ((CGRectGetHeight(viewFrame) - 150) / 2.0) , CGRectGetWidth(viewFrame)-20, 100)];
    aView.backgroundColor = [UIColor whiteColor];
    [indicatorView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]];
    [superView addSubview:indicatorView];
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, CGRectGetWidth(viewFrame), 50)];
    aLabel.text = msg;
    aLabel.font = [UIFont fontWithName:AERIAL_BOLD size:14.0];
    aLabel.textAlignment = NSTextAlignmentCenter;
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect indicatorFrame = CGRectMake(((CGRectGetWidth(aView.frame) - INDICATOR_WIDTH_HT) / 2.0), 13, INDICATOR_WIDTH_HT, INDICATOR_WIDTH_HT);
    activityIndicatorView.color = [UIColor lightGrayColor];
    [activityIndicatorView setFrame:indicatorFrame];
    [aView addSubview:activityIndicatorView];
    [activityIndicatorView startAnimating];
    [aView addSubview:aLabel];
    aView.layer.cornerRadius = 5.0;
    [indicatorView addSubview:aView];
    [superView bringSubviewToFront:indicatorView];
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}
- (void)removeIndicator
{
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    [indicatorView removeFromSuperview];
    indicatorView = nil;
}


@end
