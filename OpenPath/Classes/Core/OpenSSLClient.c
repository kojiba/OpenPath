#include "OpenSSLClient.h"
#include "Settings_Keys.h"

#include <unistd.h>
#include <sys/socket.h>
#include <resolv.h>
#include <netdb.h>

#define FAIL    -1

/*---------------------------------------------------------------------*/
/*--- OpenConnection - create socket and connect to server.         ---*/
/*---------------------------------------------------------------------*/
int OpenClientConnection(const char *hostname, int port) {
    int sd;
    struct hostent *host;
    struct sockaddr_in addr;

    if ((host = gethostbyname(hostname)) == NULL) {
        perror(hostname);
        abort();
    }
    sd = socket(PF_INET, SOCK_STREAM, 0);
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = *(long *) (host->h_addr);
    if (connect(sd, &addr, sizeof(addr)) != 0) {
        close(sd);
        perror(hostname);
        return -1;
    }
    return sd;
}

SSL_CTX *InitClientContext(void) {
    const SSL_METHOD *method;
    SSL_CTX *ctx;

    // Create new client-method instance
    #ifdef PATH_USE_TLS
        method = TLSv1_2_client_method();
    #elif defined(PATH_USE_SSL)
        method = SSLv3_client_method();
    #endif
    ctx = SSL_CTX_new(method);         // Create new context
    if (ctx == NULL) {
        ERR_print_errors_fp(stderr);
        return nil;
    }
    return ctx;
}

/*---------------------------------------------------------------------*/
/*--- main - create SSL context and connect                         ---*/
/*---------------------------------------------------------------------*/
void openSSLClientStart(char const *hostname, char const *port, char const *certFilePath, char const *keyFilePath, char const *password) {
    SSL_CTX *ctx;
    int server;
    SSL *ssl;
    char buf[1024];
    int bytes;

    ctx = InitClientContext();
    LoadCertificates(ctx, certFilePath, keyFilePath, password);

    server = OpenClientConnection(hostname, atoi(port));
    ssl = SSL_new(ctx);
    /* create new SSL connection state */
    SSL_set_fd(ssl, server); /* attach the socket descriptor */
    if (SSL_connect(ssl) == FAIL) {
        ERR_print_errors_fp(stderr);
    } else {
        char *msg = "Hello???";

        printf("Connected with %s encryption\n", SSL_get_cipher(ssl));

        ShowCerts(ssl, no);
        /* get any certs */
        SSL_write(ssl, msg, (int) strlen(msg));
        /* encrypt & send message */
        bytes = SSL_read(ssl, buf, sizeof(buf));
        /* get reply & decrypt */
        buf[bytes] = 0;
        printf("Received: \"%s\"\n", buf);
        SSL_free(ssl);                                /* release connection state */
    }
    close(server);
    /* close socket */
    SSL_CTX_free(ctx);                                /* release context */
}