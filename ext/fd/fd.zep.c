
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
#include "kernel/operators.h"
#include "kernel/memory.h"
#include "kernel/object.h"

#include <fcntl.h>
#include <unistd.h>



ZEPHIR_INIT_CLASS(Fd_FD)
{
	ZEPHIR_REGISTER_CLASS(Fd, FD, fd, fd, fd_fd_method_entry, 0);

	return SUCCESS;
}

PHP_METHOD(Fd_FD, open)
{
	zephir_method_globals *ZEPHIR_METHOD_GLOBALS_PTR = NULL;
	zend_long flags, result = 0;
	zval *device_path_param = NULL, *flags_param = NULL, dp;
	zval device_path;

	ZVAL_UNDEF(&device_path);
	ZVAL_UNDEF(&dp);
	ZEND_PARSE_PARAMETERS_START(2, 2)
		Z_PARAM_STR(device_path)
		Z_PARAM_LONG(flags)
	ZEND_PARSE_PARAMETERS_END();
	ZEPHIR_METHOD_GLOBALS_PTR = pecalloc(1, sizeof(zephir_method_globals), 0);
	zephir_memory_grow_stack(ZEPHIR_METHOD_GLOBALS_PTR, __func__);
	zephir_fetch_params(1, 2, 0, &device_path_param, &flags_param);
	zephir_get_strval(&device_path, device_path_param);
	ZEPHIR_CPY_WRT(&dp, &device_path);
	
            result = open(Z_STRVAL_P(&dp), (int) flags);
        
	RETURN_MM_LONG(result);
}

PHP_METHOD(Fd_FD, close)
{
	zval *_fd_param = NULL;
	zend_long _fd, result = 0;

	ZEND_PARSE_PARAMETERS_START(1, 1)
		Z_PARAM_LONG(_fd)
	ZEND_PARSE_PARAMETERS_END();
	zephir_fetch_params_without_memory_grow(1, 0, &_fd_param);
	
            result = close((int) _fd);
        
	RETURN_LONG(result);
}

PHP_METHOD(Fd_FD, addFlags)
{
	zval *_fd_param = NULL, *flags_param = NULL;
	zend_long _fd, flags, result = 0;

	ZEND_PARSE_PARAMETERS_START(2, 2)
		Z_PARAM_LONG(_fd)
		Z_PARAM_LONG(flags)
	ZEND_PARSE_PARAMETERS_END();
	zephir_fetch_params_without_memory_grow(2, 0, &_fd_param, &flags_param);
	
            int current_flags;
            
            // Get current file descriptor flags
            current_flags = fcntl(_fd, F_GETFL, 0);
            
            if (current_flags < 0) {
                result = -1;
            } else {
                // OR in the new flags and set them
                result = fcntl(_fd, F_SETFL, current_flags | flags);
            }
        
	RETURN_LONG(result);
}

PHP_METHOD(Fd_FD, read)
{
	zval *fd_param = NULL, *bytes_to_read_param = NULL, result;
	zend_long fd, bytes_to_read;

	ZVAL_UNDEF(&result);
	ZEND_PARSE_PARAMETERS_START(2, 2)
		Z_PARAM_LONG(fd)
		Z_PARAM_LONG(bytes_to_read)
	ZEND_PARSE_PARAMETERS_END();
	zephir_fetch_params_without_memory_grow(2, 0, &fd_param, &bytes_to_read_param);
	
            char *_buf = emalloc((size_t) bytes_to_read + 1);
            ssize_t _n = read((int) fd, _buf, (size_t) bytes_to_read);

            if (_n < 0) {
                efree(_buf);
                ZVAL_EMPTY_STRING(&result);
            } else {
                _buf[_n] = '\0';
                ZVAL_STRINGL(&result, _buf, (size_t) _n);
                efree(_buf);
            }
        
	RETURN_CCTORW(&result);
}

PHP_METHOD(Fd_FD, write)
{
	zephir_method_globals *ZEPHIR_METHOD_GLOBALS_PTR = NULL;
	zval data;
	zval *fd_param = NULL, *data_param = NULL, *bytes_to_write_param = NULL;
	zend_long fd, bytes_to_write, results = 0;

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
	
            results = (zend_long) write((int) fd, (const char *) Z_STRVAL(data), (size_t) bytes_to_write);
        
	RETURN_MM_LONG(results);
}

