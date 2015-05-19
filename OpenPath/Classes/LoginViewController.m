//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "LoginViewController.h"
#import "Helper.h"
#import "UserData.h"
#import "RegisterViewController.h"

#define NOVALIDATION


@interface LoginViewController()
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIButton    *signInButton;
@end

@implementation LoginViewController {

}

-(IBAction)signInPressed {
    #ifndef NOVALIDATION
    if(!stringIsBlankOrNil(self.loginTextField.text)
            && !stringIsBlankOrNil(self.passwordTextField.text)) {

        if([self.loginTextField.text isEqualToString:self.passwordTextField.text]) {
            ShowShortMessage(@"Login and password cannot be equals.");
        } else {
    #endif
            if ([[UserData sharedData] loginWithName:self.loginTextField.text password:self.passwordTextField.text]) {
                [self gotoAccountDetails];
            }
    #ifndef NOVALIDATION
            else {
                ShowShortMessage(@"User not exist");
            }
        }
    } else {
        ShowShortMessage(@"Please, input login and password.");
    }
    #endif
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

@end