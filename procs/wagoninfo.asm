#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newtrains,wagonspeedlimits, patchwagoninfo


extern drawsplittextfn
extern drawtextfn

begincodefragments

codefragment oldshowwagoninfo,-46
	mov bx,0x8821

codefragment newshowwagoninfo
	call runindex(showwagoninfo)
	jmp newshowwagoninfo_start+45


endcodefragments


patchwagoninfo:
	patchcode oldshowwagoninfo,newshowwagoninfo,1,1
	mov dword [edi+lastediadj+46],0x26748d	// lea esi,[byte 0+1*esi] (nop)
	mov eax,[drawsplittextfn]
	sub eax,[drawtextfn]
	add [edi+lastediadj+56],eax
	ret
