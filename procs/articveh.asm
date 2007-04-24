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
#include <town.inc>
#include <window.inc>
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
extern rvdailyprocoverride, oldrvdailyproc
extern dontLetARVsInNormalRVStops, decrementBHIfRVTrailer
extern changePtrToParentVehicleIfTrailer
extern rvcheckovertake, cacheFoundVehicle, movingVehicle
extern setTrailerMovementFlags,setTrailerMovementFlags.origfn

extern	RedrawRoadVehicle
extern	SetRoadVehObjectOffsets
extern	SelectRVSpriteByLoad
extern	SetCurrentVehicleBBox
extern	off_111D62
extern	byte_112552
extern	word_11257A
extern	unk_112582

extern GenerateFirstRVArrivesMessage
extern ProcessNextRVOrder
extern ProcessLoadUnload
extern IncrementRVMovementFrac
extern ProcessCrashedRV
;extern ProcessBrokenDownRV
extern ChkForRVCollisionWithTrain
extern RVCheckCollisionWithRV
extern RVMountainSpeedManagement
extern LimitTurnToFortyFiveDegrees
extern VehEnterLeaveTile
extern RVStartSound
extern RoadVehiclePathFinder
extern GetVehicleNewPos
extern UpdateVehicleSpriteBox
extern UpdateDirectionIfMovedTooFar

extern DrawRVImageInWindow

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
		pop	ebp
		pop	edi
		pop	dx
		pop	cx
		pop	ebx
		pop	ax
		retn

	codefragment newRVCollisionCheck
		icall	checkIfTrailerAndCancelCollision

	codefragment oldRVCollisionCheck2, 11
		push	ax
		push	ebx
		push	cx
		push	dx
		push	edi
		push	ebp

;	reusecodefragment oldRVCollisionCheck3, oldRVCollisionCheck2, 24
;
;	codefragment startTrailerInDepot
;		icall	checkIfTrailerAndStartInDepot

	codefragment oldOpenRVWindow
		mov	cl, 0Dh
		mov	dx, [edi+veh.idx]

	codefragment newOpenRVWindow
		icall	dontOpenRVWindowForTrailer


	codefragment oldListRVsInDepotWindow, 23
		add	dx, 15
		cmp	byte [edi+veh.class], 11h

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
	codefragment findProcessNextRVOrder, -10
		mov	al, byte [esi+veh.totalorders]
		cmp	al, byte [esi+veh.currorderidx]
	codefragment findProcessLoadUnload
		mov	ax, word [esi+veh.currorder]
		or	ax, ax
	codefragment findIncrementRVMovementFrac, -14
		mov	bx, word [esi+veh.maxspeed]
		cmp	ax, bx
	codefragment findProcessCrashedRV
		inc	word [esi+0x68]
	codefragment findChkForCollisionWithTrain
		cmp	byte [esi+veh.movementstat], 0xFF
	codefragment findRVCheckCollisionWithRV
		cmp	byte [esi+0x6A], 0
	codefragment findbyte_112552
		db 0x14,0x14,0x10,0x10,0x00,0x00,0x00,0x00
	codefragment findRVMountainSpeedManagement, -7
		mov	dx, word [esi+veh.speed]
		shr	dx, 2
	codefragment findword_11257A, 18
		retn
		and	edx, 3
	codefragment findunk_112582, -9
		and	edx, 3
		mov	di, word [esi+veh.XY]
	codefragment findVehEnterLeaveTile
		push	word [esi+veh.XY]
	codefragment findRVStartSound
		push	eax
		movzx	eax, word [esi+veh.vehtype]
	codefragment findRoadVehiclePathFinder, 1
		retn
		mov	ax, 2
		push	esi
	codefragment findGetVehicleNewPos, 1
		retn
		movzx	ebx, byte [esi+veh.direction]
	codefragment findUpdateVehicleSpriteBox
		mov	bp, word [esi+veh.cursprite]
	codefragment findUpdateDirectionIfMovedTooFar
		movzx	ebx, ax
		mov	dx, cx

	codefragment oldAddStationToRVSchedule, 24
		mov	ah, 8
		cmp	al, 11h

	codefragment newAddStationToRVSchedule
		icall	dontLetARVsInNormalRVStops
		setfragmentsize 8

	codefragment oldDrawRVINRVList, 4
		add     cx, 22
		add     dx, 6

	codefragment newDrawRVINRVList
		icall	drawAllTrailersInRVList
		setfragmentsize 9

	codefragment findDrawRVImageInWindow, 2
		retn
		retn
		push	word [edi+veh.cursprite]

	codefragment oldRVDepotScrXYtoVeh, -14
		mov	al, 1
		retn
		cmp	dl, 24

	codefragment newRVDepotScrXYtoVeh
		icall	RVDepotScrXYtoVehSkipTrailers

	codefragment oldDrawRVinRVInformation,-15
		add	cx, 31

	codefragment newDrawRVinRVInformation
		icall	drawRVWithTrailersInInfoWindow
		setfragmentsize 15

	codefragment oldSetSizeOfRVInformationWindow, -5
		mov	dx, 88h
		mov	ebp, 6

	codefragment newSetSizeOfRVInformationWindow
		mov	ebx, 0095017Ch

	codefragment oldLocationOfServiceStringInInfoWindow
		add	cx, 13
		add	dx, 90

	codefragment newLocationOfServiceStringInInfoWindow
		icall	relocateServiceString
		setfragmentsize 8

	codefragment oldFindRVCapacityForInfoWindow, 14
		mov	ax, word [edi+veh.capacity]
		mov	word [textrefstack+2], ax

	codefragment newFindRVCapacityForInfoWindow
		icall	drawTotalCapacityForTrailers
		setfragmentsize 10

	codefragment oldDrawCurrentCargoInfoInRVInfoWindow, 47
		mul	byte [edi+veh.cargosource]
		movzx	esi, ax

	codefragment newDrawCurrentCargoInfoInRVInfoWindow
		icall	listAdditionalTrailerCargo
		setfragmentsize 10

	codefragment oldMoveInTmpVehPtrForOvertake
		icall	changePtrToParentVehicleIfTrailer

	codefragment oldCheckIfVehicleToOvertakeIsBlocked, 21
		test eax, 3F3F0000h
 
	codefragment newCheckIfVehicleToOvertakeIsBlocked
		icall cancelBlockIfArticulated
		setfragmentsize 15

	codefragment oldSetRoadVehicleGoToDepotOrder, 2
		mov ah, al
		mov al, 0C2h
		mov word [esi+veh.currorder], ax

	codefragment newSetRoadVehicleGoToDepotOrder
		icall sendTrailersToDepot

	codefragment oldCallRVMovementFract,-7
		retn
		cmp	byte [esi+0x66], 0

endcodefragments

patcharticulatedvehicles:
	mov	eax,[ophandler+0x11*8]		// class 11: road vehicles
	mov	eax,[eax+0x10]			// 	action handler
	mov	esi,[eax+9]			// 	action handler table
	mov	eax,addr(newbuyroadvehicle)
	xchg	eax,[esi]
	mov	dword [oldbuyroadvehicle],eax

	mov	eax,[ophandler+0x11*8]		// class 11: road vehicles
	mov	esi, eax
	add	esi, 0x1C
	mov	eax,[eax+0x1C]			// 	action handler
	mov	eax,addr(rvdailyprocoverride)
	xchg	eax,[esi]
	mov	dword [oldrvdailyproc],eax

	patchcode oldSetMovementStat, newSetMovementStat, 1, 1
	patchcode oldSetMovementStat2, newSetMovementStat2, 1, 1
	patchcode oldSetMovementStat3, newSetMovementStat3, 1, 1

	patchcode oldSetRoadVehicleGoToDepotOrder, newSetRoadVehicleGoToDepotOrder,2-WINTTDX,3

	stringaddress oldRVCollisionCheck2, 2-WINTTDX, 3
	mov	edi, [edi]
	mov	dword [rvCollisionCurrVehicle], edi
;	patchcode oldRVCollisionCheck3, startTrailerInDepot, 2-WINTTDX, 3
	storeaddress oldRVCollisionCheck, 2-WINTTDX, 3, JumpOutOfRVRVCollision, 6
	stringaddress oldRVCollisionCheck, 2-WINTTDX, 3
	mov	edi, [edi+2]
	mov	dword [rvCollisionFoundVehicle], edi
	patchcode oldRVCollisionCheck, newRVCollisionCheck, 2-WINTTDX, 3

	patchcode oldRVCollisionTimeout, newRVCollisionTimeout, 1, 1

;probably should re-enable eventually.
	patchcode oldOpenRVWindow, newOpenRVWindow, 2, 4
	patchcode oldListRVsInDepotWindow, newListRVsInDepotWindow, 2, 2
	stringaddress oldSellRoadVehicle, 2+WINTTDX, 5
	chainfunction sellRVTrailers, .origfn, 1

	patchcode oldAddRVScheduleWhenBuilding, newAddRVScheduleWhenBuilding, 2, 4

#if WINTTDX
	stringaddress oldCallRVProcessing, 1, 5
#else
	stringaddress oldCallRVProcessing, 3, 5
#endif
	chainfunction updateTrailerPosAfterRVProc, .origfn, 1

	stringaddress oldCallRVMovementFract, 1, 1
	chainfunction setTrailerMovementFlags, .origfn, 1

;------------new stuffs.
	stringaddress findLimitTurnToFortyFiveDegrees, 1, 1
	mov	[LimitTurnToFortyFiveDegrees], edi
	stringaddress findRedrawRoadVehicle, 2-WINTTDX, 2
	mov	[RedrawRoadVehicle], edi
	stringaddress findSetRoadVehObjectOffsets, 1, 1
	mov	[SetRoadVehObjectOffsets], edi
	stringaddress findSelectRVSpriteByLoad, 2-WINTTDX, 2
	mov	[SelectRVSpriteByLoad], edi
	stringaddress findSetCurrentVehicleBBox, 1, 2
	mov	[SetCurrentVehicleBBox], edi
	stringaddress findWhatIThinkIsMovementSchemes
	mov	edi, [edi]
	mov	dword [off_111D62], edi
	stringaddress findGenerateFirstRVArrivesMessage, 2, 4
	mov	dword [GenerateFirstRVArrivesMessage], edi
	stringaddress findProcessNextRVOrder, 2, 4
	mov	dword [ProcessNextRVOrder], edi
	stringaddress findProcessLoadUnload, 2, 4
	mov	dword [ProcessLoadUnload], edi
	stringaddress findIncrementRVMovementFrac, 1, 1
	mov	dword [IncrementRVMovementFrac], edi
	stringaddress findProcessCrashedRV, 2, 2
	mov	dword [ProcessCrashedRV], edi
	stringaddress findChkForCollisionWithTrain, 2, 2
	mov	dword [ChkForRVCollisionWithTrain], edi
	stringaddress findRVCheckCollisionWithRV, 3, 3
	mov	dword [RVCheckCollisionWithRV], edi
	stringaddress findbyte_112552, 1, 1
	mov	dword [byte_112552], edi
	stringaddress findRVMountainSpeedManagement, 1, 1
	mov	dword [RVMountainSpeedManagement], edi
	stringaddress findword_11257A, 1, 1
	mov	edi, [edi]
	mov	dword [word_11257A], edi
	stringaddress findunk_112582, 1, 1
	mov	edi, [edi]
	mov	dword [unk_112582], edi
	stringaddress findVehEnterLeaveTile, 1, 1
	mov	dword [VehEnterLeaveTile], edi
	stringaddress findRVStartSound, 1+WINTTDX, 3
	mov	dword [RVStartSound], edi
	stringaddress findRoadVehiclePathFinder, 1, 2
	mov	dword [RoadVehiclePathFinder], edi
	stringaddress findGetVehicleNewPos, 1+WINTTDX, 4
	mov	dword [GetVehicleNewPos], edi
	stringaddress findUpdateVehicleSpriteBox, 1, 1
	mov	dword [UpdateVehicleSpriteBox], edi
	stringaddress findUpdateDirectionIfMovedTooFar, 2-WINTTDX, 3
	mov	dword [UpdateDirectionIfMovedTooFar], edi

	//NOTE!: this code overwrites the 'call' to gotodepo.asm:294
	patchcode oldAddStationToRVSchedule, newAddStationToRVSchedule, 1, 1

	patchcode oldDrawRVINRVList, newDrawRVINRVList, 1, 1
	patchcode oldDrawRVinRVInformation, newDrawRVinRVInformation, 1, 2
	stringaddress oldSetSizeOfRVInformationWindow, 1, 1
	add edi, 22
	mov edi, [edi]
	add edi, 56
	mov [edi], byte 0x88			//the size of the second rectangle in the rv information window
	add edi, 10				//stretched down 16 pixels
	mov [edi], byte 0x89			//to allow the articulated rvs to be drawn in a line.
	add edi, 2
	mov [edi], byte 0x8E
	add edi, 10
	mov [edi], byte 0x8F
	add edi, 2
	mov [edi], byte 0x94
	add edi, 10
	mov [edi], byte 0x89
	add edi, 2
	mov [edi], byte 0x94
	patchcode oldLocationOfServiceStringInInfoWindow, newLocationOfServiceStringInInfoWindow, 1, 2
	patchcode oldSetSizeOfRVInformationWindow, newSetSizeOfRVInformationWindow, 1, 1

	stringaddress findDrawRVImageInWindow, 1, 1
	mov	[DrawRVImageInWindow], edi

	patchcode oldRVDepotScrXYtoVeh, newRVDepotScrXYtoVeh, 1, 1

	patchcode oldFindRVCapacityForInfoWindow, newFindRVCapacityForInfoWindow, 1+WINTTDX, 3
	patchcode oldDrawCurrentCargoInfoInRVInfoWindow, newDrawCurrentCargoInfoInRVInfoWindow, 2, 4

	xor	ecx, ecx
	mov	edi, dword [rvcheckovertake]
	push	edi
	mov	edi, [edi+8]
	mov	dword [cacheFoundVehicle], edi
	pop	edi
	push	edi
	mov	edi, [edi+14]
	mov	dword [movingVehicle], edi
	pop	edi
	storefragment oldMoveInTmpVehPtrForOvertake
	patchcode oldCheckIfVehicleToOvertakeIsBlocked, newCheckIfVehicleToOvertakeIsBlocked, 1, 1

	retn
