//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// makelang.c:	create language.dat, the compressed file with
//		the program output strings for several languages
//		this file will then be appended to the ttdpatch
//		executable files
//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <ctype.h>

#include "zlib.h"
#include "types.h"
#include "error.h"
#include "switches.h"
#include "codepage.h"
#include "auxfiles.h"

#define IS_MAKELANG_CPP
#include "language.h"
#include "langerr.h"
#include "versionw.h"
#include "loadlng.h"

#define WANTBITSWITCHNAMES
#define NOSWITCHLIST
#include "bitnames.h"

extern const char **bitnames[];

// add new languages here; english must always be first in languagedata[]
typedef void langproc(void);
extern langproc
#ifdef TESTMAKELANG
	english;
#elifdef SINGLELANG
	SINGELANG;
#else
	czech, danish, dutch, english, finnish, french, german, hungaria,
	italian, norwegia, polish, russian, spanish;
#endif

langproc *languagedata[] = {
#ifdef SINGLELANG
	&SINGLELANG,
#else
	&english,
#ifndef TESTMAKELANG
	&czech, &danish, &dutch, &finnish, &french, &german, &hungaria,
	&italian, &norwegia, &polish, &russian, &spanish,
#endif
#endif
	};

u32 nlang;
u32 tcomp = 0, tucomp = 0, tucoverhead = 0, tcoverhead = 0;
u32 overheadstats[8];
int nocomp = 0;
langinfo *linfo;int acp;	// to make switches.c happy

#define BUFBLOCKS 128	// size increments in which buffer size is increased

#define UNTRANSLATED ((char*)(-1L))
#define OBSOLETE ((char*)(-2L))
#define INVALIDSWITCH -1


// For the in-game texts

typedef struct {
	char *data;
	u32 size;
	u32 numfilesizes;
	u32 filesizes[0];
} ingame, *pingame;


extern u32 ingamelang_num;
extern pingame  ingamelang_ptr[];

void error(const char s[], ...) __attribute__ ((noreturn));
void error(const char s[], ...)
{
  va_list args;

  va_start(args, s);
  vfprintf(stderr, s, args);
  va_end(args);

  exit(1);
}

// same as above but used by switches.c
void errornowait(const char s[], ...)
{
  va_list args;

  va_start(args, s);
  vfprintf(stderr, s, args);
  va_end(args);

  exit(1);
}

// also needed by switches.c
void warning(const char s[], ...)
{
  va_list args;

  va_start(args, s);
  vfprintf(stderr, s, args);
  fprintf(stderr, "\n");
  va_end(args);
}

#ifdef __POWERPC__
inline u32 littleendian(u32 in, int size)
{
  u8 *inp = (u8*) &in;
  u8 outp[4];

  if (size == 4) {
	outp[0] = inp[3]; outp[1] = inp[2]; outp[2] = inp[1]; outp[3] = inp[0];
	return *(u32*) outp;
  } else if (size == 2) {
	outp[0] = inp[3]; outp[1] = inp[2];
	return *(u16*) outp;
  } else if (size != 1)
	error("Can't convert size %d to little endian\n", size);
  return in;
}

inline int vfwrite_(u32 v, int size, FILE *f)
{
  if (size == 4) {
	u32 l = littleendian(v, 4);
	return fwrite(&l, 4, 1, f);
  } else if (size == 2) {
	u16 l = littleendian(v, 2);
	return fwrite(&l, 2, 1, f);
  } else if (size == 1) {
	u8 l = v;
	return fwrite(&l, 1, 1, f);
  }
  error("Can't vfwrite variable of size %d\n", size);
}
#else
inline u32 littleendian(u32 in, int size) { return in; }
#define vfwrite_(v, s, f) fwrite(&v, s, 1, f)
#endif

#define vfwrite(v, f) vfwrite_(v, sizeof(v), f)

void ensurebuflen(u32 newlen, char **buf, u32 *buflen, u32 bufend)
{
  while (newlen > *buflen) {
    if (!*buf)
	error("*buf is NULL\n");

    {
	u32 add = newlen - *buflen + BUFBLOCKS;
	add -= add % BUFBLOCKS;
	*buflen += BUFBLOCKS + add;
	*buf = (char*) realloc(*buf, *buflen);
    }
  }
  memset(*buf+bufend, 0, *buflen-bufend);
}

const char *strname(s16 code)
{
  static char strnamebuf[128];

  if (code <= LANGCODE_NAME(0))
	return "the language name";

  if (code <= LANGCODE_SWITCHES(0,0))
	return switchname[(LANGCODE_SWITCHES(0,0) - code)/2];

  if (code >= LANGCODE_BITSWITCH(0,0)) {
	int bitswitch, perswitch;
	code -= LANGCODE_BITSWITCH(0,0);
	perswitch = LANGCODE_BITSWITCH(1,0)-LANGCODE_BITSWITCH(0,0);
	bitswitch = code / perswitch;
	snprintf(strnamebuf, sizeof(strnamebuf), "%s bit %d", bitswitchnames[bitswitch], code - bitswitch * perswitch);
	return strnamebuf;
  }

  if (code >= LANGCODE_END(0))
	return "(unknown)";

  if (code >= LANGCODE_HALFLINES(0)) {
	sprintf(strnamebuf, "halflines[%d]", (int)(code - LANGCODE_HALFLINES(0)));
	return strnamebuf;
  }

  if (code >= LANGCODE_TEXT(0))
	return switchcodes[code-LANGCODE_TEXT(0)];

  return "(unknown)";
}

char *untranslated(s16 code)
{
  static char untransbuf[32];
  char name;
  s16 id;

  if (code <= LANGCODE_NAME(0)) {
	name = 'N';
	id = LANGCODE_NAME(0) - code;
  } else if (code <= LANGCODE_SWITCHES(0,0)) {
	name = 'S';
	id = (LANGCODE_SWITCHES(0,0) - code)/2;
  } else if (code >= LANGCODE_BITSWITCH(0,0)) {
	name = 'B';
	id = code - LANGCODE_BITSWITCH(0,0);
  } else if (code >= LANGCODE_END(0)) {
	name = 'E';
	id = code - LANGCODE_END(0);
  } else if (code >= LANGCODE_HALFLINES(0)) {
	name = 'H';
	id = code - LANGCODE_HALFLINES(0);
  } else if (code >= LANGCODE_TEXT(0)) {
	name = 'T';
	id = code - LANGCODE_TEXT(0);
  } else {
	name = '?';
	id = code;
  };

  sprintf(untransbuf, "(untranslated:%c%d)", name, id);
  return untransbuf;
}

int checkdups = 0;
void checkmult(const char *prev, const char *name1, const char *name2)
{
  if (checkdups && prev && prev != UNTRANSLATED)
	warning("%s: Warning: %s entry for %s %s",
		langname, prev == OBSOLETE ? "obsolete" : "duplicate",
		name1, name2 ? name2 : "");
}

#define WRITEVAR(bufvar, bufofsvar, valtype, val) { \
	*((valtype*) (*bufvar+*bufofsvar)) = littleendian(val,sizeof(valtype)); \
	*bufofsvar += sizeof(valtype); }

#define WRITESTR(bufvar, bufofsvar, len, str) { \
	memcpy(*bufvar+*bufofsvar, str, len); \
	*bufofsvar += len; }


void addarraysize(u16 arraysize, char **buf, u32 *buflen, u32 *bufofs)
{
  u16 len = sizeof(arraysize);
  u32 newofs = *bufofs + (u32) len;

  ensurebuflen(newofs, buf, buflen, *bufofs);

  WRITEVAR(buf, bufofs, u16, arraysize);
	//  *((u16*) (*buf+*bufofs) ) = arraysize;
	//  *bufofs += sizeof(arraysize);

  overheadstats[3] += sizeof(arraysize);
  tcoverhead += sizeof(arraysize);
}

s16 oldcode;

void addstring(s16 code, const char *str, char **buf, u32 *buflen, u32 *bufofs)
{
  char display[30];
  size_t i;
  s16 newcode;
  u32 len, totallen, newofs;
  char L, H;

  if (!str)
	error("Hey, I'm getting a NULL string for string %d: %s!\n",
		code, strname(code));

  if (str == UNTRANSLATED) {
	str = untranslated(code);
	fprintf(stderr, "%s: %s, define %s\n", langname, str, strname(code));
  }

  strncpy(display, str, 29);
  display[28] = display[29] = 0;
  for (i=0; i<sizeof(display)/sizeof(display[0]); i++)
	if (strchr("\n\r", display[i]))
		display[i] = ' ';

  if (code == LANGCODE_RESERVED)
	error("Reserved language code used, string is:\n%s\n", display);

  newcode = oldcode;
  if (oldcode > 0)
	newcode++;
  else
	newcode--;

  len = strlen(str);

  if (len > 0xffff >> 2)
	error("String %d has %ld of %d bytes:\n%s\n", code, len, 0xffff >> 2, display);

  L = (len & 0x3f);			// bits 0..5 of length plus flags*
  H = (len >> 6);			// bits 6..13 of length

					// Flags: 0x40: not consecutive code
					//	  0x80: length needs >6 bits

  totallen = (u32) len + 1;		// L + string

  if (len > 0x3f) {
	totallen++;			// H
	L |= 0x80;
  }

  if (newcode != code) {
	totallen += 2;			// code
	L |= 0x40;
  }

  newofs = *bufofs + (u32) totallen;

//  printf("\rAdding string %d: %s    \b\b\b\b", code, display);

  ensurebuflen(newofs, buf, buflen, *bufofs);

//  printf(".");

  WRITEVAR(buf, bufofs, char, L);

  if (L & 0x80) {
	WRITEVAR(buf, bufofs, char, H);
	overheadstats[4] ++;
	tcoverhead ++;
  }

  if (L & 0x40) {
	WRITEVAR(buf, bufofs, s16, code);
	overheadstats[5] += 2;
	tcoverhead += 2;
  }

  WRITESTR(buf, bufofs, len, str);

//  printf(".");

  if (*bufofs != newofs)
	error("Huh? Something isn't right here: %ld is not %ld (%ld).\n",
		*bufofs, newofs, totallen);

//  printf(".\r%79s\r", "");
//  fflush(stdout);

  oldcode = code;
}

void addarray(const char **array, u16 arraysize, s16 code, s16 nextcode,
	char **buf, u32 *buflen, u32 *bufofs)
{
  int i;
  s16 delta = nextcode - code;
  s16 curcode = code;

  if (!arraysize)
	for (arraysize=0; array[arraysize]; arraysize++);	// count it

  addarraysize(arraysize, buf, buflen, bufofs);
  for (i=0; i<arraysize; i++) {
	addstring(curcode, array[i], buf, buflen, bufofs);
	curcode += delta;
  }

  addstring(curcode, "", buf, buflen, bufofs);	// empty string marks end of array
  printf("Wrote codes %x to %x (%d=%d-%d)\n", code, curcode, delta,code,nextcode);
}

void unicodecheckstring(s16 code, const char ** const strp, int warn)
{
  if (*strp && *strp != UNTRANSLATED) {
	const char *escs = *strp;

	// try to find an XML-style escape sequence
	while ((escs = strstr(escs, "&#x")) != NULL) {
	    escs += 3;					// prefix found, skip
	    if (isxdigit(*escs)) {			// is the next char a hexdigit?
		while (isxdigit(*escs)) escs++;		// yes, skip all hexdigits
		if (*escs++ == ';') break;		// is the terminating semicolon there?
	    }
	}

	if (escs != NULL) {				// found an escape sequence
		char *buf = strdup(*strp);
		/*
		NOTE: there's a possible memory leak here.
		Not very dangerous in Windows, so we just ignore it.
		*/
		if (warn) fprintf(stderr, "%s: %s contains unconverted Unicode escape sequences\n",
				langname, strname(code));

		if (!buf) error("Cannot allocate buffer for conversion\n");

		convertescapedstring(buf);
		*strp = buf;

		if (warn) fprintf(stderr, "%s: %s is now: %s\n",
			langname, strname(code), *strp);
	}
  }
}

void unicodecheckarray(const char ** const array, u16 arraysize, s16 code, s16 nextcode, int warn)
{
  int i;
  s16 delta = nextcode - code;
  s16 curcode = code;

  if (!arraysize)
	for (arraysize=0; array[arraysize]; arraysize++);	// count it

  for (i=0; i<arraysize; i++) {
	unicodecheckstring(curcode, &array[i], warn);
	curcode += delta;
  }
}

void unicodecheck(int warn)
{
  int i;

  unicodecheckstring(LANGCODE_NAME(0), &langname, warn);
  unicodecheckstring(LANGCODE_NAME(1), &langcode, warn);
  unicodecheckstring(LANGCODE_NAME(2), &dosencoding, warn);
  unicodecheckstring(LANGCODE_NAME(3), &winencoding, warn);

  unicodecheckarray(langtext, LANG_LASTSTRING, LANGCODE_TEXT(0), LANGCODE_TEXT(1), warn);
  unicodecheckarray(switchnames, SWITCHNUMT*2, LANGCODE_SWITCHES(0,0), LANGCODE_SWITCHES(0,1), warn);
  unicodecheckarray(halflines, 0, LANGCODE_HALFLINES(0), LANGCODE_HALFLINES(1), warn);

  for (i=0; i<BITSWITCHNUM; i++)
	unicodecheckarray(bitswitchdesc[i], 0, LANGCODE_BITSWITCH(i,0), LANGCODE_BITSWITCH(i,1), warn);
}

extern const switchinfo switches[];
const char *patchedfilename = "";

#define SWITCHBLOCK 64	// 26 upper and lowercase letters  plus 10 digits
#define UCBLOCK 26		// for each block: 0..25 = lower case
#define NUMBLOCK (2*UCBLOCK)	//	26..51 = upper case, 52..61 = numbers
#define XBLOCK (SWITCHBLOCK)
#define YBLOCK (2*SWITCHBLOCK)
#define ZBLOCK (3*SWITCHBLOCK)
#define NOCMDSWITCHES (4*SWITCHBLOCK)
#define TOTALSWITCHES (NOCMDSWITCHES+128)

int switchid(int ch)
{
  int orgch = ch;
  int ind = 0;

  if (firstchar(ch) == 'X') {
	ind = XBLOCK;
	ch = secondchar(ch);
  } else if (firstchar(ch) == 'Y') {
	ind = YBLOCK;
	ch = secondchar(ch);
  } else if (firstchar(ch) == 'Z') {
	ind = ZBLOCK;
	ch = secondchar(ch);
	if (ch == 0) {
		// hack to support both obsolete 'Z' and new style 'Z?'
		ch = orgch;
		ind = 0;
	}
  } else if ( (firstchar(ch) >= 128) && (firstchar(ch) <= 255) ) {
	return NOCMDSWITCHES + ch - 128;
  }

  if (ch > 0xff) {
	warning("%s: Invalid two-byte char: %c%c\n",
		langname, firstchar(ch), secondchar(ch));
	return INVALIDSWITCH;
  }

  if (isalpha(ch)) {
	ind += tolower(ch) - 'a';
	if (isupper(ch))
		ind += UCBLOCK;
  } else if (isdigit(ch))
	ind += ch - '0' + NUMBLOCK;
  else {
	// some special cases
	switch (ch) {
		case '?': break;
		default:
			warning("%s: Unknown command line switch '%s' (%d %d), block %d ind %d",
				langname, dchartostr(orgch),
				firstchar(orgch), secondchar(orgch),
				ind, ch);
			return INVALIDSWITCH;
	}
	ind = INVALIDSWITCH;
  }

  return ind;
}

int getswitchid(const char **str)
{
  int ind, ext, ch;
  const char *orgstr = *str;

  ch = *str[0];
  (*str)++;

  if (ch == 'X' || ch == 'Y' || ch == 'Z') {
	ext = *str[0];
	(*str)++;

	ch = maketwochars(ch, ext);
  }

  ind = switchid(ch);
  if (ind >= TOTALSWITCHES)
	warning("%s: Invalid index for switch '%s' in line: %s\n",
		langname, dchartostr(ch), orgstr);
  return ind;
}

extern u8 switchorder[];
extern int numswitchorder;

void errorcheck(void)
{
  // check that the special stuff is OK
  // halflines: at least one line starting with the
  //	cmd switches for each YESNO switch,
  //	length being limited to 38
  // switchnames: test the length, max 36 for both texts of each switch

  // first find out which yesno switches there are
  int cmdchars[TOTALSWITCHES];
  int i, ind;
  const char *line;
  int inorder[lastbitdefaultoff+1];

  // these switches are not in the -h display, remove them from the list
  const char *notlisted = "hVX2";

  printf("Error checking");
  memset(cmdchars, -1, sizeof(cmdchars));
  for (i=0; switches[i].cmdline; i++) {
		ind = switchid(switches[i].cmdline);
		if (ind >= 0 && !(switches[i].bit == -1 &&
				  switches[i].var == (void _fptr *)-1L))
			cmdchars[ind] = switches[i].cmdline;
  }
  printf(".");

  line = notlisted;
  for (line=notlisted; line[0]; ) {
	ind = getswitchid(&line);
	if (ind >= 0)
		cmdchars[ind] = 0;
  }
  printf(".");

  // go through all halflines and check the leading letters
  for (i=0; halflines[i]; i++) {
	const char *orgline;

	orgline = line = halflines[i];
	if (strlen(line) > 38)
		fprintf(stderr, "%s: halfline too long by %d chars: %s\n",
			langname, (int) strlen(line) - 38, line);

	if ((line[0] == ' ') && (line[1] == '-') )
		line++;

	if (line[0] != '-')
		continue;

	line++;
	ind = getswitchid(&line);
	if (ind >= 0) {
		if (!cmdchars[ind])
			fprintf(stderr, "%s: duplicate halfline entry: %s\n",
				langname, orgline);
		if (cmdchars[ind] < 0)
			fprintf(stderr, "%s: halfline entry for nonexistent switch: %s\n",
				langname, orgline);
		cmdchars[ind] = 0;
	}
  }
  printf(".");

  // Go through the ranged switches
  line = langtext[LANG_FULLSWITCHES];

  while (line) {
	if (line[0] == '-') {
		const char *orgline = line;
		line++;

		while ( (line[0] != ' ') && ((ind = getswitchid(&line)) >= 0) ) {
			if (!cmdchars[ind])
				fprintf(stderr, "%s: duplicate switch entry: %s\n",
					langname, orgline);
			if (cmdchars[ind] < 0)
				fprintf(stderr, "%s: switch entry for nonexistent switch: %6.6s\n",
					langname, orgline);
			cmdchars[ind] = 0;
		}
	}

	line = strchr(line, '\n');
	if (!line)
		break;

	line++;
  }
  printf(".");

  // check that all switches are in switchorder[]
  memset(inorder, 0, sizeof(inorder));
  for (i=0; i<numswitchorder; i++) {
	if (switchorder[i] > lastbitdefaultoff)
		error("Switch %d is beyond lastbitdefaultoff in common.h\n", switchorder[i]);
	if ( (switchorder[i] > lastbitdefaulton) && (switchorder[i] < firstbitdefaultoff) )
		error("Switch %d is beyond lastbitdefaulton in common.h\n", switchorder[i]);

	inorder[switchorder[i]]++;
  }

  // special cases
  inorder[setsignal1waittime]++;
  inorder[setsignal2waittime]++;
  inorder[lowmemory]++;

  // check that all switches are present
  for (i=0; i<=lastbitdefaultoff; i++) {
	if (i==lastbitdefaulton+1) i=firstbitdefaultoff;
	if (!inorder[i])
		error("Switch %d is not in switch order list in sw_list.h\n", i);
	else if (inorder[i] > 1)
		error("Switch %d occurs %d times in switch order list in sw_list.h\n", i, inorder[i]);
  }
  printf(".");

  // now see which ones are missing
  for (i=0; i<SWITCHBLOCK; i++)
	if (cmdchars[i] > 0)
		fprintf(stderr, "%s: halflines missing description of option -%c\n",
			langname, cmdchars[i]);
  for (; i<NOCMDSWITCHES; i++)
	if (cmdchars[i] > 0)
		fprintf(stderr, "%s: halflines missing description of option -%s\n",
			langname, dchartostr(cmdchars[i]));

  printf(".");

  // OK, and go through switchnames making sure they're not too long
  for (i=0; i<SWITCHNUMT; i++) {
	if (switchnames[i*2] == UNTRANSLATED)
		continue;		// will be caught and flagged later

	if (!switchnames[i*2+1])
		switchnames[i*2+1] = "";

	if ( (strlen(switchnames[i*2])+strlen(switchnames[i*2+1]) > 74)
			&& (i != setsignal1waittime) )
		fprintf(stderr, "%s: %s too long by %d chars: %s%s\n",
			langname, switchname[i],
			(int) (strlen(switchnames[i*2])+strlen(switchnames[i*2+1]) - 74),
			switchnames[i*2], switchnames[i*2+1]);
  }
  printf(".\n");

}

u32 assemblebuffer(char **buf, u32 *buflen)
{
  u32 bufofs=0;
  int i;

  oldcode = LANGCODE_NAME(-1);
  addstring(LANGCODE_NAME(0), langname, buf, buflen, &bufofs);
  addstring(LANGCODE_NAME(1), langcode, buf, buflen, &bufofs);
  addstring(LANGCODE_NAME(2), dosencoding, buf, buflen, &bufofs);
  addstring(LANGCODE_NAME(3), winencoding, buf, buflen, &bufofs);
  addstring(LANGCODE_NAME(4), "", buf, buflen, &bufofs);

  printf("Assembling: langtext\n");
  addarray(langtext, LANG_LASTSTRING, LANGCODE_TEXT(0), LANGCODE_TEXT(1), buf, buflen, &bufofs);

  printf("Assembling: switchnames\n");
  addarray(switchnames, SWITCHNUMA*2, LANGCODE_SWITCHES(0,0), LANGCODE_SWITCHES(0,1), buf, buflen, &bufofs);
  addarray(switchnames+SWITCHSTARTB*2, SWITCHNUMB*2, LANGCODE_SWITCHES(SWITCHSTARTB,0), LANGCODE_SWITCHES(SWITCHSTARTB,1), buf, buflen, &bufofs);

  printf("Assembling: halflines\n");
  addarray(halflines, 0, LANGCODE_HALFLINES(0), LANGCODE_HALFLINES(1), buf, buflen, &bufofs);

  printf("Assembling: bit switches\n");
  for (i=0; i<BITSWITCHNUM; i++)
	addarray(bitswitchdesc[i], numbits[i], LANGCODE_BITSWITCH(i,0), LANGCODE_BITSWITCH(i,1), buf, buflen, &bufofs);

  addstring(LANGCODE_END(0), "", buf, buflen, &bufofs);	// end of file

  printf("Assembling: done!\n");

  return bufofs;
}

u32 writelanguages(FILE *dat)
{
  int i, j, result;
  u32 lang;
  u32 thisofs, thisccofs, nextofs, uncompsize, maxuncompsize=0;
  uLong compsize, maxcompsize=0;
  u32 cbuflen = BUFBLOCKS, ucbuflen = BUFBLOCKS;
  u32 versid;
  char *cbuf, *ucbuf;
  char *langcode = strdup(LANGCODE);

  for (i=0; i<LANGCODELEN; i++)	// it's XOR'd in the EXE file
	langcode[i] ^= 32;

  versid = littleendian(TTDPATCHVERSIONNUM, 4);
  fwrite(langcode, sizeof(char), LANGCODELEN, dat);
  fwrite(&versid, sizeof(versid), 1, dat);
  vfwrite(i, dat);	// offset to in-game strings; written later.
  vfwrite(nlang, dat);

  free(langcode);

  cbuf = (char*) calloc(cbuflen, sizeof(char));
  if (!cbuf)
	error("malloc\n");
  ucbuf = (char*) calloc(ucbuflen, sizeof(char));
  if (!ucbuf)
	error("malloc\n");

  nextofs = LANGINFOOFFSET + nlang*LANGINFOSIZE;

  printf("Starting...\n");
  for (lang=0; lang<nlang; lang++) {

	printf("Processing language #%ld\n", (long)lang);

	for (i=0; i<LANG_LASTSTRING; i++)
		langtext[i] = UNTRANSLATED;
	for (i=LANG_LASTSTRING; i<LANG_REALLYLASTSTRING; i++)
		langtext[i] = OBSOLETE;
	for (i=0; i<SWITCHNUMT; i++) {
		switchnames[i*2] = UNTRANSLATED;
		switchnames[i*2+1] = "";
	}
	for (i=0; i<BITSWITCHNUM; i++)
		for (j=0; j<numbits[i]; j++) {
			if (strcmp(bitnames[i][j], "(reserved)"))
				bitswitchdesc[i][j] = UNTRANSLATED;
			else
				bitswitchdesc[i][j] = "";
		}

	checkdups = 1;
	languagedata[lang]();
	unicodecheck(1);
	errorcheck();		// for error checking, keep untranslated strings empty
	assemblebuffer(&ucbuf, &ucbuflen);

	printf("Checked language %s\n", langname);

	// but for the real run, we use
	// english strings as default

	checkdups = 0;
	languagedata[0]();		// english
	languagedata[lang]();	// override all defined strings with this language
	unicodecheck(0);


	printf("Prepared language %s\n", langname);

	for (i=0; countries[i]; i++);
	for (i++; countries[i]; i++);	// find second "0" in countries[]

	printf("Writing %d country info bytes\n", i);
	fseek(dat, nextofs, SEEK_SET);
	thisccofs = ftell(dat);

	for (j=0; j<i; j++)
		vfwrite(countries[j], dat);
	thisofs = ftell(dat);
	overheadstats[0] += sizeof(countries[0]) * i;
	tucoverhead += sizeof(countries[0]) * i;

	uncompsize = assemblebuffer(&ucbuf, &ucbuflen);
	printf("Compressing %ld bytes\n", uncompsize);

	tucomp += uncompsize;

	ensurebuflen(uncompsize + uncompsize / 1000 + BUFBLOCKS, &cbuf, &cbuflen, 0);
	if (nocomp) {
		memcpy(cbuf, ucbuf, uncompsize);
		compsize = uncompsize;
	} else {
		compsize = cbuflen;
		result = compress2( (Bytef*) cbuf, &compsize,
			(Bytef*) ucbuf, uncompsize, Z_BEST_COMPRESSION);
		if (result != Z_OK)
			error("Compress returned %d\n", result);

		if (compsize == uncompsize)
			error("Compressed and uncompressed have the same length!\n");
//                	compsize++;	// both equal is taken to mean uncompressed, so add another irrelevant byte
	}

	tcomp += compsize;

	if (uncompsize > maxuncompsize) maxuncompsize = uncompsize;
	if (  compsize >   maxcompsize)   maxcompsize =   compsize;

	printf("Writing %ld bytes %scompressed data at %lx\n",
		compsize, nocomp?"un":"", thisofs);

	fseek(dat, thisofs, SEEK_SET);
	fwrite(cbuf, 1, compsize, dat);
	nextofs = ftell(dat);

	fseek(dat, LANGINFOOFFSET + lang*LANGINFOSIZE, SEEK_SET);
	vfwrite(thisofs, dat);
	vfwrite(thisccofs, dat);
	vfwrite(compsize, dat);
	vfwrite(uncompsize, dat);
	vfwrite(codepage, dat);

	overheadstats[1] += sizeof(thisofs) + sizeof(thisccofs) +
			sizeof(compsize) + sizeof(uncompsize);
	tucoverhead += sizeof(thisofs) + sizeof(thisccofs) +
			sizeof(compsize) + sizeof(uncompsize);
  }

  printf("Will write in-game strings at %lx\n", nextofs);

  fseek(dat, LANGINGAMEOFS, SEEK_SET);
  vfwrite(nextofs, dat);

  fseek(dat, LANGMAXSIZEOFS, SEEK_SET);
  vfwrite(maxuncompsize, dat);
  vfwrite(maxcompsize, dat);

  overheadstats[2] += LANGMAXSIZEOFS + sizeof(maxuncompsize) + sizeof(maxcompsize);
  tucoverhead += LANGMAXSIZEOFS + sizeof(maxuncompsize) + sizeof(maxcompsize);

  return nextofs;
}

u32 writeingametexts(FILE *dat, u32 baseofs)
{
  int result;
  u32 i, j, nextofs, dataofs;
  u32 num, numfsizes;
  u32 ucsize, csize;
  u32 cbuflen = BUFBLOCKS;
  char *cbuf, *ucbuf;

  cbuf = (char*) calloc(cbuflen, sizeof(char));
  if (!cbuf)
	error("malloc\n");

  printf("Writing in-game strings at %lx\n", baseofs);

  num = littleendian(ingamelang_num, 4);

  fseek(dat, baseofs, SEEK_SET);
  vfwrite(num, dat);
  nextofs = ftell(dat);
  dataofs = nextofs + 4*num;

  for (i=0; i<num; i++) {
	pingame ptr = (pingame) littleendian((u32) (ingamelang_ptr[i]), 4);

	fseek(dat, nextofs, SEEK_SET);
	vfwrite(dataofs, dat);
	nextofs = ftell(dat);

	ucbuf = (char*) littleendian((u32) ptr->data, 4);
	ucsize = littleendian(ptr->size, 4);

	tucomp += ucsize;

	printf("Compressing %ld bytes of in-game language %ld\n", ucsize, i);

	if (nocomp) {
		csize = ucsize;
		cbuf = ucbuf;
	} else {
		ensurebuflen(ucsize + ucsize / 1000 + BUFBLOCKS, &cbuf, &cbuflen, 0);
		csize = cbuflen;
		result = compress2( (Bytef*) cbuf, &csize,
			(Bytef*) ucbuf, ucsize, Z_BEST_COMPRESSION);
		if (result != Z_OK)
			error("Compress returned %d\n", result);

		if (csize == ucsize)
			error("Compressed and uncompressed have the same length!\n");
	}

	tcomp += csize;

	numfsizes = littleendian(ptr->numfilesizes, 4);

	printf("Writing sizes and %ld file sizes at %lx\n",
		numfsizes, dataofs);

	fseek(dat, dataofs, SEEK_SET);
	vfwrite(numfsizes, dat);
	vfwrite(ucsize, dat);
	vfwrite(csize, dat);
	fwrite(ptr->filesizes, sizeof(ptr->filesizes[0]), numfsizes, dat);

	printf("Writing %ld bytes of %scompressed data at %lx\n",
		csize, nocomp?"un":"", ftell(dat));
	fwrite(cbuf, 1, csize, dat);

	dataofs = ftell(dat);

	overheadstats[6] += 4*4;
	tucoverhead += 4*4;

	overheadstats[7] += 4*numfsizes;
	tucoverhead += 4*numfsizes;
  }

  return dataofs;
}


int main(int argc, char **argv)
{
  int i;
  FILE *dat;
  u32 size;

  if ( (argc > 1) && (argv[1][0] == 'n') )
	nocomp = 1;
//  if ( (argc > 1) && (argv[1][0] == 'e') )
//	freopen("makelang.err", "wt", stderr);

  for (i=0; i<sizeof(overheadstats)/sizeof(overheadstats[0]); i++)
	overheadstats[i] = 0;

  nlang = sizeof(languagedata) / sizeof(languagedata[0]);

  dat = fopen(nocomp?"language.ucd":"language.dat", "wb");
  if (!dat)
	error("Can't write: %s", strerror(errno));

  size = writelanguages(dat);
  writeingametexts(dat, size);

  fclose(dat);

  {
    // tucomp total bytes in to-be-compressed data
    // tcomp  total bytes in compressed data
    // tucoverhead   overhead in file header
    // tcoverhead	   overhead: extra bytes in to-be-compressed data

    // total compression ratio
    u32 fpcr = 100L*(tcomp+tucoverhead)/(tucomp+tucoverhead);

    // Original data (total, overhead, percentage overhead)
    u32 ftorig = tucomp - tcoverhead;

    // uncompressed data
    u32 ftucomp = tucomp + tucoverhead;
    u32 foucomp = tucoverhead + tcoverhead;
    u32 fpu = 100L*foucomp/ftucomp;

    // compressed data
    u32 ftcomp = tcomp + tucoverhead;
    u32 focomp = tucoverhead + (tcoverhead*fpcr/100L);	// estimate that overhead is compressed at same ratio
    u32 fpc = 100L*focomp/ftcomp;

    fprintf(stderr, "\n"
	"Summary:\n"
	"		   Total	incl. Overhead\n"
	"original data	%8ld	     ---\n"
	"uncompressed	%8ld	%8ld (%3ld%%)\n"
	"compressed	%8ld	%8ld (%3ld%%) estimated\n",
  	ftorig,
  	ftucomp, foucomp, fpu,
	ftcomp, focomp, fpc
	);

    {
      const char *overstatstext[] =
	{ "Countryinfo (W)",
	  "Sizes and offsets (4D)",
	  "Magic bytes and max sizes (B)",
	  "Array sizes (W)",
	  "2-byte string lengths (W)",
	  "non-consecutive codes (W)",
	  "In-game language sizes (4D)",
	  "Exe file sizes (D)",
	};
      u32 overheadsize[] = { 2, 4*4, 1, 2, 2, 2, 4*4, 4 };
      u32 overheadperlang[] = { 1, 1, 0, 1, 1, 1, 0, 0 };

      for(i=0; i<sizeof(overheadperlang)/sizeof(overheadperlang[0]); i++)
	overheadperlang[i] *= nlang;

      fprintf(stderr, "\nOverhead statistics:\n"
	"	   Bytes  Number  no/lang  What\n");
      for (i=0; i<sizeof(overheadstats)/sizeof(overheadstats[0]); i++)
	fprintf(stderr, "	%8ld%8ld%9ld  %s\n",
		overheadstats[i],
		overheadstats[i]/overheadsize[i],
		!overheadperlang[i]?0:
			overheadstats[i]/overheadsize[i]/overheadperlang[i],
		overstatstext[i]);

    }

    fprintf(stderr, "\nRatio: %3ld%%\n", fpcr);
  }
  return 0;
}
