//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "Listener.h"

#import "RSocket.h"
#import "Settings_Keys.h"


@implementation Listener {
    RSocket *socket;
}

+ (Listener *)sharedListener {
    static Listener *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

-(void)startListen {
    if(socket != nil) {
        close(socket->socket);
        deallocator(socket);
        socket = nil;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        char buffer[1500];

        socket = c(RSocket)(nil);
        $(socket, m(bindPort, RSocket)), PROTOCOL_PORT);

        $(socket, m(joinMulticastGroup, RSocket)), LOCAL_MULTICAST);

        while(1) {
            ssize_t length = $(socket, m(receive, RSocket)), buffer, 1500);
            __block char *tempData = (char *) getByteArrayCopy((byte const *) buffer, (size_t) length);

            if(length >= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.updateBlock(tempData, length, socket->packetCounter, 0, addressToString(&socket->address));
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.updateBlock(tempData, length, socket->packetCounter, networkOperationErrorConst, nil);
                });
                break;
            }
        }

        nilDeleter(socket, RSocket);
        socket = nil;
    });
}


@end