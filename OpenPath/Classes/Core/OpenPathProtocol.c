/**
 * OpenPathProtocol.c
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

#include "OpenPathProtocol.h"
#include "Helper.h"

rbool canDecryptHello(const byte *buffer, size_t size, const byte *key, size_t keySize) {
    rbool result = no;
    if(size == (sizeof(pathHelloString))) {
        byte *copy = getByteArrayCopy(buffer, size);
        if (copy != nil) {
            Xor(copy, (pointer const) key, size, keySize);
            // check if first 5 bytes is hello (proof of decrypt)
//            FIXME
            if(isMemEquals(copy + 1, pathHelloString, sizeof(pathHelloString) - 1)) {
                result = yes;
            }
            // check first byte
            result = (rbool) (result && copy[0] == HelloPacketFlag);
            deallocator(copy);
        }
    }
    return result;
}

RByteArray * createHelloPacketWithKey(char *key, size_t size) {
    RByteArray *result = makeRByteArray(sizeof(pathHelloString));
    if(result != nil) {
        result->array[0] = HelloPacketFlag;
        RMemCpy(result->array + 1, pathHelloString, sizeof(pathHelloString) - 1);
        Xor(result->array, (pointer const) key, sizeof(pathHelloString), size);
    }
    return result;
}
