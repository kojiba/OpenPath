//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import "RSyntax.h"

typedef BOOL (^HelloUpdateBlock)(size_t packetsCounter, int error);

@interface Helloer : NSObject

+ (Helloer *)sharedHelloer;

- (void)sendHelloWithDelay:(NSUInteger)seconds repeat:(NSUInteger)times key:(NSData *)key block:(HelloUpdateBlock)block;


@end