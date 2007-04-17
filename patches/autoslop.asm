// todo list:
// station class
// switch
// cross platform
// add costs

#include <std.inc>
#include <human.inc>

extern autoslopevalue,curplayerctrlkey,gettileinfoshort,ishumanplayer
extern getindustileid,industilecallbackflags
extern grffeature,curcallback,getnewsprite




ptrvar bTempRaiseLowerDirection
ptrvar bTempRaiseLowerCorner

//WSEN
var cornerchecktile1, db 3,0,1,2

var cornerchecktile2, db 1,2,3,0

/*  3 
    /\
  a/  \d
  0    2
  b\  /c
    \/ 
     1  */
var railgetol5, db 10110b, 11001b, 101010b, 100101b, 10110b
var roadedgetol5, db 1b, 10b, 100b, 1000b, 1b
var roadconvertdepottobit, db 1000b, 100b, 10b, 1b, 1000b, 100b, 10b, 1b
//var railconvertdepottobit, db 100b, 1000b, 1000b, 100b
var stationtoroutetranslation, db 1b, 10b

uvarb autoslopechecklandscapezf,1
uvarb autoslopecheckeachtileonchangeheight,1

global autoslopechecklandscape
autoslopechecklandscape:
	setnz [autoslopechecklandscapezf]

	push byte PL_DEFAULT
	call ishumanplayer
	jnz .oldcode

	// disable ctrl key, otherwise industries get removed
	mov byte [curplayerctrlkey], 0

	mov ah, [landscape4(bx)]
	and ah, 0xF0
	cmp ah, 0x10
	je near .railtile
	cmp ah, 0x20
	je near .roadtile
	cmp ah, 0x30
	je near .noroutetiles
	cmp ah, 0x50
	je near .stationtile
	cmp ah, 0x80
	je near .industrytile
	cmp ah, 0x90
	je near .bridgetile
	cmp ah, 0xA0
	je near .noroutetiles

.oldcode:
	//or eax, eax
	// do old code
	cmp byte [autoslopechecklandscapezf], 0
	ret
	
// ---
.stationtile:
	pusha	
	mov esi, ebx
	call [gettileinfoshort]

	mov dl, dh
	cmp dh, 0x07
	ja .norailstation
	movzx eax, dh
	and eax, 1
	mov dh, [stationtoroutetranslation+eax]
	mov ecx, railgetol5
	jmp .routecommon
	
.norailstation:
	cmp dh, 0x42
	jb near .exit 
	jne .noheliport
	popa
	jmp .noroutetiles
	
.noheliport:
	cmp dh, 0x4A
	ja .nobays
	movzx eax, dh
	sub eax, 0x43
	mov dh, byte [roadconvertdepottobit+eax]
	mov ecx, roadedgetol5
	jmp .routecommon
.nobays:
	cmp dh, 0x58
	jb near .exit
// busstops	
	mov dh, 1010b
	je .nototherdir
	mov dh, 101b
.nototherdir:
	mov ecx, roadedgetol5
	jmp .routecommon
	
// --- 
.railtile:
	pusha
	mov esi, ebx
	call [gettileinfoshort]
	xor ecx, ecx
	mov ecx, railgetol5
	
	mov dl, dh
	bt dx, 7					// depot
	jnc .noraildepot
	movzx eax, dh
	and eax, 3
	mov dh, byte [roadconvertdepottobit+eax]
	mov ecx, roadedgetol5
	
.noraildepot:
	jmp .routecommon
	
.roadtile:
	pusha
	mov esi, ebx
	call [gettileinfoshort]
	xor ecx, ecx

	mov dl, dh
	bt dx, 4					// crossing
	jc near .exit
	
	bt dx, 5					// depot
	jnc .noroaddepot
	movzx eax, dh
	and eax, 3
	mov dh, byte [roadconvertdepottobit+eax]
	
.noroaddepot:
	mov ecx, roadedgetol5
	// fall
	
.routecommon:

	mov bl, byte [bTempRaiseLowerDirection]		// bTempRaiseLowerDirection
	cmp bl, 1
	je near .routeup

.routedown:	
	// di = corner map
	// dh = L5 (maybe faked)
	// ecx = route test table
	cmp di, 0
	je near .oktochange
	
	and di, 0x1F
	bt di, 4
	jc near .exit				// steep slopes are to complicate

	mov ax, di
	mov ah, al   				// test if more than 1 bit is set
	dec al
	test al, ah
	jz near .exit

	mov ebx, 3 
	sub bl, byte [bTempRaiseLowerCorner]		// corner to change

	bt di, bx					// already set bit
	jnc near .exit
	
	mov dl, byte [ecx+ebx]
	test dh, dl
	jz .roaddown_noroute1

	xor eax, eax
	mov al, byte [cornerchecktile1+ebx]
	bt di, ax
	jnc near .exit
.roaddown_noroute1:

	mov dl, byte [ecx+ebx+1]
	test dh, dl
	jz .roaddown_noroute2

	mov al, byte [cornerchecktile2+ebx]
	bt di, ax
	jnc near .exit
.roaddown_noroute2:
	jmp .oktochange
	
.routeup:
	// di = corner map
	// dh = L5
	// ecx = route test table
	cmp di, 0
	je near .exit
	
	and di, 0x1F
	bt di, 4
	jc near .exit				// steep slopes are to complicate

	mov ebx, 3 
	sub bl, byte [bTempRaiseLowerCorner]		// corner to change
	
	bt di, bx					// already set bit
	jc near .exit
	
	mov dl, byte [ecx+ebx]
	test dh, dl
	jz .roadup_noroute1

	xor eax, eax
	mov al, byte [cornerchecktile1+ebx]
	bt di, ax
	jnc near .exit
.roadup_noroute1:

	mov dl, byte [ecx+ebx+1]
	test dh, dl
	jz .roadup_noroute2

	mov al, byte [cornerchecktile2+ebx]
	bt di, ax
	jnc near .exit
.roadup_noroute2:
	jmp .oktochange

.industrytile:

	xor eax,eax
	call getindustileid
	jnc .noroutetiles

	test byte [industilecallbackflags+eax],0x40
	jz .noroutetiles

	xchg esi,ebx
	mov byte [grffeature],9
	mov byte [curcallback],0x3C
	call getnewsprite
	mov byte [curcallback],0
	xchg esi,ebx
	jc .noroutetiles

	test eax,eax
	jnz .exit_nopop

// normal tiles
.noroutetiles:	
	pusha
	mov esi, ebx
	call [gettileinfoshort]

	mov bl, byte [bTempRaiseLowerDirection]		// bTempRaiseLowerDirection
	cmp bl, 1
	je .up
.down:
	cmp di, 0
	je .oktochange
	and di, 0x1F
	bt di, 4
	jc .exit				// steep slopes are to complicate
	
	mov bx, 3 
	sub bl, byte [bTempRaiseLowerCorner]		// corner to change
	
	mov ax, di
	// Apart from the value 0, if only one bit is set in a variable x, it 
	// has no bits in common with (x-1). SO after trapping for a zero parameter, 
	// just use this test. 
	mov ah, al   				// test if more than 1 bit is set
	dec al
	test al, ah
	jz .exit
	
	bt di, bx
	jc .oktochange

	jmp .exit
.up:
	cmp di, 0
	je .exit
	and di, 0x1F
	bt di, 4				// steep slopes are to complicate
	jc .exit

	mov bx, 3
	sub bl, byte [bTempRaiseLowerCorner]		// corner to change
	
	bt di, bx
	jnc .oktochange
.exit:
	popa
.exit_nopop:
	// or eax, eax
	// do old code
	cmp	byte [autoslopechecklandscapezf], 0
	ret

.oktochange:
	popa
	mov ah, byte [bTempRaiseLowerCorner]
	xor al, al
	add esp, 8		// we get called by canraiselowertrack
	mov ebp,[raiselowercost]

	push ebp
	mov ebp, [raiselowercost]
	imul ebp, dword [autoslopevalue]
	add edx, ebp 	// cost to change
	pop ebp

	movzx ebp, word [0x447BD0]
ovar tempraiseloweraffectedtilearraycount, -4
      cmp bp, 0x271
	jnb .oktochangeproblem
	inc word [0x447BD0]
ovar tempraiseloweraffectedtilearraycount2, -4
	shl bp, 1
	add ebp, dword [0x447BCA]
ovar tempraiseloweraffectedtilearray, -4
	mov [ebp+0], bx
	xor al, al
	ret
.oktochangeproblem:
	mov al, 0xFF
	ret
	
.bridgetile:
	pusha
	mov esi, ebx
	call [gettileinfoshort]
//I/O: AX,CX = X,Y coord. (precise) of tile's north corner
//Out: ESI = XY index of the tile
//     BX = class of the tile * 8
//     DH = type of the tile (from L5)
//     DL = altitude of the lowest corner (height * 8)
//     DI = map of corners that are above DL, <3:0>=<NESW>;
//          bit 4 set if one corner is more than 1 height unit above DL

//RaiseLowerLand

	test di, 0x10
	jnz NEAR .exit
	test dh, 0x80
	jz NEAR .exit
	test dh, 0x40
	jnz NEAR .bridgemiddle
//bridge end
	mov al, dh
	and al, 6
	cmp al, 4
	je NEAR .exit	//disable autoslope for aquaduct ends
	//assumption: corners: 0=sloped, 1=flat, 2=flat, 3=sloped
	mov al, [bTempRaiseLowerDirection]
	mov bx, 3
	sub bl, byte [bTempRaiseLowerCorner]
	xor ah, ah
	mov cx, di
	or cx, cx
	jz .checkedbridgeendslope
	mov ch, cl
	xor cx, 0x0F0F
	dec cl
	and ch, cl	//3 corner -> 1 bit -> ch&dl=0 -> ah=0
	setnz ah
.checkedbridgeendslope:
	or al, al
	js .bridgeenddown
//bridge end up
	mov cx, di
	bts cx, bx
	jc NEAR .exit
	cmp cx, 0xF
	jne .bridgeendin
	xor cx, cx
	jmp .bridgeendin
.bridgeenddown:
	mov cx, di
	btr cx, bx
	jc .bridgeendin	// easy lower raised corner
	or di, di
	jnz NEAR .exit	//would make a steep slope
	//cx=0
	bts cx, bx
	xor cx, 0xF
.bridgeendin:
	xor al, al
	mov ch, cl
	or cl, cl
	jz .checkedbridgeendslope2
	xor cx, 0x0F0F
	dec ch
	and ch, cl
	setnz al
.checkedbridgeendslope2:
	xor al, ah
	jnz NEAR .exit	//sloped bridge end has become a flat bridge end or vice versa
	mov ax, [landscape3+esi*2]
	test dh, 6
	jnz .roadbridgeend
//rail bridge end
	and ax, 0x02f0
	shr ax, 4
	mov dh, al
	mov ecx, railgetol5
	jmp .routecommon
.roadbridgeend:
	mov dh, al
	shr dh, 4
	shr ax, 8
	and al, 0x0F
	or dh, al
	mov ecx, roadedgetol5
	jmp .routecommon

.bridgemiddle:
	mov al, [bTempRaiseLowerDirection]
	mov bx, 3
	sub bl, byte [bTempRaiseLowerCorner]
	test di, 0x10
	jnz NEAR .exit	// steep slope...
	or al, al
	js .bridgemiddledown
	mov cx, di
	bts cx, bx
	jc NEAR .exit	// steep slope...
	xor cx, 0xF
	setz al		// al=1 if baseline of tile raised
	mov ah, [landscape7+esi]
	shr ah, 3
	test di, 0Fh
	jnz .bridgemiddlegotah
	dec ah		// reduce reported height if this tile was flat
	jmp .bridgemiddlegotah
.bridgemiddledown:
	bt di, bx	// is the corner level above the baseline
	setc al
	dec al		// level: -1, above: 0
	jc .bridgemiddlein
	xor bx, 2
	bt di, bx
	jc NEAR .exit	// steep slope...
.bridgemiddlein:
	mov ah, [landscape7+esi]
	shr ah, 3
.bridgemiddlegotah:
	cmp ah, al
	jl NEAR .exit
	or al, al
	setnz dl
	mov al, dh
	and al, 0x38
	xor al, 8
	setz al
	or dl, al
	or BYTE [autoslopecheckeachtileonchangeheight],dl
	test dh, 0x20
	jnz .routeunderbridge


	jmp .oktochange
.routeunderbridge:
	xor dl, dl
	bt dx, 8
	//CF=bridge in Y direction, route in X direction
	sbb dl, -2
	//dl=if bridge in Y direction, 1, else 2
	mov dh, dl
	mov ecx, railgetol5
	jmp .routecommon

uvarb tmpautoslopebuff,4E2h/2

global correctlandscapeonraiselower,correctlandscapeonraiselower.oldfn
correctlandscapeonraiselower:
	cmp BYTE [autoslopecheckeachtileonchangeheight], 0
	jz .done
	pusha
	movzx ecx, WORD [esp+32+8]
	movzx ebx, WORD [ebp+0]
	mov BYTE [tmpautoslopebuff+ecx-1],0
	mov al, [landscape4(bx)]
	shr al, 4
	cmp al, 9
	jne .donepopa
	mov esi, ebx
	call [gettileinfoshort]
	and dh, 0xC0
	xor dh, 0xC0
	jnz .donepopa
	add dl,dl
	and dl, 0xF0
	or dl, 1
	movzx ecx, WORD [esp+32+8]
	mov BYTE [tmpautoslopebuff+ecx-1],dl
	//[tmpautoslopebuff] = bits:7-4 old height, bits:3-0 type of tile operation: 0=none, 1=fix L7 higher bridges
.donepopa:
	popa
.done:
	jmp near $
ovar correctlandscapeonraiselower.oldfn,-4

global correctlandscapeonraiselower2,correctlandscapeonraiselower2.oldfn
correctlandscapeonraiselower2:
	cmp BYTE [autoslopecheckeachtileonchangeheight], 0
	jz .done
	pusha
	movzx ecx, WORD [esp+32+8]
	movzx ebx, WORD [ebp+0]
	movzx ebp, BYTE [tmpautoslopebuff+ecx-1]
	dec ecx
	setnz al
	and BYTE [autoslopecheckeachtileonchangeheight], al
	mov eax, ebp
	and eax, 0xf
	cmp eax, 1
	jne .donepopa
	mov al, [landscape4(bx)]
	shr al, 4
	cmp al, 9
	jne .donepopa
	mov esi, ebx
	call [gettileinfoshort]
	and dh, 0xC0
	xor dh, 0xC0
	jnz .donepopa
	shr ebp, 1
	mov eax, ebp
	//al=old tile height, dl=new tile height
	sub al, dl
	//al=amount tile has gone down
	add [landscape7+esi], al
.doneheight:
	mov ah, [landscape5(si)]
	mov al, ah
	and ah, 0x38
	xor ah, 8
	jnz .donepopa
	and al, ~0x18
	mov [landscape5(si)], al
	and BYTE [landscape3+esi*2], ~1
.donepopa:
	popa
.done:
	jmp near $
ovar correctlandscapeonraiselower2.oldfn,-4

// comp.lang.asm.x86  "One bit set? (Was: Bit Counting)"
// Apart from the value 0, if only one bit is set in a variable x, it 
// has no bits in common with (x-1). SO after trapping for a zero parameter, 
// just use this test. 
//;; Return ZERO flag set if one and only one bit was set: 
//  mov  ah,al   ;copy into AH 
//  sub  al,1    ;dec AL, set CARRY and Clear ZERO if 0 
//  jc  AL_Was_Zero 
//  test al,ah   ; this sets the ZERO flag if only one bit was set 
// AL_Was_Zero:   ; Jumps here with ZERO cleared if AL == 0 
//  ret 
//
//
