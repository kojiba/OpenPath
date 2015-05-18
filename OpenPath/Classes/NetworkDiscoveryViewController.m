//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "NetworkDiscoveryViewController.h"
#import "Helloer.h"
#import "Listener.h"


@interface NetworkDiscoveryViewController()
@property (strong, nonatomic) IBOutlet UITextView *logView;
@property (strong, nonatomic) IBOutlet UIButton   *signInButton;
@end

@implementation NetworkDiscoveryViewController {

}

-(void)logString:(NSString*)string {
    self.logView.text = [self.logView.text stringByAppendingString:string];
}

-(IBAction)logoutClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[Listener sharedListener] setUpdateBlock:^void(char *data, ssize_t length, size_t packetsCounter, int error, char const *address) {
        if(error == 0) {
            [self logString: [NSString stringWithFormat:@"Received data: %s from %s, total received %lu!\n", data, address, packetsCounter]];
        } else {
            [self logString: [NSString stringWithFormat:@"Error receive packet!\n"]];
        }
    }];

    [[Listener sharedListener] startListen];

    [[Helloer sharedHelloer] sendHelloWithDelay:1 repeat:10 block:^BOOL(size_t packetsCounter, int error) {

        if(!error) {
            [self logString: [NSString stringWithFormat:@"Send hello, total sent %lu!\n", packetsCounter]];
        } else {
            [self logString: [NSString stringWithFormat:@"Error send packet!\n"]];
        }
        return YES;
    }];
}

@end