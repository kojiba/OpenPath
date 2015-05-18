/**
 * OpenPathProtocol.h
 * Protocol control flags and utils.
 * Author Kucheruavyu Ilya (kojiba@ro.ru)
 * 05/18/2015 Ukraine Kharkiv
 *  _         _ _ _
 * | |       (_|_) |
 * | | _____  _ _| |__   __ _
 * | |/ / _ \| | | '_ \ / _` |
 * |   < (_) | | | |_) | (_| |
 * |_|\_\___/| |_|_.__/ \__,_|
 *          _/ |
 *         |__/
 **/

#ifndef __OPEN_PATH_PROTOCOL_H__
#define __OPEN_PATH_PROTOCOL_H__

//
// +----------------------+
// | 1 byte flag |   data |
// +----------------------+
//

#import "RByteOperations.h"

#define DEBUG_PRIVATE_HELLO_KEY @"it's true private key"

static const char pathHelloString[] = "HELLO MESSAGE, WHICH MUST BE DECRYPTED WHEN RECEIVED";

typedef enum OpenPathFlag {
    HelloPacketFlag = 20,
    DataPacketFlag,

    GetCertPackeFlag,
    CertPackeFlag,

    GetKeyPackeFlag,
    KeyPackeFlag,


} OpenPathFlag;

rbool canDecryptHello(const byte *buffer, size_t size, const byte *key, size_t keySize);

RByteArray * createHelloPacketWithKey(char *key, size_t size);


#endif /*__OPEN_PATH_PROTOCOL_H__*/