#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <proc.inc>
#include <window.inc>
#include <imports/gui.inc>
#include <ptrvar.inc>

extern RefreshWindowArea
extern tmpbuffer1
extern ttdtexthandler, gettextwidth
extern resheight

%assign DropDownExID 159

%assign DropDownMaxItemsVisible 15
%assign DropDownExMax 100

// Example of usage of GenerateDropDownEx* 
// you need esi = window  ecx = element nr that is calling
// call GenerateDropDownExPrepare		// this will result carry if a DropDownEx is already open
// ...
// mov [DropDownExList+ecx*2], eax		// where eax is text id to be filled, ecx is position
// ... 
// bts [DropDownExListDisabled], ecx	// will disable an entry
// ...
// mov [DropDownExList+ecx*2], 0xFFFF	// terminate the last entry
// ...
// call GenerateDropDownExPrepare		// open the DropDownEx window, needs:
//										// esi = window, ecx = ele, dx = selected item

// Needs to be filled after prepare
uvarw DropDownExListItemHeight
uvarw DropDownExList, DropDownExMax+1
uvarb DropDownExListDisabled, DropDownExMax/8+1


varb DropDownExElements
	db cWinElemSpriteBox
DropDownExElements.bgcolorbox:
	db cColorSchemeDarkBlue
	dw 0 
DropDownExElements.boxwidth:
	dw 1000, 0,
DropDownExElements.boxheight:
	dw 1000, 0
	db cWinElemSlider
DropDownExElements.bgcolorslider:
	db cColorSchemeDarkBlue
DropDownExElements.sliderx:
	dw 0, 1000, 0
DropDownExElements.sliderheight: 
	dw 1000, 0
	db cWinElemLast
endvar

struc DropDownExData
	.parentid: resw 1
	.parenttype: resb 1
	.parentele: resb 1
	.timer: resb 1
	.mousestate: resb 1
endstruc


// in:
// esi = parent window
// cx = parent ele id
// carry flag = set if the button was active already, you should surely quit your dropdown handler now
exported GenerateDropDownExPrepare
	pusha
	mov cl, 0x2A
	mov dx, DropDownExID
	call [FindWindow]
	test esi,esi
	jz .noold
	call [DestroyWindow]
.noold:
	xor eax, eax
	mov ecx, DropDownExMax/8
	mov edi, DropDownExListDisabled
	rep stosb
	mov word [DropDownExListItemHeight], 10
	popa
	btr [esi+window.activebuttons], ecx
	ret

// in:
// esi = window
// dx  = selected item
// cx  = calling ele number
// filled DropDownExList, DropDownExListDisabled
proc GenerateDropDownEx
	local parenttype,parentid,parentele,parentheight, newxy, itemselected, itemstotal
	
	_enter
	pusha
	movzx ecx, cx
	mov [%$parentele], ecx
	mov word [%$itemselected], dx

	mov edi, ecx
	imul edi, 0x0C
	add edi, [esi+window.elemlistptr]
	mov al, [edi+windowbox.bgcolor]
	mov byte [DropDownExElements.bgcolorbox], al
	mov byte [DropDownExElements.bgcolorslider], al
	
	mov ax, word [esi+window.id]
	mov word [%$parentid], ax
	mov al, byte [esi+window.type]
	mov byte [%$parenttype], al
	
	mov bx, word [edi+windowbox.y2]
	mov word [%$newxy+2], bx
	sub bx, word [edi+windowbox.y1]
	mov word [%$parentheight], bx	// need to know if window doesn't fit anymore
	
	movzx ebx, word [edi+windowbox.x1]
	mov word [%$newxy], bx
	sub bx, word [edi+windowbox.x2]
	neg ebx
	
	
	// calculate the width of the texts, unsafe local vars!
	push ebp
	mov ebp, DropDownExList
.nexttext:
	movzx eax, word [ebp]
	cmp ax, 0xFFFF
	je .nomoretext
	
	mov edi, tmpbuffer1
	pusha
	call [ttdtexthandler]
	popa
	mov esi, edi
	push ebx
	call [gettextwidth]
	pop ebx
	cmp cx, bx
	jl .okay
	movzx ebx, cx
.okay:
	add ebp, 2
	jmp .nexttext
	mov ecx, ebp
	pop ebp
	// unsafe local vars end
		
.nomoretext:
	// how many items do we have?
	sub ecx, DropDownExList
	shr ecx, 1
	mov dword [%$itemstotal], ecx

	// calculate the height of the window
	movzx eax, word [DropDownExListItemHeight]
	mov ecx, DropDownMaxItemsVisible
	imul ax, cx
	
	// change the elements list
	// ebx = width
	// eax = height
	add eax, 4	// pixels for borders
	add ebx, 10	// pixels for borders and some space at the text 
	
	mov word [DropDownExElements.boxwidth], bx
	mov word [DropDownExElements.boxheight], ax
	mov word [DropDownExElements.sliderheight], ax
	inc ebx
	mov word [DropDownExElements.sliderx], bx
	add ebx, 16
	mov word [DropDownExElements.sliderx+2], bx
	// end change of element list

	// create window sizes
	inc eax
	inc ebx
	
	// fix position if it's not well
	mov cx, ax	// does it end below the visible area? (the status bar takes 12 pixels)
	add cx, word [%$newxy+2]
	mov dx,[resheight]
	sub dx, 12	// status bar 
	cmp cx,dx
	jl .heightok
	
	mov dx, word [%$newxy+2]
	sub dx, ax
	sub dx, word [%$parentheight]
	mov word [%$newxy+2], dx
.heightok:

	// merge sizes
	shl eax, 16
	or ebx, eax	
	// ebx = width , height
	mov eax, dword [%$newxy]
	
	push ebp
	mov ebp, addr(GenerateDropDownEx_winhandler)
	mov cx, 0x2A			// window type
	mov dx, -1				// -1 = direct handler
	call dword [CreateWindow]
	pop ebp
	mov word [esi+window.id], DropDownExID
	mov dword [esi+window.elemlistptr], addr(DropDownExElements)
	
	mov cl, byte [%$parenttype]
	mov byte [edi+window.data+DropDownExData.parenttype], cl
	mov dx, word [%$parentid]
	mov word [edi+window.data+DropDownExData.parentid], dx
	mov cl, [%$parentele]
	mov byte [esi+window.data+DropDownExData.parentele], cl
	
	
	mov dx, word [%$itemselected]
	mov word [esi+window.selecteditem], dx
	mov dx, word [%$itemstotal]
	mov byte [esi+window.itemstotal], dl
	mov byte [esi+window.itemsvisible], DropDownMaxItemsVisible
	mov byte [esi+window.itemsoffset], 0
	// enable mouse tracking
	mov byte [esi+window.data+DropDownExData.timer], 0
	mov byte [esi+window.data+DropDownExData.mousestate], 1
	popa
	_ret
endproc

GenerateDropDownEx_close:
	push esi
	push edi
	xchg esi, edi
	mov cl, byte [edi+window.data+DropDownExData.parenttype]
	mov dx, word [edi+window.data+DropDownExData.parentid]
	mov ebx, edx
	call [FindWindow]
	test esi,esi
	jz .parentnotfound
	
	mov dx, word [edi+window.data+DropDownExData.parentid]
	movzx ecx, word [edi+window.data+DropDownExData.parentele]
	btr dword [esi+window.activebuttons], ecx
	or al, 0x80
	mov ah, cl
	call [invalidatehandle]
		
.parentnotfound:
	pop edi
	pop esi
	ret
	
GenerateDropDownEx_winhandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz near GenerateDropDownEx_redraw
	cmp dl, cWinEventClick
	jz near GenerateDropDownEx_clickhandler
	cmp dl, cWinEventClose
	jz GenerateDropDownEx_close
	cmp dl, cWinEventTimer
//	jz GenerateDropDownEx_timer
	cmp dl, cWinEventSecTick
//	jz GenerateDropDownEx_sectick

	cmp dl,cWinEventUITick
	jz GenerateDropDownEx_uitick
	ret
	
	
GenerateDropDownEx_uitick:
	push edx
	push esi
	mov ax,0x8000
	call [WindowClicked]	// release up/down scroll arrows
	pop esi
	pop edx
	
	push esi
	mov cl, byte [edi+window.data+DropDownExData.parenttype]
	mov dx, word [edi+window.data+DropDownExData.parentid]
	call [FindWindow]
	mov edi, esi
	pop esi
	test edi,edi
	jz .closewindow		// our parent isn't there anymore
	
	cmp byte [esi+window.data+DropDownExData.timer], 0
	jz .checkmousedrag
	dec byte [esi+window.data+DropDownExData.timer]
	jnz .checkmousedrag
	push esi
	// generate drop down event
	mov dl, cWinEventDropDownItemSelect
	mov ax, word [edi+window.selecteditem]
	mov cx, word [edi+window.data+DropDownExData.parentele]
	
	mov si, [edi+window.opclassoff]
	cmp si,-1
	je .plaincall
	movzx esi, si
	mov ebx, [edi+window.function]
	mov ebp, [ophandler+esi]
	call dword [ebp+4]
	jmp short .calldone
.plaincall:
	call dword [edi+window.function]
.calldone:
	pop esi
.closewindow:
	jmp [DestroyWindow]
	
.checkmousedrag:
	// to be implemented
	
	ret
	
	
GenerateDropDownEx_redraw:
	call dword [DrawWindowElements]
	mov cx, [esi+window.x]
	add cx, 1
	mov dx, [esi+window.y]
	add dx, 2

	mov edi, [currscreenupdateblock]
	movzx ebx, byte [esi+window.itemsoffset]
	movzx ebp, byte [esi+window.itemsvisible]
	add ebp, ebx

.start:
	cmp word [DropDownExList+ebx*2], 0xFFFF
	je near .done
	cmp ebp, ebx
	je near .done
	
	cmp word [DropDownExList+ebx*2], 0
	je .next
	
	mov al, 0x10	//cTextColorBlack
	cmp bx, [esi+window.selecteditem]
	jne .notelected
.selected:
	mov al, 0x0C	//cTextColorWhite
	pusha
	add cx, 1
	mov eax, ecx
	mov ecx, edx
	mov ebx, eax
	add bx, word [esi+window.width]
	sub ebx, 5
    add edx, 9
	xor ebp, ebp
	call [fillrectangle]
	popa
.notelected:
	
	pusha
	add cx, 2
	movzx ebx, word [DropDownExList+ebx*2]
	call [drawtextfn]
	popa
	
	bt [DropDownExListDisabled], ebx
	jnc .notdisabled
.disabled:
	pusha
	mov eax, ecx
	mov ecx, edx
	mov ebx, eax
	add bx, word [esi+window.width]
	sub ebx, 5
    add edx, 9
	mov bp, 0x8000
	call [fillrectangle]
	popa
.notdisabled:
.next:
 	add dx, word [DropDownExListItemHeight]
	inc ebx
	cmp ebx, ebp
	jne near .start
.done:
	ret
	
GenerateDropDownEx_clickhandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
#if 0
	cmp cl, 0
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
#endif
	mov ax, bx
	sub	ax, [esi+window.y]
	sub ax, 2
	mov bl, 10
//can we have a overflow here?
	div bl
	movzx eax, al
	add al, [esi+window.itemsoffset]
	cmp al, [esi+window.itemstotal]
	jnb .nonselect
	bt [DropDownExListDisabled], eax
	jc .nonselect
	mov word [esi+window.selecteditem], ax
	mov byte [esi+window.data+DropDownExData.timer], 4
.nonselect:
	movzx eax, al
	call [RefreshWindowArea]
	ret
