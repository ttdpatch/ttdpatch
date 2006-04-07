#ifndef CODEPAGE_H
#define CODEPAGE_H
//
// This file is part of TTDPatch
// Copyright (C) 2001-2002 by Josef Drexler, Marcin Grzegorczyk
//
// codepage.h: header file for codepage.c
//

#include <stddef.h>

#if WINTTDX
	const char *langcfg(size_t index);
#else
#	define langcfg(index) langtext[index]
#endif

const char *converttoACP(const char *str);
const char *getwinerrormsg(unsigned long err);
void convertescapedstring(char *str);

#endif
