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

extern newbuyrailvehicle, discard, vehcallback, articulatedvehicle, delveharrayentry, sellroadvehicle

uvard	oldbuyroadvehicle
uvarb	buildingroadvehicle
uvard	oldchoosevehmove
uvard	rvCollisionFoundVehicle
uvard	rvCollisionCurrVehicle
uvard	JumpOutOfRVRVCollision


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
	push	eax
	xor	eax,eax
	mov	ax, [esi+veh.engineidx]
	cmp	ax, [esi+veh.idx]
	pop	eax
	jne	.processRVTrailer
	push	eax
	push	dx
	mov	dl, byte [esi+veh.movementstat]
	movzx	eax, word [esi+veh.nextunitidx]
	shl	ax, 7
	add	eax, [veharrayptr]
	mov	byte [eax+veh.parentmvstat], dl
	pop	dx
	pop	eax
	retn
.processRVTrailer:
	push	eax
	push	dx
	mov	dl, byte [esi+veh.parentmvstat]
	mov	byte [esi+veh.movementstat], dl
	mov	eax, esi
.loopTrailers:
	cmp	word [eax+veh.nextunitidx], 0xFFFF
	je	.noTrailer
	movzx	eax, word [esi+veh.nextunitidx]
	shl	ax, 7
	add	eax, [veharrayptr]
	mov	byte [eax+veh.parentmvstat], dl
	jmp	.loopTrailers
.noTrailer:
	pop	dx
	pop	eax
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

global setTrailerToMax
setTrailerToMax:
	push	eax
	mov	ax, [esi+veh.engineidx]
	cmp	ax, [esi+veh.idx]
	pop	eax
	je	.notATrailer
	mov	ax, word [esi+veh.maxspeed]
	inc	ax	// -
	inc	ax	// |
	inc	ax	// |-----> used to give me bytes to play with in olly
	inc	ax	// |
	inc	ax	// |
	inc	ax	// |
	inc	ax	// -
	inc	ax
	inc	ax
	inc	ax
	inc	ax
	inc	ax
	inc	ax
	inc	ax
	inc	ax
	retn
.notATrailer:
	mov	bx, word [esi+veh.maxspeed]
	cmp	ax, bx
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
	cmp	word [edx+veh.nextunitidx], 0xFFFF	//do we have trailers?
	jne	.trailersExist

	call	near $
ovar .origfn, -4, $, sellRVTrailers
	retn

.trailersExist:
	pushad						//push prev veh onto stack
	movzx	edx, word [edx+veh.nextunitidx]		//iterate to last trailer...
	shl	dx, 7
	add	edx, [veharrayptr]
	cmp	word [edx+veh.nextunitidx], 0xFFFF	//MORE? push them on the stack
	jne	.trailersExist
.recurseOut:
	mov	word [edx+veh.nextunitidx], 0xFFFF	//is this needed?
	movzx	edx, word [edx+veh.idx]
	mov	bl, 1					//no idea what's meant to be in here
							//but sellRoadVehicle wants 1
	call	[sellroadvehicle]			//del trailer.
	popad
	push	eax
	mov	ax, [edx+veh.idx]
	cmp	ax, [edx+veh.engineidx]
	pop	eax
	jne	.recurseOut				//more trailers.
	mov	word [edx+veh.nextunitidx], 0xFFFF	//is this needed?
	jmp	sellRVTrailers				//head? back to top.

var	diroffset, dw 0x0000, 0x0001, 0x0000, 0xFF00, 0x0000, 0xFFFF, 0x0000, 0x0100
var	dirdanger, dw 0x0000, 0x0002, 0x0000, 0xFE00, 0x0000, 0xFFFE, 0x0000, 0x0200
var	diruuturn, dw 0x0000, 0xFFFE, 0x0000, 0x0200, 0x0000, 0x0002, 0x0000, 0xFE00

global updateTrailerPosAfterRVProc
updateTrailerPosAfterRVProc:
	call	near $
ovar .origfn, -4, $, updateTrailerPosAfterRVProc

;	push	eax
;	push	ebx
;	push	ecx
;	movzx	eax, word [esi+veh.engineidx]
;	cmp	ax, word [esi+veh.idx]
;	je	.dontShiftFinal
;.loopToFindPrevVeh:
;	shl	ax, 7
;	add	eax, [veharrayptr]
;	mov	cx, word [eax+veh.nextunitidx]
;	cmp	cx, [esi+veh.idx]
;	je	.gotThePrevVeh
;	movzx	eax, word [eax+veh.nextunitidx]
;	jmp	.loopToFindPrevVeh
;.gotThePrevVeh:
;	movzx	ebx, byte [eax+veh.direction]
;	mov	bx, word [dirdanger+ebx*2]
;	mov	cx, word [eax+veh.XY]
;	cmp	bx, 0000h
;	je	.dontUpdateTrailerPos
;	add	cx, bx
;	cmp	cx, word [esi+veh.XY]
;	jne	.dontUpdateTrailerPos
;	movzx	ebx, byte [eax+veh.direction]
;	mov	bx, word [diroffset+ebx*2]
;	mov	cx, word [eax+veh.XY]
;	add	cx, bx
;	mov	word [esi+veh.XY], cx
;.dontUpdateTrailerPos:
;.dontShiftFinal:
;	pop	ecx
;	pop	ebx
;	pop	eax

	push	eax
	push	ebx
;	push	ecx
	movzx	eax, word [esi+veh.engineidx]
	cmp	ax, word [esi+veh.idx]
	je	.justQuit
	mov	ax, word [esi+veh.engineidx]
	shl	ax, 7
	add	eax, [veharrayptr]
	cmp	byte [eax+0x6A], 0
	je	.justQuit
	push	ecx
	mov	ecx, dword [eax+veh.xpos]		;we want to move 2 words, the veh.* are just offsets
	mov	dword [esi+veh.xpos], ecx
	mov	ecx, dword [eax+veh.zpos]
	mov	dword [esi+veh.zpos], ecx
	mov	cx, word [eax+veh.XY]
	movzx	ebx, byte [eax+veh.direction]
	mov	bx, word [diroffset+ebx*2]
	add	cx, bx
	mov	word [esi+veh.XY], cx
	pop	ecx
.justQuit:
;	pop	ecx
	pop	ebx
	pop	eax
	retn

global turnTrailersAroundToo
turnTrailersAroundToo:
	test	bl, 1
	jz	.justReturn
	mov	byte [edx+0x6A], 180
	push	ecx
	movzx	ecx, word [edx+veh.engineidx]
	cmp	cx, word [edx+veh.idx]
	jne	.cleanAndJustReturn
	mov	ecx, edx
.doZeeLoop:
	cmp	word [ecx+veh.nextunitidx], 0xFFFF	//MORE?
	je	.cleanAndJustReturn
	mov	cx, word [ecx+veh.nextunitidx]
	shl	cx, 7
	add	cx, [veharrayptr]
	mov	byte [ecx+0x6A], 180
	jmp	.doZeeLoop
.cleanAndJustReturn:
	pop	ecx
.justReturn:
	retn
