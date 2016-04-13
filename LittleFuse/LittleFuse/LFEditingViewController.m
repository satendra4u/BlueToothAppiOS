//
//  LFEditingViewController.m
//  LittleFuse
//
//  Created by Kranthi on 29/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFEditingViewController.h"
#import "LFInfoViewController.h"

@interface LFEditingViewController () <UIPickerViewDataSource, UIPickerViewDelegate>
{
    NSArray *pickerArr;
    UIPickerView *categoryPickerView;
    UIToolbar *pickerToolbar;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewCenterYConstraint;
@property (weak, nonatomic) IBOutlet UILabel *sliderSelectedTxt;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UIView *authenticationView;

@property (weak, nonatomic) IBOutlet UILabel *lblTitleheader;
@property (weak, nonatomic) IBOutlet UILabel *lblSelectTxt;
@property (weak, nonatomic) IBOutlet UITextField *textFiled;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UIButton *btnSave;
@property (weak, nonatomic) IBOutlet UILabel *lblrangeTxt;
@property (weak, nonatomic) IBOutlet UILabel *lblMin;
@property (weak, nonatomic) IBOutlet UILabel *lblMax;
@property (weak, nonatomic) IBOutlet UITextField *authenticationTextField;

@property (weak, nonatomic) IBOutlet UIView *btnsView;

@property (weak, nonatomic) IBOutlet UISlider *slider;

- (IBAction)sliderValueChange:(UISlider *)sender;

- (IBAction)cancelAction:(UIButton *)sender;

- (IBAction)saveAction:(UIButton *)sender;

- (IBAction)infoAction:(UIButton *)sender;

- (IBAction)authenticationCancel:(UIButton *)sender;

- (IBAction)authenticationOkAction:(UIButton *)sender;
@end

@implementation LFEditingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    if (_showAuthentication) {
        self.authenticationView.hidden = NO;
        self.passwordView.hidden = YES;
        [self.view bringSubviewToFront:self.authenticationView];
        [self.authenticationTextField becomeFirstResponder];
    } else {
        self.authenticationView.hidden = YES;
        self.passwordView.hidden = NO;
        pickerArr = @[@"1", @"5", @"10", @"20", @"50", @"100", @"125", @"200"];
        
        [self.textFiled becomeFirstResponder];
        self.lblTitleheader.text = _selectedText;
        [self.view bringSubviewToFront:self.passwordView];

    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationItem.title = @"";
    self.navigationController.navigationBarHidden = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sliderValueChange:(UISlider *)sender
{
    self.sliderSelectedTxt.text = [NSString stringWithFormat:@"%d", (int)sender.value];

}

- (IBAction)cancelAction:(UIButton *)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)saveAction:(UIButton *)sender
{
    
    [self dismissViewControllerAnimated:NO completion:^{
        if (_delegate && [_delegate respondsToSelector:@selector(selectedValue:)]) {
            [_delegate selectedValue:self.textFiled.text];
        }
    }];

}

- (IBAction)infoAction:(UIButton *)sender
{
    LFInfoViewController *info = (LFInfoViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"LFInfoViewControllerID"];
    [self.navigationController pushViewController:info animated:YES];
}

- (IBAction)authenticationCancel:(UIButton *)sender
{
    if (_isAdvConfig) {
        if (_delegate && [_delegate respondsToSelector:@selector(toggleSelectedWithSuccess:)]) {
            [_delegate toggleSelectedWithSuccess:NO];
            [self dismissViewControllerAnimated:NO completion:nil];
            return;
        }
    }
    [self dismissViewControllerAnimated:NO completion:nil];

}

- (IBAction)authenticationOkAction:(UIButton *)sender
{
    if (![self.authenticationTextField.text isEqualToString:@"admin"])
    {
        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Please enter valid password" withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            self.authenticationTextField.text = @"";
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
        
        }];
    } else {
        self.authenticationView.hidden = YES;
        self.passwordView.hidden = NO;
        
        [self.textFiled becomeFirstResponder];
        self.lblTitleheader.text = _selectedText;
        if (_isAdvConfig) {
            if (_delegate && [_delegate respondsToSelector:@selector(toggleSelectedWithSuccess:)]) {
                [_delegate toggleSelectedWithSuccess:YES];
                [self dismissViewControllerAnimated:NO completion:nil];
                return;
            }
        }
        [self.view bringSubviewToFront:self.passwordView];



    }
}

- (void)displayPickerrView
{
    
    categoryPickerView = [[UIPickerView alloc] init];
    
    [categoryPickerView setDataSource: self];
    [categoryPickerView setDelegate: self];
    categoryPickerView.showsSelectionIndicator = YES;
    
    pickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    pickerToolbar.barStyle = UIBarStyleDefault;
    [pickerToolbar sizeToFit];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(doneButtonPressed)];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    
    [pickerToolbar setItems:@[cancelBtn, flexSpace, doneBtn] animated:YES];
    
    self.textFiled.inputView = categoryPickerView;
    self.textFiled.inputAccessoryView = pickerToolbar;
    
}

-(void)doneButtonPressed
{
    [self saveAction:self.btnSave];

}

-(void)cancelButtonPressed
{
    [self cancelAction:self.btnCancel];

}

#pragma mark UIPickerDelegate & Data Source
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.textFiled.text = pickerArr[row];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [pickerArr count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return  pickerArr[row];
}



@end
