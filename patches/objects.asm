#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <house.inc>
#include <human.inc>
#include <town.inc>
#include <grf.inc>
#include <ptrvar.inc>
#include <bitvars.inc>
#include <idf.inc>
#include <objects.inc>
#include <window.inc>
#include <imports/gui.inc>

extern failpropwithgrfconflict
extern curspriteblock,grfstage

uvard objectsdataiddata,256*idf_dataid_data_size
uvard objectsdataidcount


extern objectsdataidtogameid
extern objectsgameiddata
extern objectsgameidcount
extern curgrfobjectgameids
extern RefreshWindowArea

global objectidf
vard objectidf
istruc idfsystem
	at idfsystem.dataid_dataptr, 		dd objectsdataiddata
	at idfsystem.dataid_lastnumptr,		dd objectsdataidcount
	at idfsystem.dataidtogameidptr,		dd objectsdataidtogameid
	at idfsystem.gameid_dataptr,		dd objectsgameiddata
	at idfsystem.gameid_lastnumptr,		dd objectsgameidcount
	at idfsystem.curgrfidtogameidptr,	dd curgrfobjectgameids
	at idfsystem.dataidcount,			dd NOBJECTS
	at idfsystem.gameidcount,			dd NOBJECTS
iend
endvar


%define objectclassesmax 255	// how many classes we can totally
uvard numobjectclasses			// how many classes we have have loaded already
uvard objectclasses, 256		// the actual defined classes

uvard lastobjectdataid

uvard lastobjectgameid

// special functions to handle special object properties
//
// in:	eax=special prop-num
//	ebx=offset (first id)
//	ecx=num-info
//	edx->feature specific data offset
//	esi=>data
// out:	esi=>after data
//	carry clear if successful
//	carry set if error, then ax=error message
// safe:eax ebx ecx edx edi
	
exported setobjectclass
.nextdefine:

	push ecx
// first we define the class, if the class fails to load, we can't select the object anyway,
// so storeing and resolveing gameid isn't need either.
.loadclass:
	lodsd
	mov ecx,[numobjectclasses]
	mov edi,objectclasses
	repne scasd
	je .classalreadydefined
	
	cmp dword [numobjectclasses], objectclassesmax
	jb .createnewclass 
	
.nomoreclasses:
	pop ecx
	mov al,GRM_EXTRA_OBJECTS
	jmp failpropwithgrfconflict
	
.createnewclass:
	// edi points to end of objectclasses
	stosd
	inc dword [numobjectclasses]
.classalreadydefined:

// creates a new gameid:
// in: ebx = action id,  edx = feature in framework
// out: 
// carry set = error, al = code why:  0 = already defined  1 = no more gameids free
// ax = gameid
	mov edx, objectidf
	extcall idf_createnewgameid
	jnc .ok
	cmp ax, 0
	je .alreadyset
.toomany:
	pop ecx
	mov ax, GRM_EXTRA_OBJECTS
	jmp failpropwithgrfconflict
.alreadyset:
	pop ecx
	mov ax, ourtext(invalidsprite)
	stc
	ret
.ok:

.endofthisdefine:
	pop ecx
	inc ebx
	dec ecx
	jnz .nextdefine
	
// all settings are ok
	clc
	ret

// clear the dataids for creating new game or if the game doesn't have one yet
exported clearobjectdataids
	pusha
	xor eax,eax
	mov edi,objectsdataiddata
	mov ecx,NOBJECTS*idf_dataid_data_size
	rep stosd
	popa
	ret




// Select window
%assign win_objectgui_id 111

%assign win_objectgui_width 200
%assign win_objectgui_height 300
%assign win_objectgui_padding 10 
%assign win_objectgui_dropwidth 12 
%assign win_objectgui_dropheight 12
%assign win_objectgui_previewheight 60

varb win_objectgui_elements
db cWinElemTextBox,cColorSchemeDarkGreen
dw 0, 10, 0, 13, 0x00C5
db cWinElemTitleBar,cColorSchemeDarkGreen
dw 11, win_objectgui_width-1, 0, 13, ourtext(grfstatcaption)
db cWinElemSpriteBox,cColorSchemeDarkGreen
dw 0, win_objectgui_width-1, 14, win_objectgui_height-1, 0
// Dropdown
db cWinElemSpriteBox,cColorSchemeGrey
dw win_objectgui_padding, win_objectgui_width-1-win_objectgui_padding-win_objectgui_dropwidth-1
dw 20, 20+win_objectgui_dropheight
dw 0
db cWinElemTextBox,cColorSchemeGrey
dw win_objectgui_width-1-win_objectgui_padding-win_objectgui_dropwidth,win_objectgui_width-1-win_objectgui_padding, 
dw 20, 20+win_objectgui_dropheight,statictext(txtetoolbox_dropdown)
// Preview
db cWinElemSpriteBox,cColorSchemeGrey
dw win_objectgui_padding,win_objectgui_width-1-win_objectgui_padding, 
dw 40, 40+win_objectgui_previewheight, 0
db cWinElemLast
endvar


exported win_objectgui_create
	bts dword [esi+window.activebuttons], 26
	or byte [esi+window.flags], 7
	call [RefreshWindowArea]
	pusha
	mov cl, 0x2A
	mov dx, win_objectgui_id // window.id
	call dword [BringWindowToForeground]
	test esi,esi
	jz .noold
	popa
	ret

.noold:
	mov eax, 100 + (100<<16) // x + (y << 16)
	mov ebx, win_objectgui_width + (win_objectgui_height << 16)
	mov cx, 0x2A			// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_objectgui_winhandler)
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], addr(win_objectgui_elements)
	mov word [esi+window.id], win_objectgui_id // window.id
	popa
	ret

win_objectgui_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near win_objectgui_redraw
	cmp dl, cWinEventClick
	jz near win_object_clickhandler
	cmp dl, cWinEventTimer
	jz win_objectgui_timer
//	cmp dl, cWinEventSecTick
//	jz win_signalgui_sectick
	ret
win_objectgui_timer:
	mov dword [esi+window.activebuttons], 0
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
//	or byte [esi+window.flags], 7
	ret
	
win_objectgui_redraw:
	call dword [DrawWindowElements]
	ret
	
win_object_clickhandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
	cmp cl, 0
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cl, 1
	jne .nottilebar
	jmp dword [WindowTitleBarClicked]
.nottilebar:
	cmp cl, 2
	jnz .notbackground
	ret
.notbackground:
	ret

