#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <window.inc>
#include <view.inc>

extern BringWindowToForeground,CreateTooltip,DestroyWindow,FindWindow
extern RefreshWindowArea,TabClicked,TitleBarClicked,currscreenupdateblock
extern dfree,dmalloc,errorpopup,fillrectangle,redrawscreen
extern win_newshistory_constraints,win_newshistory_elements
extern windowstack,CheckBoxClicked,patchflags
extern grfmodflags,CargoPacketWin_elements._sizer_constraints

ptrvardec window2ofs

uvard windowsizesbufferptr

vard winelemdrawptrs
	extern DrawWinElemTab,DrawWinElemTabButton
	extern DrawWinElemCheckBox
	// first few entries are TTD's procs, will be set in dogeneralpatching
	dd 0			// 00: dummy box
	dd 0			// 01: sprite box
	dd 0			// 02: sprite box next active
	dd 0			// 03: text box
	dd 0			// 04: text box next active
	dd 0			// 05: text
	dd 0			// 06: pushed in box
	dd 0			// 07: tiled box
	dd 0			// 08: slider
	dd 0			// 09: frame with text
	dd 0			// 0a: title bar
	dd 0			// 0b: last
	// patch draw handlers
	dd drawresizebox	// 0c: sizer
	dd drawdummy		// 0d: extra data
	dd DrawWinElemTab	// 0e: tab
	dd DrawWinElemTabButton	// 0f: tab button
	dd DrawWinElemCheckBox	// 10: check box
	dd DrawWinSetTextColor	// 11: set text color
%if ($-winelemdrawptrs)/4 <> cWinElemMax+1
	%error "Wrong number of winelemdrawptrs"
%endif
endvar

uvarb curwintextcolor

DrawWinSetTextColor:
	mov al,[ebp+windowbox.bgcolor]
	mov [curwintextcolor],al
	// fall through

drawdummy:
	jmp [winelemdrawptrs+4*cWinElemDummyBox]

exported DrawCenteredTextWithColor
	extern drawcenteredtextfn
	mov al,[curwintextcolor]
	jmp [drawcenteredtextfn]

uvarw guispritebase,1,s
var numguisprites, dd 3+12

var depotscalefactor
	dw 29

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
exported CopyWindowElementList
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
	xchg [esi+window.elemlistptr], edi
	mov [esi+window2ofs+window2.origelemlist], edi
	mov edi, [esi+window.width]
	mov [esi+window2ofs+window2.origsize], edi
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
	and dword [ResizeTempData+tmpdx], 0
	and dword [ResizeTempData+tmpdquarter], 0
	bts dword [esi+window.flags], 11
	jc .alreadycopied
	call CopyWindowElementList
	jc .fail
.alreadycopied:

	or byte [esi+window.flags+1], 4
	or byte [uiflags], 1<<7	// window is being dragged (although this is of course not entirely correct)
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
	mov cl, cWinTypeDropDownMenu
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

uvarw sizewindowprev, 2
sizewindowprevx equ sizewindowprev
sizewindowprevy equ sizewindowprev+2
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

	call doresizewinfunc

#if 0
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
#endif

	call [RefreshWindowArea]
	pop word [sizewindowprevy]
	pop word [sizewindowprevx]
	clc
	ret

//ax=width, cx=height, esi=window
global doresizewinfunc
doresizewinfunc:
	push esi
	push edx
	push ebp
	push edi

	mov dh, cWinDataSizer
	call FindWindowData
	//now edi points to the sizer window data (or carry set if not found)
	jc .nosizerdata
	push edi
	mov edi, [edi+windatabox_sizerextra.constraints]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi+windatabox_sizerextra.eleminfo]
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
	jna .itemokay		//note was previously js, caused errorneous movement of the offset to zero when more than 127 items in list.
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


	push edx
	mov dl, cWinEventResize
	extcall GuiSendEventESI
	pop edx
	ret

struc _resizedata
	tmpdx:		resw 1
	tmpdy:		resw 1
	tmpthird1:	resw 1
	tmpthird2:	resw 1
	tmpdquarter:	resw 1
	tmpquarter:	resw 1
	tmpgood1:	resb 1
endstruc
uvard ResizeTempData, (_resizedata_size+3)/4


//in: ESI=window
//    EDI=constraints (for each window element a byte with bits, bit set means move when size changes; bit0=x1, bit1=x2, bit2=y1, bit3=y2)
//    AX,BX=new width&height of window
ResizeWindowElements:
	pusha
	push bx
	push ax
	pop eax		// mov eax[16:31], bx
	sub eax, [esi+window.width]
	sub bx, [esi+window.height]
	mov edx, [esi+window.viewptr]
	test edx,edx
	jz .noview
	add [edx+view.width],eax
	add [edx+view.scrwidth],eax
.noview:
	mov esi, [esi+window.elemlistptr]
	call ResizeWindowElementsDelta
	popa
	ret

%assign changex1	  1
%assign changex2	  2
%assign changey1	  4
%assign changey2	  8
%assign changex1half	  10h
%assign changex2half	  20h
%assign changey1half	  40h
%assign changey2half	  80h
%assign changex1third	  100h
%assign changex2third	  200h
%assign changex1twothird  400h
%assign changex2twothird  800h
%assign changex1quarter	  1000h
%assign changex2quarter	  2000h
// for three-quarter, set both half and quarter

//same as above, only esi is a pointer to the first windowelement, and ax,bx are size changes instead of absolute sizes
exported ResizeWindowElementsDelta
	push ebp
	mov ecx, .load
	mov word [ecx], 0xAC90	// lodsb
	push edi				// Find the extra data, returing a pointer in edi
	mov edi, esi
	mov dh, cWinDataSizer
	mov dl, cWinElemExtraData
	call FindWindowData.loop
	test byte [edi+windatabox_sizerextra.flags], 1	// Do we have word-sized constraints?
	jz .normal
	mov word [ecx], 0xAD66	// lodsw
.normal:
	pop edi
	setbase ebp, ResizeTempData
	
// Calculate thirds first.
	push eax
	push ebx
	test ax, ax
	setnl byte [BASE ResizeTempData+tmpgood1]
	jnl .gooda
.notgood:
	neg ax
.gooda:
	cwd
	mov bx, 3
	idiv bx
	mov cx, ax
	cmp byte [BASE ResizeTempData+tmpgood1], 1
	je .good
	neg cx
.good:
	mov word [BASE ResizeTempData+tmpthird1], cx
	shr dx, 4
	adc ax, ax
	cmp byte [BASE ResizeTempData+tmpgood1], 1
	je .goods
	neg ax
.goods:
	mov word [BASE ResizeTempData+tmpthird2], ax
	pop ebx
	pop eax
	
// now halves and quarters
	push eax
	push ebx
	add ax, [BASE ResizeTempData+tmpdx]
	add bx, [BASE ResizeTempData+tmpdy]
	mov cx, ax
	sar cx, 1
	setc byte [BASE ResizeTempData+tmpdx]
	mov dx, bx
	sar dx, 1
	setc byte [BASE ResizeTempData+tmpdy]
	mov ax, cx
	add ax, [BASE ResizeTempData+tmpdquarter]
	sar ax, 1
	setc [BASE ResizeTempData+tmpdquarter]
	mov [BASE ResizeTempData+tmpquarter], ax
	pop ebx
	pop ebp

	setbase none

	xor eax,eax
	xchg esi, edi
	
.loop:
	cmp byte [edi+windowbox.type], cWinElemLast
	je near .done

noglobal ovar .load, 0
	lodsw

	test al, changex1
	jz .nox1
	add [edi+windowbox.x1], bp
.nox1:
	test al, changex2
	jz .nox2
	add [edi+windowbox.x2], bp
.nox2:
	test al, changey1
	jz .noy1
	add [edi+windowbox.y1], bx
.noy1:
	test al, changey2
	jz .noy2
	add [edi+windowbox.y2], bx
.noy2:
	test al, changex1half
	jz .nox1s
	add [edi+windowbox.x1], cx
.nox1s:
	test al, changex2half
	jz .nox2s
	add [edi+windowbox.x2], cx
.nox2s:
	test al, changey1half
	jz .noy1s
	add [edi+windowbox.y1], dx
.noy1s:
	test al, changey2half
	jz .noy2s
	add [edi+windowbox.y2], dx
.noy2s:
	push ecx
	mov ecx, [ResizeTempData+tmpthird1]
	test ah, changex1third>>8
	jz .lnox1
	add [edi+windowbox.x1], cx
.lnox1:
	test ah, changex2third>>8
	jz .lnox2
	add [edi+windowbox.x2], cx
.lnox2:
	shr ecx,16		// move [tmpthird2] into cx
	test ah, changex1twothird>>8
	jz .lnox1s
	add [edi+windowbox.x1], cx
.lnox1s:
	test ah, changex2twothird>>8
	jz .lnox2s
	add [edi+windowbox.x2], cx
.lnox2s:
	mov cx, [ResizeTempData+tmpquarter]
	test ah, changex1quarter>>8
	jz .nox1q
	add [edi+windowbox.x1], cx
.nox1q:
	test ah, changex2quarter>>8
	jz .nox2q
	add [edi+windowbox.x2], cx
.nox2q:
	pop ecx
	add edi, windowbox_size
	jmp .loop
.done:
	pop ebp
	ret

//IN: esi=window, edi=pointer to size constraints, ax,cx=new width and height of window
//OUT: ax,cx=new width and height of window
HandleSizeConstraints:
	push ebp
	mov ebp, [esi+window.elemlistptr]
	
	cmp ax, [edi+winsizer_constraints.minwidth]
	jge .widthenough
	mov ax, [edi+winsizer_constraints.minwidth]
.widthenough:
	cmp ax, [edi+winsizer_constraints.maxwidth]
	jle .widthsenough
	mov ax, [edi+winsizer_constraints.maxwidth]
.widthsenough:
	cmp byte [edi+winsizer_constraints.itemwidth], 1
	jz .widthok

	push cx
	sub ax, [edi+winsizer_constraints.basewidth]
	push edx
	movsx edx, byte [edi+winsizer_constraints.widtheleidx]
	cmp edx, -1
	je .nocount1
	shl edx, 2
	lea edx, [edx*3]		//element ofst
.nocount1:
	mov cl, [edi+winsizer_constraints.itemwidth]
	div cl
	cmp edx, -1
	je .nocount2
	mov [esi+window.itemsvisible], al
	mov [ebp+edx+windowbox.extra], al
.nocount2:
	mul cl
	pop edx
	add ax, [edi+winsizer_constraints.basewidth]
	pop cx

.widthok:

	cmp cx, [edi+winsizer_constraints.minheight]
	jge .heightenough
	mov cx, [edi+winsizer_constraints.minheight]
.heightenough:
	cmp cx, [edi+winsizer_constraints.maxheight]
	jle .heightsenough
	mov cx, [edi+winsizer_constraints.maxheight]
.heightsenough:
	cmp byte [edi+winsizer_constraints.itemheight], 1
	jz near .heightok
	sub cx, [edi+winsizer_constraints.baseheight]
	push ax
	push edx
	movsx edx, byte [edi+winsizer_constraints.heighteleidx]
	cmp edx, -1
	je .nocount3
	shl edx, 2
	lea edx, [edx*3]
.nocount3:
	mov ax, cx
	mov cl, [edi+winsizer_constraints.itemheight]
	div cl
	cmp edx, -1
	je .nocount4
	cmp edi, CargoPacketWin_elements._sizer_constraints
	je .notnorm1
	cmp edi, trainlistwindowsizes
	je .notnorm1
	cmp edi, shipairlistwindowsizes
	je .notnorm1
	cmp edi, rvlistwindowsizes
	jne .norm1
.notnorm1:
	testflags sortvehlist
	jnc .norm1
	push ecx
	mov cl, [esi+window2ofs+window2.extitemshift]
	mov [esi+window2ofs+window2.extactualvisible], al
	mov ch, al
	shr ch, cl
	mov [esi+window.itemsvisible], ch
	pop ecx
	jmp .anorm1
.norm1:
	mov [esi+window.itemsvisible], al
.anorm1:
	mov [ebp+edx+windowbox.extra+1], al
.nocount4:
	mul cl
	mov cx, ax
	pop edx
	pop ax
	add cx, [edi+winsizer_constraints.baseheight]
.heightok:
	pop ebp
	ret

//IN: esi=window
//    dh=datatype to find
//OUT: edi=pointer to data, or carry set if not found
global FindWindowData,FindWindowData.gotelemlist
FindWindowData:
	mov edi, [esi+window.elemlistptr]
.gotelemlist:
	mov dl, cWinElemExtraData

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

.fail:
	stc
	ret

// Used to correct the size constraints of the depot window
// (as they alter between 32 and 29px depot modes + clonetrain)
// **  Affects new windows only, ResizeOpenWindows fixes active windows **
extern patchflags
global ChangeRailDepotSizeLimits
ChangeRailDepotSizeLimits:
	push ebx
	push esi
	mov esi, [TrainDepotElementList]

	bt dword [grfmodflags], 3
	jc .BitEnabled

testmultiflags clonetrain
	jnz .CloneTrain
	mov ebx, traindepotwindowsizes
	jmp .SetSizeLimits

.CloneTrain:
	mov ebx, newtraindepotwindowsizes
	jmp .SetSizeLimits

.BitEnabled:
testmultiflags clonetrain
	jnz .BitCloneTrain
	mov ebx, traindepotwindowsizes32
	jmp .SetSizeLimits

.BitCloneTrain:
	mov ebx, newtraindepotwindowsizes32

.SetSizeLimits:
	mov [esi], ebx
	pop esi
	pop ebx
	ret

// Stores the location sizer in the train depot element list
uvard TrainDepotElementList

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
	mov edi, [edi+windatabox_sizerextra.constraints]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi+windatabox_sizerextra.eleminfo]
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
	
	extern ShadedWinHandler, ShadedWinHandler.drawwindowelements_ret
	cmp dword [esi+window.function], ShadedWinHandler
	jne .done

	pop ebx
	call ebx

// If we're here, then ShadedWinHandler was used to handle a cWinEventRedraw
// Find it on the stack, and return there.
	xor ecx, ecx
	mov cl, 8
.loop:
	cmp dword [esp], ShadedWinHandler.drawwindowelements_ret
	je .done
	add esp, 2			// One TTD window pushes bp before calling DrawWindowElements
	loop .loop
	ud2		// ShadedWinHandler not found in top 4 dwords
			// (twice the current maximum stack usage)
.done:
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

	mov cl, cWinTypeMap
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
	mov edi, [edi+windatabox_sizerextra.constraints]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi+windatabox_sizerextra.eleminfo]
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
	jbe near .nextwindow
	cmp al, 0x12
	jne near .nextwindow
	//depots
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
	
	mov ebx, [TrainDepotElementList]	// Update our active windows' size contraints
	mov ebx, [ebx]				// from the base train depot element list
	mov [edi+windatabox_sizerextra.constraints], ebx
	
	push edi
	mov edi, [edi+windatabox_sizerextra.constraints]
	call HandleSizeConstraints
	pop edi
	pusha
	mov edi, [edi+windatabox_sizerextra.eleminfo]
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
	mov cx, [esi+12*13+windowbox.y2]
	inc cx
	shl ecx, 16
	mov cx, [esi+12*13+windowbox.x2]
	inc cx
	mov [edi+32], ecx

	mov cx, [win_newshistory_elements+12*4+windowbox.y2]
	inc cx
	shl ecx, 16
	mov cx, [win_newshistory_elements+12*4+windowbox.x2]
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
	extern reswidth,resheight
	cmp ax, [reswidth]
	jbe .nottoowide
	mov ax, [reswidth]
.nottoowide:
	sub ax, [edi+12*13+windowbox.x2]
	dec ax
	lea di, [ebx+34]
	cmp di, [resheight]
	jbe .nottoohigh
	mov bx, [resheight]
	sub bx, 34
.nottoohigh:
	cmp bx, 234
	jae .correctheight
	mov bx, 234
.correctheight:
	sub bx, [esi+12*13+windowbox.y2]
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
	lea di, [ebx+34]
	cmp di, [resheight]
	jbe .nottoohigh2
	movzx ebx, word [resheight]
	sub ebx, 34
	push eax
	mov eax, ebx
	mov bl, 42
	sub eax, 14
	div bl
	mov byte [win_newshistory_elements+12*2+windowbox.ytiles], al
	mov ah, 0
	imul ebx,eax, 42
	add ebx, 14
	pop eax
.nottoohigh2:
	sub ax, [win_newshistory_elements+12*4+windowbox.x2]
	dec ax
	sub bx, [win_newshistory_elements+12*4+windowbox.y2]
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

uvard traininfowindowelementsptr

var traininfosizes
	dw 370, 370, 1, 0
	dw 108, 1000
	db 14, 4
	dw 80
var traininfoelemconstraints
	dw 0000b, 0010b, 0011b
	dw 0010b, 1010b, 1011b
	dw 1100b, 1100b, 1110b
	dw 0000001000001100b, 0000100100001100b, 0000010000001110b
	dw 1111b, 0000b, 0000b
	
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
var newdepotwindowconstraints
	dw 0000000000000000b, 00000000000000010b, 0000000000001010b // Close Button, Title, Tile Box
	dw 0000000000001011b, 00000000000001011b, 0000001000001100b // Sell Button, Scroll Bar, New Vehicle
	dw 0000010000001110b, 0000100100001100b, 0000000000001111b // Location, Clone Train, Resize
	dw 0 // End
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
var newtraindepotwindowsizes // These are longer so that the words don't clip
	dw 349-4*29, 2048//X
	db 29, -1 
	dw 1
	dw 110-4*14, 2048//Y
	db 14 ,2
	dw 26
var newtraindepotwindowsizes32
	dw 379-4*32, 2048//X
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

global calctraininfoserviceintervalpos
calctraininfoserviceintervalpos:
	add cx, 13
	add dx, [esi+window.height]
	sub dx, 23
	ret
	
global calctraininforowcount
calctraininforowcount:
	jns .next
	mov ah, [esi+window.itemsvisible]
	neg ah
	cmp al, ah
	jl .next
	ret
.next:
	add dword [esp], 0x54
	ret

//Functions to make the vehicle lists resizable:
lastvehdrawn:
	movzx ax, al
.hasword:
	push edx
	mov dl, [esi+window.itemsvisible]
.hasdl:
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
	push edx
	mov dl, [esi+window2ofs+window2.extactualvisible]
	movzx ax, al
	jmp lastvehdrawn.hasdl

global lastroadvehdrawn
lastroadvehdrawn:
	push eax
	mov al,0xFF
ovar roadvehoffset,-1
	push edx
	mov dl, [esi+window2ofs+window2.extactualvisible]
	movzx ax, al
	jmp lastvehdrawn.hasdl

global lastairvehdrawn
lastairvehdrawn:
	push eax
	mov ax, 0xFFFF
ovar airvehoffset, -2
	push edx
	mov dl, [esi+window2ofs+window2.extactualvisible]
	jmp lastvehdrawn.hasdl

global lastshipvehdrawn
lastshipvehdrawn:
	push eax
	mov ax, 0xFFFF
ovar shipvehoffset, -2
	push edx
	mov dl, [esi+window2ofs+window2.extactualvisible]
	jmp lastvehdrawn.hasdl

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

global traindepotwindowhandler, traindepotwindowhandler.resizewindow
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
