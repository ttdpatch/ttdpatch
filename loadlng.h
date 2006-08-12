#ifndef LOADLNG_H
#define LOADLNG_H
//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// loadlng.h: definitions for loadlng.h
//

#include <stdio.h>
#include "types.h"

#define IS_LOADLNG_H
#include "language.h"

typedef struct {
	u32 langofs, ingameofs;
	u32 maxcompsize, maxuncompsize;
	u32 cbufsize, ucbufsize;
	u32 compsize, uncompsize;
	u32 thisofs, thisccofs;
	u32 codepage;
	u32 nlang;
	u32 ucptr;
	FILE *f;
	char *ucbuf, *langname, *langcode, *lastend;
	char *dosencoding, *winencoding;
	s16 countryinfo[LANG_MAX_COUNTRY];
	s16 *countries, *languages;
	s16 lang;
	s16 oldcode;
	int ncountryinfo, ncountries, nlanguages;
} langinfo;

	langinfo *langinfo_new(void);
	void langinfo_delete(langinfo *);

	s16 langinfo_findlangfromcid(langinfo *, u16 countryid);
	s16 langinfo_findlangfromlid(langinfo *, int languageid, int usedefault);
	s16 langinfo_findlangfromcc(langinfo *, char *cc);
	s16 langinfo_findlangfromcode(langinfo *, char *acode);
	s16 langinfo_findlang(langinfo *, char *name);
	void langinfo_loadlang(langinfo *, s16 language);
	void langinfo_freebuf(langinfo *);
	#define langinfo_number(linfo) ((s16)(linfo)->nlang)
	#define langinfo_name(linfo) ((linfo)->langname)
	#define langinfo_code(linfo) ((linfo)->langcode)
	#define langinfo_exename(linfo) ((linfo)->exefilename)

	void langinfo_loadcurlangdata(langinfo *);
	void langinfo_processlangdata(langinfo *);
	u32 langinfo_readingamestrings(langinfo *linfo, u32 exesize, char *target, u32 targetsize, char *langid);
#endif
