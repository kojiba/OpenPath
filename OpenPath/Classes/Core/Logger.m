//
// Created by Ilya Kucheruavyu on 5/19/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "Logger.h"

@interface Logger()
@property (strong, nonatomic) NSMutableString *fullLog;
@end

@implementation Logger {


}

+ (Logger *)sharedLogger {
    static Logger *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
            _instance.fullLog = [[NSMutableString alloc] initWithCapacity:10000];
        }
    }

    return _instance;
}

- (NSString *)getFullLog {
    return self.fullLog;
}

+(void)addSessionStartStamp {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDateFormatter *formatter;
        NSString        *dateString;

        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];

        dateString = [formatter stringFromDate:[NSDate date]];
        [[Logger sharedLogger].fullLog appendString:@"Session start at "];
        [[Logger sharedLogger].fullLog appendString:dateString];
        [[Logger sharedLogger].fullLog appendString:@"-------\n"];
    });
}

+(void)addSessionEndStamp {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSDateFormatter *formatter;
        NSString        *dateString;

        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];

        dateString = [formatter stringFromDate:[NSDate date]];
        [[Logger sharedLogger].fullLog appendString:@"Session end at "];
        [[Logger sharedLogger].fullLog appendString:dateString];
        [[Logger sharedLogger].fullLog appendString:@"-------\n"];
    });
}

void customLog(NSString *format, ...) {
    va_list argumentList;
    va_start(argumentList, format);

    NSMutableString * message = [[NSMutableString alloc] initWithFormat:format
                                                              arguments:argumentList];

    NSDateFormatter *formatter;
    NSString        *dateString;

    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];

    dateString = [formatter stringFromDate:[NSDate date]];

    [[Logger sharedLogger].fullLog appendString:@"["];
    [[Logger sharedLogger].fullLog appendString:dateString];
    [[Logger sharedLogger].fullLog appendString:@"] "];
    [[Logger sharedLogger].fullLog appendString:message];
    [[Logger sharedLogger].fullLog appendString:@"\n"];

//    NSLogv(message, argumentList);
    va_end(argumentList);
}

@end