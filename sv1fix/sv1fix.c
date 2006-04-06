/*
   sv1fix - Program to fix some bugs in TTD savegames
   Copyright (C) 2002 by Josef Drexler

   Distributed under the terms of the GNU General Public License.
*/

#include <stdlib.h>
#include <stdio.h>
#include <io.h>
#include <stdarg.h>
#include <string.h>
#include <conio.h>

#include "../types.h"

char *sv1codec = "sv1codec";
char *bigfile = "sv1fix.big";
char *tmpname = "sv1fix.tmp";

int verbose = 0;

char *tmpdata;

void die(const char s[], ...)
{
  va_list args;

  fflush(stdout);
  fflush(stderr);

  va_start(args, s);
  vfprintf(stderr, s, args);
  va_end(args);

  fputs("\nPress any key to abort.", stderr);

  getch();
  fputs("\n", stderr);

  exit(1);
}

void *myalloc(size_t size)
{
  void *p = malloc(size);
  if (!p)
	die("Not enough memory");
  return p;
}

int runsv1codec(char *exepath, char *args, ...)
{
  int result;
  va_list ap;
  char *cmdline, *cmdfile;

  va_start(ap, args);
  cmdline = tmpdata;
  strcpy(cmdline, exepath);

  cmdfile = strrchr(cmdline, '\\');
  if (!cmdfile)
	cmdfile = cmdline;		// no path component at all
  else
	cmdfile++;			// keep final backslash
  *cmdfile = 0;				// keep path; remove filename

  strcat(cmdline, sv1codec);
  strcat(cmdline, " ");
  vsprintf(cmdline + strlen(cmdline), args, ap);
  va_end(args);

  if (!verbose)
	  strcat(cmdline, ">nul");

  result = system(cmdline);
  if (result)
	die("Can't run %s, make sure it's installed (%s)",
		sv1codec, strerror(errno));

  return 1;
}

int gettitle(char *title, char *filename)
{
  FILE *f = fopen(filename, "rb");
  if (!f)
	die("Can't read %s: %s", filename, strerror(errno));

  fread(title, 1, 48, f);

  fclose(f);

  return 1;
}

#define doread(a,b,c,d) _doread(a,b,c,d,__LINE__)
size_t _doread(void *ptr, size_t size, size_t n, FILE *stream, int line)
{
  size_t res = fread(ptr, size, n, stream);
  if (res < n)
	die("Error reading (line %d), only got %d out of %d: %s", line, res, n, strerror(errno));
  return res;
}

#define dowrite(a,b,c,d) _dowrite(a,b,c,d,__LINE__)
size_t _dowrite(const void *ptr, size_t size, size_t n, FILE*stream, int line)
{
  size_t res = fwrite(ptr, size, n, stream);
  if (res < n)
	die("Error writing (line %d), only wrote %d out of %d: %s", line, res, n, strerror(errno));
  return res;
}

long morevehofs;
int problems = 0;
int fixed = 0;

long playerpos(int pl)
{
  return 0x52a62L + (long)pl * 0x3b2L;
}

int fix_forgotten_hq(FILE *f)
{
  u16 hq;
  int i, pl, row, col;
  unsigned char *rowdata, *rowdata2;

  rowdata = tmpdata;
  rowdata2 = tmpdata+256;


  for (pl=0; pl<8; pl++) {
	fseek(f, playerpos(pl), SEEK_SET);
	doread(&hq, 2, 1, f);
	if (!hq) {
		if (verbose) printf("Player %d does not exist.\n", pl);
		continue;
	}
	if (verbose) printf("Player %d exists.\n", pl);
	fseek(f, playerpos(pl) + 0x3a4, SEEK_SET);
	doread(&hq, 2, 1, f);
	if (hq) {
		if (verbose) printf("HQ is OK (at %04x).\n", hq);
		continue;
	}
	printf("Player %d's headquarters are missing!\n", pl);
	problems++;

	for (row=0; !hq && row<255; row++) {
		fseek(f, 0x77179L + morevehofs + row * 256L, SEEK_SET);
		doread(rowdata, 1, 256, f);

		for (col=0; !hq && col<255; col++) {
			if ( ( (rowdata[col] & 0xf0) != 0xa0) ||
			     ( (rowdata[col+1] & 0xf0) != 0xa0) )
				continue;

			hq = (row << 8) + col;
			if (verbose) printf("Could be at %04x\n", hq);
			doread(rowdata2, 1, 256, f);
			if ( ( (rowdata2[col] & 0xf0) != 0xa0) ||
			     ( (rowdata2[col+1] & 0xf0) != 0xa0) ) {
				if (verbose) printf("Nope, next row doesn't match.\n");
				hq = 0;
				continue;
			}

			fseek(f, 0x87179L + morevehofs + hq, SEEK_SET);
printf("Now at %lx for %lx\n", ftell(f), (long) hq);
			doread(rowdata2, 1, 2, f);
			fseek(f, 254, SEEK_CUR);
			doread(rowdata2+2, 1, 2, f);

			for (i=0; i<4; i++) {
				if ( (rowdata2[i] < 0x80) ||
				     (rowdata2[i] > 0x93) )
					hq = 0;
			}
			if (!hq) {
				if (verbose) printf("Nope, it's not an HQ.\n");
				continue;
			}

			fseek(f, 0x4cba + hq, SEEK_SET);
			doread(rowdata2, 1, 2, f);
			fseek(f, 254, SEEK_CUR);
			doread(rowdata2+2, 1, 2, f);

			for (i=0; i<4; i++) {
				if (rowdata2[i] != pl)
					hq=0;
			}
			if (!hq) {
				if (verbose) printf("Nope, it's the wrong player!\n");
				continue;
			}

			if (verbose) printf("Yes, it's the HQ at %4x, so let's fix it.\n", hq);
			fseek(f, playerpos(pl) + 0x3a4, SEEK_SET);
			dowrite(&hq, 2, 1, f);

			rowdata[0] = 0;
			rowdata[1] = 0;
			fseek(f, 0x87179L + morevehofs, SEEK_SET);
			dowrite(rowdata, 1, 2, f);
			fseek(f, 0x87179L + morevehofs + 256L, SEEK_SET);
			dowrite(rowdata, 1, 2, f);

			printf("Fixed headquarters location for player %d.\n", pl);
			fixed++;
		}
	}

  }
  return 1;
}

int fix_aborted_subsidy(FILE *f)
{
  int subs;
  u8 cargotype, age, from, to, facil1, facil2;
  u16 fromxy, toxy;

  for (subs=0; subs<8; subs++) {
	fseek(f, 0x76da4L + morevehofs + subs*4L, SEEK_SET);
	doread(&cargotype, 1, 1, f);
	doread(&age, 1, 1, f);
	doread(&from, 1, 1, f);
	doread(&to, 1, 1, f);

	if (verbose) printf("Subsidy %d for %d is %d months old, from %d to %d\n",
				subs, cargotype, age-12, from, to);

	if (cargotype == 0xff)
		continue;
	if (age < 12)
		continue;

	if (from > 0xfd)
		die("Invalid station number %d", from);
	if (to > 0xfd)
		die("Invalid station number %d", to);
	if (cargotype > 12)
		die("Invalid cargo type %d", cargotype);

	fseek(f, 0x48cbaL + from*0x8eL, SEEK_SET);
	doread(&fromxy, 2, 1, f);
	fseek(f, 0x7e, SEEK_CUR);
	doread(&facil1, 1, 1, f);

	fseek(f, 0x48cbaL + to*0x8eL, SEEK_SET);
	doread(&toxy, 2, 1, f);
	fseek(f, 0x7e, SEEK_CUR);
	doread(&facil2, 1, 1, f);

	if (fromxy && toxy && facil1 && facil2) {
		if (verbose) printf("Both stations are OK. (%04x/%02x and %04x/%02x)\n",
				fromxy, facil1, toxy, facil2);
		continue;
	}

	printf("Subsidy %d is missing a station!\n", subs);
	problems++;

	cargotype = 0xff;
	fseek(f, 0x76da4L + morevehofs + subs*4L, SEEK_SET);
	dowrite(&cargotype, 1, 1, f);

	printf("Subsidy removed.\n");
	fixed++;
  }

  return 1;
}

int fixfile(char *filename)
{
  char vehfact;
  FILE *f = fopen(filename, "r+b");
  if (!f)
	die("Can't open %s: %s", filename, strerror(errno));

  fseek(f, 0x24cba, SEEK_SET);
  fread(&vehfact, 1, 1, f);
  vehfact += vehfact < 2;

  morevehofs = 850L * 128L * (long) (vehfact-1);

  if (vehfact > 40)
	die("Invalid morevehicles setting %d", vehfact);

//  printf("Morevehicles setting: %d (offset %lx)\n", vehfact, morevehofs);

  fix_forgotten_hq(f);
  fix_aborted_subsidy(f);

  if (problems) 
	printf("Fixed %d out of %d problems.\n", fixed, problems);
  else
	printf("No problems found.\n");

  fclose(f);
  return 1;
}

int main(int argc, char **argv)
{
  char *filename, *bakfile;
  char *c;
  char title[48];

  printf("sv1fix V0.04 - fix bugs in TTD savegames.  Copyright (C) 2003 by Josef Drexler.\n");
  if (argc < 2)
	die("Usage: sv1fix <sv1-filename>");

  tmpdata = myalloc(1024);

  filename = argv[1];

  if (stricmp(filename, "-v") == 0) {
	filename = argv[2];
	verbose = 1;
  }

  if (access(filename, 06))
	die("Can't read/write %s: %s", filename, strerror(errno));

  gettitle(title, filename);
  printf("Decoding %s (using %s)\nName: %s\n", filename, sv1codec, title);

  if (!access(bigfile, 06))
	if (remove(bigfile))
		die("Can't delete old %s: %s", bigfile, strerror(errno));

  runsv1codec(argv[0], "-f -d %s -o %s", filename, bigfile);

  if (access(bigfile, 06))
	die("Can't read/write %s: %s", bigfile, strerror(errno));

  fixfile(bigfile);

  if (verbose) printf("Encoding %s into %s\n", bigfile, tmpname);
  runsv1codec(argv[0], "-e %s -ttd -o %s -title \"%s\"", bigfile, tmpname, title);

	// make backup file name
  bakfile = tmpdata;
  strcpy(bakfile, filename);
  c = bakfile + strlen(bakfile);
  while ( (c > bakfile) && (*c != '\\') && (*c != '/'))
	c--;
  while (*c && (*c != '.'))
	c++;
  strcpy(c, ".bak");

  if (access(bakfile, 0)) {
	printf("Making backup %s\n", bakfile);
	if (rename(filename, bakfile))
		die("Can't rename %s to %s: %s", filename, bakfile, strerror(errno));
  }
  if (!access(filename, 0))
	if (remove(filename))
		die("Can't replace %s: %s", filename, strerror(errno));

  if (rename(tmpname, filename))
	die("Can't rename %s to %s: %s", tmpname, filename, strerror(errno));

  if (!access(bigfile, 06))
	if (remove(bigfile))
		die("Can't delete old %s: %s", bigfile, strerror(errno));

  printf("Done!\nPress any key to exit.");
  fflush(stdout);
  getch();

  return 1;
}
