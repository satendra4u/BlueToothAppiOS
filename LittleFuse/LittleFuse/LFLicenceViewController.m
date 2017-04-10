//
//  LFLicenceViewController.m
//  Littlefuse
//
//  Created by SivaRamaKrishna on 05/04/17.
//  Copyright © 2017 XcubeLabs. All rights reserved.
//

#import "LFLicenceViewController.h"
#import "LFNavigationController.h"

@interface LFLicenceViewController ()
{
    //LFLicenceAgreementCompletionHandler licenceAgreementCompletionHandler;
}
@property (weak, nonatomic) IBOutlet UIWebView *licenceWebView;
@end

@implementation LFLicenceViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.leftBarButtonItems = nil;

    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"Terms&Conditions" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [_licenceWebView loadHTMLString:htmlString baseURL: [[NSBundle mainBundle] bundleURL]];
    _licenceWebView.backgroundColor = [UIColor clearColor];
}

/*- (void)configureLicenceWithAgreementCompletionHandler:(LFLicenceAgreementCompletionHandler)licenceAgreementCompletionBlock
{
    licenceAgreementCompletionHandler = licenceAgreementCompletionBlock;
}*/
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"Error : %@", error);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Action Methods

- (IBAction)agreeAction:(id)sender {
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:LicenceAgreedKey ];
    [[NSUserDefaults standardUserDefaults] synchronize];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LFNavigationController *deviceListNavigationController = [storyboard instantiateViewControllerWithIdentifier:@"DevicesListNavigationControllerSID"]; //
    [[UIApplication sharedApplication].keyWindow setRootViewController:deviceListNavigationController];

}
- (IBAction)cancelAction:(id)sender {
   // licenceAgreementCompletionHandler(LFLicenceButtonTypeCancel);
    exit(0);
}


@end
