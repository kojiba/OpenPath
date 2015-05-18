//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "NetworkDiscoveryViewController.h"
#import "Helloer.h"


@interface NetworkDiscoveryViewController()
@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (strong, nonatomic) IBOutlet UIButton   *signInButton;
@end

@implementation NetworkDiscoveryViewController {

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[Helloer sharedHelloer] sendHelloWithDelay:1 repeat:10 logTextView:self.logView];
}

@end