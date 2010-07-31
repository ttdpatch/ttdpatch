#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <patchproc.inc>
#include <window.inc>
#include <objects.inc>


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

codefragment newobjectdefercleartile, 7
	or dh, dh
	db 0x78, 0x1D // js $+0x1D
	cmp dh, 3

codefragment findobjectcleartile, -4
	db 0x44 + (6 * WINTTDX)
	push ebx
	push edx

codefragment oldobjecthookcompanycleartile, -7
	dw 0x013B
	mov dl, byte [landscape1+edi]

codefragment newobjecthookcompanycleartile, 9
extern RemoveObject
	icall RemoveObject
	jc $+3
	ret

codefragment newobjectdeferdrawtile, 8
	pop cx
	pop ax
	ret
	cmp dh, 3

codefragment oldobjecthookdrawtile, 6
	pop ax
	ret
	movzx ebp, bx

codefragment newobjecthookdrawtile, 14
extern DrawObject
	icall DrawObject
	jnc $+8
	ret

codefragment oldobjecthookquery
	cmp cl, 2
	jz $+6
	mov ax, 0x5805 // Company owned land

codefragment newobjecthookquery
extern QueryObject
	icall QueryObject
	setfragmentsize 9

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
	jne near .notfoundelelist
	
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

	// Our Object Array
extern malloccrit, objectpool_ptr, reloc
	push dword NACTIVEOBJECTS*object_size
	call malloccrit
	// leave on stack for reloc
	push objectpool_ptr
	call reloc

	stringaddress newobjectdefercleartile
	mov byte [edi], 0x73 // jae

extern ObjectClearTile
	stringaddress findobjectcleartile
	mov dword [ObjectClearTile], edi
	patchcode objecthookcompanycleartile, 2, 2
	
	stringaddress newobjectdeferdrawtile, 1, 1
	mov byte [edi], 0x73 // jae
	patchcode objecthookdrawtile, 1, 2
	patchcode objecthookquery

extern ClassAAnimationHandler, ClassAPeriodicHandler
	mov eax, [ophandler+(0xA * 8)]
	mov dword [eax+(12 * 4)], ClassAAnimationHandler
	mov dword [eax+(8 * 4)], ClassAPeriodicHandler
	ret

.notfoundelelist:
	ud2



