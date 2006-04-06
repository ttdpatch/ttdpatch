#include <defs.inc>
#include <frag_mac.inc>

global patchsignalsontrafficside

begincodefragments

codefragment oldsignaloffsets,2
	push eax
	push ecx
	db 0x66,0xBB	// mov bx,imm16

codefragment newsignaloffsets
	mov bl,0	// patch count, see patches.ah
	call runindex(setsignaloffsets)
	setfragmentsize 9


endcodefragments

patchsignalsontrafficside:
	multipatchcode oldsignaloffsets,newsignaloffsets,12,{inc byte [esi-8]}
		// the INC increases patch count (the imm8 operand of "mov bl,x" in codefragment newsignaloffsets)
	ret
