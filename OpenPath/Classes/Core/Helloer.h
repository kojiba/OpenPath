//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>


@interface Helloer : NSObject
+ (Helloer *)sharedHelloer;

- (void)sendHelloWithDelay:(NSUInteger)seconds repeat:(NSUInteger)times logTextView:(UITextView *)log;


@end