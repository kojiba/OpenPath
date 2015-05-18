/**
 * Helper.h
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

#ifndef __HELPER_H__
#define __HELPER_H__

#define ShowShortMessage(text) [[[UIAlertView alloc] initWithTitle:text message:@"" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

#define stringIsBlankOrNil(string) (string == nil || [string isEqualToString:@""])

#define isMemEquals(first, second, size) (memcmp(first, second, size) == 0)

#endif /*__HELPER_H__*/