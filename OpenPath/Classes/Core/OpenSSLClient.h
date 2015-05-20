#ifndef __OPEN_SSL_CLIENT_H__
#define __OPEN_SSL_CLIENT_H__

#include "OpenSSLServer.h"

SSL_CTX *InitClientContext(void);
int      OpenClientConnection(const char *hostname, int port);

void openSSLClientStart(char const *hostname, char const *port, char const *certFilePath, char const *keyFilePath, char const *password);

#endif
