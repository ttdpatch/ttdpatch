//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// error.c: abort with error message
//


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <conio.h>
#include "error.h"
#include "osfunc.h"
#include "language.h"
#include "switches.h"

// show error message and abort, without waiting for a key
void errornowait(const char s[], ...)
{
  va_list args;

  va_start(args, s);
  fflush(stdout);
  vfprintf(stderr, s, args);
  va_end(args);

  restoreconsize();

  exit(1);
}

// same as above but wait for key
void error(const char s[], ...)
{
  va_list args;

  va_start(args, s);
  fflush(stdout);
  vfprintf(stderr, s, args);
  va_end(args);

  fputs(langtext_isvalid ? langtext[LANG_PRESSANYKEY] : "Press any key to abort.", stderr);
  fflush(stderr);

  getch();
  fputs("\n", stderr);

  restoreconsize();

  exit(1);
}

// show warning message and wait for a key to continue (Esc - abort)
void warning(const char s[], ...)
{
  int c;
  va_list args;

  fflush(stdout);
  if (s == NULL) {
	// special case, used when TTDPatch is about to exit anyway,
	// so there's not much difference between "continue" and "abort",
	// but we still want the user to be able to read console messages
	if (debug_flags.warnwait == 0) {
		// langdata always loaded at that point
		fputs(langtext[LANG_PRESSANYKEY], stderr);
		fflush(stderr);
		getch();
		fputs("\n", stderr);
	}
	return;
  }

  va_start(args, s);
  vfprintf(stderr, s, args);
  va_end(args);

  if (debug_flags.warnwait == 0) {
	fputs(langtext_isvalid ?
		langtext[LANG_PRESSESCTOEXIT] :
		"Press Escape to abort, or any other key to continue.", stderr);
	fflush(stderr);
	c = getch();
	fputs("\n", stderr);
  } else if (debug_flags.warnwait < 0) {
	c = ' ';	// don't wait for key; don't abort
  } else {
	c = 27;
  }

  if (c == 27) errornowait(langtext_isvalid ? langtext[LANG_ABORTLOAD] : "Program load aborted.\n");
}
