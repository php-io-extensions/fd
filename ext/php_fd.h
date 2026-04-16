
/* This file was generated automatically by Zephir do not modify it! */

#ifndef PHP_FD_H
#define PHP_FD_H 1

#ifdef PHP_WIN32
#define ZEPHIR_RELEASE 1
#endif

#include "kernel/globals.h"

#define PHP_FD_NAME        "fd"
#define PHP_FD_VERSION     "0.1.0"
#define PHP_FD_EXTNAME     "fd"
#define PHP_FD_AUTHOR      "Project Saturn Studios, LLC"
#define PHP_FD_ZEPVERSION  "0.19.0-$Id$"
#define PHP_FD_DESCRIPTION "PHP-Controllable FileDescriptor Extension"



ZEND_BEGIN_MODULE_GLOBALS(fd)

	int initialized;

	/** Function cache */
	HashTable *fcache;

	zephir_fcall_cache_entry *scache[ZEPHIR_MAX_CACHE_SLOTS];

	/* Cache enabled */
	unsigned int cache_enabled;

	/* Max recursion control */
	unsigned int recursive_lock;

	
ZEND_END_MODULE_GLOBALS(fd)

#ifdef ZTS
#include "TSRM.h"
#endif

ZEND_EXTERN_MODULE_GLOBALS(fd)

#ifdef ZTS
	#define ZEPHIR_GLOBAL(v) ZEND_MODULE_GLOBALS_ACCESSOR(fd, v)
#else
	#define ZEPHIR_GLOBAL(v) (fd_globals.v)
#endif

#ifdef ZTS
	ZEND_TSRMLS_CACHE_EXTERN()
	#define ZEPHIR_VGLOBAL ((zend_fd_globals *) (*((void ***) tsrm_get_ls_cache()))[TSRM_UNSHUFFLE_RSRC_ID(fd_globals_id)])
#else
	#define ZEPHIR_VGLOBAL &(fd_globals)
#endif

#define ZEPHIR_API ZEND_API

#define zephir_globals_def fd_globals
#define zend_zephir_globals_def zend_fd_globals

extern zend_module_entry fd_module_entry;
#define phpext_fd_ptr &fd_module_entry

#endif
