//
//  RSAPrivateKey.m
//  OpenSSL-for-iOS
//
//  Created by Alexander Pogulyaka on 1/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSAPrivateKey.h"
#import "NSData+Utils.h"


@interface RSAPrivateKey (CSRSAPrivateKey_PRIVATE)
- (BOOL)loadKeyFromPEMWithPassword:(NSString *)pPassword;

- (id)initWithPEMData:(NSData *)pem withPassword:(NSString *)pPassword;
@end

@implementation RSAPrivateKey (CSRSAPrivateKey_PRIVATE)

- (BOOL)loadKeyFromPEMWithPassword:(NSString *)pPassword {
    //NSLog(@"-[ loadKeyFromPEMWithPassword:%@]", pPassword);

    openSSLSturtup();
    NSUInteger bufKeyLen = [dataPEM length];
    char *bufKey = (char *) malloc(bufKeyLen);
    @try {
        [dataPEM getBytes:bufKey];

        BIO *bio = BIO_new_mem_buf(bufKey, bufKeyLen);
        if (openSSLError() || !bio) return NO;
        @try {
            NSUInteger pwdLen = [pPassword length] + 1;
            char *pwd = (char *) malloc(pwdLen);
            @try {
                memset(pwd, 0x00, pwdLen);
                [pPassword getBytes:pwd maxLength:pwdLen - 1 usedLength:nil encoding:NSUTF8StringEncoding options:0 range:(NSRange) {0, pwdLen - 1} remainingRange:nil];

                //NSLog(@"-[ loadKeyFromPEMWithPassword:] :: pwd [%s]", pwd);

                privateKey = PEM_read_bio_PrivateKey(bio, NULL, NULL, pwd);

                unsigned long sslErrorCode = 0;
                BOOL result = !(openSSLErrorCode(&sslErrorCode) || !privateKey);
                if (!result) {
                    NSLog(@"OpenSSLErrorCode: %lu", sslErrorCode);
                }

                return result;
            }
            @finally {
                memset(pwd, 0x00, pwdLen);
                free(pwd);
            }
        }
        @finally {
            BIO_free(bio);
        }
    }
    @finally {
        free(bufKey);
    }

    return YES;
}

- (id)initWithPEMData:(NSData *)pem withPassword:(NSString *)pPassword {
    self = [super init];
    if (self) {
        dataPEM = [pem copy];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];// ask rush
        if (![self loadKeyFromPEMWithPassword:pPassword]) {
            [self release];
            self = nil;
        }
    }
    return self;
}


@end

@implementation RSAPrivateKey

+ (BOOL)checkPEM:(NSData *)pem withPassword:(NSString *)pPassword {
    BOOL result = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        @try {
            RSAPrivateKey *tmpKey = [[RSAPrivateKey alloc] initWithPEMData:pem withPassword:pPassword];
            result = tmpKey != nil;
            [tmpKey release];
        }
        @catch (...) {;
        }
    }
    @finally {
        [pool release];
    }

    return result;
}


- (NSString *)signData:(NSData *)data {
    NSAssert(privateKey, @"PRIVATE KEY IS NOT ASSIGNED");

    NSString *result = @"";

    if ([data length] > 0) {
        const EVP_MD *md = EVP_get_digestbyname("md5");
        if (!openSSLError()) {
            EVP_MD_CTX ctx;
            EVP_SignInit(&ctx, md);
            if (!openSSLError()) {
                NSUInteger dataSize = [data length];
                char *dataBuf = (char *) malloc(dataSize);
                @try {
                    [data getBytes:dataBuf];
                    EVP_SignUpdate(&ctx, dataBuf, dataSize);
                    if (!openSSLError()) {
                        NSUInteger sigLen = EVP_PKEY_size(privateKey);
                        unsigned char *sigBuf = (unsigned char *) malloc(sigLen);
                        @try {
                            memset(sigBuf, 0x00, sigLen);
                            EVP_SignFinal(&ctx, sigBuf, &sigLen, privateKey);
                            if (!openSSLError()) {
                                NSData *sigData = [NSData dataWithBytes:sigBuf length:sigLen];
                                if (sigData && [sigData length] > 0) {
                                    result = [sigData base64EncodedString];
                                }
                            }
                        }
                        @finally {
                            free(sigBuf);
                        }
                    }
                }
                @finally {
                    free(dataBuf);
                }
            }
        }
    }

    return result;
}

+ (NSString *)signData:(NSData *)data withPEM:(NSData *)pem withPassword:(NSString *)pPassword {
    NSString *result = nil;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]]; // coz sometimes have EX_BAD_ACC, while runs "quickly" 
    RSAPrivateKey *key = [[RSAPrivateKey alloc] initWithPEMData:pem withPassword:pPassword];
    if (key) {
        @try {
            result = [key signData:data];
        }
        @finally {
            [key release];
        }
    }

    return result;
}

- (void)dealloc {
    [dataPEM release];
    EVP_PKEY_free(self->privateKey);
    [super dealloc];
}
@end

