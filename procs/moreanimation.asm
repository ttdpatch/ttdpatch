#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <flagdata.inc>

patchproc moreanimation, patchmoreanimation


extern malloccrit
uvard newanimarray

begincodefragments

codefragment findanimlist1
	movzx ebx,word [esi]
	or bx,bx

codefragment findanimlist2
	or ax,ax
	jnz $+2+0x17

codefragment findanimlist3
	mov bx,[esi]
	or bx,bx
	jz $+2+0x14

codefragment findanimlist4
	mov bx,[esi]
	or bx,bx
	jz $+2+0x10

codefragment findanimlist5
	xor ebx,ebx
	mov dx,0x100

codefragment findanimlist6
	mov bx,[esi+2]
	mov [esi],bx


endcodefragments


patchmoreanimation:
	mov eax,[animarraysize]
	shl eax,1
	push eax
	call malloccrit
	pop ebx
	mov [newanimarray],ebx
	lea ebp,[eax+ebx]
	stringaddress findanimlist1,1,1
	mov [edi-4],ebx
	mov [edi+0x32+7*WINTTDX],ebp
	stringaddress findanimlist2,1,1
	mov [edi+11],ebx
	mov eax,[animarraysize]
	mov [edi+16],eax
	stringaddress findanimlist3,1,1
	mov [edi-4],ebx
	mov [edi+0x12],ebp
	stringaddress findanimlist4,1,1
	mov [edi-4],ebx
	mov [edi+0x12],ebp
	stringaddress findanimlist5,1,1
	mov [edi-4],ebx
	mov eax,[animarraysize]
	mov [edi+4],ax
	mov [edi+34],ax
	stringaddress findanimlist6,1,1
	dec ebp
	dec ebp
	mov [edi-6],ebp
	ret
