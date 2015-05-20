//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ListenerUpdateBlock)(char *data, ssize_t length, size_t packetsCounter, int error, char const *address);

@interface Listener : NSObject

@property (nonatomic, copy) ListenerUpdateBlock updateBlock;

+ (Listener *)sharedListener;

- (void)stopListen;

- (void)startListen;
@end