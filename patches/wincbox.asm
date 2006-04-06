
#include <std.inc>
#include <textdef.inc>
#include <window.inc>

extern drawrectangle,fillrectangle,temp_drawwindow_active_ptr,drawtextfn
extern winelemdrawptrs,invalidatehandle

global DrawWinElemCheckBox
DrawWinElemCheckBox:
	// first draw the check box
	push esi
	push ebp
	mov ax,[ebp+windowbox.x1]
	mov cx,[ebp+windowbox.y1]
	add ax,[esi+window.x]
	add cx,[esi+window.y]
	lea bx,[eax+10]		// width of check box
	lea dx,[ecx+11]		// height of check box

	mov esi,1<<5	// pushed in box
	movzx ebp,byte [ebp+windowbox.bgcolor]
	call [drawrectangle]
	pop ebp
	pop ebx
	mov esi, [temp_drawwindow_active_ptr]
	test byte [esi],1
	jz .notactive

	pusha
	mov al,[ebp+windowbox.extra]
	and al,15
	jnz .notblack
	mov al,0x10	// 0 (blue) -> black
.notblack:
	mov cx,[ebp+windowbox.x1]
	add cx,[ebx+window.x]
	add cx,2
	mov dx,[ebp+windowbox.y1]
	add dx,[ebx+window.y]
	inc dx
	mov bx,statictext(checkmark)
	call [drawtextfn]
	popa

.notactive:
	test byte [esi+4],1
	mov esi,ebx
	jz .notdisabled

	// if disabled, fill with mesh
	push ebp
	mov ax,[ebp+windowbox.x1]
	add ax,[esi+window.x]
	mov cx,[ebp+windowbox.y1]
	add cx,[esi+window.y]
	mov bx,[ebp+windowbox.x2]
	add bx,[esi+window.x]
	mov dx,[ebp+windowbox.y2]
	add dx,[esi+window.y]
	movzx ebp,byte [ebp+windowbox.bgcolor]
	bts ebp,15
	call [fillrectangle]
	pop ebp

.notdisabled:
	jmp [winelemdrawptrs+4*cWinElemDummyBox]

global CheckBoxClicked
CheckBoxClicked:
	cmp cx,32
	jae .bad
	bt [esi+window.disabledbuttons],cx
	jc .bad

	btc [esi+window.activebuttons],cx
	push eax
	push ecx
	sbb ch,ch
	mov cl,[ebp+windowbox.extra+1]
	shr cl,11-8
	mov eax,[ebp+windowbox.extra]
	shr eax,4
	and eax,0x7f
	rol eax,cl	// now eax=mask of buttons to enable/disable

	test ch,ch
	jz .active

.inactive:
	or [esi+window.disabledbuttons],eax
	jmp short .done

.active:
	not eax
	and [esi+window.disabledbuttons],eax

.done:
	push ebx
	mov al,[esi+window.type]
	mov bx,[esi+window.id]
	call [invalidatehandle]
	pop ebx
	pop ecx
	pop eax

.bad:
	ret

