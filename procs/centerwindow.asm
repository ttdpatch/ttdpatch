#if WINTTDX

#include <defs.inc>
#include <frag_mac.inc>
#include <win32.inc>
#include <patchproc.inc>
#include <bitvars.inc>

extern patchflags

patchproc generalfixes,stretchwindow, patchwindowcenter

begincodefragments

codefragment newcenterwindow
	icall centerwindow
	push ecx
	push eax
	setfragmentsize 8

endcodefragments

patchwindowcenter:
	xor ebx,ebx
	testflags generalfixes
	jnc .nofixtaskbar
	test dword [miscmods2flags],MISCMODS2_IGNORETASKBAR
	setz bl
.nofixtaskbar:
	testflags stretchwindow
	adc bl,0

	test bl,bl
	jz .nopatch

	mov edi,0x404b42
	storefragment newcenterwindow

.nopatch:
	ret

#endif // WINTTDX
