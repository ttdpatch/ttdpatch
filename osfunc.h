#ifndef OSFUNC_H
#define OSFUNC_H
//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// osfunc.h: defines the OS-specific functions
//

#include "loadlng.h"

#if defined(WIN32) || !WINTTDX

#if 0	// currently not used
void ensureconsize(int minlines);
void getcursorxy(int *x, int *y);
#endif
void getconsoleinfo(int *width, int *height, unsigned *attrib);
int gettextattrib(void);
void setcursorxy(int x, int y);
void clrconsole(int startline, int endline, int conwidth, unsigned attrib);
void restoreconsize(void);
int trynoregistry(void);

int runttd(const char *program, char *options, langinfo **info);
void initializewindow(void);
/*
void addgrffiles(FILE *f);
*/

#ifdef __cplusplus
extern "C" {
#endif

void _fptr __cdecl protectedcode();
void _fptr __cdecl protectedfunc();
//void _fptr __cdecl protectedfuncrealend();
//void _fptr __cdecl protectedfuncend();
void _fptr __cdecl initfunc();
void _fptr __cdecl initfuncend();
void _fptr __cdecl winloader();
void _fptr __cdecl realentrypoint();
void _fptr __cdecl winloaderend();

#ifdef __cplusplus
}
#endif

s16 getdefaultlanguage(langinfo *info);

#endif

#endif
