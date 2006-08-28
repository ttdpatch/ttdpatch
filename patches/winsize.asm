
#include <std.inc>
#include <proc.inc>
#include <window.inc>
#include <textdef.inc>
#include <ptrvar.inc>

extern BringWindowToForeground,CreateTooltip,DestroyWindow,FindWindow
extern RefreshWindowArea,TabClicked,TitleBarClicked,currscreenupdateblock
extern dfree,dmalloc,errorpopup,fillrectangle,redrawscreen
extern win_newshistory_constraints,win_newshistory_elements
extern windowstack,CheckBoxClicked
extern grfmodflags


uvard winelemdrawptrs,cWinElemMax+1,s
uvard windowsizesbufferptr

uvarw guispritebase,1,s
var numguisprites, dd 3+12

var depotscalefactor
	dw 29

global drawresizebox
drawresizebox:
	mov word [ebp+windowbox.extra], 682
	mov ax, [guispritebase]
	cmp ax, -1
	jz .noextrasprites
	mov [ebp+windowbox.extra], ax
.noextrasprites:
	jmp [winelemdrawptrs+4*cWinElemSpriteBox]

global windowclicked
windowclicked:
	mov ebp, [0xFFFFFFFF]
ovar temp_windowclicked_element, -4
	or cx, cx
	js .nothingclicked
	cmp byte [ebp+windowbox.type], cWinElemSizer
	jnz .notsizer
	cmp byte [rmbclicked], 0
	jne .rmb
	call BeginResizeWindow
	mov cx, -1
	ret
.rmb:
	pusha
	mov ax, ourtext(sizertooltip)
	call [CreateTooltip]
	popa
	mov cx, -1
.notsizer:
	cmp byte [ebp+windowbox.type], cWinElemTab
	je near TabClicked
	cmp byte [ebp+windowbox.type], cWinElemTitleBar
	je near TitleBarClicked
	cmp byte [ebp+windowbox.type], cWinElemCheckBox
	je near CheckBoxClicked
.nothingclicked:
	ret

//IN: esi=window
//OUT: [esi+window.elemlistptr] points to a copy of the element list
CopyWindowElementList:
	pusha
	
	push edi
	push esi
	xor ecx, ecx
	mov esi, [esi+window.elemlistptr]
.countloop:
	cmp byte [esi+windowbox.type], cWinElemLast
	je .done
	inc ecx
	add esi, windowbox_size
	jmp .countloop
.done:
	shl ecx, 2
	lea ecx, [ecx*3]
	inc ecx
	pop esi
	push esi
	push ecx
	call dmalloc
	jc .fail
	mov esi, [esi+window.elemlistptr]
	pop ecx
	push edi
	rep movsb
	pop edi
	pop esi
	mov [esi+window.elemlistptr], edi
	pop edi

	popa
	or word [esi+window.flags], 1000h
	clc
	ret
.fail:
	pop ecx
	pop esi
	pop edi
	mov word [operrormsg2], ourtext(outofdynmem)
	popa
	stc
	ret

global CloseWindow
CloseWindow:
	mov cl, [esi+window.type]
	mov dx, [esi+window.id]
	test word [esi+window.flags], 1000h
	jz .nofree
	pusha
	mov edi, [esi+window.elemlistptr]
	call dfree
	popa
.nofree:
	ret

BeginResizeWindow:
	mov word [tmpdx], 0
	mov word [tmpdy], 0
	test word [esi+window.flags], 800h
	jnz .alreadycopied
	call CopyWindowElementList
	jc .fail
	or word [esi+window.flags], 800h
.alreadycopied:

	or word [esi+window.flags], 400h
	bts word [uiflags], 7	// window is being dragged (althoug this is of course not entirely correct)
	push edi
	push ecx
	xor ecx, ecx
	mov edi, [esi+window.elemlistptr]
.searchloop:
	cmp byte [edi+windowbox.type], cWinElemSizer
	je .found
	inc cx
	add edi, windowbox_size
	jmp .searchloop
.found:
	bts dword [esi+window.activebuttons], ecx
	pop ecx
	pop edi

	pusha
	mov eax, [mousecursorscrx]
	mov [sizewindowprevx], eax
	mov eax, [esi+window.width]
	mov [realwinsize], eax
	call [BringWindowToForeground]
	popa
	
	mov cl, [esi+window.type]
	mov dx, [esi+window.id]
	push cx
	push dx
	mov cl, 3Fh
	xor dx, dx
	call [FindWindow]
	call [DestroyWindow]
	pop dx
	pop cx
	call [FindWindow]
	ret
.fail:
	pusha
	xor ax, ax
	xor cx, cx
	mov bx, ourtext(cantresize)
	mov dx, ourtext(outofdynmem)
	call [errorpopup]
	popa
	ret

uvarw sizewindowprevx
uvarw sizewindowprevy
uvard realwinsize

global procwindowdragmode
procwindowdragmode:
	test word [esi+window.flags], 400h
	jnz .windowsizing

	test word [esi+window.flags], 8
	ret

.endsizing:
	and word [esi+window.flags], ~400h
	btr word [uiflags], 7

	push edi
	push ecx

	push eax
	push edx
	
	movzx edi, byte [esi+window.type]
	movzx edx, word [esi+window.id]
	mov ax, [esi+window.width]
	mov cx, [esi+window.height]
	call SaveWindowSize

	pop edx
	pop eax

	xor ecx, ecx
	mov edi, [esi+window.elemlistptr]
.searchloop:
	cmp byte [edi+windowbox.type], cWinElemSizer
	je .found
	inc cx
	add edi, windowbox_size
	jmp .searchloop
.found:
	btr dword [esi+window.activebuttons], ecx
	pop ecx
	pop edi

	call [RefreshWindowArea]
	stc
	ret

.windowsizing:
	pop ebx
	cmp byte [lmbstate], 0
	jz .endsizing
	
	mov ax, [mousecursorscrx]
	mov cx, [mousecursorscry]
	
	push ax
	push cx
	sub ax, [sizewindowprevx]
	sub cx, [sizewindowprevy]
	add ax, [realwinsize]
	add cx, [realwinsize+2]
	mov [realwinsize], ax
	mov [realwinsize+2], cx
	call [RefreshWindowArea]

	push esi
	push edx
	push ebp
	push edi

	mov dh, cWinDataSizer
	call FindWindowData
	//now edi points to the sizer window data (or carry set if not found)
	jc .nosizerdata
	push edi
	mov edi, [edi+4]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi]
	mov bx, cx
	call ResizeWindowElements
	popa
	push ax
	mov al, [esi+window.itemsoffset]
	add al, [esi+window.itemsvisible]
	cmp al, [esi+window.itemstotal]
	jbe .itemokay
	mov byte [esi+window.itemsoffset], 0
	mov al, [esi+window.itemstotal]
	sub al, [esi+window.itemsvisible]
	js .itemokay
	mov [esi+window.itemsoffset], al
.itemokay:
	pop ax
.nosizerdata:

	pop edi
	pop ebp
	pop edx
	pop esi
	
	mov [esi+window.width], ax
	mov [esi+window.height], cx

	pusha
	mov edi, esi
	mov dl, cWinEventResize
	mov si, [edi+window.opclassoff]
	cmp si, -1
	jz .winfunc
	mov ebx, [edi+window.function]
	movzx esi, si
	mov ebp, [ophandler+esi]
	call dword [ebp+4]
	jmp .calldone
.winfunc:
	call dword [edi+window.function]
.calldone:
	popa

	call [RefreshWindowArea]
	pop word [sizewindowprevy]
	pop word [sizewindowprevx]
	clc
	ret

//in: ESI=window
//    EDI=constraints (for each window element a byte with bits, bit set means move when size changes; bit0=x1, bit1=x2, bit2=y1, bit3=y2)
//    AX,BX=new width&height of window
uvarw tmpdx
uvarw tmpdy
ResizeWindowElements:
	push esi
	push edi
	push ax
	push bx
	push cx
	push dx
	sub ax, [esi+window.width]
	sub bx, [esi+window.height]
	mov esi, [esi+window.elemlistptr]
	call ResizeWindowElementsDelta
	pop dx
	pop cx
	pop bx
	pop ax
	pop edi
	pop esi
	ret
	
//same as above, only esi is a pointer to the first windowelement, and ax,bx are size changes instead of absolute sizes
ResizeWindowElementsDelta:
	push ax
	push bx
	add ax, [tmpdx]
	add bx, [tmpdy]
	mov word [tmpdx], 0
	test ax, 1
	jz .correctdx
	mov word [tmpdx], 1
.correctdx:
	mov word [tmpdy], 0
	test bx, 1
	jz .correctdy
	mov word [tmpdy], 1
.correctdy:	
	mov cx, ax
	and cx, 0xfffe
	sar cx, 1
	mov dx, bx
	and dx, 0xfffe
	sar dx, 1
	pop bx
	pop ax
	
.loop:
	cmp byte [esi+windowbox.type], cWinElemLast
	je .done

	test byte [edi], 1
	jz .nox1
	add [esi+windowbox.x1], ax
.nox1:
	test byte [edi], 2
	jz .nox2
	add [esi+windowbox.x2], ax
.nox2:
	test byte [edi], 4
	jz .noy1
	add [esi+windowbox.y1], bx
.noy1:
	test byte [edi], 8
	jz .noy2
	add [esi+windowbox.y2], bx
.noy2:
	test byte [edi], 10h
	jz .nox1s
	add [esi+windowbox.x1], cx
.nox1s:
	test byte [edi], 20h
	jz .nox2s
	add [esi+windowbox.x2], cx
.nox2s:
	test byte [edi], 40h
	jz .noy1s
	add [esi+windowbox.y1], dx
.noy1s:
	test byte [edi], 80h
	jz .noy2s
	add [esi+windowbox.y2], dx
.noy2s:
	
	add esi, windowbox_size
	inc edi
	jmp .loop
.done:
	ret

//IN: esi=window, edi=pointer to size constraints, ax,cx=new width and height of window
//OUT: ax,cx=new width and height of window
HandleSizeConstraints:
	push ebp
	mov ebp, [esi+window.elemlistptr]
	
	cmp ax, [edi+0+0]
	jge .widthenough
	mov ax, [edi+0+0]
.widthenough:
	cmp ax, [edi+0+2]
	jle .widthsenough
	mov ax, [edi+0+2]
.widthsenough:
	cmp byte [edi+0+4], 1
	jz .widthok

	push cx
	sub ax, [edi+0+6]
	push edx
	movsx edx, byte [edi+0+5]
	cmp edx, -1
	je .nocount1
	shl edx, 2
	lea edx, [edx*3]
.nocount1:
	mov cl, [edi+0+4]
	div cl
	cmp edx, -1
	je .nocount2
	mov [esi+window.itemsvisible], al
	mov [ebp+edx+10], al
.nocount2:
	mul cl
	pop edx
	add ax, [edi+0+6]
	pop cx

.widthok:

	cmp cx, [edi+8+0]
	jge .heightenough
	mov cx, [edi+8+0]
.heightenough:
	cmp cx, [edi+8+2]
	jle .heightsenough
	mov cx, [edi+8+2]
.heightsenough:
	cmp byte [edi+8+4], 1
	jz .heightok
	sub cx, [edi+8+6]
	push ax
	push edx
	movsx edx, byte [edi+8+5]
	cmp edx, -1
	je .nocount3
	shl edx, 2
	lea edx, [edx*3]
.nocount3:
	mov ax, cx
	mov cl, [edi+8+4]
	div cl
	cmp edx, -1
	je .nocount4
	mov [esi+window.itemsvisible], al
	mov [ebp+edx+11], al
.nocount4:
	mul cl
	mov cx, ax
	pop edx
	pop ax
	add cx, [edi+8+6]
.heightok:
	pop ebp
	ret

//IN: esi=window
//    dh=datatype to find
//OUT: edi=pointer to data, or carry set if not found
global FindWindowData
FindWindowData:
	mov dl, cWinElemExtraData
	mov edi, [esi+window.elemlistptr]

	cmp byte [esi+window.type], 0x12
	je .isdepot

.loop:
	cmp byte [edi], cWinElemLast
	je .fail
	cmp word [edi], dx
	je .found
	add edi, 12
	jmp .loop

.found:
	add edi, 2
	clc
	ret

.isdepot:
	push edx // Used to work out the sub type of depot
	movzx edx, word [esi+window.id]
	mov bl, [landscape4(dx, 1)]
	and bl, 0xF0
	cmp bl, 0x10
	pop edx
	jne .loop // Is not a rail depot so use old code

	bt dword [grfmodflags], 3
	jnc .loop
	mov dword [tmpAddress+2], depotwindowconstraints
	mov dword [tmpAddress+6], traindepotwindowsizes32
	mov edi, tmpAddress
	jmp .found

.fail:
	stc
	ret

var tmpAddress // Used to stop a slight oversight by me above (Lakie)
	db cWinElemExtraData, cWinDataSizer
	dd 0x0, 0x0

global drawwindowelements
drawwindowelements:
	test word [esi+window.flags], 2000h
	jnz .alreadycopied
	or word [esi+window.flags], 2000h
	test word [esi+window.flags], 800h
	jnz .alreadycopied
	push edx
	push eax
	push ecx
	movzx edx, word [esi+window.id]
	movzx edi, byte [esi+window.type]
	call RestoreWindowSize
	jc .fail
	call CopyWindowElementList
	jc .fail
	or word [esi+window.flags], 800h

	mov dh, cWinDataSizer
	call FindWindowData
	//now edi points to the sizer window data (or carry set if not found)
	jc .nosizerdata
	push edi
	mov edi, [edi+4]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi]
	mov bx, cx
	call ResizeWindowElements
	popa
.nosizerdata:
	mov [esi+window.width], ax
	mov [esi+window.height], cx
	call [RefreshWindowArea]

.fail:
	pop ecx
	pop eax
	pop edx
.alreadycopied:
	mov ebp, [esi+window.elemlistptr]
	mov edi, [currscreenupdateblock]
	ret
	
//Called to check if a window element can be clicked
//IN: dl = element type
//OUT: zero-flag set if this element cannot be clicked
global windowclickedelement
windowclickedelement:
	cmp dl, cWinElemDummyBox
	jz .return
	cmp dl, cWinElemFrameWithText
	jz .return
	cmp dl, cWinElemExtraData
//	jz .return
.return:
	ret

uvard vehlistwinsizesptr

//IN: edi = window-type, edx = window-ID
//OUT: ax,cx=width,height
RestoreWindowSize:
	cmp di, 0x09
	jb .dontsave
	cmp di, 0x0C
	jbe .dosave
	cmp di, 0x12
	je .dosave
	
.dontsave:
	stc
	ret
	
.dosave:
	push esi
	push ebx
	cmp di, 0x12
	je .isdepot
	mov esi, edi
	sub esi, 0x09
	shl esi, 2
	jmp .isnodepot
.isdepot:
	mov esi, 4
	mov bl, [landscape4(dx,1)]
	and bl, 0xF0
	cmp bl, 10h
	jz .gotit
	inc esi
	cmp bl, 20h
	jz .gotit
	inc esi
	cmp byte [landscape5(dx,1)], 0x4C
	jae .gotit
	inc esi
.gotit:
	shl esi, 2
	// Depots have a slightly different code because of the 32px and 29px variants
	cmp esi, 0x10
	je .raildepot
.isnodepot:
	add esi, [vehlistwinsizesptr]
	//now esi points to the correct place in the array
	mov ax, [esi]
	mov cx, [esi+2]
	pop ebx
	pop esi
	cmp ax, 0
	jz .fail
	clc
	ret
.fail:
	stc
	ret

.raildepot:
	add esi, [vehlistwinsizesptr]
	//now esi points to the correct place in the array
	mov ax, [esi]
	mov cx, [esi+2]
	pop ebx
	cmp ax, 0
	jz .lfail

	push ebx
	sub ax, 59
	xor ebx, ebx
	mov bl, [depotscalefactor]
	cmp bl, 29
	je .lcontinue
	cmp bl, 32
	je .lcontinue
	jmp .lbadfactor

.lcontinue:
	div bl
	xor ah, ah // Removes any faults from devision
	mov bl, 29
	bt dword [grfmodflags], 3
	jnc .not32
	add bl, 3

.not32:
	mul bl
	add ax, 59
	pop ebx
	pop esi
	clc
	ret

.lbadfactor:
	push ax
	mov bl, 29
	div bl
	cmp ah, 0
	je .lend
	mov bl, 32
.lend:
	pop ax
	jmp .lcontinue

.lfail:
	bt dword [grfmodflags], 3
	jnc .lnot32
	add esi, 0x10
.lnot32:
	sub esi, [vehlistwinsizesptr]
	mov ax, [origwindowsizes+esi]
	mov cx, [origwindowsizes+esi+2]
	pop esi
	clc
	ret
	
//IN: edi = window-type, edx = window-ID
//	ax,cx = width,height
SaveWindowSize:
	cmp di, 0x09
	jb .dontsave
	cmp di, 0x0C
	jbe .dosave
	cmp di, 0x12
	je .dosave
	
.dontsave:
	ret
.dosave:
	push esi
	push ebx
	cmp di, 0x12
	je .isdepot
	mov esi, edi
	sub esi, 0x09
	shl esi, 2
	jmp .isnodepot
.isdepot:
	mov esi, 4
	mov bl, [landscape4(dx,1)]
	and bl, 0xF0
	cmp bl, 10h
	jz .gotit
	inc esi
	cmp bl, 20h
	jz .gotit
	inc esi
	cmp byte [landscape5(dx,1)], 0x4C
	jae .gotit
	inc esi
.gotit:
	shl esi, 2

	// Rail depots have a little extra code
	cmp esi, 0x10
	jne .isnodepot
	mov byte [depotscalefactor], 29
	bt dword [grfmodflags], 3
	jnc .isnodepot
	add byte [depotscalefactor], 3

.isnodepot:
	add esi, [vehlistwinsizesptr]
	//now esi points to the correct place in the array
	mov [esi], ax
	mov [esi+2], cx
	pop ebx
	pop esi
	ret

var defaultwindowsizes
	dd 0,0,0,0,0,0,0,0
	dw 248, 234
	dw 351, 224
	
global ResetDefaultWindowSizes
ResetDefaultWindowSizes:
	mov esi, defaultwindowsizes
	mov edi, [windowsizesbufferptr]
	mov ecx, 40
	rep movsb
	call LoadWindowSizesFinish

	mov cl, 0x08	// cWinTypeMap
	xor dx, dx
	call [FindWindow]
	jz .mapwindownotopen
	mov edi, [mapwindowelementsptr]
	mov ax, [edi+12*13+8]
	inc ax
	shl eax, 16
	mov ax, [edi+12*13+4]
	inc ax
	mov [esi+window.width], eax
.mapwindownotopen:

	mov cl, 0x2A
	mov dx, 101
	call [FindWindow]
	jz .newshistnotopen
	mov ax, [win_newshistory_elements+12*4+8]
	inc ax
	shl eax, 16
	mov ax, [win_newshistory_elements+12*4+4]
	inc ax
	mov [esi+window.width], eax
	mov byte [esi+window.itemsvisible], 5
	mov byte [win_newshistory_elements+12*2+11], 5
.newshistnotopen:

	call ResetOpenWindows
	ret

var origwindowsizes //train,rv,ship,air
//lists
	dw 325,208
	dw 260,208
	dw 260,170
	dw 260,170
//depots
	dw 349,110
	dw 315,68
	dw 305,74
	dw 331,74
	dw 379,110 // 32px depots

ResetOpenWindows:
	mov esi, [windowstack]

.windowloop:
	cmp esi, [windowstacktop]
	jnb near .done
	
	test word [esi+window.flags], 800h
	jz .nextwindow	//not resized
	
	mov al, [esi+window.type]
	cmp al, 0x09
	jb .nextwindow
	cmp al, 0x0C
	jbe .vehlist
	cmp al, 0x12
	jne .nextwindow
	//depot's
	movzx ebx, word [esi+window.opclassoff]
	sub ebx, 80h
	shr ebx, 1
	add ebx, 4*4
	jmp .resizewindow
.vehlist:
	sub al, 0x09
	movzx ebx, al
	shl ebx, 2

.resizewindow:

	cmp ebx, 0x10
	jne .notraildepot
	bt dword [grfmodflags], 3
	jnc .notraildepot
	add ebx, 0x10
.notraildepot:

	mov ax, [origwindowsizes+ebx]
	mov cx, [origwindowsizes+ebx+2]
	
	mov dh, cWinDataSizer
	call FindWindowData
	jc .nosizerdata
	push edi
	mov edi, [edi+4]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi]
	mov bx, cx
	call ResizeWindowElements
	popa
.nosizerdata:
	mov [esi+window.width], ax
	mov [esi+window.height], cx
.nextwindow:
	add esi, window_size
	jmp .windowloop
	
.done:
	call redrawscreen
	ret

// Used to update the depot windows for trains
global ResizeOpenWindows
ResizeOpenWindows:
	mov esi, [windowstack]

.windowloop:
	cmp esi, [windowstacktop]
	jnb near .done
	
	test word [esi+window.flags], 800h
	jz near .nextwindow	//not resized
	
	mov al, [esi+window.type]
	cmp al, 0x0C
	jbe .nextwindow
	cmp al, 0x12
	jne .nextwindow
	//depot's
	movzx ebx, word [esi+window.opclassoff]
	sub ebx, 80h
	shr ebx, 1
	add ebx, 4*4

	cmp ebx, 0x10
	jne .nextwindow

	mov ax, [esi+window.width] // Get the current height and width
	mov cx, [esi+window.height]
	
	// Calculate the number of units from the length
	sub ax, 59
	mov bl, [depotscalefactor]
	div bl // This gives us the number of units to show

	// Calculate new width of the window
	mov bl, 29
	bt dword [grfmodflags], 3
	jnc .lnot32
	add bl, 3 // 32px-29px = 3px more
.lnot32:
	mul bl // Gives the new total length of all the units
	add ax, 59 // Adds the extra window bits on to the total length of the window

	mov dh, cWinDataSizer
	call FindWindowData
	jc .nosizerdata
	push edi
	mov edi, [edi+4]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi]
	mov bx, cx
	call ResizeWindowElements
	popa
.nosizerdata:
	mov [esi+window.width], ax
	mov [esi+window.height], cx
.nextwindow:
	add esi, window_size
	jmp .windowloop
	
.done:
	// Updates the scale factor of the game
	push bx
	mov bl, 29
	bt dword [grfmodflags], 3
	jnc .lnot32x
	add bl, 3 // 32px-29px = 3px more
.lnot32x:
	mov byte [depotscalefactor], bl
	pop bx

	call redrawscreen
	ret

global SaveWindowSizesPrepare
SaveWindowSizesPrepare:
	mov edi, [windowsizesbufferptr]
	mov esi, [mapwindowelementsptr]
	mov cx, [esi+12*13+8]
	inc cx
	shl ecx, 16
	mov cx, [esi+12*13+4]
	inc cx
	mov [edi+32], ecx

	mov cx, [win_newshistory_elements+12*4+8]
	inc cx
	shl ecx, 16
	mov cx, [win_newshistory_elements+12*4+4]
	inc cx
	mov [edi+36], ecx

	mov esi, [vehlistwinsizesptr]
	xor ecx, ecx
	mov cl, 32
	rep movsb
	ret

global LoadWindowSizesFinish
LoadWindowSizesFinish:
	mov esi, [windowsizesbufferptr]
	mov edi, [mapwindowelementsptr]
	push esi
	mov eax, [esi+32]
	mov esi, edi
	mov ebx, eax
	shr ebx, 16
	sub ax, [edi+12*13+4]
	dec ax
	cmp bx, 234
	jae .correctheight
	mov bx, 234
.correctheight:
	sub bx, [edi+12*13+8]
	dec bx
	mov edi, mapwindowconstraints
	call ResizeWindowElementsDelta
	pop esi

	push esi
	mov eax, [esi+36]
	cmp eax, 0
	jz .notpresent
	mov esi, win_newshistory_elements
	mov ebx, eax
	shr ebx, 16
	sub ax, [win_newshistory_elements+12*4+4]
	dec ax
	sub bx, [win_newshistory_elements+12*4+8]
	dec bx
	mov edi, win_newshistory_constraints
	call ResizeWindowElementsDelta
.notpresent:
	pop esi

	mov edi, [vehlistwinsizesptr]
	xor ecx, ecx
	mov cl, 32
	rep movsb
	
	ret

//And now code to make some existing windows resizable:

uvard mapwindowelementsptr

var mapwindowconstraints
	db 0000b, 0010b, 0011b
	db 1010b, 1010b, 0011b
	db 0011b, 0011b, 0011b
	db 0011b, 0011b, 0011b
	db 1110b, 1111b, 0
	db 0011b, 1011b
var mapwindowsizes
	dw 248, 2048, 1, 0
	dw 234, 2048, 1, 0

var tmpwindowsizes
	dw 100, 1000, 1, 0
	dw 100, 1000, 1, 0

var vehlistwindowconstraints
	db 0000b, 0010b, 1010b
	db 1011b, 00101100b, 00011110b
	db 1111b, 1111b, 0

var rvlistwindowsizes
	dw 160, 260	//X
	db 1, 0
	dw 0
	dw 52, 2048	//Y
	db 26, 2
	dw 26

var trainlistwindowsizes
	dw 325-3*29, 2048	//X
	db 1, 0
	dw 0
	dw 52, 2048	//Y
	db 26, 2
	dw 26
var shipairlistwindowsizes
	dw 160, 260	//X
	db 1, 0
	dw 0
	dw 62, 2048	//Y
	db 36, 2
	dw 26

var vehlistwindowsizes
	dd trainlistwindowsizes,rvlistwindowsizes,shipairlistwindowsizes,shipairlistwindowsizes

var depotwindowconstraints
	db 00000000b, 00000010b, 00001010b
	db 00001011b, 00001011b, 00101100b
	db 00011110b, 00001111b, 0
var rvdepotwindowsizes
	dw 315-3*56, 2048//X
	db 56, 2
	dw 35
	dw 68-14, 2048	//Y
	db 14, 2
	dw 26
var shipdepotwindowsizes
	dw 305-90, 2048	//X
	db 90, 2
	dw 35
	dw 74-24, 2048	//Y
	db 24, 2
	dw 26
var aircraftdepotwindowsizes
	dw 315-74, 2048	//X
	db 74, 2
	dw 35
	dw 68, 2048	//Y
	db 24, 2
	dw 26	
var traindepotwindowsizes
	dw 349-6*29, 2048//X
	db 29, -1 
	dw 1
	dw 110-4*14, 2048//Y
	db 14 ,2
	dw 26
var traindepotwindowsizes32
	dw 379-6*32, 2048//X
	db 32, -1 
	dw 59
	dw 110-4*14, 2048//Y
	db 14 ,2
	dw 26

//Functions to make the mini-map window resizable:
global openmapwindowpre
openmapwindowpre:
	push edi
	mov edi, [mapwindowelementsptr]
	mov bx, [edi+12*13+8]
	inc bx
	shl ebx, 16
	mov bx, [edi+12*13+4]
	inc bx
	mov dx, -1
	pop edi
	ret

global openmapwindowpost
openmapwindowpost:
	bts dword [esi+window.activebuttons], 5
	bts dword [esi+window.activebuttons], 11
	or word [esi+window.flags], 800h
	ret

global openmapwindowxadjust
openmapwindowxadjust:
	push ax
	mov ax, [esi+window.width]
	sub ax, 28
	shl ax, 4
	sub cx, ax
	pop ax

	sar cx, 1
	ret

global openmapwindowyadjust
openmapwindowyadjust:
	push ax
	mov ax, [esi+window.height]
	sub ax, 62
	shl ax, 4
	sub dx, ax
	pop ax

	sar dx, 1
	ret

global drawmapwindow
drawmapwindow:
	pusha
	mov ebp, cColorSchemeBrown
	mov bp, [colorschememap+8*ebp+3]
	mov ax, [esi+window.width]
	add ax, [esi+window.x]
	sub ax, 12
	mov bx, ax
	mov cx, [esi+window.height]
	add cx, [esi+window.y]
	sub cx, 13
	mov dx, cx
	add dx, 12
	push ax
	push cx
	push bp
	call [fillrectangle]
	pop bp
	pop cx
	pop ax
	mov bx, [esi+window.width]
	add bx, [esi+window.x]
	mov dx, cx
	call [fillrectangle]
	popa
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	ret

//Functions to make the vehicle lists resizable:
lastvehdrawn:
	movzx ax, al
.hasword:
	push edx
	mov dl, [esi+window.itemsvisible]
	neg dl
	movzx eax, ax
	cmp bl, dl
	pop edx
	jnl .nojump
	add dword [esp+4], eax
.nojump:
	pop eax
	ret

global lastrailvehdrawn
lastrailvehdrawn:
	push eax
	mov al,0xFF
ovar railvehoffset,-1
	jmp lastvehdrawn

global lastroadvehdrawn
lastroadvehdrawn:
	push eax
	mov al,0xFF
ovar roadvehoffset,-1
	jmp lastvehdrawn

global lastairvehdrawn
lastairvehdrawn:
	push eax
	mov ax, 0xFFFF
ovar airvehoffset, -2
	jmp lastvehdrawn.hasword

global lastshipvehdrawn
lastshipvehdrawn:
	push eax
	mov ax, 0xFFFF
ovar shipvehoffset, -2
	jmp lastvehdrawn.hasword

#if 0
global drawtrainlist
drawtrainlist:
	add dx, 6
	mov ax, [esi+window.width]
	sub ax, 35
	mov bl, 29
	div bl
	ret
#endif

//Functions to make the RV depot windows resizable:
global lastdepotcoldrawn
lastdepotcoldrawn:
	push esi
	push edi
	push eax
	push dx
	mov esi, [esi+window.elemlistptr]
	mov ax, [esi+2*12+windowbox.x2]
	inc ax
	mov dx, ax
	push bx
	mov bl, [esi+2*12+10]
	div bl
	movzx ax, al
	add cx, ax
	mov al, bl
	pop bx
	inc bh
	mov edi, [esp+14]
	mov [edi+2], al
	mov [edi+8], dx
	pop dx
	pop eax
	pop edi
	pop esi
	ret

global lastdepotrowdrawn
lastdepotrowdrawn:
	push esi
	push ebx
	push eax
	mov esi, [esi+window.elemlistptr]
	mov al, [esi+2*12+10]
	mov ah, [esi+2*12+11]
	mul ah
	neg ax
	movsx bx, bl
	cmp bx, ax
	pop eax
	jnl .nojump
	movzx eax, al
	add dword [esp+8], eax
.nojump:
	pop ebx
	pop esi
	mov eax,[esp+4]
	ret 4

global lasttraindepotrowdrawn
lasttraindepotrowdrawn:
	push esi
	dec bl
	push ebx
	push eax
	jns .jump
	mov esi, [esi+window.elemlistptr]
	mov al, [esi+2*12+10]
	mov ah, [esi+2*12+11]
	mul ah
	neg ax
	movsx bx, bl
	cmp bx, ax
	jl .jump
	pop eax
	pop ebx
	pop esi
	ret
.jump:
	pop eax
	pop ebx
	pop esi
	add dword [esp], 0x42
	ret

global depotdrawoffset
depotdrawoffset:
	push edi
	mov edi, [esi+window.elemlistptr]
	movzx cx, byte [edi+2*12+10]
	imul bx, cx
	pop edi
	mov cx, [esi+window.x]
	ret

global calcdepottotalitems
calcdepottotalitems:
	mov edi, [esi+window.elemlistptr]
	movzx bx, byte [edi+2*12+10]
	dec bl
	add ax, bx
	inc bl
	mov bl, byte [edi+2*12+10]
	ret

global depotwindowxytoveh.checkx
global depotwindowxytoveh.checky
global depotwindowxytoveh.calcoffset
depotwindowxytoveh:
.checkx:
	push dx
	push edi
	mov edi, [esi+window.elemlistptr]
	mov dl, byte [edi+2*12+10]
	mov byte [depotcolumn], dl
	cmp al, dl
	pop edi
	pop dx
	jnb .return1
	xchg ax, bx
	ret

.checky:
	push dx
	mov edi, [esi+window.elemlistptr]
	mov dl, byte [edi+2*12+11]
	cmp al, dl
	pop dx
	jnb .return1
	mov dl, bh
	ret

.calcoffset:
	xor ah, ah
	imul ax, 5
ovar depotcolumn, -1
	ret
	
.return1:
	pop ebp
	mov al, 1
	ret

// Replaced by new one in trainwins.asm
#if 0
global CalcTrainDepotWidth
CalcTrainDepotWidth:
	mov ax, [esi+window.width]
	sub ax, 59
	push bx
	mov bl, 29
	div bl
	pop bx

	ret
#endif

global traindepotwindowhandler
traindepotwindowhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventResize
	je .resizewindow
	cmp dl, cWinEventRedraw
	ret

.resizewindow:
	bt dword [grfmodflags], 3
	jc .resizewindowx

	pop ecx
	mov ax, [esi+window.width]
	dec ax
	mov cl, 29
	div cl
	cmp al, 33
	jna .gotsize
	mov al, 33
.gotsize:
	sub al, 6
	movzx ax, al
	add ax, statictext(depotsize4)
	call [CreateTooltip]
	ret

.resizewindowx:
	pop ecx
	mov ax, [esi+window.width]
	sub ax, 0x3B	// Removes the constant window widths
	mov cl, 32	// Get the number of slots
	div cl
	cmp al, 31	// Is it greater than 30?
	jna .gotsizex
	mov al, 31
.gotsizex:
	sub al, 4	// Changed values to get right results ingame (...)
	movzx ax, al
	add ax, statictext(depotsize4)
	call [CreateTooltip]
	ret
