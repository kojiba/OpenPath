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

@interface ChatCellObject : NSObject
@property (strong, nonatomic) NSString *message;
@property (nonatomic) MessageType type;
@end

@implementation ChatCellObject
@end

@interface ChatCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ChatCell

-(void)fillWithObject:(id)object {
    self.textView.text = ((ChatCellObject *)object).message;
    self.textView.textColor = ((ChatCellObject *)object).type == SelfMessageType ? [UIColor redColor] : [UIColor blueColor];
    [self.textView setTextAlignment: ((ChatCellObject *)object).type == SelfMessageType ? NSTextAlignmentLeft : NSTextAlignmentRight];
}

@end

@interface ChatViewController() <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

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
            ChatCellObject *object = [[ChatCellObject alloc] init];
            object.message = newMessage;
            object.type = PeerMessageType;
            [self updateMessagesWithObject:object isSelf:NO];
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
    [OpenSSLReceiver sharedReceiver].updateBlock = nil;
    [[OpenSSLSender sharedSender] closeSSL];
}


-(void)updateMessagesWithObject:(id)newMessage isSelf:(BOOL)flag {
    // update data source with the object that you need to add
    [self.messages addObject:newMessage];
    NSInteger row = self.messages.count - 1; // specify a row where you need to add new row
    NSInteger section = 0;               // specify the section where the new row to be added
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];

    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
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

-(IBAction)sendButtonPressed {
    self.sendButton.enabled = NO;
    inBackGround ^{
        NSString *result = [[OpenSSLSender sharedSender] sendString:self.inputTextView.text];

        inMainThread ^{
            if(result) {
                ShowShortMessage(result);
            } else {

                ChatCellObject *object = [[ChatCellObject alloc] init];
                object.message = self.inputTextView.text;
                object.type = SelfMessageType;
                [self updateMessagesWithObject:object isSelf:YES];
                self.inputTextView.text = @"";
            }
            self.sendButton.enabled = YES;
        });
    });
}

#pragma mark TextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
}

#pragma mark Keyboarding

- (void)keyboardWillChangeFrame:(NSNotification*)notification {
    double duration;
    CGRect keyboardRect;
    duration = [[notification userInfo] [UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardRect = [[notification userInfo] [UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view.superview convertRect:keyboardRect fromView:nil];

    self.bottomConstraint.constant = -keyboardRect.size.height;

    [UIView animateWithDuration:duration animations:^{
        [self.view updateConstraintsIfNeeded];
    }];
}

- (void) keyboardWillHide:(NSNotification*)notification {
    self.bottomConstraint.constant = -20;
    double duration = [[notification userInfo] [UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration animations:^{
        [self.view updateConstraintsIfNeeded];
    }];
}


@end