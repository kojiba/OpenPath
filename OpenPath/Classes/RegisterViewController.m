//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "RegisterViewController.h"
#import "Helper.h"
#import "UserData.h"


@interface RegisterViewController() <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
@end

@implementation RegisterViewController {

}

-(IBAction)backPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSString*)checkPassword {
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

-(IBAction)registerPressed {
    NSString *alert = [self checkPassword];
    if(!stringIsBlankOrNil(alert)) {
        ShowShortMessage(alert);
        return;
    }

    NSString *result = [[UserData sharedData] createUserWithLogin:self.loginTextField.text password:self.passwordTextField.text];
    if(stringIsBlankOrNil(result)) {
        ShowShortMessage(@"User succesfully created!");
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        ShowShortMessage(result);
    }
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