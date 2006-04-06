//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
//  Ladies and Gentlemen... Let me introduce to you TRAMS!
//  The basic idea:
//	--Allocate a Variable in the vehmiscflags to specify a road vehicle as a tram
//	--If a road vehicle is a tram, check L3 0..3 for its route-map instead of L5
//	--Draw tramtracks over the roadbase... drawing a basic landscape sprite if no road
//	--allow this shiz to work without breaking OneWay Roads
//
//	Any Questions/Comments, blast stevenhoefel (at) hotmail (dot) com
//	Or anyone in #Tycoon on QuakeNet or the forums @ http://www.tt-forums.net/
//---------------------------------------------------------------------------------------------
#include <std.inc>
#include <window.inc>
#include <veh.inc>
#include <newvehdata.inc>
#include <textdef.inc>
#include <misc.inc>

extern	RefreshWindows,  gettileinfo, addsprite, addgroundsprite
extern	catenaryspritebase,elrailsprites.wires, elrailsprites.pylons, elrailsprites.anchor,housespritetable
extern	newvehdata, invalidatetile, addrelsprite, demolishroadflag, checkroadremovalconditions
extern  rvcheckovertake, CreateWindow, txteroadmenu

extern CloseWindow, RefreshWindowArea

extern addrailfence1,addrailfence2,addrailfence3,addrailfence4,addrailfence5,addrailfence6,addrailfence7,addrailfence8

uvard	tramVehPtr,1,s
uvard	RVMovementArrayPtr
uvarw	tramtracks,1,s
uvard	Class0DrawLand, 1, s
uvard	roadtoolbarelemlisty2
uvard	oldClass2DrawLand,1,s
uvard	oldRoadTile,1,s
uvard	Class5LandPointer,1,s
uvard	Class2LandPointer,1,s
uvard	stdRoadElemListPtr,1,s
uvarb	editTramMode
uvarb	curTileMap
uvard	bTempNewBridgeDirection
uvard	tramTracksSWNE
uvard	tramTracksNWSE
uvard	paRoadConstrWinClickProcs,1,s
uvarw	tmpDI,1,s
var	numtramtracks, dd 75
var	tramfrontwiresprites,	db 0h, 37h, 37h, 3Fh, 37h, 37h, 43h, 37h, 37h, 3Fh, 37h, 37h, 3Fh, 37h, 37h, 37h
var	trambackpolesprites,	db 0h, 38h, 39h, 40h, 38h, 38h, 43h, 3Eh, 39h, 41h, 39h, 3Ch, 42h, 3Bh, 3Dh, 3Ah
var	tramtracksprites,	db 0h, 16h, 15h, 0Bh, 14h, 04h, 0Eh, 09h, 13h, 0Ch, 05h, 08h, 0Dh, 07h, 0Ah, 06h, 00h, 01h, 02h, 03h, 30h
var	tramMovement,		db 0h, 02h, 01h, 10h, 02h, 02h, 08h, 1Ah, 01h, 04h, 01h, 15h, 20h, 26h, 29h, 3Fh

vard paStationtramstop, paStationtramstop1, paStationtramstop2
var paStationtramstop1
	dd 1314
	db 0x80
var paStationtramstop2
	dd 1313
	db 0x80

uvard roadmenuelemlisty2

global storeVehIDAndContinue
storeVehIDAndContinue:
	mov	dword [tramVehPtr], esi
	inc	byte [esi+veh.cycle]
	cmp	byte [esi+6Ah], 0    //actually known as .field_6A in IDA
	jz      short .dontDEc
	dec     byte [esi+6Ah]
.dontDEc:
	retn

global destroyVehIDAndContinue
destroyVehIDAndContinue:
	mov	dword [tramVehPtr], -1
	mov	bx, [esi+veh.XY]
	call	[RefreshWindows]
	retn

global Class2RouteMapHandlerChunk1
Class2RouteMapHandlerChunk1:
	cmp	dword [tramVehPtr], 0FFFFFFFFh
	je	.continueRouteMapping
	push	esi
	push	edx
	mov	esi, [tramVehPtr]
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
	pop	esi
	jz	.checkNormalRoads
	mov	byte al, [landscape3+edi*2]	//check for trams
	jmp	.continueRouteMapping

.checkNormalRoads:
	mov	al, [landscape5(di)]

.continueRouteMapping:	
	mov	ah, al
	and	ah, 0F0h
	retn


global noOneWaySetTramTurnAround
global noOneWaySetTramTurnAround.rvmovement
noOneWaySetTramTurnAround:
	cmp	dword [tramVehPtr], 0FFFFFFFFh
	je	.normalRoadVehicleMovement
	push	esi
	push	edx
	mov	esi, [tramVehPtr]
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
	pop	esi

	jz	.normalRoadVehicleMovement
	mov	al, byte [tramMovement+eax]
	jmp	.shipRoadMovement

.normalRoadVehicleMovement:
	mov	al, [dword 0+eax]
.rvmovement equ $-4

.shipRoadMovement:
	mov	ah, al
	retn

global insertTramTrackL3Value
insertTramTrackL3Value:
	call	[gettileinfo]
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	.dontLoadTramArray
	cmp	byte [editTramMode], 0
	jz	.dontLoadTramArray
	push	dx
	and	dh, 10h
	cmp	dh, 10h
	pop	dx
	je	.dontLoadTramArray
    
	mov	byte dh, [landscape3+esi*2]	
    
.dontLoadTramArray:
	cmp	bl, 10h
	retn


global insertTramTrackIntoRemove
insertTramTrackIntoRemove:
	call	[gettileinfo]
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	.dontLoadTramArray
	cmp	byte [demolishroadflag],1
	je	.dontLoadTramArray
	cmp	byte [editTramMode], 0
	jz	.dontLoadTramArray
	mov	byte dh, [landscape3+esi*2]
.dontLoadTramArray:
	cmp	bl, 48h
	retn

global insertTramTracksIntoFindRoadDepot
insertTramTracksIntoFindRoadDepot:
	call	[gettileinfo]
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	.dontLoadTramArray
	push	edx
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
	jz	.dontLoadTramArray
	mov	byte dh, [landscape3+esi*2]
.dontLoadTramArray:
	cmp	bl, 48h
	retn


global shiftTramBytesIntoL5
shiftTramBytesIntoL5:
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	.dontMakeTramTracks
	cmp	byte [editTramMode], 0
	je	.dontMakeTramTracks
	or	byte [landscape3+esi*2], bh
	jmp	short .dontMakeRoads

.dontMakeTramTracks:
	or	byte [landscape5(si)], bh		//we want to move this into landscape3 now

.dontMakeRoads:
	mov	byte [landscape2+esi], 0
	retn


global attemptRemoveTramTracks
attemptRemoveTramTracks:
	cmp	byte [demolishroadflag],1 //dynamite? trash it ALLL!
	jz	short .dynamiteBoth
	cmp	byte [editTramMode], 1
	jz	short .onlyDeleteTramTracks
	jmp	short .onlyDeleteRoads

.deleteTracksAndRoads:
	cmp	byte [landscape5(si)], 0
	jz	short .onlyDeleteTramTracks
	xor	[landscape5(si)], bh
.onlyDeleteTramTracks:
	cmp	byte [landscape3+esi*2], 0
	jz	short .finaliseDeleting
	xor	[landscape3+esi*2], bh
	test	byte [landscape3+esi*2], 0Fh
	jnz	.finaliseDeleting
	test	byte [landscape5(si)], 0Fh
	jmp	short .finaliseDeleting

.onlyDeleteRoads:
	xor	[landscape5(si)], bh
	test	byte [landscape5(si)], 0Fh
	jnz	.finaliseDeleting
	test	byte [landscape3+esi*2], 0Fh
	jmp	.finaliseDeleting

.dynamiteBoth:
	cmp	byte [landscape5(si)], 0
	jz	short .dynamiteTramTracks
	mov	byte [landscape5(si)], 0
.dynamiteTramTracks:
	cmp	byte [landscape3+esi*2], 0
	jz	short .finaliseDeleting
	mov	byte [landscape3+esi*2], 0
	test	byte [landscape3+esi*2], 0Fh

.finaliseDeleting:
	retn





global newStartToClass2DrawLand
newStartToClass2DrawLand:
	mov	dword [Class2LandPointer], ebx
	cmp	dh, 0
	jnz	.dontMoveInTramTracks
	mov	dh, byte [landscape3+ebx*2]
	mov	byte [curTileMap], dh
	jmp	.continueOn

.dontMoveInTramTracks:
	push	dx
	mov	dh, byte [landscape3+ebx*2]
	mov	byte [curTileMap], dh
	pop	dx

.continueOn:
	jmp	[oldClass2DrawLand]



global DrawTramTracks
DrawTramTracks:
	call	near $
ovar .origfn, -4, $, DrawTramTracks

	push	ax
	mov 	al, byte [landscape4(si)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jne	near .noTramTrackImagery

	cmp	word [tramtracks], 0
	jle	near .noTramTrackImagery

	pushad
	mov	word [tmpDI], di
.skipDrawingRoads:
	cmp	byte [landscape3+esi*2], 0   //check for tram tracks...
	jz	near .finishDrawTramTracks

	xor	ebx,ebx
	movzx	bx,  byte [curTileMap]
	movzx	bx, [tramtracksprites+ebx]
	or	di, di
	jz	short .skipSlopes
	mov	bx, 0Fh
	cmp	di, 0Ch
	jz	short .skipSlopes
	inc	bx
	cmp	di, 6
	jz	short .skipSlopes
	inc	bx
	cmp	di, 3
	jz	short .skipSlopes
	inc	bx

.skipSlopes:
	cmp	byte [landscape5(si)], 0
	jnz	.dontAddOffRoadTracks
	add	bx, 17h
	push	eax
	push	ebx
	push	ebp
	push	esi
;    //add rail fences...
	xor	ebx,ebx

	mov	bl, byte [landscape3+esi*2]
	and	bl, 1 //NW
	jnz	.checkSW
	call	[addrailfence1]
.checkSW:
	mov	bl, byte [landscape3+esi*2]
	and	bl, 2 //SW
	jnz	.checkSE
	call	[addrailfence4]
.checkSE:
	mov	bl, byte [landscape3+esi*2]
	and	bl, 4 //SE
	jnz	.checkNE
	call	[addrailfence2]
.checkNE:
	mov	bl, byte [landscape3+esi*2]
	and	bl, 8 //NE
	jnz	.getReadytoAddRails
	call	[addrailfence3]

.getReadytoAddRails:
	pop	esi
	pop	ebp
	pop	ebx
	pop	eax
	or	di, di
	jz	short .weneedToHackStuff
	mov	di, 5h
	mov	si, 5h
	mov	dh, 1h
	jmp	short .skipBoundingBox
.weneedToHackStuff:
	mov	di, 4h
	mov	si, 4h
	mov	dh, 0Bh
	jmp	short .skipBoundingBox
.dontAddOffRoadTracks:
	mov	di, 8h
	mov	si, 8h
	mov	dh, 1h
.skipBoundingBox:
	add	bx,[tramtracks]
	call	[addsprite]
	xor	ebx,ebx
	movzx	bx, byte [curTileMap]
	movzx	bx, [trambackpolesprites+ebx]
	xor	edi,edi
	mov	di, word [tmpDI]
	or	di, di
	jz	short .skipSlopesRearElec
	mov	bx, 44h
	cmp	di, 0Ch
	jz	short .skipSlopesRearElecDraw
	inc	bx
	cmp	di, 6
	jz	short .skipSlopesRearElecDraw
	inc	bx
	cmp	di, 3
	jz	short .skipSlopesRearElecDraw
	inc	bx
	jmp	short .skipSlopesRearElecDraw

.skipSlopesRearElec:
	push	bx
	add	bx, [tramtracks]
	mov	di, 0Fh
	mov	si, 0Fh
	mov	dh, 40h
	call	[addsprite]
	pop	bx

	xor	ebx,ebx
	movzx	bx, byte [curTileMap]
	movzx	bx, [tramfrontwiresprites+ebx]
	add	bx, [tramtracks]
	mov	di, 0Fh
	mov	si, 0Fh
	mov	dh, 08h
	call	[addsprite]
	jmp	.finishDrawTramTracks

.skipSlopesRearElecDraw:
	push	bx
	add	bx, [tramtracks]
	mov	di, 0Fh
	mov	si, 0Fh
	mov	dh, 40h
	call	[addsprite]
	pop	bx

	add	bx, 4
	add	bx, [tramtracks]
	mov	di, 0Fh
	mov	si, 0Fh
	mov	dh, 08h
	call	[addsprite]

.finishDrawTramTracks:
	popad
.noTramTrackImagery:
	retn

global updateRoadRemovalConditions
updateRoadRemovalConditions:
	movzx	edi, di
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	.runNormalCheck
	cmp	byte [editTramMode], 1
	jz	short .dontCheckWithAuthority
.runNormalCheck:
	call	[checkroadremovalconditions]
.dontCheckWithAuthority:
	retn

global drawTramTracksOnStation
drawTramTracksOnStation:
	call	near $
ovar .origfn, -4, $, drawTramTracksOnStation

	cmp	word [tramtracks], 0
	jle	near .dontAddTramTracks
	mov	esi, dword [Class5LandPointer]
	test	byte [landscape3+esi*2], 0x10
	jz	near .dontAddTramTracks
	movzx	bx, byte [landscape5(si)] //also check if L5 reports that we are in a bus stop!
	cmp	bx, 54h
	jnz	.tryNextDirection
	mov	bx, 17h
	jmp	.weGotItSoDraw

.tryNextDirection:
	mov	esi, dword [Class5LandPointer]
	movzx	bx, byte [landscape5(si)]
	cmp	bx, 53h
	jnz	near .dontAddTramTracks
	mov	bx, 18h

.weGotItSoDraw:
	push	ebx
	add	bx, [tramtracks]
	mov	si, 6h
	push	ebx
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
	pop	ebx
	add	bx, 2
	add	dh, 8h
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
	pop	ebx

	cmp	bx, 18h
	jne	.drawWiresOtherDirection
	jmp	.drawOtherWires

.drawWiresOtherDirection:
	xor	ebx,ebx
	mov	bl, 05h
	push	ebx
	movzx	bx, [trambackpolesprites+ebx]
	add	bx, [tramtracks]
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
	pop	ebx
	movzx	bx, [tramfrontwiresprites+ebx]
	add	bx, [tramtracks]
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
	jmp 	.dontAddTramTracks
.drawOtherWires:
	xor	ebx,ebx
	mov	bl, 0Ah
	push	ebx
	movzx	bx, [trambackpolesprites+ebx]
	add	bx, [tramtracks]
	mov	di, 14h
	mov	si,14h
	mov	dh, 8h
	call	[addsprite]
	pop	ebx
	movzx	bx, [tramfrontwiresprites+ebx]
	add	bx, [tramtracks]
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
.dontAddTramTracks:
	retn

global insertTramsIntoGetGroundAltitude
insertTramsIntoGetGroundAltitude:
	call	near $
ovar .origfn, -4, $, insertTramsIntoGetGroundAltitude
	cmp	word bx, (2*8)
	jnz	.skipInsertingTramTracks
	cmp	dh, 0
	jnz	.skipInsertingTramTracks
	mov	byte dh, [landscape3+esi*2]
.skipInsertingTramTracks:
	retn
    
global stopTramOvertaking
stopTramOvertaking:
	cmp	byte [tramVehPtr], 0
	jle	.dontLetTramsOvertake
	push	esi
	push	edx
	mov	esi, [tramVehPtr]
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
	pop	esi
	jnz	.dontLetTramsOvertake
	call	[rvcheckovertake]
.dontLetTramsOvertake:
	retn

global createRoadConstructionWindow
createRoadConstructionWindow:
	cmp	al, 1
	jne	.moveInZero
	mov	byte [editTramMode], 1
	jmp	.movedInData
.moveInZero:
	mov	byte [editTramMode], 0
.movedInData:
	mov	eax, 356 + (22 << 16)
	mov	ebx, 284 + (36 << 16)
	mov	cx, 3h
	mov	dx, 10h
	mov	ebp, 1
	call	[CreateWindow]            ; EAX = x + (y << 16)
	push	edi
	cmp	byte [editTramMode], 1
	jne	.drawInRoads
	mov	edi, addr(saTramConstrWindowElemList)
	jmp	short .doneElemList
.drawInRoads:
	mov	edi, [stdRoadElemListPtr]
.doneElemList:
	mov	dword [esi+window.elemlistptr], edi
	cmp	byte [editTramMode], 1
	jne	.dontSetTruckStopDisabled
	mov	dword [esi+window.disabledbuttons], 200h
.dontSetTruckStopDisabled:
	pop	edi
	retn

global roadmenudropdown
roadmenudropdown:
	cmp	word [tramtracks], 0
	jle	.noTramTrackImagery
	push	ebx
	xor	ebx,ebx
	mov	bx, 10h
	movzx	bx, byte [tramtracksprites+ebx]
	add	bx, [tramtracks]
	mov	word [saTramConstrWindowElemList+22h], bx
	xor	ebx,ebx
	mov	bx, 11h
	movzx	bx, byte [tramtracksprites+ebx]
	add	bx, [tramtracks]
	mov	word [saTramConstrWindowElemList+2Eh], bx
	xor	ebx,ebx
	mov 	bx, 14h
	movzx	bx, byte [tramtracksprites+ebx]
	add	bx, [tramtracks]
	mov	word [saTramConstrWindowElemList+6Ah], bx
	pop	ebx

.noTramTrackImagery:
	mov	eax,[roadmenuelemlisty2]
	mov	ecx,1h
	add	ecx,1h //add one line to the menu TRAMS!
	imul	ebx,ecx,10
	inc	ebx
	mov	[eax],bx
	inc	ebx
	shl	ebx,16
	ret

//---------------------What follows next?------------------
//the code to produce the new tram toolbar.
global saTramConstrWindowElemList
saTramConstrWindowElemList:
    db cWinElemTextBox,cColorSchemeDarkGreen
    dw 0,10,0,13,0x00C5;12
    db cWinElemTitleBar,cColorSchemeDarkGreen
    dw 11, 283, 0, 13, ourtext(txtetramwindowheader);24
    db cWinElemSpriteBox,cColorSchemeDarkGreen  ;builtrack NWSE
    dw 0,21,14,35,1309;36
    db cWinElemSpriteBox,cColorSchemeDarkGreen  ;buildtrack SWNE
    dw 22,43,14,35,1310  ;48                  ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;DYNAMITE
    dw 44,65,14,35,703      ;60                    ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;down landscape
    dw 66,87,14,35,695 ;72
    db cWinElemSpriteBox,cColorSchemeDarkGreen  ;up landscape
    dw 88,109,14,35,694    ;84                       ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen  ;depot
    dw 110,131,14,35,1295     ;96                   ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;busstop
    dw 132,153,14,35,749       ;108                   ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;truckstop
    dw 154,175,14,35,750  
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;bridge
    dw 176,217,14,35,2594                         ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;tunnel
    dw 218,239,14,35,2429                         ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;bulldoze
    dw 240,261,14,35,714                          ; sprite
    db cWinElemSpriteBox,cColorSchemeDarkGreen ;sign
    dw 262,283,14,35,4791                         ; sprite
    db cWinElemLast
//-------------------------end tram toolbar-------------------------------------------------------

global setTramXPieceTool
setTramXPieceTool:
	cmp	word [tramtracks], 0
	jle	.moveRoadToolIn
	cmp	byte [editTramMode], 1
	jne	.moveRoadToolIn
	mov	ebx, 13h
	movzx	bx, byte [tramtracksprites+ebx]
	add	bx, [tramtracks]
	jmp	.leaveTramToolIn
.moveRoadToolIn:
	mov	ebx, 1312
.leaveTramToolIn:
	mov	al, 1
	retn

global setTramYPieceTool
setTramYPieceTool:
	cmp	word [tramtracks], 0
	jle	.moveRoadToolIn
	cmp	byte [editTramMode], 1
	jne	.moveRoadToolIn
	mov	ebx, 12h
	movzx	bx, byte [tramtracksprites+ebx]
	add	bx, [tramtracks]
	jmp	.leaveTramToolIn
.moveRoadToolIn:
	mov	ebx, 1311
.leaveTramToolIn:
	mov	al, 1
	retn

global updateBridgeData1
updateBridgeData1:
	call	near $
ovar .origfn, -4, $, updateBridgeData1
	cmp	dh,0
	jne	.dontDoAnything
	mov	dh, [landscape3+esi*2]
.dontDoAnything:
	movzx	ebx, byte [bTempNewBridgeDirection]
	retn

global updateBridgeData2
updateBridgeData2:
	call	near $
ovar .origfn, -4, $, updateBridgeData2
	cmp	dh,0
	jne	.dontDoAnything
	mov	dh, [landscape3+esi*2]
.dontDoAnything:
	movzx	ebx, byte [bTempNewBridgeDirection]
	retn

global checkIfThisShouldBeATramStop
checkIfThisShouldBeATramStop:
	cmp	byte [editTramMode], 1
	jne	.dontSetTramStopFlag
	bts	word [landscape3+edi*2],4
	jmp	short .skipOldLoadingOfL3
.dontSetTramStopFlag:
	mov	word [landscape3+edi*2], 0
.skipOldLoadingOfL3:
	retn

global dontForgetTramCrossingsRail
dontForgetTramCrossingsRail:
	and     byte [landscape4(bx)], 0Fh
	or      byte [landscape4(bx)], 10h
	or      byte [landscape5(bx)], dh
	
	//cmp	byte [landscape3+ebx*2], 0
	//je	.weDontCare
	//shift a bit into L3 somewhere...
	
	mov	byte [landscape3+ebx*2], 0

.weDontCare:
	retn

global dontForgetTramCrossingsRoad
dontForgetTramCrossingsRoad:
	and	byte [landscape4(si)], 0Fh
	or	byte [landscape4(si)], 20h
	mov	byte [landscape5(si)], dl
	movzx	esi, si
	cmp	byte [editTramMode], 0
	je	.dontDoTramStuff
	bts	word [landscape3+esi*2],12

	//check for ONLY trams
	//cmp	byte [OLYTRAMS], 0
	//jne	.dontDoTramStuff
	//bts	word [landscape3+esi*2],13

.dontDoTramStuff:
	retn

global drawTramTracksLevelCrossing
drawTramTracksLevelCrossing:
	push	ebx
	xor	ebx,ebx
	mov	bx, word [landscape3+esi*2]
	and	bx, 800h
	cmp	bx, 800h
	pop	ebx
	jnz	.returnToDraw

	push	ebx
	xor	ebx,ebx
	mov	bl, 05h
	movzx	bx, [trambackpolesprites+ebx]
	add	bx, [tramtracks]
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
	pop	ebx

.returnToDraw:
	mov	si, [landscape3+esi*2]
	retn

global insertTramDepotFlag
insertTramDepotFlag:
	mov	byte [landscape5(di)], bh
	mov	word [esi+depot.XY], di
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	.dontSetTramFlag
	cmp	byte [editTramMode], 1
	jne	.dontSetTramFlag
	push	edi
	movzx	edi, di
	mov	byte [landscape3+edi*2], 1
	pop	edi
.dontSetTramFlag:
	retn

global drawTramOrRoadDepot
drawTramOrRoadDepot:
	push	ebx
	push	esi
	mov	esi, dword [Class2LandPointer]
	xor	ebx, ebx
	mov	bl, byte [landscape3+esi*2]
	and	bl, 01h
	cmp	bl, 01h
	pop	esi
	pop	ebx
	jne	.dontDrawTramDepot
	sub	bx, 054Fh
	add	bx, [tramtracks]
.dontDrawTramDepot:
	mov     dh, 14h
.finishDrawing:
	call    [addsprite]
	retn


