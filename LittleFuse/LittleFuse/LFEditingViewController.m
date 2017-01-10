//
//  LFEditingViewController.m
//  LittleFuse
//
//  Created by Kranthi on 29/01/16.
//  Copyright © 2016 XcubeLabs. All rights reserved.
//

#import "LFEditingViewController.h"
#import "LFInfoViewController.h"
#import "LFBluetoothManager.h"

@interface LFEditingViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
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
@property (weak, nonatomic) IBOutlet UIButton *infoBtn;

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
    _textFiled.delegate = self;
    _authenticationTextField.delegate = self;
    if ([_selectedText caseInsensitiveCompare:@"name"] == NSOrderedSame) {
        _lblrangeTxt.text = @"Note:Enter name between 1-12 characters";
        _infoBtn.hidden = YES;
        _lblSelectTxt.text = @"Enter a new name for the device.";
        _textFiled.keyboardType = UIKeyboardTypeDefault;
    }
    else if ([_selectedText caseInsensitiveCompare:@"password"] == NSOrderedSame) {
        _lblrangeTxt.text = @"Note:Enter password between 1-12 characters";
        _infoBtn.hidden = YES;
        _lblSelectTxt.text = @"Enter a new password for the device.";
        _textFiled.keyboardType = UIKeyboardTypeDefault;
    }
    else {
        _infoBtn.hidden = NO;
        _textFiled.keyboardType = UIKeyboardTypeDecimalPad;
    }
    if (CGRectGetHeight(self.view.frame) < 568.0f) {
        [self updateAccessoryViewForTextField:_textFiled];
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
    
    [self.textFiled resignFirstResponder];
    
    NSString *password;
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        password = self.authenticationTextField.text;
    }
    else {
        password = nil;
    }

    [self dismissViewControllerAnimated:NO completion:^{
        if (_delegate && [_delegate respondsToSelector:@selector(selectedValue: andPassword:)]) {
            NSString *newVal = self.textFiled.text;
            [_delegate selectedValue:newVal andPassword:password];
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
        if (_delegate && [_delegate respondsToSelector:@selector(toggleSelectedWithSuccess: andPassword:)]) {
            [_delegate toggleSelectedWithSuccess:NO andPassword:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
            return;
        }
    }
    [self dismissViewControllerAnimated:NO completion:nil];

}

- (IBAction)authenticationOkAction:(UIButton *)sender
{

    NSString *password;
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        password = self.authenticationTextField.text;
    }
    else {
        password = nil;
    }
    
        if (self.isFromDevicesList) { //This condition executes when user tries to connect to device in DevicesList Screen.
            if (_delegate && [_delegate respondsToSelector:@selector(authenticationDoneWithStatus: andPassword:)]) {
                [self dismissViewControllerAnimated:NO completion:nil];
                [_delegate authenticationDoneWithStatus:YES andPassword:password];
                return;
            }
        }
    
    
    if (!self.authenticationTextField.text.length) {
        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Please enter valid password" withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
                        if ([alert isKindOfClass:[UIAlertController class]]) {
                            [alert dismissViewControllerAnimated:NO completion:nil];
                        }
                    }];
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(checkPassword:)]) {
        [_delegate checkPassword:self.authenticationTextField.text];
    }
    
//    if (![self.authenticationTextField.text isEqualToString:@"littelfuse"])//TODO Implement code to verify the correctnes of entered password.
//    {
//        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Please enter valid password" withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
//            self.authenticationTextField.text = @"";
//            if ([alert isKindOfClass:[UIAlertController class]]) {
//                [alert dismissViewControllerAnimated:NO completion:nil];
//            }
//            
//        }];
//    } else {
//    
//        self.authenticationView.hidden = YES;
//        self.passwordView.hidden = NO;
//        
//        [self.textFiled becomeFirstResponder];
//        self.lblTitleheader.text = _selectedText;
//        if (_isAdvConfig) {
//            if (_delegate && [_delegate respondsToSelector:@selector(toggleSelectedWithSuccess: andPassword:)]) {
//                [_delegate toggleSelectedWithSuccess:YES andPassword:password];
//                [self dismissViewControllerAnimated:NO completion:nil];
//                return;
//            }
//        }
//        [self.view bringSubviewToFront:self.passwordView];
//    }
}


- (void)authDoneWithStatus:(BOOL)isSuccess {
    
    NSString *password;
    if (![[LFBluetoothManager sharedManager] isPasswordVerified]) {
        password = self.authenticationTextField.text;
    }
    else {
        password = nil;
    }
    
    if (isSuccess) {
        self.authenticationView.hidden = YES;
        self.passwordView.hidden = NO;
        
        [self.textFiled becomeFirstResponder];
        self.lblTitleheader.text = _selectedText;
        if (_isAdvConfig) {
            if (_delegate && [_delegate respondsToSelector:@selector(toggleSelectedWithSuccess: andPassword:)]) {
                [_delegate toggleSelectedWithSuccess:YES andPassword:password];
                [self dismissViewControllerAnimated:NO completion:nil];
                return;
            }
        }
        [self.view bringSubviewToFront:self.passwordView];
    }
    else {
        [self showAlertViewWithCancelButtonTitle:@"OK" withMessage:@"Please enter valid password" withTitle:APP_NAME otherButtons:nil clickedAtIndexWithBlock:^(id alert, NSInteger index) {
            self.authenticationTextField.text = @"";
            if ([alert isKindOfClass:[UIAlertController class]]) {
                [alert dismissViewControllerAnimated:NO completion:nil];
            }
            
        }];
    }
}

/**
 * This method displays the picker view.
 */

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

#pragma mark TextField Delegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
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

#pragma mark Keyboard Methods
- (void)updateAccessoryViewForTextField:(UITextField *)numberTextField {
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.frame), 50.0f)];
    numberToolbar.barStyle = UIBarStyleDefault;
    [numberToolbar setBackgroundColor:[UIColor lightGrayColor]];
    numberToolbar.items = @[
                            [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)]];
    [numberToolbar sizeToFit];
    numberTextField.inputAccessoryView = numberToolbar;
}

- (void)cancelNumberPad {
    [_textFiled resignFirstResponder];
}

-(void)doneWithNumberPad {
    [_textFiled resignFirstResponder];
}


@end
