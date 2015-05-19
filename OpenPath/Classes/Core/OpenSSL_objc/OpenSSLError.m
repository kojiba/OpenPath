//
//  OpenSSLError.m
//  OpenSSL-for-iOS
//
//  Created by Alexander Pogulyaka on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenSSLError.h"


void checkOpenSSLError(NSString *context) {
    unsigned long errCode = ERR_get_error();
    if (errCode) {
        const char *errMsg = ERR_reason_error_string(errCode);
        NSException *e = [NSException exceptionWithName:[NSString stringWithFormat:@"OpenSSL Error \"%s\" while \"%@\" ", errMsg, context] reason:nil userInfo:nil];
        @throw e;
    }
}

BOOL openSSLError() {
    unsigned long errCode = ERR_get_error();
    return errCode != 0;
}

BOOL openSSLErrorCode(unsigned long *outErrorCode) {
    if (nil == outErrorCode) {
        return openSSLError();
    } else {
        *outErrorCode = ERR_get_error();
        if (*outErrorCode) {
        }
        return *outErrorCode != 0;
    }
}

