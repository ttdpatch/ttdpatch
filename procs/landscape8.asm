#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

// all switches that use landscape8 must be listed here
patchproc newroutes, patchlandscape8


extern malloccrit, landscape8_ptr, reloc


patchlandscape8:
	push dword 0x20000
	call malloccrit
	// leave on stack for reloc
	push landscape8_ptr
	call reloc
	ret

