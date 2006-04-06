#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

// all switches using L7 must be listed here
patchproc higherbridges,newhouses,newindustries,onewayroads, patchlandscape7

extern malloccrit,landscape7_ptr, reloc

patchlandscape7:
	push dword 0x10000
	call malloccrit
	// leave on stack for reloc
	push landscape7_ptr
	call reloc
	ret


