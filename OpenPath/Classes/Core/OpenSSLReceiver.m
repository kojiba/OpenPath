//
// Created by Ilya Kucheruavyu on 5/20/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "OpenSSLReceiver.h"

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


void Servlet(SSL *ssl)    /* Serve the connection -- threadable */ {
    char buffer[1024];
    char responce[1024];
    int sd, bytes;
    const char *echo = "Welcome on OpenPath SSL server, echo : \"%s\"\n\n";

    if (SSL_accept(ssl) == -1) { // do SSL-protocol accept
        ERR_print_errors_fp(stderr);
        customLog(@"Error SSL accept");
    } else {
//        customLog(@"Client certificates ----");
//        logSertificates(ssl);

        bytes = SSL_read(ssl, buffer, sizeof(buffer));    // get request
        if (bytes > 0) {
            buffer[bytes] = 0;
            customLog(@"Client msg: \"%s\"\n", buffer);
            sprintf(responce, echo, buffer);                  // construct responce
            SSL_write(ssl, responce, (int) strlen(responce)); // send responce
        }
        else
            ERR_print_errors_fp(stderr);
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

    customLog(@"OpenPath SSL server started at port %@", port);

    while (1) {
        struct sockaddr_in clienAddress;
        size_t len = sizeof(clienAddress);
        SSL *ssl;

        int client = accept(serverSocket, (struct sockaddr *) &clienAddress, &len); // accept connection as usual
        if(client > 0) {
            customLog(@"Connection: %s:%d", inet_ntoa(clienAddress.sin_addr), ntohs(clienAddress.sin_port));

            ssl = SSL_new(currentContext); // get new SSL state with context
            SSL_set_fd(ssl, client);       // set connection socket to SSL state
            Servlet(ssl);                  // service connection

        } else {
            customLog(@"Error accept connection", inet_ntoa(clienAddress.sin_addr), ntohs(clienAddress.sin_port));
            [self closeSSL];
            break;
        }
    }

    return nil;
}

@end