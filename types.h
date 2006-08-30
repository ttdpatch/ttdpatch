#ifndef TYPES_H
#define TYPES_H
//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// Further modifications by Marcin Grzegorczyk
//
// types.h: Define platform-independent data types with known size
//	    and signed-ness
//

// Type definition code below adapted from SV1tool

#include <limits.h>

#if (CHAR_BIT != 8) || (SCHAR_MIN != -128)
  #error Cannot compile in this environment (bad char type)
#endif

#ifndef DONT_CHECK_C99
  #if __STDC_VERSION__ >= 199901L
    /* If the compiler is C99-compliant, it must have <stdint.h> */
    #ifndef HAVE_STDINT_H
      #define HAVE_STDINT_H
    #endif
    
  #endif
#endif


#ifdef HAVE_STDINT_H
  #include <stdint.h>

  #if !defined INT8_MAX || !defined INT16_MAX || !defined INT32_MAX
    #error Cannot compile in this environment (no suitable integer types)
  #endif

  typedef uint8_t u8;
  typedef int8_t s8;

  typedef uint16_t u16;
  typedef int16_t s16;

  typedef int32_t s32;
  typedef uint32_t u32;

#else  /* we've got to determine these types ourselves */

  typedef unsigned char u8;
  typedef signed char s8;

  #if USHRT_MAX != 65535u
    #error 16-bit integer type required to compile. Sorry.
  #endif
  typedef unsigned short u16;
  typedef signed short s16;

  #if ULONG_MAX == 4294967295uL
    typedef unsigned long u32;
    typedef signed long s32;
  #elif UINT_MAX == 4294967295uL
    typedef unsigned int u32;
    typedef signed int s32;
  #else
    #error 32-bit integer type required to compile. Sorry.
  #endif
#endif



#if WINTTDX
#	ifdef __GNUC__
#		define _fptr
#	else
#		if __BORLANDC__>0x310
#			define _fptr
#		elif defined _MSC_VER
#			define _fptr
#		else
#			define _fptr far
#		endif
#	endif

#else
#	if defined __BORLANDC__ || defined __WATCOMC__
#		define _fptr __far
#	else
#		define _fptr
#	endif
#	define _texport

#endif

typedef char _fptr *_protptr;


#ifdef HAVE_BAD_SNPRINTF
#	undef HAVE_SNPRINTF
#elif defined __GNUC__ || defined __WATCOMC__ || __BORLANDC__ >= 0x550
#	define HAVE_SNPRINTF
#endif


// Macros useful in preprocessing other macros

#define STRINGIFY(tokens) #tokens
#define MAKESTRING(macro) STRINGIFY(macro)

#define TOKENPASTE(a, b) a ## b
#define MACROPASTE(a, b) TOKENPASTE(a, b)

#endif	// ndef TYPES_H
