
#ifdef HAVE_CONFIG_H
#include "../ext_config.h"
#endif

#include <php.h>
#include "../php_ext.h"
#include "../ext.h"

#include <Zend/zend_operators.h>
#include <Zend/zend_exceptions.h>
#include <Zend/zend_interfaces.h>

#include "kernel/main.h"
#include "api/fd-api.h"
#include "kernel/operators.h"
#include "kernel/memory.h"
#include "kernel/object.h"
#include "kernel/string.h"


ZEPHIR_INIT_CLASS(Fd_FD)
{
	ZEPHIR_REGISTER_CLASS(Fd, FD, fd, fd, fd_fd_method_entry, 0);

	return SUCCESS;
}

PHP_METHOD(Fd_FD, open)
{
	zephir_method_globals *ZEPHIR_METHOD_GLOBALS_PTR = NULL;
	zend_long flags, result = 0;
	zval *device_path_param = NULL, *flags_param = NULL, dp, _0;
	zval device_path;

	ZVAL_UNDEF(&device_path);
	ZVAL_UNDEF(&dp);
	ZVAL_UNDEF(&_0);
	ZEND_PARSE_PARAMETERS_START(2, 2)
		Z_PARAM_STR(device_path)
		Z_PARAM_LONG(flags)
	ZEND_PARSE_PARAMETERS_END();
	ZEPHIR_METHOD_GLOBALS_PTR = pecalloc(1, sizeof(zephir_method_globals), 0);
	zephir_memory_grow_stack(ZEPHIR_METHOD_GLOBALS_PTR, __func__);
	zephir_fetch_params(1, 2, 0, &device_path_param, &flags_param);
	zephir_get_strval(&device_path, device_path_param);
	ZEPHIR_CPY_WRT(&dp, &device_path);
	ZVAL_LONG(&_0, flags);
	result = get_file_fd(&dp,&_0);
	RETURN_MM_LONG(result);
}

PHP_METHOD(Fd_FD, close)
{
	zval *_fd_param = NULL, _0;
	zend_long _fd, result = 0;

	ZVAL_UNDEF(&_0);
	ZEND_PARSE_PARAMETERS_START(1, 1)
		Z_PARAM_LONG(_fd)
	ZEND_PARSE_PARAMETERS_END();
	zephir_fetch_params_without_memory_grow(1, 0, &_fd_param);
	ZVAL_LONG(&_0, _fd);
	result = close_fd(&_0);
	RETURN_LONG(result);
}

PHP_METHOD(Fd_FD, addFlags)
{
	zval *_fd_param = NULL, *flags_param = NULL, _0, _1;
	zend_long _fd, flags, result = 0;

	ZVAL_UNDEF(&_0);
	ZVAL_UNDEF(&_1);
	ZEND_PARSE_PARAMETERS_START(2, 2)
		Z_PARAM_LONG(_fd)
		Z_PARAM_LONG(flags)
	ZEND_PARSE_PARAMETERS_END();
	zephir_fetch_params_without_memory_grow(2, 0, &_fd_param, &flags_param);
	ZVAL_LONG(&_0, _fd);
	ZVAL_LONG(&_1, flags);
	result = add_fd_flags(&_0, &_1);
	RETURN_LONG(result);
}

PHP_METHOD(Fd_FD, read)
{
	zephir_method_globals *ZEPHIR_METHOD_GLOBALS_PTR = NULL;
	zval *fd_param = NULL, *bytes_to_read_param = NULL, result, _0, _1;
	zend_long fd, bytes_to_read;

	ZVAL_UNDEF(&result);
	ZVAL_UNDEF(&_0);
	ZVAL_UNDEF(&_1);
	ZEND_PARSE_PARAMETERS_START(2, 2)
		Z_PARAM_LONG(fd)
		Z_PARAM_LONG(bytes_to_read)
	ZEND_PARSE_PARAMETERS_END();
	ZEPHIR_METHOD_GLOBALS_PTR = pecalloc(1, sizeof(zephir_method_globals), 0);
	zephir_memory_grow_stack(ZEPHIR_METHOD_GLOBALS_PTR, __func__);
	zephir_fetch_params(1, 2, 0, &fd_param, &bytes_to_read_param);
	ZVAL_LONG(&_0, fd);
	ZVAL_LONG(&_1, bytes_to_read);
	ZEPHIR_INIT_VAR(&result);
	read_fd(&result, &_0, &_1);
	RETURN_CCTOR(&result);
}

PHP_METHOD(Fd_FD, write)
{
	zephir_method_globals *ZEPHIR_METHOD_GLOBALS_PTR = NULL;
	zval data;
	zval *fd_param = NULL, *data_param = NULL, *bytes_to_write_param = NULL, _0, _1;
	zend_long fd, bytes_to_write, results = 0;

	ZVAL_UNDEF(&_0);
	ZVAL_UNDEF(&_1);
	ZVAL_UNDEF(&data);
	ZEND_PARSE_PARAMETERS_START(3, 3)
		Z_PARAM_LONG(fd)
		Z_PARAM_STR(data)
		Z_PARAM_LONG(bytes_to_write)
	ZEND_PARSE_PARAMETERS_END();
	ZEPHIR_METHOD_GLOBALS_PTR = pecalloc(1, sizeof(zephir_method_globals), 0);
	zephir_memory_grow_stack(ZEPHIR_METHOD_GLOBALS_PTR, __func__);
	zephir_fetch_params(1, 3, 0, &fd_param, &data_param, &bytes_to_write_param);
	zephir_get_strval(&data, data_param);
	ZVAL_LONG(&_0, fd);
	ZVAL_LONG(&_1, bytes_to_write);
	results = write_fd(&_0, &data, &_1);
	RETURN_MM_LONG(results);
}

