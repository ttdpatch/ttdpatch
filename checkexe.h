#ifndef CHECKEXE_H
#define CHECKEXE_H
//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// checkexe.h: header file for checkexe.cpp
//

#include "versions.h"

#if defined(IS_CHECKEXE_CPP)
#	define ISEXTERN
#else
#	define ISEXTERN extern
#endif


extern const s32 filesizebase;
extern const s32 filesizeshr;

void checkpatch(void);
void versiontotext(s32 version, s32 filesize, int shorttype, char *dest);
void versioninfototext(pversioninfo version, int shorttype, char *dest);

u32 checkexe(FILE **f, const char *exenames[], u32 thisneid, const char *thistype);
u32 loadingamestrings(u32 programsize);
int setseglen(u32 seglenpos, u32 min, u32 max, u32 newlen, u32 altlen);
void startwrite(void);
void checkversion(u32 programversion, u32 programsize);

u32 getval(u32 pos, int size);
void setval(u32 pos, int size, u32 value);
int ensureval(u32 pos, int size, u32 value);


ISEXTERN s32 newversion;
ISEXTERN s32 newfilesize;

ISEXTERN u32 customtextsize;
ISEXTERN char *customtexts;

extern enum langtextids customsystexts[];
size_t getncustomsystexts(void);

#define isothertext(n) (customsystexts[n] > OTHER_FIRSTSTRING)
#define systext(n) (isothertext(n) \
			? othertext[customsystexts[n]-OTHER_FIRSTSTRING-1] \
			: langtext[customsystexts[n]])

#undef ISEXTERN

#endif
