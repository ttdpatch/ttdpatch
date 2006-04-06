#ifndef VERSIONS_H
#define VERSIONS_H
// File contains the offsets for the various TTD versions, as include files
// in /versions

#include "common.h"

#define NOVERSION 0xffffffff

#define ALLOCEMPTYOFFSETS 2048	// allocate space for this many offsets
				// if we have no version information

typedef struct {
	u32 version, filesize, numoffsets;
} versionheader;

typedef struct {
	versionheader h;
	u32 versionoffsets[ALLOCEMPTYOFFSETS];	// number is actually variable
} versioninfo, *pversioninfo;

typedef versioninfo versionarray[], *pversionarray;

#if defined(IS_TTDSTART_CPP)
#	define ISEXTERN
#else
#	define ISEXTERN extern
#endif

ISEXTERN pversioninfo curversion;

#undef ISEXTERN
#endif
