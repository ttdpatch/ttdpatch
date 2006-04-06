
#include <defs.inc>
#include <frag_mac.inc>

extern aiboostfactor

%macro fixaibyte 0
	mov cl,[aiboostfactor]
	shl byte [edi+6], cl
%endmacro
	


global patchaibooster
patchaibooster:
	multipatchcode oldAIareasize,newAIareasizedummy,12, fixaibyte
#if 0
	stringaddress oldairecursion1,1,1
	movzx eax,byte [edi]
	movzx ecx,byte [aiboostfactor]
	imul eax,ecx
	shr eax,2
	add [edi],al

	xor ecx,ecx

	stringaddress oldairecursion2,1,1
	movzx eax,byte [edi]
	movzx ecx,byte [aiboostfactor]
	imul eax,ecx
	shr eax,3
	add [edi],al

	xor ecx,ecx
#endif
	ret



begincodefragments

codefragment oldAIareasize
	// mov [esi+company.AIconstr.areasize], ??
	db 0xC6,0x86,0xC6,0x02,0x00,0x00  

codefragment newAIareasizedummy


endcodefragments
