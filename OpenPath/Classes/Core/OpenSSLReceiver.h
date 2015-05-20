//
// Created by Ilya Kucheruavyu on 5/20/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenSSLServer.h"
#import "Logger.h"

@class OpenSSLReceiver;


void logSertificates(SSL *ssl);

@protocol OpenSSLReceiverDelegate<NSObject>
@required
-(void)openSSLReceiver:(OpenSSLReceiver*)receiver didAcceptClient:(NSString*)address;
@end

@interface OpenSSLReceiver : NSObject

@property (strong, nonatomic) id<OpenSSLReceiverDelegate> delegate;

+ (OpenSSLReceiver *)sharedReceiver;

- (void)closeSSL;

- (NSString *)openSSLServerStartOnPort:(NSString *)port
                   certificateFilePath:(NSString *)certFilePath
                           keyFilePath:(NSString *)keyFilePath
                              password:(NSString *)password ;

@end