//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UserData : NSObject
+ (UserData *)sharedData;

-(BOOL)loginWithName:(NSString*)login password:(NSString*)password;

@end