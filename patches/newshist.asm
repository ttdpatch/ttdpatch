
#include <std.inc>
#include <textdef.inc>
#include <window.inc>
#include <news.inc>
#include <ptrvar.inc>

extern BringWindowToForeground,CreateWindow,DestroyWindow,DrawWindowElements
extern WindowClicked,WindowTitleBarClicked,currscreenupdateblock
extern drawsplittextfn,drawtextfn,invalidatehandle,newshistoryptr
extern newsmessagefn,specialtext1,statusbarnewsitem
extern ttdtexthandler



uvard firstfreenewshist,1	// pointer to first free item
uvard lastusednewshist,1	// pointer to last used item (probable one before first free)
uvard firstusednewshist,1	// pointer to first used item
uvarb numnewsitems,1
uvarb newsalreadyadded,1

global newshistclear
newshistclear:
	pusha
	mov ecx, NEWS_HISTORY_SIZE
	mov edi, [newshistoryptr]
.loop:
	mov byte [edi+newsitem.type], 0xFF
	add edi, newsitem_size
	dec ecx
	jnz .loop

	mov edi, [newshistoryptr]
	mov [firstfreenewshist], edi
	mov [firstusednewshist], edi
	mov dword [lastusednewshist], 0
	mov byte [numnewsitems], 0
	
	popa
	ret

global newshistinit
newshistinit:
	pusha
	// initialize firstfreenewshist, lastusednewshist, firstusednewshist and numnewsitems
	// first count numnewsitems
	mov byte [numnewsitems], 0
	mov ecx, NEWS_HISTORY_SIZE
	mov edi, [newshistoryptr]
.loop:
	cmp byte [edi+newsitem.type], 0xFF
	je .notused
	inc byte [numnewsitems]
.notused:
	add edi, newsitem_size
	dec ecx
	jnz .loop
	
	// now, if count == NEWS_HISTROY_SIZE, do linear search to find the gap in the dates, else do linear search to first not used item
	cmp byte [numnewsitems], NEWS_HISTORY_SIZE
	je .fulllist
	cmp byte [numnewsitems], 0
	je .emptylist
	mov edi, [newshistoryptr]
	mov [firstusednewshist], edi
.loop2:
	cmp byte [edi+newsitem.type], 0xFF
	je .found
	add edi, newsitem_size
	jmp .loop2
.found:
	mov [firstfreenewshist], edi
	sub edi, newsitem_size
	mov [lastusednewshist], edi
	jmp .done

.emptylist:
	mov edi, [newshistoryptr]
	mov [firstfreenewshist], edi
	mov [firstusednewshist], edi
	mov dword [lastusednewshist], 0
	jmp .done

.fulllist:
	mov edi, [newshistoryptr]
	mov esi, edi
	mov [firstusednewshist], edi
	add esi, newsitem_size
	mov ecx, NEWS_HISTORY_SIZE-1
.loop3:
	mov ax, [edi+newsitem.date]
	cmp [esi+newsitem.date], ax
	jb .found2
	add esi, newsitem_size
	add edi, newsitem_size
	dec ecx
	jnz .loop3
// failed to find it, edi points to the last message in the queue
	mov [lastusednewshist], edi
	mov edi, [newshistoryptr]
	mov [firstfreenewshist], edi
	jmp .done
.found2:
	mov [lastusednewshist], edi
	mov [firstfreenewshist], esi
	mov [firstusednewshist], esi

.done:
	popa
	ret


global addnewsmessagetohistory
addnewsmessagetohistory:	// old name was same as existing name but with different capitalization... not good
	pusha
	cmp byte [newsalreadyadded], 0
	jne near .done

	// copy the news message to the history
	mov esi, [firstfreenewshist]
	mov [lastusednewshist], esi
	mov [esi+newsitem.item], dx
	mov edx, [textrefstack]
	mov [esi+newsitem.textrefstack], edx
	mov edx, [textrefstack+4]
	mov [esi+newsitem.textrefstack+4], edx
	mov edx, [textrefstack+8]
	mov [esi+newsitem.textrefstack+8], edx
	mov edx, [textrefstack+0Ch]
	mov [esi+newsitem.textrefstack+0Ch], edx
	mov edx, [textrefstack+10h]
	mov [esi+newsitem.textrefstack+10h], edx
	mov edx, [textrefstack+14h]
	mov [esi+newsitem.textrefstack+14h], edx
	mov edx, [textrefstack+18h]
	mov [esi+newsitem.textrefstack+18h], edx
	mov edx, [textrefstack+1Ch]
	mov [esi+newsitem.textrefstack+1Ch], edx
	mov [esi+newsitem.type], bl
	or bh, 20h
	mov [esi+newsitem.flags], bh
	shr ebx, 10h
	mov [esi+newsitem.category], bx
	mov [esi+newsitem.par3], ax
	mov [esi+newsitem.par4], cx
	mov word [esi+newsitem.countdown], 555
	mov ax, [newsitemparam]
	mov [esi+newsitem.par1], ax
	mov ax, [newsitemparam+2]
	mov [esi+newsitem.par2], ax
	mov ax, [currentdate]
	mov [esi+newsitem.date], ax

	mov eax, [newshistoryptr]
	add eax, newsitem_size*NEWS_HISTORY_SIZE

	cmp byte [numnewsitems], NEWS_HISTORY_SIZE
	jne .notfull
	dec byte [numnewsitems]
	mov edi, [firstusednewshist]
	add edi, newsitem_size
	cmp edi, eax
	jnae .notfullwrap
	mov edi, [newshistoryptr]
.notfullwrap:
	mov [firstusednewshist], edi
.notfull:
	
	add esi, newsitem_size
	cmp esi, eax
	jnae .nowrap
	mov esi, [newshistoryptr]
.nowrap:
	mov [firstfreenewshist], esi
	inc byte [numnewsitems]


	// redraw the window
	mov al, 0x2A
	mov bx, 101
	call [invalidatehandle]

.done:
	popa
	cmp byte [gamemode], 0
	ret

	
var win_newshistory_elements
	db cWinElemTextBox, cColorSchemeLightBlue
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeLightBlue
	dw 11, 350, 0, 13, ourtext(messages)
	db cWinElemTiledBox, cColorSchemeLightBlue
	dw 0, 339, 14, 223, 0x0501
	db cWinElemSlider, cColorSchemeLightBlue
	dw 340, 350, 14, 211, 0
	db cWinElemSizer, cColorSchemeLightBlue
	dw 340, 350, 212, 223, 0
	db cWinElemExtraData, cWinDataSizer
	dd win_newshistory_constraints, win_newshistory_sizes
	dw 0
	db cWinElemLast

//bit set: move when size changes
//bit 0: x1
//bit 1: x2
//bit 3: y1
//bit 4: y2
var win_newshistory_constraints
	db 0000b
	db 0010b
	db 1010b
	db 1011b
	db 1111b
	db 0
	db 0000b

var win_newshistory_sizes
	dw 300, 600
	db 1, 0
	dw 0	// min, max, stepsize, tiledboxidx, stepadd
	dw 56, 1024
	db 42, 2
	dw 14

global NewsMenuWindowHandler
NewsMenuWindowHandler:
	mov dx, [esi+window.data + 2]
	mov cx, [esi+window.data + 4]
	pusha

	cmp cx, 24
	jne .origfunc
	cmp dl, 0
	jne .origfunc

	// close the menu
	call [DestroyWindow]

	// create our window...
	mov cl, 0x2A
	mov dx, 101
	call [BringWindowToForeground]
	jnz .alreadyopen
	
	mov bx, [win_newshistory_elements+4*12+8]
	inc bx
	shl ebx, 16
	mov bx, [win_newshistory_elements+4*12+4]
	inc bx
	mov eax, 30 + (30 << 16)
	mov cx, 0x2A
	mov dx, -1
	mov ebp, addr(NewsHistWindowHandler)
	call [CreateWindow]
	mov dword [esi+24h], win_newshistory_elements
	mov word [esi+6h], 101
	mov ax, [esi+window.height]
	mov cl, 42
	sub ax, 14
	div cl
	mov byte [esi+window.itemsvisible], al
	or word [esi+window.flags], 800h		//element list can be changed
.alreadyopen:

.skiporig:
	pop eax
	popa
	ret

.origfunc:
	popa
	ret

NewsMessageClicked:
	sub dx, [esi+window.y]
	sub dx, 14
	// dx == y-coordinate relative to top-left of tiled-box
	mov ax, dx
	xor dx, dx
	mov bx, 42
	div bx
	// ax == relative index of message
	add ax, [esi+window.itemsoffset]
	movzx eax, ax
	// eax == message index relative to lastusednewshist
	mov edi, [lastusednewshist]
	or edi, edi
	jnz .used
	jmp .notused
.used:
	imul eax, newsitem_size
	sub edi, eax
	cmp edi, [newshistoryptr]
	jnb .notwrong
	add edi, newsitem_size*NEWS_HISTORY_SIZE
.notwrong:
	// now edi is the news message
	cmp byte [edi+newsitem.type], 0xFF
	je .notused

#if 0
	test byte [edi+newsitem.flags], 8
	jnz .viewvehicle
	test byte [edi+newsitem.flags], 4
	jz .notused

	mov bx, [edi+newsitem.par1]
	rol bx, 4
	mov ax, bx
	mov cx, bx
	rol cx, 8
	and ax, 0FF0h
	and cx, 0FF0h
	push edi
	call [setmainviewxy]
	pop edi
	jnc .notused
	mov bx, [edi+newsitem.par2]
	or bx, bx
	jz .notused
	rol bx, 4
	mov ax, bx
	mov cx, bx
	rol cx, 8
	and ax, 0FF0h
	and cx, 0FF0h
	call [setmainviewxy]
	ret

.viewvehicle:
	movzx esi, byte [edi+newsitem.par1]
	shl esi, 7
	add esi, [veharrayptr]
	mov ax, [esi+veh.xpos]
	mov cx, [esi+veh.ypos]
	call [setmainviewxy]
#endif
	
	mov eax, [edi+newsitem.textrefstack+0x00]
	mov [textrefstack+0x00], eax
	mov eax, [edi+newsitem.textrefstack+0x04]
	mov [textrefstack+0x04], eax
	mov eax, [edi+newsitem.textrefstack+0x08]
	mov [textrefstack+0x08], eax
	mov eax, [edi+newsitem.textrefstack+0x0C]
	mov [textrefstack+0x0C], eax
	mov eax, [edi+newsitem.textrefstack+0x10]
	mov [textrefstack+0x10], eax
	mov eax, [edi+newsitem.textrefstack+0x14]
	mov [textrefstack+0x14], eax
	mov eax, [edi+newsitem.textrefstack+0x18]
	mov [textrefstack+0x18], eax
	mov eax, [edi+newsitem.textrefstack+0x1C]
	mov [textrefstack+0x1C], eax
	mov eax,[edi+newsitem.par1]
	mov [newsitemparam],eax
	mov bx, [edi+newsitem.category]
	shl ebx, 0x10
	mov bl, [edi+newsitem.type]
	mov bh, [edi+newsitem.flags]
	or bh, 0x10
	mov ax, [edi+newsitem.par3]
	mov cx, [edi+newsitem.par4]
	mov dx, [edi+newsitem.item]
	mov byte [newsalreadyadded], 1
	call [newsmessagefn]
	mov byte [newsalreadyadded], 0
.notused:
	ret

NewsHistClick:
	push bx
	call [WindowClicked]
	pop dx
	jns .click
.exit:
	ret
.click:
	cmp byte [rmbclicked], 0
	jne .exit

	cmp cl, 0
	jnz .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cl, 1
	jnz .nowindowtitlebarclicked
	jmp [WindowTitleBarClicked]
.nowindowtitlebarclicked:
	cmp cl, 2
	jnz .nomessageclicked
	jmp NewsMessageClicked
.nomessageclicked:
	ret

NewsHistWindowHandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz NewsHistRedraw
	cmp dl, cWinEventClick
	jz NewsHistClick
	ret

NewsHistRedraw:
	mov al, [numnewsitems]
	mov [esi+window.itemstotal], al
	call [DrawWindowElements]
	mov edi, [lastusednewshist]
	or edi, edi
	jnz .hasitems
	jmp .finished
.hasitems:

// 	movzx eax, byte [numnewsitems]
// 	mul eax, newsitem_size
// 	add edi, eax
	
	movzx eax, byte [esi+window.itemsoffset]
	imul eax, newsitem_size
	sub edi, eax
	cmp edi, [newshistoryptr]
	jnb .notwrong1
	add edi, newsitem_size*NEWS_HISTORY_SIZE
.notwrong1:

	mov cx, [esi+window.x]
	add cx, 2
	mov dx, [esi+window.y]
	add dx, 15

	movzx eax, byte [esi+window.itemsvisible]
.drawnext:
	push eax

	cmp byte [edi+newsitem.type], 0xFF
	jne .used
	jmp .notused
.used:
	pusha
	// draw the date
	mov ax, [edi+newsitem.date]
	mov [textrefstack], ax
	mov bx, 0x01FF
	mov edi, [currscreenupdateblock]
	call [drawtextfn]
	popa
	// draw the message
	cmp byte [edi+newsitem.type], 0x03
	jb .normal
	ja near .notused

	// type 3 uses opclass function, which in turn uses the statusbar textrefstack
	pusha
	push esi
	push cx
	push dx

	mov edx,[statusbarnewsitem]
	mov ebx,edi

	// so first we make a copy of the current status bar data
	mov esi,edx
	mov edi,tmpbuffer2
	mov ecx,newsitem_size
	rep movsb

	// then write the current news item over there
	mov esi,ebx
	mov edi,edx
	mov cl,newsitem_size
	rep movsb

	// and call the function handler to prepare the real text stack
	pusha
	xor edi,edi	// to make it format it like for the status bar
	movzx esi,word [ebx+newsitem.par3]
	movzx ebx,word [ebx+newsitem.par4]
	mov ebp,[ophandler+esi]
	call [ebp+4]
	mov [esp+0x1c],ax	// text ID
	popa

	// now restore the status bar
	mov esi,tmpbuffer2
	mov edi,edx
	mov cl,newsitem_size
	rep movsb

	mov edi,ebx
	jmp short .formatnewsmessage

.normal:
	pusha
	push esi
	push cx
	push dx
	mov eax, [edi+newsitem.textrefstack+0x00]
	mov [textrefstack+0x00], eax
	mov eax, [edi+newsitem.textrefstack+0x04]
	mov [textrefstack+0x04], eax
	mov eax, [edi+newsitem.textrefstack+0x08]
	mov [textrefstack+0x08], eax
	mov eax, [edi+newsitem.textrefstack+0x0C]
	mov [textrefstack+0x0C], eax
	mov eax, [edi+newsitem.textrefstack+0x10]
	mov [textrefstack+0x10], eax
	mov eax, [edi+newsitem.textrefstack+0x14]
	mov [textrefstack+0x14], eax
	mov eax, [edi+newsitem.textrefstack+0x18]
	mov [textrefstack+0x18], eax
	mov eax, [edi+newsitem.textrefstack+0x1C]
	mov [textrefstack+0x1C], eax
	mov ax, [edi+newsitem.item]

.formatnewsmessage:
	mov edi, tmpbuffer1
	call [ttdtexthandler]
	mov esi, tmpbuffer1
	mov edi, tmpbuffer2

.copyloop:
	mov al, [esi]
	inc esi
	or al, al
	jz .zero
	cmp al, 0Dh
	jz .lbl0Dh
	cmp al, 20h
	jb .copyloop
	cmp al, 88h
	jb .lbl88h
	cmp al, 99h
	jb .copyloop

.lbl88h:
	mov [edi], al
	inc edi
	jmp .copyloop

.lbl0Dh:
	mov dword [edi], 20202020h
	add edi, 4
	jmp .copyloop

.zero:
	mov [edi], al
	//draw it?
	mov dword [specialtext1], tmpbuffer2

	pop dx
	pop cx
	mov bx, statictext(special1)
	add dx, 9
	mov edi, [currscreenupdateblock]
	mov word [currentfont], 448
	pop esi
	movzx ebp, word [esi+window.width]
	sub ebp, 16
//	mov ebp, 335
	call [drawsplittextfn]
	popa
.notused:
	pop eax
	add dx, 42
	cmp edi,[firstusednewshist]
	je .finished
	sub edi,newsitem_size
	cmp edi, [newshistoryptr]
	jnb .notwrong2
	add edi, newsitem_size*NEWS_HISTORY_SIZE
.notwrong2:
	dec eax
	jnz .drawnext
.finished:
	ret

uvarb tmpbuffer1,512
uvarb tmpbuffer2,512
