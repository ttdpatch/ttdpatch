//
// This file is part of TTDPatch
// Copyright (C) 1999-2001 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// ttdstart.c: main file
//


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "types.h"
#include "error.h"

#if WINTTDX
#	include "versionw.h"
	const char *patchedfilename = "TTDLOADW.OVL";
#else
#	include "versiond.h"
	const char *patchedfilename = "TTDLOAD.OVL";
#endif

unsigned int grep_blksize = 4096;

#define IS_TTDSTART_CPP 1
#include "language.h"
#include "loadlng.h"
#include "osfunc.h"
#include "switches.h"
#include "checkexe.h"
#include "auxfiles.h"


langinfo *linfo;


void saveversion(int wasgood)
{
  char s1[40], s2[40], verfilename[40];
  FILE *f;
  int i, count;

  curversion->h.version = newversion;
  curversion->h.filesize = newfilesize;

  versioninfototext(curversion, 1, s1);
  versioninfototext(curversion, 0, s2);

  sprintf(verfilename, "%s.ver", s1);

  if (wasgood)
	printf("Version information succesfully collected.\n");
  else {
	printf("FAILED to collect version information.\n");
	return;
  }

  printf("Writing the collected information to %s.\n\n", verfilename);

  f = fopen(verfilename, "wt");
  fprintf(f, "// Version information for %s\n"
	     "\n"
	     "\t{ 0x%lX, 0x%lX, %ld,\n\n\t  ",
	     s2, curversion->h.version, curversion->h.filesize, curversion->h.numoffsets);

  for (i=count=0; i<curversion->h.numoffsets; i++, count++) {
	if(curversion->versionoffsets[i] & 0xff000000 || (count ==5)) {
		fprintf(f, "%s\n\t  ", curversion->versionoffsets[i] & 0xff000000 ? "\n" : "");
		count=0;
	}
	fprintf(f, "0x%lX%s", curversion->versionoffsets[i],
		(i < curversion->h.numoffsets - 1)?", ":"\n\t};\n");
  }
  fclose(f);
}


void getlangdata(langinfo *info)
{
  langinfo_loadcurlangdata(info);
  langinfo_processlangdata(info);
  return;
}

void initlanguage(langinfo *info)
{
  int text;
  s16 lang, deflang;
  char *envlang;

  // find country code
  lang = getdefaultlanguage(info);
  if (lang == -1) lang = 0;	// default not found, use first language
  deflang = lang;

  envlang = getenv("LANG");
  if (!envlang) envlang = getenv("LANGUAGE");
  if (envlang) {
	lang = langinfo_findlang(info, envlang);
	if (lang == -1) lang = langinfo_findlangfromcc(info, envlang);
	if (lang == -1) lang = langinfo_findlangfromcode(info, envlang);

	if (lang == -1) {
		printf(	"Unknown language '%s' specified in the environment \n"
			"variable LANG or LANGUAGE. Known languages:\n",
			envlang);

		for (lang=0; lang<langinfo_number(info); lang++) {
			langinfo_loadlang(info, lang);
			langinfo_loadcurlangdata(info);
			printf("%s %s (%s)", lang==0?"":",",
				langinfo_name(info), langinfo_code(info));
			langinfo_freebuf(linfo);
		}

		printf("\nUse SET LANG=language to select the language.\n"
			"E.g. SET LANG=french\n"
			"  or SET LANG=es\n\n"
			"Using English instead.\n\n");

		lang = deflang;
	}

  }

  langinfo_loadlang(info, lang);
  getlangdata(info);

}

// FIXME: better cprintf(), one for DOS and one for Windows
static int my_cprintf(const char *format, ...) {
  va_list args;
  int n;

  va_start(args, format);
  n = vprintf(format, args);
  va_end(args);
  fflush(stdout);
  return n;
}

int main(int argc, char **argv)
{
  _protptr protptr;
  int result;

  atexit(&auxcloseall);

  setexename(argv[0]);

  initializewindow();

  check_debug_switches(&argc, (const char *const **)&argv);
  if ((debug_flags.runcmdline > 0) && argv[0])
	patchedfilename = argv[0];

  linfo = langinfo_new();

  initlanguage(linfo);

  if (debug_flags.dumpswitches)
	return dumpswitches(debug_flags.dumpswitches);

  printf("TTDPatch V%s%s", TTDPATCHVERSION, langtext[LANG_STARTING]);

  flags = calloc(sizeof(paramset), 1);
  if (!flags)
	error(langtext[LANG_NOTENOUGHMEM], "malloc(flags)", sizeof(paramset));

  flags->magic = MAGIC;

  commandline(argc, (const char **)argv);

  if (debug_flags.terminatettd < 0)
	return 0;

  if (debug_flags.checkttd >= 0) {
	checkpatch();
  }

  if (showswitches) {
	static struct consoleinfo console = {
		-1, -1, 0,
		my_cprintf,
		setcursorxy,
		clrconsole,
	};
	getconsoleinfo(&console.width, &console.height, &console.attrib);
	showtheswitches(&console);
  }

  if (flags->data.vehicledatafactor > 0)
	setf1(uselargerarray);
  if (getf(gradualloading) && !getf(recordversiondata))
	clearf(improvedloadtimes);

  result = runttd(patchedfilename, ttdoptions, &linfo);

  printf(langtext[LANG_RUNRESULT],
	result?langtext[LANG_RUNRESULTERROR]:langtext[LANG_RUNRESULTOK]);

  if (getf(recordversiondata))
	saveversion(!result);

  if ((unsigned)result > 1 && result != 127)
	warning(NULL);

  langinfo_delete(linfo);

  restoreconsize();

  return result;
}
