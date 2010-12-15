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
#include <patchdata.inc>
#include <pusha.inc>
#include <player.inc>

extern failpropwithgrfconflict
extern curspriteblock
extern grfstage
extern RefreshWindowArea
extern player2array
extern numtwocolormaps

uvard objectsdataiddata,256*idf_dataid_data_size
uvard objectsdataidcount

global objectsdefandclassnames
uvard objectsdefandclassnames, 512

// idf data id management
extern idf_increaseusage
extern idf_decreaseusage
extern idf_getdataidbygameid

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
	at idfsystem.dataidcount,		dd NOBJECTS
	at idfsystem.gameidcount,		dd NOBJECTS
iend
endvar

// Properties for objects (gameid based)
extern objectclass				// a word id to the actuall objectclasses
extern objectnames				// a TextID
extern objectspriteblock			// to get GRF specific TextIDs
extern objectavailability
extern objectsizes
extern objectcostfactors
extern objectstartdates
extern objectenddates
extern objectflags
extern objectanimframes
extern objectanimspeeds
extern objectanimtriggers
extern objectremovalcostfactors
extern objectcallbackflags
extern objectheights
extern objectviews

// Properties for classes of objects
extern objectclasses			// the actual defined classes
extern objectclassesnames		// the TextID for the name
extern objectclassesnamesprptr		// the spriteblockptr for this TextID
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

	jmp .nocorrection
	
.classalreadydefined:
	sub edi, 4 // Points to the entry after

.nocorrection:
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
	
	mov ecx, dword [curspriteblock]
	mov dword [objectspriteblock+eax*4],ecx

.endofthisdefine:
// Now we default all of the poperties for it
// Required properties (leaving these unset voids the object)
	mov word [objectnames+eax*2], 0
	mov byte [objectsizes+eax], 0
	mov byte [objectavailability+eax], 0

// Optional properties
	mov byte [objectcostfactors+eax], 2
	mov dword [objectstartdates+eax*4], 0
	mov dword [objectenddates+eax*4], 0
	mov word [objectflags+eax*2], 0
	mov word [objectanimframes+eax*2], -1
	mov byte [objectanimspeeds+eax], 0
	mov word [objectanimtriggers+eax*2], 0
	mov byte [objectremovalcostfactors+eax], 2
	mov word [objectcallbackflags+eax*2], 0
	mov byte [objectheights+eax], -1
	mov byte [objectviews+eax], 1

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
	mov ecx,NOBJECTS*idf_dataid_data_size/4
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
	cmp ah, 0xD0
	jb .nofix
	cmp ah, 0xD3
	ja .nofix
	add ah, 0x04
.nofix:
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

// Based off the specs, I believe it is meant to work more or less this way
exported setobjectbuyfactor
	lodsb
	mov byte [objectcostfactors+ebx], al
	mov byte [objectremovalcostfactors+ebx], al
	clc
	ret

// We recieve a number of 'views', either 1, 2 or 4.
exported setobjectviews
	lodsb

	btr ax, 0 // 3->2, 1->0, etc
	cmp al, 4 // Truncate to 4
	jbe .under
	mov al, 4

.under:
	test al, al // 0->1
	jnz .above
	mov al, 1

.above:
	mov byte [objectviews+ebx], al
	clc
	ret

// Select window
%assign win_objectgui_padding 10 

%assign win_objectgui_dropwidth 12 
%assign win_objectgui_dropheight 12
%assign win_objectgui_drop1y 20

%assign win_objectgui_previewheight 72

guiwindow win_objectgui,200,195
	guicaption cColorSchemeDarkGreen, ourtext(objectgui_title)
	guiele background,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,-x2,0,y,14,-y2,0,data,0
	// Dropdown 1
	guiele dropdown1_text,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding+win_objectgui_dropwidth+1,y,win_objectgui_drop1y,h,win_objectgui_dropheight,data,0
	guiele dropdown1,cWinElemTextBox,cColorSchemeGrey,-x,win_objectgui_padding+win_objectgui_dropwidth,-x2,win_objectgui_padding,y,win_objectgui_drop1y,h,win_objectgui_dropheight,data,statictext(txtetoolbox_dropdown)
	// Preview
	guiele preview,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding,y,40,h,win_objectgui_previewheight,data,0
	// Dropdown 2
	guiele dropdown2_text,cWinElemSpriteBox,cColorSchemeGrey,x,win_objectgui_padding,-x2,win_objectgui_padding+win_objectgui_dropwidth+1,y,40+win_objectgui_previewheight+8,h,win_objectgui_dropheight,data,0
	guiele dropdown2,cWinElemTextBox,cColorSchemeGrey,-x,win_objectgui_padding+win_objectgui_dropwidth,-x2,win_objectgui_padding,y,40+win_objectgui_previewheight+8,h,win_objectgui_dropheight,data,statictext(txtetoolbox_dropdown)
	// Build button
	guiele buildbtn, cWinElemTextBox, cColorSchemeGrey, x, win_objectgui_padding, -x2, win_objectgui_padding, -y, win_objectgui_padding+win_objectgui_dropheight, h, win_objectgui_dropheight, data, ourtext(objectbuild)
endguiwindow

svarw win_objectgui_curclass
svard win_objectgui_curobject
uvarb win_objectgui_curobject_view
uvarw cur_object_tile

exported win_objectgui_create
	bts dword [esi+window.activebuttons], ebx
	call [RefreshWindowArea]
	pusha
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowObjectGUI // window.id
	push ebx
	call dword [BringWindowToForeground]
	pop ebx
	test esi,esi
	jz .noold
	mov byte [esi+window.data], bl
	or byte [esi+window.flags], 7
	popa
	ret

.noold:
	push ebx
	mov eax, 100 + (100<<16) // x + (y << 16)
	mov ebx, win_objectgui_width + (win_objectgui_height << 16)
	mov cx, cWinTypeTTDPatchWindow		// window type
	mov dx, -1				// -1 = direct handler
	mov ebp, addr(win_objectgui_winhandler)
	call dword [CreateWindow]
	pop ebx
	mov dword [esi+window.elemlistptr], addr(win_objectgui_elements)
	mov word [esi+window.id], cPatchWindowObjectGUI // window.id
	mov byte [esi+window.data], bl
	or byte [esi+window.flags], 7
	call doesclasshaveusableobjects
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
	jz near win_objectgui_timer

	cmp dl, cWinEventMouseToolClick
	je near win_objectgui_mousetoolcallback
	cmp dl, cWinEventMouseToolClose
	je near win_objectgui_setmousetool.noobject

	cmp dl, cWinEventGRFChanges
	je near win_objectgui_grfchanges
	ret
	
win_objectgui_grfchanges:
	pusha
	mov word [win_objectgui_curobject], -1
	mov word [win_objectgui_curclass], -1
	
	// To prevent possible crashes, if we have any active drop downs, we close them
	bt dword [esi+window.activebuttons], win_objectgui_elements.dropdown1_id
	jnc .nodrop1
	mov ecx, win_objectgui_elements.dropdown1_id
	extcall GenerateDropDownExPrepare
	jmp .nodrop2

.nodrop1:
	bt dword [esi+window.activebuttons], win_objectgui_elements.dropdown2_id
	jnc .nodrop2
	mov ecx, win_objectgui_elements.dropdown2_id
	extcall GenerateDropDownExPrepare

.nodrop2:
	call doesclasshaveusableobjects
	popa
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
	push esi
	call dword [DrawWindowElements]	
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]

	push ecx
	push edx
	cmp word [win_objectgui_curclass], -1
	je .noclassselected

	movzx ebx, word [win_objectgui_curclass]
	mov eax, dword [objectclassesnamesprptr+ebx*4]
extern curmiscgrf
	mov [curmiscgrf], eax
	movzx eax, word [objectclassesnames+ebx*2]
	
	mov [textrefstack],eax
	mov bx,statictext(blacktext)
	add cx, win_objectgui_elements.dropdown1_text_x+2
	add dx, win_objectgui_elements.dropdown1_text_y+1
	call [drawtextfn]

.noclassselected:
	pop edx
	pop ecx

	cmp word [win_objectgui_curobject], -1
	je .noobjectselected

	movzx ebx, word [win_objectgui_curobject]
	mov eax, dword [objectspriteblock+ebx*4]
	mov [curmiscgrf], eax
	movzx eax, word [objectnames+ebx*2]

	cmp ah, 0xD0
	jb .nofix
	cmp ah, 0xD3
	ja .nofix
	add ax, 0x400

.nofix:
	mov [textrefstack],eax
	mov bx,statictext(blacktext)
	add cx, win_objectgui_elements.dropdown2_text_x+2
	add dx, win_objectgui_elements.dropdown2_text_y+1
	call [drawtextfn]

	call drawobjectproperties
	call drawobjectpreviewsprite

.noobjectselected:
	pop esi
	ret

// Draws the objects specifications
drawobjectproperties:
	push ecx
	push edx
	mov esi, [esp+0xC]
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, win_objectgui_padding+1
	add dx, win_objectgui_elements.dropdown2_text_y+win_objectgui_dropheight+8

	cmp byte [gamemode], 2
	je .showsize

	push edx
	push eax
	movzx ebx, word [win_objectgui_curobject]
	push ebx
	push dword [win_objectgui_curobject_view]
	call GetObjectSize
	movzx eax, dl
	mul dh
	mov dx, ax
	mov eax, ebx
	and dword [ObjectCost], 0
	call BuildObjectCost
	mov dword [textrefstack], ebx
	pop eax
	pop edx

	push ecx
	push edx
	mov bx, ourtext(objectgui_cost)
	call [drawtextfn]
	pop edx
	pop ecx
	add dx, 11

.showsize:
	push edx
	push dword [win_objectgui_curobject]
	push dword [win_objectgui_curobject_view]
	call GetObjectSize
	mov word [textrefstack], dx
	pop edx

	mov bx, ourtext(objectgui_size)
	call [drawtextfn]
	pop edx
	pop ecx
	ret

// Draws the objects preview sprite onto the window
// - Updated to create a drawing buffer to prevent overlap
// - Now also uses a compatible full tile drawing routine
drawobjectpreviewsprite:
	call .createbuffer
	jz .invalid

	pusha
	movzx eax, word [win_objectgui_curobject]
	mov esi, 0
	mov byte [grffeature], 0xF
	call getnewsprite
	push eax	 // Data Pointer
	push ebx	 // Sprite Availability
	push dword 3 // Construction stage (always fully built for objects)

	mov esi, [esp+0x30] // Restore window handle
	call .getcolours

	mov edi, baTempBuffer1
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, win_objectgui_elements.preview_x+89
	add dx, win_objectgui_elements.preview_y+33

	push ebx
	push dword 0xF
	call DrawObjectTileSelWindow
	popa

.invalid:
	ret

// Out:	z flag, clear if failed
.createbuffer:
	pusha
	mov edi, baTempBuffer1
	mov esi, [esp+0x28] // Restore window handle
	mov byte [edi], 0

	//	DX,BX = X,Y CX,BP = width,height
	mov dx, [esi+window.x]
	mov bx, [esi+window.y]
	add dx, win_objectgui_elements.preview_x+1	// So it doesn't clip the edges
	add bx, win_objectgui_elements.preview_y+1
	mov cx, win_objectgui_elements.preview_width-2
	mov bp, win_objectgui_elements.preview_height-2

extern MakeTempScrnBlockDesc
	call [MakeTempScrnBlockDesc]
	popa
	ret

// In:	esi = Window handle
// Out:	esi = Window handle
//	 bx = Recolour mapping
.getcolours:
	mov edx, 0x10	// Get the recolour to defaultly apply
	cmp byte [gamemode], 2
	je .noowner
	movzx edx, byte [human1]

.noowner:
	push edx // Owner of the window
	push dword 0 // No tile index
	push dword [win_objectgui_curobject] // Current selected object id
	call GetObjectColourMap
	ret

#if 0	// Orginial method of previewing the object
	pusha
	mov esi, [esp+0x24]
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, win_objectgui_elements.preview_x+89 // 59
	add dx, win_objectgui_elements.preview_y+33 // 36

	movzx eax, word [win_objectgui_curobject]
	push esi
	xor esi, esi
	mov byte [grffeature], 0xF
	call getnewsprite
	pop esi
	jc .nosprite

	inc eax
	call getobjectpreviewsprite
	call [drawspritefn]

.nosprite:
	popa
	ret

// In:	eax = pointer to the action2 data
//	ebx = sprites available
// Out:	ebx = sprite with recolour map
getobjectpreviewsprite:
	mov ebx, dword [eax]
	btr ebx, 31
	jnc .notgrfsprite

extern exscurfeature, exsspritelistext, randomfn
	mov byte [exscurfeature], 0xF
	mov byte [exsspritelistext], 1

.notgrfsprite:
	btr ebx, 30
	test bx, bx
	jns .norecolour
	call recolourobjectsprite

.norecolour:
	ret

// In:	esi = window pointer
// Out:	ebx = sprite plus recolour 
recolourobjectsprite:
	push edx
	push ebx

	mov edx, 0x10
	cmp byte [gamemode], 2
	je .noowner
	movzx edx, byte [human1]

.noowner:
	push edx // Owner of the window
	push dword 0 // No tile index
	push dword [win_objectgui_curobject] // Current selected object id

	call GetObjectColourMap
	shl ebx, 16
	mov bx, [esp]
	pop edx // We don't want to change ebx back
	pop edx
	ret
#endif

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
	
	cmp cl, win_objectgui_elements.dropdown2_text_id
	je near win_objectgui_objectdropdown.text
	cmp cl, win_objectgui_elements.dropdown2_id
	je near win_objectgui_objectdropdown

	cmp cl, win_objectgui_elements.buildbtn_id
	je near win_objectgui_objectbuild

	ret


win_objectgui_classdropdown.text:
	inc cl

win_objectgui_classdropdown:
	movzx ecx, cl
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
	cmp al,[numobjectclasses]
	jae .done

	movzx ecx, word [objectclassesnames+eax*2]
	mov dword [DropDownExList+4*eax],ecx
	mov ecx, dword [objectclassesnamesprptr+eax*4]
	mov dword [DropDownExListGrfPtr+4*eax],ecx
	inc eax
	jmp .loop
	
.done:
	mov dword [DropDownExList+4*eax],-1	// terminate it
	mov byte [DropDownExMaxItemsVisible], 12
	mov word [DropDownExFlags], 1b
	
	movzx edx, word [win_objectgui_curclass]
	
	pop ecx
	extjmp GenerateDropDownEx

// Used to cache the list generated by the drop down
// (reduces issues with objects changing availability whilst open)
uvarw objectddgameidlist, MAXDROPDOWNEXENTRIES

// Notes: ids' are always >0 due to the way idf works
win_objectgui_objectdropdown.text:
	inc cl

win_objectgui_objectdropdown:
	movzx ecx, cl
	push ecx
	bt dword [esi+window.disabledbuttons], ecx
	pop ecx
	jc .ret

	extcall GenerateDropDownExPrepare
	jnc .noolddrop

.ret:
	ret

.noolddrop:
	push ecx
	push ebx
	push edx

	xor eax, eax
	xor ebx, ebx
	xor edx, edx

	// Generate our list?
	mov bx, [win_objectgui_curclass]
	mov dword [esp], -1

.loop:
	inc edx
	cmp al, MAXDROPDOWNEXENTRIES
	jae .done
	cmp edx, [objectsgameidcount]
	ja .done // First ids are always +1 against the actual count

	push edx
	push ebx
	call validobject
	jc .loop

// Works out the selected item's index [-1 if never added to list] (Lakie)
	cmp dx, word [win_objectgui_curobject]
	jne .notcur
	mov dword [esp], eax

.notcur:
	mov cx, word [objectnames+edx*2]
	cmp ch, 0xD0
	jb .nofix
	cmp ch, 0xD3
	ja .nofix
	add cx, 0x400

.nofix:
	mov dword [DropDownExList+4*eax], ecx
	mov ecx, dword [objectspriteblock+edx*4]
	mov dword [DropDownExListGrfPtr+eax*4], ecx
	mov word [objectddgameidlist+eax*2], dx
	inc eax
	jmp .loop

.done:
	mov dword [DropDownExList+4*eax],-1	// terminate it
	mov byte [DropDownExMaxItemsVisible], 12
	mov word [DropDownExFlags], 11b

	test byte [expswitches],EXP_PREVIEWDD
	jz .nopreview

	// Used for the setting up previewdd
	mov word [DropDownExListItemExtraWidth], 38
	mov word [DropDownExListItemHeight], 23
	mov byte [DropDownExMaxItemsVisible], 7
	mov dword [DropDownExListItemDrawCallback], DrawObjectDDPreview //makestationseldropdown_callback

.nopreview:
	pop edx
	pop ebx
	pop ecx
	extjmp GenerateDropDownEx

win_objectgui_dropdowncallback:
	cmp cl, win_objectgui_elements.dropdown1_id
	je .selectclass
	cmp cl, win_objectgui_elements.dropdown2_id
	je .selectobject
	ret

.selectclass:
	cmp word [win_objectgui_curclass], ax
	je .noclasschange

	mov word [win_objectgui_curclass], ax
	mov word [win_objectgui_curobject], -1
	call doesclasshaveusableobjects

.noclasschange:
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	jmp win_objectgui_setmousetool.noobject

.selectobject:
	push ebx
	mov bx, word [objectddgameidlist+eax*2]
	mov word [win_objectgui_curobject], bx
	pop ebx
	jmp .noclasschange

win_objectgui_objectbuild:
	bt dword [esi+window.disabledbuttons], win_objectgui_elements.buildbtn_id
	jc .disabled

	bt dword [esi+window.activebuttons], win_objectgui_elements.buildbtn_id
	jc win_objectgui_setmousetool.noobject
	jmp win_objectgui_setmousetool

.disabled:
	ret

// Functions which control the mouse tool
win_objectgui_setmousetool:
	cmp word [win_objectgui_curobject], byte -1
	je .noobject

	push esi
	mov dx, [esi+window.id]
	mov ah, cWinTypeTTDPatchWindow
	mov al, 0x1
	mov ebx, 0xFF9

extern setmousetool
	call [setmousetool]
	pop esi
	
//.active:
	cmp word [win_objectgui_curobject], byte -1
	je .noobject
	
	push dword [win_objectgui_curobject]
	push dword [win_objectgui_curobject_view]
	call GetObjectSize

	shl dx, 4
	movzx ax, dl
	movzx dx, dh

	mov word [highlightareainnerxsize], ax
	mov word [highlightareainnerysize], dx
	mov word [highlightareaouterxsize], ax
	mov word [highlightareaouterysize], dx

	bts dword [esi+window.activebuttons], win_objectgui_elements.buildbtn_id 
	call dword [RefreshWindowArea] // Refresh the screen
	ret

// Reset the mouse tool
.noobject:
	push esi
	mov ebx, 0
	mov al, 0
	call [setmousetool]
	pop esi

	btr dword [esi+window.activebuttons], win_objectgui_elements.buildbtn_id
	call dword [RefreshWindowArea] // Refresh the screen
	ret

win_objectgui_mousetoolcallback:
	cmp byte [curmousetoolwintype], cWinTypeTTDPatchWindow // Is this depot clone vehicle active?
	jne .notactive

	// Nothing selected then we do not attempt building
	cmp word [win_objectgui_curobject], -1
	je .notactive

	movzx edx, byte [win_objectgui_curobject_view]
	shl edx, 16
	mov dx, word [win_objectgui_curobject]

	movzx edi, word [mousetoolclicklocxy]
	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4

	mov bl, 0xB
	mov word [operrormsg1], ourtext(objecterr)
	push esi
extern BuildObject_actionnum
	dopatchaction BuildObject
	pop esi

	cmp ebx, 1<<31
	je .notactive

	push esi
	mov bx, ax
	mov eax, 0x1D
	mov esi, -1
extern generatesoundeffect
	call [generatesoundeffect]
	pop esi
	call win_objectgui_setmousetool.noobject

.notactive:
	ret

// Called to workout if we have any extries for current class
// (sets the current object to the first found one if it does)
doesclasshaveusableobjects:
	push ecx
	push ebx
	call win_objectgui_setmousetool.noobject

// Check that we do have atleast one class loaded, to prevent gibberish (Lakie)
	cmp byte [numobjectclasses], 0
	je .noclasses

// We always try to select the first class (eis_os)
//	cmp word [win_objectgui_curclass], -1	
//	je .no

	cmp word [win_objectgui_curclass], -1	
	jne .validclass
//	cmp byte [numobjectclasses], 0
//	jbe .validclass
	mov word [win_objectgui_curclass], 0
	
.validclass:
	mov bx, [win_objectgui_curclass]

// We should probably check if this current object is still valid first (Lakie)
// (Because the gui may be openned later when the object is no-longer valid)
	cmp word [win_objectgui_curobject], -1
	je .noobject

	mov cx, [win_objectgui_curobject]
	push ecx
	push ebx
	call validobject
	jnc .skip

.noobject:
	push eax
	xor ecx, ecx
	xor eax, eax

.loop:
	inc ecx
	cmp ecx, [objectsgameidcount]
	ja .done

	push ecx
	push ebx
	call validobject
	jc .loop

	inc al

.done:
	cmp al, 0
	pop eax
	je .no

	mov word [win_objectgui_curobject], cx

.skip:
	pop ebx
	pop ecx
	btr dword [esi+window.disabledbuttons], win_objectgui_elements.dropdown2_id
	btr dword [esi+window.disabledbuttons], win_objectgui_elements.buildbtn_id
	ret

.noclasses:
	mov word [win_objectgui_curclass], -1
	
.no:
	pop ebx
	pop ecx
	mov word [win_objectgui_curobject], -1
	bts dword [esi+window.disabledbuttons], win_objectgui_elements.dropdown2_id
	bts dword [esi+window.disabledbuttons], win_objectgui_elements.buildbtn_id
	ret
#if 0
// We can use cWinEventGRFChanges for this (eis_os)
.external:
	push ecx // called upon newgrf change to update the window
	push edx
	push esi
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowObjectGUI
	call [FindWindow]
	jz .notopen
	call doesclasshaveusableobjects

.notopen:
	pop esi
	pop edx
	pop ecx
	ret
#endif

// ************************************ Object Pool Functions *************************************

global objectpoolclear
objectpoolclear:
	pusha
	mov edi, objectpool		// first, fill it with zeroes
	xor eax, eax
	mov ecx, NACTIVEOBJECTS*(object_size/4)
	rep stosd
	popa
	ret

global objectpoolmigrate
objectpoolmigrate:
	push esi
	push edi
	push eax
	mov esi, NACTIVEOBJECTS*oldobject_size
	mov edi, NACTIVEOBJECTS*object_size

// Always going to do atleast one iteration
.loop:
	cmp word [objectpool+esi+object.origin], 0
	je .skip

	// We have a record, move the data as needed
	mov ax, word [objectpool+esi+oldobject.origin] // Origin move 0x0 -> 0x0
	mov word [objectpool+edi+object.origin], ax
	mov ax, word [objectpool+esi+oldobject.dataid] // Dataid move 0x2 -> 0x4
	mov word [objectpool+edi+object.dataid], ax
	mov al, byte [objectpool+esi+oldobject.colour] // Colours move 0x2 -> 0x4
	mov byte [objectpool+edi+object.colour], al

	// Calculate the date
	movzx eax, word [objectpool+esi+oldobject.buildyear]
	imul eax, (365*4)+1	// multiply by 4 years (one being a leap year)
	shr eax, 2			// Divide by 4
	mov dword [objectpool+edi+object.builddate], eax

	// Finally get the townptr
	pusha
	mov ax, word [objectpool+edi+object.origin]
	call findnearesttown
	mov dword [esp+_pusha.eax], edi
	popa
	mov dword [objectpool+edi+object.townptr], eax

.skip:
	sub esi, oldobject_size
	sub edi, object_size
	jnz .loop
	
	pop eax
	pop edi
	pop esi
	ret

// ********************************** Externs for the code below **********************************

extern CheckForVehiclesInTheWay
extern actionhandler
extern gettileinfo
extern miscgrfvar
extern callback_extrainfo
extern curcallback
extern grffeature
extern getnewsprite
extern randomfn
extern processtileaction2
extern addgroundsprite
extern addsprite
extern objectpool_ptr
extern displayfoundation

extern redrawtile
extern curplayerctrlkey
extern invalidatetile
extern getyear4fromdate
extern reduceyeartoword
extern deftwocolormaps
extern findnearesttown

// *************************************** Helper functions ***************************************

// Validates if a object is 'available' for use
// Out:	carry = set if not valid for usage
global validobject
proc validobject
	arg gameid, classid
	_enter

	push eax
	push ebx
	push ecx
	movzx ecx, word [%$classid]
	movzx ebx, word [%$gameid]

	cmp cx, byte -1
	je .noclass

	cmp word [objectclass+ebx*2], cx
	jne near .fail

.noclass:
	cmp word [objectnames+ebx*2], 0
	je near .fail

	cmp byte [objectsizes+ebx], 0x11
	jb near .fail

	mov word [operrormsg2], ourtext(objecterr_noaction3)
	cmp dword [objectsgameiddata+ebx*idf_gameid_data_size+idf_gameid_data.act3info], 0
	je near .fail

	mov word [operrormsg2], ourtext(objecterr_wrongclimate)
	movzx ax, byte [climate]
	bt word [objectavailability+ebx], ax
	jnc near .fail

	mov word [operrormsg2], ourtext(objecterr_wronggamemode)
	test word [objectflags+ebx*2], OF_SCENERIOEDITOR
	jz .notScenerioOnly
	cmp byte [gamemode], 2
	jne near .fail

.notScenerioOnly:
	test word [objectflags+ebx*2], OF_NEEDSOWNER
	jz .notGameplayOnly
	cmp byte [gamemode], 1
	jne .fail

.notGameplayOnly:
	movzx eax, word [currentdate]
	add eax, 701265
	add eax,[landscape3+ttdpatchdata.daysadd]

	mov ecx, dword [objectstartdates+ebx*4]
	cmp ecx, 701265
	jbe .skipstart // jump if carry or zero
	
	mov word [operrormsg2], ourtext(objecterr_tooearly)
	cmp eax, ecx
	jb .writeyear

.skipstart:
	add ecx, 365 // Add roughly a year
	cmp dword [objectenddates+ebx*4], ecx
	jbe .skipend

	mov ecx, dword [objectenddates+ebx*4]
	cmp ecx, 701265
	jbe .skipend

	mov word [operrormsg2], ourtext(objecterr_toolate)
	cmp eax, ecx
	ja .writeyear

.skipend:
	pop ecx
	pop ebx
	pop eax
	clc
	_ret

.writeyear:
	xchg eax, ecx
	call GetObjectYear
	mov dword [textrefstack+0], eax

.fail:
	pop ecx
	pop ebx
	pop eax
	stc
	_ret
endproc

// In:	eax = days since year 0
// Out:	eax = year from year 0
GetObjectYear:
	push edx
	call getyear4fromdate

	// Calculate the ~3 years part
	sub edx, 366 // First year is always a leppia year
	jc .done
	inc eax

	sub edx, 365 // Second year
	jc .done
	inc eax

	sub edx, 365 // Third year (last one)
	jc .done
	inc eax

.done:
	pop edx
	ret

// Out:	carry = error because of bad game id
//	edx = tiles to loop
proc GetObjectSize
	arg gameid
	arg view

	_enter
	mov word [operrormsg2], ourtext(objecterr_invalidsize)
	movzx edx, word [%$gameid]
	test edx, edx
	je .default

	movzx dx, byte [objectsizes+edx] // Get the object size and store
	shl dx, 4
	shr dl, 4
	and dx, 0xF0F
	jz .default

	test byte [%$view], 1
	jz .done
	rol dx, 8 // swap the x,y sizes

.done:
	clc
	_ret

.default:
	mov dx, 0xF0F
	stc
	_ret
endproc

// In:	edx = number of tiles X and Y to loop
//	bh = object owner
//	edi = origin tile
// Out:	carry = set on error
//	edx = tile count
proc LoopTiles
	arg checkfn, actualfn, id, poolid
	slocal tilecount

	_enter
	push ecx
	push edx
	push edi
	and dword [%$tilecount], 0
	xor ecx, ecx

.nexty:
	and cl, 0xF0
	push edx
	push edi

.nextx:
	push eax
	push edx
	movzx eax, word [%$id]
	movzx edx, word [%$poolid]

	call [%$checkfn]
	jc .skipTile

	call [%$actualfn]
	jc .failpop
	inc byte [%$tilecount]

.skipTile:
	pop edx
	pop eax

	lea edi, [edi+1]
	inc cl
	dec dl
	jnz .nextx

	pop edi
	pop edx
	lea edi, [edi+256]
	add cl, 0x10
	dec dh
	jnz .nexty

	pop edi
	pop edx
	pop ecx
	mov edx, [%$tilecount]
	clc
	_ret

.failpop:
	pop edx // Inner
	pop eax
	pop edi // Y
	pop edx
	pop edi // X
	pop edx
	pop ecx
	mov edx, 0
	stc
	_ret
endproc

// In:	edi = tile
RedrawObjectTile:
	pusha
	mov esi, edi
	call redrawtile
	popa
	clc
	ret

// In:	eax = game id
//	ecx = pool id
//	edi = object origin
SetObjectPoolEntry:
	cmp edi, 0
	je .noOrigin

	push eax
	push ecx
	push ebx
	imul ecx, object_size
	mov word [objectpool+ecx+object.origin], di

	push eax // Get and store the date since year 0
	movzx eax, word [currentdate]
	add eax, 701265
	add eax, [landscape3+ttdpatchdata.daysadd]
// We now store the build date itself (Lakie)
//	call GetObjectYear
//	call reduceyeartoword
//	mov word [objectpool+ecx+object.buildyear], ax
	mov dword [objectpool+ecx+object.builddate], eax
	pop eax

// We no longer cache object flags in the pool (Lakie)
//	mov bx, word [objectflags+eax*2]
//	mov word [objectpool+ecx+object.flags], bx
	mov bx, [objectsgameiddata+eax*idf_gameid_data_size+idf_gameid_data.dataid]
	mov word [objectpool+ecx+object.dataid], bx

// We now store a 'nearest' town
	pusha
	mov ax, di
	call findnearesttown
	mov dword [esp+_pusha.ebx], edi
	popa

	mov dword [objectpool+ecx+object.townptr], ebx
	pop ebx

	cmp byte [gamemode], 2
	jne .companyowned
	mov bh, 0x10

.companyowned:
	call SetObjectBuildColour

// Store the object view being built
	mov al, [ObjectView]
	mov byte [objectpool+ecx+object.view], al

	pop ecx
	pop eax
	ret

.noOrigin:
	pusha
	mov edi, objectpool		// Set the entry to be wiped
	imul ecx, object_size
	add edi, ecx

	xor eax, eax
	mov ecx, (object_size / 4)	// Wipe one entry (always aligned to dwords)
	rep stosd
	popa
	ret

// In:	edi = tile
//	edx = pool id
//	bh = object owner
// Out:	carry = set if not an object tile
IsObjectTile:
	push ebx
	mov bl, byte [landscape4(di, 1)]
	and bl, 0xF0
	cmp bl, 0xA0
	pop ebx
	jne .isNotObjectTile

	cmp byte [landscape5(di, 1)], NOBJECTTYPE
	jne .isNotObjectTile	// Right class wrong type...

	cmp byte [landscape1+edi], bh
	jne .isNotObjectTile	// Atleast not one we own...

	cmp dx, [landscape3+edi*2]
	jne .isNotObjectTile	// It is an object tile but it
				// doesn't belong to this object...

	clc
	ret

.isNotObjectTile:
	stc
	ret

// Out: bx as the recolour map
proc GetObjectColourMap
	arg owner, tile, gameid

	_enter
	push eax
	push ecx
	push edx

	cmp dword [%$tile], 0
	je near .gui
	
	movzx edx, word [%$tile]
	movzx edx, word [landscape3+edx*2]
	imul edx, object_size
	mov dword [%$tile], edx

	movzx edx, word [%$gameid]
	test dx, dx
	jz .normal

	// We have a special case where having cb15b set means cached colour
	test word [objectcallbackflags+edx*2], OC_BUILDCOLOUR
	jnz .cached

.normal:
	cmp byte [%$owner], 0x10
	jb .owned

.cached:
	mov eax, dword [%$tile]
	movzx ax, byte [objectpool+eax+object.colour]
	mov cx, ax
	and ax, 0x0F
	and cx, 0xF0
	jmp .hascolours

.owned:
	movzx eax, byte [%$owner]
	call GetOwnerColours

.hascolours:
	test edx, edx // No game id, so only 1cc is possible
	jz .onecc

	cmp byte dword [numtwocolormaps+1], 1 // No 2cc maps loaded so we can only do 1cc
	jb .onecc

	test word [objectflags+edx*2], OF_TWOCC
	jnz .twocc

.onecc:
	mov bx, ax
	add bx, 775
	pop edx
	pop ecx
	pop eax
	_ret

.twocc:
	mov bx, ax
	or bx, cx
	add bx, [deftwocolormaps]
	pop edx
	pop ecx
	pop eax
	_ret

.gui:
	movzx edx, word [%$gameid]
	mov eax, 0x00 // Dark Blue
	mov ecx, 0x10 // Pale Green

	cmp byte [gamemode], 2
	je .guichecks

	movzx eax, byte [%$owner]
	call GetOwnerColours

.guichecks:
	cmp byte [numtwocolormaps+1], 1 // No 2cc maps loaded so we can only do 1cc
	jb .onecc

	test word [objectflags+edx*2], OF_TWOCC // We only have the grf raw data of flags for the gui
	jnz .twocc
	jmp .onecc
endproc

// In:	eax - owner
// Out:	al - first colour [lower nibble]
//		cl - second colour [upper bibble] (same as first if no second colour defined) 
GetOwnerColours:
	push edx
	mov ecx, eax
	mov edx, eax

	imul edx, player2_size
	add edx, dword [player2array]
	movzx eax, byte [companycolors+eax]
	movzx ecx, byte [edx+player2.col2]

	bt dword [edx+player2.colschemes], 0 // Have standard second colour?
	jc .hascolour
	mov ecx, eax

.hascolour:
	shl ecx, 4
	pop edx
	ret

// **************************************** Object Creation ***************************************

uvard ObjectCost
uvard ObjectLayout
uvarb ObjectWater
uvarb ObjectCurHeight
uvarb ObjectView

// Create Object function
// Input:	edi - tile index (word)
//		edx - object data id (word,  0..15)
//		    - object view    (byte, 16..23)
// Output:	ebx - 0x80000000 if fail, cost if sucessful
exported BuildObject
	push eax
	push ecx
	push edx
	mov byte [currentexpensetype], expenses_construction
	and dword [ObjectCost], 0

	movzx eax, dx			// Move our game id to a more perminant home
	rol edx, 16
	mov byte [ObjectView], dl

	mov word [operrormsg2], ourtext(cheatinvalidparm)
	or eax, eax
	jz near .fail
	cmp eax, [objectsgameidcount]
	ja near .fail

	push eax
	push dword -1
	call validobject
	jc near .fail

	call GetObjectLayout		// Result is in ObjectLayout
	call GetObjectPoolEntry		// Can we create an instance of an object?
	jc near .fail

	// Store the height of the initial tile (Lakie)
	pusha
	mov esi, edi
	call [gettileinfoshort]
	shr dl, 3	// Height is in multiples of 8
	test di, di
	jz .flat
	bt di, 4
	adc dl, 1

.flat:
	mov byte [ObjectCurHeight], dl
	popa

	push eax
	push dword [ObjectView]
	call GetObjectSize
	jc .fail

	push edx
	push dword CheckObjectLayout	// Functions and values for check tile
	push dword CheckObjectTile
	push eax
	push ecx
	call LoopTiles
	jc .failpop

	test bl, 1
	jz .check

	pop edx
	mov bh, [curplayer]
	push dword CheckObjectLayout	// Functions and values for create tile
	push dword CreateObjectTile
	push eax
	push ecx
	call LoopTiles
	call SetObjectPoolEntry

	mov dword [ObjectLayout], -1 // Return and clear the selected layout
	mov byte [ObjectView], 0

	push ebx
	mov ebx, edi
	mov edx, OA_CONSTRUCTION
	call ObjectAnimTrigger
	pop ebx
	pop edx
	pop ecx
	pop eax
	ret

.failpop:
	pop edx

.fail:
	mov dword [ObjectLayout], -1 // Return error and clear the selected layout
	mov ebx, 1<<31
	pop edx
	pop ecx
	pop eax
	ret

.check:
	call BuildObjectCost
	pop edx
	pop edx
	pop ecx
	pop eax
	ret

// In:	eax = game id
//	edx = tile count
// Out:	ebx = cost
BuildObjectCost:
	push eax
	push edx
	mov ebx, 2 // Our base factor
	test ax, ax
	jz .nogrf
	movzx ebx, byte [objectcostfactors+eax] // Get the grf factor

.nogrf:
	// multiple it by the number of tiles
	imul ebx, edx

	// multiple it the base factor
	mov edx, dword [costs+0x8A]
	imul ebx, edx

	add ebx, dword [ObjectCost] // Add the cost of clearing the tiles below
	pop edx
	pop eax
	ret

// In:	eax = game id
GetObjectLayout:
	push esi		// Currently no layout structure exists so this is a place holder
	mov dword [ObjectLayout], -1
	pop esi
	ret

// Out:	carry = set if cannot find entry
//	ecx = pool id
GetObjectPoolEntry:
	push eax
	mov word [operrormsg2], ourtext(objecterr_poolfull)
	xor eax, eax
	xor ecx, ecx
	
.next:
	cmp word [objectpool+eax+object.origin], 0
	je .done
	add eax, object_size
	inc ecx
	cmp ecx, NACTIVEOBJECTS
	jb .next

	pop eax
	stc
	ret

.done:
	pop eax
	clc
	ret
	
// In:	edi = tile
// Out:	carry = set if not an object tile
CheckObjectLayout:
	clc			// Currently no layout structure exists so this is a place holder
	ret

// In:	edi = tile
//	eax = game id
//	cl = tile offset
// Out:	carry = set if not an object tile
CheckObjectTile:
	push ecx
	push eax
	call [CheckForVehiclesInTheWay]
	jnz near .fail

	rol di, 4		// Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4

//	pusha
//	call [gettileinfo]
//	mov dword [miscgrfvar], edi
//	popa

	push ecx
	push eax
	mov word [cur_object_tile], di
	mov eax, [esp+0x8]
	mov ecx, [esp+0xC]
	call CheckObjectSlope
	mov word [cur_object_tile], 0
	pop eax
	pop ecx
	jnz .fail
	
	pusha
	mov ebx, [esp+0x20]	// get our game id
	mov dl, byte [landscape4(di, 1)]	// We check water slightly differently
	and dl, 0xF0
	cmp dl, 0x60
	je .water
	cmp dl, 0xA0
	jne .usual

	test byte [landscape7+edi], 4
	jz .usual
	test word [objectflags+ebx*2], OF_NOBUILDLAND
	jnz .waterobject

.usual:
// Allows the grf to prevent an object being constructd on land (Lakie)
	mov word [operrormsg2], ourtext(objecterr_cantbuildonland)
	test word [objectflags+ebx*2], OF_NOBUILDLAND
	jnz .failpop

.waterobject:
	mov esi, 0		// Clear Tile
	call BuildObjectFlags
	call [actionhandler]
	cmp ebx, 1<<31
	je .failpop

	add dword [ObjectCost], ebx
	popa
	pop eax
	pop ecx
	clc
	ret

.failpop:
	popa

.fail:
	pop eax
	pop ecx
	stc
	ret

.water:
// Checks water tiles allowing flat water tiles and 'river rapids' (Lakie)
//   Additionally also removes the cost of clearing the water.
	mov dh, byte [landscape5(di, 1)]
	test word [objectflags+ebx*2], OF_BUILDWATER	// Can we build on water
	jz .usual

	cmp dh, 3	// River Rapids (valid due to slopes not allowed on map edge)
	je .donepop
	cmp dh, 0	// Flat water tile
	jne .usual

	mov esi, 0		// Check to see if we can clear the water tile
	mov bl, 2		// (mainly to check if we are trying to replace map edge tiles)
	call [actionhandler]
	cmp ebx, 1<<31
	je .failpop

.donepop:
	popa
	pop eax
	pop ecx
	clc
	ret

// In:	ebx = game id
// Out: ebx = action flags
BuildObjectFlags:
	push eax
	xchg ebx, eax
	mov ebx, 0xA
	test word [objectflags+eax*2], OF_BUILDWATER
	jz .nowater
	and bl, ~8

.nowater:
	pop eax
	ret

// In:	eax = game id
//	di = slope information
//	cl = offset from northen corner
// Out:	zero flag = set for not allowed
global CheckObjectSlope
CheckObjectSlope:
	pusha
	mov word [operrormsg2], 0x1000
	mov esi, edi
	call [gettileinfoshort]
	mov dword [miscgrfvar], edi

	test di, 0x10
	jnz .fail

	test word [objectcallbackflags+eax*2], OC_SLOPECHECK
	jz .default

	xor esi, esi
	movzx ecx, cl
	mov dword [callback_extrainfo], ecx

	mov word [curcallback],0x157
	mov byte [grffeature], 0xF
	call getnewsprite
	mov dword [curcallback],0
	mov dword [miscgrfvar], 0
	jc .default

	test ax, ax
	popa
	ret

.default:
	mov eax, dword [esp+_pusha.eax]
	shr dl, 3	// Height is in multiples of 8

//	test word [objectflags+eax*2], OF_NOFOUNDATIONS
//	jnz .flat

	test di, di
	jz .flat

	bt di, 4
	adc dl, 1

.flat:
	cmp dl, [ObjectCurHeight] // Should be ok, (je = jz)
	
.fail:
	popa
	ret

// In:	edi = tile
//	edx = pool id
//	eax = game id
//	bh = object owner
CreateObjectTile:
	pusha
	movzx cx, byte [landscape4(di, 1)]
	and cl, 0xF0
	cmp cl, 0x60
	jne .notwater
	cmp byte [landscape5(di, 1)], 0x1
	je .notwater

// Stores the water bits of the water tile we are being built on (Lakie)
	mov ch, byte [landscape3+edi*2]
	or ch, 4

.notwater:
	mov byte [ObjectWater], ch

	rol di, 4		// Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, eax
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
	mov esi, 0
	call [actionhandler]
	call [invalidatetile]
	popa

	// Landscape 1 = owner (0x10 for no owner)
	// Landscape 2 = tile animation // tile offset from origin (northen tile)
	// Landscape 3 = pool id
	// Landscape 4 = Class A and hieght
	// Landscape 5 = newObject Type (NOBJECTTYPE)
	// Landscape 6 = Random bits

	mov byte [landscape1+edi], bh
	mov byte [landscape2+edi], 0 //cl
	mov word [landscape3+edi*2], dx
	and byte [landscape4(di, 1)], 0xF
	or byte [landscape4(di, 1)], 0xA0
	mov byte [landscape5(di, 1)], NOBJECTTYPE

	push eax
	call [randomfn]
	mov byte [landscape6+edi], al

	mov al, byte [ObjectWater]
	mov byte [landscape7+edi], al
	pop eax

	push eax
	push edx
	mov edx, objectidf
	call idf_increaseusage
	pop edx
	pop eax

// Grf Authors are expected to use the callback to start animations,
//   changed to be consistant with OpenTTD. (Lakie)
//	test word [objectflags+eax*2], OF_ANIMATED
//	jnz .hasanimation
	ret

#if 0
.hasanimation:
	push ebp
	push ebx
	push edi
	mov ebp, [ophandler+0xA0]
	mov ebx, 2
	call [ebp+4]
	pop edi
	pop ebx
	pop ebp
	ret
#endif

// in:	 bh = owner
//		eax = game id
//		ecx = pool id
SetObjectBuildColour:
	push ebx
	push eax
	push edx
	mov edx, eax
	cmp bh, 0x10
	jb .owned

	call [randomfn]

	test word [objectcallbackflags+edx*2], OC_BUILDCOLOUR
	jz .done
	
.hascolour:
	mov bl, al

	test word [objectflags+edx*2], OF_TWOCC
	jnz .twocc
	and al, 0xF

.twocc:
	push esi
	push ebx

	xor esi, esi
	movzx eax, al
	mov dword [miscgrfvar], eax
	mov byte [grffeature], 0xF
	mov word [curcallback], 0x15B
	mov eax, edx

	call getnewsprite
	mov dword [miscgrfvar], 0
	mov word [curcallback], 0
	pop ebx
	pop esi
	jnc .done

	// Restore original calculated value
	mov al, bl

.done:
	mov byte [objectpool+ecx+object.colour], al

.donenoset:
	pop edx
	pop eax
	pop ebx
	ret

.owned:
	test word [objectcallbackflags+edx*2], OC_BUILDCOLOUR
	jz .donenoset

	push ecx
	movzx eax, bh
	call GetOwnerColours
	or al, cl
	pop ecx
	jmp .hascolour

// **************************************** Object Removal ****************************************
// Removal of newgrf objects (Hooks owned land)
// Input:	edi - tile coordinates
uvard ObjectClearTile

global SellObject
SellObject:
	mov bl, 1
	cmp byte [landscape5(bx, 1)], NOBJECTTYPE
	je .new
	call [ObjectClearTile]
	ret

// Effectively a highly stripped down version of RemoveObject
.new:
	pusha
	movzx ecx, word [landscape3+ebx*2]
	mov ebp, ecx
	shl ebp, 4 // imul ebp, object_size

	movzx edi, word [objectpool+ebp+object.origin]
	movzx eax, word [objectpool+ebp+object.dataid]

	push dword [objectsdataidtogameid+eax*2]
	push dword [objectpool+ebp+object.view] 
	call GetObjectSize

	push dword IsObjectTile		// Functions and values for check tile
	push dword RemoveObjectTile
	push eax
	push ecx
	call LoopTiles

	xor edi, edi
	call SetObjectPoolEntry
	popa
	ret

global RemoveObject, RemoveObject.origfn
RemoveObject:
	mov word [operrormsg2], 0x013B
	cmp byte [landscape5(di, 1)], NOBJECTTYPE
	je .ObjectTile
	stc
	ret

// Both the new and old functions need this
.clearTile:
	call [ObjectClearTile]
	ret

// Remove new objects
.ObjectTile:
	push eax
	push ecx
	push edx
	movzx ecx, word [landscape3+edi*2]
	imul ecx, object_size
	cmp word [objectpool+ecx+object.origin], 0
	je near .ud2

	mov bh, [landscape1+edi]
	cmp bh, [curplayer]
	je .companyowned

	cmp bh, 0x10
	jne near .companyfail

.companyowned:
	movzx eax, word [objectpool+ecx+object.dataid]
	movzx edx, word [objectsdataidtogameid+eax*2]

	call RemoveObjectFlags
	jc .fail

	push edx
	push dword [objectpool+ecx+object.view]
	call GetObjectSize

	push edi
	push ebp
	movzx ebp, word [landscape3+edi*2]
	movzx edi, word [objectpool+ecx+object.origin]
	push ebp

	push dword IsObjectTile		// Functions and values for check tile
	push dword RemoveObjectTile
	push eax
	push ebp
	call LoopTiles

	pop ecx
	pop ebp
	pop edi
	jc .fail

	movzx eax, word [objectsdataidtogameid+eax*2]

	cmp edx, 0	// We shouldn't really get 0 unless there has been an error
	je .ud2

	test bl, 1
	jz .check

	push edi
	xor edi, edi
	call SetObjectPoolEntry
	pop edi

	pop edx
	pop ecx
	pop eax
	clc
	ret

.check:
	call RemoveObjectCost
	pop edx
	pop ecx
	pop eax
	clc
	ret
.ud2:
	ud2 // Forced crash upon corrupt object pool entry

.fail:
	pop edx
	pop ecx
	pop eax
	mov ebx, 1<<31
	clc
	ret

.companyfail:
	pop edx
	pop ecx
	pop eax
	stc
	ret

// In:	ecx = pool id
//	bl = action code
// Out: carry = set if error
RemoveObjectFlags:
	cmp byte [curplayer], 0x11
	je .fail
	
	cmp byte [gamemode], 2 // Objects are always removeable in the scenerio editor
	je .done

	test dx, dx
	jz .nogrf

	test word [objectflags+edx*2], OF_ANYREMOVE
	jnz .done

	test word [objectflags+edx*2], OF_UNREMOVALABLE
	jnz .unremovable

.nogrf:
	mov word [operrormsg2], 0x5800
	test bl, 2
	jnz .fail

.done:
	clc
	ret

.unremovable:
	mov word [operrormsg2], 0x013B
	cmp byte [curplayerctrlkey], 1
	jz .done

.fail:
	stc
	ret

// In:	eax = data id
//	cl = Tile Number
//	edx = pool id
//	edi = tile
RemoveObjectTile:
	pusha
	mov cl, byte [landscape7+edi]
	mov byte [ObjectWater], cl

	test cl, 4
	jz .notwater
	test bl, 8
	jnz near .fail

.notwater:
	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
	call RemoveObject.clearTile
	popa

	test bl, 1
	jnz .remove

	clc
	ret

.remove:
	call RedrawObjectTile // Force the game to redraw the tile

	push esi
	push ebx
	push edx
	mov edx, objectidf
	call idf_decreaseusage // Requires an action3 structure
	pop edx
	pop ebx

// We no longer now if the object tile is animated or not
//	imul edx, object_size
//	test word [objectpool+edx+object.flags], OF_ANIMATED
//	jz .normaltile

	push ebx
	push ebp
	push edi
	mov ebp, [ophandler+0xA0]
	mov ebx, 3
	call [ebp+4]
	pop edi
	pop ebp
	pop ebx

.normaltile:
	test byte [ObjectWater], 4
	jz .wasntwater

// Restore the water tile originally under the object (Lakie)
	pusha
	rol di, 4 // Store the x, y in the ax, cx registors
	mov eax, edi
	mov ecx, edi
	rol cx, 8
	and ax, 0x0FF0
	and cx, 0x0FF0
	ror di, 4
	
	movzx edi, byte [ObjectWater]
	and di, ~4
	jnz .notsea
	mov byte [curplayerctrlkey], 1 // Overrides canal/rivers on sea level

.notsea:
	shr di, 1 // 1 = river, 0 = canal

extern actionmakewater_actionnum
	mov esi, actionmakewater_actionnum
	mov bx, 1
	call [actionhandler]
	popa

.wasntwater:
	pop esi
	clc
	ret

.fail:
	mov word [operrormsg2], 0x3807
	popa
	stc
	ret

// In:	eax = game id
//	ecx = pool id
//	edx = number of tiles
// Out:	ebx = cost
RemoveObjectCost:
	push eax
	push edx
	push ebx
	push ecx
	imul ecx, object_size
	mov ebx, 2 // Our fallback base factor
	mov ecx, 5 // default object remove cost is 1/5th of buy / sell factor

	test ax, ax
	jz .nogrf
	movzx ebx, byte [objectremovalcostfactors+eax]

.nogrf:
	// multiple it by the number of tiles
	imul ebx, edx

	// multiple it the base factor
	mov edx, [costs+0x8A]
	imul ebx, edx

	push eax
	pop eax

	// No grf?
	test ax, ax
	jz .normal

	// Unmovable flag (if we get here we know ctrl is pressed)
	test word [objectflags+eax*2], OF_UNREMOVALABLE
	jz .removable
	imul ebx, 125

.removable:
	// Removal as income flag
	test word [objectflags+eax*2], OF_REMOVALINCOME
	jz .normal
	
	neg ecx

.normal:
	mov eax, ebx
	xor edx, edx
	idiv ecx
	mov ebx, eax
	pop ecx
	pop edx
	pop edx
	pop eax
	ret

// **************************************** Object Drawing ****************************************

global DrawObject
DrawObject:
	cmp dh, NOBJECTTYPE
	je .newObject

	movzx ebp, byte [landscape1+ebp]
	movzx ebp, byte [companycolors+ebp]
	clc
	ret

.fallbackpop:
	pop ebp
	pop ebx
	pop edx
	pop ecx
	pop eax


.fallback:
	push ebp
	call DrawObjectFoundations
	call GetObjectColourMapWrapper
	shl ebp, 16

	push ebp
	mov bx, 1420
	call .fallback_ground
	pop ebx

	or al, 8
	or cl, 8
	mov di, 1
	mov si, di
	mov dh, 0xA
	mov bx, 4790 + 0x8000
	call [addsprite]
	pop ebp
	popa
	stc
	ret

// Because of foundations, we need to draw our ground tile differently
.fallback_ground:
	push ebp
	mov ebp, dword [esp+8]
	test bp, bp
	pop ebp
	jnz .fallback_found

	call [addgroundsprite]
	ret

.fallback_found:
	push eax
	push ecx
	push edx
	mov ax,31
	mov cx,1
extern addrelsprite
	call [addrelsprite]
	pop edx
	pop ecx
	pop eax
	add dl, 16
	ret

.newObject:
	pusha
	xchg edi, ebp
	cmp dword [objectpool_ptr], 0
	je .fallback

	movzx esi, word [landscape3+edi*2]
	imul esi, object_size
	cmp word [objectpool+esi+object.origin], 0
	je .fallback	// invalid pool (should be crash)?

	movzx esi, word [objectpool+esi+object.dataid]
	movzx esi, word [objectsdataidtogameid+esi*2]
	test esi, esi
	jz .fallback	// No grf loaded

	push edx
	call DrawObjectFoundations.gameid
	pop edx

	push esi
	push edi
	push eax
	push ecx
	push edx
	push ebx
	push ebp

	mov eax, esi
	mov esi, ebx
	mov byte [grffeature], 0xF
	call getnewsprite
	
	push eax	// dataptr for processtileaction2
	push ebx	// spritesavail for processtileaction2
	push dword 3	// conststate for processtileaction2

	push ebx
	mov ebx, [esp+0x14]
	call GetObjectColourMapWrapper
	pop ebx

	push ebp	// defcolor for processtileaction2

	movzx eax, word [esp+0x20]
	movzx ecx, word [esp+0x1C]
	mov edx, [esp+0x18]
	mov edi, [esp+0x10]

	push dword 0xF		// grffeature for processtileaction2
	call processtileaction2

	pop ebp
	pop ebx
	pop edx
	pop ecx
	pop eax
	pop edi
	pop esi

// Replaces the ground sprite with water showing correct canal / river bits (Lakie)
	xchg esi, edi // Were we built upon water
	test byte [landscape7+esi], 4
	jz .nowater

	test word [objectflags+edi*2], OF_DRAWWATER
	jz .nowater

	call [gettileinfoshort]
	movzx bp, byte [landscape7+esi]
extern Class6DrawLandCanalsOrRiversOrSeeWaterL3.ebp
	call Class6DrawLandCanalsOrRiversOrSeeWaterL3.ebp

.nowater:
	popa
	stc
	ret

// In:	ebx = tile
//	ebp = raised flags
//	esi = gameid (only for .gameid)
// Out:	carry = set if foundations
DrawObjectFoundations.gameid:
	push edi
	movzx edi, word [landscape3+ebx*2]
	imul edi, object_size
	test word [objectflags+esi*2], OF_NOFOUNDATIONS
	pop edi
	jnz DrawObjectFoundations.override

// Draws the basic 
DrawObjectFoundations:
	test bp, bp
	jz .nofondations

	add dl, 8
	call displayfoundation
	ret

.override:
	xor bp, bp

.nofondations:
	ret

// In:	ebx = tile
// Out:	ebp = colour / recolour map
GetObjectColourMapWrapper:
	push ebx
	push edx

	movzx edx, byte [landscape1+ebx]
	movzx ebp, word [landscape3+ebx*2]
	imul ebp, object_size
	movzx ebp, word [objectpool+ebp+object.dataid]
	movzx ebp, byte [objectsdataidtogameid+ebp*2]

	push edx // Object owner
	push ebx // Tile index
	push ebp // Object game id

	call GetObjectColourMap
	mov bp, bx
	pop edx
	pop ebx
	ret

// In:	 cx, dx = x, y
//	ebx = dropdown item index
DrawObjectDDPreview:
	inc ecx
	call .createview
	jz .invalid

	pusha
	mov edi, baTempBuffer1
	mov word [edi+scrnblockdesc.zoom], 1
	shl word [edi+scrnblockdesc.x], 1
	shl word [edi+scrnblockdesc.y], 1
	shl word [edi+scrnblockdesc.width], 1
	shl word [edi+scrnblockdesc.height], 1

	movzx eax, word [objectddgameidlist+ebx*2]
	mov ebp, eax
	mov esi, 0
	mov byte [grffeature], 0xF
	call getnewsprite
	push eax	 // Data Pointer
	push ebx	 // Sprite Availability
	push dword 3 // Construction stage (always fully built for objects)

	add cx, 16
	add dx, 8
	shl cx, 1
	shl dx, 1

	call .getcolours
	push ebx
	push dword 0xF
	call DrawObjectTileSelWindow
	popa

.invalid:
	ret

.createview:
	pusha
	mov edi, baTempBuffer1
	mov byte [edi], 0
	//	DX,BX = X,Y CX,BP = width,height
	mov ebx, edx
	mov edx, ecx
	mov cx, 64/2
	mov bp, 46/2

	call [MakeTempScrnBlockDesc]
	popa
	ret

.getcolours:
	push edx
	mov edx, 0x10	// Get the recolour to defaultly apply
	cmp byte [gamemode], 2
	je .noowner
	movzx edx, byte [human1]

.noowner:
	push edx // Owner of the window
	push dword 0 // No tile index
	push dword ebp // Current selected object id
	call GetObjectColourMap
	pop edx
	ret

// ************************************ Object Preview Drawing ************************************
extern drawspritefn, exscurfeature, exsspritelistext, newspritedata, newspritexofs, newspriteyofs
global DrawObjectTileSelWindow

uvarw DrawPreviewLastX
uvarw DrawPreviewLastY

// Draws a object tile in a temporary buffer, [also house or industry tiles in theory]. (Lakie)
// - This is going to mainly be a stripped down and simplified clone of processtileaction2
// In:	 cx = x
//	 dx = y
//	edi = Sprite Block
//	(On the stack in this order)
//	- Data Pointer
//	- Sprite Availablity
//	- Construction State
//	- Defualt Recolour
//	- Grf Feature
proc DrawObjectTileSelWindow
	arg dataptr, spritesavail, conststate, defcolor, grffeature
	slocal numsprites, byte

	_enter

	mov esi, dword [%$dataptr]
	
	mov bl, [esi] // Num sprites / type of action2
	mov byte [%$numsprites], bl
	inc esi

	call .getsprite
	jz .noground

	pusha	// Draw the ground tile
	mov word [DrawPreviewLastX], cx
	mov word [DrawPreviewLastY], dx

	call [drawspritefn]
	popa

.noground:
	cmp byte [%$numsprites], 0
	ja .newformat

	call .getsprite
	jz .done

	pusha
	movzx ax, byte [esi] // x
	movzx cx, byte [esi+1] // y
	mov dl, 0 // z
	call .topixels
	mov bx, cx
	
	mov ecx, dword [esp+_pusha.ecx]
	mov edx, dword [esp+_pusha.edx]
	add cx, ax
	add dx, bx
	mov ebx, dword [esp+_pusha.ebx]
	
	// Draw the upper tile part
	call [drawspritefn]
	popa

.done:
	_ret

.error:
	ud2
	_ret

.newformat:
	// First loop the extended ground sprites
	// - There isn't much difference between this and .normal/.shared, the
	//     main difference is ground sprites do not support the x, y offsets.
	cmp byte [esi+6], 0x80
	jne .normal

	call .getsprite
	jz .error
	btr ebx, 30
	add esi, 3

	pusha	// Draw the extra ground tile
	call [drawspritefn]
	popa
	dec byte [%$numsprites]
	jnz .newformat
	_ret

.normal:
	// Handles the rest of the action2, both the 'boxes' and 'relatives'
	call .getsprite
	jz .error
	btr ebx, 30

	pusha
	cmp byte [esi+2], 0x80
	je .shared
	
	// Get the landscape offsets and convert them to pixel offsets
	movsx ax, byte [esi] // x
	movsx cx, byte [esi+1] // y
	mov dl, byte [esi+2] // z
	call .topixels
	mov bx, cx

	mov ecx, dword [esp+_pusha.ecx]
	mov edx, dword [esp+_pusha.edx]
	add cx, ax
	add dx, bx

	mov ebx, [esp+_pusha.ebx]
	push ecx
	push edx

	// To provide almost correct functionality for 'relatives'
	call .getoffset
	mov word [DrawPreviewLastX], cx
	mov word [DrawPreviewLastY], dx

	pop edx
	pop ecx

	add dword [esp+_pusha.esi], 6
	jmp .offsets

.shared:
	// Already pixel offsets so no adjustment needed
	movzx cx, byte [esi]
	movzx dx, byte [esi+1]
	add cx, word [DrawPreviewLastX]
	add dx, word [DrawPreviewLastY]
	add dword [esp+_pusha.esi], 3

.offsets:
	call [drawspritefn]
	popa
	dec byte [%$numsprites]
	jnz .normal
	_ret

// In:	ebx - sprite
//	 cx - x offset
//	 dx - y offset
// Out:	 cx - x offset
//	 dx - y offset
.getoffset:
	push ebx
	push ebp
	and ebx, 0x3FFF
	cmp bx, baseoursprites
	jb .ttdoffsets

	mov byte [exscurfeature], 0xF
	extcall exsfeaturespritetoreal

	// Next find the location of its 'offsets'
	mov ebp, [newspritedata]
	lea ebp, [ebp+ebx*4]
	mov ebp, [ebp]
	test ebp, ebp
	jz .badoffsets

	add cx, [ebp+4]
	add dx, [ebp+6]
	pop ebp
	pop ebx
	_ret 0

.ttdoffsets:
	mov ebp, [newspritexofs]
	add cx, [ebp+ebx*2]
	mov ebp, [newspriteyofs]
	add dx, [ebp+ebx*2]
	pop ebp
	pop ebx
	_ret 0

.badoffsets:
	ud2
	pop ebp
	pop ebx
	_ret 0

// In:	esi = Pointer to Action2 (Sprite raw)
// Out:	ebx = Sprite (with recolour)
//	z flag = set means sprite valid
.getsprite:
	mov ebx, dword [esi]
	add esi, 4
	btr ebx, 31
	jnc .ttdsprite

	// Grf (house / industry) sprites need adjusting according to construction
	push edx
	mov edx, dword [%$spritesavail]
	shl edx, 2
	add edx, [%$conststate]
	movzx edx, byte [.spriteoffsets+edx]
	add ebx, edx

	mov dl, [%$grffeature]	// Something to do with GRM apparently
	mov [exscurfeature], dl
	mov byte [exsspritelistext], 1
	pop edx

.ttdsprite:
	test bx, bx
	jns .norecolor

	rol ebx, 16	// Tests for a specified recolour mapping
	test bx, 0x3fff
	jnz .goodrecolor
	or bx, [%$defcolor]

.goodrecolor:
	ror ebx,16
	
.norecolor:
	test ebx, ebx
	_ret 0 // Preserve stack frame

// In:	ax, cx, dl = landscape x, y, z
// Out:	ax, cx = pixel x, y
.topixels:
	xor dh, dh
	mov bx, ax
	neg ax
	add ax, cx
	add cx, bx
	shl ax, 1
	sub cx, dx
	_ret 0
endproc

.spriteoffsets:
	db 0,0,0,0
	db 0,0,0,1
	db 0,1,1,2
	db 0,1,2,3

// ***************************************** Animation ********************************************
// Used to increment the animation of the object
global ClassAAnimationHandler
ClassAAnimationHandler:
	cmp byte [gamemode], 2
	je near .finish

	cmp byte [landscape5(bx, 1)], NOBJECTTYPE
	jne near .notobject

	pusha
	movzx ebp, word [landscape3+ebx*2]
	imul ebp, object_size
	movzx eax, word [objectpool+ebp+object.dataid]
	movzx eax, word [objectsdataidtogameid+eax*2]
	
	// don't bother if the grf isn't loaded
	test ax, ax
	jz near .finishpop

	// Check animation enabled
	test word [objectflags+eax*2], OF_ANIMATED
	jz near .finishpop
	cmp word [objectanimframes+eax*2], -1
	je near .original

	movzx edi, word [animcounter]
	mov ebp, 1

	// Should be loop for an animation speed callback?
	test word [objectcallbackflags+eax*2], OC_ANIM_SPEED
	jz .speedprop

	push eax
	push ebx
	mov esi, ebx
	mov byte [grffeature], 0xF
	mov word [curcallback], 0x15A
	call getnewsprite
	mov byte [curcallback],0
	mov cl,al
	pop ebx
	pop eax
	jnc .hasspeed

.speedprop:
	mov cl, byte [objectanimspeeds+eax]

.hasspeed:
	shl ebp, cl
	dec ebp

	// Has the animation time elapsed?
	test edi, ebp
	jnz near .finishpop

	// Should we call the next frame callback?
	mov edx, eax
	test word [objectcallbackflags+eax*2], OC_ANIM_NEXTFRAME
	jz .normal

	// Should put random bits into var10
	test word [objectflags+eax*2], OF_ANIMATEDRANDBITS
	jz .norandbits

	push eax
	call [randomfn]
	mov dword [miscgrfvar], eax
	pop eax

.norandbits:
	mov dword [miscgrfvar], 0
	push eax
	push ebx
	mov esi, ebx
	mov byte [grffeature], 0xF
	mov word [curcallback], 0x158
	call getnewsprite
	mov byte [curcallback],0
	mov cl,al
	pop ebx
	pop edx
	jc .normal

	test ah, ah
	jz .nosound

	pusha
	movzx eax,ah
	and al,0x7f
	mov ecx,ebx
	rol bx,4
	ror cx,4
	and bx,0x0ff0
	and cx,0x0ff0
	or esi,byte -1
	call [generatesoundeffect]
	popa

.nosound:
	cmp al, 0xFF
	je .endanim

	cmp al, 0xFE
	jnz .gotframe

.normal:
	mov al, byte [landscape2+ebx]
	inc al
	cmp al, byte [objectanimframes+edx*2]
	jbe .gotframe

	cmp byte [objectanimframes+1+edx*2], 1
	jne .endanim
	xor al, al

.gotframe:
	mov byte [landscape2+ebx], al
	mov edi, ebx
	call RedrawObjectTile

.finishpop:
	popa

.finish:
	ret

.endanim:
	mov edi, ebx
	mov ebp, [ophandler+0xA0]
	mov ebx, 3
	call [ebp+4]
	popa
	ret

.original:
	test word [animcounter], 3	// Now every tick
	jnz .finishpop

	inc byte [landscape2+ebx]
	mov edi, ebx
	call RedrawObjectTile
	popa
	ret

#if 0
	push ebp
	push ebx
	movzx ebp, word [landscape3+ebx*2]
	push ebp
	imul ebp, object_size
	mov al, byte [objectpool+ebp+object.animation]
	inc al
	mov byte [objectpool+ebp+object.animation], al

	push edx
	movzx edx, word [objectpool+ebp+object.dataid]
	push dword [objectsdataidtogameid+edx*2]
	call GetObjectSize

	push edi
	mov bh, [landscape1+ebx]
	movzx edi, word [objectpool+ebp+object.origin]
	mov ebp, [esp+8]
	push dword IsObjectTile
	push dword RedrawObjectTile
	push dword 0 // Unused by the sub functions
	push ebp
	call LoopTiles
	pop ebp
	pop edi
	pop edx
	pop ebx
	pop ebp

.finish:
	ret
#endif

// Not a new object tile so purge it from the animated tile list
.notobject:
	push ebx
	push ebp
	push edi
	mov edi, ebx
	mov ebp, [ophandler+0xA0]
	mov ebx, 3
	call [ebp+4]
	pop edi
	pop ebp
	pop ebx
	ret

// Do callback 159 (Animation Control)
// in:	ebx = tile yx
//	edx = trigger bit
ObjectAnimTrigger:
	pusha
	mov esi, ebx
	cmp dword [objectpool_ptr], 0
	jz near .error
	
	movzx eax, word [landscape3+ebx*2]
	imul eax, object_size
	cmp word [objectpool+eax+object.origin], 0
	je .done // should be error most likely

	// Do we have a game id (newgrf loaded)?
	movzx eax, word [objectpool+eax+object.dataid]
	movzx eax, word [objectsdataidtogameid+eax*2]
	test eax, eax
	jz .done

	// Does this object allow animation?
	test word [objectflags+eax*2], OF_ANIMATED
	jz .done

	// Is this trigger enabled?
	test word [objectanimtriggers+eax*2], dx
	jz .done

.docallback:
	// Setup the callback variable data
	mov byte [grffeature], 0xF
	mov word  [curcallback], 0x159
	and dword [callback_extrainfo], 0
	mov [callback_extrainfo], dl
	
	// Is this for the whole object?
	test dl, OA_FORALLTILES
	jnz .wholeobject

	push eax
	call [randomfn]
	mov [miscgrfvar], eax
	pop eax

	call getnewsprite
	jc .done

	mov esi, ebx
	call SetObjectTileAnimStage
	mov byte [curcallback],0

.done:
	popa
	ret

.hasgameid:
	pusha
	jmp .docallback

.wholeobject:
	mov edi, ebx
	movzx ebx, word [landscape3+ebx*2]

	push ebx
	imul ebx, object_size
	mov dl, byte [objectpool+ebx+object.view]
	pop ebx

	push eax
	push edx
	call GetObjectSize

	push IsObjectTile
	push CallObjectTileTrigger
	push eax
	push ebx
	call LoopTiles

	mov byte [curcallback],0
	popa
	ret

.error:
	ud2
	popa
	ret

// Calls the trigger for all tiles in the object
CallObjectTileTrigger:
	pusha
	push eax
	call [randomfn]
	mov [miscgrfvar], eax
	pop eax

	mov esi, edi
	call getnewsprite
	jc .novalue

	mov ebx, edi
	call SetObjectTileAnimStage

.novalue:
	popa
	ret

// Start/stop animation and set the animation stage of a new object tile
// (Almost the same as sethouseanimstage, but stores the current frame differently)
// in:	al:	number of new stage where to start
//		or: ff to stop animation
//		or: fe to start wherewer it is currently
//		or: fd to do nothing (for convenience)
//	ebx:	XY of house tile
SetObjectTileAnimStage:
	or ah,ah
	jz .nosound

	pusha
	movzx eax,ah
	and al,0x7f
	mov ecx,ebx
	rol bx,4
	ror cx,4
	and bx,0x0ff0
	and cx,0x0ff0
	or esi,byte -1
	call [generatesoundeffect]
	popa

.nosound:
	cmp al,0xfd
	je .animdone

	cmp al,0xff
	jne .dontstop

	pusha
	mov edi,ebx
	mov ebx,3				// Class 14 function 3 - remove animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa
	ret

.dontstop:
	cmp al,0xfe
	je .dontset
	mov byte [landscape2+ebx],al

.dontset:
	pusha
	mov edi,ebx
	mov ebx,2				// Class 14 function 2 - add animated tile
	mov ebp,[ophandler+0x14*8]
	call [ebp+4]
	popa

.animdone:
	ret

// ************************************ Periodic Tile Proc ****************************************
global ClassAPeriodicHandler
ClassAPeriodicHandler:
	pusha
	cmp byte [landscape4(bx, 1)], NOBJECTTYPE
	jne .done

	xchg edi, ebx
	mov bh, byte [landscape1+edi]
	movzx ebp, word [landscape3+edi*2]

	push ebp
	imul ebp, object_size
	movzx esi, word [objectpool+ebp+object.dataid]
	movzx esi, word [objectsdataidtogameid+esi*2]
	pop ebp
	test esi, esi	// Do we have a valid gameid?
	jz .done

	mov ebx, edi
	mov eax, esi
	mov edx, OA_PERIODICTILE
	call ObjectAnimTrigger.hasgameid

	cmp word [objectpool+ebp+object.origin], di
	jne .done

	mov edx, OA_WHOLEOBJECT
	call ObjectAnimTrigger.hasgameid

	push esi
	push dword [objectpool+ebp+object.view]
	call GetObjectSize	// Result in dx

	push IsObjectTile
	push RedrawObjectTile
	push esi
	push ebp
	call LoopTiles	// Mark all the object tiles as dirty

.done:
	popa
	ret

// ****************************************** Query Tile ******************************************
global QueryObject

// In:	 ax = Statue string
//	 cl = Tile class
//	edi = Tile index (xy)
// Out:	ax = String to use
//	ecx= TextRefStack Values
QueryObject:
	cmp cl, 2
	je .done

	mov ax, 0x5805	// Original owned land
	cmp cl, 5
	jne .done

	// New objects
	push esi
	xor ecx, ecx
	movzx esi, word [landscape3+edi*2]
	imul esi, object_size
	movzx esi, word [objectpool+esi+object.dataid]
	movzx esi, word [objectsdataidtogameid+esi*2]
	
	test esi, esi	// No grf loaded, so fallback to company owned land
	jz .donepop

	mov ax, ourtext(objectquery)	// Store the text id and its value to use
	mov ecx, dword [objectspriteblock+esi*4]
extern curlandinfogrf
	mov dword [curlandinfogrf], ecx
	
	mov cx, word [objectnames+esi*2]
	call .fixtextid

// It's not gartentuee'd that the class and object textids come from the same grf
//   but this commented code would give the ablity to show both
//	shl ecx, 16
//	
//	movzx esi, word [objectclass+esi*2]
//	mov cx, word [objectclassesnames+esi*2]
//	call .fixtextid

.donepop:
	pop esi

.done:
	ret

.fixtextid:
	cmp ch, 0xD0
	jb .nofix
	cmp ch, 0xD3
	ja .nofix
	add ch, 0x04

.nofix:
	ret

// **************************************** Newgrf Vars *******************************************
extern gettileterrain, gettileinfoshort, specialgrfregisters, mostrecentspriteblock

// Var:	40, Relative Position
// Out:	eax = 00yxYYXX
exported getObjectVar40
	test esi, esi
	jz .gui

	push ebx
	mov eax, esi
	movzx ebx, word [landscape3+esi*2]
	imul ebx, object_size
	movzx ebx, word [objectpool+ebx+object.origin]
	sub eax, ebx

	mov bx, ax
	shl al, 4
	shr ax, 4
	shl eax, 16

	mov ax, bx
	pop ebx
	ret

.gui:
	mov eax, 0xFF0F0F
	ret

// Var:	41, Tile Type
// Out:	0000sstt (tt - same as var 43 houses, ss - slope data)
exported getObjectVar41
	test esi, esi
	jz .noobject

.hasobject:
	pusha
	call [gettileinfoshort] // First we get the tile information
	shl di, 8

	call gettileterrain // And we add the terrain information
	movzx ax, al
	or ax, di

	movzx eax, ax
	mov dword [esp+_pusha.eax], eax // Since getTileInfo changes most registors pusha was needed.
	popa
	ret

.noobject:
	movzx esi, word [cur_object_tile]
	jnz .hasobject

	xor eax, eax
	ret

// Var 42, Construction Date
// Out: dddddddd (year since year 0)
exported getObjectVar42
	test esi, esi
	jz .gui

	movzx eax, word [landscape3+esi*2]
	imul eax, object_size
	mov eax, dword [objectpool+eax+object.builddate]
	imul eax, 365	// Rough fix until the object pool update
	ret

.gui:
	movzx eax, word [currentdate]
	add eax, 701265
	add eax, [landscape3+ttdpatchdata.daysadd]
	ret

// Var 43, Animation stage
// Out:	000000AA - Animation Counter
exported getObjectVar43
	test esi, esi
	jz .gui

	movzx eax, byte [landscape2+esi]
	ret

.gui:
	xor eax, eax
	ret

// Var 44, Object Owner
// Out:	000000AA - Owner id (0x10 if unowned)
exported getObjectVar44
	test esi, esi
	jz .gui

	movzx eax, byte [landscape1+esi] // Too easy?
	ret

.gui:
	movzx eax, byte [human1]
	ret

// For these we use the same system as OpenTTD, using the town ref it was built with.
// Var 45, Get distance of closest town
// Out:	00zzDDDD - Zone, Distance (manhatten) to nearest town
exported getObjectVar45
	xor eax, eax

	test esi, esi
	jz .noobject

	push ebx
	push ebp
	push edi
	push edx

	mov eax, esi
	movzx edi, word [landscape3+eax*2]
	imul edi, object_size
	mov edi, dword [objectpool+edi+object.townptr]

	// Calculate distance as the function will not (bp)
	mov bx, [edi+town.XY]
	sub bl, al
	jnb .notx
	neg bl

.notx:
	sub bh, ah
	jnb .noty
	neg bh

.noty:
	add bl, bh
	rcl bh, 1
	and bh, 1
	mov bp, bx

// Note, uses edi if given (no bp), otherwise searchs (bp)
.hastown:
	mov ebx,2	// find nearest town and zone
	mov ecx,[ophandler+3*8]
	call [ecx+4]

	movzx eax, dl	// zone
	shl eax, 16
	mov ax, bp	// distance

	pop edx
	pop edi
	pop ebp
	pop ebx

.done:
	ret

.noobject:
	cmp word [cur_object_tile], 0
	je .done

	push ebx
	push ebp
	push edi
	push edx

	mov ax, word [cur_object_tile]
	xor edi, edi
	jmp .hastown

// Var 46, Get euclidean distance of closest town
// Out: DDDDDDDD - Distance (euclidean squared) to nearest town
exported getObjectVar46
	xor eax, eax

	test esi, esi
	jz .noobject

	push ebx
	push ebp
	push edi
	push edx

	mov eax, esi
	movzx edi, word [landscape3+eax*2]
	imul edi, object_size
	mov edi, dword [objectpool+edi+object.townptr]

.hastown:
	movzx ebx, al 			// object X
	movzx ebp, byte [edi+town.XY]	// town X
	sub ebx, ebp
	imul ebx, ebx	// ebx = X diff squared
	
	movzx eax, ah			// object Y
	movzx ebp, byte [edi+town.XY+1]	// town Y
	sub eax, ebp
	imul eax, eax	// eax = Y diff squared

	add eax, ebx	// eax = Euclidian distance squared

	pop edx
	pop edi
	pop ebp
	pop ebx

.done:
	ret

.noobject:
	cmp word [cur_object_tile], 0
	je .done

	push ebx
	push ebp
	push edi
	push edx

	mov ax, word [cur_object_tile]
	call findnearesttown
	jmp .hastown

// Var 47, Object Colour(s)
// Out:	000000CC - Object Colour
exported getObjectVar47
	push ecx
	movzx ecx, word [landscape3+esi*2]
	imul ecx, object_size
	mov ah, byte [objectpool+ecx+object.colour]

	// We don't want to fetch if object cached
	movzx ecx, word [objectpool+ecx+object.dataid]
	movzx ecx, word [objectsdataidtogameid+ecx*2]
	test word [objectcallbackflags+ecx*2], OC_BUILDCOLOUR
	jnz .noowner

	cmp byte [landscape1+esi], 0x10
	jae .noowner

	movzx eax, byte [landscape1+esi]
	call GetOwnerColours
	or cl, al

.noowner:
	// Filter the colour down to the required channels
	test word [objectflags+ecx*2], OF_TWOCC
	jnz .done
	and ax, 0xF

.done:
	pop ecx
	ret

// Var 48, Object View
// Out:	0000000V - Object View
exported getObjectVar48
	test esi, esi
	jz .gui

	push ecx
	movzx ecx, word [landscape3+esi*2]
	imul ecx, object_size
	movzx eax, byte [objectpool+ecx+object.view]
	pop ecx
	ret

.gui:
	cmp word [cur_object_tile], 0
	jne .inconstruction
	movzx eax, byte [win_objectgui_curobject_view]
	ret

.inconstruction:
	movzx eax, byte [ObjectView]
	ret


// For the below "ParamVar" functions, ah = parameter from grf

// in:	esi = tile index
//		 ah = offset information
// out:	 cx = offseted index
// uses:	eax (trashed)
getOffset:
	push edx

	shr ax, 4		// 0xF0 y
	shl ah, 4		// 0xF0 x
	movsx dx, ah	// Keep the sign of the number
	movsx ax, al
	rol dx, 4		// move the components to YYXX (with sign)
	ror ax, 4

	mov cx, si // base xy
	add cl, al // Add each component (should be signed addition)
	add ch, dh
	movzx ecx, cx

	pop edx
	ret

// Var60, Get object id at offset from tile 
// Out:	0000ttss - Type of return, Set id if valid type
exported getObjectParamVar60
	test esi, esi
	jz .noobject

.hassetup:
	call getOffset	//in	= si, ah
					//out	= cx

	// Check the tile class
	mov al, [landscape4(cx, 1)]
	and al, 0xF0
	cmp al, 0xA0
	jne .notobject

	cmp byte [landscape5(cx, 1)], NOBJECTTYPE
	jne .notobject

	movzx eax, word [landscape3+ecx*2]
	imul eax, object_size
	movzx eax, word [objectpool+eax+object.dataid]

	mov ecx, [mostrecentspriteblock]
	mov ecx, [ecx+spriteblock.grfid]
	cmp ecx, dword [objectsdataiddata+eax*idf_dataid_data_size+idf_dataid_data.grfid]
	jne .notsamegrf

	mov ax, word [objectsdataiddata+eax*idf_dataid_data_size+idf_dataid_data.setid]
	movzx eax, al	// Since we don't currently support extended bytes?
					// we'll just assume just a byte value
	ret

.notsamegrf:
	mov eax, 0xFFFE
	ret

.notobject:
	mov eax, 0xFFFF
	ret

.noobject:
	cmp word [cur_object_tile], 0
	je .notobject

	movzx esi, word [cur_object_tile]
	jmp .hassetup

// Var61, Get random bits at offset from tile
// Out:	000000RR - Random Bits from tile (given tile is of same object)
exported getObjectParamVar61
	call getOffset
	
	mov al, byte [landscape4(cx, 1)]	// Is it an object tile?
	and al, 0xF0
	cmp al, 0xA0
	jne .notobject

	cmp byte [landscape5(cx, 1)], NOBJECTTYPE
	jne .notobject

	mov ax, word [landscape3+ecx*2]	// Is it part of the same object (poolid)
	cmp ax, word [landscape3+esi*2]
	jne .notobject

	movzx eax, byte [landscape6+ecx]
	ret

.notobject:
	xor eax, eax
	ret

// Var62, Land info at offset from tile
// Out:	0czzbbss - Tile class, lowest corner height, Bit field, Slope data
exported getObjectParamVar62
	pusha
	mov dword [esp+_pusha.eax], 0 // Default return value

	test esi, esi
	jz .noobject

	movzx ebp, word [landscape3+esi*2]

.hassetup:
// The majority of the rest is effectively copied from industries version
	mov ecx,esi	// X
	shr cx,4
	and cl,0xf0
	movsx edx,ah
	and dl,0xf0
	add cx,dx

	shl ah,4	// Y
	movsx edx,ah
	mov eax,esi
	shl eax,4
	and ah,0x0f
	add ax,dx

	call [gettileinfo]

	mov [esp+28],di		// low word of saved EAX of stack, the high byte is zero
	mov [esp+30],dl		// byte 3 of saved EAX
	mov byte [esp+31], 0	// highest byte of saved EAX

	cmp bx, 10*8		// is it a class A tile?
	jne .notpart

	mov eax, ebp
	cmp ax, word [landscape3+esi*2]	// esi is now the offset of the asked tile
	sete byte [esp+29]	// byte 2 of saved eax

.notpart:
	cmp bx, 6*8		// is it a class 6 tile?
	sete al
	shl al,1
	or [esp+29],al

	call gettileterrain
	shl al,2
	or [esp+29],al

	shr bl,3
	mov [esp+31],bl

.bad:
	popa
	ret

.noobject:
	cmp word [cur_object_tile], 0 // Most likely the UI
	je .bad

	movzx esi, word [cur_object_tile]
	mov ebp, -1 // i.e. invalid
	jmp .hassetup

// Var63, Get animation counter at offset from tile
// Out:	000000AA - Animation Counter from tile (given tile is of same object)
exported getObjectParamVar63
	call getOffset	
	
	mov al, byte [landscape4(cx, 1)]	// Is it an object tile?
	and al, 0xF0
	cmp al, 0xA0
	jne .notobject

	cmp byte [landscape5(cx, 1)], NOBJECTTYPE
	jne .notobject

	mov ax, word [landscape3+ecx*2]	// Is it part of the same object (poolid)
	cmp ax, word [landscape3+esi*2]
	jne .notobject

	movzx eax, byte [landscape2+ecx]
	ret

.notobject:
	xor eax, eax
	ret

// Var64, Count of object type and closest object distance
// Out:	CCCCDDDD - Count of object type on map, Distance of closest object instance to tile
exported getObjectParamVar64
	// grfid = [specialgrfregisters+0*4]
	// setid = ah
	push ebx
	push dword 0
	test esi, esi
	jz .noobject

	mov dword [esp], esi
	movzx esi, word [landscape3+esi*2]
	imul esi, object_size
	movzx esi, word [objectpool+esi+object.origin]

.hassetup:
	movzx eax, ah
	mov ebx, dword [specialgrfregisters] // we take it from the first register
	test ebx, ebx
	jz .nothing
	cmp ebx, -1
	jne .goodgrf

	mov ebx, [mostrecentspriteblock]
	mov ebx, [ebx+spriteblock.grfid]

.goodgrf:
	mov dword [esp], esi
	xor ecx, ecx

// Last idf.lastdataid is never actually used :(
//	cmp dword [objectsdataidcount], 0
//	je .nothing

.nextdataid:
	inc ecx
	cmp ebx, dword [objectsdataiddata+ecx*idf_dataid_data_size+idf_dataid_data.grfid]
	jne .skipdataid
	cmp al, byte [objectsdataiddata+ecx*idf_dataid_data_size+idf_dataid_data.setid]
	je .gotdataid

.skipdataid:
	cmp ecx, NOBJECTS //[objectsdataidcount]
	jbe .nextdataid

.nothing:
	mov eax, 0xFFFF
	pop ebx
	pop ebx
	ret

.noobject:
	cmp word [cur_object_tile], 0
	je .nothing

	movzx esi, word [cur_object_tile]
	mov dword [esp], esi
	xor esi, esi
	jmp .hassetup

.gotdataid:
	push edx
	push edi
	push ebp

	xor eax, eax
	mov edi, NOBJECTS*object_size
	sub edi, object_size
	or ebp, byte -1

.nextpoolid:
	cmp word [objectpool+edi+object.origin], 0
	je .skippoolid
	cmp word [objectpool+edi+object.dataid], cx
	jne .skippoolid

	inc ax
	cmp word [objectpool+edi+object.origin], si
	je .skippoolid

	push edx
	movzx bx, byte [esp+16]
	movzx dx, byte [esp+17]

	sub bl, byte [objectpool+edi+object.origin]
	sbb bh, 0
	jns .notx
	neg bx

.notx:
	sub dl, byte [objectpool+edi+object.origin+1]
	sbb dh, 0
	jns .noty
	neg dx

.noty:
	add bx, dx
	pop edx

	cmp bx, bp
	ja .skippoolid

	mov bp, bx

.skippoolid:
	sub edi, object_size
	jns .nextpoolid

	// now ax = count, bp = distance
	shl eax, 16
	mov ax, bp

	pop ebp
	pop edi
	pop edx
	pop ebx
	pop ebx
	ret

