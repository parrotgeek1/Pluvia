#include <iostream>

#include <sys/stat.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <sys/mman.h>
#include <syslog.h>

#include <mach/mach.h>

#include <dlfcn.h>

#include <sys/syscall.h>

#define LC_SOURCE_VERSION 0x2A

#ifndef EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER
	#define EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER 0x10
#endif

#ifndef EXPORT_SYMBOL_FLAGS_REEXPORT
	#define EXPORT_SYMBOL_FLAGS_REEXPORT 0x08
#endif

#ifndef LC_VERSION_MIN_IPHONEOS
	#define LC_VERSION_MIN_IPHONEOS 0x25
#endif

#ifndef LC_FUNCTION_STARTS
	#define LC_FUNCTION_STARTS 0x26
#endif


#ifdef TARGET_IPHONE
	#include <CommonCrypto/CommonDigest.h>
	#define SHA1 CC_SHA1
#else
	#include <openssl/sha.h>
#endif


#define CommonLog_old(fmt, ...) \
	{ \
		syslog(5, fmt, ##__VA_ARGS__); \
		fprintf(stdout, fmt "\n", ##__VA_ARGS__); \
	}
	
#define CommonLog(fmt, ...) \
	{ \
		syslog(5, "%s/%d: " fmt, __FUNCTION__, __LINE__, ##__VA_ARGS__); \
		fprintf(stdout, "%s/%d: " fmt "\n", __FUNCTION__, __LINE__, ##__VA_ARGS__); \
	}

#define PANIC(fmt, ...) \
	{ \
		CommonLog_old("Panic encountered at %s (%d): " fmt , __FUNCTION__, __LINE__, ##__VA_ARGS__); \
		abort(); \
	}


#define LINE() \
	{ \
		CommonLog_old("%s %s %d", __FILE__, __FUNCTION__, __LINE__); \
	}


