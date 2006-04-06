
#include <std.inc>
#include <window.inc>

extern DrawWindowElements,FindWindowData,WindowClicked,drawrectangle
extern drawspritefn,fillrectangle,temp_drawwindow_active_ptr
extern winelemdrawptrs



global DrawWinElemTab
DrawWinElemTab:
	push ax
	mov ax, [esi+window.selecteditem]
	cmp word [ebp+windowbox.extra], ax
	pop ax
	je .tabactive
	jmp [winelemdrawptrs+4*cWinElemDummyBox]
.tabactive:
	
	push word [ebp+windowbox.extra]
	mov word [ebp+windowbox.extra], 0
	
	push esi
	mov esi, [winelemdrawptrs+4*cWinElemDummyBox]
	mov byte [esi], 0xC3	// ret
	pop esi
	
	call [winelemdrawptrs+4*cWinElemSpriteBox]

	push esi
	mov esi, [winelemdrawptrs+4*cWinElemDummyBox]
	mov byte [esi], 0x83
	pop esi

	pop bx
	mov [ebp+windowbox.extra], bx

	pusha
	push dword [esi+window.elemlistptr]
	push dword [esi+window.activebuttons]
	push dword [esi+window.disabledbuttons]

	mov edi, [temp_drawwindow_active_ptr]
	push dword [edi]
	push dword [edi+4]

	movzx ebx, bx
	
	mov dh, cWinDataTabs
	call FindWindowData
	jc .failed
	mov edi, [edi]
	mov edi, [edi+4*ebx]
	mov [esi+window.elemlistptr], edi
	cmp byte [edi], cWinElemLast
	je .failed

	mov edi, [esi+window.data]
	mov eax, [edi+ebx*8]
	mov [esi+window.activebuttons], eax
	mov eax, [edi+ebx*8+4]
	mov [esi+window.disabledbuttons], eax

	call [DrawWindowElements]

.failed:
	
	mov edi, [temp_drawwindow_active_ptr]
	pop dword [edi+4]
	pop dword [edi]
	
	pop dword [esi+window.disabledbuttons]
	pop dword [esi+window.activebuttons]
	pop dword [esi+window.elemlistptr]
	popa
				
	jmp [winelemdrawptrs+4*cWinElemDummyBox]


global DrawWinElemTabButton
DrawWinElemTabButton:
	pusha
	mov ax, [esi+window.x]
	mov bx, ax
	add ax, [ebp+windowbox.x1]
	add bx, [ebp+windowbox.x2]
	mov cx, [esi+window.y]
	mov dx, cx
	add cx, [ebp+windowbox.y1]
	add dx, [ebp+windowbox.y2]
	push ebp
	
	movzx ebp, byte [ebp+windowbox.bgcolor]
	push ax
	push bx
	push cx
	push dx
	push ebp
	push esi
	mov si, 0
	call [drawrectangle]
	pop esi
	pop ebp
	pop dx
	pop cx
	pop bx
	pop ax
	
	lea ebp, [colorschememap+8*ebp+7]
	push esi
	mov esi, [temp_drawwindow_active_ptr]
	test byte [esi], 1
	pop esi
	jz .notactive
	sub ebp, 2
.notactive:
	movzx bp, byte [ebp]
	push ax
	push cx
	push esi
	mov cx, dx
	call [fillrectangle]
	pop esi
	pop dx
	pop cx
	pop ebp
	add cx, 3
	add dx, 3
	movzx ebx, word [ebp+windowbox.extra]
	call [drawspritefn]
	popa

	
	jmp [winelemdrawptrs+4*cWinElemDummyBox]

global TabClicked
TabClicked:
	push edi
	push edx
	xor cx, cx
	push dword [esi+window.elemlistptr]
	push dword [esi+window.activebuttons]
	push dword [esi+window.disabledbuttons]
	movzx edx, word [esi+window.selecteditem]

	push edx
	mov dh, cWinDataTabs
	call FindWindowData
	jc .failed
	pop edx
	mov edi, [edi]
	mov edi, [edi+4*edx]
	mov [esi+window.elemlistptr], edi
	cmp byte [edi], cWinElemLast
	je .failednopop

	push eax
	mov edi, [esi+window.data]
	mov eax, [edi+edx*8]
	mov [esi+window.activebuttons], eax
	mov eax, [edi+edx*8+4]
	mov [esi+window.disabledbuttons], eax
	pop eax

	push edx
	call [WindowClicked]
.failed:
	pop edx
.failednopop:
	mov ch, dl
	inc ch
	pop dword [esi+window.disabledbuttons]
	pop dword [esi+window.activebuttons]
	pop dword [esi+window.elemlistptr]
	pop edx
	pop edi

	ret

global CloseDropDownMenu
CloseDropDownMenu:
	cmp ch, 0
	jne .ontab
	btr dword [esi+window.activebuttons], ecx
	mov bx, [0xFFFFFF]
ovar .ddmParentWinIdPtr1, -4,$,CloseDropDownMenu
	ret
.ontab:
	dec ch
	movzx ebx, ch
	push edi
	mov edi, [esi+window.data]
	push ecx
	movzx ecx, cl
	btr dword [edi+8*ebx], ecx
	pop ecx
	mov edi, [esi+window.elemlistptr]
	xor ecx, ecx
.loop:
	cmp byte [edi+windowbox.type], cWinElemLast
	je .found	//notfound
	cmp byte [edi+windowbox.type], cWinElemTab
	jne .next
	cmp word [edi+windowbox.extra], bx
	je .found
.next:
	inc ecx
	add edi, 12
	jmp .loop
.found:
	pop edi
	mov bx, [0xFFFFFF]
ovar .ddmParentWinIdPtr2, -4,$,CloseDropDownMenu
	ret
//btr [esi+window.activebuttons], ecx
//db 66h, 8bh, ..h, address
//--> out: cl = tab, als het op een tab is, en activebutton gereset

global DropDownMenuResetActiveButtons
DropDownMenuResetActiveButtons:
	movzx ecx, cx
	push ecx
	xor ch, ch
	btr [esi+window.activebuttons], ecx
	pop ecx
	ret
//btr [esi+window.activebuttons], ecx
//db 66h, 9ch
//-3 (7 bytes)--> push ecx; movzx ecx, cl; btr ...; pop ecx

global DropDownMenuSetActiveButtons
DropDownMenuSetActiveButtons:
	push ecx
	xor ch, ch
	bts [esi+window.activebuttons], ecx
	pop ecx
	mov bx, [esi+window.id]
	ret
//bts [esi+window.activebuttons], ecx
//mov bx, [esi+window.id]

global DropDownMenuGetElements
DropDownMenuGetElements:
	movzx ebp, cl
	imul ebp, 0Ch
	add ebp, [esi+window.elemlistptr]
	ret
//mov ebp, ecx
//imul ebp, 0Ch
//add ebp, [esi+window.elemlistptr]
//-->add a movzx ecx, cl
