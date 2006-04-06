/*
   sv2flip - Program to flip players in a TTD savegame
   Copyright (C) 2003 by Josef Drexler

   Distributed under the terms of the GNU General Public License.
*/

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <conio.h>

char *sv1codec = "sv1codec";
char *bigfile = "sv2flip.big";
char *tmpname = "sv2flip.tmp";

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
  *cmdfile = 0;				// keep path; remove filename

  strcat(cmdline, "\\");
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


int main(int argc, char **argv)
{
  FILE *f;
  char *filename, *bakfile;
  char *c, vehfact;
  char title[48];
  unsigned char p[2], op[2], t;
  long morevehofs, magic;

  printf("sv2flip V0.03 - flip TTD players.  Copyright (C) 2003 by Josef Drexler.\n");
  if (argc < 2)
	die("Usage: sv2flip <sv2-filename>");

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

  f = fopen(bigfile, "r+b");

  fseek(f, 0x24cba, SEEK_SET);
  fread(&vehfact, 1, 1, f);
  vehfact += vehfact < 2;

  morevehofs = 850L * 128L * (long) (vehfact-1);

  if (vehfact > 40)
	die("Invalid morevehicles setting %d", vehfact);

//  printf("Morevehicles setting: %d (offset %lx)\n", vehfact, morevehofs);

  fseek(f, 0x770f8L + morevehofs, SEEK_SET);
  fread(p, 2, 1, f);
  fseek(f, -2, SEEK_CUR);

  printf("Before:  Player1=%d  Player2=%d\n", p[0], p[1]);

  if (p[1] > 8) {
	printf("Error: Not a multiplayer game.\nAborted.\n");
	exit(1);
  }

  t = p[0]; p[0] = p[1]; p[1] = t;

  printf("After:   Player1=%d  Player2=%d\n", p[0], p[1]);

  fwrite(p, 2, 1, f);

  fseek(f, 0x44cb4, SEEK_SET);
  fread(&magic, 1, 4, f);
  if (magic == 0x70445454) {
	if (verbose) printf("Using new TTDPatch 2.0 structure\n");
	fseek(f, 0x44ace, SEEK_SET);
  } else {
	if (verbose) printf("Using old pre-TTDPatch 2.0 structure\n");
	fseek(f, 0x24cc2, SEEK_SET);
  }
  fread(op, 2, 1, f);
  fseek(f, -2, SEEK_CUR);

  if (verbose || p[0] != op[1] || p[1] != op[0])
	printf("Before:  OrgPlayer1=%d  OrgPlayer2=%d\n", op[0], op[1]);

  t = op[0]; op[0] = op[1]; op[1] = t;

  if (verbose || p[0] != op[0] || p[1] != op[1])
	printf("After:   OrgPlayer1=%d  OrgPlayer2=%d\n", op[0], op[1]);

  fwrite(op, 2, 1, f);

  fclose(f);

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
