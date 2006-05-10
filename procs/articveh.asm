//---------------------START HEADER--------------------------------
//Welcome to the procs of road vehicle articulation......
///_attemped_ by Steven Hoefel... stevenhoefel@hotmail.com

//tasks:
//hack build vehicle to create the trailers
//hack buynewrailvehicle to work with road vehicles
//-----------------notez0rz---------from the man himself------------------
//[15:22] <patchman> afaict the only changes you need to make in that proc:
//[15:22] <patchman> - skip the checknewtrainisengine2 check
//[15:23] <patchman> - call oldbuyroadvehicle instead of oldbuyrailvehicle (you need to defined it first)
//[15:23] <patchman> - change traincallbackflags to rvcallbackflags
//[15:23] <patchman> (all of the above conditionally on whether you're building RVs or trains, of course)
//------------------------------------------------------------------------

//more notez0rz
//-nextunitidx tells you the next trailer.
//-engineidx = the parent/engine (or == idx if this _is_ the parent)
//-[shl idx, 7 + veharrayptr] == vehstruc
//-veh+06Fh = nextturn.
//-[15:40] <patchman> just change the "resb 0x70-$" line to 6F and then do a resb for your variable after it

//----------------------END HEADER--------------------------------


#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <textdef.inc>
#include <misc.inc>
#include <vehtype.inc>

extern oldbuyroadvehicle, newbuyroadvehicle, oldchoosevehmove
extern rvTmpXCollision, rvTmpYCollision
extern JumpOutOfRVRVCollision
extern callRVProcOnTrailers, callRVProcOnTrailers.origfn
extern rvCollisionFoundVehicle, rvCollisionCurrVehicle
extern dontOpenRVWindowForTrailer, dontOpenRVWindowForTrailer.origfn
extern OpenRVWindow
extern skipTrailersInDepotWindow, skipTrailersInRVList
extern dontAddScheduleForTrailers
extern sellRVTrailers, sellRVTrailers.origfn, delveharrayentry
extern updateTrailerPosAfterRVProc, updateTrailerPosAfterRVProc.origfn
extern turnTrailersAroundToo

extern ScrewWithRVDirection, UpdateRVPos, SetRoadVehObjectOffsets, SelectRVSpriteByLoad, SetCurrentVehicleBBox, off_111D62

patchproc articulatedrvs, patcharticulatedvehicles

begincodefragments
	codefragment oldSetMovementStat
		mov	byte [esi+veh.movementstat], bl
		mov	byte [esi+veh.targetairport], 0

	codefragment newSetMovementStat
		icall	grabMovementFromParentIfTrailer1
		nop

	codefragment oldSetMovementStat2
		mov	byte [esi+veh.movementstat], bl
		mov	byte [esi+veh.targetairport], 1

	codefragment newSetMovementStat2
		icall	grabMovementFromParentIfTrailer2
		nop

	codefragment oldSetMovementStat3
		mov	byte [esi+veh.movementstat], bl
		mov	byte [esi+veh.targetairport], 6

	codefragment newSetMovementStat3
		icall	grabMovementFromParentIfTrailer3
		nop

	codefragment oldRVCollisionCheck, -6
		pop     ebp
		pop     edi
		pop     dx
		pop     cx
		pop     ebx
		pop     ax
		retn

	codefragment newRVCollisionCheck
		icall	checkIfTrailerAndCancelCollision

	codefragment oldRVCollisionCheck2, 11
		push    ax
		push    ebx
		push    cx
		push    dx
		push    edi
		push    ebp

	reusecodefragment oldRVCollisionCheck3, oldRVCollisionCheck2, 24

	codefragment startTrailerInDepot
		icall	checkIfTrailerAndStartInDepot

	codefragment oldIncrementRVSpeed
		mov	bx, word [esi+veh.maxspeed]
		cmp	ax, bx

	codefragment newIncrementRVSpeed
		icall	setTrailerToMax
		nop

	codefragment oldOpenRVWindow
		mov	cl, 0Dh
		mov	dx, [edi+veh.idx]

	codefragment newOpenRVWindow
		icall	dontOpenRVWindowForTrailer


	codefragment oldListRVsInDepotWindow, 23
		add     dx, 15
		cmp     byte [edi+veh.class], 11h

	codefragment newListRVsInDepotWindow
		icall	skipTrailersInDepotWindow
		setfragmentsize 8

	codefragment oldAddRVScheduleWhenBuilding, 6
		mov	ebx, dword [scheduleheapfree]
		add	dword [scheduleheapfree], 2

	codefragment newAddRVScheduleWhenBuilding
		icall	dontAddScheduleForTrailers
		setfragmentsize 15

	codefragment oldSellRoadVehicle, -5
		mov	al, 12h
		mov	bx, word [edx+veh.XY]

	codefragment oldRVCollisionTimeout
		cmp	word [esi+64h], 1480

	codefragment newRVCollisionTimeout
		setfragmentsize 8

	codefragment oldCallRVProcessing, 9
		retn
		push	edi
		mov	esi, edi

;----new shit to try and replicate RVProc
	codefragment findLimitTurnToFortyFiveDegrees, -12
		inc	dl
		and	dl, 7
	codefragment findRedrawRoadVehicle, 1
		retn
		push	bx
		mov	word [esi+veh.xpos], ax
	codefragment findSetRoadVehObjectOffsets
		push	ebx
		movzx	ebx, byte [esi+veh.direction]
	codefragment findSelectRVSpriteByLoad
		push	ax
		push	edi
		movzx	edi, byte [esi+veh.spritetype]
	codefragment findSetCurrentVehicleBBox, 1
		retn
		mov	ax, word [esi+0x2A]	;spritebox.x1
	codefragment findWhatIThinkIsMovementSchemes, -4
		movzx	edx, byte [esi+0x63]
	codefragment findGenerateFirstRVArrivesMessage
		and	eax, 0FFh
		imul	ax, 8Eh
	codefragment findTwoStationFunctionsInRVProcessing, -13
		and	al, 1Fh
		cmp	al, 4
	codefragment findIncrementRVMovementFrac
		mov	ax, word [esi+veh.speed]
		inc	ax
	codefragment findProcessCrashedRV
		inc	word [esi+0x68]
	codefragment findChkForCollisionWithTrain
		cmp	byte [esi+veh.movementstat], 0xFF
	codefragment findRVCheckCollisionWithRV
		cmp	byte [esi+0x6A], 0
	codefragment findbyte_112552
		db 0x14,0x14,0x10,0x10,0x00,0x00,0x00,0x00
	codefragment findRVMountainSpeedManagement, 1
		retn
		cmp	dl, byte [esi+veh.zpos]
endcodefragments

patcharticulatedvehicles:
	mov eax,[ophandler+0x11*8]		// class 11: road vehicles
	mov eax,[eax+0x10]			// 	action handler
	mov esi,[eax+9]			// 	action handler table

	mov eax,addr(newbuyroadvehicle)
	xchg eax,[esi]
	mov [oldbuyroadvehicle],eax

	patchcode oldSetMovementStat, newSetMovementStat, 1, 1
	patchcode oldSetMovementStat2, newSetMovementStat2, 1, 1
	patchcode oldSetMovementStat3, newSetMovementStat3, 1, 1

#if WINTTDX
	stringaddress oldRVCollisionCheck2, 1, 3
	mov	edi, [edi]
	mov	dword [rvCollisionCurrVehicle], edi
	patchcode oldRVCollisionCheck3, startTrailerInDepot, 1, 3
	storeaddress oldRVCollisionCheck, 1, 3, JumpOutOfRVRVCollision, 6
	stringaddress oldRVCollisionCheck, 1, 3
	mov	edi, [edi+2]
	mov	dword [rvCollisionFoundVehicle], edi
	patchcode oldRVCollisionCheck, newRVCollisionCheck, 1, 3
#else
	stringaddress oldRVCollisionCheck2, 2, 3
	mov	edi, [edi]
	mov	dword [rvCollisionCurrVehicle], edi
	patchcode oldRVCollisionCheck3, startTrailerInDepot, 2, 3
	storeaddress oldRVCollisionCheck, 2, 3, JumpOutOfRVRVCollision, 6
	stringaddress oldRVCollisionCheck, 2, 3
	mov	edi, [edi+2]
	mov	dword [rvCollisionFoundVehicle], edi
	patchcode oldRVCollisionCheck, newRVCollisionCheck, 2, 3
#endif

	patchcode oldIncrementRVSpeed, newIncrementRVSpeed, 1, 1	;deprecated.
	patchcode oldOpenRVWindow, newOpenRVWindow, 2, 4
	patchcode oldListRVsInDepotWindow, newListRVsInDepotWindow, 2, 2

;	patchcode oldAddRVScheduleWhenBuilding, newAddRVScheduleWhenBuilding, 2, 4
	stringaddress oldSellRoadVehicle, 2+WINTTDX, 5
	chainfunction sellRVTrailers, .origfn, 1

	patchcode oldRVCollisionTimeout, newRVCollisionTimeout, 1, 1

#if WINTTDX
	stringaddress oldCallRVProcessing, 1, 5
#else
	stringaddress oldCallRVProcessing, 3, 5
#endif
	chainfunction updateTrailerPosAfterRVProc, .origfn, 1

;------------new stuffs.
	stringaddress findLimitTurnToFortyFiveDegrees, 1, 1
	mov	[LimitTurnToFortyFiveDegrees], edi
	stringaddress findRedrawRoadVehicle, 2, 2
	mov	[RedrawRoadVehicle], edi
	stringaddress findSetRoadVehObjectOffsets, 1, 1
	mov	[SetRoadVehObjectOffsets], edi
	stringaddress findSelectRVSpriteByLoad, 2, 2
	mov	[SelectRVSpriteByLoad], edi
	stringaddress findSetCurrentVehicleBBox, 1, 2
	mov	[SetCurrentVehicleBBox], edi
	stringaddress findWhatIThinkIsMovementSchemes
	mov	edi, [edi]
	mov	dword [off_111D62], edi
	storeaddress findGenerateFirstRVArrivesMessage, 1, 1
	mov	dword [GenerateFirstRVArrivesMessage], edi
	storeaddress findTwoStationFunctionsInRVProcessing, 1, 1
	mov	dword [ProcessNextRVOrder], edi
	mov	edi, [edi+5]
	mov	dword [ProcessLoadUnload], edi
	storeaddress findIncrementRVMovementFrac, 1, 2
	mov	dword [IncrementRVMovementFrac], edi
	storeaddress findProcessCrashedRV, 2, 2
	mov	dword [ProcessCrashedRV], edi
	storeaddress findChkForCollisionWithTrain, 2, 2
	mov	dword [ChkForRVCollisionWithTrain], edi
	storeaddress findRVCheckCollisionWithRV, 3, 3
	mov	dword [RVCheckCollisionWithRV], edi
	storeaddress findbyte_112552, 1, 1
	mov	dword [byte_112552], edi
	storeaddress findRVMountainSpeedManagement, 2, 2
	mov	dword [RVMountainSpeedManagement], edi
	retn
