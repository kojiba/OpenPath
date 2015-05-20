//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "Listener.h"

#import "RSocket.h"
#import "Settings_Keys.h"


@implementation Listener {
    RSocket *socket;
    BOOL breakFlag;
}

+ (Listener *)sharedListener {
    static Listener *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
            _instance->breakFlag = NO;
        }
    }

    return _instance;
}

-(void)stopListen {
    breakFlag = YES;
    nilDeleter(socket, RSocket);
    socket = nil;
}

-(void)startListen {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        breakFlag = NO;
        char buffer[1500];

        socket = c(RSocket)(nil);
        $(socket, m(bindPort, RSocket)), PROTOCOL_PORT);
        $(socket, m(joinMulticastGroup, RSocket)), LOCAL_MULTICAST);

        while(!breakFlag) {
            ssize_t length = $(socket, m(receive, RSocket)), buffer, 1500);
            __block char *tempData = (char *) getByteArrayCopy((byte const *) buffer, (size_t) length);

            if(length < 0) {
                break;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(length >= 0) {
                    self.updateBlock(tempData, length, socket->packetCounter, 0, addressToString(&socket->address));
                } else {
                        self.updateBlock(tempData, length, socket->packetCounter, networkOperationErrorConst, nil);
                }
            });
        }
    });
}


@end