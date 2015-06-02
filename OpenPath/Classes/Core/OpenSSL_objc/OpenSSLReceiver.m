//
// Created by Ilya Kucheruavyu on 5/20/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "OpenSSLReceiver.h"
#import "Helper.h"
#import "Settings_Keys.h"

#define bufferSize 65535

@implementation OpenSSLReceiver {
    SSL_CTX *currentContext;
    SSL     *currentSSL;

    int serverSocket;
}

void logSertificates(SSL *ssl) {
    X509 *cert;
    char *line;

    cert = SSL_get_peer_certificate(ssl);    /* Get certificates (if available) */
    if (cert != nil) {
        line = X509_NAME_oneline(X509_get_subject_name(cert), 0, 0);
        customLog(@"Subject: %s", line);
        deallocator(line);

        line = X509_NAME_oneline(X509_get_issuer_name(cert), 0, 0);
        customLog(@"Issuer: %s", line);
        deallocator(line);

        X509_free(cert);
    }
    else
        customLog(@"No certificates.");
}


-(void)Servlet:(SSL*)ssl {  // Serve the connection -- threadable
    char buffer[bufferSize];
#ifdef SELFTEST
    char responce[1024];
    const char *echo = "Welcome on OpenPath SSL server, echo : \"%s\"\n\n";
#endif
    int sd, bytes = 1024;

    if (SSL_accept(ssl) == -1) { // do SSL-protocol accept
        ERR_print_errors_fp(stderr);
        customLog(@"Error SSL accept");
    } else {

        while(bytes >= 0) {

            bytes = SSL_read(ssl, buffer, sizeof(buffer));    // get request
            if (bytes > 0) {
                buffer[bytes] = 0;
                customLog(@"Client msg: \"%s\"\n", buffer);

            #ifdef SELFTEST
                sprintf(responce, echo, buffer);                  // construct responce
                SSL_write(ssl, responce, (int) strlen(responce)); // send responce
            #else
                if (self.updateBlock != nil) {
                    self.updateBlock(buffer, bytes);
                }
            #endif
            }
            else {
                ERR_print_errors_fp(stderr);
                break;
            }
        }
    }
    sd = SSL_get_fd(ssl);      // get socket connection
    SSL_free(ssl);             // release SSL state
    close(sd);                 // close connection
}

+ (OpenSSLReceiver *)sharedReceiver {
    static OpenSSLReceiver *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (void)closeSSL {
    // release connection state
    if(currentSSL != nil)
        SSL_free(currentSSL);

    // close socket
    if(serverSocket > 0)
        close(serverSocket);

    // release context
    if(currentContext != nil)
        SSL_CTX_free(currentContext);

    currentSSL     = nil;
    serverSocket   = nil;
    currentContext = nil;
}

- (NSString *)openSSLServerStartOnPort:(NSString *)port
                   certificateFilePath:(NSString *)certFilePath
                           keyFilePath:(NSString *)keyFilePath
                              password:(NSString *)password {

    currentContext = InitServerCTX();

    char *error =  LoadCertificates(currentContext,
            [certFilePath cStringUsingEncoding:NSUTF8StringEncoding],
            [keyFilePath  cStringUsingEncoding:NSUTF8StringEncoding],
            [password     cStringUsingEncoding:NSUTF8StringEncoding]);

    if(error != nil) {
        return [NSString stringWithCString:error encoding:NSUTF8StringEncoding];
    }
    serverSocket = OpenListener(atoi([port cStringUsingEncoding:NSUTF8StringEncoding])); // create server socket

    if(serverSocket < 0) {
        return @"Can't open listener socket";
    }

    #ifdef PATH_USE_TLS
    customLog(@"OpenPath TLS server started at port %@", port);
    #elif defined(PATH_USE_SSL)
    customLog(@"OpenPath SSL server started at port %@", port);
    #endif

    while (1) {
        struct sockaddr_in clienAddress;
        size_t len = sizeof(clienAddress);
        SSL *ssl;

        int client = accept(serverSocket, (struct sockaddr *) &clienAddress, &len); // accept connection as usual
        if(client > 0) {
            char *clientAddr = inet_ntoa(clienAddress.sin_addr);
            customLog(@"Connection: %s:%d", clientAddr, ntohs(clienAddress.sin_port));

            if(self.delegate != nil) {
                [self.delegate openSSLReceiver:self didAcceptClient:[NSString stringWithCString:clientAddr encoding:NSASCIIStringEncoding]];
            }

            ssl = SSL_new(currentContext); // get new SSL state with context
            SSL_set_fd(ssl, client);       // set connection socket to SSL state

            [self Servlet:ssl];                  // service connection

        } else {
            if(serverSocket > 0) {
                customLog(@"Error accept connection", inet_ntoa(clienAddress.sin_addr), ntohs(clienAddress.sin_port));
                [self closeSSL];
            }
            break;
        }
    }

    return nil;
}

@end