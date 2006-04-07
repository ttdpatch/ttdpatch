#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_SLOWCROSSING),, patchcrossingslowdown

begincodefragments

codefragment oldtrainactivatecrossingmove
	push eax		// 50 56 B8 0C 00 00 00
	push esi
 	mov eax, 0Ch

codefragment newtrainactivatecrossingmove
	cmp word [esi+34h], 30		
	jb $+2+0x06
	mov word [esi+34h], 30
	nop


endcodefragments

patchcrossingslowdown:
	// Slow down before Rail Crossing (Bit 0)
	patchcode trainactivatecrossingmove
	ret
