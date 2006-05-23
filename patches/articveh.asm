//----------------------START HEADER--------------------------------
//welcome to the patches of road vehicle articulation
//----------------------END HEADER----------------------------------

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <misc.inc>
#include <vehtype.inc>
#include <window.inc>
#include <station.inc>

extern newbuyrailvehicle, discard, vehcallback, articulatedvehicle, delveharrayentry, sellroadvehicle
extern RefreshWindows, LoadUnloadCargo

uvarb byte_11258E
uvarb vaTempLocation1

uvarw	ParentXY
uvard	ParentIDX

uvard	oldbuyroadvehicle
uvarb	buildingroadvehicle
uvard	oldchoosevehmove
uvard	rvCollisionFoundVehicle
uvard	rvCollisionCurrVehicle
uvard	JumpOutOfRVRVCollision

uvard	RedrawRoadVehicle
uvard	SetRoadVehObjectOffsets
uvard	SelectRVSpriteByLoad
uvard	SetCurrentVehicleBBox
uvard	off_111D62
uvard	byte_112552
uvard	word_11257A
uvard	unk_112582

uvard GenerateFirstRVArrivesMessage
uvard ProcessNextRVOrder
uvard ProcessLoadUnload
uvard IncrementRVMovementFrac
uvard ProcessCrashedRV
;uvard ProcessBrokenDownRV
uvard ChkForRVCollisionWithTrain
uvard RVCheckCollisionWithRV
uvard RVMountainSpeedManagement
uvard LimitTurnToFortyFiveDegrees
uvard VehEnterLeaveTile
uvard RVStartSound
uvard RoadVehiclePathFinder
uvard GetVehicleNewPos
uvard UpdateVehicleSpriteBox
uvard UpdateDirectionIfMovedTooFar


global newbuyroadvehicle
newbuyroadvehicle:
	mov	byte [buildingroadvehicle], 1
	call	newbuyrailvehicle			//this proc knows what to do
							//if [buildingroadvehicle] is set... and it is!
							//see newtrains.asm
	mov	byte [buildingroadvehicle], 0
	retn

global grabMovementFromParentIfTrailer1
grabMovementFromParentIfTrailer1:
	mov	byte [esi+veh.movementstat], bl
	mov	byte [esi+veh.targetairport], 0
	call	shiftInParentMovement
	retn

global grabMovementFromParentIfTrailer2
grabMovementFromParentIfTrailer2:
	mov	byte [esi+veh.movementstat], bl
	mov	byte [esi+veh.targetairport], 1
	call	shiftInParentMovement
	retn

global grabMovementFromParentIfTrailer3
grabMovementFromParentIfTrailer3:
	mov	byte [esi+veh.movementstat], bl
	mov	byte [esi+veh.targetairport], 0
	call	shiftInParentMovement
	retn

global shiftInParentMovement
shiftInParentMovement:
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	je	.justReturnNoPop
	push	eax
	push	dx
	mov	dl, byte [esi+veh.movementstat]
	movzx	eax, word [esi+veh.nextunitidx]
	shl	ax, 7
	add	eax, [veharrayptr]
	cmp	byte [eax+veh.parentmvstat], 0xFF
	jne	.shiftIntoUpper
.doNormal:
	mov	byte [eax+veh.parentmvstat], dl
	mov	byte [eax+0x6E], 0xFF
	jmp	.shifted
.shiftIntoUpper:
	mov	byte [eax+0x6E], dl
.shifted:
	mov	dl, byte [esi+0x6A]
	mov	byte [eax+0x6A], dl
.dontDoTurnAround:
	pop	dx
	pop	eax
.justReturnNoPop:
	retn


global checkIfTrailerAndCancelCollision
checkIfTrailerAndCancelCollision:
	push	eax
	mov	ax, word [edi+veh.engineidx]		//am I an Engine/Single car?
	cmp	ax, word [edi+veh.idx]
	je	.checkIfHead
	cmp	word [edi+0x6A], 0			//check if vehicle is doing a u-turn
	jne	.zeroCollisionOnOtherVehicle
	mov	ax, word [esi+veh.nextunitidx]		//is the target my 'parent'
	cmp	ax, word [edi+veh.idx]			//note: this is _not_ always the engine!
	je	.checkIfInStation			//(we want to collide with the parent)
	mov	ax, word [esi+veh.idx]			//is the target my engine?
	cmp	ax, word [edi+veh.engineidx]		//note that I need to collide with my 'parent'
	je	.checkIfInStation			//AND my engine... the other cars are ok.
.zeroCollisionOnOtherVehicle:
	mov	eax, dword [rvCollisionFoundVehicle]
	mov	dword [eax], 0x0			//cancel any collision!
	pop	eax
	retn
.checkIfInStation:
	movzx	eax, word [esi+veh.XY]
	mov	al, byte [landscape4(ax)]
	and	al, 0xF0
	cmp	al, 0x50
	je	.zeroCollisionOnOtherVehicle
	jmp	.moveInCollision
.checkIfHead:
	cmp	word [edi+veh.nextunitidx], 0xFFFF	//do i have trailers?
	je	.moveInCollision			//(no? then collide!)
	push	eax					//is the target a trailer of mine?
	mov	ax, [esi+veh.engineidx]			//(we dont want to collide with them)
	cmp	word [edi+veh.idx], ax
	pop	eax
	je	.zeroCollisionOnOtherVehicle
.moveInCollision:					//just collide!
	pop	eax
	mov	eax, dword [rvCollisionFoundVehicle]
	mov	dword [eax], esi
	retn

global checkIfTrailerAndStartInDepot
checkIfTrailerAndStartInDepot:
	push	eax
	mov	ax, [edi+veh.engineidx]
	cmp	ax, [edi+veh.idx]
	pop	eax
	jne	.processRVTrailer
	cmp	byte [esi+veh.movementstat], 0FEh
	je	.jumpToEnd
	retn
.jumpToEnd:
	pop	dword [discard]
	jmp	[JumpOutOfRVRVCollision]
.processRVTrailer:
	cmp	byte [edi+veh.movementstat], 0FEh
	je	.jumpToEnd
	cmp	byte [esi+veh.movementstat], 0FEh
	je	.jumpToEnd
	retn

global dontOpenRVWindowForTrailer
dontOpenRVWindowForTrailer:
	mov	cl, 0Dh
	mov	dx, [edi+veh.idx]
	push	ecx
	xor	ecx, ecx
	mov	cx, [edi+veh.engineidx]
	cmp	cx, [edi+veh.idx]
	je	.notATrailer
	shl	cx, 7
	add	ecx, [veharrayptr]
	mov	dx, [ecx+veh.idx]
	mov	edi, ecx
.notATrailer:
	pop	ecx
	retn

global skipTrailersInDepotWindow
skipTrailersInDepotWindow:
	push	eax
	xor	eax, eax
	mov	ax, [edi+veh.idx]
	cmp	ax, [edi+veh.engineidx]
	pop	eax
	jne	.useThisAsTheReturnCMP
	mov	ax, [esi+window.id]
	cmp	ax, [edi+veh.XY]
	retn
.useThisAsTheReturnCMP:
	cmp	ax, 0xFFFF				//we just want this to always fail
	retn

global dontAddScheduleForTrailers
dontAddScheduleForTrailers:
	cmp	dword [articulatedvehicle], 0		//trailer?
	jne	.trailer
	add	dword [scheduleheapfree], 2		//no, do the usual
	mov	dword [esi+veh.scheduleptr], ebx
	mov	[ebx], word 0x0
.trailer:
	retn

global sellRVTrailers
sellRVTrailers:
	cmp	word [edx+veh.nextunitidx], 0xFFFF	;do we have trailers?
	jne	.trailersExist

	call	near $
ovar .origfn, -4, $, sellRVTrailers
	retn

.trailersExist:
	pushad						;push prev veh onto stack
	movzx	edx, word [edx+veh.nextunitidx]		;iterate to last trailer...
	shl	dx, 7
	add	edx, [veharrayptr]
	cmp	word [edx+veh.nextunitidx], 0xFFFF	;MORE? push them on the stack
	jne	.trailersExist
.recurseOut:
	mov	word [edx+veh.nextunitidx], 0xFFFF	;is this needed?
	movzx	edx, word [edx+veh.idx]
	mov	bl, 1					;no idea what's meant to be in here
							;but sellRoadVehicle wants 1
	call	[sellroadvehicle]			;del trailer.
	popad
	push	eax
	mov	ax, [edx+veh.idx]
	cmp	ax, [edx+veh.engineidx]
	pop	eax
	jne	.recurseOut				;more trailers.
	mov	word [edx+veh.nextunitidx], 0xFFFF	;is this needed?
	jmp	sellRVTrailers				;head? back to top.

global updateTrailerPosAfterRVProc
updateTrailerPosAfterRVProc:
	mov	byte [runTrailer], 0
	push	ebx
	movzx	ebx, word [esi+veh.engineidx]
	cmp	bx, word [esi+veh.idx]
	pop	ebx
	jne	.justQuit			;engine? continue: not? quit.
	push	bx
	mov	bl, byte [esi+veh.movementfract]
	pushad
	call	near $
ovar .origfn, -4, $, updateTrailerPosAfterRVProc
	popad
	cmp	bl, byte [esi+veh.movementfract]
	pop	bx
	jb	.setTrailerFlag
	jmp	.continueRunningTrailers
.setTrailerFlag:
	mov	byte [runTrailer], 1
.continueRunningTrailers:
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;trailers? continue.
	je	.justQuit
	;now we need to check if rvproc was actually run, there is a ticker inside that stops it run on every call.
	push	esi
.loopToNextTrailer:
	push	cx
	mov	cx, word [esi+veh.XY]
	mov	word [ParentXY], cx
	mov	dword [ParentIDX], esi
	pop	cx
	movzx	esi, word [esi+veh.nextunitidx]
	shl	si, 7
	add	esi, dword [veharrayptr]	;we now have the first trailers ptr.
	pushad
	call	RVTrailerProcessing	;see below.
	popad
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;morE?
	jne	.loopToNextTrailer
	pop	esi
.justQuit:
	retn

;-------------MY HACKY FUNCTION... THIS, in the end, NEEDS TO REPLICATE RVProcessing.
; BUT ONLY THE BITS WE NEED... EVERYONE CAN HELP WITH THIS :)))

var	unk_1125D7,		db 0x00,0x01,0x08,0x09
var	unk_1125DB,		db 0x01,0x03,0x05,0x07,0x90
uvarb	runTrailer

global RVTrailerProcessing
RVTrailerProcessing:
	inc	byte [esi+veh.cycle]
	cmp	byte [esi+0x6A], 0
	jz	short .skipCounter
	dec	byte [esi+0x6A]		;what counter is this?
.skipCounter:
	cmp	word [esi+0x68], 0
	jnz	.ProcessCrashedRV

	;breakdowns and collisions need to be shifted in from the parent...

	;call	[ChkForRVCollisionWithTrain]
	;cmp	byte [esi+veh.breakdowncountdown], 0		we don't care for breakdowns... the head will work this out.
	;jz	short .noBreakDown
	;cmp	byte [esi+veh.breakdowncountdown], 2
	;jbe	short .breakDownRV		;if we're 2 or 1, since 0 gets skipped... we're broken
						;2 == draw smoke, make noise, etc....
						;1 == just tick down the breakdown timer...
	;dec	byte [esi+veh.breakdowncountdown]
	jmp	short .noBreakDown		;otherwise just business as usual... though we have decrmented
.ProcessCrashedRV:
	jmp	[ProcessCrashedRV]
.breakDownRV:
	;call	[ProcessBrokenDownRV]
	retn

.noBreakDown:
	test	word [esi+veh.vehstatus], 2		;2 == stopped... so just quit.
	jnz	near .justQUIT
	call	[ProcessNextRVOrder]			;get next station, if necessary
	call	[ProcessLoadUnload]			;process load/unload state
	mov	ax, word [esi+veh.currorder]
	and	al, 1Fh
	cmp	al, 4				;4== _N0_IDEA_ (ie. not on way to station,depot,etc)
	jz	short .notOnWayToStationDepotOrNowhere
	cmp	al, 3				;3== loading/unloading
	jnb	near .justQUIT			;so if we're 3 or above... just quit...

.notOnWayToStationDepotOrNowhere:
	cmp	byte [esi+veh.movementstat], 0FEh
	jz	near .inDepot
	call	[IncrementRVMovementFrac]			;process vehicle tick, if overflow then make movement
	;jb	short .makeAMove				;needs to be called... but we don't want it governing whether or not
								;this process runs!
	inc	ax
	inc	ax
	inc	ax						;play catch up
	inc	ax
	cmp	byte [runTrailer], 1
	je	.makeAMove
	retn

.makeAMove:
	cmp	byte [esi+0x66], 0		;are we overtaking?
	jz	short .doTheOvertake
	inc	byte [esi+0x67]
	cmp	byte [esi+0x67], 23h		;seems that 23 is the max overtaking steps
	jb	short .doTheOvertake
	mov	byte [esi+0x66], 0		;stop overtaking.

.doTheOvertake:
	call	[SetCurrentVehicleBBox]			;overtaking........
	movzx	ebx, byte [esi+veh.movementstat]	;i'm not going to bother dechipering the following
	cmp	bl, 0FFh				;movementstat of -1? what the!
	jz	near .skipOvertake
	add	bl, byte [roadtrafficside]
	xor	bl, byte [esi+0x66]
	push	ecx
	mov	ecx, dword [off_111D62]
	mov	ebx, [ecx+ebx*4]		;GET ADDRESS
	pop	ecx
	movzx	edx, byte [esi+0x63]
	shl	edx, 1
	add	ebx, edx
	mov	dx, [ebx+2]
	test	dl, 80h
	jnz	near .CallPathfinderForNewTile			;Runs off and does pathfinder stuffssss  ?????????????????
	test	dl, 40h
	jnz	near .Process2ndTurnInUTurn			;
	mov	ax, word [esi+veh.xpos]
	mov	cx, word [esi+veh.ypos]
	and	al, 0F0h
	and	cl, 0F0h
	or	al, dl
	or	cl, dh
	mov	bl, dl
	call	[LimitTurnToFortyFiveDegrees]	;make sure new turn is only 45deg
	mov	bl, byte [esi+veh.movementstat]
	cmp	bl, 20h				;are we going 'straight'?
	jb	short .checkIfWeCanOvertake
	cmp	bl, 30h				;we're turning, or something, don't even bother
	jb	short .noNeedToAttemptOvertake

.checkIfWeCanOvertake:
	call	[RVCheckCollisionWithRV]		;are we up the ass of an RV?
	jnb	short .noNeedToAttemptOvertake	;no... continue
	;cmp	byte [esi+0x66], 0
	;jnz	near .justQUIT
	;call	[RVCheckOvertake]		;CANCELLED OUT.. conflicts with trams and is unecessary for trailers anyway.
	;but we'll feed in the flags from the parent anyway.
	jmp	near .justQUIT
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.noNeedToAttemptOvertake:
	mov	dh, byte [esi+veh.direction]
	cmp	dl, dh				;We're turning, LimitTurnToFortyFiveDegrees has changed the dir.
	jz	short .noTurnRequired
	mov	byte [esi+veh.direction], dl	;shift in new direction
	mov	dl, dh
	cmp	dl, bl
	jz	short .noTurnRequired
	mov	ax, word [esi+veh.xpos]
	mov	cx, word [esi+veh.ypos]
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	jmp	[RedrawRoadVehicle]
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.noTurnRequired:
	movzx	ebx, byte [esi+veh.movementstat]
	sub	bl, 20h
	jb	near .JustMoveIntoNextTile				;this is not a station!
	add	bl, byte [roadtrafficside]
	push	ecx
	mov	ecx, dword [byte_112552]
	mov	bl, [ecx+ebx]				;the ends of the tiles? or maybe the ends of the stations.
	pop	ecx
	cmp	bl, byte [esi+0x63]				;this is the px into the current tile 0x0-0xF
	jnz	near .JustMoveIntoNextTile
	movzx	ebp, word [esi+veh.XY]				;ugh.. from here is station code... nasty
	mov	bl, [landscape2+ebp]
	mov	byte [vaTempLocation1], bl
	mov	bx, word [esi+veh.currorder]
	and	bl, 1Fh
	cmp	bl, 4
	jz	near .loc_165C37
	cmp	bl, 2
	jz	near .loc_165C37
	mov	bp, word [esi+veh.XY]
	mov	edx, [station.busstop]
	mov	al, byte [landscape5(bp,1)]
	cmp	al, 43h
	jb	short .loc_165BBB
	cmp	al, 47h
	jnb	short .loc_165BBB
	mov	dl, [station.truckstop]

.loc_165BBB:
	movzx	ebp, byte [vaTempLocation1]
	imul	bp, 8Eh
	add	ebp, [stationarrayptr]
	and	byte [edx+ebp], 7Fh ;not 80h
	mov	al, byte [vaTempLocation1]
	mov	byte [esi+veh.laststation], al
	call	[GenerateFirstRVArrivesMessage]
	mov	ax, word [esi+veh.currorder]
	mov	word [esi+veh.currorder], 3
	mov	dl, al
	and	dl, 1Fh
	cmp	dl, 1
	jnz	short .loc_165C08
	cmp	ah, byte [vaTempLocation1]
	jnz	short .loc_165C08
	or	word [esi+veh.currorder], 80h
	and	ax, 60h
	or	word [esi+veh.currorder], ax

.loc_165C08:
	mov	byte [currentexpensetype], expenses_rvincome
	call	LoadUnloadCargo		; in: esi->vehicle		USE THE REDEFINED ONE, THEREFORE no brackets!
					; out: al=flags (see below)
	or	al, al
	jz	short .loc_165C29
	movzx	bx, byte [esi+veh.owner]
	mov	al, 0x0A ;cWinTypeRVList
	call	[RefreshWindows]	; AL = window type
					; AH = element idx (only if AL:7 set)
					; BX = window ID (only if AL:6 clear)
	call	[RedrawRoadVehicle]

.loc_165C29:
	mov	bx, word [esi+veh.idx]
	mov	ax, 0x48D ;cWinTypeVehicle or cWinElemRel or cWinElem4
	call	[RefreshWindows]	; AL = window type
					; AH = element idx (only if AL:7 set)
					; BX = window ID (only if AL:6 clear)
	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.loc_165C37:
	retn				//ADDED TO STOP TRAILERS FROM DOING STATIONS.
	push	ax
	mov	bp, word [esi+veh.XY]
	mov	ebx, [station.busstop]
	mov	al, byte [landscape5(bp,1)]
	cmp	al, 43h
	jb	short .loc_165C51
	cmp	al, 47h
	jnb	short .loc_165C51
	mov	bl, [station.truckstop]

.loc_165C51:
	movzx	ebp, byte [vaTempLocation1]
	imul	bp, 8Eh
	add	ebp, [stationarrayptr]
	mov	ax, word [esi+veh.currorder]
	and	al, 1Fh
	cmp	al, 2
	jz	short .loc_165C7A
	test	byte [ebx+ebp], 80h
	jz	short .loc_165C7A
	pop	ax
	jmp	.zeroSpeedAndReturn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.loc_165C7A:
	or	byte [ebx+ebp], 80h
	mov	ax, word [esi+veh.currorder]
	and	al, 1Fh
	cmp	al, 2
	jz	short .loc_165C8E
	mov	word [esi+veh.currorder], 0

.loc_165C8E:
	call	RVStartSound
	mov	bx, word [esi+veh.idx]
	mov	ax, 0x48D ;cWinTypeVehicle or cWinElemRel or cWinElem4
	call	[RefreshWindows]		; AL = window type
					; AH = element idx (only if AL:7 set)
					; BX = window ID (only if AL:6 clear)
	pop	ax

.JustMoveIntoNextTile:
	mov	bp, word [esi+veh.XY]
	call	[VehEnterLeaveTile]
	or	ebp, ebp
	js	near .zeroSpeedAndReturn
	test	ebp, 40000000h
	jnz	short .loc_165CBE
	inc	byte [esi+0x63]

.loc_165CBE:
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[RedrawRoadVehicle]
	call	[RVMountainSpeedManagement]

.justQUIT:
	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.CallPathfinderForNewTile:
	and	edx, 3
	mov	byte [byte_11258E], dl			;seems to be a temp location for dl... which is the new movement stat?
	mov	di, word [esi+veh.XY]

	push	ebx
	mov	ebx, dword [word_11257A]
	add	di, [ebx+edx*2]
	pop	ebx
	push	di
	call	[RoadVehiclePathFinder]
	pop	di
	push	esi
	mov	esi, dword [ParentIDX]
	cmp	byte [esi+0x6A], 0
	pop	esi
	jne	.somewhere1
	mov	dl, byte [esi+veh.parentmvstat]
.somewhere1:
	bt	bx, dx
	jb	near .zeroSpeedAndReturn

.loopThisChunkAgain:
	mov	al, dl
	and	al, 7
	cmp	al, 6
	jb	short .dontMoveInXY
	mov	di, word [esi+veh.XY]

.dontMoveInXY:
	and	edx, 0FFh
	add	dl, byte [roadtrafficside]
	xor	dl, byte [esi+0x66]
	push	ecx
	mov	ecx, dword [off_111D62]
	mov	ebx, [ecx+edx*4]
	pop	ecx
	mov	bp, di
	rol	di, 4
	mov	ax, di
	mov	cx, di
	rol	cx, 8
	and	ax, 0FF0h
	and	cx, 0FF0h
	add	al, [ebx]
	add	cl, [ebx+1]
	mov	bl, dl
	and	bl, 0EFh
	push	bx
	call	[LimitTurnToFortyFiveDegrees]
	pop	bx
	call	[VehEnterLeaveTile]
	push	esi
	mov	esi, dword [ParentIDX]
	cmp	byte [esi+0x6A], 0
	pop	esi
	je	.somewhere
	mov	bp, word [ParentXY]
.somewhere:
	or	ebp, ebp				;we can't move into the next tile
	js	near .checkForTunnelOrTryAgain
	push	ax
	push	ebx
	push	ebp
	mov	ah, byte [esi+veh.movementstat]
	cmp	ah, 20h					;station maneuver?
	jb	near .finaliseAndMove
	cmp	ah, 30h
	jnb	near .finaliseAndMove
	mov	dh, bl
	movzx	ebx, word [esi+veh.XY]
	mov	al, byte [landscape4(bx)]
	and	al, 0F0h
	cmp	al, 50h
	jnz	near .finaliseAndMove
	mov	al, dh					;otherwise we're entering a station! (or exiting)
	and	al, 7
	cmp	al, 6
	jnb	short .stopVehicleEntirely
	mov	al, byte [landscape5(bx,1)]
	movzx	ebx, byte [landscape2+ebx]			; BYTE !?!?!?!
	imul	bx, 8Eh
	add	ebx, [stationarrayptr]
	cmp	al, 43h
	jb	short .workWithBusStops
	cmp	al, 47h
	jb	short .workWithTruckStops

.workWithBusStops:
	cmp	al, 47h
	jb	short .finaliseAndMove
	cmp	al, 4Bh
	jnb	short .finaliseAndMove
	mov	al, 1
	test	ah, 2
	jz	short .dontChangeALForBusStop
	shl	al, 1

.dontChangeALForBusStop:
	or	al, byte [ebx+station.busstop]
	and	al, 7Fh; not 80h
	mov	byte [ebx+station.busstop], al
	jmp	short .finaliseAndMove
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.stopVehicleEntirely:
	pop	ebp
	pop	ebx
	pop	ax
	mov	word [esi+veh.speed], 0
	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.workWithTruckStops:
	mov	al, 1
	test	ah, 2
	jz	short .dontChangeALForTruckStop
	shl	al, 1

.dontChangeALForTruckStop:
	or	al, byte [ebx+station.truckstop]
	and	al, 7Fh
	mov	byte [ebx+station.truckstop], al

.finaliseAndMove:
	pop	ebp
	pop	ebx
	pop	ax
	test	ebp, 40000000h
	jnz	short .dontActuallyMoveVehicle		;something failed and we can't use this move.
	mov	word [esi+veh.XY], bp
	call	useParentMovement	;mov	byte [esi+veh.movementstat], bl
	mov	byte [esi+0x63], 0

.dontActuallyMoveVehicle:
	cmp	dl, byte [esi+veh.direction]
	jz	short .weAreNotTurning
	mov	byte [esi+veh.direction], dl		;change direction
	mov	bp, word [esi+veh.speed]		;slow down
	shr	bp, 2					;slow down
	sub	word [esi+veh.speed], bp		;slow down

.weAreNotTurning:
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[RedrawRoadVehicle]
	jmp	[RVMountainSpeedManagement]
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.checkForTunnelOrTryAgain:
	mov	bl, byte [landscape4(bp)]
	and	bl, 0F0h
	cmp	bl, 90h
	jnz	near .zeroSpeedAndReturn
	movzx	ebx, byte [byte_11258E]
	push	ecx
	mov	ecx, dword [unk_112582]
	movzx	dx, byte [ecx+ebx]
	pop	ecx
	jmp	.loopThisChunkAgain
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.Process2ndTurnInUTurn:					;seems to be called only when we're doing a UTURN
	and	edx, 3
	mov	di, word [esi+veh.XY]
	push	di
	call	[RoadVehiclePathFinder]
	pop	di
	push	esi
	mov	esi, dword [ParentIDX]
	cmp	byte [esi+0x6A], 0
	pop	esi
	jne	.somewhere12
	mov	dl, byte [esi+veh.parentmvstat]
.somewhere12:
	bt	bx, dx
	jb	near .zeroSpeedAndReturn
	and	edx, 0FFh
	add	bl, byte [roadtrafficside]
	push	ecx
	mov	ecx, dword [off_111D62]
	mov	ebx, [ecx+ebx*4]
	pop	ecx
	mov	bp, di
	rol	di, 4
	mov	ax, di
	mov	cx, di
	rol	cx, 8
	and	ax, 0FF0h
	and	cx, 0FF0h
	add	al, [ebx+2]
	add	cl, [ebx+3]
	mov	bl, dl
	and	bl, 0EFh
	push	bx
	call	[LimitTurnToFortyFiveDegrees]
	pop	bx
	call	[VehEnterLeaveTile]
	or	ebp, ebp
	js	short .zeroSpeedAndReturn
	call	useParentMovement	;mov	byte [esi+veh.movementstat], bl
	mov	byte [esi+0x63], 1
	cmp	dl, byte [esi+veh.direction]
	jz	short .skipTurnCode
	mov	byte [esi+veh.direction], dl

.skipTurnCode:
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[RedrawRoadVehicle]
	jmp	[RVMountainSpeedManagement]

; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
.zeroSpeedAndReturn:
	mov	word [esi+veh.speed], 0
	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.skipOvertake:
	xor	edi, edi
	call	[GetVehicleNewPos]		; ESI -> vehicle
						; Return: AX,CX = new X,Y coordinates
						;         DI = new XY index
						;         EBX = current XY index
						;         ZF set if BX=DI
	mov	dl, byte [esi+veh.direction]
	call	[RVCheckCollisionWithRV]		;check if there is a vehicle 'in front' of us.
	jb	short .zeroSpeedAndReturn
	mov	dl, byte [landscape4(di,1)]			;landscape 4
	and	dl, 0F0h
	cmp	dl, 90h				;IS THIS A STATION?
	jnz	short .notJustRoad
	test	byte [landscape5(di,1)], 0F0h		;IS THIS LEVEL CROSSING OR DEPOT?
	jnz	short .notJustRoad
	mov	bp, di
	call	[VehEnterLeaveTile]
	test	ebp, 40000000h			;are we entering a new tile? or just moving forward?
	jnz	short .enterNewTile

.notJustRoad:
	mov	word [esi+veh.xpos], ax
	mov	word [esi+veh.ypos], cx
	call	[UpdateVehicleSpriteBox]
	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.enterNewTile:
	call	[UpdateDirectionIfMovedTooFar]	;checks if the calculated positions are more than one pixel
						;greater than the previous positions and then changes the direction
						;(well, moves it into bl)
	push	bx				;but now we mask the new direction
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]		;why do we want to use the current direction instead of the new one?
	call	[SetRoadVehObjectOffsets]	;this func doesn't even care for any input params, except esi
						;from which it gets veh.direction.
	pop	bx
	call	[RedrawRoadVehicle]
	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.inDepot:
	mov	word [esi+veh.speed], 0			;exit depot
	mov	di, word [esi+veh.XY]
	mov	bl, byte [landscape5(di,1)]
	and	ebx, 3
	mov	dl, byte [unk_1125DB+ebx]		;Direction to leave depot
	mov	byte [esi+veh.direction], dl			;set vehicles direction
	mov	bl, byte [unk_1125D7+ebx]		;next move after depot?
	mov	dl, byte [roadtrafficside]
	and	edx, 7Fh
	add	dl, bl
	push	ecx
	mov	ecx, dword [off_111D62]
	mov	edx, [ecx+edx*4]
	pop	ecx					;get the movementstat for the next move!?!?!?!?
	rol	di, 4
	mov	ax, di
	mov	cx, di
	rol	cx, 8
	and	ax, 0FF0h
	and	cx, 0FF0h
	add	al, byte [edx+0Ch]			;set up the collision box.
	add	cl, byte [edx+0Dh]			;and this is the other coord of the box
	mov	dl, byte [esi+veh.direction]
	call	[RVCheckCollisionWithRV]			;is there an RV in the way?
	jb	.zeroSpeedAndReturn			;don't move!
	call	[RVStartSound]				;make noise.
	and	byte [roadtrafficside], 7Fh
	push	ax
	call	[SetCurrentVehicleBBox]
	pop	ax
	and	word [esi+veh.vehstatus], 0FFFEh		;set all the relevant starting values
	call	useParentMovement	;mov	byte [esi+veh.movementstat], bl
	mov	byte [esi+0x63], 6			;what the hell is this?
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[RedrawRoadVehicle]
	mov	al, 12h ;cWinTypeDepot
	mov	bx, word [esi+veh.XY]
	call	[RefreshWindows]
	retn

global	useParentMovement
useParentMovement:
	push	edx
	mov	dl, byte [esi+veh.parentmvstat]
	mov	dh, byte [esi+0x6E]
	mov	byte [esi+veh+0x6E], 0xFF
	mov	byte [esi+veh.parentmvstat], dh
	mov	byte [esi+veh.movementstat], dl
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	je	.noTrailer
	push	eax
	movzx	eax, word [esi+veh.nextunitidx]
	shl	ax, 7
	add	eax, [veharrayptr]
	cmp	byte [eax+veh.parentmvstat], 0xFF
	jne	.shiftIntoUpper
	mov	byte [eax+veh.parentmvstat], dl
	mov	byte [eax+0x6E], 0xFF
	jmp	.shifted
.shiftIntoUpper:
	mov	byte [eax+0x6E], dl
.shifted:
	mov	dl, byte [esi+0x6A]
	mov	byte [eax+0x6A], dl
	pop	eax
.noTrailer:
	pop	edx
	retn

global turnTrailersAroundToo
turnTrailersAroundToo:
	test	bl, 1
	jz	.justReturn
	mov	byte [edx+0x6A], 180
	push	ecx
	push	ax
	movzx	ecx, word [edx+veh.engineidx]
	mov	ax, word [edx+veh.XY]
	cmp	cx, word [edx+veh.idx]
	jne	.cleanAndJustReturn
	mov	ecx, edx
.doZeeLoop:
	cmp	word [ecx+veh.nextunitidx], 0xFFFF      //MORE?
	je	.cleanAndJustReturn
	mov	cx, word [ecx+veh.nextunitidx]
	shl	cx, 7
	add	cx, [veharrayptr]
;	mov	ax, word [edx+veh.XY]
;	mov	word [ecx+veh.XY], ax
;	mov	byte [ecx+0x6A], 180
	jmp	.doZeeLoop
.cleanAndJustReturn:
	pop	ax
	pop	ecx
.justReturn:
	retn
