// morebuildoptions

#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <town.inc>
#include <industry.inc>
#include <bitvars.inc>
#include <ptrvar.inc>

extern cleartilefn,curplayerctrlkey,locationtoxy,morebuildoptionsflags
extern patchflags
extern pushownerontextstack
extern industrydestroymultis

var morestationspritebase, dw -1
uvard nummorestationgraphics

// in:	AX,CX = X,Y location
//	DX,DI from [gettileinfo]
//	BL = constr. flags
// safe:all except EAX,ECX,EDI?
global removeobject
removeobject:
	mov word [operrormsg2],0x5800	// "object in the way"
	call locationtoxy
	mov dl,[landscape1+esi]

	mov ebp,patchflags
	testflagbase ebp

	testmultiflags morebuildoptions
	jz .normal
	test byte [morebuildoptionsflags],MOREBUILDOPTIONS_REMOVEOBJECTS
	jz .normal
	cmp byte [curplayerctrlkey],1
	jz .remove

.normal:
	testmultiflags morethingsremovable
	jz .fail
	test bl,2
	jnz .fail
	cmp dh,2
	je .chkremove

.fail:
	testflagbase none

	// replicate the overwritten code
	mov ebx,0x80000000
	ret

.chkremove:
	mov word [operrormsg2],0x13b	// "owned by..."
	cmp dl,[curplayer]
	je .remove

	mov ebp,textrefstack
	call [pushownerontextstack]
	jmp .fail

.remove:
	call dword [cleartilefn]	// preserves all registers

	test bl,1
	jz .done

	pusha
	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,1
	xchg eax,esi
	call [ebp+4]		// returns the nearest town ptr in EDI and distance in BP; scrambles BX,ESI
	mov [esp+4],edi		// put the pointer in ESI
	popa

	cmp dh,2
	jne .done

	// check if there are any statues left in this town
	pusha
	xor ecx,ecx
	xor eax,eax

.chkstatueloop:
	mov bl,[landscape4(ax,1)]
	and bl,0xf0
	cmp bl,0xa0
	jne .chkstatuenexttile
	cmp dh,[landscape5(ax,1)]	// DH=2
	jne .chkstatuenexttile
	cmp dl,[landscape1+eax]
	jne .chkstatuenexttile

	mov ebp,[ophandler+(3*8)]
	xor ebx,ebx
	mov bl,1
	call [ebp+4]		// returns the nearest town ptr in EDI and distance in BP; scrambles BX,ESI
	cmp edi,[esp+4]		// this town?
	jne .chkstatuenexttile
	inc ecx			// count this town's this company's statues in ECX

.chkstatuenexttile:
	inc ax
	jnz .chkstatueloop

	or ecx,ecx
	popa
	jnz .done

	cmp dl,8
	jae .done		// just in case

	movzx edx,dl
	btr [esi+town.havestatue],edx

.done:
	mov ebx,[housermbasecost]
	sar ebx,2
	lea ebx,[ebx*5]
	ret
;endp removeobject


global removeindustry
removeindustry:
	cmp byte [gamemode], 2
	je .editormode
	cmp byte [curplayerctrlkey],1
	jz .doit
	clc
	ret
.doit:
	testflags newindustries
	jc .doit_newcost
	mov edi,[housermbasecost]
	imul edi, 1000
.editormode:
	stc
	ret

.doit_newcost:
	movzx edi,byte [esi+industry.type]
	mov edi,[industrydestroymultis+edi*4]
	imul edi,[housermbasecost]
	stc
	ret
;endp removeindustry

global industryallowedtobuild
industryallowedtobuild:
	// check industry type
	cmp bl, [esi+industry.type]
	jnz .nocheckneeded	// type is different
	
	cmp ebp, [esi+industry.townptr]
 	jz .checkindustriedistance

.nocheckneeded:
	clc
	ret

.checkindustriedistance:
	test byte [morebuildoptionsflags],MOREBUILDOPTIONS_CLOSEINDUSTRIES
	jnz .nocheckneeded

	// di is xy of the new industry
	push eax
	push edx
	mov edx, [esi+industry.XY]
	mov eax,edi
	sub al,dl
	jnc .x
	neg al
.x:
	sub ah,dh
	jnc .y
	neg ah
.y:
	add al,ah
	jc .nextinloop 	// really far away

	cmp al, 8 		// could be fine tuned,
				// 8 seems to be a good value...
	ja .nextinloop	// far away

	// error to near 
	pop edx
	pop eax
	stc
	ret

.nextinloop:
	pop edx
	pop eax
	clc	
	ret // next in loop
;endp industryallowedtobuild

global placebuoy
extern adjflags
placebuoy:
	cmp byte [curplayerctrlkey],1
	je .special
	test BYTE [adjflags], 2
	jnz .special
	mov byte [esi+station.owner],0x10	// overwritten
	xor al,al				// ditto
	ret

.special:
	mov al,[curplayer]
	mov [esi+station.owner],al
	and byte [esi+station.flags],~0x40
	mov [landscape1+edi],al
	xor al,al
	ret
