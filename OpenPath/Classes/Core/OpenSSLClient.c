#include "OpenSSLClient.h"

#include <unistd.h>
#include <sys/socket.h>
#include <resolv.h>
#include <netdb.h>

#define FAIL    -1

/*---------------------------------------------------------------------*/
/*--- OpenConnection - create socket and connect to server.         ---*/
/*---------------------------------------------------------------------*/
int OpenConnection(const char *hostname, int port) {
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
//        abort();
    }
    return sd;
}

/*---------------------------------------------------------------------*/
/*--- InitCTX - initialize the SSL engine.                          ---*/
/*---------------------------------------------------------------------*/
SSL_CTX *InitCTX(void) {
    const SSL_METHOD *method;
    SSL_CTX *ctx;

    method = SSLv23_client_method();     // Create new client-method instance
    ctx = SSL_CTX_new(method);          // Create new context
    if (ctx == NULL) {
        ERR_print_errors_fp(stderr);
//        abort();
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

    ctx = InitCTX();
    LoadCertificates(ctx, certFilePath, keyFilePath, password);

    server = OpenConnection(hostname, atoi(port));
    ssl = SSL_new(ctx);
    /* create new SSL connection state */
    SSL_set_fd(ssl, server
    );                /* attach the socket descriptor */
    if (
            SSL_connect(ssl)
                    == FAIL)
    /* perform the connection */
        ERR_print_errors_fp(stderr);
    else {
        char *msg = "Hello???";

        printf("Connected with %s encryption\n", SSL_get_cipher(ssl)
        );
        ShowCerts(ssl);
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