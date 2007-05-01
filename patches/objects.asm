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
#include <windowext.inc>
#include <imports/gui.inc>
#include <misc.inc>
#include <imports/dropdownex.inc>

extern failpropwithgrfconflict
extern curspriteblock,grfstage
extern RefreshWindowArea

uvard objectsdataiddata,256*idf_dataid_data_size
uvard objectsdataidcount

global objectsdefandclassnames
uvard objectsdefandclassnames, 512


// objects id management
extern objectsdataidtogameid
extern objectsgameiddata
extern objectsgameidcount

// objects id management per grf
extern curgrfobjectgameids

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

// Properties for objects (gameid based)
extern objectclass				// a word id to the actuall objectclasses
extern objectnames				// a TextID

// Properties for classes of objects
extern objectclasses			// the actual defined classes
extern objectclassesnames		// the TextID for the name
extern objectclassesnamesprptr	// the spriteblockptr for this TextID
extern numobjectclasses			// how many classes we have have loaded already

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

uvard curobjectclass
exported setobjectclass
.nextdefine:
	push ecx
// first we define the class, if the class fails to load, we can't select the object anyway,
// so storeing and resolveing gameid isn't need either.
.loadclass:
	lodsd
	
	mov ecx,[numobjectclasses]
	mov edi,objectclasses
	test ecx, ecx
	jz .createnewclass
	repne scasd
	je .classalreadydefined
	
	cmp dword [numobjectclasses], NOBJECTSCLASSES
	jb .createnewclass 
	
.nomoreclasses:
	pop ecx
	mov al,GRM_EXTRA_OBJECTS
	jmp failpropwithgrfconflict
	
.createnewclass:
	// edi points to end of objectclasses
	mov dword [edi], eax
	inc dword [numobjectclasses]
	
.classalreadydefined:
	sub edi, objectclasses
	shr edi, 2
	mov [curobjectclass], edi
	
// creates a new gameid:
// in: ebx = action id,  edx = feature in framework
// out: 
// carry set = error, al = code why:  0 = already defined  1 = no more gameids free
// eax = gameid
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
	mov ecx, [curobjectclass]
	mov word [objectclass+eax*2], cx
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

// special functions to handle station properties
//
// in:	eax=special prop-num
//	ebx=offset (objectid)
//	ecx=num-info
//	esi=>data
// out:	esi=>after data
//	carry clear if successful
//	carry set if error, then ax=error message
exported setobjectclasstexid
.nextobjectclass:
	lodsw
	movzx edx, word [objectclass+ebx*2]
	mov word [objectclassesnames+edx*2], ax
	mov eax, [curspriteblock]
	mov dword [objectclassesnamesprptr+edx*4], eax
	inc ebx
	loop .nextobjectclass
	clc
	ret
.fail:
	mov ax, ourtext(invalidsprite)
	stc
	ret
	

// Select window
%assign win_objectgui_id 114

%assign win_objectgui_padding 10 

%assign win_objectgui_dropwidth 12 
%assign win_objectgui_dropheight 12
%assign win_objectgui_drop1y 20

%assign win_objectgui_previewheight 60

guiwindow win_objectgui,200,250
	guicaption cColorSchemeDarkGreen, ourtext(grfstatcaption)
	guiele background,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,-x2,0,y,14,-y2,0,data,0
	// Dropdown 1
	guiele dropdown1_text,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding+win_objectgui_dropwidth+1,y,win_objectgui_drop1y,h,win_objectgui_dropheight,data,0
	guiele dropdown1,cWinElemTextBox,cColorSchemeGrey,-x,win_objectgui_padding+win_objectgui_dropwidth,-x2,win_objectgui_padding,y,win_objectgui_drop1y,h,win_objectgui_dropheight,data,statictext(txtetoolbox_dropdown)
	// Preview
	guiele preview,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding,y,40,h,win_objectgui_previewheight,data,0
	// Dropdown 2
	guiele dropdown2_text,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding+win_objectgui_dropwidth+1,y,40+win_objectgui_previewheight+20,h,win_objectgui_dropheight,data,0
	guiele dropdown2,cWinElemTextBox,cColorSchemeGrey,-x,win_objectgui_padding+win_objectgui_dropwidth,-x2,win_objectgui_padding,y,40+win_objectgui_previewheight+20,h,win_objectgui_dropheight,data,statictext(txtetoolbox_dropdown)
endguiwindow

svarw win_objectgui_curclass
uvard win_objectgui_curobject

exported win_objectgui_create
	bts dword [esi+window.activebuttons], 26
	call [RefreshWindowArea]
	pusha
	mov cl, 0x2A
	mov dx, win_objectgui_id // window.id
	call dword [BringWindowToForeground]
	test esi,esi
	jz .noold
	mov byte [esi+window.data], 26
	or byte [esi+window.flags], 7
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
	mov byte [esi+window.data], 26
	or byte [esi+window.flags], 7
	popa
	ret

win_objectgui_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near win_objectgui_redraw
	cmp dl, cWinEventClick
	jz near win_objectgui_clickhandler
	cmp dl, cWinEventDropDownItemSelect
	jz near win_objectgui_dropdowncallback
	cmp dl, cWinEventTimer
	jz win_objectgui_timer
//	cmp dl, cWinEventSecTick
//	jz win_signalgui_sectick
	ret
win_objectgui_timer:
	mov dword [esi+window.activebuttons], 0
	
	cmp byte [esi+window.data], 0
	jne .toolbar

.ok:
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
//	or byte [esi+window.flags], 7
	ret
	
.toolbar:
	movzx eax, byte [esi+window.data]
	mov byte [esi+window.data], 0
	mov cl, 1
	xor dx, dx
	call [FindWindow]
	btr dword [esi+window.activebuttons], eax
	jmp [RefreshWindowArea]

	
win_objectgui_redraw:
	call dword [DrawWindowElements]	
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	
	cmp word [win_objectgui_curclass], -1
	je .noclassselected
	
	movzx ebx, word [win_objectgui_curclass]
	mov eax, dword [objectclassesnamesprptr+ebx*4]
	extern curmiscgrf
	mov [curmiscgrf], eax
	movzx eax, word [objectclassesnames+ebx*2]
	mov [textrefstack],eax
	mov bx,statictext(blacktext)
	add cx, win_objectgui_padding+2
	add dx, win_objectgui_drop1y+2
	call [drawtextfn]
.noclassselected:
	ret
	
win_objectgui_clickhandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
	cmp cl, win_objectgui_elements.caption_close_id
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cl, win_objectgui_elements.caption_id
	jne .nottilebar
	jmp dword [WindowTitleBarClicked]
.nottilebar:
	cmp cl, win_objectgui_elements.dropdown1_text_id
	je near win_objectgui_classdropdown.text
	cmp cl, win_objectgui_elements.dropdown1_id
	je near win_objectgui_classdropdown
	ret
	
	
win_objectgui_classdropdown.text:
	inc cl
win_objectgui_classdropdown:
	extcall GenerateDropDownExPrepare
	jnc .noolddrop
	ret
.noolddrop:
	push ecx
	xor eax,eax
	xor ebx,ebx
.loop:
	cmp al, MAXDROPDOWNEXENTRIES
	jae .done

	movzx ecx, word [objectclassesnames+eax*2]
	mov dword [DropDownExList+4*eax],ecx
	mov ecx, dword [objectclassesnamesprptr+eax*4]
	mov dword [DropDownExListGrfPtr+4*eax],ecx
	inc eax
	cmp al, MAXDROPDOWNEXENTRIES
	jae .done
	cmp al,[numobjectclasses]
	jb .loop
.done:
	mov dword [DropDownExList+4*eax],-1	// terminate it
	mov byte [DropDownExMaxItemsVisible], 16
	mov word [DropDownExFlags], 11b
	pop ecx
	extjmp GenerateDropDownEx
	
win_objectgui_dropdowncallback:
	cmp cl, win_objectgui_elements.dropdown1_id
	je .selectclass
	ret
.selectclass:
	mov word [win_objectgui_curclass],ax
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	ret
