
#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <veh.inc>
#include <human.inc>
#include <misc.inc>
#include <ptrvar.inc>
#include <objects.inc>

extern actionhandler,addgroundsprite,addsprite,canalfeatureids
extern checkvehiclesinthewayfn,cleartilefn,curplayerctrlkey,getdesertmap
extern getgroundalt,getnewsprite,gettileinfo,grffeature,landshapetospriteptr
extern locationtoxy,patchflags,redrawscreen
extern waterbanksprites,gettileterrain
extern guispritebase,numguisprites,actionmakewater_actionnum,ctrlkeystate,cleararea_actionnum
extern canalscallbackflags,canalsgraphicflags,curcallback,miscgrfvar

#if 0
struc newwatersprites
	.watercliff:	resb 4
	.lifthouse:		resb 24
	.lifthouseseelevel: resb 24
	.waterwharf:	resb 12
	.ico:			resb 1
endstruc
#endif

// Cost can be calculated via clearwatercost * FACTOR / 8
%define WATERPLACEFACTOR 3
%define SHIPLIFTPLACEFACTOR 22
%define SHIPLIFTCLEARFACTOR 16

// Cliff translation table
var baCliffTranslation, db -1, -1, -1, 2
                db -1, -1, 0, -1
                db -1, 3, -1, -1
                db 1, -1, -1, -1
				
				
%assign canalslifthouseofs 0

var paLiftHouseSprites, dd LiftHouse0, LiftHouse1, LiftHouse2, LiftHouse3	// middle part
dd LiftHouse0b, LiftHouse1b, LiftHouse2b, LiftHouse3b					// bottom
dd LiftHouse0t, LiftHouse1t, LiftHouse2t, LiftHouse3t					// top

var LiftHouse0, db 0, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+4
		    db 0 // seelevel, if it's the same or below use first set!

var LiftHouse1, db 0, 0, 0, 10h, 1, 14h
		    dd canalslifthouseofs+1
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd canalslifthouseofs+4+1
		    db 0

var LiftHouse2, db 0, 0, 0, 10h, 1, 14h
		    dd canalslifthouseofs+2
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd canalslifthouseofs+4+2
		    db 0

var LiftHouse3, db 0, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+3
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+4+3
		    db 0

var LiftHouse0b, db 0, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+8
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+12
		    db 0

var LiftHouse1b, db 0, 0, 0, 10h, 1, 14h
		    dd canalslifthouseofs+8+1
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd canalslifthouseofs+12+1
		    db 0

var LiftHouse2b, db 0, 0, 0, 10h, 1, 14h
		    dd canalslifthouseofs+8+2
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd canalslifthouseofs+12+2
		    db 0

var LiftHouse3b, db 0, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+8+3
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+12+3
		    db 0

var LiftHouse0t, db 0, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+16
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+20
		    db 8

var LiftHouse1t, db 0, 0, 0, 10h, 1, 14h
		    dd canalslifthouseofs+16+1
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd canalslifthouseofs+20+1
		    db 8

var LiftHouse2t, db 0, 0, 0, 10h, 1, 14h
		    dd canalslifthouseofs+16+2
		    db 0, 0Fh, 0, 10h, 1, 14h
		    dd canalslifthouseofs+20+2
		    db 8

var LiftHouse3t, db 0, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+16+3
		    db 0Fh, 0, 0, 1, 10h, 14h
		    dd canalslifthouseofs+20+3
		    db 8

var LiftHouseNoGRF, db 0x83,0x81,0x81,0x83

var newwaterspritebase, dw -1	// First new sprite with water sprites...
		// number of sprites necessary for correct operation
		// (aborts with wrong version number if it doesn't match)
var numnewwatersprites, dd 65+10 // make old canals.grf invalid


uvard oldclass6drawlandfnc,1,s
uvard oldclass6maphandler,1,s
uvard oldclass6periodicproc,1,s
uvard dockwinpurchaselandico,1,s
uvard oldclass5drawlandfnc,1,s
uvard oldclass9drawlandfnc,1,s
uvard oldclass9queryfnc,1,s

uvarb canalaction2array,4  // height byte, dessertmapinfo byte, dikemapbyte, randomnum byte

global SwapDockWinPurchaseLandIco
SwapDockWinPurchaseLandIco:
	testflags canals
	jc .active
	ret
.active:
	extjmp DockWaterConstrWindowSetIcons
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
	mov esi, ebx		// now esi = xy
	jmp Class6DrawLandCanalsOrRiversOrSeeWaterL3

.couldbecliff:
	mov esi, ebx	// we need it later, so store it
	mov ebp, 1
	cmp dh, 3
	je near Class6DrawLandRiverSlope
	cmp dh, 1
	ja Class6DrawLandShiftLift

.oldfunction:
	jmp [oldclass6drawlandfnc]
	ret

Class6DrawLandShiftLift:
	mov esi, ebx	// we need it later, so store it

// Shows the new Shiplifts on and the Watercliffs

// Get the tile type that is stored in the landscape
	movzx edi, byte [landscape2+esi]
	
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
	call FillCanalAction2FeatureArray
// correct the height for special upper parts of locks, they need to get the same height as the lower tiles
	cmp edi, 8
	jb .notatoppart
	dec byte [canalaction2array]
.notatoppart:

	// See if we need a cliff groundsprite
	push ebx
	cmp edi, 3
	ja .normalwatertile

	// draw water cliffs
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

	push esi
	push eax
	mov eax, 1	// we want locks
	mov esi, canalaction2array
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	pop eax
	pop esi

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

	push esi
	push eax
	mov eax, 1	// we want locks
	mov esi, canalaction2array
	mov byte [grffeature], 5
	call getnewsprite
	xchg eax, ebx
	pop eax
	pop esi

	add dl, [ebp+2]
	call [addsprite]
.nosprites:
	popa
	ret

// in: esi xy
// out: filled canalaction2array
//	height byte
//	desertmapinfo byte
//	dikemapbyte
//	randomnum byte
FillCanalAction2FeatureArray:
	pusha
	call getdikemap
	xchg edi, edx
	mov [canalaction2array+2], dl
	// in SI=XY, out ESI=XY, DL=Z, DH=L5[ESI], BX=class<<3, DI=map of corners above DL
	call [gettileinfoshort]
	
	xor eax, eax
	
	cmp bx, 6<<3
	jne .notawatertile				// we may be called by a bridge tile, which has other info in L6
	mov al, byte [landscape6+esi]	// get the random byte
.notawatertile:
	mov [canalaction2array+3], al

	shr dl, 3
	mov [canalaction2array], dl
	shl dl, 3
	
	cmp byte [climate],2
	je .tropic
	cmp byte [climate],1
	je .snowtest
	testflags tempsnowline
	jnc .gotclimate
	cmp byte [climate],0
	jne .gotclimate
.snowtest:
	add dl, 8
	cmp dl,[snowline]
	seta al
	shl al,2
	jmp .gotclimate
.tropic:
	xchg ebx,esi
	call [getdesertmap]
	xchg ebx,esi
.gotclimate:
	mov [canalaction2array+1], al // now 0 normal, 1 desert, 2 rainforest, 4 on or above snowline

	popa
	ret
	

// in: esi tilexy
// edi = corner map
// dl = height
// L3 of esi = Canal/River Type
global Class6DrawLandCanalsOrRiversOrSeeWaterL3.ebp
Class6DrawLandCanalsOrRiversOrSeeWaterL3:
	// the corners aren't allowed to be used with canals code because of crash
	cmp esi,0x101
	jb .nocanal
	movzx ebp, byte [landscape3+2*esi]

// Same as above but with ebp containing the bits from L3
.ebp:
	and ebp, 11b
	jz .nobitsset
	shr ebp, 1			// now for canals = 0 and for rivers = 1
	jmp Class6DrawLandCanalsOrRiverSlope
.nobitsset:
	// If we need to draw some eyecandy around the water sprites height > 0
	cmp dl, 0
	jnz Class6DrawLandCanalsOrRiverSlope
// no, normal water tile
.nocanal:
	mov ebx, 4061
	call [addgroundsprite]
	ret
		
	// fall through if it's canals	
Class6DrawLandCanals:
	xor ebp, ebp
	jmp short Class6DrawLandCanalsOrRiverSlope

Class6DrawLandRiverSlope:
	mov ebp, 1

// in: esi tilexy
// edi = corner map
// ebp = 0 canals 1 = rivers
Class6DrawLandCanalsOrRiverSlope:
	call FillCanalAction2FeatureArray

	pusha
	push eax
	mov ebx, 4061

	cmp ebp, 0
	je .canal

	mov eax, 5	// we want river slopes
	cmp dword [canalfeatureids+5*4], 0
	jnz .hassprites

.canal:
	mov eax, 0	// we want water cliffs from canals
	cmp dword [canalfeatureids+0*4], 0
	jnz .hassprites
		
	jmp .nosprites
.hassprites:
	and edi, byte 0x0F
	movsx ebx, byte [baCliffTranslation+edi]
	
	test byte [canalsgraphicflags+eax], 1
	jz .nogroundsprite
	inc ebx
.nogroundsprite:
	cmp ebx, -1	// if we have no groundsprite for a flat tile, we have still have -1 now. Result, less jmps
	jne .docallback
	
	mov ebx, 4061
	jmp .nosprites

.docallback:
	mov esi, canalaction2array
	mov byte [grffeature], 5
	
// call callback 0x147 to get a new offset if the grfauthor wish..
	test byte [canalscallbackflags+eax],1
	jz .nocallback
	mov dword [curcallback], 0x147
	mov dword [miscgrfvar], ebx
	push eax
	call getnewsprite
	// jc not needed, as failing means eax = 0
	add ebx, eax
	pop eax
	mov dword [curcallback], 0
	mov dword [miscgrfvar], 0
.nocallback:	
	
	call getnewsprite
	xchg eax, ebx
.nosprites:
	pop eax
	call [addgroundsprite]
	popa
	
	pusha


	mov ebx, ebp
	shl ebx, 2			// now ebx = 0 or 4
	add ebx, 2			// now ebx = 2(dikes) or 6 (river waterside as feature)

	// select river waterside
	cmp dword [canalfeatureids+ebx*4], 0
	jz .nospriteswaterside
	
	mov dword [showadikespritetype], ebx
	and edi, byte 0x0F
	movsx ebx, byte [baCliffTranslation+edi]
	inc ebx
	imul ebx, 12
	mov dword [showadikespriteofs], ebx
	
	popa
	movzx edi, byte [canalaction2array+2]
	jmp DrawDikeAroundWater
	
.nospriteswaterside:
	popa
	
	ret
;endp Class6DrawLand

uvard saved_ebx
uvarb aquaductflag
var coastdirections // xy-offsets for all possible height masks (1234h means this must have a coast drawn whatsoever)
	dw 0000h, 1234h, 1234h, -001h
	dw 1234h, 0000h, -100h, 0000h 
	dw 1234h, +100h, 0000h, 0000h
	dw +001h, 0000h, 0000h, 0000h
uvard newaquaductbase	//4 end sprites (on to bridge is: SW, SE, NE, NW), 4 base sprites: X,Y of top, pillar
uvard newaquaductnum

uvard aquamiddlebridgesprites,8

global class9drawland
class9drawland:
	mov [saved_ebx], ebx
	test dh, 0xF0
	jz .norm
	movzx si, dh
	and si, 6
	cmp si, 4
	jne .norm
	mov BYTE [aquaductflag], 1
	jmp [oldclass9drawlandfnc]
.norm:
	mov BYTE [aquaductflag], 0
	jmp [oldclass9drawlandfnc]


exported aquaductmiddlespritebaseget

	test BYTE [aquaductflag], 1
	jz .norm
	cmp DWORD [newaquaductnum], 8
	jb .norm
	mov edi, [newaquaductbase]
	push eax
	lea eax, [edi+31E8004h]
	mov [aquamiddlebridgesprites], eax
	inc eax
	mov [aquamiddlebridgesprites+4*4], eax
	lea eax, [edi+6]
	mov edi, aquamiddlebridgesprites
	mov [edi+2*4], eax
	inc eax
	mov [edi+6*4], eax
	mov eax, 1<<0x1E
	mov [edi+1*4], eax
	mov [edi+5*4], eax
	and ebx, 2<<3
	pop eax
	mov [esp+4], ebx
	mov [esp+8], edi
.norm:
	mov     ebx, [ebx+edi]	//old code starts
	btr     ebx, 1Eh	//old code ends
	ret

uvard aquaendbridgesprites, 4

exported aquaductendspritebaseget
	test BYTE [aquaductflag], 1
	jz .norm
	cmp DWORD [newaquaductnum], 8
	jb .norm
	
	mov esi, [newaquaductbase]
	test dh, 20h
	jz .next1
	add esi, 2
.next1:
	test bl, 2
	jz .next2
	inc esi
.next2:
	mov ebx, esi
	ret
.norm:
	and ebx, 0Ch		//old
	mov ebx, [esi+ebx*8]
	ret
	
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
	testflags canals
	jc .hascanals
	call [addgroundsprite]
	ret
	
.hascanals:
.hasriverslope:
	mov esi, [saved_ebx]
	// needs esi = xy, edi = corner, and dl = height
	jmp Class6DrawLandCanalsOrRiversOrSeeWaterL3	
.coast:
	mov esi, [saved_ebx]
	mov bx, word [landscape3+esi*2]
	and ebx, 11b
	cmp ebx, 11b
	jz .hasriverslope
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

	mov ax, word [landscape3+esi*2]
	and ax, 11b
	cmp ax, 11b
	je .riveronslope
.coast:
	popa
	mov dx, 0x6001
	ret
.riveronslope:
	popa
	mov dx, 0x6003
	ret

.nocoast:
	popa
	mov dx, 0x6000
	ret
;endp removebridgewater

// code for showing "dikes" around water
// in:
//	esi = xy
//	edi = corner map
//	dl = height
//  L3 = type
DrawDikeAroundWaterTestL3:
	pusha
	xor ebx, ebx
	movzx ebx, byte [landscape3+2*esi]
	and ebx, 11b
	jnz .trydrawing
	// If we need to draw some eyecandy around the water sprites height > 0
	cmp dl, 0
	jz .nosprites
	
.trydrawing:
	// now canals or rivers
	and ebx, 10b
	shl ebx, 1			// now ebx = 0 or 4
	add ebx, 2			// now ebx = 2(dikes) or 6 (river waterside as feature)

	// select river waterside
	cmp dword [canalfeatureids+ebx*4], 0
	jz .nosprites
	call FillCanalAction2FeatureArray
	mov dword [showadikespritetype], ebx
	and edi, byte 0x0F
	movsx ebx, byte [baCliffTranslation+edi]
	inc ebx
	imul ebx, 12
	mov dword [showadikespriteofs], ebx
	
	popa
	movzx edi, byte [canalaction2array+2]
	jmp DrawDikeAroundWater
	
.nosprites:
	popa
	ret	
	
// in: 
//	edi = dikemap
//	ax,cx = tilexy
//  showadikespritetype = type to draw
//	showadikespriteofs = offset in type (to support slopes as examples)
DrawDikeAroundWater:
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


uvard showadikespritetype, 1
uvard showadikespriteofs, 1

// ebx = cornernumber
showadikesprite:
	push edi

	push esi
	push eax
	add ebx, [showadikespriteofs]
	mov eax, [showadikespritetype]	// dike parts or other
	mov esi, canalaction2array
	mov byte [grffeature], 5
	
	test byte [canalscallbackflags+eax],1
	jz .nocallback
	mov dword [curcallback], 0x147
	mov dword [miscgrfvar], ebx
	push eax
	call getnewsprite
	// jc not needed, as failing means eax = 0
	add ebx, eax
	pop eax
	mov dword [curcallback], 0
	mov dword [miscgrfvar], 0
.nocallback:		
		
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
	call iswateredtilestart
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
// 		ebx = tile to check  (not in start)
extern gettileinfoshort

uvarb iswateredrefheight
uvarw iswateredrefcorner
iswateredtilestart:
	pusha
	//  in SI=XY, out ESI=XY, DL=Z, DH=L5[ESI], BX=class<<3, DI=map of corners above DL
	call [gettileinfoshort]
	mov [iswateredrefheight], dl
	mov [iswateredrefcorner], di
	popa
	ret
	
iswateredtile:
	pusha
	xchg esi, ebx
	//  in SI=XY, out ESI=XY, DL=Z, DH=L5[ESI], BX=class<<3, DI=map of corners above DL
	call [gettileinfoshort]	
// Show rules
	cmp bl, 6<<3	// is it a water tile
	jnz .testother
	cmp dh, 1
	jnz .watertile	// no cliff
	
// if we have a cliff and we need to check if our reference tile is above ground
	cmp byte [iswateredrefheight], 0	// a seelevel reference tile
	jnz .notwater
	cmp word [iswateredrefcorner], 0	// are we a slope tile? if not, we assume water
	jz .watertile
	// non flat ref tile with lowest height 0
	bt di, 4
	jc .notwater	// steep slopes are to complicate
	mov bx, word [iswateredrefcorner]
	not ebx
	and di,0x0f
	and bx,0x0f
	test di, bx
	jnz .watertile
	jmp .notwater

.testother:
// ESI=XY, DL=Z, DH=L5[ESI], BX=class<<3, DI=map of corners above DL
// returns carry if water
	cmp bl, 5<<3
	je .station
	
	cmp bl, 9<<3
	je .bridgetunnelpiece
	
	cmp bl, 0xA<<3
	je .object
	
.notwater:
	popa
	clc
	ret

// Station Tiles
.station:
	cmp dh, 0x4B
	jb .notwater
// fall through

.watertile:
       popa
       stc
       ret

	
// Bridge + Tunnel Parts:
.bridgetunnelpiece:
	// test if it's a bridge middlepart
	bt dx, 14		// would be:  bt dh, 6 but thats not supported in x86 
	jnc .testbridgeend	// not a middle part
	bt dx, 13		// 5
	jc .notwater		// not a land/water
	bt dx, 11		// 3
	jnc .notwater		// not a water tile
	jmp .watertile
.testbridgeend:
	and dh, 0x86
	cmp dh, 0x84
	je .watertile
	jmp .notwater
	
// Objects
.object:
	cmp dh, NOBJECTTYPE
	jne .notwater
	
extern objectpool_ptr, objectsdataidtogameid, objectflags
	cmp dword [objectpool_ptr], 0
	je .notwater    // new grf object subsystem not loaded properly?
	
	movzx edi, word [landscape3+esi*2]
	imul edi, object_size
//	test word [objectpool+edi+object.flags], OF_BUILDWATER
	movzx edi, word [objectpool+edi+object.dataid]
	movzx edi, word [objectsdataidtogameid+edi*2]
	test di, di
	jz .notwater
	test word [objectflags+edi*2], OF_BUILDWATER | OF_DRAWWATER
	jnz .watertile
	jmp .notwater
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
	cmp byte [landscape5(di)], 3h                    
	je .rivertilecliff
	jmp [oldclass6maphandler] // to TTD normal handler
.rivertilecliff:
	xor eax, eax
	ret
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
	cmp dh, 3
	je near clearriverslope
	jmp clearshiplift
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

clearriverslope:
	pusha
	call locationtoxy
	xchg esi, edi
	call dword [checkvehiclesinthewayfn]
	xchg esi, edi
	jnz .errorvehicle
	call dword [cleartilefn]
	
	popa
	mov ebx, [clearwatercost]
	ret
.errorvehicle:
	popa
	mov ebx, 80000000h
	ret

// 4 x under part, upper part 
var paShipLiftAddPartsInLandscape, dw 0, -16, 0, 16,
dw 16, 0, -16, 0,
dw -16, 0, 16, 0,
dw 0, 16, 0, -16
uvard tmpshplftlndxy, 2

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

	push ebp
	mov bp, ax
	mov dx, cx
	movzx ebx, di
	add ax, word [paShipLiftAddPartsInLandscape+ebx*8]
	add cx, word [paShipLiftAddPartsInLandscape+ebx*8+2]
	add bp, word [paShipLiftAddPartsInLandscape+ebx*8+4]
	add dx, word [paShipLiftAddPartsInLandscape+ebx*8+6]
	shl edx, 16
	mov dx, bp
	mov bl, 2
	dopatchaction cleararea
	pop ebp
	cmp ebx, 80000000h
	jnz .noerrorcleartile
	jmp .error // tempfix for short jump problem 

.noerrorcleartile:
	extern TempCAActionErrorCount
	cmp DWORD [TempCAActionErrorCount], 0
	jne NEAR .error1
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	push ebp
	call [gettileinfo]
	pop ebp
	test byte [%$actionbuildflags], 1
	jz .onlytestingmiddle
	mov [tmpshplftlndxy],esi
.onlytestingmiddle:


// bottom
	movzx ebx, word [%$shiplifttype]
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	add ax, word [paShipLiftAddPartsInLandscape+ebx*8]
	add cx, word [paShipLiftAddPartsInLandscape+ebx*8+2]
	push ebp
	call [gettileinfo]
	pop ebp
	cmp di, 0	// is flat tile
	jz .nobottomerrorflat
	jmp .error
.nobottomerrorflat: // tempfix for short jump problem 
	
	test byte [%$actionbuildflags], 1
	jz .onlytestingbottom
	mov [tmpshplftlndxy+4], esi
.onlytestingbottom:

// top part
	movzx ebx, word [%$shiplifttype]
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	add ax, word [paShipLiftAddPartsInLandscape+ebx*8+4]
	add cx, word [paShipLiftAddPartsInLandscape+ebx*8+6]

	push ebp
	call [gettileinfo]
	pop ebp
	cmp di, 0	// is flat tile
	jnz NEAR .error
	
	test byte [%$actionbuildflags], 1
	jz NEAR .onlytestingtop
	push esi
	movzx ebx, word [%$shiplifttype]
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	mov si, ax
	mov dx, cx
	add ax, word [paShipLiftAddPartsInLandscape+ebx*8]
	add cx, word [paShipLiftAddPartsInLandscape+ebx*8+2]
	add si, word [paShipLiftAddPartsInLandscape+ebx*8+4]
	add dx, word [paShipLiftAddPartsInLandscape+ebx*8+6]
	shl edx, 16
	mov dx, si
	mov bl, 0x11
	push ebp
	dopatchaction cleararea
	pop ebp
	pop esi
	cmp ebx, 80000000h
	je NEAR .error

	//top
	mov byte [landscape1+esi], 11h
	mov bx, [%$shiplifttype]
	add bx, 8
	mov byte [landscape2+esi], bl
	mov word [landscape3+esi*2], 1h
	or byte [landscape4(si)], 60h
	mov byte [landscape5(si)], 2h

	//middle
	mov esi, [tmpshplftlndxy]
	mov byte [landscape1+esi], 11h
	mov bx, [%$shiplifttype]
	mov byte [landscape2+esi], bl
	mov word [landscape3+esi*2], 1h
	or byte [landscape4(si)], 60h
	mov byte [landscape5(si)], 2h

	//bottom
	mov esi, [tmpshplftlndxy+4]
	mov byte [landscape1+esi], 11h
	mov bx, [%$shiplifttype]
	add bx, 4
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
.error1:
	mov ebx, 80000000h
.error:
	mov ax, [%$tilex]
	mov cx, [%$tiley]
	mov ebx, 80000000h
	mov word [operrormsg1], ourtext(cantbuildcanalhere)
	mov word [operrormsg2], 0x0239
	_ret

endproc createshiplift


// Action Handler for creating water
uvard actionmakewater_type
global actionmakewater
actionmakewater:	//bh:1->dx valid, dl=x extent, dh=y extent, edi=type of water
	mov dword [actionmakewater_type], edi
	test bh, 1
	jnz .multi
	mov dx, 0x101
.multi:
	movzx edx, dx
	movzx esi, dl
	shl esi, 16
	or edx, esi
	push ax
	push cx
	push edx	//high byte used to store flags: 1=successful tile, lower high byte stores x extent
	push DWORD 0	//cost

.loop:
	mov [esp+4], dl
.innerloop:
	push ebx
	call .tileloop
	cmp ebx, 0x80000000
	je .notok
	or BYTE [esp+11], 1
	add [esp+4], ebx
.notok:
	pop ebx
	add ax, 0x10
	dec BYTE [esp+4]
	jnz .innerloop
	add cx, 0x10
	movzx edx, BYTE [esp+6]
	shl edx, 4
	sub ax, dx
	shr edx, 4
	dec BYTE [esp+5]
	jnz .loop

	pop ebx
	pop edx
	pop cx
	pop ax
	test edx, 0x1000000
	jz .reterr
	ret
.reterr:
	mov ebx, 0x80000000
	ret

.tileloop:
	xor esi, esi
	rol cx, 8
	mov si, cx
	rol cx, 8
	or si, ax
	ror si, 4

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
	js near .error
	
.halftile:
	mov dl, byte [curplayerctrlkey]
	cmp dl, 1
	cmp dword [actionmakewater_type], 1
	je .rivertileoncliff
	// we are creating a shiplift...
	jmp createshiplift
	
.rivertileoncliff:
	// call remove everything on tile
	pusha
	mov esi, 0
 	call [actionhandler]
	cmp ebx, 80000000h
	popa
	jz near .error

	test bl, 1
	jz near .onlytesting
	mov byte [landscape5(si)], 3h
	mov word [landscape3+esi*2], 11b
	jmp short .common
	
.flattile:
	mov dh,[landscape4(si)]
	shr dh, 4

	cmp dh, 6
	jz near .error

	// call remove everything on tile
	pusha
	mov esi, 0
 	call [actionhandler]
	cmp ebx, 80000000h
	popa
	jz .error

	test bl, 1
	jz .onlytesting
	
	mov byte [landscape5(si)], 0h
	cmp dl, 0	// height?
	jne .noseelevel
	movzx edx,byte [curplayerctrlkey]
	cmp edx, 1
	je .seelevel
.noseelevel:
	cmp dword [actionmakewater_type], 1
	jz .rivertile
.canaltile:
	mov word [landscape3+esi*2], 1b
	jmp short .common
.rivertile:	
	mov word [landscape3+esi*2], 11b
	jmp short .common
.seelevel:
	mov word [landscape3+esi*2], 0
	jmp short .common
.common:
	mov byte [landscape2+esi], 0h
	or byte [landscape4(si)], 60h
	mov byte [landscape1+esi], 11h
	push eax
	extern randomfn
	call [randomfn]
	mov byte [landscape6+esi], al
	pop eax
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

	pusha
	call [oldclass5drawlandfnc]
	popa
	// now test and try to draw dikes or river sides
	mov esi, ebx
	call DrawDikeAroundWaterTestL3
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

uvarb canaltooltype

exported selectdockpurchaselandtool_spritesel
	xor bl, bl
	testflags enhancegui
	jnc .norm	//no enhanced gui, no aquaducts
	mov ax, 0x301
	push byte CTRL_ANY+CTRL_MP
	call ctrlkeystate
	setz bl
.norm:
	mov [canaltooltype], bl
	or bl, bl
	jne .aquaduct
	mov ebx, 4792
	cmp dword [numguisprites], 0x4A
	jbe .nonewcanalicon
	movzx ebx, word [guispritebase] // Calculate the sprite to use
	add ebx, 0x4A
.nonewcanalicon:
	ret
.aquaduct:
	mov ebx, 2593
	ret

exported newdocktoolpurchaseland_handler
	testflags enhancegui
	jnc .norm
	cmp BYTE [canaltooltype], 1
	je .bridge
	jmp .drag
.norm:
	mov bl, 3
	mov word [operrormsg1], ourtext(cantbuildcanalhere)
	mov esi, actionmakewater_actionnum
	ret
.bridge:
.drag:
	cmp ax, 0FEFh
	ja .fret
	cmp cx, 0FEFh
	ja .fret
	mov bx, cx
	rol bx, 8
	or bx, ax
	ror bx, 4
	mov [dragtoolstartx], ax
	mov [dragtoolstarty], cx
	mov [dragtoolendx], ax
	mov [dragtoolendy], cx
	mov byte [curmousetooltype], 3
	bts word [uiflags], 13
.fret:
	add esp, 4	//eat return address about to call doaction off stack
	ret

exported Class9Query
	cmp al, 2
	je .check0
.norm:
	jmp [oldclass9queryfnc]
.check0:
	movzx edi, di
	mov cl,[landscape5(di)]
	or cl, cl
	jns .norm
	and cl, 6
	cmp cl, 4
	jne .norm
	
	mov ax, ourtext(aquaducttext)

	test byte [landscape5(di)], 40h
	jz .next1
	mov ebx, edi
	mov cx, -1
	test byte [landscape5(di)], 1
	jz .next2
	mov cx, -100h

.next2:
	add bx, cx
	test byte [landscape5(bx)], 40h
	jnz .next2
	mov bl, [landscape1+ebx]
	ret
.next1:
	mov bl, [landscape1+edi]
	ret
