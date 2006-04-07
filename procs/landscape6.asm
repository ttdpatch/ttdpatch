#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

// all switches that use landscape6 must be listed here
patchproc abandonedroads,newstations,newhouses,pathbasedsignalling,newindustries,irrstations, patchlandscape6


extern malloccrit,landscape6_ptr, reloc


patchlandscape6:
	push dword 0x10000
	call malloccrit
	// leave on stack for reloc
	push landscape6_ptr
	call reloc
	ret
