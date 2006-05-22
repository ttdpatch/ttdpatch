//
// This file is part of TTDPatch
// Copyright (C) 2001-2002 by Josef Drexler, Marcin Grzegorczyk
//
// codepage.c: defines functions dealing with codepage conversions
//

#if WINTTDX

#include <stdlib.h>

#include "osfunc.h"
#include "codepage.h"
#include "error.h"

#ifdef WIN32

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>

// One-character string to use as a replacement for unmappable characters during codepage conversion
#define ACP_DEFAULT_CHAR "_"


int acp = -1;			// ANSI code page


// Convert a string from language's native code page to the system ANSI code page.
// Returns pointer to a buffer whose content is destroyed by each call,
// and which may be dynamically reallocated.
// If the buffer cannot be allocated or the conversion fails for any reason,
// returns 'str'.
// Special case: if 'str' points to an empty string, buffers are freed.
const char *converttoACP(const char *str) {
  static int outbufsize, unibufsize;	// initially 0
  static char *outbuf;			// initially NULL
  static LPWSTR unibuf;			// same here
  static const char *defchar = ACP_DEFAULT_CHAR;
  int unilen, outlen;

  if (*str == '\0') {
    if (outbufsize) {
      outbufsize = 0;
      free(outbuf);
      outbuf = NULL;
    }
    if (unibufsize) {
      unibufsize = 0;
      free(unibuf);
      unibuf = NULL;
    }
    return str;
  }

  if (acp < 0) {
    // Initialize the code page the first time this function is used
    char *acp_env = getenv("ACP");
    if (acp_env) {
      long v = strtol(acp_env, NULL, 10);
      if (v > 0) acp = v;
    }
    if (acp < 0) acp = CP_ACP;
    if (acp >= 65000 && acp < 65100) defchar = NULL;	// UTF-* require this
  }

  unilen = MultiByteToWideChar(codepage, MB_PRECOMPOSED, str, -1, NULL, 0);
  if (!unilen) return str;

  if (unilen > unibufsize) {
    int bufsize = (unilen + 255) & ~255;
    LPWSTR buf = realloc(unibuf, bufsize*sizeof(*unibuf));
    if (!buf) return str;
    unibuf = buf;
    unibufsize = bufsize;
  }

  if (MultiByteToWideChar(codepage, MB_PRECOMPOSED, str, -1, unibuf, unibufsize) != unilen)
	return str;

  outlen = WideCharToMultiByte(acp, 0, unibuf, unilen, NULL, 0, defchar, NULL);
  if (!outlen) return str;

  if (outlen >= outbufsize) {		// outbuf must have space for terminating NUL
    int bufsize = (outlen + 256) & ~255;
    char *buf = realloc(outbuf, bufsize*sizeof(*outbuf));
    if (!buf) return str;
    outbuf = buf;
    outbufsize = bufsize;
  }

  if (WideCharToMultiByte(acp, 0, unibuf, unilen, outbuf, outlen, defchar, NULL) != outlen)
	return str;

  outbuf[outlen] = 0;
  return outbuf;		// whew!
}


// Take a string from the langtext array and convert it to the system ANSI code page
// (useful for writing the config file)
const char *langcfg(size_t index) {
//#if DEBUG
  if (!langtext[index])
	error("langtext[%d] is NULL!\n", index);
//#endif
  return converttoACP(langtext[index]);
}

const char *langstr(const char *str) {
  if (!str)
	error("langstr got NULL pointer!\n");
  return converttoACP(str);
}


// Convert all "&#xHHHH;" escape sequences to Unicode characters in a wide string
// assumes wchar_t is Unicode
static void foldunicode_ws(wchar_t *ws)
{
  wchar_t wc, *wd = ws;

  do {
    wc = *ws;
    if (wc == L'&' && ws[1] == L'#' && ws[2] == L'x') {
      wchar_t *nws;
      unsigned long x = wcstoul(ws + 3, &nws, 16);
      if (nws != ws + 3 && *nws == L';') {
	wc = (wchar_t)x;
	ws = nws;
      }
    }
    ws++;
    *wd++ = wc;
  } while (wc);
}


// Get a Windows error message from an error code
const char *getwinerrormsg(unsigned long err)
{
  char *msgptr;
  return FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, NULL, err, 0, (LPTSTR)&msgptr, 0, NULL)
		? msgptr : "";
}


// Convert all "&#xHHHH;" escape sequences in a string to the current code page
// (conversion done in place; fold all composite characters produced)
void convertescapedstring(char *str)
{
  LPWSTR unibuf;
  int unibufsize, strbufsize = strlen(str) + 1;

  if (!IsValidCodePage(codepage))
	error("Conversion impossible, code page %lu is not valid on this system!\n", (unsigned long)codepage);

  unibufsize = MultiByteToWideChar(codepage, MB_COMPOSITE, str, -1, NULL, 0);
  if (!unibufsize)
	error("Conversion failed in %s: %s\n", "MultiByteToWideChar", getwinerrormsg(GetLastError()));

  unibuf = calloc(unibufsize, sizeof *unibuf);
  if (!unibuf)
	error("Cannot allocate buffer for conversion\n");

  {
    int i = MultiByteToWideChar(codepage, MB_COMPOSITE, str, -1, unibuf, unibufsize);
    if (i != unibufsize)
	error("MultiByteToWideChar returned %d on the first call and %d on the second call!\n"
	      "LastError: %s\n",
	      unibufsize, i, getwinerrormsg(GetLastError()));
  }

  foldunicode_ws(unibuf);

  if (!WideCharToMultiByte(codepage, WC_COMPOSITECHECK, unibuf, -1, str, strbufsize, ACP_DEFAULT_CHAR, NULL))
	error("Conversion failed in %s: %s\n", "WideCharToMultiByte", getwinerrormsg(GetLastError()));

  free(unibuf);
}

#else	/* !WIN32 */

/* We only need to stub convertescapedstring and langcfg
   because this is only used for makelang */

void convertescapedstring(char *str) { }

const char *langcfg(size_t index) { return NULL; }
const char *langstr(const char *str) { return NULL; }

#endif	/* linux */
#endif /* WINTTDX */
