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
#import "Settings_Keys.h"
#import "OpenSSLClient.h"

#define CREATE_SEGMENT_INDEX 0
#define JOIN_SEGMENT_INDEX   1

@interface SessionViewController()

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmented;

@property (strong, nonatomic) IBOutlet UITextField *keyTextField;
@property (strong, nonatomic) IBOutlet UIButton *generateButton;

@end

@implementation SessionViewController {

}
- (void)viewDidLoad {
    [super viewDidLoad];
    static dispatch_once_t once;
    static dispatch_once_t once2;

    SSL_library_init();
    OpenSSL_add_all_algorithms();        /* load & register all cryptos, etc. */
    SSL_load_error_strings();            /* load all error messages */


    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString * certFilePath = [[NSBundle mainBundle] pathForResource:@"login_cert" ofType:@"pem"];
            NSString * keyFilePath = [[NSBundle mainBundle] pathForResource:@"login_key" ofType:@"pem"];

            openSSLServerStart(OPEN_SSL_SERVER_PORT, [certFilePath cStringUsingEncoding:NSUTF8StringEncoding], [keyFilePath cStringUsingEncoding:NSUTF8StringEncoding], "12345");
        });
    });

    dispatch_once(&once2, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString * certFilePath = [[NSBundle mainBundle] pathForResource:@"client_cert" ofType:@"pem"];
            NSString * keyFilePath = [[NSBundle mainBundle] pathForResource:@"client_key" ofType:@"pem"];

            openSSLClientStart("127.0.0.1", OPEN_SSL_SERVER_PORT, [certFilePath cStringUsingEncoding:NSUTF8StringEncoding], [keyFilePath cStringUsingEncoding:NSUTF8StringEncoding], "12345");
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.segmented.selectedSegmentIndex = 0; // generate
    [self segmentedDidChange:self.segmented];
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
    if(self.segmented.selectedSegmentIndex == CREATE_SEGMENT_INDEX) {
        self.generateButton.enabled = NO;
        [[Listener sharedListener] startListen];

        char *temp = createHelloKey();
        NSString *key = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
        deallocator(temp);

        self.keyTextField.text = key;

        [[Helloer sharedHelloer] sendHelloWithDelay:1 repeat:10 key:key block:^BOOL(size_t packetsCounter, int error) {
            if (packetsCounter == 10) {
                self.generateButton.enabled = YES;
            }

            if (!error) {
                customLog(@"Send hello, total sent %lu!", packetsCounter);
            } else {
                customLog(@"Error send packet!");
            }
            return YES;
        }];
    }  else if(self.segmented.selectedSegmentIndex == JOIN_SEGMENT_INDEX) {
        // fixme add join
    }
}

#pragma mark Segmented

-(IBAction)segmentedDidChange:(id)sender {
    if(self.segmented.selectedSegmentIndex == CREATE_SEGMENT_INDEX) {  // create
        self.keyTextField.enabled = NO;
        [self.generateButton setTitle:@"Create" forState:UIControlStateNormal];
    } else if(self.segmented.selectedSegmentIndex == JOIN_SEGMENT_INDEX){ // join
        self.keyTextField.enabled = YES;
        self.keyTextField.text = @"";
        [self.generateButton setTitle:@"Join" forState:UIControlStateNormal];
    }
}

@end