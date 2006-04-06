#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc moreanimation, patchmoreanimation


extern animarraysize,malloccrit
extern newanimarray


patchmoreanimation:
	mov eax,[animarraysize]
	mov ebp,eax
	shl eax,1
	push eax
	call malloccrit
	pop ebx
	mov [newanimarray],ebx
	add eax,ebx
	stringaddress findanimlist1,1,1
	mov [edi-4],ebx
	mov [edi+0x32+7*WINTTDX],eax
	stringaddress findanimlist2,1,1
	mov [edi+11],ebx
	mov [edi+16],ebp
	stringaddress findanimlist3,1,1
	mov [edi-4],ebx
	mov [edi+0x12],eax
	stringaddress findanimlist4,1,1
	mov [edi-4],ebx
	mov [edi+0x12],eax
	stringaddress findanimlist5,1,1
	mov [edi-4],ebx
	mov [edi+4],bp
	mov [edi+34],bp
	stringaddress findanimlist6,1,1
	dec eax
	dec eax
	mov [edi-6],eax
	ret



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
