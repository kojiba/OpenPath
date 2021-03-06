#include "OpenSSLServer.h"
#include "Settings_Keys.h"

#define FAIL   -1

/*---------------------------------------------------------------------*/
/*--- OpenListener - create server socket                           ---*/
/*---------------------------------------------------------------------*/
int OpenListener(int port) {
    int sd;
    struct sockaddr_in addr = {};

    sd = socket(PF_INET, SOCK_STREAM, 0);
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sd, (struct sockaddr const *) &addr, sizeof(addr)) != 0) {
        perror("Can't bind port");
        return -1;
    }

    if (listen(sd, 10) != 0) {
        perror("Can't configure listening port");
        return -2;
    }
    return sd;
}

/*---------------------------------------------------------------------*/
/*--- InitServerCTX - initialize SSL server  and create context     ---*/
/*---------------------------------------------------------------------*/
SSL_CTX *InitServerCTX(void) {
    const SSL_METHOD *method;
    SSL_CTX *ctx;

    // create new server-method instance
    #ifdef PATH_USE_TLS
        method = TLSv1_2_server_method();
    #elif defined(PATH_USE_SSL)
        method = SSLv3_server_method();
    #endif

    ctx = SSL_CTX_new(method);            /* create new context from method */
    if (ctx == NULL) {
        ERR_print_errors_fp(stderr);
        return nil;
    }
    return ctx;
}

/*---------------------------------------------------------------------*/
/*--- LoadCertificates - load from files.                           ---*/
/*---------------------------------------------------------------------*/
char * LoadCertificates(SSL_CTX *ctx, char const *CertFile, char const *KeyFile, char const *password) {
    // set the local certificate from CertFile
    if (SSL_CTX_use_certificate_file(ctx, CertFile, SSL_FILETYPE_PEM) <= 0) {
        ERR_print_errors_fp(stderr);
        return "Can't load local certificate";
    }

    SSL_CTX_set_default_passwd_cb_userdata(ctx, (void *) password);

    // set the private key from KeyFile (may be the same as CertFile)
    if (SSL_CTX_use_PrivateKey_file(ctx, KeyFile, SSL_FILETYPE_PEM) <= 0) {
        ERR_print_errors_fp(stderr);
        return "Can't load private key";
    }

    // verify private key
    if (!SSL_CTX_check_private_key(ctx)) {
        fprintf(stderr, "Private key does not match the public certificate\n");
        return "Private key does not match the public certificate";
    }

    return nil;
}

/*---------------------------------------------------------------------*/
/*--- ShowCerts - print out certificates.                           ---*/
/*---------------------------------------------------------------------*/
void ShowCerts(SSL *ssl, rbool isServer) {
    X509 *cert;
    char *line;

    if(isServer) {
        printf("Server certificates:\n");
    } else {
        printf("Client certificates:\n");
    }

    cert = SSL_get_peer_certificate(ssl);    /* Get certificates (if available) */
    if (cert != NULL) {
        line = X509_NAME_oneline(X509_get_subject_name(cert), 0, 0);
        printf("Subject: %s\n", line);
        free(line);
        line = X509_NAME_oneline(X509_get_issuer_name(cert), 0, 0);
        printf("Issuer: %s\n", line);
        free(line);
        X509_free(cert);
    }
    else
        printf("No certificates.\n");
}

/*---------------------------------------------------------------------*/
/*--- Servlet - SSL servlet (contexts can be shared)                ---*/
/*---------------------------------------------------------------------*/
void serverServlet(SSL *ssl)    /* Serve the connection -- threadable */ {
    char buffer[1024];
    char responce[1024];
    int sd, bytes;
    const char *echo = "Welcome on openPath SSL server, echo : \"%s\"\n\n";

    if (SSL_accept(ssl) == FAIL)                    /* do SSL-protocol accept */
        ERR_print_errors_fp(stderr);
    else {
        ShowCerts(ssl, yes);                                /* get any certificates */

        bytes = SSL_read(ssl, buffer, sizeof(buffer));    /* get request */
        if (bytes > 0) {
            buffer[bytes] = 0;
            printf("Client msg: \"%s\"\n", buffer);
            sprintf(responce, echo, buffer);            /* construct responce */
            SSL_write(ssl, responce, (int) strlen(responce));    /* send responce */
        }
        else
            ERR_print_errors_fp(stderr);
    }
    sd = SSL_get_fd(ssl);      // get socket connection
    SSL_free(ssl);             // release SSL state
    close(sd);                 // close connection
}

/*---------------------------------------------------------------------*/
/*--- main - create SSL socket server.                              ---*/

/*---------------------------------------------------------------------*/
void openSSLServerStart(char const *port, char const *certFilePath, char const *keyFilePath, char const *password) {
    SSL_CTX *ctx;
    int server;

    ctx = InitServerCTX();
    LoadCertificates(ctx, certFilePath, keyFilePath, password);

    server = OpenListener(atoi(port)); // create server socket */

    printf("OpenPath SSL server started\n");

    while (1) {
        struct sockaddr_in addr;
        int len = sizeof(addr);
        SSL *ssl;

        int client = accept(server, &addr, &len);        /* accept connection as usual */
        printf("Connection: %s:%d\n",
                inet_ntoa(addr.sin_addr), ntohs(addr.sin_port));

        ssl = SSL_new(ctx);          /* get new SSL state with context */
        SSL_set_fd(ssl, client);      /* set connection socket to SSL state */
        serverServlet(ssl);                  /* service connection */
    }
    close(server);                                        /* close server socket */
    SSL_CTX_free(ctx);                                    /* release context */
}