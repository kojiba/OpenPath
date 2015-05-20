#import "OpenSSLCertificate.h"
#import "SynthesizeSingleton.h"
#import "NSData+Utils.h"

#import <UIKit/UIKit.h>

@implementation OpenSSLSessionCertificate

SYNTHESIZE_SINGLETON_FOR_CLASS(OpenSSLSessionCertificate, instance);

@synthesize userCertificateFileName = fileName;

+ (void)setCurrentUserCertificateFileName:(NSString *)pFileName {
    [OpenSSLSessionCertificate instance].userCertificateFileName = pFileName;
}

+ (OpenSSLCertificate *)userCertificate {
    NSString *certificateFileName = [OpenSSLSessionCertificate instance].userCertificateFileName;
    if (!certificateFileName) {
        return nil;
    }

    NSData *certificateData = [[[NSData alloc] initFromKeystoreWithShortName:certificateFileName] autorelease];
    OpenSSLCertificate *result = [[[OpenSSLCertificate alloc] initWithPEMdata:certificateData] autorelease];
    return result;
}

- (void)dealloc {
    [fileName release];
    [super dealloc];
}

@end


@interface OpenSSLCertificate (CSOpenSSLCertificate_PRIVATE)
- (BOOL)_internalParsePEM;

- (void)_internalExtractCertInfo;

- (NSDate *)_internalParseUTCTIME:(ASN1_UTCTIME *)time;

- (void)_internalParseX509name:(X509_NAME *)x509name toDictionary:(NSMutableDictionary *)dict;

- (void)_internalCalcSHA1;

- (BOOL)_internalIsSignedWithCA:(X509 *)x509CA;

- (BIO *)getBio;

- (X509 *)getX509;

- (EVP_PKEY *)getPublicKey;

@property(readonly, getter=getBio) BIO *bio;
@property(readonly, getter=getX509) X509 *x509;
@property(readonly, getter=getPublicKey) EVP_PKEY *publicKey;

@end

@implementation OpenSSLCertificate (CSOpenSSLCertificate_PRIVATE)

- (BIO *)getBio {
    return self->bio;
}

- (X509 *)getX509 {
    return self->x509;
}

- (EVP_PKEY *)getPublicKey {
    return self->publicKey;
}

- (BOOL)_internalParsePEM {
    NSAssert([dataPEM length] > 0, @"PEM is empty");

    BOOL result = NO;

    void *memBuf = malloc([dataPEM length]);
    @try {
        [dataPEM getBytes:memBuf];

        bio = BIO_new_mem_buf(memBuf, [dataPEM length]);
        checkOpenSSLError(@"BIO_new_mem_buf");
        @try {
            x509 = PEM_read_bio_X509(bio, nil, nil, nil);
            checkOpenSSLError(@"PEM_read_bio_X509");
            @try {
                [self _internalExtractCertInfo];


                // extract buplic key
                publicKey = X509_get_pubkey(x509);
                checkOpenSSLError(@"PEM_read_bio_X509");
                @try {
                    result = (publicKey != nil);
                    if (result) {
                        [self _internalCalcSHA1];
                    }
                }
                @catch (NSException *e) {
                    EVP_PKEY_free(publicKey);
                    publicKey = nil;
                    @throw e;
                }
            }
            @catch (NSException *e) {
                X509_free(x509);
                x509 = nil;
                @throw e;
            }
        }
        @catch (NSException *e) {
            BIO_free(bio);
            bio = nil;
            @throw e;
        }

    }
    @finally {
        free(memBuf);
    }

    return result;
}

- (void)_internalExtractCertInfo {
    // extract issuer
    issuer = [[NSMutableDictionary alloc] init];
    @try {
        X509_NAME *issuerName = X509_get_issuer_name(x509);
        checkOpenSSLError(@"X509_get_issuer_name");

        [self _internalParseX509name:issuerName toDictionary:issuer];
    }
    @catch (NSException *e) {
        [issuer release];
        issuer = nil;
        @throw e;
    }

    // extract subject
    subject = [[NSMutableDictionary alloc] init];
    @try {
        X509_NAME *subjectName = X509_get_subject_name(x509);
        checkOpenSSLError(@"X509_get_issuer_name");

        [self _internalParseX509name:subjectName toDictionary:subject];
    }
    @catch (NSException *e) {
        [subject release];
        subject = nil;
        @throw e;
    }

    // Vesrion
    version = X509_get_version(x509);
    checkOpenSSLError(@"X509_get_version");

    // Serial Number
    ASN1_INTEGER *sn = X509_get_serialNumber(x509);
    checkOpenSSLError(@"X509_get_serialNumber");
    serialNumber = ASN1_INTEGER_get(sn);

    // Get Start (Not Nefore) Date
    ASN1_UTCTIME *timeStamp = X509_get_notBefore(x509);
    checkOpenSSLError(@"X509_get_notBefore");
    dateNotBefore = [[self _internalParseUTCTIME:timeStamp] retain];

    // Get End (Not After) Date
    timeStamp = X509_get_notAfter(x509);
    checkOpenSSLError(@"X509_get_notAfter");
    dateNotAfter = [[self _internalParseUTCTIME:timeStamp] retain];
}

- (NSDate *)_internalParseUTCTIME:(ASN1_UTCTIME *)time {
    unsigned char YYYY[5] = "2000";
    unsigned char MM[3], DD[3], HH[3], MI[3], SS[3] = "";
    strlcpy((char *) &YYYY[2], (const char *) (time->data + 0), 3);
    strlcpy((char *) MM, (const char *) (time->data + 2), 3);
    strlcpy((char *) DD, (const char *) (time->data + 4), 3);

    if (time->length > 6) {
        strlcpy((char *) HH, (const char *) (time->data + 6), 3);
        strlcpy((char *) MI, (const char *) (time->data + 8), 3);
        strlcpy((char *) SS, (const char *) (time->data + 10), 3);
    }

    NSDateComponents *dateComps = [[NSDateComponents alloc] init];
    [dateComps setYear:(NSUInteger) atoi((const char *) YYYY)];
    [dateComps setMonth:(NSUInteger) atoi((const char *) MM)];
    [dateComps setDay:(NSUInteger) atoi((const char *) DD)];
    [dateComps setHour:(NSUInteger) atoi((const char *) HH)];
    [dateComps setMinute:(NSUInteger) atoi((const char *) MI)];
    [dateComps setSecond:(NSUInteger) atoi((const char *) SS)];

    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDate *result = [cal dateFromComponents:dateComps];

    [dateComps autorelease];
    [cal autorelease];

    return result;
}

- (void)_internalParseX509name:(X509_NAME *)x509name toDictionary:(NSMutableDictionary *)dict {
    NSAssert(dict, @"dict is NULL");
#define _nameLen    0x40
#define _valueLen    0x80
    char *name = (char *) malloc(_nameLen);
    @try {
        char *value = (char *) malloc(_valueLen);
        @try {
            for (int i = 0; i < X509_NAME_entry_count(x509name); i++) {
                X509_NAME_ENTRY *entry = X509_NAME_get_entry(x509name, i);
                checkOpenSSLError(@"X509_NAME_get_entry");
                if (entry) {
                    ASN1_OBJECT *obj = X509_NAME_ENTRY_get_object(entry);
                    checkOpenSSLError(@"X509_NAME_ENTRY_get_object");
                    if (obj) {
                        char buf;

                        int len = OBJ_obj2txt(&buf, 1, obj, 0) + 1;
                        NSAssert(len <= _nameLen, @"name length is too long");
                        OBJ_obj2txt(name, len, obj, 0);

                        ASN1_STRING *str = X509_NAME_ENTRY_get_data(entry);
                        checkOpenSSLError(@"X509_NAME_ENTRY_get_data");
                        len = M_ASN1_STRING_length(str);
                        NSAssert(len <= _valueLen, @"value length is too long");
                        strlcpy(value, (char *) M_ASN1_STRING_data(str), len + 1);

                        [dict setObject:[NSString stringWithFormat:@"%s", value] forKey:[NSString stringWithFormat:@"%s", name]];
                    }
                }
            }
        }
        @finally {
            free(value);
        }
    }
    @finally {
        free(name);
    }
}


- (void)_internalCalcSHA1 {
    NSAssert(publicKey, @"publicKey is NULL");
    unsigned char *keyBuf = (unsigned char *) malloc(2048/*max key size*/);
    @try {
        unsigned char *keyData = keyBuf;
        unsigned char **pKeyData = &keyData;
        int dataSize = i2d_PUBKEY(publicKey, pKeyData);

        NSAssert(publicKey->pkey.rsa, @"rsa is NULL");

        NSUInteger offset = 0;

        NSUInteger keySize = EVP_PKEY_size(publicKey);
        switch (keySize) {
            case 128://1024 bit
            {
                char *szE = BN_bn2dec(publicKey->pkey.rsa->e);
                NSInteger iE = 0;
                @try {
                    iE = [[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%s", szE]] integerValue];
                }
                @catch (NSException *exception) {
                    iE = -1;
                }

                if (iE != 65537) {
                    offset = 138;
                } else {
                    offset = 140;
                }
            }
                break;

            case 256://2048 bit
            {
                offset = 270;
            }
                break;

            default:
                NSAssert(NO, @"UNSUPPORTED KEY SIZE");
                break;
        }

        unsigned char *sha1bin = SHA1((unsigned char *) (keyBuf + dataSize - offset), offset, nil);
#define SHA1_SIZE 20
#define SHA1_TEXTBUF_SIZE SHA1_SIZE * 3
        unsigned char *sha1str = (unsigned char *) malloc(SHA1_TEXTBUF_SIZE);
        @try {
            const char hexnum[16] = "0123456789ABCDEF";
            int j = 0;
            for (int i = 0; i < SHA1_SIZE; i++) {
                sha1str[j + 0] = hexnum[sha1bin[i] >> 4];
                sha1str[j + 1] = hexnum[sha1bin[i] & 0x0F];
                sha1str[j + 2] = 0x20; // spaces, result will be like 'ab cd ef 12 34 ...'
                j += 3;
            }
            sha1str[SHA1_TEXTBUF_SIZE - 1] = 0;
            sha1stamp = [[NSString stringWithFormat:@"%s", sha1str] retain];
        }
        @finally {
            free(sha1str);
        }
    }
    @finally {
        free(keyBuf);
    }
}

- (BOOL)_internalIsSignedWithCA:(X509 *)x509CA {
    if (X509_NAME_cmp(X509_get_issuer_name(x509), X509_get_subject_name(x509CA))) {
        return NO;
    }
    EVP_PKEY *caPublicKey = X509_get_pubkey(x509CA);
    checkOpenSSLError(@"X509_get_pubkey");

    return X509_verify(x509, caPublicKey) && !openSSLError();
}


@end

@implementation OpenSSLCertificate

@synthesize dataPEM;
@synthesize issuer;
@synthesize subject;
@synthesize version;
@synthesize sha1stamp;
@synthesize serialNumber;
@synthesize dateNotBefore;
@synthesize dateNotAfter;

- (NSString *)serialNumberString {
    return [NSString stringWithFormat:@"%@ (%@)", @(self.serialNumber), [NSString stringWithFormat:@"%@", @(self.serialNumber)]];
}

- (NSString *)issuerString {
    return [self dictToStr:self.issuer];
}

- (NSString *)subjectString {
    return [self dictToStr:self.subject];
}


- (NSString *)dictToStr:(NSDictionary *)dict {
    NSString *result = @"";
    for (NSString *val in [dict allValues]) {
        if (![[val lowercaseString] isEqualToString:@"null"]) {
            result = [[result stringByAppendingString:val] stringByAppendingString:@", "];
        }
    }
    result = [result substringToIndex:[result length] - 2];
    return result;
}

- (id)initWithPEMdata:(NSData *)pemData {
    openSSLSturtup();

    self = [super init];
    if (self) {
        dataPEM = [[NSData alloc] initWithData:pemData];
        if ([self _internalParsePEM]) {
            //
        } else {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (BOOL)checkSignData:(NSData *)data withSign:(NSData *)sign {
    BOOL result = NO;

    void *dataBuf = malloc([data length]);
    @try {
        [data getBytes:dataBuf];

        void *signBuf = malloc([sign length]);
        @try {
            [sign getBytes:signBuf];

            const EVP_MD *md = EVP_get_digestbyname("md5");
            checkOpenSSLError(@"EVP_get_digestbyname");

            EVP_MD_CTX ctx;

            EVP_VerifyInit(&ctx, md);
            checkOpenSSLError(@"EVP_VerifyInit");

            EVP_VerifyUpdate(&ctx, dataBuf, [data length]);
            checkOpenSSLError(@"EVP_VerifyUpdate");

            result = EVP_VerifyFinal(&ctx, signBuf, [sign length], publicKey) > 0;
            if (openSSLError()) {
                result = NO;
            }

        }
        @finally {
            free(signBuf);
        }
    }
    @finally {
        free(dataBuf);
    }

    return result;
}

/* TODO
 
-(NSData*)encryptData:(NSData*)data
{
	NSAssert(data && [data length]>0, @"data is NULL or empty");
	
	NSData* result = [[NSData alloc] init];
	@try
	{
		//TODO
	}
	@catch (NSException * e)
	{
		[result release];
		@throw e;
	}
	return result;
}
*/

- (BOOL)isSignedWithCA:(OpenSSLCertificate *)caCert {
    return [self _internalIsSignedWithCA:caCert.x509];
}

- (BOOL)verifySign:(NSString *)basedSign forData:(NSData *)data {
    NSAssert(publicKey, @"publicKey not assigned");


    const EVP_MD *md = EVP_get_digestbyname("md5");
    if (openSSLError() || !md) return NO;

    EVP_MD_CTX ctx;

    EVP_VerifyInit(&ctx, md);
    if (openSSLError()) return NO;

    NSUInteger dataLen = [data length];
    unsigned char *dataBuf = (unsigned char *) malloc(dataLen);
    @try {
        [data getBytes:dataBuf];

        EVP_VerifyUpdate(&ctx, dataBuf, dataLen);
        if (openSSLError()) return NO;

        NSData *sigData = [basedSign base64DecodedData];
        NSUInteger signLen = [sigData length];
        unsigned char *signBuf = (unsigned char *) malloc(signLen);
        @try {
            [sigData getBytes:signBuf];

            BOOL result = EVP_VerifyFinal(&ctx, signBuf, signLen, publicKey) > 0;
            if (openSSLError()) return NO;

            return result;
        }
        @finally {
            free(signBuf);
        }
    }
    @finally {
        free(dataBuf);
    }
}

- (void)dealloc {
    [dataPEM release];
    [sha1stamp release];
    [dateNotAfter release];
    [dateNotBefore release];
    [super dealloc];
}

+ (BOOL)checkPEM:(NSData *)pem {
    OpenSSLCertificate *cert = [[[OpenSSLCertificate alloc] initWithPEMdata:pem] autorelease];
    return cert != nil;
}

+ (BOOL)verifySign:(NSString *)basedSign forData:(NSData *)data withCertPEM:(NSData *)certPEM {
    OpenSSLCertificate *cert = [[[OpenSSLCertificate alloc] initWithPEMdata:certPEM] autorelease];
    return cert != nil ? [cert verifySign:basedSign forData:data] : NO;
}

@end
