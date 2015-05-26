/**
* Settings_Keys.h
* Some obj-c macro helper.
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

#ifndef __SETTINGS_KEYS_H__
#define __SETTINGS_KEYS_H__


//#define SELFTEST
#define HAVE_ITUNES_KEY_TRANSFER

#define PASSWORD_MIN_LENGTH 5

#define OPEN_SSL_SERVER_PORT "7777"

#define PROTOCOL_PORT   7777
#define LOCAL_MULTICAST "224.0.0.1"

#define USER_NAME_KEY     @"kUserName"
#define USER_KEY_PASSWORD @"kUserKeyPassword"

#define KEYSTORE_PATH ( [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Keystore"] )

#endif /*__SETTINGS_KEYS_H__*/