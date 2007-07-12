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
#include <flags.inc>
#include <newvehdata.inc>
#include <textdef.inc>
#include <misc.inc>
#include <vehtype.inc>
#include <bitvars.inc>

extern	RefreshWindows,  gettileinfo, gettileinfoshort, addsprite, addgroundsprite
extern	newvehdata, invalidatetile, demolishroadflag, checkroadremovalconditions
extern	rvcheckovertake, CreateWindow, txteroadmenu, getroutemap, displbridgeendsprite, CreateWindowRelative
extern	patchflags, gettunnelotherend, DestroyWindow

extern	CloseWindow, RefreshWindowArea, findroadvehicledepot

extern paStationbusstop1, paStationbusstop2, paStationtruckstop1, paStationtruckstop2

extern bridgedrawrailunder, displayfoundation

extern addrailfence1,addrailfence2,addrailfence3,addrailfence4,addrailfence5,addrailfence6,addrailfence7,addrailfence8

extern miscmodsflags

uvard	tramVehPtr,1,s
uvard	RVMovementArrayPtr
uvarw	tramtracks,1,s
uvard	Class0DrawLand, 1, s
uvard	roadtoolbarelemlisty2
uvard	oldClass2DrawLand,1,s
uvard	oldRoadTile,1,s
uvard	Class5LandPointer,1,s
uvard	Class2LandPointer,1,s
uvard	Class9LandPointer,1,s
uvard	stdRoadElemListPtr,1,s
uvarb	editTramMode
uvarb	curTileMap
uvarb	tmpSpriteOffset
uvarb	townIsExpanding
uvard	bTempNewBridgeDirection
uvard	tramTracksSWNE
uvard	tramTracksNWSE
uvard	paRoadConstrWinClickProcs,1,s
uvard	paRoadDepotSpriteTable
uvarw	tmpDI,1,s
var	numtramtracks, dd 107
//var   tramfrontwiresprites,   db 0h, 37h, 37h, 3Fh, 37h, 37h, 43h, 37h, 37h, 3Fh, 37h, 37h, 3Fh, 37h, 37h, 37h
var     tramfrontwiresprites,   db 0h, 54h, 55h, 5Bh, 54h, 54h, 5Eh, 5Ah, 55h, 5Ch, 55h, 58h, 5Dh, 57h, 59h, 56h
var	trambackpolesprites,	db 0h, 38h, 39h, 40h, 38h, 38h, 43h, 3Eh, 39h, 41h, 39h, 3Ch, 42h, 3Bh, 3Dh, 3Ah
var	tramtracksprites,	db 0h, 16h, 15h, 0Bh, 14h, 04h, 0Eh, 09h, 13h, 0Ch, 05h, 08h, 0Dh, 07h, 0Ah, 06h, 00h, 01h, 02h, 03h, 30h
var	tramMovement,		db 0h, 02h, 01h, 10h, 02h, 02h, 08h, 1Ah, 01h, 04h, 01h, 15h, 20h, 26h, 29h, 3Fh
uvarw	removeamount,1,s
uvard	busstationwindow,1,s
uvarw	oldbusstoptext,1,s
uvard	busdepotwindow,1,s
uvarw	oldbusdepottext,1,s
uvard	buildtruckstopfunction,1,s
uvard	buildtruckstopprocarea,1,s
uvard	checkdepot3jump,1,s
uvard	checkdepot4jump,1,s
uvard	checkdepot5jump,1,s
uvard	checkdepot3return,1,s
uvard	checkdepot4return,1,s
uvard	checkdepot5return,1,s

//this is 'added' onto the end of the ttdstation sprite lists....
vard 	paStationtramstop,	paStationbusstop1,paStationbusstop2,paStationtramstop1,paStationtramstop2,paStationtruckstop1,paStationtruckstop2,paStationtramfreightstop1,paStationtramfreightstop2		//0x5A

var paStationtramstop1
	dd 1314
	db 0,0,0,16,16,0
	dd 4079
	db 3,3,7,2,2,3
	dd 4079
	db 0,0,0,24,2,16
	dd 4079
	db 0,0,0,24,16,16
	dd 4079
	db 80h

var paStationtramstop2
	dd 1313
	db 0,0,0,16,16,0
	dd 4079
	db 3,3,7,2,2,3
	dd 4079
	db 0,0,0,24,2,16
	dd 4079	//unknown
	db 0,0,0,24,16,16
	dd 4079 //unknown
	db 80h

var paStationtramfreightstop1
	dd 1314
	db 0,0,0,16,16,0
	dd 4079
	db 3,3,7,2,2,3
	dd 4079
	db 0,0,0,24,2,16
	dd 4079
	db 0,0,0,24,16,16
	dd 1407
	db 6,14,10,1,2,8
	dd 4300
	db 14,14,10,1,2,8
	dd 4079
	db 80h

var paStationtramfreightstop2
	dd 1313
	db 0,0,0,16,16,0
	dd 4079
	db 3,3,7,2,2,3
	dd 4079
	db 0,0,0,24,2,16
	dd 4079
	db 0,0,0,24,16,16
	dd 1407
	db 0,8,4,1,2,8
	dd 4300
	db 0,4,4,1,2,8
	dd 4079
	db 80h

uvard roadmenuelemlisty2

global setTramPtrWhilstRVProcessing
setTramPtrWhilstRVProcessing:
	mov	dword [tramVehPtr], esi
	call	near $
ovar .origfn, -4, $, setTramPtrWhilstRVProcessing
	mov	dword [tramVehPtr], -1
	retn

global setTownIsExpandingFlag
setTownIsExpandingFlag:
	mov	ax, 2
	mov	byte [townIsExpanding], 1
	call	[getroutemap]
	mov	byte [townIsExpanding], 0
	retn

global Class2RouteMapHandlerChunk1
Class2RouteMapHandlerChunk1:
	cmp	dword [tramVehPtr], 0FFFFFFFFh
	je	.checkNormalRoads
	push	esi
	push	edx
	mov	esi, [tramVehPtr]
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
	pop	esi
	jz	.checkNormalRoads
	cmp	byte [townIsExpanding], 1
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
	call	[gettileinfo]			//the original call
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl		//check that we are player 1
	pop	bx
	jne	.dontLoadTramArray
	cmp	byte [editTramMode], 0		//are we building trams?
	jz	.dontLoadTramArray
	push	dx
	and	dh, 10h
	cmp	dh, 10h
	pop	dx
	je	.levelCrossing			//we have a level crossing
	cmp	bl, 08h				//this is rail we are trying to apply trams to!
	je	.levelCrossing			//we have a level crossing

	test	byte [landscape5(si)], 20h	//DEPOT! skip... this fixed $4mil bug
	jne	.dontLoadTramArray

	cmp	bl, 0x48		//check if it's a bridge and DON'T insert tram tracks
	je	.dontLoadTramArray

	mov	byte dh, [landscape3+esi*2]	//move in tram track data...

.levelCrossing:
	;bleh... do something if we're placing tram tracks on a level crossing here
	;see 00148761 and hack to move the tram bits to the correct spot.
	;actually... just let this go and then patch later after it's converted the tile to a rail crossing.

.dontLoadTramArray:
	cmp	bl, 10h
	retn

global tramLevelCrossing
tramLevelCrossing:
	;placeholder number 2... somewhere here we need to work out if we're working on trams and then shift
	;in the correct tram bits depending on whether road exists or not....
	;start with just tram bits and screw 'just road crossings'
	mov	word [landscape3+esi*2], dx
	retn

global insertTramTrackIntoRemove
insertTramTrackIntoRemove:
	call	[gettileinfo]			;get the standard tile info
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl		;check if we're player one
	pop	bx
	jne	.dontLoadTramArray
	cmp	byte [demolishroadflag],1	;are we dynamiting? or removing?
	je	.dontLoadTramArray		;if we're dynamiting, then just continue, all gets removed
	cmp	byte [editTramMode], 0		;removing... trams or roads?
	jz	.dontLoadTramArray
	mov	byte dh, [landscape3+esi*2]	;trams... move in the current tram tracks
.dontLoadTramArray:
	cmp	bl, 48h				;original code.
	retn

global newSendVehicleToDepot
newSendVehicleToDepot:
	mov	dword [tramVehPtr], esi
	call	[findroadvehicledepot]
	mov	edx, ebx
	mov	dword [tramVehPtr], 0FFFFFFFFh
	retn

;called by the 'system' as opposed to a user request.
global newSendVehicleToDepotAuto
newSendVehicleToDepotAuto:
	mov	dword [tramVehPtr], esi
	call	[findroadvehicledepot]
	or	ebx, ebx
	mov	dword [tramVehPtr], 0FFFFFFFFh
	retn

global shiftTramBytesIntoL5
shiftTramBytesIntoL5:
	push	bx
	xor	bx, bx
	mov	bl, byte [human1]
	cmp	byte [curplayer], bl
	pop	bx
	jne	near .dontMakeTramTracks
	cmp	byte [editTramMode], 0
	je	near .dontMakeTramTracks
	or	byte [landscape3+esi*2], bh		;this is where the tram tracks are stored
	//now lets check if we are next to a bridge
	jmp	short .dontMakeRoads

.dontMakeTramTracks:
	or	byte [landscape5(si)], bh		;this is where the roads are stored.

.dontMakeRoads:
	call	invalidateBridgeIfExists		;this should be called on both circumstances
	mov	byte [landscape2+esi], 0		;original code.
	retn


global attemptRemoveTramTracks
attemptRemoveTramTracks:
	call	invalidateBridgeIfExists
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

uvarb	temproadmap, 1,s
global DrawTramTracks
DrawTramTracks:
	call	near $
ovar .origfn, -4, $, DrawTramTracks

	push	ax
	xor	ax, ax
	mov	al, byte [landscape5(si)]
	mov	byte [temproadmap], al
	mov 	al, byte [landscape4(si)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	je	.continueAfterCBH
.workWithCustomBridgeHeads:
	push	edx
	movzx	edx, word [landscape3+esi*2]
	shr	edx, 0x08
	and 	edx, 0x0f
	mov	byte [curTileMap], dl
	xor	edx, edx
	movzx	edx, word [landscape3+esi*2]
	shr	edx, 0x04
	and 	edx, 0x0f
	mov	byte [temproadmap], dl
	pop	edx
.continueAfterCBH:
	cmp	word [tramtracks], 0
	jle	near .noTramTrackImagery

	pushad
	mov	word [tmpDI], di
.skipDrawingRoads:
	test	byte [curTileMap], 1111b   //check for tram tracks...
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
	cmp	byte [temproadmap], 0
	jnz	.dontAddOffRoadTracks
	add	bx, 17h
	push	eax
	push	ebx
	push	ebp
	push	esi
;    //add rail fences...
	xor	ebx,ebx

	mov	bl, byte [curTileMap]
	and	bl, 1 //NW
	jnz	.checkSW
	call	[addrailfence1]
.checkSW:
	mov	bl, byte [curTileMap]
	and	bl, 2 //SW
	jnz	.checkSE
	call	[addrailfence4]
.checkSE:
	mov	bl, byte [curTileMap]
	and	bl, 4 //SE
	jnz	.checkNE
	call	[addrailfence2]
.checkNE:
	mov	bl, byte [curTileMap]
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
	mov	dh, 2Dh
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

global updateTramStopSpriteLayout
updateTramStopSpriteLayout:
	push	ecx
	xor	ecx,ecx
	mov	cx, 18h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop1+10], ecx
	mov	cx, 1Ah
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop1+20], ecx
	mov	cx, 37h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop1+30], ecx
	mov	cx, 39h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop1+40], ecx
	mov	cx, 17h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop2+10], ecx
	mov	cx, 19h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop2+20], ecx
	mov	cx, 37h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop2+30], ecx
	mov	cx, 38h
	add	cx, word [tramtracks]
	mov	dword [paStationtramstop2+40], ecx
//truck stations
	xor	ecx,ecx
	mov	cx, 05h
	add	cx, word [tramtracks]
	mov	dword [paStationtramfreightstop1+10], ecx
	mov	cx, 37h
	add	cx, word [tramtracks]
	mov	dword [paStationtramfreightstop1+20], ecx
	mov	cx, 39h
	add	cx, word [tramtracks]
	mov	dword [paStationtramfreightstop1+30], ecx
	mov	cx, 04h
	add	cx, word [tramtracks]
	mov	dword [paStationtramfreightstop2+10], ecx
	mov	cx, 37h
	add	cx, word [tramtracks]
	mov	dword [paStationtramfreightstop2+20], ecx
	mov	cx, 38h
	add	cx, word [tramtracks]
	mov	dword [paStationtramfreightstop2+30], ecx
//tram depot window cons
	xor	ecx,ecx
	mov	cx, 35h
	add	cx, word [tramtracks]
	mov	dword [tramdepotorient1+4], ecx
	sub	cx, 3
	mov	dword [tramdepotorient2+12], ecx
	sub	cx, 1
	mov	dword [tramdepotorient2+4], ecx
	add	cx, 3
	mov	dword [tramdepotorient3+12], ecx
	sub	cx, 1
	mov	dword [tramdepotorient3+4], ecx
	add	cx, 3
	mov	dword [tramdepotorient4+4], ecx
	pop	ecx
	retn

global stopTramOvertaking
stopTramOvertaking:
;	cmp	dword [tramVehPtr], 0FFFFFFFFh
;	je	.dontLetTramsOvertake
;	push	esi
	push	edx
;	mov	esi, [tramVehPtr]
	movzx	edx, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+edx], VEHMISCFLAG_RVISTRAM
	pop	edx
;	pop	esi
	jnz	.dontLetTramsOvertake
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	jne	.dontLetTramsOvertake
	jmp	[rvcheckovertake]
.dontLetTramsOvertake:
	retn

uvarb	lastroadmenuselection
global createRoadConstructionWindow
createRoadConstructionWindow:

	cmp	al, 0FFh
	jne	.dontShiftInLastValue
	mov	al, byte [lastroadmenuselection]
.dontShiftInLastValue:
	cmp	al, 1
	jne	near .moveInZero
	mov	byte [editTramMode], 1
	push	edi
	push	ecx
	mov	edi, dword [busstationwindow]
	mov	word [edi], ourtext(txtetramstationheader)
	mov	edi, dword [busdepotwindow]
	mov	word [edi], ourtext(txtetramdepotheader)
;	mov	edi, dword [buildtruckstopprocarea]
;	mov	dword [edi], null_proc
	pop	ecx
	pop	edi
	jmp	.movedInData
.moveInZero:
	mov	byte [editTramMode], 0
	push	eax
	push	edi
	mov	edi, dword [busstationwindow]
	mov	ax, [oldbusstoptext]
	mov	word [edi], ax
	mov	edi, dword [busdepotwindow]
	mov	ax, [oldbusdepottext]
	mov	word [edi], ax
;	mov	edi, dword [buildtruckstopprocarea]
;	mov	eax, dword [buildtruckstopfunction]
;	mov	dword [edi], eax
	pop	edi
	pop	eax
.movedInData:
	mov	byte [lastroadmenuselection], al
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
;	cmp	byte [editTramMode], 1
;	jne	.dontSetTruckStopDisabled
;	mov	dword [esi+window.disabledbuttons], 200h
;.dontSetTruckStopDisabled:
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
	test	byte [displayoptions], 10h
	jne	.notTransparent
	test	byte [miscmodsflags+3], MISCMODS_NOTRANSPARENTDEPOTS>>24
	jne	.notTransparent
	and	ebx, 3FFFh
	or	ebx, 3224000h
.notTransparent:
	call    [addsprite]
	retn

global storeArrayPointerFromClass9
storeArrayPointerFromClass9:
	mov	dword [Class9LandPointer], ebx
	mov	bx, word [landscape3+ebx*2]
	retn

//------------------------------------------------------
//NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE!!!!:
//------------------------------------------------------
// Disclaimer, the following functions are U__G_L_Y!
// Due to my lack of assembler knowledge, my class (L4 upper bits)
//  checking chunk of code is large..ish... and then the fact that
// i need to use this a lot means that the next section of functions
// are bloated and disgusting... but they work.
//	the basic idea is that i check adjacent tiles for tram tracks
//	and the lack of road to know exactly what tiles to draw.
//	this is for bridges, tunnels, etc...
//	i hope you can follow, whoever you are, that has to... :P
//------------------------------------------------------
uvarw	tmpXY
global drawTramTracksInTunnel
drawTramTracksInTunnel:
	push	ebx
	call	[addgroundsprite]
	pop	ebx
	push	ebx
	//----------------------------Marcin rox!--------------------------
	//L5 bits 7..4 clear: tunnel entrance/exit
	//	* L5 bits 3..2: 0 - railway tunnel, 1 - road tunnel
	//	* L5 bits 1..0 - direction: entrance towards: 0 = NE, 1 = SE, 2 = SW, 3 = NW
	//	* L1: owner of the tunnel
	//	* L3 bits 3..0 = track type for railway tunnel, must be 0 for road tunnel
	//	* L3 bit 15 set = on snow or desert
	//-----------------------------------------------------------------

	push	ecx
	push	edi
	xor	ecx, ecx

	mov	edi, dword [Class9LandPointer]
	mov	cl, byte [landscape5(di)]
	and	cl, 1100b
	cmp	cl, 0100b
	jne	near .notRoad

	mov	word [tmpXY], di

	//draw TRAMMIETRAKKIES!
	xor	ebx, ebx
	//we need to work out the direction of the tunnel:
	mov	cl, byte [landscape5(di)]
	and	cl, 0Fh

	cmp	cl, 4h //check for NE
	jne	near .checkDirSE
	mov	bx, 05h
	mov	byte [tmpSpriteOffset], 50h
	//check if we have tram tracks at DI
.iterateNE:
	cmp	di, word [tmpXY]
	jl	near .notRoad
	add	di, 1h
	mov	word [tmpXY], di
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x90
	je	.checkbridgNE
	cmp	cl, 0x50
	je	.iterateNE
	cmp	cl, 0x20
	jne	near .notRoad
	mov 	cl, byte [landscape3+edi*2]
	and	cl, 0x08
	cmp	cl, 0x08
	jne	near .notRoad
	mov 	cl, byte [landscape5(di)]
	test	cl, 16
	jnz	near .notRoad
	and	cl, 0x08
	cmp	cl, 0x08
	je	near .dirChanged
	mov	bx, 1Ch
	jmp	.dirChanged
.checkbridgNE:
	test	byte [landscape5(di)], 80h
	jnz	.iterateNE
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	jmp	.iterateNE
.checkDirSE:
	cmp	cl, 5h
	jne	near .checkDirSW
	mov	bx, 4Ch
	mov	byte [tmpSpriteOffset], 51h
.iterateSE:
	cmp	di, word [tmpXY]
	jg	near .notRoad
	sub	di, 100h				//loop starts
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x90
	je	.checkbridgSE				//Tunnel? YES \/
	cmp	cl, 0x50
	je	.iterateSE
	cmp	cl, 0x20
	jne	near .notRoad
	mov 	cl, byte [landscape3+edi*2]
	and	cl, 0x04
	cmp	cl, 0x04
	jne	near .notRoad
	mov 	cl, byte [landscape5(di)]
	test	cl, 16
	jnz	near .notRoad
	and	cl, 0x04
	cmp	cl, 0x04
	je	near .dirChanged
	mov	bx, 4Eh
	jmp	.dirChanged
.checkbridgSE:
	test	byte [landscape5(di)], 80h
	jnz	.iterateSE
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	jmp	.iterateSE				//LOOPING! ^^ //must be getting the WRONG tile....
.checkDirSW:
	cmp	cl, 6h
	jne	.checkDirNW
	mov	bx, 4Dh
	mov	byte [tmpSpriteOffset], 52h
.iterateSW:
	cmp	di, word [tmpXY]
	jg	near .notRoad
	sub	di, 1h
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x90
	je	.checkbridgSW
	cmp	cl, 0x50
	je	.iterateSW
	cmp	cl, 0x20
	jne	near .notRoad
	mov 	cl, byte [landscape3+edi*2]
	and	cl, 0x02
	cmp	cl, 0x02
	jne	near .notRoad
	mov 	cl, byte [landscape5(di)]
	test	cl, 16
	jnz	near .notRoad
	and	cl, 0x02
	cmp	cl, 0x02
	je	near .dirChanged
	mov	bx, 4Fh
	jmp	.dirChanged
.checkbridgSW:
	test	byte [landscape5(di)], 80h
	jnz	.iterateSW
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	jmp	.iterateSW
.checkDirNW:
	//NORTH WEST
	mov	bx, 04h //offset of image in GRF
	mov	byte [tmpSpriteOffset], 53h
.iterateNW:
	cmp	di, word [tmpXY]
	jl	near .notRoad
	add	di, 100h
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x90
	je	.checkbridgeNW
	cmp	cl, 0x50
	je	.iterateNW
	cmp	cl, 0x20
	jne	near .notRoad
	mov 	cl, byte [landscape3+edi*2]
	and	cl, 0x01
	cmp	cl, 0x01
	jne	.notRoad
	mov 	cl, byte [landscape5(di)]
	test	cl, 16
	jnz	near .notRoad
	and	cl, 0x01
	cmp	cl, 0x01
	je	.dirChanged
	mov	bx, 1Bh
	jmp	.dirChanged

.checkbridgeNW:
	test	byte [landscape5(di)], 80h
	jnz	.iterateNW
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	jmp	.iterateNW

.dirChanged:
	pop	edi
	pop	ecx
	push	ebx
	add	bx, [tramtracks]
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	call	[addsprite]
	pop	ebx

	mov	bx, [tmpSpriteOffset]
	add	bx, [tramtracks]
	mov	di, 0Fh
	mov	si, 0Fh
	mov	dh, 08h
	call	[addsprite]
	//meh.. disregard the following.. it was written before the above was.
	//HOLD THE PHONE!!!
	//do we have road/tram/road+tram at the entrance/exit this tunnel?
	//maybe we should check for the existence of a connecting road piece to draw road underneath,
	//or if there is ONLY tram, then draw the lightrail tracks?
	//DEFAULT: ROAD

	//how the hell do I know which way to check?

	jmp	.endOfProc
.notRoad:
	pop	edi
	pop	ecx
.endOfProc:
	pop	ebx
	retn

global storeClass9LandPointerAgain
storeClass9LandPointerAgain:
	mov	dword [Class9LandPointer], ebx
	mov	bl, byte [landscape2+ebx]
	retn

global drawTramTracksUnderBridge
drawTramTracksUnderBridge:
	testmultiflags higherbridges
	jz	.dontworryabouthigherbridges
	call	bridgedrawrailunder
	jmp	.justDoTheSHR
.dontworryabouthigherbridges:
	//original code
	call	[addgroundsprite]
.justDoTheSHR:
	shr	esi, 1
	//---------------

	push	ecx
	push	edi
	xor	ecx, ecx

	mov	edi, dword [Class9LandPointer]
	mov	ecx, dword [landscape5(di)]
	test	cl, 0x08
	pop	edi
	pop	ecx
	jz	near .notRoad

	push	ecx
	push	edi
	push	eax

	//draw tram tracks? draw roads? draw both?
	//work out direction
	xor	ebx,ebx
	mov	edi, dword [Class9LandPointer]
	mov	cx, word [landscape5(di)]
	test	cl, 1
	jz	near .bridgeXdir
	//bridge is in the Y direction... test on either X direction
	add	di, 1h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jne	.changeYDir
	test	byte [landscape3 + edi * 2], 8h
	jz	.changeYDir
	test	byte [landscape5(di)], 8h
	mov	ebx, 05h
	jnz	near .moveOnNothingToSeeHere
	sub	di, 2h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	mov	ebx, 1Ch
	jne	near .moveOnNothingToSeeHere
	test	byte [landscape5(di)], 2h
	mov	ebx, 05h
	jnz	near .moveOnNothingToSeeHere
	mov	ebx, 1Ch
	jmp	.moveOnNothingToSeeHere

.changeYDir:
	sub	di, 2h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jne	near .cleanandexit
	test	byte [landscape3 + edi * 2], 2h
	jz	near .cleanandexit
	test	byte [landscape5(di)], 2h
	mov	ebx, 05h
	jnz	near .moveOnNothingToSeeHere
	add	di, 2h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	mov	ebx, 1Ch
	jne	near .moveOnNothingToSeeHere
	test	byte [landscape5(di)], 8h
	mov	ebx, 05h
	jnz	near .moveOnNothingToSeeHere
	mov	ebx, 1Ch
	jmp	.moveOnNothingToSeeHere

.bridgeXdir:
	add	di, 100h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jne	.changeXDir
	test	byte [landscape3 + edi * 2], 1h
	jz	.changeXDir
	test	byte [landscape5(di)], 1h
	mov	bx, 04h
	jnz	near .moveOnNothingToSeeHere
	sub	di, 200h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	mov	bx, 1Bh
	jne	near .moveOnNothingToSeeHere
	test	byte [landscape5(di)], 4h
	mov	ebx, 04h
	jnz	.moveOnNothingToSeeHere
	mov	ebx, 1Bh
	jmp	.moveOnNothingToSeeHere

.changeXDir:
	sub	di, 200h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jne	near .cleanandexit
	test	byte [landscape3 + edi * 2], 4h
	jz	.cleanandexit
	test	byte [landscape5(di)], 4h
	mov	ebx, 04h
	jnz	.moveOnNothingToSeeHere
	add	di, 200h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	mov	ebx, 1Bh
	jne	near .moveOnNothingToSeeHere
	test	byte [landscape5(di)], 1h
	mov	ebx, 04h
	jnz	.moveOnNothingToSeeHere
	mov	ebx, 1Bh

.moveOnNothingToSeeHere:
	pop	eax
	pop	edi
	pop	ecx
	pushad
	test	di, di
	jz	.flat
	add	dl, 08
.flat:
	mov	di, 6h
	mov	si, 6h
	mov	dh, 1h
	add	bx, [tramtracks]
	call	[addsprite]
	popad
	jmp	.notRoad

.cleanandexit:
	pop	eax
	pop	edi
	pop	ecx

.notRoad:
	retn

var	tracktocheck,		dw 0x0001, 0xFF00, 0xFFFF, 0x0100
var	moveback,		dw 0xFFFF, 0x0100, 0x0001, 0xFF00
var	bridgetracks,		db 0Fh,    10h,    11h,    12h
var	trambridgecatenary,	db 67h,    6Ah,    68h,    69h
var	trackshouldbe,		db 08h,    04h,    02h,    01h
var	justtracks,		db 6Dh,    6Eh,    6Fh,    70h
var	flatentry,		db 05h,    04h,    05h,    04h
var	flatentrytrks,		db 6Ch,    6Bh,    6Ch,    6Bh
var	trambridgecatenaryflt,	db 62h,    61h,    62h,    61h

global drawNormalSlopeAndAddTrams
drawNormalSlopeAndAddTrams:
	testmultiflags buildonslopes
	jz .dontworryaboutbuildonslopes
	pushad
	call	displbridgeendsprite
	popad
	jmp	.skipshiz
.dontworryaboutbuildonslopes:
	call	[addgroundsprite]
.skipshiz:
	pushad
	mov	word [removeamount], 04h			//offset in grf for 2nd part of wires
	mov	edi, dword [Class9LandPointer]
	push	ecx
	mov	ecx, dword [landscape5(di)]
	test	cl, 2
	jnz	.thisisroad
	pop	ecx
	popad
	retn
.thisisroad:
	mov	word [tmpXY], di
	mov	ebx, 02h
	test	ecx, 1
	jz	.xdir
	test	ecx, 32
	jz	.notnorth
	mov	ebx, 03h
	jmp	.gotebx
.notnorth:
	mov	ebx, 01h
.xdir:
	test	ecx, 32
	jz	.gotebx
	mov	ebx, 00h
.gotebx:
	push	edi
.playitagainsam:
	cmp	word [tracktocheck+ebx*2], 0h
	jg	.testIfLesser
	cmp	di, word [tmpXY]
	jle	.continuethisstuff
	pop	edi
	pop	ecx
	popad
	retn
.testIfLesser:
	cmp	di, word [tmpXY]
	jge	.continuethisstuff
	pop	edi
	pop	ecx
	popad
	retn
.continuethisstuff:
	add	di, word [tracktocheck+ebx*2]
	push	cx
	xor	ecx,ecx
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x20
	pop	cx
	jz	.checkLevelCrossing
	push	cx
	xor	ecx,ecx
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x50
	pop	cx
	jz	.playitagainsam
	push	cx
	xor	ecx,ecx
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x90
	pop	cx
	jz	.checkfortunnel
	jmp	.dontdraw

.checkLevelCrossing:
	test	dword [landscape5(di)], 16		//skip level crossings.
	jne	near .dontdraw				//these have been causing big issues.
	jmp	.nextbit

.checkfortunnel:
	test	byte [landscape5(di)], 80h
	jnz	.playitagainsam
	test	byte [landscape5(di)], 12
	jz	.playitagainsam				// not road tunnel
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	jmp	.playitagainsam

.nextbit:
	mov	ecx, dword [landscape3+edi*2]
	test	cl, [trackshouldbe+ebx]
	jz	near .dontdraw

	mov	ecx, dword [landscape5(di)]
	test	cl, [trackshouldbe+ebx]
	pop	edi
	pop	ecx
	push	ebx
	jz	.changestyle
	pushad
	xchg	esi, edi
	call	[gettileinfoshort]
	cmp	di, 07h
	jz	.nuttinone
	cmp	di, 0Bh
	jz	.nuttinone
	cmp	di, 0Dh
	jz	.nuttinone
	cmp	di, 0Eh
	jz	.nuttinone
	or	di, di
	jnz	.slopes
.nuttinone:
	popad
	movzx	bx, [bridgetracks+ebx]
	jmp	.continuedrawing
.slopes:
	popad
	mov	word [removeamount], 02h  //straight pieces only 2 dirs, so poles/wires are only 2 tiles away
	add	dl, 8
	movzx	bx, [flatentry+ebx]
	jmp	.continuedrawing
.changestyle:
	pushad
	xchg	esi, edi
	call	[gettileinfoshort]
	cmp	di, 07h
	jz	.nuttin
	cmp	di, 0Bh
	jz	.nuttin
	cmp	di, 0Dh
	jz	.nuttin
	cmp	di, 0Eh
	jz	.nuttin
	or	di, di
	jnz	.slopes2
.nuttin:
	popad
	movzx	bx, [justtracks+ebx]
	jmp	.continuedrawing
.slopes2:
	popad
	mov	word [removeamount], 02h
	add	dl, 8
	movzx	bx, [flatentrytrks+ebx]

.continuedrawing:
	push	edi
	add	bx, [tramtracks]
	mov	di, 04h
	mov	si, 04h
	mov	dh, 03h
	push	esi
	call	[addsprite]
	pop	esi
	pop	edi
	pop	ebx

	pushad
	xchg	esi, edi
	call	[gettileinfoshort]
	cmp	di, 07h
	jz	.nuttinone2
	cmp	di, 0Bh
	jz	.nuttinone2
	cmp	di, 0Dh
	jz	.nuttinone2
	cmp	di, 0Eh
	jz	.nuttinone2
	or	di, di
	jnz	.slopes3
.nuttinone2:
	popad
	jnz	.slopes3
	movzx	ebx, byte [trambridgecatenary+ebx]
	jmp	.skips
.slopes3:
	popad
	movzx	ebx, byte [trambridgecatenaryflt+ebx]
.skips:
	push	ebx
	add	bx, [tramtracks]
	mov	di, 10h
	mov	si, 1Fh
	mov	dh, 20h
	call	[addsprite]
	pop	ebx
	sub	bx, word [removeamount]
	add	bx, [tramtracks]
	mov	di, 6h
	mov	si, 6h
	mov	dh, 5h
	call	[addsprite]
	jmp	.skippopedi
.dontdraw:
	pop	edi
	pop	ecx
.skippopedi:
	popad
	retn

var	bridgemidtrack,	db 04h, 05h
var	bridgetrackonly,db 6Bh, 6Ch
var	bridgecatenary,	db 61h, 62h
var	bridgeposts,	db 5Fh, 60h
var	midshouldbe,	db 01h, 08h
global drawTramBridgeMiddlePart
drawTramBridgeMiddlePart:
	//ok, the idea is to grab the class9landpointer and iterate positively along the bridge till we find a
	//class 9 bit 6 (bridge ending)...then shift one more tile along and check if it has tram tracks...
	//i just realised we might have to do this in both directions.
	pushad
	xor	esi, esi
	xor	ebx, ebx
	mov	edi, dword [Class9LandPointer]
	push	ecx
	push	eax
	mov	ecx, dword [landscape5(di)]
	test	cl, 2
	jz	near .cleanup
	test	cl, 1
	jz	.otherdirection
	mov	esi, 00h
	mov	eax, 0100h
	jmp	.setoffset
.otherdirection:
	mov	esi, 01h
	mov	eax, 0001h
.setoffset:
	//RIGHT HERE...!! TEST FOR CUSTOM BRIDGEHEAD
	//IF bridge head
	push	ax
	mov	ax, word [landscape3+2*edi]
	and	ax, 0FA0h
	cmp	ax, 0
	pop	ax
	je	.notacustombridgehead
	xor	ecx, ecx
	movzx	ecx,word [landscape3+edi*2]
	shr	ecx,8		//check for trams
	and	ecx,0x0f
	test	cl, byte [midshouldbe+esi]
	jz	near .cleanup
	xor	ecx, ecx
	movzx	ecx,word [landscape3+edi*2]
	shr	ecx,4		//check for roads
	and	ecx,0x0f
	test	cl, byte [midshouldbe+esi]
	jz	.changestyledir
	mov	bl, [bridgemidtrack+esi]
	jmp	.continueonafterpopping
.changestyledir:
	mov	bl, [bridgetrackonly+esi]
.continueonafterpopping:
	pop	eax
	pop	ecx
	jmp	.draw
.notacustombridgehead:
	add	edi, eax
	push	cx
	xor	ecx,ecx
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x90
	pop	cx
	jz	.checkfortunnel
	push	cx
	xor	ecx,ecx
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x50
	pop	cx
	jnz	.checkNext
	//check for road station
	cmp 	byte [landscape5(di)], 0x43	//first of original bus stops
	jl	.checkNext
	cmp 	byte [landscape5(di)], 0x4A	//last of original truck stops (which are directly after bus stops)
	jle	.setoffset
	cmp 	byte [landscape5(di)], 0x53	//first of new tram stops
	jl	.checkNext
	cmp 	byte [landscape5(di)], 0x5A	//last of new tramfreight stops
	jle	.setoffset

.checkNext:
	push	cx
	xor	ecx,ecx
	mov 	cl, byte [landscape4(di)]
	and	cl, 0xF0
	cmp	cl, 0x20
	pop	cx
	jnz	near .cleanup

	push	ecx
	mov	ecx, dword [landscape5(di)]
	test	cl, byte [midshouldbe+esi]
	pop	ecx
	jnz	.changestyle
	mov	bl, [bridgetrackonly+esi]
	jmp	.continuedrawing

.checkfortunnel:
	test	byte [landscape5(di)], 80h
	jnz	.setoffset
	mov	word [tmpXY], di
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	cmp	word [tmpXY], di
	jge	near .cleanup
	jmp	.setoffset

.changestyle:
	mov	bl, [bridgemidtrack+esi]

.continuedrawing:
	xor	ecx,ecx
	mov	cl, byte [landscape3+edi*2]
	cmp	ax, 0100h
	jz	.testother
	test	cl, 08h
	jz	.cleanup
	pop	eax
	pop	ecx
	jmp	.draw

.testother:
	test	cl, 01h
	pop	eax
	pop	ecx
	jz	.dontdraw

.draw:
	add	dl, 03h
	pushad
	add	bx, [tramtracks]
	mov	di, 04h
	mov	si, 04h
	mov	dh, 05h
	call	[addsprite]
	popad
	pushad
	mov	bl, byte [bridgeposts+esi]
	add	bx, [tramtracks]
	mov	di, 05h
	mov	si, 05h
	mov	dh, 01h
	call	[addsprite]
	popad
	mov	bl, byte [bridgecatenary+esi]
	add	bx, [tramtracks]
	mov	di, 0Fh
	mov	si, 0Fh
	mov	dh, 07h
	call	[addsprite]
	jmp	.dontdraw


.cleanup:
	pop	eax
	pop	ecx

.dontdraw:
	popad
	mov	si, 0Bh
	test	byte [esp+4], 10h
	retn

//wow.... my own function.
//in: bh, the direction of the road/tram tile being placed.
//out: nothing... but it invalidates a bridge if one exists to update the tram tracks
global invalidateBridgeIfExists
invalidateBridgeIfExists:
	pushad
	cmp	bh, 1
	mov	word [removeamount], 0xFF00
	jz	.continuetestingforbridge
	cmp	bh, 8
	mov	word [removeamount], 0xFFFF
	jz	.continuetestingforbridge
	cmp	bh, 2
	mov	word [removeamount], 1h
	jz	.continuetestingforbridge
	cmp	bh, 4
	cmp	word [removeamount], 0xFF00
	jz	.continuetestingforbridge
	cmp	bh, 5
	mov	word [removeamount], 0xFF00
	jz	.continuetestingforbridge
	mov	word [removeamount], 0xFFFF

.continuetestingforbridge:
	add	si, word [removeamount]
	mov 	al, byte [landscape4(si)]
	push	ax
	and	al, 0xF0
	cmp	al, 0x90
	pop	ax
	jz	.maybetunnel
	push	ax
	and	al, 0xF0
	cmp	al, 0x50
	pop	ax
	jz	.continuetestingforbridge

.wegotone:
	cmp	bh, 5h
	jnz	.checkotherslope
	mov	word [removeamount], 200h
	xor	ebx,ebx
	jmp	.continuetestingforbridge
.checkotherslope:
	cmp	bh, 0Ah
	jnz	near .notabridge
	mov	word [removeamount], 2
	xor	ebx,ebx
	jmp	.continuetestingforbridge

.maybetunnel:
	test	byte [landscape5(si)], 80h
	jnz	.gotcha
	test	byte [landscape5(si)], 4h
	jz	.gotcha
	push	edi
	xor	edi, edi
	mov	edi, esi
	call	gettunnelotherendmystyle		//get the other end preserving everything else BUT EDI
	mov	esi, edi
	pop	edi
	//jmp	.continuetestingforbridge

.gotcha:
	pushad
	xor	eax,eax
	xor	ecx,ecx
	mov	cx,si
	ror	cx, 8
	and	cx,0x00FF
	rol	cx, 4
	mov	ax,si
	and	ax,0x00FF
	rol	ax, 4
	call	[invalidatetile]
	popad
	jmp	.continuetestingforbridge

.singlecheckX:
	add	si, 100h
	jmp	.continuesingle
.singlecheckY:
	add	si, 1h
.continuesingle:
	mov 	al, byte [landscape4(si)]
	and	al, 0xF0
	cmp	al, 0x90
	jnz	.notabridge
	pushad
	xor	eax,eax
	xor	ecx,ecx
	mov	cx,si
	ror	cx, 8
	and	cx,0x00FF
	rol	cx, 4
	mov	ax,si
	and	ax,0x00FF
	rol	ax, 4
	call	[invalidatetile]
	popad
.notabridge:
	popad
	retn

//edi is the landscape XY.
var	bridgeremovaldirections,	db 02h, 02h, 01h, 01h, 05h, 05h, 0Ah, 0Ah, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
global checkIfTramsAndKeepTracksUnder
checkIfTramsAndKeepTracksUnder:
	and     byte [landscape4(di)], 0Fh
	or      byte [landscape4(di)], dh
	mov     byte [landscape5(di)], dl

	//now we need to shift the bytes into L3 (for trams) as well if there are tram tracks around.
	push	ebx
	push	edi
	cmp	al, 04h
	jnz	.otherdirection
	sub	edi, 0100h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	.othersideX
	test	byte [landscape3 + EDI * 2], 4h
	jz	.othersideX
	jmp	.weHaveTramTracks
.othersideX:
	add	edi, 0200h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	near .wehaveroad
	test	byte [landscape3 + EDI * 2], 1h
	jz	near .doNothing
	jmp	.weHaveTramTracks
.otherdirection:
	sub	edi, 01h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	.othersideY
	test	byte [landscape3 + EDI * 2], 2h
	jz	.othersideY
	jmp	.weHaveTramTracks
.othersideY:
	add	edi, 02h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	near .wehaveroad
	test	byte [landscape3 + EDI * 2], 8h
	jz	.doNothing

.weHaveTramTracks:
	pop	edi
	push	edx
	xor	edx,edx
	mov	dl, byte [bridgeremovaldirections+eax]
	mov	byte [landscape3 + EDI * 2], dl
	pop	edx
	jmp	.skipedipop
.doNothing:
	pop	edi
.skipedipop:
	pop	ebx

//now check if we should leave the road there
	push	ebx
	push	edi
	cmp	al, 04h
	jnz	.otherroaddirection
	sub	edi, 0100h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	.otherroadsideX
	test	byte [landscape5(di)], 4h
	jz	.otherroadsideX
	jmp	.wehaveroad
.otherroadsideX:
	add	edi, 0200h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	.trashALtostoproad
	test	byte [landscape5(di)], 1h
	jz	.trashALtostoproad
	jmp	.wehaveroad
.otherroaddirection:
	sub	edi, 01h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	.otherroadsideY
	test	byte [landscape5(di)], 2h
	jz	.otherroadsideY
	jmp	.wehaveroad
.otherroadsideY:
	add	edi, 02h
	push	ax
	mov 	al, byte [landscape4(di)]
	and	al, 0xF0
	cmp	al, 0x20
	pop	ax
	jnz	.trashALtostoproad
	test	byte [landscape5(di)], 8h
	jz	.trashALtostoproad
	jmp	.wehaveroad

.trashALtostoproad:
	pop	edi
	pop	ebx
	and	byte [landscape5(di)], 0F0h
	retn

.wehaveroad:
	pop	edi
	pop	ebx
	retn

//in edi (tunnel entrance)
//out edi tunnel exit
//preserves everything else.

var	dirmapping,	db 01h, 03h, 05h, 07h

global gettunnelotherendmystyle
gettunnelotherendmystyle:
	//original func : tunnelotherendfn
	//; in:  DI = tunnel start XY
	//;      BX = tunnel direction: 1=NE, 3=SE, 5=SW, 7=NW
	//;      SI = tunnel type: 0 = rail, 2 = road
	//; out: DI = other end's XY
	//;      AX = distance to the other end
	//; uses:CX
	push	esi
	push	ecx
	push	ebx
	push	eax
	xor	eax, eax
	mov	al, byte [landscape5(di)]
	xor	ebx, ebx
	and	ax, 3h
	mov	bl, byte [dirmapping+eax]
	mov	si, 2h
	call	[gettunnelotherend]
	pop	eax
	pop	ebx
	pop	ecx
	pop	esi
	retn

global updateDisableStandardRVStops
updateDisableStandardRVStops:
	mov	ebp, 8
	call	[CreateWindowRelative]
	cmp	byte [editTramMode], 1
	jnz	.dontDisableButtons
	mov	dword [esi+window.disabledbuttons], 78h
	retn
.dontDisableButtons:
	mov	dword [esi+window.disabledbuttons], 0h
	retn

global null_proc
null_proc:
	retn

global deSelectNormalBusStops
deSelectNormalBusStops:
	add	bp, 7
	bts	eax, ebp
	cmp	byte [editTramMode], 1
	jnz	.finish
	cmp	byte [buslorrystationorientation], 6
	jge	.finish
	mov	byte [buslorrystationorientation], 6
.finish:
	retn

global checkIfTramDepot1
checkIfTramDepot1:
	push	esi
	movzx	esi, word [esi+window.id]
	cmp	byte [landscape3+esi*2], 1
	pop	esi
	jne	.notATramDepot
.tramdepot:
	movzx	cx, [human1]
	bt	[eax+vehtype.playeravail], cx
	jnb	.notAllowedRightNow
	test	byte [vehmiscflags+ebp], VEHMISCFLAG_RVISTRAM
	jne	.setFlag
.dontSetFlag:
	clc	//wow ... neat trick... we want to reverse the 'is tram' findings!
	retn
.setFlag:
	stc
.notAllowedRightNow:
	retn

.notATramDepot:
	movzx	cx, [human1]
	bt	[eax+vehtype.playeravail], cx
	jnb	.notAllowedRightNow
	test	byte [vehmiscflags+ebp], VEHMISCFLAG_RVISTRAM
	je	.setFlag
	jmp	.dontSetFlag

global checkIfTramDepot2
checkIfTramDepot2:
	push	esi
	movzx	esi, word [esi+window.id]
	cmp	byte [landscape3+esi*2], 1
	pop	esi
	jne	.notATramDepot
.tramdepot:
	bt	[ebx+vehtype.playeravail], cx
	jnb	.justReturn
	push	eax
	xor	eax, eax
	mov	al, ROADVEHBASE + NROADVEHTYPES
	sub	al, dh
	test	byte [vehmiscflags+eax], VEHMISCFLAG_RVISTRAM
	pop	eax
	jnz	.skipNonTram
	clc
	adc	dl, 0
	retn
.skipNonTram:
	stc
	adc	dl, 0
	retn

.notATramDepot:
	bt	[ebx+vehtype.playeravail], cx
	jnb	.justReturn
	push	eax
	xor	eax, eax
	mov	al, ROADVEHBASE + NROADVEHTYPES
	sub	al, dh
	test	byte [vehmiscflags+eax], VEHMISCFLAG_RVISTRAM
	pop	eax
	jnz	.itIsTram
	stc
.justReturn:
	adc	dl, 0
	retn
.itIsTram:
	clc
	adc	dl, 0
	retn

uvard	discard
global checkIfTramDepot3
checkIfTramDepot3:
	pop	dword [discard]
	bt	[eax+vehtype.playeravail], bp
	jnb	.jumpToStoredPointer
	push	esi
	movzx	esi, word [esi+window.id]
	cmp	byte [landscape3+esi*2], 1
	pop	esi
	jne	.jumpToReturn
.tramdepot:
	test	byte [vehmiscflags+ebx], VEHMISCFLAG_RVISTRAM
	jz	.jumpToStoredPointer
	jmp	[checkdepot3return]
.jumpToStoredPointer:
	jmp	[checkdepot3jump]
.jumpToReturn:
	test	byte [vehmiscflags+ebx], VEHMISCFLAG_RVISTRAM
	jnz	.jumpToStoredPointer
	jmp	[checkdepot3return]

global checkIfTramDepot4
checkIfTramDepot4:
	pop	dword [discard]
	bt	[eax+vehtype.playeravail], bp
	jnb	.jumpToStoredPointer
	push	esi
	movzx	esi, word [esi+window.id]
	cmp	byte [landscape3+esi*2], 1
	pop	esi
	jne	.notTramDepot
.tramdepot:
	push	ebx
	and	ebx, 0FFh
	test	byte [vehmiscflags+ebx], VEHMISCFLAG_RVISTRAM
	pop	ebx
	jz	.jumpToStoredPointer
	jmp	[checkdepot4return]
.jumpToStoredPointer:
	jmp	[checkdepot4jump]
.notTramDepot:
	push	ebx
	and	ebx, 0FFh
	test	byte [vehmiscflags+ebx], VEHMISCFLAG_RVISTRAM
	pop	ebx
	jnz	.jumpToStoredPointer
	jmp	[checkdepot4return]


global checkIfTramDepot5
checkIfTramDepot5:
	pop	dword [discard]
	bt	[eax+vehtype.playeravail], bp
	jnb	.jumpToStoredPointer
	push	esi
	movzx	esi, word [esi+window.id]
	cmp	byte [landscape3+esi*2], 1
	pop	esi
	jne	.notTramDepot
.tramdepot:
	test	byte [vehmiscflags+ebx], VEHMISCFLAG_RVISTRAM
	jz	.jumpToStoredPointer
	jmp	[checkdepot5return]
.jumpToStoredPointer:
	jmp	[checkdepot5jump]
.notTramDepot:
	test	byte [vehmiscflags+ebx], VEHMISCFLAG_RVISTRAM
	jnz	.jumpToStoredPointer
	jmp	[checkdepot5return]


;[07:14] <patchman> ok, you need to get the ID
;[07:15] <patchman> at 167879, 116+(88-dh) is the ID, i.e. mov al,116+88; sub al,dh gives the ID in al
;[07:16] <patchman> at 1678D2, the ID is in EBP
;[07:16] <patchman> and at 1679A9 it's in BL
;[07:17] <patchman> in all cases you need to check [vehmiscflags+ID]
;[07:18] <patchman> just like before
;[07:19] <patchman> (btw, that 116 is ROADVEHBASE and 88 is NROADVEHTYPES; might be better to use those as constants)

global resetL3DataToo
resetL3DataToo:
	mov	byte [landscape2 + esi], 0
	and word [nosplit landscape3+esi*2], ~0xFF // Reset the lower byte since thats used for owner of crossings
	retn

global updateRoadMenuSelection
updateRoadMenuSelection:
	push	eax
	movzx	ax, byte [lastroadmenuselection]
	mov	word [esi+window.data+2], ax
	pop	eax
	retn

global checkIfDepotIsTramDepot
checkIfDepotIsTramDepot:
	cmp	dword [tramVehPtr], 0FFFFFFFFh
	je	.isRoadVehicle
	push	esi
	mov	esi, [tramVehPtr]
	movzx	esi, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+esi], VEHMISCFLAG_RVISTRAM
	pop	esi
	jz	.isRoadVehicle
	push	ebx
	add	ebx, edi
	cmp	byte [landscape3 + ebx * 2], 1
	pop	ebx
	je	.normalDepotCheck
	mov	al, 0
	retn
.isRoadVehicle:
	push	ebx
	add	ebx, edi
	cmp	byte [landscape3 + ebx * 2], 0
	pop	ebx
	je	.normalDepotCheck
	mov	al, 0
	retn
.normalDepotCheck:
	push	ebx
	add	ebx, edi
	mov	al, byte [landscape5(bx)]
	pop	ebx
	and	al, 0F0h
	retn

vard paTramDepotSpriteTable, tramdepotorient1, tramdepotorient2, tramdepotorient3, tramdepotorient4
var tramdepotorient1,	dd 2634
			dd 8000h+1412
			db 0, 0Fh, 10h, 1
			dd 0
var tramdepotorient2,	dd 2634
			dd 1408
			db 0, 0, 1, 10h
			dd 8000h+1409
			db 0Fh, 0, 1, 10h
			dd 0
var tramdepotorient3,	dd 2634
			dd 1410
			db 0, 0, 10h, 1
			dd 8000h+1411
			db 0, 0Fh, 10h, 1
			dd 0
var tramdepotorient4,	dd 2634
			dd 8000h+1413
			db 0Fh, 0, 1, 10h
			dd 0

;paRoadDepotSpriteTable is the original

global throwInTramDepots
throwInTramDepots:
	push	eax
	cmp	byte [editTramMode], 0
	jne	.insertTramDepots
	mov	eax, [paRoadDepotSpriteTable]
	jmp	short .continueDrawing
.insertTramDepots:
	mov	eax, paTramDepotSpriteTable
.continueDrawing:
	mov	ebx, [eax+ebx]
	pop	eax
	retn

global updateFirstBusArrivesNewsItem
updateFirstBusArrivesNewsItem:
	push	esi
	movzx	esi, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+esi], VEHMISCFLAG_RVISTRAM
	pop	esi
	jz	.isRoadVehicle
	mov	bx, 0A02h
	mov	dx, ourtext(firstpasstramarrives)
	retn
.isRoadVehicle:
	mov	bx, 0A02h
	mov	dx, 0x902F
	retn

global updateFirstTruckArrivesNewsItem
updateFirstTruckArrivesNewsItem:
	push	esi
	movzx	esi, byte [esi+veh.vehtype]
	test	byte [vehmiscflags+esi], VEHMISCFLAG_RVISTRAM
	pop	esi
	jz	.isRoadVehicle
	mov	bx, 0A02h
	mov	dx, ourtext(firstfreighttramarrives)
	retn
.isRoadVehicle:
	mov	bx, 0A02h
	mov	dx, 0x9030
	retn
