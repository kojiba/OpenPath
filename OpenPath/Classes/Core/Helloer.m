//
// Created by Ilya Kucheruavyu on 5/18/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "Helloer.h"
#import "RSocket.h"

#define LOCAL_MULTICAST "224.0.0.1"

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

- (void)sendHelloWithDelay:(NSUInteger)seconds repeat:(NSUInteger)times logTextView:(UITextView*)log {
    if(times != 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /* Код, который должен выполниться в фоне */
            size_t iterator;

            RSocket *socket = c(RSocket)(nil);

            $(socket, m(setPort,         RSocket)), 8888);
            $(socket, m(setAddress,      RSocket)), LOCAL_MULTICAST);
            forAll(iterator, times) {
                if($(socket, m(send, RSocket)), "Some udp multicast for hello bro", sizeof("Some udp multicast for hello bro")) == networkOperationSuccessConst) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        /* Код, который выполниться в главном потоке */
                        log.text = [log.text stringByAppendingString:[NSString stringWithFormat:@"Sended hello packet, total packets %lu\n",socket->packetCounter]];
                    });
                    sleep(seconds);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        /* Код, который выполниться в главном потоке */
                        log.text = [log.text stringByAppendingString:[NSString stringWithFormat:@"Error send packet!\n"]];
                    });
                }
            }

            deleter(socket, RSocket);

        });
    }
}


@end