#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <patchproc.inc>
#include <window.inc>


patchproc newobjects, patchobjects

begincodefragments

codefragment findmaintoolbarclicktable, 12
	js $+6+0x186
	movzx ebx, cx

codefragment findmaintoolbartooltiptable, 13
	js $+6+0x16A
	movzx ebx, cx
	
codefragment newobjectsdefandclassnames
	extern objectsdefandclassnames
	nop
	mov esi, [objectsdefandclassnames+eax*4]
	
endcodefragments


varb toolbar_newelements
db cWinElemSpriteBox, cColorSchemeGrey
dw 562, 562+21, 0, 21, 4086
db cWinElemLast
toolbar_newelements_end:
endvar

varb toolbar_newelements_small
db cWinElemSpriteBox, cColorSchemeGrey
dw 556, 556+17, 0, 21, 4086
db cWinElemLast
endvar

%assign MAINTOOLBARBUTTONORG 26
exported patchobjects
	// change the textid table for class a to support new objects
	extern ophandler
	mov eax,[ophandler+0xA*8]
	mov esi,[eax+8]
	mov esi,[esi+4]
	mov edi, objectsdefandclassnames
	// copy the old data
	mov ecx,8
	rep movsd
	// store the new fragment
	mov edi,[eax+8]
	storefragment newobjectsdefandclassnames
			
	stringaddress findmaintoolbartooltiptable
	mov eax, edi
	mov esi, [eax]
	push (MAINTOOLBARBUTTONORG+1)*2
	extcall malloc
	pop edi
	mov [eax], edi
	mov ecx, MAINTOOLBARBUTTONORG
	rep movsw
	mov word [edi], 0x1F9	// set the new tooltip

	stringaddress findmaintoolbarclicktable
	mov eax, edi
	mov esi, [edi]
	push (MAINTOOLBARBUTTONORG+1)*4
	extcall malloc
	pop edi
	mov [eax], edi
	mov eax, esi
	
	mov ecx, MAINTOOLBARBUTTONORG
	rep movsd
	extern win_objectgui_create
	mov dword [edi], win_objectgui_create 
	
	mov edi, eax
	// we assume that the click list follows the window element list 
	dec edi
	cmp dword [edi-3], 0x0B02D300	// check end marker
	jne .notfoundelelist
	
	extern reswidth
	cmp word [reswidth], 680
	ja .big
	push edi
	sub edi, 12*8
	mov ecx, 5
.nextmovesmall:
	sub word [edi+2], 6
	sub word [edi+4], 6
	add edi, 12
	dec ecx
	jnz .nextmovesmall
	pop edi
	mov esi, toolbar_newelements_small
	jmp .small
.big:
	push edi
	sub edi, 12*3
	mov ecx, 3
.nextmovebig:
	add word [edi+2], 22
	add word [edi+4], 22
	add edi, 12
	dec ecx
	jnz .nextmovebig
	pop edi
	mov esi, toolbar_newelements
.small:
	mov ecx, toolbar_newelements_end-toolbar_newelements
	rep movsb
	
	ret
.notfoundelelist:
	ud2

