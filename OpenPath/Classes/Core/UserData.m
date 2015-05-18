//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "UserData.h"
#import "Settings_Keys.h"


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

- (BOOL)loginWithName:(NSString *)login password:(NSString *)password {
    if([[NSUserDefaults standardUserDefaults] objectForKey:[self userLoginPattern:login]] != nil) {
        // load some settings
        // decrypt some
        return YES;
    }
    return NO;
}

- (BOOL)createUserWithLogin:(NSString *)login password:(NSString *)password {
    if([[NSUserDefaults standardUserDefaults] objectForKey:[self userLoginPattern:login]] == nil) {
        // save some settings
        // encrypted with password
//    [[NSUserDefaults standardUserDefaults] setObject:settings objectForKey:[self userLoginPattern:login]];
        return YES;
    } else {
        return NO;
    }
}

@end