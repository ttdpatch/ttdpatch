
// subsidiary management
// when owner of 75% of shares clicks on HQ, take over company
// temporarily

#include <std.inc>
#include <flags.inc>
#include <misc.inc>
#include <patchdata.inc>
#include <player.inc>
#include <ptrvar.inc>

extern actionhandler,isremoteplayer,patchflags,redrawscreen,setmousetool
extern setplayer_actionnum





// called when "view HQ" or "build HQ" button is pressed
// in:	ebx=player struct of player whose window is open
//	esi=window struct; [esi+6]=player whose window this is
// out:	carry if the company was taken over
//	otherwise, result of cmp [ebx.hqlocation],-1
// safe:eax ecx edx

global clickhq
clickhq:
	call getrelations
	jz .done	// clicking on own button?
	jnc .done	// not related?

.setplayer:
// can't set player directly because it must be sent to the other player as well
// do it in an action
	pusha
	mov dl,cl
	xor eax,eax
	xor ecx,ecx
	xor ebx,ebx
	inc bl
	dopatchaction setplayer
	mov al, 0
	mov ebx, 0
	call [setmousetool] 
	popa
	stc
	ret

.done:
	cmp word [ebx+player.hqlocation],byte -1		// was overwritten by call
	clc
	ret
; endp clickhq 

// Action to change current player's company.
global setplayer
setplayer:
	test bl,1
	jz .justthecost
	call redrawscreen
	movzx ebx,byte [curplayer]
 	mov [curplayer],dl
	mov edi,human1
	cmp [edi],bl
	je .gotplayer
#if WINTTDX
	testflags enhancemultiplayer
	jc .enhmulti_other
#endif
	inc edi
	cmp [edi],bl
	jne .done	// shouldn't happen
.gotplayer:
	mov [edi],dl
	extcall updatevehvars // update veh var 43
.done:
.justthecost:
	xor ebx,ebx
	ret

#if WINTTDX
.enhmulti_other:
	btr [isremoteplayer],ebx
	movzx edx,dl
	bts [isremoteplayer],edx
	xor ebx,ebx
	ret
#endif

// counts shares current player owns from player stored at ebx
// in:	al=curplayer
//	ebx=player window
// out:	ah=number of shares
// destroys ecx

countshares:
	mov ah,0
	xor ecx,ecx

.nextshare:
	cmp byte [ebx+player.shareowners+ecx],al
	jne short .notowner

	inc ah

.notowner:
	inc ecx
	cmp cl,4
	jb short .nextshare
	ret
; endp countshares 

uvarb relations,8 	// relationship masks for the eight companies
			// bit n of byte n is always set -- a company is always related to itself.
exported buysellshare
	call $+5
ovar .oldfn,-4,$,buysellshare
	call redrawscreen
	// fall through

exported makerelations
// Set company relations
// eax: share owners
// ebx->player struct
// dl: related company mask
// ecx: counter
	push 7
	pop ecx
	mov ebp, relations
	push ecx
.loop:
	mov dl, 1
	shl dl, cl // All companies are automatically related to themselves.

	mov ebx, player_size
	imul ebx,ecx
	push ecx
	add ebx, [playerarrayptr]
	cmp word [ebx], 0
	je .next
	mov eax, [ebx+player.shareowners]
	test al, al
	js .unowned
	push eax
	call countshares
	cmp ah, 3
	pop eax
	je .found
.unowned:
	shr eax, 8
	test al, al
	js .next
	call countshares
	cmp ah, 3
	jne .next

.found:
	movzx eax, al
	bts edx, eax
.next:
	pop ecx
	mov [ebp+ecx], dl
	dec ecx
	jns .loop

// Direct parentage determined. Combine masks.
// al: mask (reduced as relationships processed)
// ah: mask (grown as relationships processed)
// ecx: counter
	pop ecx
.loop2:
	movzx eax, byte [ebp+ecx]
	mov ah, al
.iloop:
	bsf esi, eax
	cmp esi, 8
	jae .next2
	btr eax, esi
	or ah, [ebp+esi]
	mov [ebp+esi], ah
	jmp short .iloop

.next2:
	cmp [ebp+ecx], ah
	mov [ebp+ecx], ah
	jne .loop2	// We found new relationships. Ensure all related companies have all necessary bits set before continuing.
	dec ecx
	jns .loop2

	ret

	align 4
uvard playerwndbase
uvarb manageaiwindow,0x79
uvard comp_humanview
uvard comp_humanbuild
uvard comp_aiview
var comp_aimanage,dd manageaiwindow

// called whenever a player window is redrawn
//
// in:	esi=windows struct
//	ebx=player
// out: no zero flag
// safe:eax ecx edx
global redrawplayerwindow
redrawplayerwindow:
	call getrelations

//	mov edx,dword [playerwndbase]		// Human Player, "View HQ"
	mov edx, dword [comp_humanview]

	je short .ishuman	// Current player

//	add edx,byte 0x61			// AI Player, "View HQ"
	mov edx, dword [comp_aiview]

	jnc short .nope		// Can't manage company

.domanage:
//	mov edx,manageaiwindow	// AI Player, "Manage"
	mov edx, [comp_aimanage]

.nope:
	mov [esi+0x24],edx
	jmp short .done

.ishuman:
	// decide whether to show "Build HQ" or "View HQ"
	cmp word [ebx+player.hqlocation],byte -1
	jne short .setit

//	sub edx,byte 0x61				// Human Player, "Build HQ"
	mov edx, [comp_humanbuild]

.setit:
	mov [esi+0x24],edx

.done:
	or al,1
	ret
; endp redrawplayerwindow

// compares [esi+6] to [human1]
// Out: ecx set to [esi+6]
//	eax set to [human1]
//	Z if they are the same company
//	C if they are related companies
getrelations:
	movzx eax, byte [human1]
	movzx ecx, byte [esi+6]
	cmp al,cl
	bt [ecx+relations], eax
	ret

