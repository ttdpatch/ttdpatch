// Let windows snap together, heavily based on the openttd window snapping code

#include <std.inc>
#include <window.inc>

extern windowsnapradius,windowstack


uvarw realwx
uvarw realwy

global beginwindowdrag
beginwindowdrag:
	mov ax, [esi+window.x]
	mov [realwx], ax
	mov ax, [esi+window.y]
	mov [realwy], ax
	
	pop eax
	push cx
	push dx
	mov cl, 3Fh
	push eax
	ret

%macro makepositive 1
	cmp %1, 0
	jge %%positive
	neg %1
%%positive:
%endmacro

;IN:  ESI == window; AX = deltax; BX = deltay
;OUT: AX = deltax; BX = deltay; zeroflag set if ax == bx == 0
uvarw nx
uvarw ny
global handlewindowdrag
handlewindowdrag:
	push edx

	mov cx, [realwx]
	add cx, ax
	mov dx, [realwy]
	add dx, bx
	
	add ax, [realwx]
	add bx, [realwy]
	mov [nx], ax
	mov [ny], bx
	mov [realwx], cx
	mov [realwy], dx
	// ax == x, bx = y
	movzx cx, byte [windowsnapradius]
	movzx dx, byte [windowsnapradius]
	// cx == hsnap, dx == vsnap
	
	mov edi, [windowstack]
.nextwindow:
	cmp edi, [windowstacktop]
	jb .notlastwindow
	jmp .lastwindow
.notlastwindow:
	
	// edi == v, esi == w
	cmp esi, edi
	jne .notcontinue
	jmp .continue
.notcontinue:
	push ax
	push bx
	add bx, [esi+window.height]
	cmp bx, word [edi+window.y]
	jbe .notleftright
	pop bx
	mov ax, [edi+window.y]
	add ax, [edi+window.height]
	cmp bx, ax
	jae .notleftright2
	pop ax
	;line 733 of window.c
	push dx // vsnap is not used, so use dx to store delta
	mov dx, [edi+window.x]
	add dx, [edi+window.width]
	sub dx, ax
	makepositive dx
	;now dx == delta
	cmp dx, cx
	ja .notmyleftright
	mov cx, dx
	mov dx, [edi+window.x]
	add dx, [edi+window.width]
	mov [nx], dx
.notmyleftright:
	
	;line 741 of window.c
	mov dx, [edi+window.x]
	sub dx, ax
	sub dx, [esi+window.width]
	makepositive dx
	cmp dx, cx
	ja .notmyrightleft
	mov cx, dx
	mov dx, [edi+window.x]
	sub dx, [esi+window.width]
	mov [nx], dx
.notmyrightleft:
	pop dx
	jmp .doneleftright
.notleftright:
	pop bx
.notleftright2:
	pop ax
.doneleftright:
	;line 747 of window.c

	push ax
	push bx
	add bx, [esi+window.height]
	cmp bx, [edi+window.y]
	jb .nothorizmatch
	pop bx
	mov ax, [edi+window.y]
	add ax, [edi+window.height]
	cmp [esi+window.y], ax
	ja .nothorizmatch2
	pop ax
	
	push dx // vsnap is not used, so use dx to store delta
	mov dx, [edi+window.x]
	sub dx, ax
	makepositive dx
	cmp dx, cx
	ja .notleftleft
	mov cx, dx
	mov dx, [edi+window.x]
	mov [nx], dx
.notleftleft:
	mov dx, [edi+window.x]
	add dx, [edi+window.width]
	sub dx, ax
	sub dx, [esi+window.width]
	makepositive dx
	cmp dx, cx
	ja .notrightright
	mov cx, dx
	mov dx, [edi+window.x]
	add dx, [edi+window.width]
	sub dx, [esi+window.width]
	mov [nx], dx
.notrightright:
	pop dx
	jmp .donehorizmatch
.nothorizmatch:
	pop bx
.nothorizmatch2:
	pop ax
.donehorizmatch:

	push bx
	push ax
	add ax, [esi+window.width]
	cmp ax, [edi+window.x]
	jbe .nottopbottom
	pop ax
	mov bx, [edi+window.x]
	add bx, [edi+window.width]
	cmp ax, bx
	jae .nottopbottom2
	pop bx

	push cx	// hsnap is unused, so use cx for delta
	mov cx, [edi+window.y]
	add cx, [edi+window.height]
	sub cx, bx
	makepositive cx
	cmp cx, dx
	ja .notmytopbottom
	mov dx, cx
	mov cx, [edi+window.y]
	add cx, [edi+window.height]
	mov [ny], cx
.notmytopbottom:
	
	mov cx, [edi+window.y]
	sub cx, bx
	sub cx, [esi+window.height]
	makepositive cx
	cmp cx, dx
	ja .notmybottomtop
	mov dx, cx
	mov cx, [edi+window.y]
	sub cx, [esi+window.height]
	mov [ny], cx
.notmybottomtop:
	pop cx
	jmp .donetopbottom
.nottopbottom:
	pop ax
.nottopbottom2:
	pop bx
.donetopbottom:

	push ax

	mov ax, [esi+window.x]
	add ax, [esi+window.width]
	cmp ax, [edi+window.x]
	jb .notvertmatch
	mov ax, [edi+window.x]
	add ax, [edi+window.width]
	cmp [esi+window.x], ax
	ja .notvertmatch
	pop ax

	push cx // hsnap is not used, so use cx for delta
	mov cx, [edi+window.y]
	sub cx, bx
	makepositive cx
	cmp cx, dx
	ja .nottoptop
	mov dx, cx
	mov cx, [edi+window.y]
	mov [ny], cx
.nottoptop:
	mov cx, [edi+window.y]
	add cx, [edi+window.height]
	sub cx, bx
	sub cx, [esi+window.height]
	makepositive cx
	cmp cx, dx
	ja .notbottombottom
	mov dx, cx
	mov cx, [edi+window.y]
	add cx, [edi+window.height]
	sub cx, [esi+window.height]
	mov [ny], cx
.notbottombottom:

	pop cx
	jmp .donevertmatch
.notvertmatch:
	pop ax
.donevertmatch:

.continue:
	add edi, window_size
	jmp .nextwindow
.lastwindow:
	mov ax, [nx]
	mov bx, [ny]
	sub ax, [esi+window.x]
	sub bx, [esi+window.y]

	pop edx
	; test for no movement
	mov cx, ax
	or cx, bx
	ret
