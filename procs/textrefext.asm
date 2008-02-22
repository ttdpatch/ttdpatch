#include <frag_mac.inc>
#include <patchproc.inc>

patchproc anyflagset, extendtextref

begincodefragments

codefragment oldsavestack,1
	push ebp
	push dword [textrefstack]

codefragment newsavestack
	sub esp, 20h
	pusha
	xor ecx, ecx
	mov cl, 8
	mov esi, textrefstack
	lea edi, [esp+ecx*4]
	rep movsd
	popa
	jmp short fragmentstart+42

codefragment newrestorestack
	pusha
	xor ecx, ecx
	mov cl, 8
	mov edi, textrefstack
	lea esi, [esp+ecx*4]
	rep movsd
	popa
	add esp, 20h
	jmp short fragmentstart+42

codefragment oldpoparg
	push eax
	mov eax, [textrefstack+1]
ovar oldtextrefptr
textref.oldptr equ 0

codefragment newpoparg
	pusha
	mov edi, textrefstack
	lea esi, [edi+1]
ovar offset,-1
textref.offset equ offset-oldtextrefptr
	xor ecx, ecx
	mov cl, 1Fh
ovar count,-1
textref.count equ count-oldtextrefptr
	rep movsb
	popa
	jmp short fragmentstart+64
ovar target, -1
textref.target equ target-oldtextrefptr

codefragment oldpush3word
	mov ax, [textrefstack+10h]

codefragment newpush3word
	pusha
	std
	mov edi, textrefstack+1Fh
	lea esi, [edi-6]
	mov ecx, 20h-6
	rep movsb
	cld
	popa
	jmp short fragmentstart+52

endcodefragments

extendtextref:
%macro storerestore 0
	add edi, byte lastediadj+42+5
	storefragment newrestorestack
%endmacro
	multipatchcode oldsavestack, newsavestack, 4, storerestore

	multipatchcode poparg, 2	// pop byte

	mov ebx, oldtextrefptr
	inc dword [ebx+textref.oldptr]
	inc byte [ebx+textref.offset]
	dec byte [ebx+textref.count]
	multipatchcode poparg, 11	// pop word

	mov al,2
	add [ebx+textref.oldptr],eax
	add [ebx+textref.offset],al
	sub [ebx+textref.count],al
	sub byte [ebx+textref.target],12// dword pops do not have a mov ax, [...] / mov [...], ax pair.
	multipatchcode poparg, 15	// pop dword

	patchcode push3word

	ret
