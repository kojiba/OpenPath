//
//  RSAPrivateKey.h
//  OpenSSL-for-iOS
//
//  Created by Alexander Pogulyaka on 1/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <Openssl/crypto.h>
#include <Openssl/rand.h>
#include <Openssl/evp.h>
#include <Openssl/sha.h>
#include <Openssl/pem.h>
#include <Openssl/err.h>
#include <Openssl/x509.h>
#include <Openssl/asn1.h>
#include <Openssl/objects.h>

#import "OpenSSLError.h"

#import "OpenSSL_objc.h"

@interface RSAPrivateKey : NSObject {
@private
    NSData   *dataPEM;
    EVP_PKEY *privateKey;
}
+ (BOOL)checkPEM:(NSData *)pem withPassword:(NSString *)pPassword;

- (NSString *)signData:(NSData *)data;

+ (NSString *)signData:(NSData *)data withPEM:(NSData *)pem withPassword:(NSString *)pPassword;
@end


