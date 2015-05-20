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
#import "Helper.h"
#import "OpenSSLSender.h"
#import "OpenSSLReceiver.h"

#define CREATE_SEGMENT_INDEX 0
#define JOIN_SEGMENT_INDEX   1

#define REPEAT_TIMES 10

@interface SessionViewController() <UITextFieldDelegate, OpenSSLReceiverDelegate>

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmented;

@property (strong, nonatomic) IBOutlet UITextField *keyTextField;
@property (strong, nonatomic) IBOutlet UIButton *generateButton;

@property (strong, nonatomic) IBOutlet UIButton *responcedButton;

@property (strong, nonatomic) NSData *keyData;

@end

@implementation SessionViewController {
    BOOL receivedHello;

}
- (void)viewDidLoad {
    [super viewDidLoad];
    static dispatch_once_t once;
    self.responcedButton.hidden = YES;

    receivedHello = NO;

    dispatch_once(&once, ^{
        SSL_library_init();            // load lib
        OpenSSL_add_all_algorithms();  // load & register all cryptos, etc.
        SSL_load_error_strings();      // load all error messages

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            NSString * certFilePath = [[NSBundle mainBundle] pathForResource:@"login_cert" ofType:@"pem"];
            NSString * keyFilePath  = [[NSBundle mainBundle] pathForResource:@"login_key" ofType:@"pem"];

            [OpenSSLReceiver sharedReceiver].delegate = self;

            NSString *result = [[OpenSSLReceiver sharedReceiver] openSSLServerStartOnPort:@OPEN_SSL_SERVER_PORT
                                                                      certificateFilePath:certFilePath
                                                                              keyFilePath:keyFilePath
                                                                                 password:@"12345"];

            if(result != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ShowShortMessage(result);
                });
            }
        });

        // client
//        #define SELFTEST
        #ifdef SELFTEST
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);

            NSString *result = [[OpenSSLSender sharedSender] openSSLClientStart:@"127.0.0.1"
                                                                       withPort:@OPEN_SSL_SERVER_PORT];
            if(result == nil) {
                result = [[OpenSSLSender sharedSender] sendString:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit,"
                        " sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, "
                        "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute "
                        "irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
                        "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"];

                [[OpenSSLSender sharedSender] closeSSL];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ShowShortMessage(result);
                });
            }

        });
        #endif
    });


    [[Listener sharedListener] setUpdateBlock:^void(char *data, ssize_t length, size_t packetsCounter, int error, char const *address) {
        if(error == 0
                && data != nil) {
            if(self.keyData.bytes != nil
                    && canDecryptHello((byte const *) data,
                                       (size_t) length,
                                       self.keyData.bytes,
                                       self.keyData.length)) {
                if(!receivedHello) {
                    receivedHello = YES;

                    NSString *message = [NSString stringWithFormat:@"Received HELLO from %s", address];

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [[OpenSSLSender sharedSender] openSSLClientStart:[NSString stringWithCString:address encoding:NSASCIIStringEncoding] withPort:@OPEN_SSL_SERVER_PORT];
                        [[OpenSSLSender sharedSender] sendString:@"HELLO OPENSSL MY FRIEND!"];
                        [[OpenSSLSender sharedSender] closeSSL];
                    });

                    customLog(message, address);
                    ShowShortMessage(message);
                }
            } else {
                // fixme processing session here
//                customLog(@"Received data: %s from %s, total received %lu!", data, address, packetsCounter);
            }
            deallocator(data);
        } else {
            customLog(@"Error receive packet!");
        }
    }];

    [[Listener sharedListener] startListen];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.segmented.selectedSegmentIndex = 0; // generate
    [self segmentedDidChange:self.segmented];
}

#pragma mark OpenSSLReceiverDelegate

- (void)openSSLReceiver:(OpenSSLReceiver *)receiver didAcceptClient:(NSString *)address {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.responcedButton setTitle:address forState:UIControlStateNormal];
        self.responcedButton.hidden = NO;
    });
}

#pragma mark Buttons

-(IBAction)responcedButtonPressed {
    [self performSegueWithIdentifier:@"session-chat.segue" sender:self];
}

-(IBAction)logoutPressed {
    [[OpenSSLReceiver sharedReceiver] closeSSL];
    [[Listener sharedListener] stopListen];
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
        NSString *key = [NSString stringWithCString:temp encoding:NSASCIIStringEncoding];
        deallocator(temp);
        if(stringIsBlankOrNil(self.keyTextField.text)) {
            self.keyTextField.text = key;
        }

        [[Helloer sharedHelloer] sendHelloWithDelay:1
                                             repeat:REPEAT_TIMES
                                                key:[self.keyTextField.text dataUsingEncoding:NSUTF8StringEncoding]
                                              block:^BOOL(size_t packetsCounter, int error) {
            if (packetsCounter == REPEAT_TIMES) {
                self.generateButton.enabled = YES;
            }

            if (!error) {
                customLog(@"Send hello [%lu]", packetsCounter);
            } else {
                self.generateButton.enabled = YES;
                customLog(@"Error send packet!");
            }
            return YES;
        }];


    }  else if(self.segmented.selectedSegmentIndex == JOIN_SEGMENT_INDEX) {
        receivedHello = NO;
        self.keyData = [self.keyTextField.text dataUsingEncoding:NSUTF8StringEncoding];
    }
}

#pragma mark Segmented

-(IBAction)segmentedDidChange:(id)sender {
    if(self.segmented.selectedSegmentIndex == CREATE_SEGMENT_INDEX) {  // create
        self.keyTextField.enabled = YES;
        [self.generateButton setTitle:@"Create" forState:UIControlStateNormal];

    } else if(self.segmented.selectedSegmentIndex == JOIN_SEGMENT_INDEX){ // join
        self.keyTextField.enabled = YES;
        self.keyTextField.text = @"";
        [self.generateButton setTitle:@"Join" forState:UIControlStateNormal];
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