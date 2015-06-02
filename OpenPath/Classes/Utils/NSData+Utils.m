//
//  NSData+Utils.m
//  MoldovaFoundation
//
//  Created by alexrush on 11/09/14.
//  Copyright (c) 2014 CSLTD. All rights reserved.
//

#import "NSData+Utils.h"
#import <CommonCrypto/CommonCryptor.h>

//
// Mapping from 6 bit pattern to ASCII character.
//
static unsigned char base64EncodeLookup[65] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

//
// Definition for "masked-out" areas of the base64DecodeLookup mapping
//
#define xx 65

//
// Mapping from ASCII character to 6 bit pattern.
//
static unsigned char base64DecodeLookup[256] =
        {
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 62, xx, xx, xx, 63,
                52, 53, 54, 55, 56, 57, 58, 59, 60, 61, xx, xx, xx, xx, xx, xx,
                xx, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
                15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, xx, xx, xx, xx, xx,
                xx, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
                41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
                xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
        };

//
// Fundamental sizes of the binary and base64 encode/decode units in bytes
//
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

//
// NewBase64Decode
//
// Decodes the base64 ASCII string in the inputBuffer to a newly malloced
// output buffer.
//
//  inputBuffer - the source ASCII string for the decode
//	length - the length of the string or -1 (to specify strlen should be used)
//	outputLength - if not-NULL, on output will contain the decoded length
//
// returns the decoded buffer. Must be free'd by caller. Length is given by
//	outputLength.
//
void *NewBase64Decode(
        const char *inputBuffer,
        size_t length,
        size_t *outputLength) {
    if (length == -1) {
        length = strlen(inputBuffer);
    }

    size_t outputBufferSize =
            ((length + BASE64_UNIT_SIZE - 1) / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE;
    unsigned char *outputBuffer = (unsigned char *) malloc(outputBufferSize);

    size_t i = 0;
    size_t j = 0;
    while (i < length) {
        //
        // Accumulate 4 valid characters (ignore everything else)
        //
        unsigned char accumulated[BASE64_UNIT_SIZE];
        size_t accumulateIndex = 0;
        while (i < length) {
            unsigned char decode = base64DecodeLookup[inputBuffer[i++]];
            if (decode != xx) {
                accumulated[accumulateIndex] = decode;
                accumulateIndex++;

                if (accumulateIndex == BASE64_UNIT_SIZE) {
                    break;
                }
            }
        }

        //
        // Store the 6 bits from each of the 4 characters as 3 bytes
        //
        // (Uses improved bounds checking suggested by Alexandre Colucci)
        //
        if (accumulateIndex >= 2)
            outputBuffer[j] = (accumulated[0] << 2) | (accumulated[1] >> 4);
        if (accumulateIndex >= 3)
            outputBuffer[j + 1] = (accumulated[1] << 4) | (accumulated[2] >> 2);
        if (accumulateIndex >= 4)
            outputBuffer[j + 2] = (accumulated[2] << 6) | accumulated[3];
        j += accumulateIndex - 1;
    }

    if (outputLength) {
        *outputLength = j;
    }
    return outputBuffer;
}

//
// NewBase64Encode
//
// Encodes the arbitrary data in the inputBuffer as base64 into a newly malloced
// output buffer.
//
//  inputBuffer - the source data for the encode
//	length - the length of the input in bytes
//  separateLines - if zero, no CR/LF characters will be added. Otherwise
//		a CR/LF pair will be added every 64 encoded chars.
//	outputLength - if not-NULL, on output will contain the encoded length
//		(not including terminating 0 char)
//
// returns the encoded buffer. Must be free'd by caller. Length is given by
//	outputLength.
//
char *NewBase64Encode(
        const void *buffer,
        size_t length,
        bool separateLines,
        size_t *outputLength) {
    const unsigned char *inputBuffer = (const unsigned char *) buffer;

#define MAX_NUM_PADDING_CHARS 2
#define OUTPUT_LINE_LENGTH 64
#define INPUT_LINE_LENGTH ((OUTPUT_LINE_LENGTH / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE)
#define CR_LF_SIZE 2

    //
    // Byte accurate calculation of final buffer size
    //
    size_t outputBufferSize =
            ((length / BINARY_UNIT_SIZE)
                    + ((length % BINARY_UNIT_SIZE) ? 1 : 0))
                    * BASE64_UNIT_SIZE;
    if (separateLines) {
        outputBufferSize +=
                (outputBufferSize / OUTPUT_LINE_LENGTH) * CR_LF_SIZE;
    }

    //
    // Include space for a terminating zero
    //
    outputBufferSize += 1;

    //
    // Allocate the output buffer
    //
    char *outputBuffer = (char *) malloc(outputBufferSize);
    if (!outputBuffer) {
        return NULL;
    }

    size_t i = 0;
    size_t j = 0;
    const size_t lineLength = separateLines ? INPUT_LINE_LENGTH : length;
    size_t lineEnd = lineLength;

    while (true) {
        if (lineEnd > length) {
            lineEnd = length;
        }

        for (; i + BINARY_UNIT_SIZE - 1 < lineEnd; i += BINARY_UNIT_SIZE) {
            //
            // Inner loop: turn 48 bytes into 64 base64 characters
            //
            outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
            outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                    | ((inputBuffer[i + 1] & 0xF0) >> 4)];
            outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)
                    | ((inputBuffer[i + 2] & 0xC0) >> 6)];
            outputBuffer[j++] = base64EncodeLookup[inputBuffer[i + 2] & 0x3F];
        }

        if (lineEnd == length) {
            break;
        }

        //
        // Add the newline
        //
        outputBuffer[j++] = '\r';
        outputBuffer[j++] = '\n';
        lineEnd += lineLength;
    }

    if (i + 1 < length) {
        //
        // Handle the single '=' case
        //
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
        outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                | ((inputBuffer[i + 1] & 0xF0) >> 4)];
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i + 1] & 0x0F) << 2];
        outputBuffer[j++] = '=';
    }
    else if (i < length) {
        //
        // Handle the double '=' case
        //
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
        outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
        outputBuffer[j++] = '=';
        outputBuffer[j++] = '=';
    }
    outputBuffer[j] = 0;

    //
    // Set the output length and return the buffer
    //
    if (outputLength) {
        *outputLength = j;
    }
    return outputBuffer;
}


@implementation NSData (Utils)

- (NSString *)base64EncodedString {
    size_t outputLength;
    char *outputBuffer =
            NewBase64Encode([self bytes], [self length], false, &outputLength);

    NSString *result = [[[NSString alloc] initWithBytes:outputBuffer
                                                 length:outputLength
                                               encoding:NSASCIIStringEncoding]
            autorelease];
    free(outputBuffer);
    return result;
}

- (BOOL)writeToKeystoreWithShortName:(NSString *)fileShortName {
    NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString *store = KEYSTORE_PATH;
    if (NO == [filemgr fileExistsAtPath:store]) {
        [filemgr createDirectoryAtPath:store
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    }
    return [self writeToFile:[KEYSTORE_PATH stringByAppendingPathComponent:fileShortName]
                  atomically:YES];
}

- (id)initFromKeystoreWithShortName:(NSString *)fileShortName {
    NSError *error = nil;
    NSString *path = [KEYSTORE_PATH stringByAppendingPathComponent:fileShortName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        self = [self initWithContentsOfFile:path
                                    options:NSDataReadingUncached
                                      error:&error];
    } else {
        [self release];
        self = nil;
    }
    return self;
}

- (NSData *)AES256EncryptWithKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    NSUInteger dataLength = [self length];

    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
            keyPtr, kCCKeySizeAES256,
            NULL /* initialization vector (optional) */,
            [self bytes], dataLength, /* input */
            buffer, bufferSize, /* output */
            &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }

    free(buffer); //free the buffer;
    return nil;
}

- (NSData *)AES256DecryptWithKey:(NSString *)key {
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    NSUInteger dataLength = [self length];

    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
            keyPtr, kCCKeySizeAES256,
            NULL /* initialization vector (optional) */,
            [self bytes], dataLength, /* input */
            buffer, bufferSize, /* output */
            &numBytesDecrypted);

    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }

    free(buffer); //free the buffer;
    return nil;
}

- (NSData *)AES128EncryptWithKey:(NSString *)key {
    // 'key' should be 16 bytes for AES128, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES128 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    NSUInteger dataLength = [self length];

    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
            keyPtr, kCCKeySizeAES128,
            NULL /* initialization vector (optional) */,
            [self bytes], dataLength, /* input */
            buffer, bufferSize, /* output */
            &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }

    free(buffer); //free the buffer;
    return nil;
}

- (NSData *)AES128DecryptWithKey:(NSString *)key {
    // 'key' should be 16 bytes for AES128, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES128 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)

    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];

    NSUInteger dataLength = [self length];

    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode,
            keyPtr, kCCKeySizeAES128,
            NULL /* initialization vector (optional) */,
            [self bytes], dataLength, /* input */
            buffer, bufferSize, /* output */
            &numBytesDecrypted);

    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }

    free(buffer); //free the buffer;
    return nil;
}

@end
