#if WINTTDX
#include <std.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <window.inc>
#include <windowext.inc>
#include <imports/gui.inc>
#include <misc.inc>
#include <win32.inc>


varb serverhostip
	db 'localhost'
	times 64 db 0
endvar

uvard framecounter, 0

varb MPDLL,'ttdpatchmp.dll',0
uvard lMPDLL
uvard ASObject

%macro mpimport 2-3
	%ifstr %3 
		varb %%1_txt, %3, 0
		push %%1_txt
		mov dword [specialerrtext2], %%1_txt
	%else
		%tostr %%2, %2
		varb %%1_txt, %%2, 0
		push %%1_txt	
		mov dword [specialerrtext2], %%1_txt
	%endif
	push dword [%1]
	call dword [GetProcAddress] // GetProcAddress(lDxMciMidi, "aDxMidiGetVolume")
	mov	dword [%2], eax
%endmacro

%macro stackalign 0
	push ebp
	mov	ebp, esp
	and	esp, byte ~ 3	// 4 byte boundry
%endmacro


// imports
uvard ASNetworkStart
uvard ASClientDisconnect
uvard ASClientConnect
uvard ASClientFree
uvard ASClientSend
uvard ASClientSendDone
uvard ASClientReceive
uvard ASClientHasNewData
uvard ASClientGetLastError

guiwindow win_asynmp,200,200
	guicaption cColorSchemeDarkGreen, 0x0145
	guiele background,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,-x2,0,y,14,-y2,0,data,0
	db cWinElemSetTextColor, 0x10
	dw 0, 0, 0, 0, 0
	guiele ipframe,cWinElemPushedInBox,cColorSchemeDarkGreen,x,10,-x2,10,y,20,h,12,data,0
	guiele ipchange,cWinElemTextBox,cColorSchemeDarkGreen,-x,22,-x2,11,y,21,h,10,data,statictext(ellipsis)
	guiele doconnect, cWinElemTextBox,cColorSchemeDarkGreen,x,10,-x2,10,-y,20,h,10,data,0x0146
endguiwindow


exported AsyncMPConnectStart
	cmp byte [numplayers], 1
	jz .startmp
	ret
.startmp:
	mov cl, cWinTypeLinkSetup
	xor dx, dx
	extern FlashWindow
	call [FlashWindow]
	jnz .windowopen
	
	mov eax, 286 + (22<<16)
	mov ebx, win_asynmp_width + (win_asynmp_height << 16)
	mov cx, cWinTypeLinkSetup
	mov dx, -1
//	mov ebp, 0x55932E // old serial window handler
	mov ebp, AsyncMPConnectWindow_Handler

	call dword [CreateWindow]
	mov dword [esi+window.elemlistptr], win_asynmp_elements
//	mov dword [esi+window.elemlistptr], 0x433D78	// old window elements
.windowopen:
	ret

AsyncMPConnectWindow_Clickhandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
	movzx eax,cl
	cmp byte [rmbclicked],0
	jne .rmb
	cmp cl, win_asynmp_elements.caption_close_id
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cl, win_asynmp_elements.caption_id
	jne .nottilebar
	jmp dword [WindowTitleBarClicked]
.nottilebar:
	cmp cl, win_asynmp_elements.ipchange_id
	jne .noipchange
	call AsyncMPConnectWindow_pressit
	push esi
	mov ecx, 48
	mov esi, serverhostip
	mov edi, baTempBuffer1
	rep movsb
	
	xor ecx, ecx
	mov ax, -1		// no start textid
	mov ch, 60		// byte
	mov bl, 200		// pixel length
	
	// owner window:
	xor edx, edx
	mov cl, cWinTypeLinkSetup
	mov bp, 0x2AA	// text id of caption
	call [CreateTextInputWindow]
	mov byte [bEditedWindowText], 1
	pop esi
 .noipchange:
 	cmp cl, win_asynmp_elements.doconnect_id
	je .doconnect
	ret
.doconnect:
	call AsyncMPConnectWindow_pressit
	jmp AsyncMPConnect	
	ret
.rmb:
 	// generate tooltips
	//mov ax, [_tooltips+eax*2]
	//jmp [CreateTooltip]
	ret
	
	
AsyncMPConnectWindow_TextUpdate:
	cmp byte [bEditedWindowText], 1
	je .iphostedit
.iphostedit:
	push esi
	mov ecx, 64/4
	mov esi, baTextInputBuffer
	mov edi, serverhostip
	rep movsd
	pop esi
	mov al,[esi]
	mov bx,[esi+window.id]
	jmp [invalidatehandle]	
	
AsyncMPConnectWindow_pressit:
	movzx ecx, cl
	bts dword [esi+window.activebuttons], ecx
	or byte [esi+window.flags], 7
	mov al,[esi]
	mov bx,[esi+window.id]
	jmp [invalidatehandle]
	
AsyncMPConnectWindow_Handler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jz AsyncMPConnectWindow_Redraw
	cmp dl, cWinEventClick
	jz near AsyncMPConnectWindow_Clickhandler
	cmp dl, cWinEventTimer
	jz AsyncMPConnectWindowr_Timer
	cmp dl, cWinEventTextUpdate
	jz AsyncMPConnectWindow_TextUpdate
	ret
	
AsyncMPConnectWindow_Redraw:
	call [DrawWindowElements]
	
	push esi
	mov edi, serverhostip
	mov [specialtext1], edi
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add cx, 14
	add dx, 22
	
	mov word [textrefstack], statictext(special1)	
	mov edi, [currscreenupdateblock]
	mov bx, statictext(blacktext)
	mov bp, win_asynmp_width-40;
	mov dword [SplittextlinesMaxlines],1
	call [drawsplittextfn]
	pop esi
	ret
	
	
AsyncMPConnectWindowr_Timer:
	mov dword [esi+window.activebuttons], 0
	mov al,[esi]
	mov bx,[esi+window.id]
	call dword [invalidatehandle]
	ret


AsyncMPUnloadDLL:
	cmp	dword [lMPDLL], 0
	jz .notloaded
	
	mov eax, dword [ASObject]
	cmp eax, 0
	je .noopenconnection
	
	push dword [ASObject]
	call [ASClientDisconnect]
	add esp, 4

	push dword [ASObject]
	call [ASClientFree]
	add esp, 4
	mov dword [ASObject], 0

.noopenconnection:
	push dword [lMPDLL]
	call dword [FreeLibrary]
	mov dword [lMPDLL], 0
.notloaded:
	ret
	
// Network code
AsyncMPLoadDLL:
	cmp	dword [lMPDLL], 0
	jz .notloaded
	call AsyncMPUnloadDLL
	
.notloaded:
	extern specialerrtext2
	mov dword [specialerrtext2], MPDLL
	push MPDLL
	call dword [LoadLibrary] 
	test eax,eax
	jz near .failed
	mov	dword [lMPDLL], eax

	mpimport lMPDLL, ASNetworkStart
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASNetworkStart
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASClientDisconnect
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASClientConnect
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASClientFree
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASClientSend
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASClientSendDone
	test eax,eax
	jz near .failedimport	
	mpimport lMPDLL, ASClientReceive
	test eax,eax
	jz near .failedimport
	mpimport lMPDLL, ASClientHasNewData
	test eax,eax
	jz near .failedimport
.done:	
	clc
	ret
.failedimport:
.failed:
	mov word [textrefstack], statictext(specialerr2)
	mov bx,ourtext(grferror)
	mov dx,-1
	xor ax,ax
	xor cx,cx
	extern errorpopup
	call [errorpopup]
	stc
	ret

exported AsyncMPConnect
	stackalign

	call AsyncMPLoadDLL
	jc .failed
	
	call [ASNetworkStart]
	add esp, 4
	test eax, eax
	jnz .failed
	
	push dword 5483
	push serverhostip
	call [ASClientConnect]
	add esp, 8
	test eax, eax
	jz .failed
	mov [ASObject], eax
	
	mov dword [baTempBuffer1], 'TTDP'
	mov dword [baTempBuffer1+4], 'ATCH'
	extern ttdpatchvercode
	mov eax, [ttdpatchvercode]
	mov dword [baTempBuffer1+8], eax
	
	push dword 12
	push dword baTempBuffer1
	push dword [ASObject]
	call [ASClientSend]
	add esp, 12
	
.failed:	
	call AsyncMPUnloadDLL
	leave
	ret
	
AsyncMPDisconnect:
	stackalign
	call AsyncMPUnloadDLL
	leave
	ret	

exported AsyncTickProcAllCompanies

	ret
	
exported AsyncMP27msWait
	
	ret
	
exported AsyncMPSendAction
	
	ret

exported AsyncMPSendEndAction
	
	ret
	
	

exported AsyncMPSyncPackageCreate
	
	ret

exported AsyncMPSyncPackageRecv
	
	ret
#endif
