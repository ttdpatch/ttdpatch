//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// dos.c: routines to run the dos-ttd from ttdpatch
//


#include <string.h>
#include <process.h>
#include <dos.h>
#include <conio.h>
#include <io.h>

#ifdef __BORLANDC__
#include <dir.h>
#endif

#if defined __BORLANDC__ || defined __WATCOMC__
#include <malloc.h>
#endif

#include "zlib.h"
#define IS_DOS_CPP
#include "error.h"
#include "exec.h"
#include "osfunc.h"
#include "common.h"
#include "checkexe.h"
#include "grep.h"
#include "switches.h"
#include "auxfiles.h"
#include "versions.h"

#define TTDSIZE			(396L*1024L)	// approx. size of real-mode memory TTD needs

#define PROT_ALIGNMASK		((1 << PROT_ALIGN) - 1)

extern const s32 filesizebase = 470000;
extern const s32 filesizeshr = 1;

extern char *patchedfilename;

extern pversioninfo versions[];


#include "memsize.h"
#define SWAPPEDSIZE 0x5a0			// size of the swap stub in memory

#define BYTES_PER_PARA 16			// how many bytes per paragraph
#define PARAS_PER_KB (1024/BYTES_PER_PARA)	// how many paragraphs per KB

const char *ttd_exenames[] = {
	"TYCOON.EXE",
	"TTDX.EXE",
	NULL};

char oldstartfunc[] = {
	  0xb4, 9,	// mov ah,9
	  0xcd, 0x21,	// int 21h
	  0xe8		// call Initialize1
	};

char oldinitfunc[] = {
	  0x8b, 0x35, 0x18, 0x79, 7, 0,	// Mov ESI,[77918]
	  0xb9, 0x00, 0xa9, 1, 0,	// Mov ECX,1A900
	  0xc6, 0x06, 0x00		// Mov byte ptr [ESI],0
	};

char modinitfunc[] = {	// almost same as above, used to prevent earlier
			// TTDPatch from installing a second loader
	  0xb9, 0x00, 0xa9, 1, 0,	// Mov ECX,1A900
	  0x8b, 0x35, 0x18, 0x79, 7, 0,	// Mov ESI,[77918]
	  0xc6, 0x06, 0x00		// Mov byte ptr [ESI],0
	};



// need to reinitialize the language data after exec'ing, this function
// is define in ttdpatch.c
void initlanguage(langinfo *info);


void checkpatch(void)
{
  u32 pos, newcode, pcofs;
  s32 initialize1ptr, auxdataptr;
  char *p_initfunc;
  u32 initfunclen;

  FILE *f, *prcode;

  u32 newexepos = checkexe(&f, ttd_exenames, maketwochars('P','3'), "DOS");

  fseek(f, newexepos, SEEK_SET);
  pos = grepfile(f, "HS.DAT", 7, 1, -1);

  if (pos == GREP_NOMATCHL) {
	printf(langtext[LANG_TTDLOADINVALID]);
	error(langtext[LANG_DELETEOVL], patchedfilename);
  }

  pos -= 0xecb6c-0xec642;	// from HS.DAT to the actual highscore table

  fseek(f, pos, SEEK_SET);
  fread(&newcode, 4, 1, f);
  fread(&initialize1ptr, 4, 1, f);
  fread(&auxdataptr, 4, 1, f);

  if (!findattachment(AUX_LOADER, &pcofs, &prcode))
	error(langtext[LANG_INTERNALERROR], 7);

  fseek(prcode, pcofs, SEEK_SET);
  fread(&initfunclen, 4, 1, prcode);

  p_initfunc = malloc(initfunclen);
  if (!p_initfunc)
	error(langtext[LANG_NOTENOUGHMEM], "initfunclen", initfunclen/1024+1);

  fread(p_initfunc, 1, initfunclen, prcode);

#if DEBUG
  printf("New code: %lx, old code: %lx\nNew aux data ptr: %lx, old aux data ptr: %lx\n",
	newcode, *(u32*) p_initfunc, auxdataptr, *(s32*) (p_initfunc+8));
#endif

  if ( (newcode != *(u32*) p_initfunc) || (auxdataptr != *(s32*) (p_initfunc+8)) ) {

	// loader not installed or wrong version

	char *s;

	printf(langtext[LANG_INSTALLLOADER]);

	startwrite();

	if (!newcode) {
		// no loader installed yet

		s32 newstartproc;
		u32 initpos, initeip, hsptr;

			// read initial EIP, to be able to translate
			// between file offsets and code offsets
		fseek(f, newexepos + 0x68, SEEK_SET);
		fread(&initeip, 4, 1, f);

			// find old place where loader used to be
		initpos = grepfile(f, oldinitfunc, sizeof(oldinitfunc), 1, -1);
		fseek(f, 0, SEEK_SET);
		if (initpos == GREP_NOMATCHL)
			initpos = grepfile(f, modinitfunc, sizeof(modinitfunc), 1, -1);
		if (initpos == GREP_NOMATCHL) {
			printf(langtext[LANG_TTDLOADINVALID]);
			error(langtext[LANG_DELETEOVL], patchedfilename);
		}

			// write modified code to prevent older TTDPatch
			// from using this .ovl file
		fseek(f, initpos, SEEK_SET);
		fwrite(modinitfunc, 1, sizeof(modinitfunc), f);

			// find where startfunc is in the file
		fseek(f, 0, SEEK_SET);
		initpos = grepfile(f, oldstartfunc, sizeof(oldstartfunc), 1, -1);
		if (initpos == GREP_NOMATCHL) {
			printf(langtext[LANG_TTDLOADINVALID]);
			error(langtext[LANG_DELETEOVL], patchedfilename);
		}

			// find linear address of highscore table
		fseek(f, initpos + 15, SEEK_SET);
		fread(&hsptr, 4, 1, f);
		fseek(f, hsptr + 17, SEEK_CUR);
		fread(&hsptr, 4, 1, f);


		fseek(f, initpos + 5, SEEK_SET);
		fread(&initialize1ptr, 4, 1, f);

		if (initialize1ptr < 0) {
			printf(langtext[LANG_TTDLOADINVALID]);
			error(langtext[LANG_DELETEOVL], patchedfilename);
		}

		newstartproc = hsptr - (initeip + 0x29);
		fseek(f, -4, SEEK_CUR);
		fwrite(&newstartproc, 4, 1, f);

	}

	// write loader code (or update it)

	s = (char*) malloc(initfunclen);

	_fmemcpy(s, p_initfunc, initfunclen);

	fseek(f, pos, SEEK_SET);
	fwrite(s, 1, initfunclen, f);

	fseek(f, pos + 4, SEEK_SET);
	fwrite(&initialize1ptr, 4, 1, f);

	free(s);
  }

  free(p_initfunc);

  fseek(f, 0, SEEK_END);
  pos = ftell(f);

  fclose(f);

  printf(langtext[LANG_TTDLOADOK], patchedfilename);

  checkversion(newversion, pos);
  loadingamestrings(pos);
}

typedef struct {
	u8 dummy_fill;
	u8 type;
	u16 size;
	u16 id;
	u16 codepage;
	u8 info[34];
//	struct COUNTRY info;
} countryinfo;

s16 getdefaultlanguage(langinfo *linfo)
{
  countryinfo info;

  union REGS inregs, outregs;
  struct SREGS segregs;

  if (!linfo)
	perror("Country code");

  inregs.x.ax = 0x6501;
  inregs.x.bx = 0xffff;
  inregs.x.dx = 0xffff;
  inregs.x.di = FP_OFF(&info) + 1;
  segregs.es = FP_SEG(&info);
  inregs.x.cx = sizeof(countryinfo);

  intdosx(&inregs, &outregs, &segregs);

  if (outregs.x.cflag)
	perror("Country code");

  return langinfo_findlangfromcid(linfo, info.id);
}


#ifdef __BORLANDC__
extern unsigned _stklen = 3072;
extern unsigned _heaplen = 8192;
#endif


// Check that we have enough memory.
// toolow: minimum paragraphs that we need if swapped
// low: minimum paragraphs that we need to not swap
int checkfreemem(u16 toolow, u16 low)
{
#define ALLOC_USE_INTDOS
#ifdef ALLOC_USE_INTDOS
  unsigned short dosmem;
  union REGS inregs, outregs;
  struct SREGS sregs;
#else
	// some versions of BCC have a bug in the library that
	// handles _dos_allocmem, the return value is bogus if
	// the call fails
	// not sure of the exact versions where this bug is present
	// it definitely exists if __BORLANDC__ == 0x410
	// so we use allocmem instead of _dos_allocmem
#if __BORLANDC__ == 0x410
  unsigned int dosmem, ptr;
#else
  unsigned short dosmem;
#endif
#endif


  if ( (_osmajor < 3) || ( (_osmajor == 3) && (_osminor < 3) ) ) {
	error("Need DOS version 3.3 or higher.\n");
	exit(1);
  }

  // let's see if we have enough memory to run TTD
#ifdef ALLOC_USE_INTDOS
  inregs.h.ah = 0x48;		// allocate block
  inregs.x.bx = 0xffff;
  intdos(&inregs, &outregs);
  dosmem = outregs.x.bx;
  if (outregs.x.cflag && outregs.x.ax != 8) {
	#ifdef __BORLANDC__
	  error(langtext[LANG_NOTENOUGHMEM], strerror(outregs.x.ax), 0);
	#else
	  // strerror() doesn't work with DOS error codes in general
	  char e[16];
	  sprintf(e, "DOS error %u", outregs.x.ax);
	  error(langtext[LANG_NOTENOUGHMEM], e, 0);
	#endif
  }
  if (!outregs.x.cflag) {
	inregs.h.ah = 0x49;	// free block
	sregs.es = dosmem;
	intdosx(&inregs, &outregs, &sregs);
#else
#if __BORLANDC__ == 0x410
  dosmem = allocmem(0xffff, &ptr); if (dosmem == 0xffff) {
	freemem(ptr);
#else
  if (_dos_allocmem(0xffff, &dosmem) == 0) {
	_dos_freemem(dosmem);
#endif
#endif
	error("Huh? Too much memory, it seems...\n");
  }
#if DEBUG
//  printf("system says: %d\n", system("command"));
  printf("Have %u paras (%u KB), low is %u (%u KB), too low is %u (%u KB)\n",
	dosmem, (int) dosmem/PARAS_PER_KB,
	low, (int) low/PARAS_PER_KB,
	toolow, (int) toolow/PARAS_PER_KB);
  if (dosmem < toolow) {
	printf(langtext[LANG_NOTENOUGHMEMTTD], (toolow-dosmem)/PARAS_PER_KB+1);
	if (debug_flags.checkmem >= 0) {
	  printf("Trying anyway, since we're debugging.  Press return.\n");
	  (void)getchar();	// BCC complains if return code is unused
	}
  }
#else
  if ( (dosmem < toolow) && (debug_flags.checkmem >= 0) )
	error(langtext[LANG_NOTENOUGHMEMTTD], (toolow-dosmem)/PARAS_PER_KB+1);
#endif

  return (dosmem < low);
}


static size_t ncustomsystexts, *customsystextlen;
static u32 *customsystextoffset;

u32 preparesystexts(void) {
  size_t n;
  u32 totalcustomsystextlen = 0;

  ncustomsystexts = getncustomsystexts();
  customsystextlen = calloc(ncustomsystexts, sizeof *customsystextlen);
  if (!customsystextlen)
	error(langtext[LANG_NOTENOUGHMEM], "customsystextlen", ncustomsystexts*sizeof(*customsystextlen)/1024+1);
  customsystextoffset = calloc(ncustomsystexts, sizeof *customsystextoffset);
  if (!customsystextoffset)
	error(langtext[LANG_NOTENOUGHMEM], "customsystextoffset", ncustomsystexts*sizeof(*customsystextoffset)/1024+1);

  for (n = 0; n < ncustomsystexts; n++) {
	size_t l = strlen(systext(n)) + 1;
	customsystextlen[n] = l;
	customsystextoffset[n] = totalcustomsystextlen;
	totalcustomsystextlen += l;
  }

  return totalcustomsystextlen + ncustomsystexts*sizeof(*customsystextoffset);
}

int copyfiledata(long size, FILE *from, FILE *to, char *buffer, long bufsize)
{
  long towrite, written;
  while (size > 0) {
	if (size > bufsize)
		towrite = bufsize;
	else
		towrite = size;
	written = fread(buffer, 1, towrite, from);
	if (written != towrite)
		return 0;

	written = fwrite(buffer, 1, towrite, to);
	if (written != towrite)
		return 0;

	size -= written;
  }
  return 1;
}

int copygzfiledata(long size, gzFile from, FILE *to, char *buffer, long bufsize)
{
  long towrite, written;
  while (size > 0) {
	if (size > bufsize)
		towrite = bufsize;
	else
		towrite = size;
	written = gzread(from, buffer, towrite);
	if (written != towrite)
		return 0;

	written = fwrite(buffer, 1, towrite, to);
	if (written != towrite)
		return 0;

	size -= written;
  }
  return 1;
}
//
// write protected mode code into the given file
//
int writepatchdata(FILE *dat)
{
  long patchdatsize, patchmemsize, totversize, fileversize;
  long relocsize;
  u32 totsystxtsize = preparesystexts();
  size_t n;

  u32 ofs;
  FILE *f;
  gzFile gz;
  char *data;

  if (!findattachment(AUX_PROTCODE, &ofs, &f))
	error(langtext[LANG_INTERNALERROR], 8);

  fseek(f, ofs, SEEK_SET);

  gz = gzdopen(dup(fileno(f)), "rb");

  gzread(gz, &patchmemsize, 4);
  gzread(gz, &patchdatsize, 4);
  gzseek(gz, sizeof(paramset), SEEK_CUR);	// skip flags

  fwrite(&patchmemsize, 4, 1, dat);
  fwrite(&patchdatsize, 4, 1, dat);
  fwrite(flags, 1, sizeof(paramset), dat);

  patchdatsize -= sizeof(paramset);

  data = malloc(16384);

	// second dword in protectedcode is initialized size to write

  // write in chunks of at most 16 KB
  if (!copygzfiledata(patchdatsize, gz, dat, data, 16384))
	error(langtext[LANG_INTERNALERROR], 10);

  gzclose(gz);

  if (curversion->h.numoffsets) {
	fileversize = totversize = sizeof(versionheader) + 4 * curversion->h.numoffsets;
  } else {
	// no version info, still reserve space for numoffsets
	curversion->h.numoffsets = ALLOCEMPTYOFFSETS;
	fileversize = sizeof(versionheader);
	totversize = fileversize + 4 * curversion->h.numoffsets;
  }

  fwrite(&totversize, 4, 1, dat);	// array size in total
  fwrite(&fileversize, 4, 1, dat);	// array size in file
  fwrite(curversion, 1, fileversize, dat);

  fwrite(&customtextsize, 4, 1, dat);
  fwrite(&customtextsize, 4, 1, dat);
  fwrite(customtexts, 1, customtextsize, dat);

  fwrite(&totsystxtsize, 4, 1, dat);
  fwrite(&totsystxtsize, 4, 1, dat);
  fwrite(customsystextoffset, 4, ncustomsystexts, dat);
  for (n = 0; n < ncustomsystexts; n++)
	fwrite(systext(n), customsystextlen[n], 1, dat);

  free(customsystextlen);
  free(customsystextoffset);

  if (!findattachment(AUX_RELOCOFS, &ofs, &f))
	error(langtext[LANG_INTERNALERROR], 9);

  fseek(f, ofs, SEEK_SET);
  fread(&relocsize, 4, 1, f);	// relocations size

  fwrite(&relocsize, 4, 1, dat);
  fwrite(&relocsize, 4, 1, dat);

  if (!copyfiledata(relocsize, f, dat, data, 16384))
	error(langtext[LANG_INTERNALERROR], 11);

  free(data);

  return 1;
}


int runttd(const char *program, char *options, langinfo **linfo)
{
  int result;
  FILE *dat;
  const char *filename = TTDPATCH_DAT_FILE;
  char *lang_runerror;
  u32 nonswapfree;
  u32 swappedfree;
  int willswap;

  printf(langtext[LANG_RUNTTDLOAD], program,
	strlen(options)?" ":"", options);

  dat = fopen(filename, "wb");
  if (!dat || !writepatchdata(dat))
	error(langtext[LANG_CFGFILENOTWRITABLE], filename);

  fclose(dat);

  fflush(stdout);

    // copy needed strings from langtext array so we can free most of the memory
    lang_runerror = strdup(langtext[LANG_RUNERROR]);

    // Make sure we have enough memory to run TTD.
    nonswapfree = TTDSIZE;
    swappedfree = TTDSIZE - (TTDPATCHSIZE - SWAPPEDSIZE);
    willswap = checkfreemem(swappedfree / BYTES_PER_PARA, nonswapfree / BYTES_PER_PARA);

    if (debug_flags.swap) willswap = (debug_flags.swap > 0);

  if (willswap) {
	// print and test this now before we free the language info
	printf(langtext[LANG_SWAPPING]);
  }

    auxcloseall();
    langinfo_delete(*linfo);
    #if defined __BORLANDC__ || defined __WATCOMC__
    (void)_heapmin();	// BCC complains if return code not used
    #endif

    if (debug_flags.norunttd) {
	warning(lang_runerror, program, "DEBUG SWITCH");
    } else if (willswap) {	// we need to swap out to make enough memory
	result = do_exec((char *)program, options, 0x17, 0xffff, NULL);
	if (result > 0x100) {
		char reason[8];
		sprintf(reason, "#%4X", result);
		error(lang_runerror, program, reason);
	}
    } else {		// don't swap, there's enough memory
	result = spawnl(P_WAIT, (char *)program, (char *)program, options, NULL);
		// spawnl() expects args to be of (char *) type, not (const char *) -- don't know why
	if (result == -1)
		error(lang_runerror, program, strerror(errno));
    }

    free(lang_runerror);

	// load the language info back
    *linfo = langinfo_new();

    initlanguage(*linfo);

	// load the version info back from the dat file
    if (getf(recordversiondata)) {
	versionheader hdr;
	int written;

	dat = fopen(filename, "rb");
	if (!dat)
		return 1;

	written = fread(&hdr, 1, sizeof(versionheader), dat);

	curversion = malloc(sizeof(versionheader) + hdr.numoffsets * 4);
	curversion->h = hdr;

	fread(&curversion->versionoffsets, 4, hdr.numoffsets, dat);

	fclose(dat);
#if !DEBUG
	remove(filename);
#endif

	if ( (written != sizeof(versionheader)) ||
	     (curversion->h.version != MOREMAGIC) )
		return 1;
    }

    return result;
}


#if 0	// Console sizing functions currently not used

#ifdef __WATCOMC__
/*** Open Watcom 1.0 doesn't have textmode() et al. -- implement in assembly ***/

/** currently not used
unsigned short wherexy(void);
#pragma aux wherexy = \
	"push bp"	\
	"mov bh,0"	\
	"mov ah,3"	\
	"int 0x10"	\
	"pop bp"	\
	value [dx]	\
	modify [ax bx cx];
*/

void EGAlines(void);
#pragma aux EGAlines = \
	"pusha"		\
	"mov ax,0x1112"	\
	"xor bl,bl"	\
	"int 0x10"	\
	"mov ah,0x12"	\
	"mov bl,0x20"	\
	"int 0x10"	\
	"popa";
/*
 Interestingly, INT 10/AX=1112 does not touch the screen buffer, and
 (at least on my machine) leaves the cursor at its previous position,
 in a usable state. Guess the mode switch should have been implemented
 this way from the start. -- Marcin
*/

unsigned char screenwidth(void);
#pragma aux screenwidth = \
	"push bp"	\
	"mov ah,0xF"	\
	"int 0x10"	\
	"pop bp"	\
	value [ah]	\
	modify [ax bx cx dx si di];
	// let compiler assume nothing is safe, just in case

#define screenheight() (*(unsigned char __far *)MK_FP(0x40, 0x84) + 1)


void ensureconsize(int minlines)
{
  if (screenwidth() < 80 || screenheight() < minlines) {
	EGAlines();
  }
}

void restoreconsize(void) { ; }	// currently not supported

#endif	// defined __WATCOMC__

#ifdef __BORLANDC__
/*** The old bloated implementation using Borland C++ conio library features */

int oldmode = -1;

void setconsize(int mode)
{
  struct text_info textmodeinfo;
  gettextinfo(&textmodeinfo);

  {
    int cx = wherex(), cy = wherey();
    char *video_save = malloc(textmodeinfo.screenheight * textmodeinfo.screenwidth * 2);
    if (video_save) gettext(1, 1, textmodeinfo.screenwidth, textmodeinfo.screenheight, video_save);
    textmode(mode);
    if (video_save) {
      struct text_info newmodeinfo;
      gettextinfo(&newmodeinfo);
      if (newmodeinfo.screenheight > textmodeinfo.screenheight) {
	puttext(1, 1, textmodeinfo.screenwidth, textmodeinfo.screenheight, video_save);
	cy += newmodeinfo.screenheight - textmodeinfo.screenheight;
      } else {
	puttext(1, 1, textmodeinfo.screenwidth, newmodeinfo.screenheight,
		video_save + (textmodeinfo.screenheight-newmodeinfo.screenheight)*textmodeinfo.screenwidth*2);
      }
      gotoxy(cx, cy);
      free(video_save);
    }
  }
}

void ensureconsize(int minlines)
{
  struct text_info textmodeinfo;
  gettextinfo(&textmodeinfo);
  if (textmodeinfo.screenwidth < 80 || textmodeinfo.screenheight < minlines) {
	oldmode = textmodeinfo.currmode;
	setconsize(C4350);
  }
}

void restoreconsize()
{
  if (oldmode != -1) {
	setconsize(oldmode);
	oldmode = -1;
  }
}

#endif	// defined __BORLANDC__

#else	// 0

void restoreconsize(void) { ; }

#endif


void initializewindow(void)
{
  // nothing to do in DOS version yet
}


static unsigned char current_video_page;

static int have_ega(void) {
  union REGS r;
  r.h.ah = 0x12;
  r.h.bl = 0x10;
  r.h.bh = 0xFF;
  int86(0x10, &r, &r);
  return (r.h.bh != 0xFF);
}

void getconsoleinfo(int *width, int *height, unsigned *attrib) {
  union REGS r;
  r.h.ah = 0xF;
  int86(0x10, &r, &r);
  if (width) *width = r.h.ah;
  if (height) *height = have_ega() ? *(unsigned char __far *)MK_FP(0x40, 0x84) + 1 : 25;
  current_video_page = r.h.bh;
  r.h.ah = 8;
  int86(0x10, &r, &r);
  if (attrib) *attrib = r.h.ah;
}

#if 0	// currently not used
void getcursorxy(int *x, int *y) {
  union REGS r;
  r.h.ah = 3;
  r.h.bh = current_video_page;
  int86(0x10, &r, &r);
  if (x) *x = r.h.dl;
  if (y) *y = r.h.dh;
}
#endif

void setcursorxy(int x, int y) {
  union REGS r;
  r.h.ah = 2;
  r.h.bh = current_video_page;
  r.h.dl = x;
  r.h.dh = y;
  int86(0x10, &r, &r);
}

void clrconsole(int startline, int endline, int conwidth, unsigned attrib) {
  union REGS r;
  struct SREGS s;
  r.x.ax = 0x600;
  r.h.bh = attrib;
  r.h.cl = 0;
  r.h.ch = startline;
  r.h.dl = conwidth - 1;
  r.h.dh = endline;
  int86x(0x10, &r, &r, &s);	// use int86x to protect from bugs in some BIOSes
}

