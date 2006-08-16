
#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <veh.inc>

extern actionhandler,addgroundsprite,addsprite,canalfeatureids
extern checkvehiclesinthewayfn,cleartilefn,curplayerctrlkey,getdesertmap
extern getgroundalt,getnewsprite,gettileinfo,grffeature,landshapetospriteptr
extern locationtoxy,patchflags,redrawscreen
extern waterbanksprites,gettileterrain




struc newwatersprites
	.watercliff:	resb 4
	.lifthouse:		resb 24
	.lifthouseseelevel: resb 24
	.waterwharf:	resb 12
	.ico:			resb 1
endstruc

// Cost can be calculated via clearwatercost * FACTOR / 8
%define WATERPLACEFACTOR 3
%define SHIPLIFTPLACEFACTOR 22
%define SHIPLIFTCLEARFACTOR 16

// Cliff translation table
var baCliffTranslation, db -1, -1, -1, 2	
                db -1, -1, 0, -1
                db -1, 3, -1, -1
                db 1, -1, -1, -1

var paLiftHouseSprites, dd LiftHouse0, LiftHouse1, LiftHouse2, LiftHouse3	// middle part
dd LiftHouse0b, LiftHouse1b, LiftHouse2b, LiftHouse3b					// bottom
dd LiftHouse0t, LiftHouse1t, LiftHouse2t, LiftHouse3t					// top

var LiftHouse0, db 0, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+4
		    db 0 // seelevel, if it's the same or below use first set!

var LiftHouse1, db 0, 0, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+1
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+4+1
		    db 0

var LiftHouse2, db 0, 0, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+2
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+4+2
		    db 0

var LiftHouse3, db 0, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+3
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+4+3
		    db 0

var LiftHouse0b, db 0, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+8
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+12
		    db 0

var LiftHouse1b, db 0, 0, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+8+1
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+12+1
		    db 0

var LiftHouse2b, db 0, 0, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+8+2
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+12+2
		    db 0

var LiftHouse3b, db 0, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+8+3
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+12+3
		    db 0

var LiftHouse0t, db 0, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+16
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+20
		    db 8

var LiftHouse1t, db 0, 0, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+16+1
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+20+1
		    db 8

var LiftHouse2t, db 0, 0, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+16+2
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd newwatersprites.lifthouse+20+2
		    db 8

var LiftHouse3t, db 0, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+16+3
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd newwatersprites.lifthouse+20+3
		    db 8

var LiftHouseNoGRF, db 0x83,0x81,0x81,0x83

var newwaterspritebase, dw -1	// First new sprite with water sprites...
		// number of sprites necessary for correct operation
		// (aborts with wrong version number if it doesn't match)
var numnewwatersprites, dd newwatersprites_size+10 // make old canals.grf invalid


uvard oldclass6drawlandfnc,1,s
uvard oldclass6maphandler,1,s
uvard oldclass6periodicproc,1,s
uvard dockwinpurchaselandico,1,s
uvard oldclass5drawlandfnc,1,s
uvard oldclass9drawlandfnc,1,s

uvarb canalaction2array,3  // height byte, dessertmapinfo byte, dikemapbyte

global SwapDockWinPurchaseLandIco
SwapDockWinPurchaseLandIco:
	testflags canals
	jc .active
	ret
.active:
#if 0
	push ebx
	push edi
	movzx ebx,word [newwaterspritebase]
	or bh,bh
	js .nosprites
	add bx, newwatersprites.ico
	mov edi, [dockwinpurchaselandico]
	mov word [edi], bx
.nosprites:
	pop edi
	pop ebx

#endif
	pusha 
	mov ebx, 4791
	cmp dword [canalfeatureids+3*4], 0
	jz .nosprites

	xor ebx, ebx
	mov eax, 3		// we want icons :)
	mov esi, 0
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	
.nosprites:
	mov edi, [dockwinpurchaselandico]
	mov word [edi], bx

	popa
	ret
;endp SwapDockWinPurchaseLandIco;

extern grfmodflags
global Class6PeriodicProc
Class6PeriodicProc:
	testmultiflags newsounds
	jz .nonewsounds
	test byte [grfmodflags],0x10
	jz .nonewsounds

	extern AmbientSound
	call AmbientSound

.nonewsounds:
	test word [landscape3 + 2*ebx], 1
	jz .oldfunction
	ret
.oldfunction:
	jmp [oldclass6periodicproc]
	ret
;endp Class6PeriodicProc

global Class6DrawLand
Class6DrawLand:
	or dh, dh
	js .oldfunction // no a depot
	jnz .couldbecliff
	mov esi, ebx	// we need it later, so store it
	mov bx, 4061
	call [addgroundsprite]
	// If we need to draw some eyecandy around the water sprites height > 0
	cmp dl, 0
	jnz .normalwaterabovejmp
	// or this is a canal at sealevel
	cmp esi,0x101
	jb .nocanal
	test word [landscape3 + 2*esi], 1
	jnz .normalwaterabovejmp
.nocanal:
	ret
.normalwaterabovejmp:
	jmp normalwaterabove

.couldbecliff:
	cmp dh, 1
	ja .shiplift

.oldfunction:
	jmp [oldclass6drawlandfnc]
	ret

.shiplift:
	mov esi, ebx	// we need it later, so store it

// Shows the new Shiplifts on and the Watercliffs

// Get the tile type that is stored in the landscape
	movzx edi, byte [landscape2+esi]
	
	//movzx ebx,word [newwaterspritebase]
	//or bh,bh
	//jns .newsprites
	//jmp short .newsprites

	cmp dword [canalfeatureids+1*4], 0
	jnz .newsprites
	
	mov dh,0	// draw regular water tile

	cmp edi,4
	jae .notmiddle

	// is middle part, show ship depot
	mov dh,[LiftHouseNoGRF+edi]

.notmiddle:
	jmp [oldclass6drawlandfnc]

.newsprites:
// fill the canalaction2array with usefull info
	pusha
	shr dl, 3
	cmp edi, 8
	jb .notatoppart
	dec dl		// fake top part so it's the right height
.notatoppart:
	mov [canalaction2array], dl
	shl dl, 3
	
	call getdikemap
	xchg edi, edx
	mov [canalaction2array+2], dl
	xchg edx, edi
	
	
	mov al, 0

	call gettileterrain

	mov [canalaction2array+1], al // now 0 normal, 1 desert, 2 rainforest, 4 on or above snowline
	popa

	// See if we need a cliff groundsprite
	push ebx
	cmp edi, 3
	ja .normalwatertile

	//lea ebx,[ebx+edi+newwatersprites.watercliff]
	//call [addgroundsprite]
	
	push edi
	mov ebx, edi
	push esi
	push eax
	mov eax, 0		// we want water cliffs
	mov esi, canalaction2array
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	pop eax
	pop esi
	call [addgroundsprite]
	pop edi

	jmp .groundtiledone
.normalwatertile:
	mov ebx, 4061
	call [addgroundsprite]
.groundtiledone:
	pop ebx


// Draw the house parts:
	mov edi, [paLiftHouseSprites+edi*4]
	
	pusha
	mov ebp, edi
	movsx bx, byte [ebp+0]
	add ax, bx
	movsx bx, byte [ebp+1]
	add cx, bx
	movsx di, byte [ebp+3]
	movsx si, byte [ebp+4]
	mov dh, [ebp+5]
	mov ebx, [ebp+6]
#if 0
	add bx, word [newwaterspritebase]	
	cmp dl, [ebp+20]
	jna .nosecondset
	add bx, 24
.nosecondset:

#else
	sub ebx, 4 // tempfix

	push esi
	push eax
	mov eax, 1	// we want locks
	mov esi, canalaction2array
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	pop eax
	pop esi
#endif
	add dl, [ebp+2]
	call [addsprite]
	popa

	pusha
	mov ebp, edi
	add ebp, 10

	movsx bx, byte [ebp+0]
	add ax, bx
	movsx bx, byte [ebp+1]
	add cx, bx
	
	movsx di, byte [ebp+3]
 	movsx si, byte [ebp+4]
	
 	mov dh, [ebp+5]
  	mov ebx, [ebp+6]

#if 0
	add bx, word [newwaterspritebase]
	cmp dl, [ebp+10]
	jna .nosecondset2
	add bx, 24
.nosecondset2:
#else
	sub ebx, 4 // tempfix

	push esi
	push eax
	mov eax, 1	// we want locks
	mov esi, canalaction2array
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	pop eax
	pop esi
#endif
	add dl, [ebp+2]
	call [addsprite]
.nosprites:
	popa
	ret
;endp Class6DrawLand

uvard saved_ebx
var coastdirections // xy-offsets for all possible height masks (1234h means this must have a coast drawn whatsoever)
	dw 0000h, 1234h, 1234h, -001h
	dw 1234h, 0000h, -100h, 0000h 
	dw 1234h, +100h, 0000h, 0000h
	dw +001h, 0000h, 0000h, 0000h

global class9drawland
class9drawland:
	mov [saved_ebx], ebx
	jmp [oldclass9drawlandfnc]

	
// in:	ebx = old sprite
//		ax, cx = landscape XY
//		dl = lowest corner
//		dh = type of tile L5
//		di = cornermap
//		saved_ebx = XY index
//
//		We assume in this code that there are no coast tiles at higher levels.
//		The old code checked the nearby tile if there is really a water tile,
//		however generally we can skip this if a bridge has the water flag set it will flood at seelevel
//		and coastlines can only happen at seelevel anyway...
//		Or in other words, if there is a slope under a bridge and it's water, display a coast, done!

global selectgroundforbridge
selectgroundforbridge:
	cmp ebx, 4061
	jz .isawatersprite
.nocoast:
	// draws a normal landshape, fixes higherbridges
	push edi
	and edi, 0xFFFF
	add edi, [landshapetospriteptr]
	movzx di, byte [edi]
	add bx, di
	pop edi
	call [addgroundsprite]
	ret
	
.isawatersprite:
	or di, di
	jnz .coast
	call [addgroundsprite]
	testflags canals
	jc .hascanals
	ret
	
.hascanals:
	mov ebx, [saved_ebx]
	cmp dl, 0
	jnz .drawdikes
	test word [landscape3+ebx*2], 1
	jnz .drawdikes
	ret
.drawdikes:
	pusha
	mov esi, ebx
	call normalwaterabove
	popa
.nodikes:
	ret
	
.coast:
#if 0
	push ebx
	mov ebx, [saved_ebx]
	test byte [landscape5(bx)], 20h
	jnz .nocoast2
	test byte [landscape5(bx)], 18h
	jz .nocoast2
	pop ebx
#endif
	push edi
	shl di, 1
	and edi, 0xFFFF
	add edi, [waterbanksprites]
	movzx ebx, word [edi]
	pop edi
	call [addgroundsprite]
	ret



;endp selectgroundforbridge

// code for removing bridge on coast
global removebridgewater
removebridgewater:
	// first fix the return address
	pop edx
	add edx, 0x39
	push edx

	pusha
	rol di, 4
	mov ax, di
	mov cx, di
	rol cx, 8
	and ax, 0ff0h
	and cx, 0ff0h
	call [gettileinfo]
	or di, di
	jz .nocoast
	popa
	mov dx, 0x6001
	ret
.nocoast:
	popa
	mov dx, 0x6000
	ret
;endp removebridgewater

// code for showing "dikes" around water
normalwaterabove:
#if 0
	movzx ebx,word [newwaterspritebase]
	or bx,bx
	jns .newsprites
#endif
	cmp dword [canalfeatureids+2*4], 0
	jnz .newsprites
	ret
.newsprites:
	
	pusha
	shr dl, 3
	mov [canalaction2array], dl
	shl dl, 3
	
	call gettileterrain
	
	mov [canalaction2array+1], al // now 0 normal, 1 desert, 2 rainforest, 4 on or above snowline
	popa

	// Calculate the Dike Map
	call getdikemap	// if you want to cache don't break selectgroundforbridge!
	
	xchg edi, edx
	mov [canalaction2array+2], dl
	xchg edx, edi	


	bt edi, 0
	jnc .sprite1
	mov ebx, 0
	call showadikesprite
.sprite1:

	bt edi, 1
	jnc .sprite2
	mov ebx, 1
	call showadikesprite
.sprite2:

	bt edi, 2
	jnc .sprite3
	mov ebx, 2
	call showadikesprite
.sprite3:

	bt edi, 3
	jnc .sprite4
	mov ebx, 3
	call showadikesprite
.sprite4:  

// We have now drawn all full side dikes,
// lets look if we need to draw fix sprites,
// maybe we didn't drawn 2 sides at all,
// so look if we need to draw a outside corner

	push edi
	and edi, 0x3

	cmp edi, 0x3
	jz .bothset5	// both side, fix corner

	test edi,edi
		
	jnz .oneisset5 	// only one side has a dike
	
	// none side, look if we need a outside corner
	bt dword [esp], 4
	jnc .oneisset5
	mov ebx, 8
	call showadikesprite
	jmp .oneisset5
.bothset5:
	mov ebx, 4
	call showadikesprite
.oneisset5:
	pop edi


	push edi
	and edi, 0x6

	cmp edi, 0x6
	jz .bothset6	// both side, fix corner

	test edi,edi
		
	jnz .oneisset6 	// only one side has a dike
	
	// none side, look if we need a outside corner
	bt dword [esp], 5
	jnc .oneisset6
	mov ebx, 9
	call showadikesprite
	jmp .oneisset6
.bothset6:
	mov ebx, 5
	call showadikesprite
.oneisset6:
	pop edi

// we aren't finished aren't we? I feel bored ...
// lets fix two other corners

	push edi
	and edi, 0xC

	cmp edi, 0xC
	jz .bothset7	// both side, fix corner

	test edi,edi
		
	jnz .oneisset7 	// only one side has a dike
	
	// none side, look if we need a outside corner
	bt dword [esp], 6
	jnc .oneisset7
	mov ebx, 10
	call showadikesprite
	jmp .oneisset7
.bothset7:
	mov ebx, 6
	call showadikesprite
.oneisset7:
	pop edi

	push edi
	and edi, 0x9

	cmp edi, 0x9
	jz .bothset8	// both side, fix corner

	test edi,edi
		
	jnz .oneisset8 	// only one side has a dike
	
	// none side, look if we need a outside corner
	bt dword [esp], 7
	jnc .oneisset8
	mov ebx, 11
	call showadikesprite
	jmp .oneisset8
.bothset8:
	mov ebx, 7
	call showadikesprite
.oneisset8:
	pop edi

	ret
;endp normalwaterabovealt
	
showadikesprite:
	push edi
#if 0
	xchg ebx, edi
	movzx ebx,word [newwaterspritebase]
	lea ebx, [ebx+newwatersprites.waterwharf+edi]
	call [addgroundsprite]
#endif
	push esi
	push eax
	mov eax, 2		// dike parts
	mov esi, canalaction2array
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	pop eax
	pop esi
	call [addgroundsprite]

	pop edi

	ret
;endp showadikesprite


// in: esi
// out: ebx & esi = in esi, edi => dike bit returned:
//  |---|---|---|
//  | 7 | 4 | 8 |
//  |---|---|---|
//  | 3 |esi| 1 |
//  |---|---|---|
//  | 6 | 2 | 5 |
//  |---|---|---|
getdikemap:
	push byte -5

%macro .addrel 2-*
	%assign %%left %0/2
	mov ebx,esi
	%rep %%left
		%assign %%left %%left-1
		%if %2>0
			add %1,%2
		%else
			sub %1,-%2
		%endif
		%if %%left>0
			jc %%bad
		%endif
		%rotate 2
	%endrep
	jnc %%ok
%%bad:
	sbb ebx,ebx
%%ok:
	push ebx
%endmacro



	.addrel bl, -1		// 1 -X
	.addrel		bh,  1	// 2    +Y
	.addrel bl,  1		// 3 +X
	.addrel		bh, -1	// 4    -Y

	.addrel bl, -1,	bh,  1	// 5 -X +Y
	.addrel bl,  1,	bh,  1	// 6 +X +Y
	.addrel bl,  1,	bh, -1	// 7 +X -Y
	.addrel bl, -1,	bh, -1	// 8 -X -Y
	
	pop ebx

	xor edi, edi
.testnext:
	test ebx,ebx
	js .outsidemap	// outside of the map is always considered to have water
	call iswateredtile
	cmc
.outsidemap:
	rcl edi, 1
	pop ebx
	cmp ebx,byte -5
	jne .testnext
	mov ebx, esi
	ret



// Is tile at esi a water tile?
// Rules if it's a water tile or not...
// return stc if it's a water tile otherwise clc
// in:	esi = reference tile
// 		ebx = tile to check
iswateredtile:
	push eax
	mov al,[landscape4(bx)]
	mov ah,[landscape5(bx)]
	shr al, 4

// Show rules
	cmp al, 6
	jnz .testother
	cmp ah, 1
	jnz .watertile	// no cliff
	
// if we have a cliff and we need to check if our reference tile is above ground
	mov al, [landscape4(si)]
	and al, 0xF
	cmp al, 0
	je .watertile	// a seelevel reference tile
	jmp .notwater
		
.testother:
// Station Tiles
	cmp al, 5
	jnz .notstationwithwater
	cmp ah, 0x4B
	jb .notstationwithwater
	jmp .watertile
.notstationwithwater:

// Bridge & Tunnel Parts:
	cmp al, 9
	jnz .nobridgepiecewithwater
	// test if it's a bridge middlepart
	bt ax, 14   // would be:  bt ah, 6 but thats not supported in x86 
	jnc .nobridgepiecewithwater // not a middle part
	bt ax, 13  // 5
	jc .nobridgepiecewithwater // not a land/water
	bt ax, 11 // 3
	jnc .nobridgepiecewithwater // not a water tile
	jmp .watertile
.nobridgepiecewithwater:
.notwater:
	pop eax
	clc
	ret
.watertile:
	pop eax
	stc
	ret
;endp iswateredtile






var waterliftmaproutes, db 2, 1, 1, 2
				db 2, 1, 1, 2
				db 2, 1, 1, 2

// 66 F7 C6 80 00  test    si, 80h
// 74 F0          jz      short loc_140F07
global Class6RouteMapHandler
Class6RouteMapHandler: 
	cmp byte [landscape5(di)], 2h                    
	je .shiplift
	jmp [oldclass6maphandler] // to TTD normal handler

.shiplift:
	movzx   esi, byte [landscape2+edi]
	mov     al, [waterliftmaproutes+esi]
	mov     ah, al
	movzx   eax, ax

	//mov eax, 3F3Fh
	ret
;endp Class6RouteMapHandler



// Complex movement handler:
global Class6VehEnterLeave
Class6VehEnterLeave:
	cmp byte [landscape5(bx)], 2h
	je .shipliftparts
	ret
.shipliftparts:
	cmp dl, 1
	jne .notleaving
	mov byte [edi+veh.targetairport], 0
	ret
.notleaving:
	cmp byte [edi+veh.targetairport], 70h
	jz .donemiddletest

	push ebx
	mov bl, byte [edi+veh.xpos]
	and bl,0x0f
	cmp bl,7  
	je .testy
	cmp bl,8
	je .testy
	pop ebx
	ret
.testy:
	mov bl, byte [edi+veh.ypos]
	and bl,0x0f
	cmp bl,7  
	je .onmiddle
	cmp bl,8
	je .onmiddle
	pop ebx

.donemiddletest:	
	ret

.onmiddle:
	pop ebx
	cmp byte [landscape2+ebx], 4
	jb .shipliftmiddletype
	// now fix bogus ships that get somehow wrong while lifting ;)
	call getgroundalt
  	mov [edi+veh.zpos], dl
	ret

.shipliftmiddletype:
	// we are in the tile middle but don't know if up/down
  	
	call getgroundalt
  	cmp dl, [edi+veh.zpos]
	jz .donemiddletest	// that shouldn't happen, what now?...
	mov byte [edi+veh.targetairport], 71h
	jb .zdown
	ret
.zdown:
	mov byte [edi+veh.targetairport], 72h
	ret
;endp ClassXVehEnterLeave


global SpecialShipMovement
SpecialShipMovement:
	cmp byte [esi+veh.targetairport], 70h
	ja .shiplift
	cmp byte [esi+veh.movementstat], 80h
	jz .isdepot
	stc
	ret

.isdepot:	
	mov ax, [esi+veh.xpos]
 	mov cx, [esi+veh.ypos]
	clc
	ret

.shiplift:
	mov bl, [esi+veh.targetairport]
	cmp bl, 71h
	je .zup
	cmp bl, 72h
	je .zdown
	stc
	ret
	
.zup:
	pusha
	xor ax, ax
	mov al, [esi+veh.zpos]
	inc ax
	jmp .changedone
.zdown:
	pusha
	xor ax, ax
	mov al, [esi+veh.zpos]
	dec ax

.changedone:
	mov [esi+veh.zpos], al
	mov dl, 8
	idiv dl
	cmp ah, 0
	popa
	je .finish
	mov word [esi+veh.speed], 0
	mov ebx, 0
	mov word [esi+veh.loadtime], 1
	jmp .done

.finish:
	mov byte [esi+veh.targetairport], 70h
.done:
	mov ax, [esi+veh.xpos]
 	mov cx, [esi+veh.ypos]
	mov ebx, 0
	mov word [esi+veh.loadtime], 1
	clc
	ret
;endp SpecialShipMovement




// very simple movement handler
Class6VehEnterLeaveSimple:
	cmp dl, 0
	jz .notleavingtile	// leaving tile will create a wrong z offset somehow
	ret
.notleavingtile:
	pusha
  	call getgroundalt
  	test dh, 1
  	jz short .underbridge
  	cmp dl, [edi+veh.zpos]
  	jz short .alreadyok
  	add dl, 8
.underbridge:
.alreadyok:
	mov [edi+veh.zpos], dl
	popa
.done:
	ret
;endp Class6VehEnterLeaveSimple

// Helpfer function to clear a shiplift
// in ax, cx a tile of a shiplift...
clearshiplift:
	pusha
	call locationtoxy
	movzx edi, byte [landscape2+esi]
	cmp di, 4
	jb .alreadyshipliftmiddle
	cmp di, 7
	ja .istoppart
	
	and di, 0x3
	sub ax, word [paShipLiftAddPartsInLandscape+edi*8]
	sub cx, word [paShipLiftAddPartsInLandscape+edi*8+2]
	jmp .alreadyshipliftmiddle
	
	.istoppart:
	and di, 0x3
	sub ax, word [paShipLiftAddPartsInLandscape+edi*8+4]
	sub cx, word [paShipLiftAddPartsInLandscape+edi*8+6]
	.alreadyshipliftmiddle:
	
	call locationtoxy
	movzx edi, byte [landscape2+esi]
	xchg esi, edi
	call dword [checkvehiclesinthewayfn]
	xchg esi, edi
	jnz .errorvehicle
	
	call dword [cleartilefn]

	push ax 
	push cx
	add ax, word [paShipLiftAddPartsInLandscape+edi*8]
	add cx, word [paShipLiftAddPartsInLandscape+edi*8+2]
	call locationtoxy
	xchg esi, edi
	call dword [checkvehiclesinthewayfn]
	xchg esi, edi
	jnz .errorvehiclepopaxcx
	call dword [cleartilefn]
	pop cx
	pop ax 

	add ax, word [paShipLiftAddPartsInLandscape+edi*8+4]
	add cx, word [paShipLiftAddPartsInLandscape+edi*8+6]
	call locationtoxy
	xchg esi, edi
	call dword [checkvehiclesinthewayfn]
	xchg esi, edi
	jnz .errorvehicle
	call dword [cleartilefn]
	
	popa
	imul ebx, [clearwatercost], SHIPLIFTCLEARFACTOR 
	shr ebx,3
	ret
.errorvehiclepopaxcx:
	pop cx
	pop ax 
	popa
	mov ebx, 80000000h
	ret
.errorvehicle:
	popa
	mov ebx, 80000000h
	ret


// Patch Clear Tile so our Shiplifts aren't removed by floating water...
global Class6ClearTile
Class6ClearTile:
	cmp dh, 1
	jb .error
	jnz .no1
	ret
.no1:
	test bl, 2 
	// if set, we doesn't want to clear landscape structures
	// -> fool we are a landscape structure
	// This means that the flood routine doesn't convert our tile back anymore...
	jnz .errorshiplift

	// we would be done here, but TTD Flood calls normal water tiles without bit 2, so
	cmp byte [curplayer], 11h 	// prevent the removeable of shipliftparts at seelevel, 
					// if the water "player" want it...
	je .errorshiplift
	add esp, 4
	call clearshiplift
	ret

.errorshipliftpopaxcx:
	pop cx
	pop ax
	popa
.errorshiplift:
	mov word [operrormsg2],0x5800	// "object in the way"
.error:
	pop ebx // don't go back to old function
	mov ebx, 80000000h
	ret


// 4 x under part, upper part 
var paShipLiftAddPartsInLandscape, dw 0, -16, 0, 16,
dw 16, 0, -16, 0,
dw -16, 0, 16, 0,
dw 0, 16, 0, -16

// In: 
// ax, cx = tile xy 
// esi = tile xy
// di  = ship lift type
// bl  = action build flags...
proc createshiplift
	slocal tilex, word
	slocal tiley, word
	slocal shiplifttype, word
	slocal actionbuildflags, byte

	_enter
	
	mov [%$tilex], ax
	mov [%$tiley], cx
	mov [%$shiplifttype], di
	mov [%$actionbuildflags], bl

	mov bl, byte [%$actionbuildflags]
	mov esi, 0
	push ebp
 	call [actionhandler]
	pop ebp
	cmp ebx, 80000000h
	jnz .noerrormiddle1
	jmp .error // tempfix for short jump problem 

.noerrormiddle1:
	push ebp
	call [gettileinfo]
	pop ebp
	test byte [%$actionbuildflags], 1
	jz .onlytestingmiddle
	mov byte [landscape1+esi], 11h
	mov bx, [%$shiplifttype]
	mov byte [landscape2+esi], bl
	mov word [landscape3+esi*2], 1h
	or byte [landscape4(si)], 60h
	mov byte [landscape5(si)], 2h
.onlytestingmiddle:


// bottom
	movzx ebx, word [%$shiplifttype]
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	add ax, word [paShipLiftAddPartsInLandscape+ebx*8]
	add cx, word [paShipLiftAddPartsInLandscape+ebx*8+2]
	mov ebx, [%$actionbuildflags]
	mov esi, 0
	push ebp
 	call [actionhandler]
	pop ebp
	cmp ebx, 80000000h
	jnz .nobottomerrorfreeing
	jmp .error	// tempfix for short jump problem 
.nobottomerrorfreeing:
	
	push ebp
	call [gettileinfo]
	pop ebp
	cmp di, 0	// is flat tile
	jz .nobottomerrorflat
	jmp .error
.nobottomerrorflat: // tempfix for short jump problem 
	
	test byte [%$actionbuildflags], 1
	jz .onlytestingbottom

	mov byte [landscape1+esi], 11h
	mov bx, [%$shiplifttype]
	add bx, 4
	mov byte [landscape2+esi], bl
	mov word [landscape3+esi*2], 1h
	or byte [landscape4(si)], 60h
	mov byte [landscape5(si)], 2h
.onlytestingbottom:

// top part
	movzx ebx, word [%$shiplifttype]
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	add ax, word [paShipLiftAddPartsInLandscape+ebx*8+4]
	add cx, word [paShipLiftAddPartsInLandscape+ebx*8+6]
	mov ebx, [%$actionbuildflags]
	mov esi, 0
	push ebp
 	call [actionhandler]
	pop ebp
	cmp ebx, 80000000h
	jz .error
	
	push ebp
	call [gettileinfo]
	pop ebp
	cmp di, 0	// is flat tile
	jnz .error
	
	test byte [%$actionbuildflags], 1
	jz .onlytestingtop

	mov byte [landscape1+esi], 11h
	mov bx, [%$shiplifttype]
	add bx, 8
	mov byte [landscape2+esi], bl
	mov word [landscape3+esi*2], 1h
	or byte [landscape4(si)], 60h
	mov byte [landscape5(si)], 2h

.onlytestingtop:
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	imul ebx, [clearwatercost], SHIPLIFTPLACEFACTOR 
	shr ebx,3
	_ret
.error:
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	mov ebx, 80000000h
	mov word [operrormsg1], ourtext(cantbuildcanalhere)
	mov word [operrormsg2], 0x5800
	_ret

endproc createshiplift


// Action Handler for creating water
global actionmakewater
actionmakewater:
	xor esi, esi
	rol cx, 8
	mov si, cx
	rol cx, 8
	or si, ax
	ror si, 4

// not needed here anymore ...
#if 0	
	mov dh,[landscape4(si)]
	shr dh, 4
	
	cmp dh, 0
	jz .validoldtile

	cmp dh, 4
	jz .validoldtile

	cmp dh, 6
	jz .validoldtile
	jmp .error
	
.validoldtile:
#endif
	push ax
	push cx
	push ebx
	call [gettileinfo]
	pop ebx
	pop cx 
	pop ax
	cmp di, 0
	je .flattile 
	and edi, byte 0x0F
	movsx edi, byte [baCliffTranslation+edi]
	test edi, edi
	js .error

.halftile:
	// we are creating a shiplift...
	jmp createshiplift
#if 0
	xchg esi, edi
	push ebx
	push edi
	mov  esi, 0
 	call [actionhandler]
	pop edi
	xchg esi, edi
	cmp ebx, 80000000h
	pop ebx
	jz .error

	test bl, 1
	jz .onlytesting
	mov byte [landscape5(si)], 2h
	jmp short .common
#endif
.flattile:
	mov dh,[landscape4(si)]
	shr dh, 4

	cmp dh, 6
	jz .error

	xchg esi, edi
	push ebx
	push edi
	mov  esi, 0
 	call [actionhandler]
	pop edi
	xchg esi, edi
	cmp ebx, 80000000h
	pop ebx
	jz .error

	test bl, 1
	jz .onlytesting
	mov byte [landscape5(si)], 0h
.common:
	mov byte [landscape2+esi], 0h

	movzx edx,byte [curplayerctrlkey]
	xor edx,1
	mov word [landscape3+esi*2], dx
	or byte [landscape4(si)], 60h
	mov byte [landscape1+esi], 11h
	call redrawscreen
.onlytesting:
	// fix cost
	imul ebx, [clearwatercost], WATERPLACEFACTOR
	shr ebx,3
	ret
.error:
	mov ebx, 80000000h
	ret
;endp actionmakewater

//called when deciding how much tiles we need to highlight (ax,cx is the mouse-cursor position)
uvarb tmpheight
global dockconstrwinhandler
dockconstrwinhandler:
	cmp dh, 00
	jne .skip0
	jmp .done
.skip0:
	mov [tmpheight], dl
	sub ax, 10h
	call [gettileinfo]
	cmp dl, [tmpheight]
	jne .skip1
	cmp bx, 6*8
	jne .skip1
	cmp dh, 00
	jne .skip1
	jmp .done
.skip1:
	add ax, 20h
	call [gettileinfo]
	cmp dl, [tmpheight]
	jne .skip2
	cmp bx, 6*8
	jne .skip2
	cmp dh, 00
	jne .skip2
	jmp .done
.skip2:
	sub ax, 10h
	sub cx, 10h
	call [gettileinfo]
	cmp dl, [tmpheight]
	jne .skip3
	cmp bx, 6*8
	jne .skip3
	cmp dh, 00
	jne .skip3
	jmp .done
.skip3:
	add cx, 20h
	call [gettileinfo]
	cmp dl, [tmpheight]
	jne .skip4
	cmp bx, 6*8
	jne .skip4
	cmp dh, 00
	jne .skip4
	jmp .done
.skip4:
	sub cx, 10h
.done:
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	ret
;endp dockconstrwinhandler

%macro checktile 1
	call [gettileinfo]
	cmp dl, [tmpheight]
	jne %%.failed
	cmp bx, 6*8	// water tile?
	jne %%.failed
	cmp dh, 00	// full water tile (not coast)?
	jne %%.failed
	cmp di, 00	// flat tile?
	jne %%.failed
	add ebp,0x100
	or ebp,%1
%%.failed:
%endmacro

// checks if a dock can be build at ax,cx; if so, return dl=direction, if not skip calling function, and return an error
global canbuilddockhere
canbuilddockhere:
	pusha
	cmp di, 0	// must be a flat tile
	jne near .failed

	call [gettileinfo]
	mov [tmpheight],dl

	xor ebp,ebp

	sub ax, 10h
	checktile 0
	add ax, 20h
	checktile 2
	sub ax, 10h
	sub cx, 10h
	checktile 3
	add cx, 20h
	checktile 1

	mov edx,ebp
	cmp dh,1	// exactly one water tile?
	je .success

.failed:
	popa
	mov word [operrormsg2], 0x304b
	pop ebx
	mov ebx, 80000000h
	ret

.success:
	mov [esp+0x14],dl
	popa
	ret
;endp canbuilddockhere

global Class5DrawLand
Class5DrawLand:
	jmp .start
.origfunc:
	cmp dh, 50h
	jb .notwater

	cmp dh, 52h
	ja .notwater

	test word [nosplit landscape3+ebx*2], 1 // Check for a canal at sea level because of the next check
	jnz .seacanal

	cmp dl, 0
	je .notwater ; actualy it is water, but not canals, but who cares

.seacanal:
      pusha
	call [oldclass5drawlandfnc]
	popa
	mov esi, ebx
	call normalwaterabove
	ret
.notwater:
	call [oldclass5drawlandfnc]
	ret

.start:
	cmp dh, 0x4C
	jb .origfunc
	cmp dh, 0x4F
	ja .origfunc
	cmp di, 0
	jnz .origfunc

	pusha

	mov bx, 3981
	call [addgroundsprite]
	sub dh, 0x4C
	
	xor ebx, ebx

	cmp dword [canalfeatureids+4*4], 0
	jz .origsprites

	push esi
	push eax

	mov bl, dh
	mov eax, 4		// we want docks :)
	mov esi, 0
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx

	pop eax
	pop esi

.origsprites:
	test dh, 1
	jnz .xdir
.ydir:
	add cx, 4
	mov di, 8
	mov si, 16
	mov dh, 8
	cmp ebx, 0
	jnz .havesprite1
	mov ebx, 2731
.havesprite1:
	call [addsprite]
	popa
	ret

.xdir:
	add ax, 4
	mov di, 16
	mov si, 8
	mov dh, 8
	cmp ebx, 0
	jnz .havesprite2
	mov ebx, 2732
.havesprite2:
	call [addsprite]
	popa
	ret
;endp Class5DrawLand
