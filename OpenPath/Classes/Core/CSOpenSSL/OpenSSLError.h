//
//  OpenSSLError.h
//  OpenSSL-for-iOS
//
//  Created by Alexander Pogulyaka on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Openssl/err.h>

void checkOpenSSLError(NSString *context);

BOOL openSSLError();

BOOL openSSLErrorCode(unsigned long *outErrorCode);


