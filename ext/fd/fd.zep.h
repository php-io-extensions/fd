
extern zend_class_entry *fd_fd_ce;

ZEPHIR_INIT_CLASS(Fd_FD);

PHP_METHOD(Fd_FD, open);
PHP_METHOD(Fd_FD, close);
PHP_METHOD(Fd_FD, addFlags);
PHP_METHOD(Fd_FD, read);
PHP_METHOD(Fd_FD, write);

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_fd_fd_open, 0, 2, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, device_path, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, flags, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_fd_fd_close, 0, 1, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, _fd, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_fd_fd_addflags, 0, 2, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, _fd, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, flags, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_fd_fd_read, 0, 2, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, fd, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, bytes_to_read, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(arginfo_fd_fd_write, 0, 3, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, fd, IS_LONG, 0)
	ZEND_ARG_TYPE_INFO(0, data, IS_STRING, 0)
	ZEND_ARG_TYPE_INFO(0, bytes_to_write, IS_LONG, 0)
ZEND_END_ARG_INFO()

ZEPHIR_INIT_FUNCS(fd_fd_method_entry) {
	PHP_ME(Fd_FD, open, arginfo_fd_fd_open, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	PHP_ME(Fd_FD, close, arginfo_fd_fd_close, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	PHP_ME(Fd_FD, addFlags, arginfo_fd_fd_addflags, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	PHP_ME(Fd_FD, read, arginfo_fd_fd_read, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	PHP_ME(Fd_FD, write, arginfo_fd_fd_write, ZEND_ACC_PUBLIC|ZEND_ACC_STATIC)
	PHP_FE_END
};
