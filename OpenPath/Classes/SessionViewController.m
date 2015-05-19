//
// Created by Ilya Kucheruavyu on 5/19/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "SessionViewController.h"
#import "OpenPathProtocol.h"
#import "Listener.h"
#import "Helloer.h"
#import "Logger.h"
#import "UserData.h"
#import "OpenSSLServer.h"

@interface SessionViewController()
@property (strong, nonatomic) IBOutlet UITextField *keyTextField;
@property (strong, nonatomic) IBOutlet UIButton *generateButton;

@end

@implementation SessionViewController {

}
- (void)viewDidLoad {
    [super viewDidLoad];
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            char *settings[] = {nil, "9999", nil};
            openSSLServerStart(2, settings);
        });
    });

    NSData *keyData = [DEBUG_PRIVATE_HELLO_KEY dataUsingEncoding:NSUTF8StringEncoding];

    [[Listener sharedListener] setUpdateBlock:^void(char *data, ssize_t length, size_t packetsCounter, int error, char const *address) {
        if(error == 0
                && data != nil) {
            if(canDecryptHello((byte const *) data, (size_t) length, keyData.bytes, keyData.length)) {
                customLog(@"Received HELLO from %s", address);
            } else {
                // fixme processing session here
//                customLog(@"Received data: %s from %s, total received %lu!", data, address, packetsCounter);
            }
            deallocator(data);
        } else {
            customLog(@"Error receive packet!");
        }
    }];
}

#pragma mark Buttons

-(IBAction)logoutPressed {
    [[UserData sharedData] logout];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)logPressed {
    [self performSegueWithIdentifier:@"session-log.segue" sender:self];
}

-(IBAction)generatePressed {
    self.generateButton.enabled = NO;
    [[Listener sharedListener] startListen];

    char *temp = createHelloKey();
    NSString *key = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
    deallocator(temp);

    self.keyTextField.text = key;

    [[Helloer sharedHelloer] sendHelloWithDelay:1 repeat:10 key:key block:^BOOL(size_t packetsCounter, int error) {
        if(packetsCounter == 10) {
            self.generateButton.enabled = YES;
        }

        if(!error) {
            customLog(@"Send hello, total sent %lu!", packetsCounter);
        } else {
            customLog(@"Error send packet!");
        }
        return YES;
    }];
}

@end