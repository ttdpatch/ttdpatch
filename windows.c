//
// This file is part of TTDPatch
// Copyright (C) 1999, 2000 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// windows.c: routines to run the windows-ttd from ttdpatch
//


#include <string.h>
#include <windows.h>
#include <unistd.h>

#include "zlib.h"
#define IS_WINDOWS_CPP
#include "osfunc.h"
#include "types.h"
#include "error.h"
#include "checkexe.h"
#include "switches.h"
#include "versions.h"
#include "auxfiles.h"

const s32 filesizebase = 1690000;
const s32 filesizeshr = 8;

extern char *patchedfilename;

extern pversioninfo versions[];

const char *ttd_winexenames[] = {
	"GAMEGFX.EXE",
	NULL,
	NULL };

int __errno;

// Function pointers to deal with the registry, these may
// be redirected to noregist.c's fake_* functions if needed
typedef LONG WINAPI t_RegQueryValueEx(HKEY,LPCSTR,LPDWORD,LPDWORD,LPBYTE,LPDWORD);
t_RegQueryValueEx *_RegQueryValueEx = RegQueryValueEx;
typedef LONG WINAPI t_RegSetValueEx(HKEY,LPCSTR,DWORD,DWORD,const BYTE*,DWORD);
t_RegSetValueEx *_RegSetValueEx = RegSetValueEx;
typedef LONG WINAPI t_RegCloseKey(HKEY);
t_RegCloseKey *_RegCloseKey = RegCloseKey;
typedef LONG WINAPI t_RegOpenKey(HKEY key, LPCSTR subkey, PHKEY result);
t_RegOpenKey *_RegOpenKey = RegOpenKey;

const char *def_noregistry =
	"[HKLM_Software_FISH_Technology_Group_Transport_Tycoon_Deluxe]\n"
	"DisplayModeNumber=D1\n"
	"ForceDIBSection=D1\n"
	"FullScreen=D0\n"
	"HDPath=S.\\\n"
	"Installed=D3\n"
	"Language=D0\n"
	"MidiType=D1\n"
	"MousePointer=D0\n"
	"RetraceSync=D0\n"
	"SafeMode=D0\n"
	"UpdateMode=D1\n";


void sysfnerror(const char *fnname, DWORD error)
{
  LPVOID msgbuf;
  DWORD n = FormatMessageA(
		FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		NULL,
		error,
		0,
		(LPSTR)&msgbuf,
		0,
		NULL);
  fflush(stdout);
  if (n) {
	CharToOemA(msgbuf, msgbuf);
	fprintf(stderr, "%s: %s\n", fnname, (char *)msgbuf);
	LocalFree(msgbuf);
  }
  else fprintf(stderr, "%s: Error %ld\n", fnname, (long)error);
}


void checkpatch(void)
{
  u32 flen, sections, optheaderstart, sectstart, newentry, entry;
  u32 ourcode, codelen;
  FILE *f, *prcode;

  ttd_winexenames[1] = langtext[LANG_WINDEFLANGEXE];
  u32 newexepos = checkexe(&f, ttd_winexenames, maketwochars('P','E'), "Windows");
  u32 section;
  u32 sectionaddr = 0;
  u32 sectionsize;
  u32 sectionalign;
  char sectname[9], *oldcode, *newcode;

  // Ensure that enough memory is available for the large vehicle array
  setseglen(newexepos + 0x50, 0x16, 0x20, 0x80, 0x80);

  // Set section number to 10, and define new section if necessary
  optheaderstart = newexepos + 0x18;
  sectstart = optheaderstart + getval(newexepos + 0x14, 2);	// is ... + optheadersize
  sections = ensureval(newexepos + 6, 2, 10);
  // we have to make the .text section writable so that we can patch the int21handler functions
  ensureval(sectstart + 0x24, 4, getval(sectstart + 0x24, 4) | 0x80000000);
  if (sections) {
	if (sections != 9) {
		fflush(stdout);
		fprintf(stderr, langtext[LANG_TTDLOADINVALID]);
		error(langtext[LANG_DELETEOVL], patchedfilename);
	}
	sectionalign = getval(optheaderstart + 0x20, 4);
	// scan existing sections and find where they end
	for (section = 0; section < sections; section++) {
		// get section's size, round up to next alignment and add to section start -> check if this number is maximum
		u32 sectionend = ((getval(sectstart + 8 + section * 0x28, 4) + sectionalign - 1) & ~(sectionalign - 1)) + getval(0, 4);
		if (sectionend > sectionaddr) sectionaddr = sectionend;
	}
	// patch section fills up to the file's memory image (set in setseglen above)
	sectionsize = getval(newexepos + 0x50, 4) - sectionaddr;
	startwrite();
	fseek(f, sectstart + sections * 0x28, SEEK_SET);
	fwrite("TTDPatch", 8, 1, f);	// section name
	setval(0, 4, sectionsize);		// section virtual size 5MB
	setval(0, 4, sectionaddr);		// virtual address, base 0
	setval(0, 4, 0);		// data in .exe file
	setval(0, 4, 0);		// offset in .exe file
	setval(0, 4, 0);		// offset to relocations
	setval(0, 4, 0);		// offset to line numbers
	setval(0, 2, 0);		// number of relocations
	setval(0, 2, 0);		// number of line numbers
	setval(0, 4, 0xc0000080);	// uninitialised, RW access
  }

  // Check if the pre-alpha 10 loader is present; if so abort and suggest
  // deleting ttdloadw.ovl
  fseek(f, sectstart + 6 * 0x28, SEEK_SET);
  fread(sectname, 8, 1, f);
  sectname[8] = 0;
  if (strcmp(sectname, "CODESEG")) {
	fflush(stdout);
	fprintf(stderr, langtext[LANG_TTDLOADINVALID]);
	error(langtext[LANG_DELETEOVL], patchedfilename);
  }
  ourcode = getval(0, 4);		// virtual size
  newentry = ourcode + getval(0, 4);	// + address = end of CODESEG
  getval(0, 4);	// skip 4 bytes
  ourcode += getval(0, 4);		// + .exe offset = same location in .exe file
  fseek(f, ourcode, SEEK_SET);
  fread(sectname, 1, 1, f);		// read first byte where code loader would be
  if (sectname[0] == '\xEB') {		// EB is from the short jump, only present
	fflush(stdout);			// if old code loader is installed, otherwise 00
	fprintf(stderr, langtext[LANG_TTDLOADINVALID]);
	error(langtext[LANG_DELETEOVL], patchedfilename);
  }

  // Make sure our code loader is present
  fseek(f, sectstart + 5 * 0x28, SEEK_SET);
  fread(sectname, 8, 1, f);
  sectname[8] = 0;
  if (strcmp(sectname, "DATASEG")) {
	fflush(stdout);
	fprintf(stderr, langtext[LANG_TTDLOADINVALID]);
	error(langtext[LANG_DELETEOVL], patchedfilename);
  }
  ourcode = getval(0, 4) - 0x3FF;	// virtual size - 4KB
  newentry = ourcode + getval(0, 4);	// + address = end of CODESEG
  getval(0, 4);	// skip 4 bytes
  ourcode += getval(0, 4);		// + .exe offset = same location in .exe file

  if (!findattachment(AUX_LOADER, &flen, &prcode))
	error(langtext[LANG_INTERNALERROR], 7);

  fseek(prcode, flen, SEEK_SET);
  fread(&codelen, 4, 1, prcode);

  newcode = malloc(codelen);
  fread(newcode, 1, codelen, prcode);

  oldcode = malloc(codelen);

  // make sure the new loader is valid
  if ( *(u32*) (newcode+2) != MAGIC )
	error(langtext[LANG_INTERNALERROR], 5);

  fseek(f, ourcode, SEEK_SET);
  fread(oldcode, 1, codelen, f);
  entry = *(u32*) (oldcode+2);			// get real entry point of current code loader
  *(u32*) (newcode+2) = entry;			// so that comparing won't fail b/o this
  if (memcmp(oldcode, newcode, codelen)) {		// empty code
	printf(langtext[LANG_INSTALLLOADER]);
	startwrite();
	fseek(f, ourcode, SEEK_SET);
	fwrite(newcode, 1, codelen, f);

	if (entry)
		setval(ourcode + 2, 4, entry);		// keep original entry point

		// Set entry point to our code loader
	entry = ensureval(optheaderstart + 0x10, 4, newentry);
	if (entry)
		if (!getval(ourcode + 2, 4))
			setval(ourcode + 2, 4, entry + 0x400000);
  }

  free(newcode);

  fseek(f, 0, SEEK_END);
  flen = ftell(f);

  fclose(f);

  printf(langtext[LANG_TTDLOADOK], patchedfilename);

  checkversion(newversion, flen);
  loadingamestrings(flen);
}

int trynoregistry()
{
  // functions in noregist.c
  t_RegQueryValueEx *fake_RegQueryValueEx;
  t_RegSetValueEx *fake_RegSetValueEx;
  t_RegCloseKey *fake_RegCloseKey;
  t_RegOpenKey *fake_RegOpenKey;
  typedef char *t_getreginifilename();
  t_getreginifilename *getreginifilename;

  HANDLE patchdll = LoadLibrary("ttdpatch.dll");
  if (!patchdll)
	return 0;

  #define IMPORT(x,t,y) \
  x = (t*) GetProcAddress(patchdll, y); \
  if (!x) { FreeLibrary(patchdll); return 0; }

  IMPORT(getreginifilename, t_getreginifilename, "getreginifilename");
  IMPORT(fake_RegQueryValueEx, t_RegQueryValueEx, "fake_RegQueryValueExA@24");
  IMPORT(fake_RegSetValueEx, t_RegSetValueEx, "fake_RegSetValueExA@24");
  IMPORT(fake_RegCloseKey, t_RegCloseKey, "fake_RegCloseKey@4");
  IMPORT(fake_RegOpenKey, t_RegOpenKey, "fake_RegOpenKeyA@12");

  char *inifile = (*getreginifilename)();
  printf(langtext[LANG_TRYINGNOREGIST], inifile);

  if (access(inifile, R_OK)) {
	FILE *ini = fopen(inifile, "wt");
	if (!ini)
		error(langtext[LANG_CFGFILENOTWRITABLE], inifile);
	fputs(def_noregistry, ini);
	fclose(ini);
  }

  _RegOpenKey = fake_RegOpenKey;
  _RegQueryValueEx = fake_RegQueryValueEx;
  _RegSetValueEx = fake_RegSetValueEx;
  _RegCloseKey = fake_RegCloseKey;

  setf1(usenoregistry);

/*
  strcpy(ttdoptions, "DLL:");
  GetModuleFileName(patchdll, ttdoptions+4, 128+1024*WINTTDX-4);
*/

  return 1;
}

// fix the HDPath in the registry, to not end in NULL
// and to be a 8.3 pathname and to end with a backslash
void fixregistry(void)
{
  HKEY hkey;
  int modified;

  char *filename, *shortname;
  DWORD len, shortlen;
  DWORD type, result;

  if (debug_flags.noregistry <= 0)	// registry allowed?
	  // try opening the key
	  result = RegOpenKey(HKEY_LOCAL_MACHINE,
		"Software\\Fish Technology Group\\Transport Tycoon Deluxe",
		&hkey);
  else result = 1;

  if (result) {
	if (debug_flags.noregistry == 0)	// noregistry automatic, show warning
		printf(langtext[LANG_REGISTRYERROR], 1);
	else if (debug_flags.noregistry < 0)	// noregistry not allowed, abort
		error(langtext[LANG_REGISTRYERROR], 1);

	if (trynoregistry()) {
		result = (*_RegOpenKey)(HKEY_LOCAL_MACHINE,
			"Software\\Fish Technology Group\\Transport Tycoon Deluxe",
			&hkey);
	}

	if (result)
		error(langtext[LANG_NOREGISTFAILED]);
  }

  // get the length of the path
  result = (*_RegQueryValueEx)(hkey, "HDPath", NULL, &type, NULL, &len);
  if (result)
	error(langtext[LANG_REGISTRYERROR], 2);

  filename = malloc(len);

  // get the value of the installation path
  result = (*_RegQueryValueEx)(hkey, "HDPath", NULL, &type, (BYTE*) filename, &len);
  if (result)
	error(langtext[LANG_REGISTRYERROR], 3);

  shortlen = len;
  shortname = malloc(shortlen);

  // translate to a short path name
  result = GetShortPathName(filename, shortname, shortlen);
  if (!result)
	error(langtext[LANG_REGISTRYERROR], 4);

  if (result != strlen(shortname)) {
	// buffer too small (how did that happen??)

	shortlen = result;
	realloc(shortname, shortlen);
	result = GetShortPathName(filename, shortname, shortlen);
	if (!result || (result != strlen(shortname)))
		error(langtext[LANG_REGISTRYERROR], 5);
  }

  modified = 0;
  if (stricmp(filename, shortname)) {
	// Not the same, so it was a long name.  Save the short name.
	modified |= 1;
  }
  if (strlen(filename)+1 != len) {
	// Same, but data was too long.  Probably had a NULL, so
	// simply save it back and get rid of the NULL.

	modified |= 2;
  }
  if (shortname[strlen(shortname)-1] != '\\') {
	// path doesn't end in a backslash.

	if (shortlen < strlen(shortname)+2) {
		shortlen++;
		shortname = realloc(shortname, shortlen);
	}
	strcat(shortname, "\\");
	modified |= 4;
  }

  if (modified) {
	result = (*_RegSetValueEx)(hkey, "HDPath", 0, type,
			(BYTE*) shortname, strlen(shortname));
	if (result)
		error(langtext[LANG_REGISTRYERROR], modified | 8);
  }

  // close the key
  (*_RegCloseKey)(hkey);

  free(shortname);
  free(filename);

}

u32 getdllstamp(FILE *f, u32 baseofs)
{
  u32 newexepos, stamp;
  char b[4] = {0, 0, 0, 0};

  fseek(f, 0x18+baseofs, SEEK_SET);
  fread(b, 1, 1, f);
  if (b[0] != 0x40)
	return b[0];

  fseek(f, 0x3c+baseofs, SEEK_SET);
  fread(&newexepos, 4, 1, f);
  fseek(f, newexepos+baseofs, SEEK_SET);
  fread(b, 1, 2, f);
  fseek(f, newexepos+8+baseofs, SEEK_SET);
  fread(&stamp, 4, 1, f);

  if (strcmp(b, "PE"))
	return 2;

  return stamp;
}

// extract ttdpatch.dll if it doesn't exist
void check_patchdll()
{
  const char *filename = "ttdpatch.dll";
  u32 ofs, size, oldstamp = 0, newstamp = 1;
  FILE *f;
  char *buf;

  f = fopen(filename, "rb");
  if (f) {
	oldstamp = getdllstamp(f, 0);	// get time stamp of existing .dll
	fclose(f);
  }
  int ret = findattachment(AUX_PATCHDLL, &ofs, &f);
  if (!ret)
	error(langtext[LANG_INTERNALERROR], 10);
  if (ret == 2)
	return;

  newstamp = getdllstamp(f, ofs+4);	// and of the one included with this patch

  //printf("Old stamp: %lx  New stamp at ofs %lx: %lx\n", oldstamp, ofs, newstamp);

  if (newstamp < 10)		// error reading the stamp?
	error(langtext[LANG_INTERNALERROR], 11);

  if (newstamp == oldstamp)		// if they agree, don't touch it
	return;

  //printf("Extracting %s\n", filename);

  // otherwise, we extract the included .dll
  fseek(f, ofs, SEEK_SET);
  fread(&size, 4, 1, f);
  buf = malloc(size);
  fread(buf, 1, size, f);
  // fclose(f); <-- will be done by auxfiles.c when appropriate

  f = fopen(filename, "wb");
  if (!f) {
	warning(langtext[LANG_CFGFILENOTWRITABLE], filename);
	return;
  }
  fwrite(buf, 1, size, f);
  fclose(f);
  free(buf);
}


void prepare_exec()
{
}


static size_t ncustomsystexts, *customsystextlen;
static u32 *customsystextoffset;
static WCHAR **customsystextw;

unsigned long preparesystexts(void) {
  size_t n;
  unsigned long totalcustomsystextlen = 0;

  ncustomsystexts = getncustomsystexts();
  customsystextlen = calloc(ncustomsystexts, sizeof *customsystextlen);
  if (!customsystextlen)
	error(langtext[LANG_NOTENOUGHMEM], "customsystextlen", ncustomsystexts*sizeof(*customsystextlen)/1024+1);
  customsystextoffset = calloc(ncustomsystexts, sizeof *customsystextoffset);
  if (!customsystextoffset)
	error(langtext[LANG_NOTENOUGHMEM], "customsystextoffset", ncustomsystexts*sizeof(*customsystextoffset)/1024+1);
  customsystextw = calloc(ncustomsystexts, sizeof *customsystextw);
  if (!customsystextw)
	error(langtext[LANG_NOTENOUGHMEM], "customsystextw", ncustomsystexts*sizeof(*customsystextw)/1024+1);

  for (n = 0; n < ncustomsystexts; n++) {
	int ul = MultiByteToWideChar(codepage, 0, systext(n), -1, NULL, 0);
	if (!ul) {
		sysfnerror("MultiByteToWideChar()", GetLastError());
		error(langtext[LANG_STRINGCONVFAIL]);
	}

	if ((customsystextw[n] = calloc(ul, sizeof(WCHAR))) == NULL)
		error(langtext[LANG_NOTENOUGHMEM], "customsystextw", ul*sizeof(WCHAR)/1024+1);

	if (isothertext(n)) {
		// this wastes some memory from the calloc but not enough to need fixing
		ul = strlen(systext(n))+1;
		strncpy((char *) customsystextw[n], systext(n), ul);
	} else if (!MultiByteToWideChar(codepage, 0, langtext[customsystexts[n]], -1, customsystextw[n], ul)) {
		sysfnerror("MultiByteToWideChar()", GetLastError());
		error(langtext[LANG_STRINGCONVFAIL]);
	}

	ul *= sizeof(WCHAR);
	customsystextlen[n] = ul;
	customsystextoffset[n] = totalcustomsystextlen;
	totalcustomsystextlen += ul;
  }

  return totalcustomsystextlen + ncustomsystexts*sizeof(*customsystextoffset);
}


void chkipcerror(
		HANDLE h,
		const char *fnname,
		const char *program,
		const char *errmsg,
		const char *existmsg)
{
  if (!h) {
	sysfnerror(fnname, GetLastError());
	error(langtext[LANG_RUNERROR], program, errmsg);
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
	sysfnerror(fnname, ERROR_ALREADY_EXISTS);
      #if DEBUG
	warning
      #else
	error
      #endif
	       (existmsg);
  }
}


#ifdef __BORLANDC__
#pragma argsused
#endif
int runttd(const char *program, char *options, langinfo **info)
{
  HANDLE shmem, ipcevent;
  void *shdata;
  STARTUPINFO siStartInfo = {
		sizeof(STARTUPINFO), 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0 };
  PROCESS_INFORMATION piProcInfo;

  int cmdlength, result = 255;
  char *commandline;

  unsigned long patchdatsize, patchmemsize, versionsize[2], relocofssize;
  unsigned long totsystxtsize = preparesystexts();
  char *relocofs;

  u32 ofs;
  FILE *f;
  gzFile gz;

  check_patchdll();
  fixregistry();

  cmdlength = strlen(options) + strlen(program) + 1;
  commandline = (char*) malloc(cmdlength);
  if (!commandline)
	error(langtext[LANG_NOTENOUGHMEM], "commandline", cmdlength/1024+1);

  strcpy(commandline, program);
  if (strlen(options)) {
	strcat(commandline, " ");
	strcat(commandline, ttdoptions);
  }

  printf(langtext[LANG_RUNTTDLOAD], commandline, "", "");

  // we have to know how much shared memory we'll need

  if (!findattachment(AUX_RELOCOFS, &ofs, &f))
	error(langtext[LANG_INTERNALERROR], 9);

  fseek(f, ofs, SEEK_SET);
  fread(&relocofssize, 4, 1, f);
  relocofs = malloc(relocofssize);
  fread(relocofs, 1, relocofssize, f);

  if (!findattachment(AUX_PROTCODE, &ofs, &f))
	error(langtext[LANG_INTERNALERROR], 8);

  fseek(f, ofs, SEEK_SET);

  //printf("gzdopening\n");
  gz = gzdopen(dup(fileno(f)), "rb");
  if (!gz)
	error(langtext[LANG_NOTENOUGHMEM], "gzdopen", 8);

  //printf("gzreading\n");

  gzread(gz, &patchmemsize, 4);
  gzread(gz, &patchdatsize, 4);

  //printf("Read sizes: %ld/%ld\n", patchmemsize, patchdatsize);

  if (curversion->h.numoffsets) {
	versionsize[0] = versionsize[1] = sizeof(versionheader) + 4 * curversion->h.numoffsets;
  } else {
	// no version info, still reserve space for numoffsets
	curversion->h.numoffsets = ALLOCEMPTYOFFSETS;
	versionsize[1] = sizeof(versionheader);
	versionsize[0] = versionsize[1] + 4 * curversion->h.numoffsets;
  }

  // Create the IPC objects

  ipcevent = CreateEventA(NULL, FALSE, FALSE, TTDPATCH_IPC_EVENT_NAME);
  chkipcerror(ipcevent, "CreateEvent()", program, "IPC error\n", langtext[LANG_IPCEXISTS]);

  shmem = CreateFileMappingA(
		(HANDLE)-1,
		NULL,
		PAGE_READWRITE,
		0,
		8 + patchdatsize + 8 + versionsize[1] + 8 + customtextsize + 8 + totsystxtsize + 8 + relocofssize,
		TTDPATCH_IPC_SHM_NAME);
  chkipcerror(shmem, "CreateFileMapping()", program, "IPC error\n", langtext[LANG_IPCEXISTS]);

  shdata = MapViewOfFile(shmem, FILE_MAP_WRITE, 0, 0, 0);
  if (!shdata) chkipcerror(0, "MapViewOfFile()", program, "IPC error\n", NULL);

  // Copy the protected-mode code into the shared memory

  ((u32 *)shdata)[0] = patchmemsize;
  ((u32 *)shdata)[1] = patchdatsize;

  //printf("Read %d of %ld bytes\n",
  gzread(gz, shdata + 8, patchdatsize);
  //patchdatsize);

  gzclose(gz);

  memcpy(shdata + 8, flags, sizeof(paramset));

  // Copy the rest of the stuff into shared memory

  {
    char *wp = shdata + patchdatsize + 8;
    size_t n;

    memcpy(wp, versionsize, 8);
    memcpy(wp += 8, curversion, versionsize[1]);
    wp += versionsize[1];

    ((u32 *)wp)[0] = ((u32 *)wp)[1] = customtextsize;
    memcpy(wp += 8, customtexts, customtextsize);
    wp += customtextsize;

    ((u32 *)wp)[0] = ((u32 *)wp)[1] = totsystxtsize;
    memcpy(wp += 8, customsystextoffset, 4*ncustomsystexts);
    wp += 4*ncustomsystexts;
    for (n = 0; n < ncustomsystexts; n++) {
	memcpy(wp, customsystextw[n], customsystextlen[n]);
	wp += customsystextlen[n];
	free(customsystextw[n]);
    }

    ((u32 *)wp)[0] = ((u32 *)wp)[1] = relocofssize;
    memcpy(wp += 8, relocofs, relocofssize);
    wp += relocofssize;

    free(customsystextlen);
    free(customsystextoffset);
    free(customsystextw);
    free(relocofs);
  }

  // Now create the child process

  if (debug_flags.norunttd) {
	error(langtext[LANG_RUNERROR], program, "DEBUG SWITCH");
  } else if (!CreateProcessA(NULL,
		commandline,	// command line
		NULL,		// process security attributes
		NULL,		// primary thread security attributes
		FALSE,		// handles are not inherited
		0,		// creation flags
		NULL,		// use parent's environment
		NULL,		// use parent's current directory
		&siStartInfo,	// STARTUPINFO pointer
		&piProcInfo)	// receives PROCESS_INFORMATION
				) {
	sysfnerror("CreateProcess()", GetLastError());
	printf(langtext[LANG_RUNERROR], program, langtext[LANG_CRPROCESSFAIL]);
	error(langtext[LANG_DELETEOVL], patchedfilename);
  }

  free(commandline);

  // Wait until ttdloadw.ovl succeeds with the initialization or dies

  {
    HANDLE whandles[2];

    whandles[0] = ipcevent;
    whandles[1] = piProcInfo.hProcess;

    switch (WaitForMultipleObjects(2, whandles, FALSE, INFINITE)) {
      default:			// invalid value, an error must have occurred
	sysfnerror("WaitForMultipleObjects()", GetLastError());
      case WAIT_OBJECT_0 + 1:	// process died
	break;
      case WAIT_OBJECT_0:	// OK
	result = 0;
    }
  }

  // Read the version information if requested

  if (result == 0 && getf(recordversiondata)) {
	curversion = (pversioninfo) shdata;
	if (curversion->h.version != MOREMAGIC)
		result = 129;
  }
  else {

  // Close IPC objects and return

	// but don't close shared memory if we've got version data there

	if (!UnmapViewOfFile(shdata))
		sysfnerror("UnmapViewOfFile()", GetLastError());
	if (!CloseHandle(shmem))
		sysfnerror("CloseHandle(shmem)", GetLastError());
  }
  if (!CloseHandle(ipcevent))
	  sysfnerror("CloseHandle(ipcevent)", GetLastError());
  // close errors are pretty harmless, but they're reported anyway

  return result;
}


s16 getdefaultlanguage(langinfo *info)
{
  char langid[6];
  if (!GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_ILANGUAGE, langid, sizeof(langid)))
	error("Could not get Windows locale information.\n");

  {
    int numlangid = strtol(langid, NULL, 16);

    return langinfo_findlangfromlid(info, numlangid & 0xff, 1);
  }
}

#if 0	// currently not used
void ensureconsize(int minlines)
{
  CONSOLE_SCREEN_BUFFER_INFO info;
  HANDLE handle = getconsoleouthandle();
  if (handle != INVALID_HANDLE_VALUE && GetConsoleScreenBufferInfo(handle, &info)) {
    if (info.dwSize.X < 80 || info.dwSize.Y < minlines) {
      info.srWindow.Left = 0;
      info.srWindow.Top = 0;
      info.srWindow.Right = 79;
      info.srWindow.Bottom = 49;
      SetConsoleWindowInfo(handle, 1, &info.srWindow);
      info.dwSize.X = 80;
      info.dwSize.Y = 50;
      SetConsoleScreenBufferSize(handle, info.dwSize);
    }
  }
}
#endif	// 0

static HANDLE getconsoleouthandle(void) {
  static HANDLE handle = INVALID_HANDLE_VALUE;
  if (handle == INVALID_HANDLE_VALUE)
	handle = GetStdHandle(STD_OUTPUT_HANDLE);
  return handle;
}


void restoreconsize()
{
	// this doesn't work yet
}


void getconsoleinfo(int *width, int *height, unsigned *attrib) {
  CONSOLE_SCREEN_BUFFER_INFO info;
  HANDLE handle = getconsoleouthandle();
  if (handle != INVALID_HANDLE_VALUE && GetConsoleScreenBufferInfo(handle, &info)) {
    if (width) *width = info.dwSize.X;
    if (height) *height = info.dwSize.Y;
    if (attrib) *attrib = info.wAttributes;
  }
  else {	// no console, perhaps output is redirected
    if (width) *width = 80;
    if (height) *height = 32767;
    if (attrib) *attrib = FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED;
  }
}

void setcursorxy(int x, int y) {
  HANDLE handle = getconsoleouthandle();
  if (handle != INVALID_HANDLE_VALUE) {
    COORD pos;
    pos.X = x;
    pos.Y = y;
    SetConsoleCursorPosition(handle, pos);
  }
}

void clrconsole(int startline, int endline, int conwidth, unsigned attrib) {
  HANDLE handle = getconsoleouthandle();
  if (handle != INVALID_HANDLE_VALUE) {
    COORD c;
    DWORD l = (endline - startline + 1)*conwidth;
    DWORD dummy;
    c.X = 0;
    c.Y = startline;
    FillConsoleOutputAttribute(handle, attrib, l, c, &dummy);
    FillConsoleOutputCharacterA(handle, ' ', l, c, &dummy);
  }
}


/*
void addgrffiles(FILE *f)
{
  int done;
  WIN32_FIND_DATA fblk;
  HANDLE fhnd;
  char *fname = (char*) &fblk.cFileName;

  // look for *.adw files in the newgrf directory
  // add the corresponding .grf files to newgrfw.txt and
  // delete the .adw file

  SetCurrentDirectory("newgrf");
  fhnd = FindFirstFile("*.adw", &fblk);
  done = (fhnd == INVALID_HANDLE_VALUE);

  while (!done) {
	fprintf(f, "newgrf/%.*s.grf\n", (int) strlen(fname) - 4, fname);
	remove(fname);

	done = !FindNextFile(fhnd, &fblk);
  }

  FindClose(fhnd);
  SetCurrentDirectory("..");
}
*/

#define MAX_SAVE_CONSOLE_TITLE	1024

void iconproc(UINT msg, HICON bigin, HICON smallin, HICON *bigout, HICON *smallout)
{
  HICON smallico, bigico;
  static HWND hConsole;
  static BOOL initialized;

  if (!initialized) {
	static char titlebuf[MAX_SAVE_CONSOLE_TITLE];
	const char *temptitle = "TTDPatch: PID=%X";
	static char temptitlebuf[32];

	initialized = 1;

	// No API to get handle of a process's console window exists before Win2000,
	// so we resort to an Official Microsoft Kludge.

	// save the current console window's title
	if (!GetConsoleTitleA(titlebuf, MAX_SAVE_CONSOLE_TITLE)) return;

	// set console window's title to a temporary unique string
	sprintf(temptitlebuf, temptitle, (unsigned)GetCurrentProcessId());
	if (!SetConsoleTitleA(temptitlebuf)) return;

	Sleep(40);	// as in the example on the MS support site...

	// now find that window via a documented API
	hConsole = FindWindowA(NULL, temptitlebuf);	// lpClassName=NULL matches all classes
							// (documented in the MSDN Library)

	// restore the original title
	SetConsoleTitleA(titlebuf);
  }

  if (!hConsole) return;	// failed to obtain the console handle the first time, better not try again

  bigico = (HICON) SendMessage( hConsole, msg, ICON_BIG, (LPARAM) bigin);
  smallico = (HICON) SendMessage( hConsole, msg, ICON_SMALL, (LPARAM) smallin);

  if (bigout) *bigout = bigico;
  if (smallout) *smallout = smallico;
}

HICON oldbigicon, oldsmallicon;

void restoreicon(void)
{
  iconproc(WM_SETICON, oldbigicon, oldsmallicon, 0, 0);
}

void initializewindow(void)
{
  // set icon for console to first icon from the .exe resources

  HICON ico = LoadIcon( GetModuleHandle( NULL ), MAKEINTRESOURCE( 1 ) );

  if ( ico != NULL ) {
	iconproc(WM_GETICON, 0, 0, &oldbigicon, &oldsmallicon);
	iconproc(WM_SETICON, ico, ico, 0, 0);
	atexit(restoreicon);
  }
}
