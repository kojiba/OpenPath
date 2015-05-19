//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "LogViewController.h"
#import "Helloer.h"
#import "Listener.h"
#import "OpenPathProtocol.h"
#import "Logger.h"


@interface LogViewController ()
@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (strong, nonatomic) IBOutlet UIButton   *signInButton;
@end

@implementation LogViewController {

}

-(void)logString:(NSString*)string {
    self.logView.text = [self.logView.text stringByAppendingString:string];
}

-(IBAction)logoutClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logView.text = [[Logger sharedLogger] getFullLog];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

@end