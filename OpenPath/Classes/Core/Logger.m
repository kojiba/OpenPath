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
    NSDateFormatter *formatter= [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    customLog(@"---- Session start at %@ ----\n", [formatter stringFromDate:[NSDate date]]);
}

+(void)addSessionEndStamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    customLog(@"---- Session end at %@ ----\n", [formatter stringFromDate:[NSDate date]]);
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

#ifdef DEBUG
    NSLogv(message, argumentList);
#endif
    va_end(argumentList);
}

@end