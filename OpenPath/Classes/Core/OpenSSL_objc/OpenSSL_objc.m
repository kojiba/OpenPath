//
//  CSOpenSSL.m
//  OpenSSL-for-iOS
//
//  Created by Alexander Pogulyaka on 1/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenSSL_objc.h"


void openSSLSturtup() {
    if (!ERR_reason_error_string((unsigned long) 218738701/* sample error (error parsing RSA private key) */)) {
        CRYPTO_malloc_init();
        ERR_load_crypto_strings();
        OpenSSL_add_all_algorithms();
        OpenSSL_add_all_digests();
        OpenSSL_add_all_ciphers();
    }
    ERR_clear_error();
}
