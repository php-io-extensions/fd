
/* This file was generated automatically by Zephir do not modify it! */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <php.h>

#include "php_ext.h"
#include "fd.h"

#include <ext/standard/info.h>

#include <Zend/zend_operators.h>
#include <Zend/zend_exceptions.h>
#include <Zend/zend_interfaces.h>

#include "kernel/globals.h"
#include "kernel/main.h"
#include "kernel/fcall.h"
#include "kernel/memory.h"



zend_class_entry *fd_fd_ce;

ZEND_DECLARE_MODULE_GLOBALS(fd)

PHP_INI_BEGIN()
	
PHP_INI_END()

static PHP_MINIT_FUNCTION(fd)
{
	REGISTER_INI_ENTRIES();
	zephir_module_init();
	ZEPHIR_INIT(Fd_FD);
	
	return SUCCESS;
}

#ifndef ZEPHIR_RELEASE
static PHP_MSHUTDOWN_FUNCTION(fd)
{
	
	zephir_deinitialize_memory();
	UNREGISTER_INI_ENTRIES();
	return SUCCESS;
}
#endif

/**
 * Initialize globals on each request or each thread started
 */
static void php_zephir_init_globals(zend_fd_globals *fd_globals)
{
	fd_globals->initialized = 0;

	/* Cache Enabled */
	fd_globals->cache_enabled = 1;

	/* Recursive Lock */
	fd_globals->recursive_lock = 0;

	/* Static cache */
	memset(fd_globals->scache, '\0', sizeof(zephir_fcall_cache_entry*) * ZEPHIR_MAX_CACHE_SLOTS);

	
	
}

/**
 * Initialize globals only on each thread started
 */
static void php_zephir_init_module_globals(zend_fd_globals *fd_globals)
{
	
}

static PHP_RINIT_FUNCTION(fd)
{
	zend_fd_globals *fd_globals_ptr;
	fd_globals_ptr = ZEPHIR_VGLOBAL;

	php_zephir_init_globals(fd_globals_ptr);
	zephir_initialize_memory(fd_globals_ptr);

	
	return SUCCESS;
}

static PHP_RSHUTDOWN_FUNCTION(fd)
{
	
	zephir_deinitialize_memory();
	return SUCCESS;
}



static PHP_MINFO_FUNCTION(fd)
{
	php_info_print_box_start(0);
	php_printf("%s", PHP_FD_DESCRIPTION);
	php_info_print_box_end();

	php_info_print_table_start();
	php_info_print_table_header(2, PHP_FD_NAME, "enabled");
	php_info_print_table_row(2, "Author", PHP_FD_AUTHOR);
	php_info_print_table_row(2, "Version", PHP_FD_VERSION);
	php_info_print_table_row(2, "Build Date", __DATE__ " " __TIME__ );
	php_info_print_table_row(2, "Powered by Zephir", "Version " PHP_FD_ZEPVERSION);
	php_info_print_table_end();
	
	DISPLAY_INI_ENTRIES();
}

static PHP_GINIT_FUNCTION(fd)
{
#if defined(COMPILE_DL_FD) && defined(ZTS)
	ZEND_TSRMLS_CACHE_UPDATE();
#endif

	php_zephir_init_globals(fd_globals);
	php_zephir_init_module_globals(fd_globals);
}

static PHP_GSHUTDOWN_FUNCTION(fd)
{
	
}


zend_function_entry php_fd_functions[] = {
	ZEND_FE_END

};

static const zend_module_dep php_fd_deps[] = {
	
	ZEND_MOD_END
};

zend_module_entry fd_module_entry = {
	STANDARD_MODULE_HEADER_EX,
	NULL,
	php_fd_deps,
	PHP_FD_EXTNAME,
	php_fd_functions,
	PHP_MINIT(fd),
#ifndef ZEPHIR_RELEASE
	PHP_MSHUTDOWN(fd),
#else
	NULL,
#endif
	PHP_RINIT(fd),
	PHP_RSHUTDOWN(fd),
	PHP_MINFO(fd),
	PHP_FD_VERSION,
	ZEND_MODULE_GLOBALS(fd),
	PHP_GINIT(fd),
	PHP_GSHUTDOWN(fd),
#ifdef ZEPHIR_POST_REQUEST
	PHP_PRSHUTDOWN(fd),
#else
	NULL,
#endif
	STANDARD_MODULE_PROPERTIES_EX
};

/* implement standard "stub" routine to introduce ourselves to Zend */
#ifdef COMPILE_DL_FD
# ifdef ZTS
ZEND_TSRMLS_CACHE_DEFINE()
# endif
ZEND_GET_MODULE(fd)
#endif
