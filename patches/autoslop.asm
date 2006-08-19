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
