//
// Created by Ilya Kucheruavyu on 5/19/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Logger : NSObject

+ (Logger *)sharedLogger;

void customLog(NSString *format, ...);

-(NSString*)getFullLog;

+(void)addSessionStartStamp;
+(void)addSessionEndStamp;

@end