//
//  NSData+Utils.h
//  MoldovaFoundation
//
//  Created by alexrush on 11/09/14.
//  Copyright (c) 2014 CSLTD. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Settings_Keys.h"

@interface NSData (Utils)

- (NSString *)base64EncodedString;

-(BOOL)writeToKeystoreWithShortName:(NSString*)fileShortName;
-(id)initFromKeystoreWithShortName:(NSString*)fileShortName;

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;
- (NSData *)AES128EncryptWithKey:(NSString *)key;
- (NSData *)AES128DecryptWithKey:(NSString *)key;
@end
