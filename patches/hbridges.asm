// Higher Bridges by Oskar Eisemuth
//
// Drawing Pieces under the Bridge isn't the fastest and best way,
// but in code size the smallest and easiest.
// Feel free to improve :)

#include <std.inc>
#include <textdef.inc>
#include <ptrvar.inc>
#include <flags.inc>

extern addgroundsprite,addsprite,bridgeflags
extern correctexactalt.getfoundationtype,getbridgefoundationtype
extern getgroundaltitude,gettileinfo,gettrackfoundationtype,landscape7_ptr
extern locationtoxy
extern redrawscreen,addrelsprite,patchflags





global bridgedrawrailunder
bridgedrawrailunder:
	cmp esi, 4
	jbe .railpiece
	call [addgroundsprite]
	ret

.railpiece:
	pusha 
// we want to draw a rail sprite...
	mov dh, 1
	je .nototherdir 
	mov dh, 2
.nototherdir:
	xor esi, esi
	rol cx, 8
	mov si, cx
	rol cx, 8
	or si, ax
	ror si, 4

	mov bl,[landscape2+esi]			// save L2
	push bx
	mov byte [landscape2+esi], 1		// fake L2, on grass, no fences 
	test word [landscape3+esi*2], 8000h
	jz .nosnow
	mov byte [landscape2+esi], 0xC	// no, it's snow or dessert...
.nosnow:
	xchg esi, ebx

	mov ebp,[ophandler+1*8]
	call dword [ebp+0x1c]			// normal rail piece draw land
	pop bx
	mov [landscape2+esi], bl		// and restore L2
	popa
	ret
;endp bridgedrawrouteunder

global bridgedrawroadunder
bridgedrawroadunder:
	pusha
	mov dh, 5
	cmp esi, 4
	jz .dirright
	mov dh, 10
.dirright:
	xor esi, esi
	rol cx, 8
	mov si, cx
	rol cx, 8
	or si, ax
	ror si, 4
	mov bl,[landscape2+esi]
	push bx
	mov byte [landscape2+esi], 1 // fake L2 
	xchg esi, ebx

	mov ebp,[ophandler+2*8]
	call dword [ebp+0x1c]	// call normal road piece draw land, supports buildonslopes aswell.
	pop bx
	mov [landscape2+esi], bl
	popa
	ret
;endp bridgedrawrouteunderroad

global bridgedrawmiddlepart
bridgedrawmiddlepart:
	mov edi, [esp+4]
	mov [bridgedrawmiddlepartpillardir], edi
	add dl, 5
	xor edi, edi
	rol cx, 8
	mov di, cx
	rol cx, 8
	or di, ax
	ror di, 4
	add dl, [landscape7+edi]

	extern aquamiddlebridgesprites
	cmp DWORD [esp+8], aquamiddlebridgesprites
	je .fixoffset
	mov di, 10h
//	mov si, 0Bh
//	test byte [esp+4], 10h
	ret
.fixoffset:		//for aquaducts, gives other bridge types horrid clipping errors.
	mov di, 10h
	mov si, 10h
	test byte [esp+4], 10h
	jz loc_153C0E
	xchg di, si
loc_153C0E:
	mov dh, 1

	pusha		//helper sprite
	//mov di, 0x10
	//mov si, di
	mov ebx, 0x1322
	call [addsprite]
	popa
	
	pusha
	mov ax, 31
	xor cx, cx
	call [addrelsprite]
	popa

	add DWORD [esp], 0x15

//aquaducts do not need tram sprite addition checking...
/*	testflags buildonslopes
	jnc .ret1
	extern drawTramBridgeMiddlePart
	call drawTramBridgeMiddlePart
.ret1:
*/
	ret
;endp bridgedrawmiddlepart


bridgedrawmiddlepartpillargettileinfo:
	pusha
	xor esi, esi
//	mov edi, [landscape7ptr]
//	or edi,edi
//	jz .no_l7
	and al, 0xF0
	and cl, 0xF0
	call [gettileinfo]
	mov edx,esi
//	add esi, [landscape7ptr]

	mov al, [landscape7+esi]
	mov ah, al

	test dword [bridgedrawmiddlepartpillardir], 10h
	jz .otherdirection
	mov bx, 0
	mov cx, 3
	jmp .doslopecheck
.otherdirection:
	mov bx, 2
	mov cx, 3

.doslopecheck:
	bt di, bx
	jnc .nofix
	sub al, 8
	.nofix:
	mov [bridgedrawmiddlepartpillaheightfront], al

	bt di, cx
	jnc .nofixback
	sub ah, 8
	.nofixback:

	movzx esi,byte [landscape2+edx]
	shr esi,4
	test byte [bridgeflags+esi],1
	jz .dodrawbackpillar

	mov ah,0

.dodrawbackpillar:
	mov [bridgedrawmiddlepartpillaheightback], ah

.no_l7:
	popa
	ret
;endp bridgedrawmiddlepartpillargettileinfo

uvard bridgedrawmiddlepartpillardir, 1
uvarb bridgedrawmiddlepartpillaheightfront, 1
uvarb bridgedrawmiddlepartpillaheightback, 1

global bridgedrawmiddlepartpillar
bridgedrawmiddlepartpillar:
	//mov edi, [esp-4]
	//mov [bridgedrawmiddlepartpillardir], edi
	pusha

	call bridgedrawmiddlepartpillargettileinfo

	movzx ebp, byte [bridgedrawmiddlepartpillaheightfront]
	push edx

.next:
	push ebx
	mov di, 1 // otherwise Sprite sorting gets a bit screwed...
	mov si, 1
	mov dh, 1
	push ebp
	call [addsprite]
	pop ebp
	pop ebx
	cmp ebp, 0
	jz .backpillar
	sub dl, 8
	sub ebp, 8
	jmp .next
	
.backpillar:
	pop edx

	movzx ebp, byte [bridgedrawmiddlepartpillaheightback]
	test ebp,ebp
	jz .nobackpillar
	
// Second back pillar
	test dword [bridgedrawmiddlepartpillardir], 10h
	jz .otherdirection
	mov di, 0
	mov si, 0
	sub ax, 9
	jmp .next2
.otherdirection:
	mov di, 0
	mov si, 0
	sub cx, 9
.next2:

	
	mov dh, 1
	push edi
	push esi
	push ebx
	push ebp
	call [addsprite]
	pop ebp
	pop ebx
	pop esi
	pop edi

	cmp ebp, 0
	jz .done
	sub dl, 8
	sub ebp, 8
	jmp .next2

.nobackpillar:

.done:
	popa
	ret
;endp bridgedrawmiddlepartpillar:

global bridgemiddlezcorrectforpylonswires
bridgemiddlezcorrectforpylonswires:
	push edi
	cmp dword [landscape7_ptr],0
	jle .no_l7
	xor edi, edi
	rol cx, 8
	mov di, cx
	rol cx, 8
	or di, ax
	ror di, 4
	add dl, [landscape7+edi] 
.no_l7:
	pop edi
	ret
;endp bridgemiddlezcorrectforpylonswires

global bridgemiddlecheckifwirefit
bridgemiddlecheckifwirefit:
	cmp dword [landscape7_ptr],0
	jle .no_l7
	call locationtoxy
	cmp byte [landscape7+esi], 8		// can't be 0, because some slope ways make problems....
	jbe .no_l7
	stc
	ret
.no_l7:
	clc
	ret

;endp bridgemiddlecheckifwirefit


// In general we could pass the ground correction routine the vehicle direction via a variable,
// Then we could test the direction, pass in bridgevehzgroundcorrect the right z correction.
// In the movement patch below we could add them to the z.

global bridgemiddlezcorrect
bridgemiddlezcorrect:
	push edi
//	mov edi, [landscape7ptr]
//	or edi,edi
//	jz .no_l7
	
	push cx
	push ax
	and al, 0F0h
	and cl, 0F0h
	call [gettileinfo]
	pop ax
	pop cx
//	add esi, [landscape7ptr]
	//add dl, byte [esi]	// Other TTD functions will break if it's higher then 8
	mov dh, [landscape7+esi]
	mov byte [bridgevehzgroundcorrect], dh
.no_l7:
	pop edi
	add dl, 8
	xor dh, dh
	ret
;endp bridgemiddlezcorrect


global bridgemiddlezcorrectslope
bridgemiddlezcorrectslope:
	push edx
	bt dx, 8 // set if Y Bridge
	mov dh, 1 // so we set a X route under the bridge	
	jc .wasydir
	mov dh, 2 // so we set a Y route under the bridge
.wasydir:

	mov ebp,addr(gettrackfoundationtype)
	call correctexactalt.getfoundationtype
	pop ebx
	mov dh,bh
	ret


var bridgevehzgroundcorrect, db 0
global bridgevehzisonthebridge
bridgevehzisonthebridge:
	mov byte [bridgevehzgroundcorrect], 0
	push esi
	call [getgroundaltitude]
	pop esi
	add dl, byte [bridgevehzgroundcorrect]	// will be altered by above routine if necessary
	test dh, 1
	jz .belowbridge

// Don't ask me anymore how this routine works, it prevents vehicles below the bridge to start jumping...
	push dx
	sub dl, [esi+1eh]
	or dl, dl
	jns .positive
	neg dl
.positive:
	cmp dl, 2
	pop dx
	jb .small
	mov dl, [esi+1eh]
.small:
.belowbridge:
	ret
;endp bridgevehzisonthebridge

global bridgevehmaxspeed
bridgevehmaxspeed:
	push edx
	movzx esi, bx
	mov dh, byte [landscape5(si)]
	test dh, 0x40
	mov dh, 2
	jz .ending
//	mov esi, [landscape7ptr]
//	or esi,esi
//	jz .no_l7
	movzx esi, bx
//	add esi, [landscape7ptr]
	add dh, [landscape7+esi]
//.no_l7:
	cmp dl, dh
	jbe .nochange
.ending:
	pop edx
	ret
.nochange:
	pop edx
	add esp, 4
	ret
;endp bridgevehmaxspeed





// Building a bridge routines...

// This get a bit complicate
// The stack:
//		WORD:	construction flags
//		DWORD: cost so far
//		WORD:	southern end XY
//		WORD:	northern end XY
var buildbridgeheight, db 0

global bridgechecklandscapeforstartorend
bridgechecklandscapeforstartorend:
	call [gettileinfo] // overwritten by call
	pusha
	mov ebp,addr(getbridgefoundationtype)
	call ebp
	popa
	jbe .normal
	add dl, 8
.normal:
	cmp si, word [esp+10]
	jz .checkifheightsaregood
	mov [buildbridgeheight], dl
	ret
.checkifheightsaregood:
	cmp [buildbridgeheight], dl
	jnz .errornotsameheight
	ret
.errornotsameheight:
	// fall into bridgechecksexit
	mov word [operrormsg2], 0x500A 
;endp bridgechecklandscapeforstartorend

bridgechecksexit:
	add esp, 4
	pop bx
	pop ebp
	pop di
	pop dx
	mov ebx, 80000000h
	pop ecx
	pop eax
	ret
;endp bridgechecksexit

global bridgemiddlecheckslopeok
bridgemiddlecheckslopeok:
    cmp dh, 00h
    jne .skipTramTracks
    mov dh, [landscape3+esi*2]
.skipTramTracks:
	//fix coasts
	cmp bx, 6*8
	jne .notwater
	cmp dh, 1
	jne .notwater
	dec dh
.notwater:

	mov word [operrormsg2], ourtext(steepslopes) 
	// steep slopes not allowed
	test di, 0x10			// we don't like steep slopes do we?
	jnz .steepslope
	mov word [operrormsg2], ourtext(landhigherbridgehead) 
	or di, di
	jnz .issloped 
	cmp dl, [buildbridgeheight]
	ja .errortohigh
 	mov word [operrormsg2], 0x5009 // overwritten by call
	ret
.issloped:
	cmp dl, [buildbridgeheight]
	jae .errortohigh 
	mov word [operrormsg2], 0x5009 // overwritten by call
	ret
.steepslope:
.errortohigh:
	// convert xy to ax, cx (maybe we should add such a function to tools.asm)
	rol si, 4
 	mov ax, si
 	mov cx, si
 	rol cx, 8
 	and ax, 0FF0h
	and cx, 0FF0h
 	ror si, 4
	// now try to flash red at the tile, doesn't work sometimes, don't know why,
	// maybe doesn't work at all in DOS :/
	xchg [flashtilex], ax
	xchg [flashtiley], cx
	call redrawscreen
	jmp bridgechecksexit
;endp bridgemiddlecheckslopeok

global bridgeendsaveinlandscape
bridgeendsaveinlandscape:
	mov byte [landscape2+esi], dl
//	push edi
//	mov edi, [landscape7ptr]
//	or edi,edi
//	jz .no_l7
	mov byte [landscape7+esi], 0
//.no_l7:
//	pop edi
	ret
;endp bridgeendsaveinlandscape

global bridgemiddlesaveinlandscape
bridgemiddlesaveinlandscape:
	or byte [landscape3+edi*2], dl
	pusha

	call [gettileinfo]
	mov dh, [buildbridgeheight] 	
	sub dh, dl
	
//	mov edi, [landscape7ptr]
//	or edi,edi
//	jz .no_l7
	mov byte [landscape7+esi], dh
//.no_l7:
	popa
	ret
;endp bridgemiddlesaveinlandscape


global getnormalclassunderbridge
getnormalclassunderbridge:
//	push esi
	movzx edi, di
//	mov esi, [landscape7ptr]
//	or esi,esi
//	jz .no_l7
	mov byte [landscape7+edi], 0
//.no_l7:
//	pop esi
// overwritten
	mov dl, al
	and eax, 0x18
	shr eax, 1
	ret
;endp getnormalclassunderbridge
