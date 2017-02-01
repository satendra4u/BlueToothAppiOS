 //
//  LFInfoViewController.m
//  Littlefuse
//
//  Created by Kranthi on 25/02/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFInfoViewController.h"

@interface LFInfoViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation LFInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIImage *image = [UIImage imageNamed:@"header-logo"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    self.navigationController.navigationBar.topItem.titleView = imageView;

    [self.activityIndicator startAnimating];
    NSString *urlString = _isAdvConfig ? @"http://www.littelfuse.com/mp8000advanced" : @"http://www.littelfuse.com/mp8000basic";
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
   // [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.littelfuse.com/products/protection-relays-and-controls/protection-relays/motor-protection"]]]; //@"http://www.littelfuse.com/products/protection-relays-and-controls/protection-relays/motor-protection"
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    [self.activityIndicator stopAnimating];
}

@end
