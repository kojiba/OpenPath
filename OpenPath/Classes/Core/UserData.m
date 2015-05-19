//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "UserData.h"
#import "Settings_Keys.h"
#import "Logger.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Helper.h"

@interface UserData()
@property (strong, nonatomic) NSString* username;

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

-(NSString*)userLoginPattern:(NSString*)login {
    return [NSString stringWithFormat:@"%@_%@", USER_NAME_KEY, login];
}

- (void)logout {
    [Logger addSessionEndStamp];
    // store logs and crypt some
}

- (BOOL)loginWithName:(NSString *)login password:(NSString *)password {
    id data = [[NSUserDefaults standardUserDefaults] objectForKey:[self userLoginPattern:login]];
    if(data != nil
            && [data isKindOfClass:[NSData class]]) {
        NSError *error = [[NSError alloc] init];
        // check if digest right, proof of decrypt
        NSData *check = [RNDecryptor decryptData:data withPassword:password error:&error];

        if(!error.code) {
            if ([check isEqualToData:[login dataUsingEncoding:NSUTF8StringEncoding]]) {
                srand((unsigned int) time(nil));
                self.username = login;

                [Logger addSessionStartStamp];
                // load some settings
                // decrypt some
                return YES;
            }
        }
    }
    return NO;
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

@end