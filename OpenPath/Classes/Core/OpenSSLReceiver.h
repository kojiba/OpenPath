//
// Created by Ilya Kucheruavyu on 5/20/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenSSLServer.h"
#import "Logger.h"


void logSertificates(SSL *ssl);

@interface OpenSSLReceiver : NSObject

+ (OpenSSLReceiver *)sharedReceiver;

- (void)closeSSL;

- (NSString *)openSSLServerStartOnPort:(NSString *)port
                   certificateFilePath:(NSString *)certFilePath
                           keyFilePath:(NSString *)keyFilePath
                              password:(NSString *)password ;

@end