//----------------------START HEADER--------------------------------
//welcome to the patches of road vehicle articulation
//----------------------END HEADER----------------------------------

#include <defs.inc>
#include <ttdvar.inc>
#include <textdef.inc>
#include <veh.inc>
#include <town.inc>
#include <imports/gui.inc>
#include <window.inc>
#include <station.inc>
#include <ptrvar.inc>
#include <misc.inc>

extern newbuyrailvehicle, discard, vehcallback, articulatedvehicle, delveharrayentry, sellroadvehicle
extern RefreshWindows, LoadUnloadCargo, checkgototype, isrvbus, curplayerctrlkey, drawtextfn, currscreenupdateblock
extern newtexthandler, drawsplittextfn, movbxcargoamountname2
extern searchcollidingvehs, tiledeltas

uvard DrawRVImageInWindow,1,s

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
uvard oldrvdailyproc

uvarw curDepotLocation,1,s
uvard vehicleToAttachTo,1,s

uvard cacheFoundVehicle, 1, s
uvard movingVehicle, 1, s

global newbuyroadvehicle
newbuyroadvehicle:
	push	ecx
	push	eax
	shr	ax, 4
	shl	cx, 4
	add	cx, ax
	mov	word [curDepotLocation], cx		//get the current depot location
	pop	eax					//which is currently x/y split in ax/cx
	pop	ecx

	cmp	byte [curplayerctrlkey], 0
	jz .dontCheckForExistingVehicleInDepot

	//is there a 'compatible' vehicle in the depot? What vehicle are we buying?
	//do i care if you mix passenger and goods?
	//DO THIS:			loop through vehicle array
	//				and see if there is an 'rv' with the same xy and stat of 0xFE
	//				and THEN store the pointer

	push	edi
	mov	edi, dword [veharrayptr]
.tryNextVehicle:
	cmp	byte [edi+veh.class], 11h
	jnz	short .doLoop
	cmp	byte [edi+veh.movementstat], 0FEh
	jnz	short .doLoop
	push	ebx
	movzx	ebx, word [curDepotLocation]
	cmp	bx, word [edi+veh.XY]
	pop	ebx
	jnz	short .doLoop
	cmp	byte [edi+veh.consistnum], 0
	je	short .doLoop
	mov	dword [vehicleToAttachTo], edi
	jmp	short .doneFindingRVInDepot
.doLoop:
	add	edi, 80h
	cmp	edi, dword [veharrayendptr]
	jb	short .tryNextVehicle

	//ERROR OUT!   --> I think we need a "Please have a vehicle in slot 1 of depot" message.
	mov	ebx, 0x80000000
	pop	edi
	retn

.doneFindingRVInDepot:
	pop	edi

.dontCheckForExistingVehicleInDepot:
	mov	byte [buildingroadvehicle], 1
	call	newbuyrailvehicle			//this proc knows what to do
							//if [buildingroadvehicle] is set... and it is!
							//see newtrains.asm

	//ok, the control key was pressed, we need to attach this vehicle to the first one in the depot window.
	//we do this here, because we need to have had all the new vehicles trailers attached
	//so that we can set their new 'engineidx'

	//DO THIS:	check for pointers
	//		then set the trailer of the vehicle (loop to find it).nextunitidx to the new vehicle.
	//		then set all the engineidxs to the head.

	cmp	byte [curplayerctrlkey], 0
	jz .dontMakeThisVehicleATrailer

	cmp word [curDepotLocation], -1
	je .dontMakeThisVehicleATrailer
	cmp dword [vehicleToAttachTo], -1
	je .dontMakeThisVehicleATrailer

	cmp	esi, edi					//if not equal then testing cost? (or something)
	jne	.dontMakeThisVehicleATrailer

	push	edi
	mov	edi, dword [vehicleToAttachTo]			//grab the parent
.testNextTrailer:
	cmp	word [edi+veh.nextunitidx], 0xFFFF		//grab the parents last trailer
	je	.thisIsTheLastTrailer
	movzx	edi, word [edi+veh.nextunitidx]
	shl	edi, 7
	add	edi, [veharrayptr]
	jmp	.testNextTrailer
.thisIsTheLastTrailer:						//now set nextunitidx to the new vehicle
	push	ecx
	mov	cx, word [esi+veh.idx]
	mov	word [edi+veh.nextunitidx], cx			// initialise to a trailer, set basic params.
	mov	byte [esi+veh.subclass], 0x02			//futile?
	mov	byte [esi+veh.parentmvstat], 0xFF
	mov	byte [esi+veh.parentmvstat2], 0xFF
	mov	edi, dword [vehicleToAttachTo]			//grab the parent again
	mov	cx, word [edi+veh.idx]
.loopSetTrailerEngineIDX:					//loop through the whole lot and reset engineidx
	mov	word [edi+veh.engineidx], cx
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	je	.weAreAllDone
	movzx	edi, word [edi+veh.nextunitidx]
	shl	edi, 7
	add	edi, [veharrayptr]
	jmp	.loopSetTrailerEngineIDX
.weAreAllDone:

// We are not quite done, remove the consist number so that the normal buy road vehicle function
// doesn't skip consist numbers (which are used by trailers when they are not needed)
	mov byte [esi+veh.consistnum], 0

	pop	ecx
	pop	edi

.dontMakeThisVehicleATrailer:
	mov	word [curDepotLocation], -1		//reset variables
	mov	dword [vehicleToAttachTo], -1
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
	shl	eax, 7
	add	eax, [veharrayptr]
	cmp	byte [eax+veh.parentmvstat], 0xFF
	jne	.shiftIntoUpper
	mov	byte [eax+veh.parentmvstat], dl
	mov	byte [eax+veh.parentmvstat2], 0xFF
	jmp	.shifted
.shiftIntoUpper:
	mov	byte [eax+veh.parentmvstat2], dl
.shifted:
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
	push	esi
	movzx	esi, word [edi+veh.engineidx]
	shl	esi, 7
	add	esi, [veharrayptr]
	cmp	byte [esi+veh.movementstat], 0xFE
	je	.checkStatus
	pop	esi
	jmp	short .continueChecking
.checkStatus:
	test	word [esi+veh.vehstatus], 2
	pop	esi
	jz	.moveInCollision
.continueChecking:
	mov	ax, word [esi+veh.nextunitidx]		//is the target my 'parent'
	cmp	ax, word [edi+veh.idx]			//note: this is _not_ always the engine!
	je	.moveInCollision			//(we want to collide with the parent)
	mov	ax, word [esi+veh.engineidx]
	cmp	ax, word [edi+veh.engineidx]		//is this a trailer of my tram?
	jne	.checkOvertake
	mov	ax, word [esi+veh.idx]
	cmp	ax, word [edi+veh.idx]			//does this trailer come before me?
	jl	.moveInCollision
.checkOvertake:
;	cmp	byte [edi+0x6A], 0			//am i uturning?
;	jne	.moveInCollision
;	cmp	byte [esi+0x6A], 0			//are they uturning?
;	jne	.moveInCollision
.zeroCollisionOnOtherVehicle:
	mov	eax, dword [rvCollisionFoundVehicle]
	mov	dword [eax], 0x0			//cancel any collision!
	pop	eax
	retn
.checkIfHead:
	cmp	word [edi+veh.nextunitidx], 0xFFFF	//do i have trailers?
	je	.moveInCollision			//(no? then collide!)
	push	eax					//is the target a trailer of mine?
	mov	ax, [esi+veh.engineidx]		//(we dont want to collide with them)
	cmp	word [edi+veh.idx], ax
	pop	eax
	je	.zeroCollisionOnOtherVehicle
.moveInCollision:					//just collide!
	pop	eax
	mov	eax, dword [rvCollisionFoundVehicle]
	mov	dword [eax], esi
	retn

;global checkIfTrailerAndStartInDepot
;checkIfTrailerAndStartInDepot:
;	push	eax
;	mov	ax, [edi+veh.engineidx]
;	cmp	ax, [edi+veh.idx]
;	pop	eax
;	jne	.processRVTrailer
;	cmp	byte [esi+veh.movementstat], 0FEh
;	je	.jumpToEnd
;	retn
;.jumpToEnd:
;	pop	dword [discard]
;	jmp	[JumpOutOfRVRVCollision]
;.processRVTrailer:
;	cmp	byte [edi+veh.movementstat], 0FEh
;	je	.jumpToEnd
;	cmp	byte [esi+veh.movementstat], 0FEh
;	je	.jumpToEnd
;	retn

global dontOpenRVWindowForTrailer
dontOpenRVWindowForTrailer:
	mov	cl, 0Dh
	mov	dx, [edi+veh.idx]
	push	ecx
	xor	ecx, ecx
	mov	cx, [edi+veh.engineidx]
	cmp	cx, [edi+veh.idx]
	je	.notATrailer
	shl	ecx, 7
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
	cmp word [edx+veh.nextunitidx], byte -1
	je .noTrailers
	
	push edx
	movzx edx, word [edx+veh.nextunitidx]
	call .deleteTrailer
	pop edx
	
.noTrailers:
	call near $ ; Delete our consist head vehicle
ovar .origfn, -4, $, sellRVTrailers
	ret

// Input:	edx - vehicle to delete
.deleteTrailer:
	pusha
	xor ecx, ecx
	xor eax, eax
	mov esi, 0x10088 ; Sell (Subroutine 2), for Road Vehicles (Class 11)
	mov ebx, 1 ; We want to do the action, we don't care about the cost
extern actionhandler
	call [actionhandler]
	popa
	ret

; Stops TTD trying to delete orders (which don't exist) for a trailers
global deleteRVorders
deleteRVorders:
	cmp dword [edx+veh.scheduleptr], -1
	je .Trailer

extern delvehschedule
	call [delvehschedule]
	
.Trailer:
	mov esi, edx
	ret

uvard PrepareNewVehicleArrayEntry
uvard CalcExactGroundAltitude

; The bulk of this code works the same as buyNewRoadVehicle
; Inputs and outputs are identical
; Please note that it will not calculate stuff required for a proper rv 
; And should ONLY be used to buy trailers
global buyRVTrailer
buyRVTrailer:
	mov byte [currentexpensetype], expenses_newvehs
	test bl, 4
	jnz near .done
	mov word [operrormsg2], 0xE1 ;TID00E1_TooManyVehiclesInGame
	call [PrepareNewVehicleArrayEntry]
	jnz short .continue

.fail:
	mov ebx, 80000000h
	retn
 
.continue:
	test bl, 1
	jz near .done
	mov byte [esi+veh.consistnum], 0	; We don't actually need this as
	push ax								; we are not the head of a consist
	push ebx
	push cx
	rol cx, 8
	mov bp, cx
	rol cx, 8
	or bp, ax
	ror bp, 4
	or al, 8
	or cl, 8
	mov byte [esi+veh.direction], 0
	mov dh, [curplayer]
	mov [esi+veh.owner], dh
	mov [esi+veh.XY], bp
	mov [esi+veh.xpos], ax
	mov [esi+veh.ypos], cx
	push esi
	call [CalcExactGroundAltitude]
	pop esi
	mov [esi+veh.zpos], dl
	mov byte [esi+veh.zsize], 6
	mov byte [esi+veh.movementstat], 0FEh
	mov word [esi+veh.vehstatus], 0Bh
	shr ebx, 8
	mov al, [rvsprite-74h+ebx]
	mov [esi+veh.spritetype], al
	mov al, [rvcargotype-74h+ebx]
	mov [esi+veh.cargotype], al
	movzx ax, byte [rvcapacity-74h+ebx]
	mov [esi+veh.capacity], ax
	mov word [esi+veh.currentload], 0
	movzx eax, byte [rvcostfactor-74h+ebx]
	mov edx, [costs+68]
	sar edx, 3
	imul eax, edx
	shr eax, 5
	mov [esi+veh.value], eax
	mov byte [esi+veh.daycounter], 0
	mov word [esi+veh.currorder], 0
	mov word [esi+veh.loadtime], 0
	mov byte [esi+veh.movementfract], 0
	mov word [esi+0x64], 0
	mov byte [esi+0x66], 0
	mov word [esi+0x6A], 0
	mov byte [esi+veh.laststation], -1
	mov word [esi+veh.target], 0FFFFh
	mov dword [esi+veh.profit], 0
	mov dword [esi+veh.previousprofit], 0
	movzx ax, byte [rvspeed-74h+ebx]
	mov [esi+veh.maxspeed], ax
	mov [esi+veh.vehtype], bx
	imul bx, 1Ch
	mov word [esi+veh.reliability], 0
	mov word [esi+veh.reliabilityspeed], 0
	mov word [esi+veh.maxage], 0
	mov word [esi+veh.name], 0x902B ; TID902B_RoadVehicleW
	mov byte [esi+0x68], 0
	mov byte [esi+veh.currorderidx], 0
	mov byte [esi+veh.totalorders], 0
	mov word [esi+veh.nextunitidx], -1
	mov word [esi+veh.lastmaintenance], 0
	mov word [esi+veh.serviceinterval], 0
	mov byte [esi+veh.breakdowncountdown], 0
	mov byte [esi+veh.breakdowns], 0
	mov byte [esi+veh.breakdownthreshold], 0
	mov al, [currentyear]
	mov  [esi+veh.yearbuilt], al
	mov byte [esi+veh.class], 11h
	mov word [esi+veh.cursprite], 3093
	push esi
	call [UpdateVehicleSpriteBox]
	pop edi
	mov al, cWinTypeDepot
	mov bx, [edi+veh.XY]
	call [RefreshWindows]	; AL = window type
							; AH = element idx (only if AL:7 set)
							; BX = window ID (only if AL:6 clear)
	movzx bx, [edi+veh.owner]
	mov al, cWinTypeRVList
	call [RefreshWindows]	; AL = window type
							; AH = element idx (only if AL:7 set)
							; BX = window ID (only if AL:6 clear)
	mov al, cWinTypeCompany
	call [RefreshWindows]	; AL = window type
							; AH = element idx (only if AL:7 set)
							; BX = window ID (only if AL:6 clear)
	pop cx
	pop ebx
	pop ax

.done:
	shr ebx, 8
	movzx ebx, byte [rvcostfactor-74h+ebx]
	mov edx, [costs+68]
	sar edx, 3
	imul ebx, edx
	shr ebx, 5
	ret
	
global updateTrailerPosAfterRVProc, updateTrailerPosAfterRVProc.clock, updateTrailerPosAfterRVProc.trailers
updateTrailerPosAfterRVProc:
	push	ebx
	movzx	ebx, word [esi+veh.engineidx]
	cmp	bx, word [esi+veh.idx]
	pop	ebx
	jne	near .justQuit			;engine? continue: not? quit.

	// By default, trailer clock, move parent, move trailers and quit.
	// Mountains 3, move parent* and quit.
	// * - Which in turn does clock, move parent, move trailers several times
extern mountaintypes
	push edx
	mov dh, [mountaintypes+3]
	cmp dh , 3
	pop edx
	je .DoRvMovement

.Default:
	call .clock
	call .DoRvMovement

.trailers:
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;trailers? continue.
	je	.justQuit
	;now we need to check if rvproc was actually run, there is a ticker inside that stops it run on every call.

	push edi
	push	esi
	mov edi, esi

.loopToNextTrailer:
	movzx	esi, word [esi+veh.nextunitidx]
	shl	esi, 7
	add	esi, dword [veharrayptr]	;we now have the first trailers ptr.

.dontStartTrailer:
	pushad
	call	RVTrailerProcessing	;see below.
	popad

;----------------------------------------------
;	Quickly clean up parentmvstat,etc
;	if we're in jail.. i mean.. depot.
;----------------------------------------------
	cmp	byte [esi+veh.movementstat], 0xFE
	jne	.notInDepot
	mov	byte [esi+veh.parentmvstat], 0xFF
	mov	byte [esi+veh.parentmvstat2], 0xFF

.notInDepot:
;----------------------------------------------
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;morE?
	jne	.loopToNextTrailer
	pop	esi
	pop edi

.justQuit:
	retn

.DoRvMovement:
	pushad
	call	near $
ovar .origfn, -4, $, updateTrailerPosAfterRVProc
	popad
	ret

/************************************************
 * Road Vehicle Consist Clock Generator		*
 *						*
 * Will the head be moving, if so then store it *
 * in dl, so we can force the trailers to move  *
 * (Make sure we restore the variables though)  *
 *						*
 * Basicly SYNCS a consist keeping it together! *
 ************************************************/
.clock:
	push ecx
	xor dl, dl
	mov cx, [esi+veh.speed]
	mov dh, [esi+veh.movementfract]
	call setTrailerMovementFlags // Out ebp as the new temp head (parent otherwise)
	adc dl, 0
	mov [esi+veh.speed], cx
	mov [esi+veh.movementfract], dh
	pop ecx
	ret
/************************************************/

;-------------MY HACKY FUNCTION... THIS, in the end, NEEDS TO REPLICATE RVProcessing.
; BUT ONLY THE BITS WE NEED... EVERYONE CAN HELP WITH THIS :)))

var	unk_1125D7,		db 0x00,0x01,0x08,0x09
var	unk_1125DB,		db 0x01,0x03,0x05,0x07,0x90

global RVTrailerProcessing
RVTrailerProcessing:
	inc	byte [esi+veh.cycle]
	cmp	byte [esi+0x6A], 0
	jz	short .skipCounter
	dec	byte [esi+0x6A]
.skipCounter:
	cmp	word [esi+0x68], 0
	je	.notcrashed
	jmp	[ProcessCrashedRV]
	retn

.notcrashed:
	pusha
	call	[ChkForRVCollisionWithTrain]
	popa
	test	word [esi+veh.vehstatus], 2		;2 == stopped... so just quit.
	jnz	near .justQUIT

;-------------------------------------------------------
;something to do with stations that we don't care about.
;we just need to make sure the parent 'stops' the
;trailers somewhere... hijack a function!
;-------------------------------------------------------
;	call    RVCheckCurrentOrder
;	call    RVLoadUnloadCargo
;	mov     ax, [esi+veh.currentorder]
;	and     al, 1Fh
;	cmp     al, 4
;	jz      short continueProcessing
;	cmp     al, 3
;	jnb     exitRVProcessing
;-------------------------------------------------------


	cmp	byte [esi+veh.movementstat], 0FEh
	jz	near .inDepot
	call	RVMovementIncrement			;process vehicle tick, if overflow then make movement
	jb	short .movementRequired			;needs to be called... but we don't want it governing whether or not
	retn

.movementRequired:
	cmp	byte [esi+0x66], 0			;are we overtaking?
	jz	short .doTheOvertake
	inc	byte [esi+0x67]
	cmp	byte [esi+0x67], 23h			;seems that 23 is the max overtaking steps
	jb	short .doTheOvertake
	mov	byte [esi+0x66], 0			;stop overtaking.

.doTheOvertake:
	call	[SetCurrentVehicleBBox]			;overtaking........
	movzx	ebx, byte [esi+veh.movementstat]	;i'm not going to bother dechipering the following
	cmp	bl, 0FFh				;movementstat of -1? what the!
	jz	near .rvInTunnel
	add	bl, byte [roadtrafficside]
	xor	bl, byte [esi+0x66]
	push	ecx
	mov	ecx, dword [off_111D62]			;SO FUNDAMENTALLY IMPORTANT
	mov	ebx, [ecx+ebx*4]			;GET ADDRESS
	pop	ecx
	movzx	edx, byte [esi+veh.RVCurTilePos]
	shl	edx, 1
	add	ebx, edx
	mov	dx, [ebx+2]
	test	dl, 80h
	jnz	near .CallPathfinderForNewTile		;Runs off and does pathfinder stuffssss  ?????????????????
	test	dl, 40h
	jnz	near .Process2ndTurnInUTurn		;
	mov	ax, word [esi+veh.xpos]
	mov	cx, word [esi+veh.ypos]
	and	al, 0F0h
	and	cl, 0F0h
	or	al, dl
	or	cl, dh
	mov	bl, dl
	call	[LimitTurnToFortyFiveDegrees]		;make sure new turn is only 45deg
	mov	bl, byte [esi+veh.movementstat]
	cmp	bl, 20h					;are we going 'straight'?
	jb	short .checkIfWeCanOvertake
	cmp	bl, 30h					;if we're 20-2Fh... we're in a station.
	jb	short .noNeedToAttemptOvertake

.checkIfWeCanOvertake:
	call	[RVCheckCollisionWithRV]		;are we up the ass of an RV?
	jnb	short .noNeedToAttemptOvertake		;no... continue

	call AttemptToCorrectConflictDetection		; Basicly tries to fix collision detection results when the above function fails
	jnb .noNeedToAttemptOvertake

;--------------------------------------------------
; >8 Cut out the Overtaking part... TODO: ADD AGAIN
;--------------------------------------------------

	retn

.noNeedToAttemptOvertake:
	mov	dh, byte [esi+veh.direction]
	cmp	dl, dh					;Are we turning?
	jz	short .noTurnRequired
	mov	byte [esi+veh.direction], dl		;shift in new direction
	mov	dl, dh
	mov	bp, word [esi+veh.speed]		; we've turned... so take a quarter off our speed.
	cmp dl, bl
	jz	short .noTurnRequired
	mov	ax, word [esi+veh.xpos]
	mov	cx, word [esi+veh.ypos]
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	jmp	[RedrawRoadVehicle]

; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
;
.noTurnRequired:
	movzx	ebx, byte [esi+veh.movementstat]
	sub	bl, 20h
	jb	near .JustMoveIntoNextTile				;this is not a station!
	add	bl, byte [roadtrafficside]
	push	ecx
	mov	ecx, dword [byte_112552]
	mov	bl, [ecx+ebx]				;the ends of the tiles? or maybe the ends of the stations.
	pop	ecx
	cmp	bl, byte [esi+veh.RVCurTilePos]				;this is the px into the current tile 0x0-0xF
	jnz	near .JustMoveIntoNextTile
;------------------------------------------------
; WE JUST WANT TO QUIT.... NO STATION CODE THX!!!
;------------------------------------------------
;	int3
	retn
;	movzx	ebp, word [esi+veh.XY]				;ugh.. from here is station code... nasty
;	mov	bl, [landscape2+ebp]
;	mov	byte [vaTempLocation1], bl
;	mov	bx, word [esi+veh.currorder]
;	and	bl, 1Fh
;	cmp	bl, 4
;	jz	near .loc_165C37
;	cmp	bl, 2
;	jz	near .loc_165C37
;	mov	bp, word [esi+veh.XY]
;	mov	edx, [station.busstop]
;	mov	al, byte [landscape5(bp,1)]
;	cmp	al, 43h
;	jb	short .loc_165BBB
;	cmp	al, 47h
;	jnb	short .loc_165BBB
;	mov	dl, [station.truckstop]
;
;.loc_165BBB:
;	movzx	ebp, byte [vaTempLocation1]
;	imul	bp, 8Eh
;	add	ebp, [stationarrayptr]
;	and	byte [edx+ebp], 7Fh ;not 80h
;	mov	al, byte [vaTempLocation1]
;	mov	byte [esi+veh.laststation], al
;	call	[GenerateFirstRVArrivesMessage]
;	mov	ax, word [esi+veh.currorder]
;	mov	word [esi+veh.currorder], 3
;	mov	dl, al
;	and	dl, 1Fh
;	cmp	dl, 1
;	jnz	short .loc_165C08
;	cmp	ah, byte [vaTempLocation1]
;	jnz	short .loc_165C08
;	or	word [esi+veh.currorder], 80h
;	and	ax, 60h
;	or	word [esi+veh.currorder], ax
;
;.loc_165C08:
;	mov	byte [currentexpensetype], expenses_rvincome
;	call	LoadUnloadCargo		; in: esi->vehicle		USE THE REDEFINED ONE, THEREFORE no brackets!
;					; out: al=flags (see below)
;	or	al, al
;	jz	short .loc_165C29
;	movzx	bx, byte [esi+veh.owner]
;	mov	al, 0x0A ;cWinTypeRVList
;	call	[RefreshWindows]	; AL = window type
;					; AH = element idx (only if AL:7 set)
;					; BX = window ID (only if AL:6 clear)
;	call	[RedrawRoadVehicle]
;
;.loc_165C29:
;	mov	bx, word [esi+veh.idx]
;	mov	ax, 0x48D ;cWinTypeVehicle or cWinElemRel or cWinElem4
;	call	[RefreshWindows]	; AL = window type
;					; AH = element idx (only if AL:7 set)
;					; BX = window ID (only if AL:6 clear)
;	retn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
;
;.loc_165C37:
;	retn				//ADDED TO STOP TRAILERS FROM DOING STATIONS.
;	push	ax
;	mov	bp, word [esi+veh.XY]
;	mov	ebx, [station.busstop]
;	mov	al, byte [landscape5(bp,1)]
;	cmp	al, 43h
;	jb	short .loc_165C51
;	cmp	al, 47h
;	jnb	short .loc_165C51
;	mov	bl, [station.truckstop]
;
;.loc_165C51:
;	movzx	ebp, byte [vaTempLocation1]
;	imul	bp, 8Eh
;	add	ebp, [stationarrayptr]
;	mov	ax, word [esi+veh.currorder]
;	and	al, 1Fh
;	cmp	al, 2
;	jz	short .loc_165C7A
;	test	byte [ebx+ebp], 80h
;	jz	short .loc_165C7A
;	pop	ax
;	jmp	.zeroSpeedAndReturn
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
;
;.loc_165C7A:
;	or	byte [ebx+ebp], 80h
;	mov	ax, word [esi+veh.currorder]
;	and	al, 1Fh
;	cmp	al, 2
;	jz	short .loc_165C8E
;	mov	word [esi+veh.currorder], 0
;
;.loc_165C8E:
;	call	RVStartSound
;	mov	bx, word [esi+veh.idx]
;	mov	ax, 0x48D ;cWinTypeVehicle or cWinElemRel or cWinElem4
;	call	[RefreshWindows]		; AL = window type
;					; AH = element idx (only if AL:7 set)
;					; BX = window ID (only if AL:6 clear)
;	pop	ax

.JustMoveIntoNextTile:
	movzx	ebp, word [esi+veh.XY]
	call	[VehEnterLeaveTile]
	or	ebp, ebp
	js	near .zeroSpeedAndReturn
	test	ebp, 40000000h
	jnz	short .dontIncrementBlockedCount
	inc	byte [esi+veh.RVCurTilePos]

.dontIncrementBlockedCount:
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[RedrawRoadVehicle]
;--------------------------------------------------
;	NONE OF THIS...we can't have trailers
;	slowing down!
;--------------------------------------------------
;	call	[RVMountainSpeedManagement]
;--------------------------------------------------

.justQUIT:
	retn
;--------------------------------------------------

.CallPathfinderForNewTile:
	and	edx, 3
	mov	byte [byte_11258E], dl			;seems to be a temp location for dl... which is the new movement stat?
	movzx	edi, word [esi+veh.XY]
	push	ebx
	mov	ebx, dword [word_11257A]
	add	di, [ebx+edx*2]
	pop	ebx
	push	di
	call	[RoadVehiclePathFinder]
	pop	di

;----------------------------------------------------------------
;	Let us call the procedure I've written to
;	get the parent movement... there is a maximum
;	of 2 parent movements buffered in the
;	trailers veh structure.
;----------------------------------------------------------------
	call getParentMovement
;----------------------------------------------------------------

;	push	esi
;	mov	esi, dword [ParentIDX]
;	cmp	byte [esi+0x6A], 0
;	pop	esi
;	jne	.dontAdjustMovementStat
;	push	cx
;	mov	cl, byte [esi+veh.parentmvstat]
;	cmp	cl, 0xFE
;	pop	cx
;	je	.dontAdjustMovementStat
;	cmp	byte [esi+veh.parentmvstat], 0xFF
;	je	.dontAdjustMovementStat
;	mov	dl, byte [esi+veh.parentmvstat]
;.dontAdjustMovementStat:

;----------------------------------------------------------------
;	We might end up removing this:
;----------------------------------------------------------------
;	bt	bx, dx
;	jb	near .zeroSpeedAndReturn
;----------------------------------------------------------------

.loopThisChunkAgain:
	mov	al, dl
	and	al, 7
	cmp	al, 6
	jb	short .dontMoveInXY
	movzx	edi, word [esi+veh.XY]			;we're u-turning, we want to keep the old tile

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
	call	[RVCheckCollisionWithRV]
	jb	.justQUIT
	call	[VehEnterLeaveTile]
;	push	esi
;	mov	esi, dword [ParentIDX]
;	cmp	byte [esi+0x6A], 0
;	pop	esi
;	je	.somewhere
;	movzx	ebp, word [ParentXY]
;.somewhere:
	or	ebp, ebp				;we can't move into the next tile
	js	near .checkForTunnelOrTryAgain
	push	ax
	push	ebx
	push	ebp
	mov	ah, byte [esi+veh.movementstat]
	cmp	ah, 20h					;station maneuver?
	jb	near .notEnteringStation
	cmp	ah, 30h
	jnb	near .notEnteringStation

;------------------------------------------------------
;WARNING.. WE DON'T WANT TO BE HERE!!!
;	int3
;------------------------------------------------------

	mov	dh, bl
	movzx	ebx, word [esi+veh.XY]
	mov	al, byte [landscape4(bx)]
	and	al, 0F0h
	cmp	al, 50h
	jnz	near .notEnteringStation
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
	jb	short .notEnteringStation
	cmp	al, 4Bh
	jnb	short .notEnteringStation
	mov	al, 1
	test	ah, 2
	jz	short .dontChangeALForBusStop
	shl	al, 1

.dontChangeALForBusStop:
	or	al, byte [ebx+station.busstop]
	and	al, 7Fh; not 80h
	mov	byte [ebx+station.busstop], al
	jmp	short .notEnteringStation
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.stopVehicleEntirely:
	pop	ebp
	pop	ebx
	pop	ax
.QuitSetSpeedZero:
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

.notEnteringStation:
	pop	ebp
	pop	ebx
	pop	ax
	test	ebp, 40000000h
	jnz	short .dontActuallyMoveVehicle		;something failed and we can't use this move.
	mov	word [esi+veh.XY], bp
	mov	byte [esi+veh.movementstat], bl
	call	cycleMovementStats
	mov	byte [esi+veh.RVCurTilePos], 0

.dontActuallyMoveVehicle:
	cmp	dl, byte [esi+veh.direction]
	jz	short .weAreNotTurning
	mov	byte [esi+veh.direction], dl		;change direction
;	mov	bp, word [esi+veh.speed]		;slow down
;	shr	bp, 2					;slow down
;	sub	word [esi+veh.speed], bp		;slow down

.weAreNotTurning:
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	jmp	[RedrawRoadVehicle]
;--------------------------------------------------
;	no slow!
;--------------------------------------------------
;	jmp	[RVMountainSpeedManagement]
;--------------------------------------------------
; AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA

.checkForTunnelOrTryAgain:
	movzx	ebp, bp
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
	movzx	edi, word [esi+veh.XY]
	push	di
	call	[RoadVehiclePathFinder]
	pop	di

;----------------------------------------------------------------
;	Let us call the procedure I've written to
;	get the parent movement... there is a maximum
;	of 2 parent movements buffered in the
;	trailers veh structure.
;----------------------------------------------------------------
	call	getParentMovement
	call	cycleMovementStats
;----------------------------------------------------------------

	bt	bx, dx
	jb	near .zeroSpeedAndReturn
	and	edx, 0FFh
	add	dl, byte [roadtrafficside]
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
	add	al, [ebx+2]
	add	cl, [ebx+3]
	mov	bl, dl
	and	bl, 0EFh
	push	bx
	call	[LimitTurnToFortyFiveDegrees]
	pop	bx
	call	[RVCheckCollisionWithRV]
	jb	.justQUIT
	call	[VehEnterLeaveTile]
	or	ebp, ebp
	js	short .zeroSpeedAndReturn
	mov	byte [esi+veh.movementstat], bl
	
	mov	byte [esi+veh.RVCurTilePos], 1
	cmp	dl, byte [esi+veh.direction]
	jz	short .skipTurnCode
	mov	byte [esi+veh.direction], dl
;	mov	bp, word [esi+veh.speed]			; slow speed, we've turned.
;	shr	bp, 2
;	sub	word [esi+veh.speed], bp


.skipTurnCode:
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	jmp	[RedrawRoadVehicle]
;--------------------------------------------------
;	and again
;--------------------------------------------------
;	jmp	[RVMountainSpeedManagement]
;--------------------------------------------------

;-----------------------------------------------------------
.zeroSpeedAndReturn:
	mov	word [esi+veh.speed], 0
	retn
;-----------------------------------------------------------

.rvInTunnel:
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
	cmp	dl, 90h				;IS THIS A tunnel/bridge?
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
	cmp byte [edi+veh.movementstat], 0xFE
	je .QuitSetSpeedZero
	mov	word [esi+veh.speed], 0			;exit depot
	movzx	edi, word [esi+veh.XY]
	mov	bl, byte [landscape5(di,1)]
	and	ebx, 3
	mov	dl, byte [unk_1125DB+ebx]		;Direction to leave depot
	mov	byte [esi+veh.direction], dl		;set vehicles direction
	mov	bl, byte [unk_1125D7+ebx]		;next movementstat after depot

;------------------------------------------------------------
;	Damage: we need to set the movementstat
;	to whatever the parents is. 
;	...unless it's nothing.
;------------------------------------------------------------
	cmp	byte [esi+veh.parentmvstat], 0xFF
	je	.dontDoIt

	push	dx
	call	getParentMovement			;possibly overwrite
	mov	bl, dl
	pop	dx
.dontDoIt:
;------------------------------------------------------------

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
;	call	[RVStartSound]				;DON'T make noise.
	and	byte [roadtrafficside], 7Fh		;stop the user from being able to change config
	push	ax
	call	[SetCurrentVehicleBBox]
	pop	ax
	and	word [esi+veh.vehstatus], 0FFFEh		;set visible
	mov	byte [esi+veh.movementstat], bl
	call	cycleMovementStats
	mov	byte [esi+veh.RVCurTilePos], 6			;set the current location in current tile
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[RedrawRoadVehicle]
	mov	al, cWinTypeDepot
	mov	bx, word [esi+veh.XY]
	call	[RefreshWindows]
	retn

global cycleMovementStats
cycleMovementStats:
	cmp	byte [esi+veh.parentmvstat], 0xFF
	jne	.allRight
	cmp	byte [esi+veh.movementstat], 0xFE
	jne	.damage
	retn
;-----------------------------------------------
;	we couldn't get a movementstat!?!
;-----------------------------------------------
.damage:
;	int3
	retn
;-----------------------------------------------
.allRight:
	push	edx
	mov	dl, byte [esi+veh.parentmvstat]	;get the next movement
	mov	dh, byte [esi+veh.parentmvstat2]	;shuffle the next next movement down
	mov	byte [esi+veh.parentmvstat2], 0xFF	;zero the register.
	mov	byte [esi+veh.parentmvstat], dh	;shift next next into next
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;check for trailers.
	je	.noTrailer
	push	eax
	mov	eax, esi
;.loopTrailers:
	movzx	eax, word [eax+veh.nextunitidx]
	shl	eax, 7
	add	eax, [veharrayptr]
	cmp	byte [eax+veh.parentmvstat], 0xFF
	jne	.shiftIntoUpper
	mov	byte [eax+veh.parentmvstat], dl
	mov	byte [eax+veh.parentmvstat2], dh
	jmp	.shifted
.shiftIntoUpper:
	cmp	byte [eax+veh.parentmvstat2], 0xFF
	jne	.busted
	mov	byte [eax+veh.parentmvstat2], dl
	jmp	.shifted
.busted:
;	int3
;	danger zone.
;	we've tried to move in a movementstat... but we have none in the cache.
;	this means we've incorrectly used one... or need another byte to store another
;	stat.
.shifted:
	pop	eax
.noTrailer:
	pop	edx
	retn

global	getParentMovement
getParentMovement:
	cmp	byte [esi+veh.parentmvstat], 0xFF
	je	.dontTouchy
	movzx	dx, byte [esi+veh.parentmvstat]	;get the next movement
;	mov	dh, byte [esi+veh.parentmvstat2] ;shuffle the next next movement down
;	mov	byte [esi+veh.parentmvstat2], 0xFF ;zero the register.
;	mov	byte [esi+veh.parentmvstat], dh	;shift next next into next
;	and	dx, 0x0F				;remove dh (next next)
.dontTouchy:
	retn

global rvdailyprocoverride
rvdailyprocoverride:
	push	eax
	mov	ax, [edi+veh.engineidx]
	cmp	ax, [edi+veh.idx]
	pop	eax
	jne	.skipRVDailyProc
	call	[oldrvdailyproc]
.skipRVDailyProc:
	retn

global dontLetARVsInNormalRVStops
// A bit better code (fragment position has changed!,
// so it doesn't depend on goto depot)
// --Oskar
// in: edi = station ptr
//	 esi = vehicle ptr
//	 ah = facilities type needed, 1=rail, 2=lorry, 4=bus, 8=air, 0x10=dock
//	 al = vehicle class
//	 facilities check already done
dontLetARVsInNormalRVStops:
	jecxz .done	//depot
	cmp word [esi+veh.nextunitidx], 0xFFFF
	je .done		// no following vehicle
	cmp al, 0x11	// following vehicle, are we a road vehicle with a trailer?
	je .roadveh
.done:
	mov ax, word [esi+veh.xpos]	// overwritten
	mov cx, word [esi+veh.ypos]	// overwritten
	ret
.roadveh:
	movzx ecx, word [edi+station.busXY]
	cmp ah, 4
	je .isbus
	mov cx, word [edi+station.lorryXY]
.isbus:
	cmp cx, 0	// the station has the facility but no tile in the landscape, should never happen, test anyway
	je .fail

	cmp byte [landscape5(cx,1)], 0x53
	jae .done	// no stop type, do normal code
.fail:
	add esp, 4
	pop esi
	ret

uvarw lastVehicleShortness,1,s
global drawAllTrailersInRVList
drawAllTrailersInRVList:
	add	dx, 6
	push	edi
	call	drawRVWithTrailers
	pop	edi
	retn

global RVDepotScrXYtoVehSkipTrailers
RVDepotScrXYtoVehSkipTrailers:
	add	edi, 80h				//overwritten
	push	ebx
	movzx	ebx, word [edi+veh.engineidx]
	cmp	bx, word [edi+veh.idx]
	pop	ebx
	jne	RVDepotScrXYtoVehSkipTrailers		//trailer? add another vehicle.
	retn

global drawRVWithTrailersInInfoWindow
drawRVWithTrailersInInfoWindow:
	push	cx
	push	dx
	push	edi
	call	drawRVWithTrailers
	pop	edi
	pop	dx
	pop	cx
	add	dx, 14			//shift down information text!
	retn

global drawRVWithTrailers
drawRVWithTrailers:
	call	[DrawRVImageInWindow]
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	je	.noMoreTrailers
	movzx	edi, word [edi+veh.nextunitidx]
	shl	edi, 7
	add	edi, [veharrayptr]
	xchg	esi, edi
	sub	cx, word [lastVehicleShortness]	//we want to use the _last_ vehicles shortness... not this ones.
	mov	al, 0x11
	call	vehcallback
	imul	ax, 4
	mov	word [lastVehicleShortness], ax
.notshortened:
	add	cx, 0x1C				//What is the standard length for an RV?
	xchg	edi, esi
	jmp	drawRVWithTrailers
.noMoreTrailers:
	mov	word [lastVehicleShortness], 0
	retn

uvard tmpEDI
global drawTotalCapacityForTrailers
drawTotalCapacityForTrailers:
	;articulated?
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	jne	.thisIsArticulated
	mov	edi, [currscreenupdateblock]
	jmp	[drawtextfn]

.thisIsArticulated:
	push	eax
	push	ecx
	push	ebx
	push	edi
.loopTrailers:
	movzx	ebx, byte [edi+veh.cargotype]		//grab the current cargo type
	movzx	eax, word [edi+veh.capacity]		//grab the current load
	add	word [cargosum+ebx*2], ax		//add the load to the cargosum array
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	je	short .noMoreTrailers
	movzx	edi, word [edi+veh.nextunitidx]		//iterate to next trailer
	shl	edi, 7
	add	edi, [veharrayptr]
	jmp	short .loopTrailers
.noMoreTrailers:					//done.
	pop	edi
	pop	ebx

	xor	ecx,ecx				//ecx will be the cargosum index
	mov	edi, cargotextbuffer
	mov 	dword [specialtext1], edi
.loopCargo:
	cmp	word [cargosum+ecx*2], 0		//check if this cargo has a positive value
	je	.tryNextCargo

	// Append some special sequence to the buffer that will print the cargo amount
	// This will use 9 bytes per cargo type
	cmp	edi, cargotextbuffer+cargotextbuffer_size-9
	jae	.bufferFull

	mov	word [edi], 0x039a		// push word to reference stack
	mov	ax, [cargosum+ecx*2]
	mov	[edi+2], ax
	add	edi, 4

	mov	ebx, ecx
	call	movbxcargoamountname2
	mov	byte [edi],0x81			// print textID from next word
	mov	[edi+1],bx
	add	edi,3

	mov word [edi], ', '		//add comma
	add edi, 2

	mov	word [cargosum+ecx*2], 0		//zero the cargo sum once it has been
							//thrown in the text handler
.tryNextCargo:
	inc	ecx
	cmp	ecx, 32
	jb	.loopCargo

.bufferFull:
	pop	ecx
	pop	eax

	mov	bx, 0x8812
	cmp	edi, [specialtext1]
	je	.drawString				// no capacity
	mov     byte [edi-2], 0				//remove last comma and null-terminate
	mov	word [textrefstack], statictext(special1)	//our newly created string
	mov	bx, 0x9012
.drawString:
	mov	bp, 0x150
	mov	edi, [currscreenupdateblock]			//area to be drawn to
	call	[drawsplittextfn]				//draw it!
	retn

uvarw	cargosum,32
uvarb	cargosource,32,s
cargotextbuffer_size equ 256
uvarb	cargotextbuffer,cargotextbuffer_size
global listAdditionalTrailerCargo
listAdditionalTrailerCargo:
	;articulated?
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	jne	.thisIsArticulated
	mov	edi, [currscreenupdateblock]
	jmp	[drawtextfn]

.thisIsArticulated:
	push	eax
	push	ecx
	push	ebx
	push	edi
.loopTrailers:
	movzx	ebx, byte [edi+veh.cargotype]		//grab the current cargo type
	movzx	eax, word [edi+veh.currentload]		//grab the current load
	add	word [cargosum+ebx*2], ax		//add the load to the cargosum array
	test	eax,eax
	jz	.empty					//if this vehicle is empty, ignore the cargo source
	movzx	eax, byte [edi+veh.cargosource]
	mov	[cargosource+ebx], al			//it doesnt, move in the source
.empty:
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	je	short .noMoreTrailers
	movzx	edi, word [edi+veh.nextunitidx]		//iterate to next trailer
	shl	edi, 7
	add	edi, [veharrayptr]
	jmp	short .loopTrailers
.noMoreTrailers:					//done.
	pop	edi
	pop	ebx

	xor	ecx,ecx				//ecx will be the cargosum index
	mov	edi, cargotextbuffer
	mov 	dword [specialtext1], edi
.loopCargo:
	cmp	word [cargosum+ecx*2], 0		//check if this cargo has a positive value
	je	.tryNextCargo

	// Append some special sequence to the buffer that will print the cargo amount and destination
	// This will use 21 bytes per cargo type
	cmp	edi, cargotextbuffer+cargotextbuffer_size-21
	jae	.bufferFull

	// This is rather tricky -- the text ref. stack isn't big enough to hold all the required data,
	// so we fill it as we go, with special "push" string codes. We need four words per element:
	// the first is the cargo amount textId, the second is the amount itself, the third is a fixed text
	// (consumed by ID 8813 as the source station), the fourth is the ID of the station
	// (assembling the station name itself is done via a special string code).
	// Since we're working on a stack, the item that gets used last needs to be pushed first.

	mov	word [edi], 0x039a	 		// push station id to reference stack
	movzx	ax, byte [cargosource+ecx]
	mov	[edi+2],ax
	add	edi, 4

	mov	dword [edi], 0x039a | (statictext(outstation)<<16)	// push a fixed static text to ref.stack
	add	edi, 4

	mov	word [edi], 0x039a	 		// push cargo amount to reference stack
	mov	ax, [cargosum+ecx*2]
	mov	[edi+2],ax
	add	edi,4

	mov	word [edi], 0x039a	 		// push cargo type text to reference stack
	mov	ebx, ecx
	call	movbxcargoamountname2
	mov	[edi+2],bx
	add	edi,4

	mov	dword [edi], 0x881381			// print textId 8813
	add	edi,3

	mov	word [edi], ', '
	add	edi, 2

	mov	word [cargosum+ecx*2], 0		//zero the cargo sum once it has been
							//thrown in the text handler
.tryNextCargo:
	inc	ecx
	cmp	ecx, 32
	jb	.loopCargo

.bufferFull:
	pop	ecx
	pop	eax

	mov	bx, 0x8812
	cmp	edi, [specialtext1]
	je	.drawString
	mov     byte [edi-2], 0
	mov	bx, statictext(special1)
.drawString:
	mov	bp, 0x150
	add	dx, 10
	;and then call: DrawTextSplitLines instead
	;with BP being the width of the lines...
	mov	edi, [currscreenupdateblock]			//area to be drawn to
	call	[drawsplittextfn]				//draw it!
	retn

global relocateServiceString
relocateServiceString:
	add	cx, 13
	add	dx, 138
	retn

global changePtrToParentVehicleIfTrailer
changePtrToParentVehicleIfTrailer:
	mov	edi, dword [rvCollisionFoundVehicle]		//overwritten
	mov	edi, [edi]
	push	ebx
	movzx	ebx, word [esi+veh.engineidx]
	cmp	bx, word [esi+veh.idx]
	pop	ebx
	jne	.dontAdjustPtr					//it's a trailer, don't change anything
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	jne	.dontAdjustPtr					//it's a trailer, don't change anything
	push	ebx
	movzx	ebx, word [edi+veh.engineidx]
	cmp	bx, word [edi+veh.idx]
	pop	ebx
	je	.dontAdjustPtr					//it's trying to overtake an engine, don't adjust
	movzx	edi, word [edi+veh.engineidx]			//trying to overtake trailer, shift in parent.
	shl	edi, 7
	add	edi, [veharrayptr]
.dontAdjustPtr:
	retn

global cancelBlockIfArticulated
cancelBlockIfArticulated:
	push	edi
	mov	edi, dword [rvCollisionFoundVehicle]		//overwritten
	mov	dword [edi], 0
	pop	edi
	call	[searchcollidingvehs]
	push	edi
	mov	edi, dword [movingVehicle]
	mov	edi, [edi]
	push	ebx
	movzx	ebx, word [edi+veh.engineidx]
	cmp	bx, word [edi+veh.idx]
	pop	ebx
	jne	.dontTouchTrailer
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	jne	.dontTouchTrailer
	pop	edi
	push	edi
	push	esi
	mov	esi, dword [cacheFoundVehicle]
	mov	esi, [esi]
	movzx	esi, word [esi+veh.engineidx]
	mov	edi, dword [rvCollisionFoundVehicle]
	mov	edi, [edi]
	cmp	edi, 0
	jle	.dontZeroFoundVehicle
	cmp	si, word [edi+veh.engineidx]
	jne	.dontZeroFoundVehicle
	mov	edi, dword [rvCollisionFoundVehicle]
	mov	dword [edi], 0
.dontZeroFoundVehicle:
	pop	esi
.dontTouchTrailer:
	pop	edi
	retn

global sendTrailersToDepot
sendTrailersToDepot:
	mov	al, 0C2h
	mov	word [esi+veh.currorder], ax
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	je	.noTrailers
	push esi
.loopTrailers:
	movzx	esi, word [esi+veh.nextunitidx]		//iterate to next trailer
	shl	esi, 7
	add	esi, [veharrayptr]
	mov	word [esi+veh.currorder], ax
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	jne	.loopTrailers
	pop	esi
.noTrailers:
	retn

/************************************************
 * Now we only need move when we know the head	*
 * will move so we can move the trailer		*
 ************************************************/
//Input:	esi - trailer id
//		dl - clock cycle move (value 1)
//		ebp - consist head pointer
//Output:	CF - Move now (set)
//		[Since its set basicly from dl, it is almost completely predictable]
global RVMovementIncrement
RVMovementIncrement:
	clc
	cmp	byte [esi+veh.movementstat], 0xFE
	jne	.checkMovementFract
	stc
	retn

/* This applies the CLOCK for the (SYNC'ED) consist */
.checkMovementFract:
	or dl, dl				// Are we going to be moving?
	jz .dontAdjustFract
	mov ax, word [ebp+veh.speed]		// We need the change to move at the
						// same speed otherwise it will break up
	mov word [esi+veh.speed], ax		// set the consist's head's current speed
	stc
.dontAdjustFract:				// Since the head moved happily we can move
	retn

/************************************************
 * Generates the CLOCK for a Road Vehicle, not	*
 * too important for a single unit RV but for	*
 * aRVs this is essential for keeping the	*
 * consist together (SYNCED), there MUST be a	*
 * working head pointer cycle for a consist to	*
 * work correctly on any movement change!	*
 ************************************************/
// Input:	esi - parent pointer
// Output:	ebp - consist head pointer
//		CF - Move now (set)
global setTrailerMovementFlags
setTrailerMovementFlags:
	push esi // Push this for the function, as it holds the head to generate the flag
	cmp word [esi+veh.nextunitidx], 0xFFFF // Single unit then only one head possible
	je .JustCallFunction

	// If the head is stopped do not move (similar to how train consists work)
	bt word [esi+veh.vehstatus], 1
	jc .JustFail

.NextUnit:
	cmp byte [esi+veh.movementstat], 0xFE // Is this unit 'free'?
	jne .JustCallFunction

	cmp word [esi+veh.nextunitidx], byte -1 // Consist End?
	je .FoundNoNewHead

	movzx esi, word [esi+veh.nextunitidx]
	shl esi, 7
	add esi, [veharrayptr]
	jmp .NextUnit

.FoundNoNewHead:
	mov esi, [esp] // Restore it to the parent

.JustCallFunction: // Right now call the orginal sub to generate the flags
	call	near $
ovar .origfn, -4, $, setTrailerMovementFlags
	mov ebp, esi // Allow us to use this new head for trailer speed
	pop esi
	ret

.JustFail:
	clc
	pop esi
	ret

/************************************************
 * -Quickly put together in a WLM conversation-	*
 * Should stop a head leaving if its trailers	*
 * have not all got inside the depot.		*
 ************************************************/
//Input:	esi - Vehicle (Parent) idx
//Output:	CF - Continue (set), Abort (not set)
global DontStartParentIfTrailersMoving
DontStartParentIfTrailersMoving:
	mov word [esi+veh.speed], 0
	cmp word [esi+veh.nextunitidx], 0xFFFF
	je .noTrailers

	push esi

.nexttrailer:
	movzx esi, word [esi+veh.nextunitidx]
	shl esi, 7
	add esi, [veharrayptr]

	cmp byte [esi+veh.movementstat], 0xFE // Is it in the depot?
	jne .waitfortrailers
.nexttrailercheck:
	cmp word [esi+veh.nextunitidx], byte -1
	jne .nexttrailer
	pop esi

.noTrailers:
	mov di, word [esi+veh.XY]
	stc
	retn

.waitfortrailers:
	push edi
	mov edi, esi
	mov esi, [esp+4]
	call HeadInDepotCheckTrailerDecoupledAndRepair
	mov esi, edi
	pop edi
	//jnc .nexttrailercheck
	and BYTE [esi+veh.vehstatus], ~2	//unstop vehicle
	pop esi
	clc // Fail, to let the trailers enter
	ret

/************************************************
 * Unsets the stop flag if all the trailers	*
 * haven't entered the depot.			*
 ************************************************/
//Output:	ZF - Finnished (unset)
global RVDepotEnterStop
RVDepotEnterStop:
	push edi
	movzx edi, word [edi+veh.engineidx]	// We are only interested in the head to start with
						// As this will be the first unit in the depot
	push esi


	shl edi, 7
	add edi, [veharrayptr]
	mov esi, edi				// Store this as the parent for quick access later

.Next:
	cmp byte [edi+veh.movementstat], 0xFE	// Is this unit in the Depot
	jne .Wait

	cmp word [edi+veh.nextunitidx], byte -1	// Is this the end of the consist?
	je .End
	movzx edi, word [edi+veh.nextunitidx]
	shl edi, 7
	add edi, [veharrayptr]
	jmp .Next

.End:
						// We only set the flag and checks things on the parent
	or word [esi+veh.vehstatus], 2		// This vehicle IS stopped
	push ax
	push bx
	mov al, 0x0D				// Update the window to show it has stopped
	mov bx, [esi+veh.engineidx]
	call [RefreshWindows]
	pop bx
	pop ax

	mov al, [human1]			// Should we give a message to the player only works
	cmp al, [edi+veh.owner]			// for the human player on the local machine

	pop esi
	pop edi
	ret

.Wait:
	call HeadInDepotCheckTrailerDecoupledAndRepair
	jnc .Next
					// We only set the flag and checks things on the parent
	and word [esi+veh.vehstatus], ~2	// This vehicle is NOT stopped

	test al, 2				// Zero MUST be cleared for the head to wait
	pop esi
	pop edi
	ret

//esi=head, edi=trailer in question
//return stc if OK, clc if trailer relocated
HeadInDepotCheckTrailerDecoupledAndRepair:
	cmp edi, esi
	je .normalwait
	pusha
//	cmp BYTE [edi+veh.parentmvstat], 0xFF
//	je .forceemergencytrailerteleport
	mov ax, [esi+veh.XY]
	movzx ecx, ax
	movzx edx, WORD [edi+veh.XY]
	sub ax, dx 
	add ax, 0x101				//trailers outside the immediate 9 tile region of the depot are considered bad
	cmp al, 2
	ja .forceemergencytrailerteleport
	cmp ah, 2
	ja .forceemergencytrailerteleport
	or ax, ax
	jnz .rigorouscheck
.p_normalwait:
	popa
.normalwait:
	stc
	ret
.rigorouscheck:
	mov bl, [landscape5(cx,1)]
	test bl, 0x20
	jz .p_normalwait
	and ebx, BYTE 3
	movzx ebp, WORD [tiledeltas+ebx*2]
	add ebp, ecx
	cmp ebp, edx
	je .p_normalwait
	
//fall through
	

.forceemergencytrailerteleport:
	mov bp, [esi+veh.XY]
	mov [edi+veh.XY], bp
	mov ax, [esi+veh.xpos]
	mov [edi+veh.xpos], ax
	mov cx, [esi+veh.ypos]
	mov [edi+veh.ypos], cx
	mov dl, [esi+veh.zpos]
	mov [edi+veh.zpos], dl
	//begins copy n' pasted code from buy trailer
	mov byte [edi+veh.direction], 0
	mov byte [edi+veh.movementstat], 0FEh
	mov word [edi+veh.vehstatus], 0Bh
	mov word [edi+veh.currorder], 0
	mov word [edi+veh.loadtime], 0
	mov byte [edi+veh.movementfract], 0
	mov word [edi+0x64], 0
	mov byte [edi+0x66], 0
	mov word [edi+0x6A], 0
	mov byte [edi+veh.laststation], -1
	mov word [edi+veh.target], 0FFFFh
	mov dword [edi+veh.profit], 0
	mov dword [edi+veh.previousprofit], 0
	mov word [edi+veh.reliability], 0
	mov word [edi+veh.reliabilityspeed], 0
	mov word [edi+veh.maxage], 0
	mov word [edi+veh.name], 0x902B ; TID902B_RoadVehicleW
	mov byte [edi+0x68], 0
	mov byte [edi+veh.currorderidx], 0
	mov byte [edi+veh.totalorders], 0
	mov word [edi+veh.lastmaintenance], 0
	mov word [edi+veh.serviceinterval], 0
	mov byte [edi+veh.breakdowncountdown], 0
	mov byte [edi+veh.breakdowns], 0
	mov byte [edi+veh.breakdownthreshold], 0
	//ends copy n' pasted code
	popa
	clc
	ret

/************************************************
 * Holds a load of hacks which attempt to find	*
 * and correct the result, really need Steven	*
 * to fix real collision detection patch!	*
 ************************************************/
AttemptToCorrectConflictDetection:
	push edi

/************************************************
 * On corners the head will count trip the	*
 * Collision code as it tries to leave the	*
 * Corner, causing it to fall behind, so we	*
 * check if the direction of the head (edi) is	*
 * the same as the head if not we are turning!	*
 ************************************************/ 

// Need to find the unit just infront for this check
	mov bp, [esi+veh.idx] // Store our idx for checks
	mov dh, byte [esi+veh.direction] // Yes, is it at a different angle?

.lNextUnit:
	cmp bp, [edi+veh.nextunitidx] // Is this the unit directly infront
	jne .lGetNextUnit

	cmp dh, [edi+veh.direction] // Are they facing different directions (turn)
	jne .lNoConflict // Yes so complete the turn!

.lGetNextUnit:
	cmp word [edi+veh.nextunitidx], byte -1 // End of Consist?
	je .lNotTurning

	movzx edi, word [edi+veh.nextunitidx] // No so get next unit and repeat
	shl edi, 7
	add edi, [veharrayptr]	
	jmp .lNextUnit

.lNotTurning:

/************************************************
 * Seems that when entering a depot a shorter	*
 * rv will fail collision detection and stop	*
 * Dead causing the consist to halt.		*
 ************************************************/
	movzx edi, word [edi+veh.engineidx]
	shl edi, 7
	add edi, [veharrayptr]
	cmp byte [edi+veh.movementstat], 0xFE
	je .lNoConflict

	pop edi
	stc
	ret

.lNoConflict:
	pop edi
	clc
	ret

// Called to change the status of a road vehicle to crashed
// The old code handles the head vehicle only, make sure we update every vehicle of the consist in the new code
// in:	esi->vehicle that collided
// safe: everything but esi
exported rvcrash_makecrashed
	movzx edi, word [esi+veh.engineidx]
	shl edi, 7
	add edi, [veharrayptr]

	mov eax, edi
.next:
	inc word [eax+0x68]
	or byte [eax+veh.vehstatus], 0x80
	movzx eax, word [eax+veh.nextunitidx]
	cmp ax, 0xFFFF
	je .done
	shl eax, 7
	add eax, [veharrayptr]
	jmp short .next

.done:
	ret

// Called to remove all cargo from a road vehicle after a crash and to count the victims of the crash
// in:	esi->vehicle that collided
//	edi->engine of the crashed consist, kept from rvcrash_makecrashed
// out:	cx: total victim count (don't forget to add 1 for the driver)
// safe: everything but esi
exported rvcrash_handlecargo
	mov cx, 1
.next:
	xchg esi, edi
	call isrvbus
	xchg esi, edi
	jnz .nonhuman
	add cx, [edi+veh.currentload]
.nonhuman:
	and word [edi+veh.currentload], 0
	movzx edi, word [edi+veh.nextunitidx]
	cmp di, 0xFFFF
	je .done
	shl edi, 7
	add edi, [veharrayptr]
	jmp short .next

.done:
	ret

// The same as rvcrash_makecrashed, but this one is called when a small UFO destroys the vehicle
// in:	esi->the UFO
//	edi->the vehicle destroyed by the UFO
// safe: ebx, ???
exported smallufo_makecrashed
	movzx ebx, word [edi+veh.engineidx]
	shl ebx, 7
	add ebx, [veharrayptr]

.next:
	inc word [ebx+0x68]
	or byte [ebx+veh.vehstatus], 0x80
	movzx ebx, word [ebx+veh.nextunitidx]
	cmp bx, 0xFFFF
	je .done
	shl ebx, 7
	add ebx, [veharrayptr]
	jmp short .next

.done:
	ret
