//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// checkexe.c: create ttdload(w).ovl and ensure it is correct
//

#if WINTTDX == 1
   #include <windows.h>
#endif

#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <ctype.h>

#define IS_CHECKEXE_CPP
#include "language.h"
#include "error.h"
#include "grep.h"
#include "checkexe.h"
#include "switches.h"
#include "loadver.h"
#include "loadlng.h"
#include "osfunc.h"

enum langtextids customsystexts[] = {
	#define systxt(id) id,
	#include "systexts.h"
	#undef systxt
};

extern langinfo *linfo;
extern int forcerebuildovl;

void checkversion(u32 programversion, u32 programsize)
{
  int num, numversions;
  char ch;
  pversioninfo knownversion;

  knownversion = NULL;

  numversions = sizeof(versions) / sizeof(versions[0]);
  if (getf(recordversiondata) || (debug_flags.useversioninfo))
	numversions = -1;

  for (num=0; num<numversions; num++)
	if (versions[num]->h.version != NOVERSION) {
		if ( (versions[num]->h.version == programversion) &&
		     (versions[num]->h.filesize == programsize) ) {
			printf(langtext[LANG_KNOWNVERSION]);
			knownversion = versions[num];
			break;
		}
	}

  if (knownversion != NULL) {
	curversion = knownversion;
	return;
  }

  curversion = malloc(sizeof(versionheader));
  if (!curversion)
	error(langtext[LANG_NOTENOUGHMEM], "curversion", sizeof(versionheader)/1024+1);

  curversion->h.numoffsets = 0;
  curversion->h.version = 0xffffffff;
  curversion->h.filesize = programsize;

  if (programversion == NOVERSION-1)
    return;

  // unknown version.  Store at least the size, so that the crash handler
  // can write something useful

  if (!alwaysrun) {
	printf(langtext[LANG_WRONGVERSION]);


	fflush(stdout);
	ch = tolower(getche());
	printf("\n");

	/*
	int isyes = 0;
	for (unsigned int keynum=0; keynum<strlen(langtext[LANG_YESKEYS]); keynum++)
		if (ch == langtext[LANG_YESKEYS][keynum]) {
			isyes = 1;
			break;
		}

	if (isyes)
	*/

	if (strchr(langtext[LANG_YESKEYS], ch))
		printf(langtext[LANG_CONTINUELOAD]);
	else
		errornowait(langtext[LANG_ABORTLOAD]);

  } else
	printf(langtext[LANG_WARNVERSION]);

  if (getf(recordversiondata))
	allswitches(1, 1);
}

u32 loadingamestrings(u32 programsize)
{

  // find out size of the in-game strings
  customtextsize = langinfo_readingamestrings(linfo, programsize, NULL, 0,
			&(flags->data.languageid) );

  customtexts = malloc(customtextsize);
  if (!customtexts)
	error(langtext[LANG_NOTENOUGHMEM], "ingamestrings", customtextsize/1024+1);

  // load the corresponding in-game strings. The "2" is the number of offsets.
  langinfo_readingamestrings(linfo, programsize, customtexts, customtextsize,
			&(flags->data.languageid) );

  return customtextsize;
}

size_t getncustomsystexts(void) {
  return sizeof(customsystexts)/sizeof(customsystexts[0]);
}



extern char *patchedfilename;

FILE *f;
int iswriting;

void openexe(const char *exenames[])
{
  int i;
  const char *s = NULL;	// to make gcc happy
  char command[128];

  f = forcerebuildovl?NULL:fopen(patchedfilename, "rb");
  if (!f) {
	printf(patchedfilename);
	printf(langtext[LANG_OVLNOTFOUND]);
	for (i=0; exenames[i] && (!f); i++) {
		s = exenames[i];
		f = fopen(s, "rb");
		if (!f) {
			char *errmsg = strerror(errno);
			printf("%s: %s", s, errmsg);
			if (!strchr(errmsg, '\n')) printf("\n");
		}
	}
	if (!f)
		error(langtext[i > 1 ? LANG_NOFILESFOUND : LANG_NOFILEFOUND], s);

	fclose(f);
#if WINTTDX
	printf(langtext[LANG_SHOWCOPYING], s, patchedfilename);
	printf("\n");

	i = CopyFile(s, patchedfilename, FALSE);

	if (i == FALSE)
		error(langtext[LANG_COPYERROR_RUN], "CopyFile"); // FIXME: a new language string might be better
#else
	sprintf(command, "COPY %s %s >nul", s, patchedfilename);
	printf(langtext[LANG_SHOWCOPYING], s, patchedfilename);
	printf(":\n%s /C %s\n", getenv("COMSPEC"), command);
	i = system(command);
	if (i == -1)
		error(langtext[LANG_COPYERROR_RUN], getenv("COMSPEC"));
#endif

	f = fopen(patchedfilename, "rb");
	if (!f)
		error(langtext[LANG_COPYERROR_NOEXIST], patchedfilename);
  };

  iswriting = 0;
  return;
}

void startwrite(void)
{
  if (!iswriting) {
	fclose(f);
	f = fopen(patchedfilename, "r+b");
	if (!f)
		error(langtext[LANG_WRITEERROR], patchedfilename);
	iswriting = 1;
  }

}

u32 getval(u32 pos, int size)
{
  {
    u32 value = 0;
  
    if (pos)
  	fseek(f, pos, SEEK_SET);
    fread(&value, size, 1, f);
  
    return value;
  }
}

void setval(u32 pos, int size, u32 value)
{
  startwrite();
  if (pos)
	fseek(f, pos, SEEK_SET);
  fwrite(&value, size, 1, f);
}

int ensureval(u32 pos, int size, u32 value)
{
  {
    u32 oldval = getval(pos, size);
  
    if (oldval != value) {
  	setval(pos, size, value);
  	return oldval;
    }
  }
  return 0;
}

u32 exeinfo(u32 *newexeid)
{
  u32 newexepos;

  {
    char b = getval(0x18, 1);
  
    if (b != 0x40)
      error(langtext[LANG_INVALIDEXE]);
  }

	// Check which version it is
  newexepos = getval(0x3c, 4);
  *newexeid = getval(newexepos, 4);

  return newexepos;
}

int setseglen(u32 seglenpos, u32 min, u32 max, u32 newlen, u32 altlen)
{
  u32 seglen;

  seglen = getval(seglenpos, 4);
  min <<= 16;
  max <<= 16;
  newlen <<= 16;
  altlen <<= 16;

		// set the new code/data segment size
  if ( ( (seglen < min) || (seglen > max) )
      && (seglen != newlen) && (seglen != altlen) ) {
	printf(langtext[LANG_INVALIDSEGMENTLEN], seglen);
	error(langtext[LANG_DELETEOVL], patchedfilename);
  }

  if (seglen != newlen) {
		// show new size, rounded up to half an MB

//	printf(langtext[LANG_INCREASECODELENGTH], ((newlen>>19)+1) / 2.0);
// stupid, the above need floating point libs; what a waste.
//

	int newmb = (newlen>>19)+1;
	char number[32];
	sprintf(number, "%d.%d", newmb >> 1, (newmb&1)*5);

	printf(langtext[LANG_INCREASECODELENGTH], number);

	setval(seglenpos, 4, newlen);
	return 1;
  }

  return 0;
}

void versiontotext(s32 version, s32 filesize, int shorttype, char *dest)
{
  if (shorttype)
	sprintf(dest, "%1d%03d%04X",
		(int) (version >> 16) & 0xff,
		(int) version & 0xffff,
		(int) ( ((s32) filesize - (s32) filesizebase) >> filesizeshr) );
  else
	sprintf(dest, "V%d.%02d.%03d, %s %lu",
		(int) (version >> 24) & 0xff,
		(int) (version >> 16) & 0xff,
		(int) version & 0xffff,
		langtext[LANG_SIZE],
		(u32) filesize);
}

void versioninfototext(pversioninfo version, int shorttype, char *dest)
{
  versiontotext(version->h.version, version->h.filesize, shorttype, dest);
}

void checkexeversion(void)
{
  u32 pos, oldpos;
  char b, *s, *vername, *prog, vertext[128];
  int verdig[4], i;

  pos = grepfile(f, "Sawyer", 6, 2, -1);
  if (pos == GREP_NOMATCH)
    error(langtext[LANG_VERSIONUNCONFIRMED]);
  fseek(f, pos, SEEK_SET);

  pos = grepfile(f, "Versi", 5, 1, -1);
  if (pos == GREP_NOMATCH)
    error(langtext[LANG_VERSIONUNCONFIRMED]);

  fseek(f, pos, SEEK_SET);

  s = (char*) malloc(256);

  fread(s, 1, 256, f);
	// s contains something like "V2.01.119  21st September etc..."
	// this finds the version number part

	// These loops are no operation loops - just increase pos
	// First, find the string end, a < ' ' char or '$'
  for (pos=0; (pos < 255) && (s[pos] >= ' ') && (s[pos] != '$'); pos++);
  s[pos] = 0;

	// Now find the first digit in it
  for (pos=0; (pos < 255) && (s[pos] != '.') && (!isdigit(s[pos]) ); pos++);

  vername = &(s[pos]);
	//  s := copy(s, pos, 255);!!

	// and the first space
  for (pos=0; (vername[pos] != 0) && (vername[pos] != ' '); pos++);
  b = vername[pos];
  oldpos = pos;
  vername[pos] = 0;

	// vername is now of the form "2.01.119" or "3.02.011"

  if (vername[0] == '3')
	fseek(f, 16, SEEK_CUR);	// In the Windows version the program string comes after the version
  else
	fseek(f, 0, SEEK_SET);

  pos = grepfile(f, vername, strlen(vername), 1, -1);	// find this version again to get the program name
  if (pos == GREP_NOMATCH)
    error(langtext[LANG_VERSIONUNCONFIRMED]);
  vername[oldpos] = b;
  vername = strdup(vername);

  fseek(f, pos - 128, SEEK_SET);
  fread(s, 1, 256, f);

	// find string beginning
  for (pos=128; (pos > 0) && (s[pos] >= ' ') && (s[pos] != '$'); pos--);
  prog = &(s[++pos]);

	// ...and end
  for (pos=0; (pos < 255) && (prog[pos] >= ' ') && (prog[pos] != '$'); pos++);
  prog[pos] = 0;

  printf(langtext[LANG_PROGANDVER], prog, vername);

  pos = 0;
  verdig[pos] = 0;

	// parse the version string into the three numbers
  for (i=0; (vername[i] != 0) && (isdigit(vername[i]) || (vername[i] == '.') ); i++)
	if (vername[i] == '.') {
		pos++;
		verdig[pos] = 0;
	} else {
		if (pos >= 3)
			error(langtext[LANG_TOOMANYNUMBERS]);
		verdig[pos] *= 10;
		verdig[pos] += vername[i] - '0';
	}

  if (pos < 2)
	error(langtext[LANG_VERSIONUNCONFIRMED]);

  if ( (verdig[0] != 2) && (verdig[0] != 3) )
    error(langtext[LANG_WRONGPROGRAM]);

  free(vername);
  free(s);

  fseek(f, 0, SEEK_END);
  pos = ftell(f);
  newversion =	( (u32) verdig[0] << 24) |
		( (u32) verdig[1] << 16) |
		( (u32) verdig[2] );
  newfilesize = pos;
  versiontotext(newversion, newfilesize, 0, vertext);
  printf(langtext[LANG_PARSEDVERSION], vertext);

}

u32 checkexe(FILE **outf, const char *exenames[], u32 thisneid, const char *thistype)
{
  u32 newexepos, newexeid;

  openexe(exenames);

  newexepos = exeinfo(&newexeid);

  if (newexeid == maketwochars('P','E'))
	printf(langtext[LANG_ISWINDOWSEXE]);
  else if  ( (u16) newexeid == maketwochars('P','3')) {
	newexeid = (u16) newexeid;	// use only two bytes in this case
	printf(langtext[LANG_ISDOSEXTEXE]);
  } else
	printf(langtext[LANG_ISUNKNOWNEXE]);

  if (newexeid != thisneid)
	error(langtext[LANG_NOTSUPPORTED], thistype);

  checkexeversion();

  *outf = f;

  return newexepos;
}

