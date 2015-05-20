#ifndef __OPEN_SSL_SERVER_H__
#define __OPEN_SSL_SERVER_H__

#include <openssl/ssl.h>
#include <openssl/err.h>
#include "RSyntax.h"

void ShowCerts(SSL *ssl, rbool isServer);

void LoadCertificates(SSL_CTX *ctx, char const *CertFile, char const *KeyFile, char const *password);

void openSSLServerStart(char const *port, char const *certFilePath, char const *keyFilePath, char const *password);

#endif
