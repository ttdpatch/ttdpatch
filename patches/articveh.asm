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

extern newbuyrailvehicle, discard, vehcallback, articulatedvehicle, delveharrayentry

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
	xor	eax,eax
	mov	ax, [esi+veh.nextunitidx]
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
	xor	eax, eax
	mov	ax, [esi+veh.nextunitidx]
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
	retn
.trailer:
	mov	ebx, 0xFFFF				//yes, don't shift freeheap, make pointer -1
	retn

global sellRVTrailers
sellRVTrailers:
	cmp	word [esi+veh.nextunitidx], 0xFFFF	//do we have trailers?
	jne	.trailersExist

	call	near $
ovar .origfn, -4, $, sellRVTrailers
	retn

.trailersExist:
	push	esi					//push prev veh onto stack
	movzx	esi, word [esi+veh.nextunitidx]		//iterate to last trailer...
	shl	esi, 7
	add	esi, [veharrayptr]
	cmp	word [esi+veh.nextunitidx], 0xFFFF	//MORE? push them on the stack
	jne	.trailersExist
.recurseOut:
	call	[delveharrayentry]			//del trailer.
	pop	esi					//return to prev veh
	mov	word [esi+veh.nextunitidx], 0xFFFF	//is this needed?
	push	eax
	mov	ax, [esi+veh.idx]
	cmp	ax, [esi+veh.engineidx]
	pop	eax
	je	sellRVTrailers				//head? back to top.
	jmp	.recurseOut				//more trailers.
