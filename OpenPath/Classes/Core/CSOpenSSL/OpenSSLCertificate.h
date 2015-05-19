//
//  OpenSSLCertificate.h
//  OpenSSL-for-iOS
//
//  Created by Alexander Pogulyaka on 1/26/11.
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

#import "OpenSSL_obj.h"

@interface OpenSSLCertificate : NSObject {
@private
    NSData *dataPEM;
    BIO *bio;
    X509 *x509;
    EVP_PKEY *publicKey;
@private
    NSMutableDictionary *issuer;
    NSMutableDictionary *subject;
    NSUInteger version;
    NSString *sha1stamp;
    NSUInteger serialNumber;
    NSDate *dateNotBefore;
    NSDate *dateNotAfter;
}

- (id)initWithPEMdata:(NSData *)pemData;

- (BOOL)checkSignData:(NSData *)data withSign:(NSData *)sign;

//-(NSData*)encryptData:(NSData*)data;
- (BOOL)isSignedWithCA:(OpenSSLCertificate *)caCert;

- (BOOL)verifySign:(NSString *)basedSign forData:(NSData *)data;

+ (BOOL)checkPEM:(NSData *)pem;

+ (BOOL)verifySign:(NSString *)basedSign forData:(NSData *)data withCertPEM:(NSData *)certPEM;

@property(nonatomic, readonly, retain) NSData *dataPEM;
@property(nonatomic, readonly, retain) NSMutableDictionary *issuer;
@property(nonatomic, readonly, retain) NSMutableDictionary *subject;
@property(readonly) NSUInteger version;
@property(nonatomic, readonly, retain) NSString *sha1stamp;
@property(readonly) NSUInteger serialNumber;
@property(nonatomic, readonly, retain) NSDate *dateNotBefore;
@property(nonatomic, readonly, retain) NSDate *dateNotAfter;

@property(nonatomic, readonly) NSString *serialNumberString;
@property(nonatomic, readonly) NSString *issuerString;
@property(nonatomic, readonly) NSString *subjectString;

@end

@interface CSOpenSSLSessionCertificate : NSObject {
@private
    NSString *fileName;
}
@property(nonatomic, readwrite, retain) NSString *userCertificateFileName;

+ (void)setCurrentUserCertificateFileName:(NSString *)pFileName;

+ (OpenSSLCertificate *)userCertificate;
@end
