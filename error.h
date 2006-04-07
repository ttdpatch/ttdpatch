#ifndef ERROR_H
#define ERROR_H
//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// error.h:	function to abort with an error message
//


#include <stdarg.h>

#ifdef __GNUC__
// enable compile time attribute argument checking of the format string
void error(const char s[], ...) __attribute__ ((format (printf, 1, 2)));
void errornowait(const char s[], ...) __attribute__ ((format (printf, 1, 2)));
void warning(const char s[], ...) __attribute__ ((format (printf, 1, 2)));
#else
// non-gcc doesn't know the "format" attribute
void error(const char s[], ...);
void errornowait(const char s[], ...);
void warning(const char s[], ...);
#endif

#endif
