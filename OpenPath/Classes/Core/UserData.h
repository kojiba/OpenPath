//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings_Keys.h"
#import "OpenSSLCertificate.h"

#define PASSWORD_MIN_LENGTH 5

@interface UserData : NSObject
+ (UserData *)sharedData;
-(NSString*)userPasswordKey;

-(NSString *)currentUserName;
-(NSString*)createUserWithLogin:(NSString*)login password:(NSString*)password;
-(BOOL)loginWithName:(NSString*)login password:(NSString*)password;
-(void)logout;

#ifdef HAVE_ITUNES_KEY_TRANSFER

-(BOOL)isUserKeyExists;
-(BOOL)checkUserKeyPassword:(NSString*)password;
-(NSString*)keyStoredFileNameShort;
-(NSString*)cerStoredFileNameShort;
-(void)alertCertExpired;
-(NSString*)signString:(NSString*)strToSign withPassword:(NSString*)pkPassword;
-(OpenSSLCertificate*)userCertificate;
-(void) deleteUserKeys;

@property (nonatomic, readonly) NSString* getCAName;
@property (nonatomic, readonly) NSString* getTransportName;
@property (nonatomic, readonly) NSString* keyStoredFileNameShort;
@property (nonatomic, readonly) NSString* cerStoredFileNameShort;

#endif

@end