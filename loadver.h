#ifndef LOADVER_H
#define LOADVER_H
// File contains the offsets for the various TTD versions, as include files
// in /versions

#include "versions.h"

#if WINTTDX
u32 _Version1[] =
#	include "versions/20110016.ver"
u32 _Version2[] =
#	include "versions/20110018.ver"
u32 _Version3[] =
#	include "versions/20110024.ver"
u32 _Version4[] =
#	include "versions/20110042.ver"
u32 _Version5[] =
#	include "versions/20110044.ver"
#else
u32 _Version1[] =
#	include "versions/111933d7.ver"
u32 _Version2[] =
#	include "versions/111933f4.ver"
u32 _Version3[] =
#	include "versions/111939c7.ver"
u32 _Version4[] =
#	include "versions/111945d7.ver"
u32 _Version5[] =
#	include "versions/111946c6.ver"
#endif
pversioninfo versions[] = { 
	(pversioninfo) _Version1, 
	(pversioninfo) _Version2,
	(pversioninfo) _Version3,
	(pversioninfo) _Version4,
	(pversioninfo) _Version5
};
#endif
