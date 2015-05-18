//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "RegisterViewController.h"
#import "Helper.h"
#import "UserData.h"


@interface RegisterViewController()
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@end

@implementation RegisterViewController {

}

-(IBAction)registerPressed {
    if(!stringIsBlankOrNil(self.loginTextField.text)
            && !stringIsBlankOrNil(self.passwordTextField.text)) {

        if([self.loginTextField.text isEqualToString:self.passwordTextField.text]) {
            ShowShortMessage(@"Login and password cannot be equals.");
        } else {
            if(self.loginTextField.text.length > 3
                    && self.passwordTextField.text.length > 3) {
                if ([[UserData sharedData] createUserWithLogin:self.loginTextField.text password:self.passwordTextField.text]) {

                    ShowShortMessage(@"User succesfully created!");
                    [self.navigationController popViewControllerAnimated:YES];

                } else {
                    ShowShortMessage(@"User already exists!");
                }
            } else {
                ShowShortMessage(@"Name and password must be at least 4 symbols length.");
            }
        }
    } else {
        ShowShortMessage(@"Please, input login and password.");
    }
}

@end