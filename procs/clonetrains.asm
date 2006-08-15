// Houses the fragments for Clone Train

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <textdef.inc>
#include <window.inc>

extern patchflags, malloccrit
extern variabletofind, variabletowrite
extern newDepotWinElemList, CloneDepotToolTips
extern CloneDepotClick, CloneDepotRightClick
extern patchwindowsizer.addforclonetrain

ext_frag findvariableaccess,newvariable

patchproc clonetrain, patchclonetrain

begincodefragments

codefragment finddepotwinelemlist,-12
	db cWinElemTitleBar, cColorSchemeGrey
	dw 0xFF, 0xFF
depotwinelemx1 equ $-4
depotwinelemx2 equ $-2

codefragment findoldtextstrings, 13
	db 0x0F, 0x88, 0x6D, 0x02, 0x00, 0x00
	movzx ebx, cx
	db 0x66, 0x8B, 0x04, 0x5D

codefragment olddepotrightclick
	db 0x66, 0x8B, 0x04, 0x5D
	dd 0x00
depotrightclicktooltips equ $-4

codefragment newdepotrightclick
	icall CloneDepotRightClick
	setfragmentsize 8

codefragment olddepotleftclick
	cmp cl, 2
	db 0x0F, 0x84, 0xB4, 0x01, 0x00, 0x00

codefragment newdepotleftclick
	icall CloneDepotClick
	setfragmentsize 9

endcodefragments

patchclonetrain:
	mov word [depotwinelemx1], 11
	mov word [depotwinelemx2], 348
	stringaddress finddepotwinelemlist

	push edi
	mov esi, edi

	mov ecx, 7*12+1 + 1*12
testmultiflags enhancegui
	jz .noenhancegui
	add ecx, 2*12

.noenhancegui:
	push ecx
	call malloccrit
	pop edi

	push edi
	mov ecx, 7*12+1
	rep movsb
	pop esi
	pop edi

	call .addclonebutton

	mov [variabletofind], edi
	mov [variabletowrite], esi
	mov dword [newDepotWinElemList], esi

	patchcode findvariableaccess, newvariable, 1, 1

	// Add the Window sizer
	call patchwindowsizer.addforclonetrain

	// Now hook some misc bits of code
	stringaddress findoldtextstrings
	mov edi, [edi]
	mov dword [depotrightclicktooltips], edi
	mov dword [CloneDepotToolTips], edi

	patchcode olddepotrightclick, newdepotrightclick
	patchcode olddepotleftclick, newdepotleftclick

	ret

.addclonebutton:
	push ebx
	mov ebx, 7*12
	mov byte [esi+ebx+1*12+windowbox.type], cWinElemLast // Move the last window element
	mov byte [esi+ebx+windowbox.type], cWinElemTextBox
	mov byte [esi+ebx+windowbox.bgcolor], cColorSchemeGrey
testmultiflags enhancegui
	jz .noenhanceguix
	mov word [esi+ebx+windowbox.x1], 113
	mov word [esi+ebx+windowbox.x2], 113+111
	mov word [esi+ebx+windowbox.y1], 98
	mov word [esi+ebx+windowbox.y2], 98+11
	mov word [esi+ebx+windowbox.text], ourtext(txtclonedepotbutton)
	mov ebx, 5*12
	mov word [esi+ebx+windowbox.x2], 112
	mov word [esi+ebx+1*12+windowbox.x1], 113+111+1
	pop ebx
	ret

.noenhanceguix:
	mov word [esi+ebx+windowbox.x1], 117
	mov word [esi+ebx+windowbox.x2], 117+115
	mov word [esi+ebx+windowbox.y1], 98
	mov word [esi+ebx+windowbox.y2], 98+11
	mov word [esi+ebx+windowbox.text], ourtext(txtclonedepotbutton)
	mov ebx, 5*12
	mov word [esi+ebx+windowbox.x2], 116
	mov word [esi+ebx+1*12+windowbox.x1], 117+115+1
	pop ebx
	ret

