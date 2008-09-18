#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc BIT(EXP_RAILVEHMENU), patchrailvehmenu

begincodefragments

codefragment oldtraindepotdragdropfailed, 2
	or ebx, ebx
	jz $+2+0x18
	cmp byte [ebx+veh.subclass], 0

codefragment newtraindepotdragdropfailed
	icall TrainDepotDragDropFailed
	db 0x73	// convert jnz to jnc 
	
endcodefragments

patchrailvehmenu:
	patchcode oldtraindepotdragdropfailed,newtraindepotdragdropfailed,1,1
	ret
