//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "LoginViewController.h"
#import "Helper.h"
#import "UserData.h"
#import "RegisterViewController.h"
#import "IndicatorView.h"

@interface LoginViewController()
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIButton    *signInButton;
@end

@implementation LoginViewController {

}

#ifdef DEBUG
- (void)viewDidLoad {
    [super viewDidLoad];
    self.loginTextField.text = @"login";
    self.passwordTextField.text = @"12345";
}
#endif

-(NSString*)check {
    if(stringIsBlankOrNil(self.loginTextField.text)
            || stringIsBlankOrNil(self.passwordTextField.text)) {
        return @"Plese, input login and password";
    }

    if([self.loginTextField.text isEqualToString:self.passwordTextField.text]) {
        return @"Login and password cannot be equals";
    }

    if(self.passwordTextField.text.length < PASSWORD_MIN_LENGTH) {
        return [NSString stringWithFormat:@"Password cannot be less than %d", PASSWORD_MIN_LENGTH];
    }

    if([self.passwordTextField.text.uppercaseString isEqualToString:@"PASSWORD"]) {
        return @"Password cannot be equal to \"password\"";
    }
    return nil;
}

-(IBAction)signInPressed {
    NSString *alert = [self check];

    if(!stringIsBlankOrNil(alert)) {
        ShowShortMessage(alert);
        return;
    }

    [self.view showLoading];
    self.signInButton.enabled = NO;

    inBackGround ^{
        sleep(1);
        BOOL result = [[UserData sharedData] loginWithName:self.loginTextField.text password:self.passwordTextField.text];

        inMainThread ^{

            self.passwordTextField.text = @"";
            self.signInButton.enabled = YES;
            [self.view hideLoading];

            if (result) {
                self.loginTextField.text = @"";
                [self gotoAccountDetails];
            }
        });
    });
}

-(IBAction)registerPressed {
    [self performSegueWithIdentifier:@"login-creation.segue" sender:self];
}

-(void)gotoAccountDetails {
    [self performSegueWithIdentifier:@"login-session.segue" sender:self];
}

#pragma mark Navigation

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
}

#pragma mark TextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    UIView *view = [self.view viewWithTag:textField.tag + 1];
    if(view.canBecomeFirstResponder) {
        [view becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

@end