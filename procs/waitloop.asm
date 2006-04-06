#if WINTTDX

// dos version still needs to be done

#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc gamespeed,generalfixes, patchwaitloop

extern dynprevtickcount,miscmodsflags,patchflags,prevtickcount


patchwaitloop:
	stringaddress oldwaitloop,1,1
	mov eax,[edi+4]
	mov dword [prevtickcount],eax
	mov dword [dynprevtickcount],eax

	testmultiflags generalfixes
	jz .dodynwaitloop
	test byte [miscmodsflags+1],MISCMODS_NOTIMEGIVEAWAY>>8
	jnz .dodynwaitloop

	storefragment newwaitloop
	jmp .endwaitloop
.dodynwaitloop:
	storefragment newdynwaitloop
.endwaitloop:
	ret

begincodefragments

codefragment oldwaitloop
	mov ebx,eax
	db 0x2b,5	// sub eax,[....]

codefragment newwaitloop
	call runindex(waitloop)
	setfragmentsize 11

codefragment newdynwaitloop
	call runindex(dynwaitloop)
	setfragmentsize 11


endcodefragments
#endif
