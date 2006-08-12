//
// This file is part of TTDPatch
// Copyright (C) 1999-2003 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// auxfiles.c: functions to handle auxiliary data files, either attached
//	to the patch executable or as separate files
//

#include <stdlib.h>
#include "grep.h"
#include "error.h"
#include "switches.h"
#include "auxfiles.h"

// definitions of the available auxiliary files
typedef struct {
	signed char *debugswitch;	// pointer to corresponding debug switch
	const char *filename;		// filename to use if debug switch is set
	char code[CODELEN+1];		// code by which to find the attachment
	int nocodecheck;		// the external file should not be checked
					// for the code or correctness

	// usually uninitialized
	char xored;
	FILE *f;
} attachment_t;

static char *exename;
static FILE *exefile;

#if WINTTDX
	#define PROTCODEFILE "ttdprotw.bin"
#elif LINTTDX
	#define PROTCODEFILE "ttdprotl.bin"
#else
	#define PROTCODEFILE "ttdprotd.bin"
#endif

static attachment_t attachments[AUX_NUM] = {
	{ &debug_flags.langdatafile, "language.dat", LANGCODE },
	{ &debug_flags.protcodefile, PROTCODEFILE, PROTCODE },
	{ &debug_flags.relocofsfile, "reloc.bin", RELOCOFS },
	{ &debug_flags.patchdllfile, "ttdpatch.dll", PATCHDLL, 1 },
};

static char *langcode = attachments[AUX_PROTCODE].code;

static int auxopen(int auxnum);


int findattachment(int auxnum, u32 *ofs, FILE **f)
{
  int i;
  u32 newofs;

  if (!attachments[auxnum].xored) {
	for (i=0; i<CODELEN; i++)	// it's XOR'd in the EXE file
		attachments[auxnum].code[i] ^= 32;
	attachments[auxnum].xored = 1;
  }

  if (auxopen(auxnum) && attachments[auxnum].nocodecheck) {
	*ofs = 0;
	*f = attachments[auxnum].f;
	return 2;
  }

  *ofs = GREP_NOMATCHL;
  fseek(attachments[auxnum].f, 0, SEEK_SET);

	// find last occurence of string to make overwriting possible
  do {
	newofs = grepfile(attachments[auxnum].f, attachments[auxnum].code, CODELEN, 1, -1);
	if (newofs != GREP_NOMATCHL)
		*ofs = newofs + CODELEN;

  } while (newofs != GREP_NOMATCHL);

  *f = attachments[auxnum].f;

  return *ofs != GREP_NOMATCHL;
}

void setexename(char *cmdline) {
  FILE *f;

  f = fopen(cmdline, "rb");
  if (!f) {
	exename = malloc(strlen(cmdline)+5);
	strcpy(exename, cmdline);
	strcat(exename, ".exe");
	f = fopen(exename, "rb");
	if (!f)
		error("Fatal error: Could open neither %s nor %s.\n",
			cmdline, exename);
  } else {
	exename = strdup(cmdline);
  }

  fclose(f);
}

static int auxopen(int auxnum)
{
  const char *filename;
  int type;

  if (*attachments[auxnum].debugswitch != 1) {
	if (!exefile)
		exefile = fopen(exename, "rb");
	attachments[auxnum].f = exefile;
	filename = exename;
	type = 0;
  } else {
	attachments[auxnum].f = fopen(attachments[auxnum].filename, "rb");
	filename = attachments[auxnum].filename;
	type = 1;
  }
  if (!attachments[auxnum].f)
	error("Fatal error: Couldn't open %s.\n", filename);
  return type;
}

static int auxclose(int auxnum)
{
  int ret = 1;
  int i, from, to;
  int closeexe = 0;

  if (auxnum == AUX_ALL) {
	from = AUX_FIRST;
	to = AUX_LAST;
	closeexe = 1;
  } else
	from = to = auxnum;

  for (i = from; i<=to; i++) {
	if (attachments[i].f) {
		if (*attachments[i].debugswitch != 1)
			closeexe = 1;
		else {
			if (fclose(attachments[i].f))
				ret = 0;
			attachments[i].f = NULL;
		}
	}
  }
  if (closeexe && exefile) {
	if (fclose(exefile))
		ret = 0;
	exefile = NULL;
  }

  return ret;
}

void auxcloseall()
{
  auxclose(AUX_ALL);
}
