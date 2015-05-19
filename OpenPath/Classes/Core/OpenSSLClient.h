#ifndef __OPEN_SSL_CLIENT_H__
#define __OPEN_SSL_CLIENT_H__

#include "OpenSSLServer.h"

void openSSLClientStart(char const *hostname, char const *port, char const *certFilePath, char const *keyFilePath, char const *password);

#endif
