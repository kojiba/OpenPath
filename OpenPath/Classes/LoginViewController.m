//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "LoginViewController.h"
#import "Helper.h"


@interface LoginViewController()
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@property (strong, nonatomic) IBOutlet UIButton    *signInButton;
@end

@implementation LoginViewController {

}

-(IBAction)signInPressed {
    if(!stringIsBlankOrNil(self.loginTextField.text)
            && !stringIsBlankOrNil(self.passwordTextField.text)) {

    } else {
        ShowShortMessage(@"Please, input login and password.");
    }
}

@end