
#include <std.inc>
#include <textdef.inc>
#include <human.inc>
#include <window.inc>

extern BringWindowToForeground,CreateWindowRelative,DestroyWindow
extern DrawWindowElements,FindWindow,RefreshWindowArea,WindowClicked
extern WindowTitleBarClicked,cargotypenamesptr,ctrlkeystate,drawrighttextfn
extern drawtextfn




#include "stats.ah"

uvard companystatsptr

global companystatsclear
companystatsclear:
	mov edi, [companystatsptr]
	mov ecx, 8*32
	xor eax,eax
	rep stosd
	ret

global acceptvehiclecargo
acceptvehiclecargo:
	movzx esi, byte [curplayer]
	pusha
	pusha
	mov dx, si
	or dx, 0x8000
	mov cl, 0x1D
	call [FindWindow]
	call [RefreshWindowArea]
	popa
	shl esi, 7 // esi=esi*4*32
	add esi, [companystatsptr]
	movzx ecx, ch
	shl ecx, 2
	movzx edx, bx
	add [esi+ecx], edx
	popa
	ret

var player1CompanyWindowElemList
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, 359, 0, 13, 0x7001
	db cWinElemSpriteBox, cColorSchemeGrey
	dw 0, 359, 14, 157, 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 89, 158, 169, 0x7004
	db cWinElemTextBox, cColorSchemeGrey
	dw 90, 179, 158, 169, 0x7005
	db cWinElemTextBox, cColorSchemeGrey
	dw 180, 269, 158, 169, 0x7009
	db cWinElemTextBox, cColorSchemeGrey
	dw 270, 359, 158, 169, 0x7008
	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 18, 29, 0x706F
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0

	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 32, 43, ourtext(statistics)
	db cWinElemLast

var player1CompanyWHQWindowElemList
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, 359, 0, 13, 0x7001
	db cWinElemSpriteBox, cColorSchemeGrey
	dw 0, 359, 14, 157, 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 89, 158, 169, 0x7004
	db cWinElemTextBox, cColorSchemeGrey
	dw 90, 179, 158, 169, 0x7005
	db cWinElemTextBox, cColorSchemeGrey
	dw 180, 269, 158, 169, 0x7009
	db cWinElemTextBox, cColorSchemeGrey
	dw 270, 359, 158, 169, 0x7008
	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 18, 29, 0x7072
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0

	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 32, 43, ourtext(statistics)
	db cWinElemLast

var otherCompanyWindowElemList
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, 359, 0, 13, 0x7001
	db cWinElemSpriteBox, cColorSchemeGrey
	dw 0, 359, 14, 157, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 18, 29, 0x7072
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 179, 158, 169, 0x7077
	db cWinElemTextBox, cColorSchemeGrey
	dw 180, 359, 158, 169, 0x7078
	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 32, 43, ourtext(statistics)
	db cWinElemLast

global otherCompanyManageWindowElemList.hqmanagebutton
var otherCompanyManageWindowElemList
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, 359, 0, 13, 0x7001
	db cWinElemSpriteBox, cColorSchemeGrey
	dw 0, 359, 14, 157, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemDummyBox, cColorSchemeGrey
	dw 0, 0, 0, 0, 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 18, 29
.hqmanagebutton: dw 0x7073
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 179, 158, 169, 0x7077
	db cWinElemTextBox, cColorSchemeGrey
	dw 180, 359, 158, 169, 0x7078

	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 355, 32, 43, ourtext(statistics)
	db cWinElemLast

varw companywintooltips
	dw 0x018B
	dw 0x018C
	dw 0
	dw 0x7030
	dw 0x7031
	dw 0x7032
	dw 0x7033
	dw 0x7070
	dw 0x7079
	dw 0x707A
	dw ourtext(statistics_tooltip)
endvar	

global companywindowclicked
companywindowclicked:
	jne .noskip
	add dword [esp], 0xB9
.noskip:
	cmp cl, 10
	je .statistics
	ret

.statistics:
	bts dword [esi+window.activebuttons], 10
	or word [esi+window.flags], 5
	push ax
	push bx
	mov bx, [esi+window.id]
	mov al, [esi+window.type]
	or al, 80h
	mov ah, 10
	call [RefreshWindowArea]
	pop bx
	pop ax

	mov dx, [esi+window.id]
.openstatistics:
	or dx, 0x8000
	mov cl, 0x1D // cWinTypeCompany
	call [BringWindowToForeground]
	jnz .done

	push dx
	mov cx, 0x1D
	mov ebx, CompanyStats_width + (CompanyStats_height << 16)
	mov dx, -1
	mov ebp, addr(CompanyStatsWinHandler)
	call [CreateWindowRelative]
	mov dword [esi+window.elemlistptr], CompanyStatsElems
	pop dx
	mov [esi+window.id], dx
	mov [esi+window.company], dl
.done:
	ret

global opencompanywindow
opencompanywindow:
        push byte PL_DEFAULT
	call ctrlkeystate
	jz .stats
	mov cl, 0x1D	// cWinTypeCompany
	call [BringWindowToForeground]
	ret
.stats:
	pop eax
	jmp companywindowclicked.openstatistics

CompanyStatsWinHandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	je CompanyStatsWinRedraw
	cmp dl, cWinEventClick
	je CompanyStatsWinClick
	ret
	
CompanyStatsWinClick:
	call [WindowClicked]
	jns .click
.exit:
	ret
.click:
	cmp byte [rmbclicked], 0
	jne .exit

	cmp cx, CompanyStats_closebox
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cx, CompanyStats_titlebar
	jne .notitlebar
	jmp [WindowTitleBarClicked]
.notitlebar:
	ret
	
CompanyStatsWinRedraw:
	mov ax, [esi+window.height]
	sub ax, 31
	mov cl, 10
	idiv cl
	mov [esi+window.itemsvisible], al
	mov [esi+window.data], al
	mov al, [esi+window.itemsoffset]
	mov [esi+window.data+1], al

	movzx ebx, byte [esi+window.company]
	shl ebx, 7
	add ebx, [companystatsptr]
	push ebx
	xor ax,ax
	mov ecx, 32
.countloop:
	cmp dword [ebx], 0
	jz .countnext
	inc ax
.countnext:
	add ebx, 4
	loop .countloop
	mov byte [esi+window.itemstotal],al

	call [DrawWindowElements]
	pop ebx

	mov eax, [cargotypenamesptr]
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, 10
	add dx, 30
	mov eax, 0
.cargoloop:
	pusha
	mov ebx, [ebx]
	cmp ebx, 0
	je .next
	dec byte [esi+window.data+1]
	jns .next
	pusha
	mov ebx, [cargotypenamesptr]
	mov bx, [ebx+eax*2]
	mov ax, 8
	call [drawtextfn]
	popa
	mov dword [textrefstack], ebx
	add cx, 170
	mov bx, statictext(whitedword)
	call [drawrighttextfn]
	popa
	add dx, 10
	dec byte [esi+window.data]
	jmp .con
.next:
	popa
.con:
	add ebx, 4
	inc ax
	cmp al, 32
	jae .done
	cmp byte [esi+window.data],0
	jne .cargoloop
.done:
	ret

global companywindowtimer
companywindowtimer:
	btr dword [esi+window.activebuttons], 10
	jnb .nostats
	mov bx, [esi+window.id]
	mov al, [esi+window.type]
	or al, 80h
	mov ah, 10
	call [RefreshWindowArea]
.nostats:
	btr dword [esi+window.activebuttons], 4
	jb .noskip
	add dword [esp], 1+0x0F
.noskip:
	ret
