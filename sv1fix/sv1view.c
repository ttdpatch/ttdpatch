/*
   sv1view - Program to view structure of TTD savegames
   Copyright (C) 2004 by Josef Drexler

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
char *bigfile = "sv1view.big";

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

char *optchunks[5] = {
	"TTD Vehicle data",
	"TTDPatch Vehicle data",
	"old list of GRF IDs",
	"TTDPatch version and configuration",
	"enhancegui options",
	};

char *mandchunks[5] = {
	"Town array extension",
	"Landscape 6 array",
	"New Station ID map",
	"Landscape 7 array",
	"List of GRF IDs",
	};


int viewfile(char *filename)
{
  char vehfact;
  int i;
  u16 numchunks;

  FILE *f = fopen(filename, "r+b");
  if (!f)
	die("Can't open %s: %s", filename, strerror(errno));

  fseek(f, 0x24cba, SEEK_SET);
  fread(&vehfact, 1, 1, f);
  vehfact += vehfact < 2;

  morevehofs = 850L * 128L * (long) (vehfact-1);

  if (vehfact > 40)
	die("Invalid morevehicles setting %d", vehfact);

  printf("Morevehicles setting: %d (offset %lx)\n", vehfact, morevehofs);

  fseek(f, 0x44cb8, SEEK_SET);
  fread(&numchunks, 2, 1, f);

  printf("%d TTDPatch chunks present\n", numchunks);

  fseek(f, 0x97179 + morevehofs, SEEK_SET);
  printf("Main data: 000000 L%06lx\n", ftell(f));

  for (i=0; i<numchunks; i++) {
	u16 id;
	u32 length;

	printf("Chunk %d: %06lx ", i, ftell(f));

	fread(&id, 2, 1, f);
	fread(&length, 4, 1, f);

	printf("L%06lx  ID %04x  ", length, id);
	if (id&0x8000) {
		id &= ~0x8000;
		printf("%s\n", id < sizeof(mandchunks) ? mandchunks[id] : "unknown chunk");
	} else {
		printf("%s\n", id < sizeof(optchunks) ? optchunks[id] : "unknown chunk");
	}

	fseek(f, length, SEEK_CUR);
  }

  printf("End of chunks: %06lx\n", ftell(f));

  fseek(f, 0, SEEK_END);
  printf("Filesize: %06lx\n", ftell(f));

  fclose(f);
  return 1;
}

int main(int argc, char **argv)
{
  char *filename, *bakfile;
  char *c;
  char title[48];

  printf("sv1view V0.01 - view structure of TTD savegames.  Copyright (C) 2004 by Josef Drexler.\n");
  if (argc < 2)
	die("Usage: sv1view <sv1-filename>");

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

  viewfile(bigfile);

  printf("Done!\nPress any key to exit.");
  fflush(stdout);
  getch();

  return 1;
}
