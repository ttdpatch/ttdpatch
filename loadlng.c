//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// loadlng.c: functions to load and decode the language data
//

#include "zlib.h"
#include "grep.h"
#include "error.h"
#include "loadlng.h"
#include "auxfiles.h"

//#include "patches/texts.h"

#if WINTTDX
#	include "versionw.h"
#else
#	include "versiond.h"
#endif


// u32 infoloc(s16 language)
#define infoloc(linfo, language) (u32)((linfo)->langofs + LANGINFOOFFSET + ((s16)language)*LANGINFOSIZE)
// u32 dataloc(u32 relofs)
#define dataloc(linfo, relofs) (u32)((linfo)->langofs + ((u32)relofs))


langinfo *langinfo_new()
{
  u32 versid;
  langinfo *linfo = malloc(sizeof *linfo);

  linfo->lang = -1;
  linfo->lastend = NULL;
  linfo->ucbuf = NULL;

  if (!findattachment(AUX_LANG, &linfo->langofs, &linfo->f))
	error("Fatal error: No language data present.\n");
  linfo->langofs -= LANGCODELEN;

  fseek(linfo->f, dataloc(linfo, LANGCODELEN), SEEK_SET);
  fread(&versid, sizeof(versid), 1, linfo->f);

  if (versid != (TTDPATCHVERSIONNUM & 0xffffffff))
	error("Language data version mismatch.\n"
		"This is TTDPatch V%llx, language data is for V%lx.",
		TTDPATCHVERSIONNUM, versid);

  fread(&linfo->ingameofs, sizeof(linfo->ingameofs), 1, linfo->f);
  fread(&linfo->nlang, sizeof(linfo->nlang), 1, linfo->f);
  fread(&linfo->maxuncompsize, sizeof(linfo->maxuncompsize), 1, linfo->f);
  fread(&linfo->maxcompsize, sizeof(linfo->maxcompsize), 1, linfo->f);
  
  return linfo;
}

void langinfo_delete(langinfo *linfo)
{
  langtext_isvalid = 0;
  if (linfo) {
	langinfo_freebuf(linfo);
	free(linfo);
  }
}

// find the number of a language by country id
s16 langinfo_findlangfromcid(langinfo *linfo, u16 countryid)
{
  s16 lang, deflang = -1;
  int i;

  for (lang=0; lang< (s16) linfo->nlang; lang++) {
	langinfo_loadlang(linfo, lang);
	for (i=0; i<linfo->ncountries; i++) {
		if (!linfo->countries[i])	// end of country codes
			break;
		if (linfo->countries[i] == countryid)
			return lang;
		if (linfo->countries[i] == -1)
			deflang = lang;
	}
  }

  return deflang;
}

// find the number of a language by Windows language id
s16 langinfo_findlangfromlid(langinfo *linfo, int languageid, int usedefault)
{
  s16 lang, deflang = -1;
  int i;

  for (lang=0; lang< (s16) linfo->nlang; lang++) {
	langinfo_loadlang(linfo, lang);

	// skip country codes
	for (i=0; i<linfo->nlanguages; i++) {
		if (linfo->languages[i] == languageid)
			return lang;
		if ( (linfo->languages[i] == -1) && usedefault)
			deflang = lang;
	}
  }

  return deflang;
}

// find the number of a language by name
s16 langinfo_findlang(langinfo *linfo, char *name)
{
  s16 lang;

  for (lang=0; lang< (s16) linfo->nlang; lang++) {
	langinfo_loadlang(linfo, lang);
	langinfo_loadcurlangdata(linfo);
	if (strnicmp(name, linfo->langname, 8) == 0)
		return lang;
	langinfo_freebuf(linfo);
  }

  return -1;
}

// and from the ISO-3166 country code
s16 langinfo_findlangfromcc(langinfo *linfo, char *cc)
{
  s16 lang;

  // for now, we ignore everything after the first two country code letters

  for (lang=0; lang< (s16) linfo->nlang; lang++) {
	langinfo_loadlang(linfo, lang);
	langinfo_loadcurlangdata(linfo);
	if (strnicmp(cc, linfo->langcode, 2) == 0)
		return lang;
	langinfo_freebuf(linfo);
  }

  return -1;
}

// and from the Windows language code (e.g. from "LANG=1031"; 1031=0x407 and 7=German)
s16 langinfo_findlangfromcode(langinfo *linfo, char *acode)
{
  s16 lang;
  int code;

  code = atoi(acode);
  if (!code) return -1;
  return langinfo_findlangfromlid(linfo, code & 0xff, 0);
}


// load info about the language, like size and country codes
void langinfo_loadlang(langinfo *linfo, s16 language)
{
  int i;

  fseek(linfo->f, infoloc(linfo, language), SEEK_SET);
  fread(&linfo->thisofs, sizeof(linfo->thisofs), 1, linfo->f);
  fread(&linfo->thisccofs, sizeof(linfo->thisccofs), 1, linfo->f);
  fread(&linfo->compsize, sizeof(linfo->compsize), 1, linfo->f);
  fread(&linfo->uncompsize, sizeof(linfo->uncompsize), 1, linfo->f);
  fread(&linfo->codepage, sizeof(linfo->codepage), 1, linfo->f);

  linfo->ncountryinfo = (linfo->thisofs - linfo->thisccofs) / sizeof(linfo->countryinfo[0]);
  if (linfo->ncountryinfo > sizeof(linfo->countryinfo)/sizeof(linfo->countryinfo[0]))
	error("Too much country info for language %d: %d not %d.\n", language,
	linfo->ncountryinfo, sizeof(linfo->countryinfo)/sizeof(linfo->countryinfo[0]));

  fseek(linfo->f, dataloc(linfo, linfo->thisccofs), SEEK_SET);
  fread(linfo->countryinfo, sizeof(linfo->countryinfo[0]), linfo->ncountryinfo, linfo->f);

  linfo->countries = linfo->countryinfo;
  linfo->languages = NULL;

  for (i=0; i<linfo->ncountryinfo; i++)
	if (!linfo->countryinfo[i]) {
		linfo->ncountries = i;
		linfo->languages = linfo->countryinfo + i + 1;
		linfo->nlanguages = linfo->ncountryinfo - i - 1;
		break;
	}

  if (!linfo->languages)
  	error("No Windows language IDs in language %d.\n", language);

  linfo->lang = language;	// take note which language this info applies to

  codepage = linfo->codepage;	// set the global variable
}

// free the buffer containing uncompressed data
void langinfo_freebuf(langinfo *linfo)
{
  if (linfo && linfo->ucbuf) {
	free(linfo->ucbuf);
	linfo->ucbuf = NULL;
  }
}


static char *langinfo_nextstring(langinfo *linfo, s16 code);
static void langinfo_emptystring(langinfo *linfo, s16 code);


// load the compressed data and uncompress it
void langinfo_loadcurlangdata(langinfo *linfo)
{
  int result;
  uLong realuncomp;
  char *cbuf;

  if (linfo->lang == -1)
	error("call loadlang() before loadcurlangdata().\n");

	// allocate buffers
  cbuf = (char*) malloc(linfo->compsize);
  if (!cbuf)
	error("Error allocating %s buffer of %ld bytes for language %d\n",
		"compressed", linfo->compsize, linfo->lang);

	// read compressed language data
  fseek(linfo->f, dataloc(linfo, linfo->thisofs), SEEK_SET);
  fread(cbuf, 1, linfo->compsize, linfo->f);

  if (linfo->uncompsize != linfo->compsize) {
		// and uncompress it
	linfo->ucbuf = (char*) malloc(linfo->uncompsize);
	if (!linfo->ucbuf)
		error("Error allocating %s buffer of %ld bytes for language %d\n",
			"uncompressed", linfo->uncompsize, linfo->lang);

	realuncomp = linfo->uncompsize;
	result = uncompress( (Bytef*) linfo->ucbuf, &realuncomp, (Bytef*) cbuf, linfo->compsize);
	if (result != Z_OK)
		error("Uncompressing language %d: error %d\n", linfo->lang, result);

	free(cbuf);
  } else {
	linfo->ucbuf = cbuf;	// was already uncompressed
  }

  linfo->ucptr = 0;
  linfo->lastend = NULL;

  linfo->oldcode = LANGCODE_NAME(-1);
  linfo->langname = langinfo_nextstring(linfo, LANGCODE_NAME(0));
  linfo->langcode = langinfo_nextstring(linfo, LANGCODE_NAME(1));
  linfo->dosencoding = langinfo_nextstring(linfo, LANGCODE_NAME(2));
  linfo->winencoding = langinfo_nextstring(linfo, LANGCODE_NAME(3));

  langinfo_emptystring(linfo, LANGCODE_NAME(4));

  return;
}

// process the next string in the uncompressed stream
static void langinfo_procnextstring(langinfo *linfo, s16 code, char **str, s16 *len)
{
  char L, H;
  s16 dcode;

  if (linfo->ucptr >= linfo->uncompsize)
	error("Read beyond end of language data.\n");

  L = *((char*) (linfo->ucbuf+linfo->ucptr) );
  linfo->ucptr ++;

  if (linfo->lastend)
	*linfo->lastend = 0;

  *len = L & 0x3f;

  if (L & 0x80) {
	H = *((char*) (linfo->ucbuf+linfo->ucptr) );
	linfo->ucptr++;
	*len = *len | (H << 6);
  }

  if (L & 0x40) {
	dcode = *((s16*) (linfo->ucbuf+linfo->ucptr) );
	linfo->ucptr += sizeof(dcode);
  } else {
	dcode = linfo->oldcode;
	if (dcode > 0)
		dcode++;
	else
		dcode--;
  }

  if (dcode != code)
	error("Wanted code %x but got %x\n", code, dcode);

  if (str)
	*str = linfo->ucbuf+linfo->ucptr;
  linfo->ucptr += *len;

  linfo->lastend = linfo->ucbuf+linfo->ucptr;

  linfo->oldcode = dcode;
}

// return the location of the next string in the uncompressed buffer,
static char *langinfo_nextstring(langinfo *linfo, s16 code)
{
  char *str;
  s16 len;
  langinfo_procnextstring(linfo, code, &str, &len);
  return str;
}

// return the length of the next string in the uncompressed buffer,
// note this also discards that string!  But you can't get the length
// reliably with the nextstring() function, strlen it won't be valid
// until the next string is read.
static s16 langinfo_nextstringlength(langinfo *linfo, s16 code)
{
  s16 len;
  langinfo_procnextstring(linfo, code, NULL, &len);
  return len;
}

// skip an empty string, both checking the code and that it is an empty string
static void langinfo_emptystring(langinfo *linfo, s16 code)
{
  if (langinfo_nextstringlength(linfo, code) > 0)
	error("Got a non-empty string but wasn't expecting one for %d\n", code);
}

// read the size of the following array
static s16 langinfo_arraysize(langinfo *linfo)
{
  s16 size = ( *((s16*) (linfo->ucbuf+linfo->ucptr) ) );
  linfo->ucptr += sizeof(size);
  return size;
}

// read a variable size array, terminated by a NULL entry.
// "array" is a pointer to an array of strings, therefore ***
static void langinfo_readarray(langinfo *linfo, const char ***array, int *cursize, s16 firstcode, s16 secondcode)
{
  int i;

  if (linfo->ucptr >= linfo->uncompsize)
	error("Read beyond end of language data.\n");

  {
    s16 size = langinfo_arraysize(linfo) + 1;
  
    if (linfo->lastend) {
  	*linfo->lastend = 0;
  	linfo->lastend = NULL;
    }
  
    if (size > *cursize) {
  	if (*array)
  		*array = (const char**) realloc(*array, size * sizeof(*array));
  	else
  		*array = (const char**) malloc(size * sizeof(*array));
  
  	*cursize = size;
    }
  
    for (i=0; i<size-1; i++)
	(*array)[i] = langinfo_nextstring(linfo, firstcode + i * (secondcode-firstcode) );
    (*array)[size-1] = NULL;
  }

  langinfo_emptystring(linfo, firstcode + i * (secondcode-firstcode));
}

// read an fixed size array
static void langinfo_readfixedarray(langinfo *linfo, const char **array, int cursize, s16 firstcode, s16 secondcode)
{
  int i;

  if (linfo->ucptr >= linfo->uncompsize)
	error("Read beyond end of language data.\n");

  {
    s16 size = langinfo_arraysize(linfo);
  
    if (linfo->lastend) {
  	*linfo->lastend = 0;
	linfo->lastend = NULL;
    }
  
    if (size > cursize)
	error("Fixed array too small at %d, need %d instead of %d.\n",
  		firstcode, size, cursize);
  
    for (i=0; i<size; i++)
	array[i] = langinfo_nextstring(linfo, firstcode + i * (secondcode-firstcode) );
  }
  langinfo_emptystring(linfo, firstcode + i * (secondcode-firstcode));
}

// process the language data read by loadcurlangdata()
void langinfo_processlangdata(langinfo *linfo)
{
  int i, j;

  linfo->langname = langinfo_name(linfo);
  linfo->langcode = langinfo_code(linfo);
  langinfo_readfixedarray(linfo, langtext, LANG_LASTSTRING+1, LANGCODE_TEXT(0), LANGCODE_TEXT(1));
//  langinfo_readfixedarray(linfo, switchnames, SWITCHNUM*2, LANGCODE_SWITCHES(0,0), LANGCODE_SWITCHES(0,1));
  langinfo_readfixedarray(linfo, switchnames, SWITCHNUMA*2, LANGCODE_SWITCHES(0,0), LANGCODE_SWITCHES(0,1));
  langinfo_readfixedarray(linfo, switchnames+SWITCHSTARTB*2, SWITCHNUMB*2, LANGCODE_SWITCHES(SWITCHSTARTB,0), LANGCODE_SWITCHES(SWITCHSTARTB,1));
  langinfo_readarray(linfo, &halflines, &numhalflines, LANGCODE_HALFLINES(0), LANGCODE_HALFLINES(1));
  for (i=0; i<BITSWITCHNUM; i++)
	langinfo_readfixedarray(linfo, bitswitchdesc[i], sizeof(bitswitchdesc[0])/sizeof(bitswitchdesc[0][0]),
		LANGCODE_BITSWITCH(i,0), LANGCODE_BITSWITCH(i,1));
  langinfo_emptystring(linfo, LANGCODE_END(0));

  langtext_isvalid = 1;
}

// read the in-game strings for a certain file size.  Return how many
// bytes of data there were, or 0 if wrong size.
// only returns size if target==NULL
u32 langinfo_readingamestrings(langinfo *linfo, u32 exesize, char *target, u32 targetsize, char *langid)
{
  u32 baseofs, nextofs, dataofs, foundofs;
  u32 numsizes, size, csize, ucsize, realucsize;
  u32 datsize = 0;
  u32 i, nlang;
  u32 magic;
  int result, found = 0;
  char *cbuf;
  FILE *f;
  static const char *external_text_file = "ttdpttxt.dat";

//  printf("Reading in-game language data from %x\n", dataloc(linfo, LANGINGAMEOFS));
  fseek(linfo->f, dataloc(linfo, LANGINGAMEOFS), SEEK_SET);
  fread(&baseofs, sizeof(baseofs), 1, linfo->f);

//  printf("Baseofs is %x\n",baseofs);
  fseek(linfo->f, dataloc(linfo, baseofs), SEEK_SET);
  fread(&nlang, sizeof(nlang), 1, linfo->f);
  nextofs = ftell(linfo->f);

  foundofs = 0;	// to make gcc happy
  for (i=0; (i<nlang) && !found; i++) {
//	printf("Language %d is at %x\n", i, nextofs);
	fseek(linfo->f, nextofs, SEEK_SET);
	nextofs += sizeof(nextofs);

	fread(&dataofs, sizeof(dataofs), 1, linfo->f);
	if (!i)
		foundofs = dataofs;

//	printf("The data is at %x\n", dataloc(linfo, dataofs));
	fseek(linfo->f, dataloc(linfo, dataofs), SEEK_SET);
	fread(&numsizes, 4, 1, linfo->f);
	fread(&ucsize, 4, 1, linfo->f);
	fread(&csize, 4, 1, linfo->f);

//	printf("Num sizes: %d  Ucsize: %d  Csize: %d\n", numsizes, ucsize, csize);
	while (numsizes--) {
		fread(&size, 4, 1, linfo->f);
//		printf("Size: %d\n", size);
		if (size == exesize) {
//			printf("Language %d has the right size!\n", i);
			found = 1;
			foundofs = dataofs;
			*langid = i;
			break;
		}
	}

	dataofs += 3*4 + numsizes*4;
  }
  if (found == -1) {
//	printf("No language has the right size, using default.\n");
	found = 0;	// use first language by default
	*langid = 0;
  }

  // it's the right size, uncompress (if necessary) the data
  fseek(linfo->f, dataloc(linfo, foundofs), SEEK_SET);
  fread(&numsizes, 4, 1, linfo->f);
  fread(&ucsize, 4, 1, linfo->f);
  fread(&csize, 4, 1, linfo->f);

	// also load ttdpttxt.dat if it exists and is correct

  f = fopen(external_text_file, "rb");
  if (f) {
		// try to use texts from ttdpttxt.dat instead
	fread(&magic, 4, 1, f);

	if (magic != MAGIC) {
		// show error messages only during actual loading, not when
		// determining size
		if (targetsize)
			warning(langtext[LANG_CUSTOMTXTINVALID], external_text_file);
	} else
		datsize++;	// good so far
  }
  if (datsize) {
	fread(&i, 4, 1, f);
	if (i !=  (MAGIC ^ 0x12345678)) {
		if (targetsize)
			warning(langtext[LANG_CUSTOMTXTINVALID], external_text_file);
		datsize--;
	}
  }
  if (datsize) {
	fread(&datsize, 4, 1, f);
	if (!targetsize) {
		fclose(f);
		return datsize + ucsize - 2;
	}

		// generic error message is fine; size should be right anyway
	if (datsize > targetsize) {
		warning(langtext[LANG_CUSTOMTXTINVALID], external_text_file);
		datsize = 0;
	} else {
		printf(langtext[LANG_LOADCUSTOMTEXTS], external_text_file);

		fread(target + ucsize - 2, 1, datsize, f);

		// could return here, but we need to set *langid
	}
  }
  if (f)
	fclose(f);

  if (!targetsize)
	return ucsize;

  if (datsize)
	datsize = -2;

  fseek(linfo->f, numsizes*4, SEEK_CUR);
  if (ucsize != csize) {
	int datid;

	// allocate buffers
	cbuf = (char*) malloc(csize);
	if (!cbuf)
		error("Error allocating %s buffer of %ld bytes for in-game language %d\n",
			"compressed", csize, found);

	// read compressed language data
	fread(cbuf, 1, csize, linfo->f);
	realucsize=ucsize;
	datid = *(u16*) (target+ucsize-2);
	result = uncompress( (Bytef*) target, &realucsize, (Bytef*) cbuf, csize);
	if (result != Z_OK)
		error("Uncompressing in-game language %d: error %d\n", found, result);

	free(cbuf);
	if (datsize)
		*(u16*) (target+ucsize-2) = datid;
  } else {
	// read uncompressed data
	fread(target, 1, ucsize + datsize, linfo->f);
  }

  return datsize + ucsize;
}
