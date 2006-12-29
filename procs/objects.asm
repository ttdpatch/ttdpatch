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

endcodefragments


varb toolbar_newelements
db cWinElemSpriteBox, cColorSchemeGrey
dw 650, 650+21, 0, 21, 4086
db cWinElemLast
toolbar_newelements_end:
endvar

%assign MAINTOOLBARBUTTONORG 26
exported patchobjects
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
	mov esi, toolbar_newelements
	mov ecx, toolbar_newelements_end-toolbar_newelements
	rep movsb
	
	ret
.notfoundelelist:
	ud2

