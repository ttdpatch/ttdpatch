#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>

extern dailyvehproc,dailyvehproc.oldaircraft,drawsplittextfn
extern gettextandtableptrs,vehtickproc.oldaircraft
extern vehtickproc_aircraft


global patchnewplanes
patchnewplanes:
	patchcode setplanecargotype
	patchcode showplanestats
	patchcode shownewplaneinfo
	stringaddress findopennewplanewnd,1,2
	mov ebx,(50 << 16)+50
	add word [edi-4],bx
	stringaddress findopennewplanewnd,2,1
	add [edi-4],bx

	mov edi,[edi+15]
	add [edi+56],bx
	add [edi+66],ebx
	add [edi+78],ebx

	// replace "n passengers, n bags of mail" by 0x80
	mov ax,0xa02e
	call .adjust

	mov ax,0xa007
	call .adjust

	std
	mov al,0x7c
	repne scasb
	mov byte [edi+1],0x7d	// change year from word to byte
	cld

	mov esi,vehtickproc_aircraft
	mov eax,[ophandler+0x13*8]	// aircraft vehicle class
	xchg esi,[eax+0x14]		// vehtickproc
	mov [vehtickproc.oldaircraft],esi

	mov esi,dailyvehproc
	xchg esi,[eax+0x1c]		// dailyvehproc
	mov [dailyvehproc.oldaircraft],esi

	patchcode oldshipplanestartsound,newvehstartsound,3-2*WINTTDX,3
	patchcode touchdownsound
	ret

.adjust:
	call gettextandtableptrs
	mov al,0x7c
	or ecx,byte -1
	repne scasb
	mov byte [edi-1],0x80

	mov esi,edi
	mov al,13
	repne scasb
	dec edi
	xchg esi,edi

.copynext:
	lodsb
	stosb
	test al,al
	loopnz .copynext
	ret



begincodefragments

codefragment oldsetplanecargotype
	mov byte [esi+veh.cargotype],0
	mov byte [edi+veh.cargotype],2

codefragment newsetplanecargotype
	icall setplanecargotype
	setfragmentsize 8

codefragment oldshowplanestats
	mov bx,0xa007

codefragment newshowplanestats
	icall showplanestats
	call [drawsplittextfn]
	setfragmentsize 14

codefragment oldshownewplaneinfo,-8
	mov bx,0xa02e

codefragment newshownewplaneinfo
	icall shownewplaneinfo
	setfragmentsize 8

codefragment findopennewplanewnd
	dw 98h	// aircraft class offset
	mov ebp,4

glob_frag oldshipplanestartsound
codefragment oldshipplanestartsound,12
	push eax
	movzx eax,word [esi+veh.vehtype]

glob_frag newvehstartsound
codefragment newvehstartsound
	icall vehstartsound
	pop eax
	ret

codefragment oldtouchdownsound
	mov eax,0x15

codefragment newtouchdownsound
	icall touchdownsound
	setfragmentsize 10


endcodefragments
