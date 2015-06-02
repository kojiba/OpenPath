#import <Foundation/Foundation.h>
#include <Openssl/err.h>

void checkOpenSSLError(NSString *context);

BOOL openSSLError();

BOOL openSSLErrorCode(unsigned long *outErrorCode);


