//
// Created by Ilya Kucheruavyu on 5/19/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "ChatViewController.h"
#import "OpenSSLReceiver.h"
#import "Helper.h"
#import "OpenSSLSender.h"
#import "Settings_Keys.h"



typedef enum MessageType {
    SelfMessageType,
    PeerMessageType
} MessageType;

@interface ChatCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ChatCell

-(void)fillWithObject:(id)object {
    self.textView.text = object;
    self.textView.textColor = [UIColor blueColor];
}

@end

@interface ChatViewController() <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITextView  *inputTextView;

@property (strong, nonatomic) IBOutlet UIButton *sendButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.messages = [[NSMutableArray alloc] initWithCapacity:30];

    [[OpenSSLReceiver sharedReceiver] setUpdateBlock:^(char *data, int length) {
        inMainThread ^{
            NSString *newMessage = [NSString stringWithUTF8String:data];
            [self updateMessagesWithString:newMessage];
        });
    }];
}

-(void)updateMessagesWithString:(NSString*)newMessage {
    customLog(@"RECEIVED! : %@", newMessage);
//    // update data source with the object that you need to add
//    [self.messages addObject:newMessage];
//    NSInteger row = self.messages.count - 1; // specify a row where you need to add new row
//    NSInteger section = 0;               // specify the section where the new row to be added
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
//
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
//    [self.tableView endUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [OpenSSLReceiver sharedReceiver].updateBlock = nil;
    [[OpenSSLSender sharedSender] closeSSL];
}

#pragma mark TableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCellIndetifier" forIndexPath:indexPath];
    [cell fillWithObject:self.messages[(NSUInteger) indexPath.row]];
    return cell;
}

#pragma mark Buttons

-(IBAction)backPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)sendPressed {

    self.sendButton.enabled = NO;
    inBackGround ^{
        NSString *result = [[OpenSSLSender sharedSender] sendString:self.inputTextView.text];

        inMainThread ^{
            if(result) {
                ShowShortMessage(result);
            } else {
                [self updateMessagesWithString:self.inputTextView.text];
                self.inputTextView.text = @"";
            }
            self.sendButton.enabled = YES;
        });
    });
}


@end