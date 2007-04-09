
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
	mov al,[human1]

	call countshares

	mov cl,[esi+6]
	mov ch,[landscape3+ttdpatchdata.orgpl1]

	cmp al,cl	// clicking on own button?
	je .done

	// is it maybe the player going back to his original company?
	cmp cl,ch
	je short .setplayer

	// no, so see if companies are related
	movzx eax, al
	bt [ebx+player2ofs+player2.related], eax
	jnc short .done

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

exported buysellshare
	call $+5
ovar .oldfn,-4,$,buysellshare
	call redrawscreen
	// fall through

exported makerelations
// Set company relations
// eax: share owners
// ebx->player array
// dl: related company mask
// ecx: counter
	push 7
	pop ecx
	sub esp, 8
	mov ebp, esp
	// Locals [ebp+0]..[ebp+7]: related masks for companies 0..7
	push ecx
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
	shl eax, 8
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

// All relationships determined. Store.
	pop ecx
.loop3:
	mov eax, player_size
	mul ecx
	extern player2array
	add eax, [player2array]
	mov bl, [ebp+ecx]
	mov [eax+player2.related],bl

	dec ecx
	jns .loop3

	add esp, 8
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
	mov al,[human1]
	mov ah,[landscape3+ttdpatchdata.orgpl1]

//	mov edx,dword [playerwndbase]		// Human Player, "View HQ"
	mov edx, dword [comp_humanview]

	cmp al,[esi+6]
	je short .ishuman

	cmp ah,[esi+6]
	je short .domanage

//	add edx,byte 0x61				// AI Player, "View HQ"
	mov edx, dword [comp_aiview]

	// is an AI company; can we take it over?
	
	movzx eax, al
	extern player2ofs
	bt [ebx+player2ofs+player2.related], eax

	jnc short .nope

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
