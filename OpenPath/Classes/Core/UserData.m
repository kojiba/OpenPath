//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "UserData.h"
#import "Logger.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Helper.h"
#import "RSAPrivateKey.h"
#import "NSData+Utils.h"

#import <UIKit/UIKit.h>

@interface RSAPrivateKey (KeyStore)
+ (BOOL)getUserKeyExistsForLogin:(NSString *)login;
+ (BOOL)checkKeyPassword:(NSString *)password forLogin:(NSString *)login;
+ (NSString *)getUserKeyNameForLogin:(NSString *)login;
@end

@implementation RSAPrivateKey (KeyStore)

+ (NSString *)getUserKeyNameForLogin:(NSString *)login {
    NSString *userKeyFileNameTemplate = @"%@_key.pem";
    return [NSString stringWithFormat:userKeyFileNameTemplate, login];
}

+ (NSString *)getUserCertNameForLogin:(NSString *)login {
    NSString *userKeyFileNameTemplate = @"%@_cert.pem";
    return [NSString stringWithFormat:userKeyFileNameTemplate, login];
}


+ (BOOL)getUserKeyExistsForLogin:(NSString *)login {
    NSString *keyPathShort = [self getUserKeyNameForLogin:login];
    NSString *path = [KEYSTORE_PATH stringByAppendingPathComponent:keyPathShort];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];

}

+ (BOOL)checkKeyPassword:(NSString *)password forLogin:(NSString *)login {
    NSData *pkPEM = [[NSData alloc] initFromKeystoreWithShortName:[self getUserKeyNameForLogin:login]];
    BOOL result = [RSAPrivateKey checkPEM:pkPEM withPassword:password];
    return result;
}

@end

@interface UserData() <UIAlertViewDelegate> {
    NSString   *sharedFileNameKey;
    NSString   *sharedFileNameCer;
    NSUInteger  keyPasswordCounter;

    NSString *userPasswordKey;
}

@property (strong, nonatomic) NSString* username;
@property (strong, nonatomic) NSString* tempStoredPassword;

@end

#define USERDATA_KEY @"*)A_Ptc?=jX4HnV0CkbPF68Hl,elLM"

@implementation UserData {

}
+ (UserData *)sharedData {
    static UserData *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (NSString *)currentUserName {
    return [self.username copy];
}

-(NSString*)userLoginPattern:(NSString*)login {
    return [NSString stringWithFormat:@"%@_%@", USER_NAME_KEY, login];
}

-(NSString*)userKeyPasswordPattern:(NSString*)login {
    return [NSString stringWithFormat:@"%@_%@", USER_KEY_PASSWORD, login];
}

- (void)logout {
    if(!stringIsBlankOrNil(self.username)) {
        self.username = nil;
        userPasswordKey = nil;
        // fixme
        // store logs and encrypt some
        [Logger addSessionEndStamp];
    }
}

- (NSString *)userPasswordKey {
    return userPasswordKey;
}

- (BOOL)loginWithName:(NSString *)login password:(NSString *)password {
    id data = [[NSUserDefaults standardUserDefaults] objectForKey:[self userLoginPattern:login]];
    if(data == nil
            || ![data isKindOfClass:[NSData class]]) {
        showMessageInMain(@"Bad username or password");
        return NO;
    }
    NSError *error = nil;

    NSData *check = [RNDecryptor decryptData:data withPassword:password error:&error];
    if(error) {
        showMessageInMain(@"Bad username or password");
        return NO;
    }
    // check if digest right, proof of decrypt
    if (![check isEqualToData:[login dataUsingEncoding:NSUTF8StringEncoding]]) {
        showMessageInMain(@"Bad username or password");
        return NO;
    }

    NSData *privateKeyPasswordData = [[NSUserDefaults standardUserDefaults] objectForKey:[self userKeyPasswordPattern:login]];
    NSData *privateKeyDecrypted = [RNDecryptor decryptData:privateKeyPasswordData withPassword:password error:&error];

    if(error) {
        showMessageInMain(@"Cannot load user key");
        return NO;
    }

    NSUInteger size = privateKeyDecrypted.length;
    char *nullTerminatedString = malloc(size + 1);
    if(nullTerminatedString != nil) {
        memcpy(nullTerminatedString, privateKeyDecrypted.bytes, size);
        nullTerminatedString[size] = 0;
        userPasswordKey = [NSString stringWithUTF8String:nullTerminatedString];
    }
    srand((unsigned int) time(nil));
    self.username = login;

    [Logger addSessionStartStamp];
    // fixme
    // load some settings
    // decrypt some

#ifdef HAVE_ITUNES_KEY_TRANSFER
    inMainThread ^{
        if([self checkSharedKeysFound]){
            self.tempStoredPassword = password;
            [self checkSharedKeysPromptPassword];
        } else {
            [self alertCertExpired];
        }
    });
#endif
    return YES;
}

- (NSString*)createUserWithLogin:(NSString *)login password:(NSString *)password {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[self userLoginPattern:login]];
    if(data == nil) {
        // create digest
        NSError *error = [[NSError alloc] init];
        NSData *digest = [RNEncryptor encryptData:[login dataUsingEncoding:NSUTF8StringEncoding]
                                     withSettings:kRNCryptorAES256Settings
                                         password:password
                                            error:&error];
        if(!error.code) {
            [[NSUserDefaults standardUserDefaults] setObject:digest forKey:[self userLoginPattern:login]];
            return nil;
        } else {
            return error.localizedDescription;
        }
    } else {
        return @"User already exists!";
    }
}

#pragma mark -= User Keys =-

#ifdef HAVE_ITUNES_KEY_TRANSFER

- (BOOL)isUserKeyExists {
    return [RSAPrivateKey getUserKeyExistsForLogin:self.username];
}

- (BOOL)checkUserKeyPassword:(NSString *)password {
    return [RSAPrivateKey checkKeyPassword:password forLogin:self.username];
}

- (BOOL)checkSharedKeysFound {
    BOOL result = NO;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];

    NSString *patKey = [RSAPrivateKey getUserKeyNameForLogin:self.username];
    NSString *patCer = [RSAPrivateKey getUserCertNameForLogin:self.username];

    for (NSString *fileName in directoryContent) {
        sharedFileNameKey = [fileName isEqualToString:patKey] ? fileName : sharedFileNameKey;
        sharedFileNameCer = [fileName isEqualToString:patCer] ? fileName : sharedFileNameCer;
        if (sharedFileNameKey != nil && sharedFileNameCer != nil) break;
    }

    if (!(sharedFileNameKey != nil && sharedFileNameCer != nil)) {
        return result;
    }

    NSString *path = [documentsDirectory stringByAppendingPathComponent:sharedFileNameKey];
    NSData *keyPEM = [[NSData alloc] initWithContentsOfFile:path];
    BOOL keyValid = keyPEM.length > 700;

    path = [documentsDirectory stringByAppendingPathComponent:sharedFileNameKey];
    NSData *cerPEM = [[NSData alloc] initWithContentsOfFile:path];
    BOOL cerValid = cerPEM.length > 700;

    result = keyValid && cerValid;

    return result;
}

- (NSString *)keySharedFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:sharedFileNameKey];
    return path;
}


- (NSString *)cerSharedFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:sharedFileNameCer];
    return path;
}


#define SAVE_SHARED_KEY_ALERT 10770

- (void)checkSharedKeysPromptPassword:(BOOL)first {

    NSString *localizedMessage, *message;

    NSString *messageAccept = @"Accept";
    NSString *messageDelete = @"Delete";
    if (first) {
        message = @"To save the private key on the device, enter your password and press \"%@\". To cancel press \"%@\"";
    } else {
        message = @"You have probably entered an incorrect password for private key. Check and enter the password again and press \"%@\". To cancel press \"%@ \"";
    }
    localizedMessage = [NSString stringWithFormat:message, messageAccept, messageDelete];


    UIAlertView *inputAlertView = [[UIAlertView alloc] initWithTitle:@"Input private key password to store"
                                                                           message:localizedMessage
                                                                          delegate:self
                                                                 cancelButtonTitle:messageAccept
                                                                 otherButtonTitles:messageDelete, nil];
    inputAlertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [[inputAlertView textFieldAtIndex:0] setSecureTextEntry:YES];
    inputAlertView.tag = SAVE_SHARED_KEY_ALERT;
    [inputAlertView show];
}

- (void)checkSharedKeysPromptPassword {
    [self checkSharedKeysPromptPassword:YES];
}

- (BOOL)checkSharedKeysPassword:(NSString *)password {
    BOOL result;
    NSData *keyPEM = [[NSData alloc] initWithContentsOfFile:[self keySharedFilePath]];
    result = [RSAPrivateKey checkPEM:keyPEM withPassword:password];
    return result;
}


- (void)deleteKeyAndCertFromDocuments {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self keySharedFilePath] error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:[self cerSharedFilePath] error:&error];

    sharedFileNameKey = nil;
    sharedFileNameCer = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self alertCertExpired];
    });
}

- (void)deleteUserKeys {
    NSString *certPath = [KEYSTORE_PATH stringByAppendingPathComponent:[RSAPrivateKey getUserCertNameForLogin:self.username]];
    NSString *keyPath = [KEYSTORE_PATH stringByAppendingPathComponent:[RSAPrivateKey getUserKeyNameForLogin:self.username]];
    NSError *error = nil;

    [[NSFileManager defaultManager] removeItemAtPath:certPath error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:keyPath error:&error];
}

- (NSString *)keyStoredFileNameShort {
    NSString *keyStoredFileName = [NSString stringWithFormat:@"%@_key.pem", self.username];
    return keyStoredFileName;
}

- (NSString *)cerStoredFileNameShort {
    NSString *cerStoredFileName = [NSString stringWithFormat:@"%@_cert.pem", self.username];
    return cerStoredFileName;
}

- (BOOL)copyKeyAndCertToKeystore {
    NSData *keyPEM = [[NSData alloc] initWithContentsOfFile:[self keySharedFilePath]];

    [keyPEM writeToKeystoreWithShortName:[self keyStoredFileNameShort]];

    NSData *cerPEM = [[NSData alloc] initWithContentsOfFile:[self cerSharedFilePath]];
    [cerPEM writeToKeystoreWithShortName:[self cerStoredFileNameShort]];

    [self deleteKeyAndCertFromDocuments];

    return YES;
}

#pragma mark AlertViewDelegate

#define KEYPASSWORD_MAX_TRY 3

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (SAVE_SHARED_KEY_ALERT == alertView.tag) {
        if (1 == buttonIndex /* delete*/) {
            [self deleteKeyAndCertFromDocuments];
        }
        if (0 == buttonIndex /* save*/) {
            NSString *password = [[alertView textFieldAtIndex:0] text];

            BOOL doSecond = stringIsBlankOrNil(password);

            if (!(doSecond)) doSecond = ![self checkSharedKeysPassword:password];

            if (doSecond) {
                if (keyPasswordCounter < KEYPASSWORD_MAX_TRY) {
                    keyPasswordCounter++;
                    [self checkSharedKeysPromptPassword:NO];
                } else {
                    ShowShortMessage(@"The number of attempts to enter valid password exceeded. Keys will be deleted");
                    [self deleteKeyAndCertFromDocuments];
                }
            } else {
                if ([self copyKeyAndCertToKeystore]) {
                    // store password
                    NSError *error = [[NSError alloc] init];
                    NSData  *digest = [RNEncryptor encryptData:[password dataUsingEncoding:NSUTF8StringEncoding]
                                                  withSettings:kRNCryptorAES256Settings
                                                      password:self.tempStoredPassword
                                                         error:&error];
                    self.tempStoredPassword = nil;

                    if(!error.code) {
                        [[NSUserDefaults standardUserDefaults] setObject:digest forKey:[self userKeyPasswordPattern:self.username]];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        ShowShortMessage(@"Keys saved successfully");
                    } else {
                        ShowShortMessage(@"Error saving private key password");
                    }
                }
            }
        }
    }
}


- (void)alertCertExpired {
    OpenSSLCertificate *cert = [self userCertificate];
    if (cert != nil) {
        if ([[cert dateNotAfter] timeIntervalSinceNow] < 1 * 3600 * 24 * 10) {
            NSString *message = [NSString stringWithFormat:@"Certificate \"%@\" will expire at %@",
                            cert.subject[@"commonName"],
                            cert.dateNotAfter.description];
            ShowShortMessage(message);
        }
    }
}


- (NSString *)signString:(NSString *)strToSign withPassword:(NSString *)pkPassword {
    NSString *result = nil;

    NSData *pkPEM = [[NSData alloc] initFromKeystoreWithShortName:[RSAPrivateKey getUserKeyNameForLogin:self.username]];
    @try {
        NSData *signData = [strToSign dataUsingEncoding:NSWindowsCP1251StringEncoding];
        result = [RSAPrivateKey signData:signData withPEM:pkPEM withPassword:pkPassword];
    }
    @finally {
    }

    return result;
}

- (OpenSSLCertificate *)userCertificate {
    if (![self isUserKeyExists]) return (OpenSSLCertificate * )nil;

    NSData *cerPEM = [[NSData alloc] initFromKeystoreWithShortName:[self cerStoredFileNameShort]];
    @try {
        OpenSSLCertificate *cert = [[OpenSSLCertificate alloc] initWithPEMdata:cerPEM];
        [OpenSSLSessionCertificate setCurrentUserCertificateFileName:[self cerStoredFileNameShort]];
        return cert;
    }
    @catch (...) {
        customLog(@"UNEXPECTED ERROR in %@", NSStringFromSelector(_cmd));
    }
    @finally {
    }
    return nil;
}

#endif

@end