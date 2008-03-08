#include <std.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <window.inc>
#include <windowext.inc>
#include <imports/gui.inc>
#include <misc.inc>
extern canalfeatureids, getnewsprite, grffeature
extern setmousetool

guiwindow win_dockconstgui,240,36
	guicaption cColorSchemeDarkGreen, 0x9801	// DockConstruction
	guiele dock,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,w,22,y,14,h,22,data,746
	guiele shipdepot,cWinElemSpriteBox,cColorSchemeDarkGreen,x,22,w,22,y,14,h,22,data,748
	guiele buoy,cWinElemSpriteBox,cColorSchemeDarkGreen,x,44,w,22,y,14,h,22,data,693
	guiele dynamite,cWinElemSpriteBox,cColorSchemeDarkGreen,x,66,w,22,y,14,h,22,data,703
	guiele lowerland,cWinElemSpriteBox,cColorSchemeDarkGreen,x,88,w,22,y,14,h,22,data,695
	guiele raiseland,cWinElemSpriteBox,cColorSchemeDarkGreen,x,110,w,22,y,14,h,22,data,694
	guiele purchaseland,cWinElemSpriteBox,cColorSchemeDarkGreen,x,132,w,22,y,14,h,22,data,4791
	guiele canals,cWinElemSpriteBox,cColorSchemeDarkGreen,x,154,w,22,y,14,h,22,data,0
	guiele aqueduct,cWinElemSpriteBox,cColorSchemeDarkGreen,x,176,w,42,y,14,h,22,data,2598
	guiele river,cWinElemSpriteBox,cColorSchemeDarkGreen,x,218,w,22,y,14,h,22,data,4083
endguiwindow
// changeing the order or size will influence waterconstgui

exported CreateDockWaterConstrWindow
	mov eax, 286 + (22<<16) // x + (y << 16)
	mov ebx, win_dockconstgui_width + (win_dockconstgui_height << 16)
	mov cx, cWinTypeConstrToolbar	// window type
	mov dx, 0x90					// operation class offset
	mov ebp, 1						// function number
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], addr(win_dockconstgui_elements)
	mov byte [esi+window.data], 24
	ret
	
exported DockWaterConstrWindowSetIcons
	pusha
	mov eax, 4791
	cmp dword [canalfeatureids+3*4], 0
	jz .nosprites
	xor ebx, ebx
	mov eax, 3		// we want icons :)
	mov esi, 0
	mov byte [grffeature], 5
	call getnewsprite
.nosprites:	
	mov word [win_dockconstgui_elements.canals+10], ax
	mov word [win_waterconstgui_elements.canals+10], ax
	
	mov eax, 4083
	cmp dword [canalfeatureids+7*4], 0
	jz .nospritesriver
	xor ebx, ebx
	mov eax, 7		// we want river icons
	mov esi, 0
	mov byte [grffeature], 5
	call getnewsprite
.nospritesriver:
	mov word [win_dockconstgui_elements.river+10], ax
	mov word [win_waterconstgui_elements.river+10], ax
	popa
	ret

	
	
	
	
uvard OldDockWaterConstr_ToolClickProcs, 1
exported DockWaterConstr_MouseToolClick
	and al, 0xF0
	and cl, 0xF0
	mov dx, word [mousetoolclicklocfinex]
	movzx ebx, word [selectedtool]
	cmp ebx, 7
	jae .newtools
	mov esi, [OldDockWaterConstr_ToolClickProcs]
	jmp [esi+ebx*4]
.newtools:
	cmp ax, 0xFEF
	ja .fret
	cmp cx, 0xFEF
	ja .fret
	mov bx, cx
	rol bx, 8
	or bx, ax
	ror bx, 4
	mov [dragtoolstartx], ax
	mov [dragtoolstarty], cx
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	mov byte [curmousetooltype], 3
	bts word [uiflags], 13
.fret:
	ret
	
DockWaterConstr_MouseToolClose:
	jmp [OldDockWaterConstr_WindowHandler]	// simple use old ttd code
DockWaterConstr_MouseToolUITick:
	jmp [OldDockWaterConstr_WindowHandler]	// simple use old ttd code

uvard OldDockWaterConstr_WindowHandler,1
exported DockWaterConstr_WindowHandler
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jnz .noredraw
	jmp [DrawWindowElements]
.noredraw:
	cmp dl, cWinEventClick
	jz DockWaterConstr_ClickHandler
	cmp dl, cWinEventMouseToolClick
 	jz DockWaterConstr_MouseToolClick
	cmp dl, cWinEventMouseToolClose
	jz DockWaterConstr_MouseToolClose
	cmp dl, cWinEventMouseToolUITick
	jz near DockWaterConstr_MouseToolUITick
	cmp dl, cWinEventMouseDragUITick
	jz near DockWaterConstr_MouseDragUITick
	cmp dl, cWinEventMouseDragRelease
	jz near DockWaterConstr_MouseDragRelease
	cmp dl, cWinEventTimer
	je DockWaterConstr_timer
	ret

DockWaterConstr_timer:
	cmp byte [esi+window.data], 0
	jnz .toolbar
	ret
	
.toolbar:
	movzx eax, byte [esi+window.data]
	mov byte [esi+window.data], 0
	mov cl, cWinTypeMainToolbar
	xor dx, dx
	call [FindWindow]
	btr dword [esi+window.activebuttons], eax
	mov bx, [esi+window.id]
	shl eax, 8
	mov al, [esi+window.type]
	or al, 0x80
	jmp [invalidatehandle]

	
uvard OldDockWaterConstr_ClickProcs,1

varw DockWaterConstr_tooltips, 0x018B, 0x018C, 0x981D, 0x981E, 0x9834, 0x018D, 0x018E, 0x018F, 0x0329, ourtext(canaltexttip), ourtext(aquaducttexttip), ourtext(rivertexttip)
exported DockWaterConstr_ClickHandler
	call dword [WindowClicked]
	jns .click
	ret
.click:
	movzx eax,cl
	cmp byte [rmbclicked],0
	jne .rmb
	
	cmp al, 0
	jne .notdestroy
	jmp [DestroyWindow]
global DockWaterConstr_ClickHandler.notdestroy // hotkeys enters here, with al set appropriately
.notdestroy:
	cmp al, 8
	ja .newbuttons
	shl eax, 2
	add eax, [OldDockWaterConstr_ClickProcs]
	jmp [eax]
.newbuttons:
	sub al, 9
	call [DockWaterConstr_ClickProcs+eax*4]
	ret	
.rmb:
 	// generate tooltip
	mov ax,[DockWaterConstr_tooltips+eax*2]
	jmp [CreateTooltip]
	ret
	
DockWaterConstr_ClkUnselected:
	//unselect mousetool
	xor ebx,ebx
	xor al,al
	jmp [setmousetool]
	

vard DockWaterConstr_ClickProcs
	dd DockWaterConstr_ClkCanalsBuild
	dd DockWaterConstr_ClkAqueductBuild
	dd DockWaterConstr_ClkRiverBuild
endvar

DockWaterConstr_ClkCanalsBuild:
	push eax
 	push esi
 	xor esi, esi
	mov eax, 0x13
	extern generatesoundeffect
	call [generatesoundeffect]
	pop esi
	pop eax
	call [RefreshWindowArea]
	bt dword [esi+window.activebuttons], 9
	jc DockWaterConstr_ClkUnselected
	push esi
	//movzx ebx, word [win_dockconstgui_elements.canals+10]	

	mov ebx, 4792
	extern numguisprites
	cmp dword [numguisprites], 0x4A
	jbe .nonewcanalicon
	extern guispritebase
	movzx ebx, word [guispritebase] // Calculate the sprite to use
	add ebx, 0x4A
.nonewcanalicon:


	mov ax, 1 + (cWinTypeConstrToolbar << 8)
 	xor edx, edx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 9
	mov word [selectedtool], 7
	ret

DockWaterConstr_ClkRiverBuild:
	push eax
 	push esi
 	xor esi, esi
	mov eax, 0x13
	extern generatesoundeffect
	call [generatesoundeffect]
	pop esi
	pop eax
	call [RefreshWindowArea]
	bt dword [esi+window.activebuttons], 11
	jc DockWaterConstr_ClkUnselected
	push esi
	//movzx ebx, word [win_dockconstgui_elements.canals+10]	

	mov ebx, 4792
	extern numguisprites
	cmp dword [numguisprites], 0x4A
	jbe .nonewcanalicon
	extern guispritebase
	movzx ebx, word [guispritebase] // Calculate the sprite to use
	add ebx, 0x4A
.nonewcanalicon:


	mov ax, 1 + (cWinTypeConstrToolbar << 8)
 	xor edx, edx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 11
	mov word [selectedtool], 8
	ret

	
DockWaterConstr_ClkAqueductBuild:
	push eax
 	push esi
 	xor esi, esi
	mov eax, 0x13
	extern generatesoundeffect
	call [generatesoundeffect]
	pop esi
	pop eax
	call [RefreshWindowArea]
	bt dword [esi+window.activebuttons], 10
	jc DockWaterConstr_ClkUnselected
	push esi
	//movzx ebx, word [win_dockconstgui_elements.canals+10]	
	mov ebx, 2593
	mov ax, 1 + (cWinTypeConstrToolbar << 8)
 	xor edx, edx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 10
	mov word [selectedtool], 9
	ret

DockWaterConstr_MouseDragUITick:
	push esi
	extern ScreenToLandscapeCoords
	call [ScreenToLandscapeCoords]
	pop esi
	cmp ax, -1
	je .havecoord
	and ax, 0xFFF0
	and cx, 0xFFF0
	cmp byte [selectedtool], 9
	je .bridge
.havecoord:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	ret
.bridge:
	mov bx, [dragtoolstartx]
	mov dx, [dragtoolstarty]
	mov bp, bx
	sub bp, ax
	jns .next0
	neg bp
.next0:
	mov di, dx
	sub di, cx
	jns .next1
	neg di
.next1:
	cmp di, bp
	ja .next2
	mov cx, dx
	jmp .havecoord
.next2:
	mov ax, bx
	jmp .havecoord


DockWaterConstr_MouseDragRelease:
	pusha
	mov ax, [dragtoolendx]
	mov bx, [dragtoolstartx]
	mov dx, [dragtoolstarty]
	mov cx, [dragtoolendy]
	

	cmp word [selectedtool], 7
	je near .dragwater
	cmp word [selectedtool], 8
	je near .dragwater
	cmp word [selectedtool], 9
	je near .aqueduct
		
	cmp ax, -1
	je .errordynamite
		
	shl edx, 16
	mov dx, bx
	mov bl, 1
	extern actionhandler,cleararea_actionnum
	dopatchaction cleararea
	cmp ebx, 80000000h
	je .errordynamite
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 10h
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.errordynamite:
	popa
	push esi
	mov ebx, -1
	extern AnimDynamiteCursorSprites
	mov esi, AnimDynamiteCursorSprites
	mov ax, 1 + (cWinTypeConstrToolbar << 8)
	xor edx, edx
	call [setmousetool]
	pop esi
	bts dword [esi+window.activebuttons], 5
	mov word [selectedtool], 2
	ret
	
	
.dragwater:
	cmp ax, -1
	je .dragwatererror
	and ax, 0xFF0	//endx
	and bx, 0xFF0	//startx
	and cx, 0xFF0	//endy
	and dx, 0xFF0	//starty
	cmp ax, bx
	jbe .noswapx
	xchg ax, bx
.noswapx:		//low xcoord in ax
	cmp cx, dx
	jbe .noswapy
	xchg cx, dx
.noswapy:		//low ycoord in cx
				//cx=low ycoord, dx=high ycoord
				//ax=low xcoord, bx=high xcoord
	sub dx, cx
	sub bx, ax
	shl dx, 4
	shr bx, 4
	mov dl, bl
	add dx, 0x101	//dl=x extent, dh=y extent

	mov bx, 0x103
	mov word [operrormsg1], ourtext(cantbuildcanalhere)
	extern actionmakewater_actionnum
	push esi
	push edi
	xor edi, edi
	cmp word [selectedtool], 8
	jne .noriver
	mov edi, 1
.noriver:
	dopatchaction actionmakewater
	pop edi
	pop esi
	
	cmp word [selectedtool], 8
	jne .noriverreselect
	call DockWaterConstr_ClkRiverBuild
	jmp short .dragwatererror
.noriverreselect:
	call DockWaterConstr_ClkCanalsBuild
	
.dragwatererror:
	popa
	ret

extern gettileinfo, errorpopup
.aqueduct:
	cmp ax, -1
	je near .aqueducterror
	pusha
	mov word [operrormsg1], 0x5015
	call [gettileinfo]
	test di, 0x10
	jnz NEAR .badslope
	movzx edi, di
	cmp BYTE [aquaductbridgeendslopetbl+edi], 1
	jne NEAR .badslope
	popa
	xchg cx, dx
	xchg ax, bx
	pusha
	call [gettileinfo]
	test di, 0x10
	jnz NEAR .badslope
	movzx edi, di
	cmp BYTE [aquaductbridgeendslopetbl+edi], 1
	jne .badslope
	popa
	shl dx, 4
	shr bx, 4
	mov dl, bl
	mov bx, 0x403
	mov di, 0
	mov esi, 0x10048
	call [actionhandler]
	cmp ebx, 80000000h
	je .bad
	push eax
	push esi
	mov esi, -1
	push ebx
	mov bx, ax
	mov eax, 25h
	call [generatesoundeffect]
	pop ebx
	pop esi
	pop eax
.end:
	popa
	ret
.badslope:
	mov word [operrormsg2], 0x5009
	popa
.bad:
	mov bx, [operrormsg1]
	mov dx, [operrormsg2]
	xor ax, ax
	xor cx, cx
	call dword [errorpopup]
	popa
	mov ebx, 0x80000000
.aqueducterror:
	ret

varb aquaductbridgeendslopetbl	//where exactly two bits are set 0-3
//3,5,9,6,10,12
// 0 1 2 1,2
db 0,0,0,1	//0
db 0,1,1,0	//4
db 0,1,1,0	//8
db 1,0,0,0	//4,8
endvar

guiwindow win_waterconstgui,152,36
	guicaption cColorSchemeDarkGreen, ourtext(waterconstrwin)
	guiele dock,cWinElemDummyBox,cColorSchemeDarkBlue,x,0,x2,0,y,0,y2,0,data,0
	guiele shipdepot,cWinElemDummyBox,cColorSchemeDarkBlue,x,0,x2,0,y,0,y2,0,data,0
	guiele buoy,cWinElemDummyBox,cColorSchemeDarkBlue,x,0,x2,0,y,0,y2,0,data,0
	guiele dynamite,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,w,21,y,14,h,21,data,703
	guiele lowerland,cWinElemSpriteBox,cColorSchemeDarkGreen,x,22,w,21,y,14,h,21,data,695
	guiele raiseland,cWinElemSpriteBox,cColorSchemeDarkGreen,x,44,w,21,y,14,h,21,data,694
	guiele purchaseland,cWinElemDummyBox,cColorSchemeDarkBlue,x,0,x2,0,y,0,y2,0,data,0
	guiele canals,cWinElemSpriteBox,cColorSchemeDarkGreen,x,66,w,21,y,14,h,21,data,0
	guiele aqueduct,cWinElemSpriteBox,cColorSchemeDarkGreen,x,88,w,41,y,14,h,21,data,2598
	guiele river,cWinElemSpriteBox,cColorSchemeDarkGreen,x,130,w,21,y,14,h,21,data,4083
endguiwindow

exported CreateScenWaterConstrWindow
	bts dword [esi+window.activebuttons], 24

	mov bx, [esi+window.id]
	mov al, [esi+window.type]
	or al, 0x80
	mov ah, 24
	call [invalidatehandle]
		
	mov cx, cWinTypeConstrToolbar
	xor edx, edx
	extern FlashWindow
	call [FlashWindow]
	jnz .windowopen
	
	mov eax, 286 + (22<<16) // x + (y << 16)
	mov ebx, win_waterconstgui_width + (win_waterconstgui_height << 16)
	mov cx, cWinTypeConstrToolbar	// window type
	mov dx, 0x90					// operation class offset
	mov ebp, 1						// function number
	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], win_waterconstgui_elements
	mov byte [esi+window.data], 24
	or word [esi+window.flags], 5
	ret
.windowopen:
	mov byte [esi+window.data], 24
	or word [esi+window.flags], 5
	ret

