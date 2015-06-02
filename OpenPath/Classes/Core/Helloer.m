//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "Helloer.h"
#import "RSocket.h"
#import "Settings_Keys.h"
#import "OpenPathProtocol.h"

@implementation Helloer {

}

+ (Helloer *)sharedHelloer {
    static Helloer *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (void)sendHelloWithDelay:(NSUInteger)seconds repeat:(NSUInteger)times key:(NSData*)key block:(HelloUpdateBlock)block {
    if(times != 0) {
        NSData *keyCopy = [key copy];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            size_t iterator;

            RByteArray *hello = createHelloPacketWithKey(keyCopy.bytes, keyCopy.length);

            RSocket *socket = c(RSocket)(nil);

            $(socket, m(setPort,    RSocket)), PROTOCOL_PORT);
            $(socket, m(setAddress, RSocket)), LOCAL_MULTICAST);

            forAll(iterator, times) {
                if($(socket, m(send, RSocket)), hello->array, hello->size) == networkOperationSuccessConst) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block(socket->packetCounter, 0);
                    });
                    sleep(seconds);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        block(socket->packetCounter, networkOperationErrorConst);
                    });
                }
            }

            deleter(socket, RSocket);
            deleter(hello, RByteArray);

        });
    }
}


@end