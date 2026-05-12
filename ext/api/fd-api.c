#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_ext.h"
#include "fd-api.h"
#include <fcntl.h>
#include <unistd.h>

int get_file_fd(zval *dp, zval *flags) {
    return open(Z_STRVAL_P(dp), (int) Z_LVAL_P(flags));
}

int close_fd(zval *fd) {
    return close((int) Z_LVAL_P(fd));
}

int add_fd_flags(zval *fd, zval *flags) {
    int current_flags = fcntl((int) Z_LVAL_P(fd), F_GETFL, 0);
    if (current_flags < 0) {
        return -1;
    }
    return fcntl((int) Z_LVAL_P(fd), F_SETFL, current_flags | (int) Z_LVAL_P(flags));
}

void read_fd(zval *return_value, zval *fd, zval *bytes_to_read) {
    size_t n   = (size_t) Z_LVAL_P(bytes_to_read);
    char  *buf = emalloc(n + 1);
    ssize_t read_n = read((int) Z_LVAL_P(fd), buf, n);
    if (read_n < 0) {
        efree(buf);
        ZVAL_EMPTY_STRING(return_value);
    } else {
        buf[read_n] = '\0';
        ZVAL_STRINGL(return_value, buf, (size_t) read_n);
        efree(buf);
    }
}

zend_long write_fd(zval *fd, zval *data, zval *bytes_to_write) {
    return (zend_long) write(
        (int)         Z_LVAL_P(fd),
        (const char*) Z_STRVAL_P(data),
        (size_t)      Z_LVAL_P(bytes_to_write)
    );
}
