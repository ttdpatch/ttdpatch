//
// This file is part of TTDPatch
// Copyright (C) 1999 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// proclang.c:	define functions for loading a language
//		Each .o made from proclang.c deals with one language
//
// Use something like the following to compile:
// gcc -o <lang>.o -DLANGUAGE=<lang> proclang.c
//


#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifndef C
#	define C	// for common.h
#endif

#include "types.h"
#include "error.h"
#include "common.h"

#define IS_LANGUAGE_CPP
#include "language.h"

#define NOSWITCHLIST
#define WANTBITNUMS
#include "bitnames.h"

// Macros to make defining the arrays easier
#define ARRAYNAME(name) MACROPASTE(name ## _, LANGUAGE)
#define PROCESSTHIS MACROPASTE(process_, LANGUAGE)

// The three following macros have very special requirements, due to
// limitations of C (1989 standard). They open or close new blocks.
// See loadlang.h for more details.
#define COUNTRYARRAY(name) { \
	static u16 ARRAYNAME(name) []
#define TEXTARRAY(name,size) { \
	static const char * ARRAYNAME(name) [size]
#define SETARRAY(name) \
	name = ARRAYNAME(name); }

#define SETNAME(name) \
	langname = name;
#define SETCODE(code) \
	langcode = code;
#define DOSCODEPAGE(cp) \
	codepage = cp;
#define WINCODEPAGE(cp) \
	wincodepage = cp;
#define EDITORCODEPAGE(cp) \
	editorcodepage = cp;
#define DOSENCODING(enc) \
	dosencoding = #enc;
#define WINENCODING(enc) \
	winencoding = #enc;
#define SETTEXT(name,text) \
	checkmult(langtext[name], #name, NULL); \
	langtext[name] = text;
#define SETLONGTEXT(name) \
	checkmult(langtext[name], #name, NULL); \
	langtext[name] =
#define SWITCHTEXT(name, text1, text2) \
	checkmult(switchnames[(name)*2], #name, NULL); \
	switchnames[(name)*2] = text1; \
	switchnames[(name)*2+1] = text2;
#define BITSWITCH(name) \
	curbitswname = #name; \
	curbitswitch = BITSWITCH_ ## name;
#define BIT(num, text) \
	if (num ## _SWITCH != curbitswitch) \
		error("%s: Bit %s defined for wrong switch\n", langname, #num); \
	checkmult(bitswitchdesc[curbitswitch][num ## _NUM], curbitswname, #num); \
	bitswitchdesc[curbitswitch][num ## _NUM] = text;

#define LANGFILE(name) MAKESTRING(lang/name.tmp)
#define LANGERR(name) MAKESTRING(lang/name.err)

void checkmult(const char *prev, const char *name1, const char *name2);

FILE* LANGUAGE(int doopen)
{
  u32 wincodepage, editorcodepage;
  int curbitswitch;
  const char *curbitswname;

  #include LANGFILE(LANGUAGE)

  if (codepage != editorcodepage)
	error("Error: DOS code page is %ld but editor code page is %ld (Win: %ld)\n",
		codepage, editorcodepage, wincodepage);

  if(doopen)return fopen(LANGERR(LANGUAGE),"rt");

  return NULL;
}
