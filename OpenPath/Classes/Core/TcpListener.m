//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "TcpListener.h"


@implementation TcpListener {

}

+ (TcpListener *)sharedListener {
    static TcpListener *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

-(void)startListen {

}

@end