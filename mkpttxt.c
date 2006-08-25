/*
  mkpttxt.c - convert ttdpttxt.txt into ttdpttxt.dat

  Copyright (C) 2002-2003 by Josef Drexler <jdrexler@uwo.ca>

  Distributed under the GNU General Public License.
*/

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>

#define WANTINGAMETEXTNAMES
#include "inc/ourtext.h"

#define C
#include "common.h"
#include "types.h"

typedef struct {
	char *data;
	u32 size;
	u32 numfilesizes;
	u32 filesizes[2];	// number of entries is actually variable
} ingame, *pingame;


#ifdef DOS
pingame pascal ingamelang_ptr[] = {NULL};
#else
extern u32 ingamelang_num;
extern pingame ingamelang_ptr[];
#endif

static int allocsize = 32768;

static void error(const char s[], ...)
{
  va_list args;

  va_start(args, s);
  vfprintf(stderr, s, args);
  va_end(args);

  exit(1);
}

#ifdef __POWERPC__
static inline u32 littleendian(u32 in, int size)
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
#else
static inline u32 littleendian(u32 in, int size) { return in; }
#endif

static char *data;
static char *entries[TXT_last+1];
static int lengths[TXT_last+1];
static int defined[TXT_last+1];
static int txtindex, linelen;
static pingame defstr;

static const char *txtname = "ttdpttxt.txt";
static const char *datname = "ttdpttxt.dat";
static const char *tmpname = "ttdpttxt.tmp";
static const char *newname = "ttdpttxt.new";

static void store(void)
{
  if (txtindex == -1) {
	linelen = 0;
	return;
  }

  entries[txtindex] = malloc(linelen);
  if (!entries[txtindex])
	error("Not enough memory.\n");

  memcpy(entries[txtindex], data, linelen);
  lengths[txtindex] = linelen;
  defined[txtindex] = 1;

  linelen = 0;
  txtindex = -1;
}

static void printdefault(FILE *txt, int txtindex, int withname)
{
  int i;
  unsigned char c;
  const char *prefix;

  if (txtindex == -1) {
	fprintf(txt,
		"// TTDPatch in-game text strings\n"
		"// Edit with a Windows editor, or a charset of ISO-8859-1,\n"
		"// remove initial semicolon of modified lines,\n"
		"// then compile with the mkpttxt program.\n"
		"// Leave backslashes followed by two hexdigits alone\n"
		"// Escape newlines with \\n, backslashes with \\\\ and quotation marks with \\\".\n"
		"// Lines starting with whitespace (tab or space) are continuations.\n"
		"// All strings must be wrapped in quotes.\n"
		"// Maximum total size: unlimited.\n"
		"//\n");
	return;
  }

  if (!defined[txtindex]) {
	fprintf(txt, "; ");
  }
  fprintf(txt, withname ? "%s=\"" : "\"", ingametextnames[txtindex]);

  prefix = "";
  linelen=strlen(ingametextnames[txtindex])+2;
  for (i=0; i<lengths[txtindex]; i++) {
	c=entries[txtindex][i];
	fprintf(txt, prefix);
	prefix = "";
	if (c == '\r') {
		// print "\n\" following by newline
		fprintf(txt, "\\n");
		linelen = 250;	// force line break
	} else if (c < ' ' || ( (c > 'z') && (c <= 0x9e) ) ) {
		fprintf(txt, "\\%02x", c);
		if (!c && ( (i == 0) || entries[txtindex][i-1] )
		       && ( (i == lengths[txtindex]-1) || entries[txtindex][i+1] ) ) {
			linelen = 250;	// force line break at single NUL
		}
	} else if (c == '\\' || c == '"')
		fprintf(txt, "\\%c", c);
	else
		putc(c, txt);

	linelen++;
	if ( (linelen > 80) || ( (linelen > 70) && (c == ' ') ) ) {
		if (withname)
			prefix = "\"\n;\t\"";
		linelen = 8;
	}
  }
  fprintf(txt, "\"\n");
}

static int findsize(const char *filename)
{
  FILE *exe;
  long exesize;
  int lang, size;

  exe = fopen(filename, "rb");
  if (!exe) return -1;

  fseek(exe, 0, SEEK_END);
  exesize = ftell(exe);
  fclose(exe);

  for (lang=0; lang<ingamelang_num; lang++) {
	for (size=0; size<ingamelang_ptr[lang]->numfilesizes; size++) {
		if (littleendian(ingamelang_ptr[lang]->filesizes[size],4) == exesize) {
			return lang;
		}
	}
  }
  return -1;
}

static void showids(void)
{
  int i;
  for (i=0; i<TXT_last; i++) {
	printf("%04x %s ", i+0xf800, ingametextnames[i]);
	printdefault(stdout, i, 0);
  }
}

int main(int argc, char **argv)
{
  FILE *txt, *dat;
  char *baseline, *line, *name, c, *strdata;
  u32 u; //, *offsets;
  int i, lineno, datasize, doshowids = 0, deflang = -1;

  for (i=1; i<argc; i++) {
	if (!strcmp(argv[i], "-l"))
		doshowids = 1;
	else {
		deflang = atoi(argv[i]) - 1;
		if ( (deflang < 0) || (deflang >= ingamelang_num) ) 
			deflang = -1;
	}
  }

  if (!doshowids)
	printf("mkpttxt - takes ttdpttxt.txt and converts it into ttdpttxt.dat\n"
		"Copyright (C) 2002 by Josef Drexler\n\n");

	// FIXME: if size ever potentially goes above 32kb (allocsize)
	// need to realloc these arrays as necessary
  baseline = malloc(allocsize);
  data = malloc(allocsize);

  if (!baseline || !data)
	error("Not enough memory.\n");

  i = deflang;
  if (i == -1) i = findsize("gamegfx.exe");
  if (i == -1) i = findsize("ttdx.exe");
  if (i == -1) i = findsize("tycoon.exe");
  if (i == -1) i = 0;

  if (!doshowids)
	printf("Using language %d as default.\n", i+1);

  // set default (language from executable file size)
  defstr = (pingame) littleendian((int)ingamelang_ptr[i], 4);
  strdata = (char*) littleendian((int) defstr->data, 4);

  while (1) {
	i = littleendian( *( (u16*) strdata), 2);
	strdata += 2;
	if (i == 0xffff) break;
	if (i > TXT_last)
		error("invalid string ID %d > %d\n", i, TXT_last);
	linelen = littleendian( *( (u16*) strdata), 2);
	strdata += 2;
/*
  for (i=0; i<TXT_last; i++) {
	if (defstr) {
		line = defstr->data + littleendian(offsets[i], 4);
		if (i == TXT_last - 1)
			linelen = littleendian(defstr->size, 4);
		else
			linelen = littleendian(offsets[i+1], 4);
		linelen -= offsets[i];
	} else {
		static char untranslated[] = "(untranslated)";
		line = untranslated;
		linelen = strlen(line) + 1;
	}
*/
	entries[i] = strdata;
	lengths[i] = linelen;
	defined[i] = 0;
	strdata += linelen;
  };

  if (doshowids) {
	showids();
	exit(0);
  }

  txt = fopen(txtname, "rt");

  // if file not found, create default file
  if (!txt && errno == ENOENT && defstr) {
	printf("%s not found, generating default file.\n", txtname);
	txt = fopen(txtname, "wt");
	if (!txt)
		error("Error creating %s: %s\n", txtname, strerror(errno));

	printdefault(txt, -1, 1);	// header

	for (txtindex=0; txtindex<TXT_last; txtindex++)
		printdefault(txt, txtindex, 1);

	fclose(txt);

	// reopen for reading
	txt = fopen(txtname, "rt");
  }

  if (!txt)
	error("Error opening %s: %s\n", txtname, strerror(errno));

  printf("Reading %s\n", txtname);

  txtindex=-1;
  linelen = 0;
  lineno = 0;

  // scan all lines
  while (!feof(txt)) {
	lineno++;
	line = baseline;
	if (!fgets(line, 16384, txt))
		break;
	if ( (strncmp(line, "//", 2) == 0) || (line[0] == ';') )
		continue;

	// does it begin with whitespace?
	i = strspn(line, " \t");
	if (i) {
		line += i;	// continuation; skip whitespace
	} else {
		store();	// new entry
		name = line;
		line = strchr(line, '=');
		if (!line) error("Not an assignment on line %d\n", lineno);
		*line = 0;
		line++;

		txtindex = -1;
		for (i=0; i<TXT_last; i++) {
			if (strcmp(name, ingametextnames[i]) == 0) {
				txtindex = i;
				break;
			}
		}
		if (txtindex == -1)
			printf("Unknown entry '%s' on line %d skipped.\n", 
				name, lineno);
	}

	// skip whitespace
	line += strspn(line, " \t");
	if (line[0] != '"')
		error("Value is not in quotes on line %d\n", lineno);
	line++;	// skip quote

	// terminate at final quote
	name = strrchr(line, '"');
	if (!name)
		error("Value is not in quotes on line %d\n", lineno);
	*name = 0;

	// unescape all chars
	while (line[0]) {
		if (line[0] == '\\') {
			switch (line[1]) {
				case 'n':
					data[linelen++] = '\r';
					line+=2;
					break;
				case '\\':
				case '"':
					data[linelen++] = line[1];
					line+=2;
					break;
				default:
					c = line[3];
					line[3] = 0;
					i = strtol(line+1, NULL, 16);
					line[3] = c;
					data[linelen++] = i;
					line+=3;
			}
		} else {
			data[linelen++] = line[0];
			line++;
		}
	}
  }

  store();

  printf("Assembling data.\n");

//!  offsets = (u32*) data;

//!  datasize = TXT_last * 4;
//!  offsets[0] = datasize;

  datasize = 2;
  strdata = data;

  for (i=0; i<TXT_last; i++) {
	if (!defined[i]) continue;

	linelen = lengths[i];

	*(u16*) strdata = littleendian(i, 2);
	strdata += 2;
	*(u16*) strdata = littleendian(linelen, 2);
	strdata += 2;

	datasize += 4+linelen;
	/* realloc here maybe?
	if (datasize > VARDATASIZE)
		error("ERROR: Too much data (more than %d characters in total)\n", VARDATASIZE);
	*/

	memcpy(strdata, entries[i], linelen);
	strdata += linelen;
  }
  *(u16*) strdata = -1;

  printf("Writing %s\n", tmpname);

  dat = fopen(tmpname, "wb");
  if (!dat)
	error("Error opening %s: %s\n", tmpname, strerror(errno));

  u = MAGIC;
  fwrite(&u, 4, 1, dat);

  u = MAGIC ^ 0x12345678;
  fwrite(&u, 4, 1, dat);

  u = littleendian(datasize,4);
  fwrite(&u, 4, 1, dat);

  fwrite(data, 1, datasize, dat);

  fclose(dat);

  dat = fopen(datname, "rb");
  if (dat) {
	fclose(dat);
	printf("Deleting %s\n", datname);
	if (remove(datname))
		error("Error deleting %s: %s\n", datname, strerror(errno));
  }

  printf("Renaming %s to %s\n", tmpname, datname);
  if (rename(tmpname, datname))
	error("Error renaming: %s", strerror(errno));

  // see if anything is missing
  txtindex = 0;
  for (i=0; i<TXT_last; i++) {
	if (!defined[i]) {
		if (!txtindex)
			printf("\nNotice: the following entries are using the default strings:\n");
		txtindex = 1;
		printf("\t%s\n", ingametextnames[i]);
	}
  }

  if (!txtindex)
	return 0;

  // write new file with missing strings added
  txt = fopen(newname, "rt");
  if (txt) {
	fclose(txt);
	error("I wanted to write an updated %s, but it exists already!", newname);
  }

  txt = fopen(newname, "wt");
  if (!txt)
	error("Error creating %s: %s\n", newname, strerror(errno));

  printdefault(txt, -1, 1);	// header

  for (txtindex=0; txtindex<TXT_last; txtindex++)
	printdefault(txt, txtindex, 1);

  fclose(txt);

  printf("I wrote an updated %s with the missing strings added.\n"
	"Simply rename it to %s and translate the new entries.\n",
	newname, txtname);

  return 0;
}
