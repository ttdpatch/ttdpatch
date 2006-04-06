#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc aichoosechances, patchaichoosechances


extern aibuildairchance,aibuildrailchance
extern aibuildrvchance


patchaichoosechances:
	stringaddress findaiplannewroute,1,1
	add edi, 2
	mov ax, [aibuildrailchance]
	mov [edi], ax
	add ax, [aibuildrvchance]
	add edi, 6
	mov [edi], ax
	add ax, [aibuildairchance]
	add edi, 6
	mov [edi], ax
	ret



begincodefragments

codefragment findaiplannewroute,11
	mov cx, 200
	push cx


endcodefragments
