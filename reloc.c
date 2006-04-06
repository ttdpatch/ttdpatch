
/* This file provides the DLL-like imports to make relocations work */

#define RELOC(a) int a __attribute__ ((dllexport)) = 0;

RELOC(ttdvar_base)
RELOC(trainpower)
RELOC(ophandler)
RELOC(landscape6)
RELOC(landscape7)
RELOC(newhousedatablock)
RELOC(bTempRaiseLowerDirection)
RELOC(bTempRaiseLowerCorner)

