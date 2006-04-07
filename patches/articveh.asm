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

extern newbuyrailvehicle, discard, vehcallback

uvard	oldbuyroadvehicle
uvarb	buildingroadvehicle
uvard	oldchoosevehmove
uvard	rvCollisionFoundVehicle
uvard	rvCollisionCurrVehicle
uvard	JumpOutOfRVRVCollision


global newbuyroadvehicle
newbuyroadvehicle:
	mov	byte [buildingroadvehicle], 1
	call	newbuyrailvehicle	//this proc knows what to do if buildingroadvehicle is set.
					//see newtrains.asm
	mov	byte [buildingroadvehicle], 0
	retn

global grabMovementFromParentIfTrailer1
grabMovementFromParentIfTrailer1:
	mov     byte [esi+veh.movementstat], bl
	mov     byte [esi+veh.targetairport], 0
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
	mov	ax, word [edi+veh.engineidx]
	cmp	ax, word [edi+veh.idx]
	je	.checkIfHead
	mov	ax, word [esi+veh.nextunitidx]
	cmp	ax, word [edi+veh.idx]
	je	.moveInCollision
	mov	ax, word [esi+veh.idx]
	cmp	ax, word [edi+veh.engineidx]
	je	.moveInCollision
.zeroCollisionOnOtherVehicle:
	mov	eax, dword [rvCollisionFoundVehicle]
	mov	dword [eax], 0
	pop	eax
	retn
.checkIfHead:
	cmp	word [edi+veh.nextunitidx], 0xFFFF
	je	.moveInCollision
	push	eax
	mov	ax, [esi+veh.engineidx]
	cmp	word [edi+veh.idx], ax
	pop	eax
	je	.zeroCollisionOnOtherVehicle
.moveInCollision:
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
	inc	ax
	inc	ax	//used to give me bytes to play with in olly
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
	cmp     ax, [edi+veh.XY]
	retn
.useThisAsTheReturnCMP:
	cmp	ax, 0xFFFF	//we just want this to always fail
	retn
