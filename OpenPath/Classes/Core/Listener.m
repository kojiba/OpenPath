//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "Listener.h"

#import "RSocket.h"
#import "Settings_Keys.h"


@implementation Listener {

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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        char buffer[1500];

        RSocket *receiver = c(RSocket)(nil);
        $(receiver, m(bindPort, RSocket)), PROTOCOL_PORT);

        $(receiver, m(joinMulticastGroup, RSocket)), LOCAL_MULTICAST);

        while(1) {
            ssize_t length = $(receiver, m(receive, RSocket)), buffer, 1500);
            __block char *tempData = (char *) getByteArrayCopy((byte const *) buffer, (size_t) length);

            if(length >= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.updateBlock(tempData, length, receiver->packetCounter, 0, addressToString(&receiver->address));
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.updateBlock(tempData, length, receiver->packetCounter, networkOperationErrorConst, nil);
                });
                break;
            }
        }

        deleter(receiver, RSocket);
    });
}


@end