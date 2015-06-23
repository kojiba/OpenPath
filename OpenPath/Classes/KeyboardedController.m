//
// Created by Ilya Kucheruavyu on 6/23/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "KeyboardedController.h"


@implementation KeyboardedController {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.backGroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backGroundTaped)]];
    [self.backGroundView setUserInteractionEnabled:YES];
}

-(void)backGroundTaped {
    [self.view endEditing:YES];
}


@end