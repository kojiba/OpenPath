//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PASSWORD_MIN_LENGTH 5

@interface UserData : NSObject
+ (UserData *)sharedData;

-(NSString*)createUserWithLogin:(NSString*)login password:(NSString*)password;
-(BOOL)loginWithName:(NSString*)login password:(NSString*)password;
-(void)logout;

@end