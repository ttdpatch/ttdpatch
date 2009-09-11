
/* This file provides the DLL-like imports to make relocations work */

#define RELOC(a) int a __attribute__ ((dllexport)) = 0;

RELOC(ttdvar_base)
RELOC(trainpower)
RELOC(rvspeed)
RELOC(shipsprite)
RELOC(planesprite)
RELOC(ophandler)
RELOC(landscape6)
RELOC(landscape7)
RELOC(newhousedatablock)
RELOC(industrydatablock)
RELOC(bTempRaiseLowerDirection)
RELOC(player2ofs)
RELOC(landscape8)
RELOC(station2ofs)
RELOC(vehtypedata)
RELOC(objectpool)
RELOC(window2ofs)
