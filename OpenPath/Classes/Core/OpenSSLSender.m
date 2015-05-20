//
// Created by Ilya Kucheruavyu on 5/20/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "OpenSSLSender.h"

#import "OpenSSLClient.h"
#import "Logger.h"

@implementation OpenSSLSender {
    SSL_CTX *currentContext;
    SSL *currentSSL;

    int clientSocket;
}

+ (OpenSSLSender *)sharedSender {
    static OpenSSLSender *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

-(NSString*)sendString:(NSString*)message {
    NSData *dataToSend = [message dataUsingEncoding:NSUTF8StringEncoding];

    int result = SSL_write(currentSSL, dataToSend.bytes, (int) dataToSend.length);  // encrypt & send message
    if(result < 0) {
        NSString *error = [NSString stringWithFormat:@"Error send message \"%@\"", message];
        customLog(error);
        return error;
    }
    return nil;
}

-(void)closeSSL {
    // release connection state
    if(currentSSL != nil)
        SSL_free(currentSSL);

    // close socket
    if(clientSocket > 0)
        close(clientSocket);

    // release context
    if(currentContext != nil)
        SSL_CTX_free(currentContext);
}

-(NSString*)openSSLClientStart:(NSString*)hostnameIp
                      withPort:(NSString*)port
//           certificateFilePath:(NSString*)certFilePath
//                   keyFilePath:(NSString*)keyFilePath
//                      password:(NSString*)password
{

    char buf[1024];
    int bytes;

    currentContext = InitClientContext();
    if(currentContext == nil) {
        return @"Error initialize SSL client context";
    }

//    LoadCertificates(currentContext,
//            [certFilePath cStringUsingEncoding:NSUTF8StringEncoding],
//            [keyFilePath  cStringUsingEncoding:NSUTF8StringEncoding],
//            [password     cStringUsingEncoding:NSUTF8StringEncoding]);

    clientSocket = OpenClientConnection([hostnameIp cStringUsingEncoding:NSUTF8StringEncoding],
                                   atoi([port cStringUsingEncoding:NSUTF8StringEncoding]));
    if(clientSocket < 0) {
        return @"Error open SSL client connection";
    }

    currentSSL = SSL_new(currentContext);
    if(currentSSL == nil) {
        return @"Error create session SSL context";
    }

    // create new SSL connection state
    if(SSL_set_fd(currentSSL, clientSocket) < 0) { // attach the socket descriptor
        return @"Error attach to socket descriptor";
    }

    if (SSL_connect(currentSSL) == -1) {
        return @"Can't connect to SSL listener";

    } else {
        customLog(@"Connected with %s encryption", SSL_get_cipher(currentSSL));
        ShowCerts(currentSSL, no);                     // get any certs
    }

//    [self closeSSL];
    return nil;
}

- (void)dealloc {
    [self closeSSL];
}

@end