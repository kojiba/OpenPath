//
// Created by Ilya Kucheruavyu on 5/20/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OpenSSLSender : NSObject

+ (OpenSSLSender *)sharedSender;

- (NSString *)sendString:(NSString *)message;

- (void)closeSSL;

- (NSString *)openSSLClientStart:(NSString *)hostnameIp
                        withPort:(NSString *)port;

@end