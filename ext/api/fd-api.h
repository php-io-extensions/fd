#ifndef PHP_FD_API_H
#define PHP_FD_API_H

#include "php.h"

int      get_file_fd(zval *device_path, zval *flags);
int      close_fd(zval *fd);
int      add_fd_flags(zval *fd, zval *flags);
void     read_fd(zval *return_value, zval *fd, zval *bytes_to_read);
zend_long write_fd(zval *fd, zval *data, zval *bytes_to_write);

#endif /* PHP_FD_API_H */
