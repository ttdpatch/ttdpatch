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

uvard	ScrewWithRVDirection
uvard	UpdateRVPos
uvard	SetRoadVehObjectOffsets
uvard	SelectRVSpriteByLoad
uvard	SetCurrentVehicleBBox
uvard	off_111D62


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
;	push	eax
;	xor	eax,eax
;	mov	ax, [esi+veh.engineidx]
;	cmp	ax, [esi+veh.idx]
;	pop	eax
;	jne	.processRVTrailer
	cmp	word [esi+veh.nextunitidx], 0xFFFF
	je	.justReturnNoPop
	push	esi
	push	eax
	push	dx
	push	bx
	mov	dl, byte [esi+veh.movementstat]
	mov	bl, byte [esi+veh.direction]
.loopTrailers:
	movzx	eax, word [esi+veh.nextunitidx]
	shl	ax, 7
	add	eax, [veharrayptr]
	mov	byte [eax+veh.movementstat], dl
	mov	byte [eax+0x63], 6
	and	word [esi+veh.vehstatus], 0xFFFE
	mov	byte [esi+veh.direction], bl
	cmp	word [eax+veh.nextunitidx], 0xFFFF
	je	.justReturn
	mov	esi, eax
	jmp	.loopTrailers
.justReturn:
	pop	bx
	pop	dx
	pop	eax
	pop	esi
.justReturnNoPop:
	retn
;.processRVTrailer:
;	push	eax
;	push	dx
;	mov	dl, byte [esi+veh.parentmvstat]
;	mov	byte [esi+veh.movementstat], dl
;	mov	eax, esi
;.loopTrailers:
;	cmp	word [eax+veh.nextunitidx], 0xFFFF
;	je	.noTrailer
;	movzx	eax, word [esi+veh.nextunitidx]
;	shl	ax, 7
;	add	eax, [veharrayptr]
;	mov	byte [eax+veh.parentmvstat], dl
;	jmp	.loopTrailers
;.noTrailer:
;	pop	dx
;	pop	eax
;	retn

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

global updateTrailerPosAfterRVProc
updateTrailerPosAfterRVProc:
	push	ebx
	movzx	ebx, word [esi+veh.engineidx]
	cmp	bx, word [esi+veh.idx]
	pop	ebx
	jne	.justQuit			;engine? continue: not? quit.
	pushad
	call	near $
ovar .origfn, -4, $, updateTrailerPosAfterRVProc
	popad
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;trailers? continue.
	je	.justQuit
	push	esi
.loopToNextTrailer:
	movzx	esi, word [esi+veh.nextunitidx]
	shl	si, 7
	add	esi, dword [veharrayptr]	;we now have the first trailers ptr.
	pushad
	call	hackedTrailerRVProcessing	;see below.
	popad
	cmp	word [esi+veh.nextunitidx], 0xFFFF	;morE?
	jne	.loopToNextTrailer
	pop	esi
.justQuit:
	retn

;-------------MY HACKY FUNCTION... THIS, in the end, NEEDS TO REPLICATE RVProcessing.
; BUT ONLY THE BITS WE NEED... EVERYONE CAN HELP WITH THIS :)))

global hackedTrailerRVProcessing
hackedTrailerRVProcessing:
	test	word [esi+veh.vehstatus], 2
	jnz	near .DontKnowJustQuit
	cmp	byte [esi+0x66], 0x00
	jz	.continueProcessing
	inc	byte [esi+0x67]
	cmp	byte [esi+0x67], 0x23
	jb	.continueProcessing
	mov	byte [esi+0x66], 0x00

.continueProcessing:
	call	[SetCurrentVehicleBBox]
	movzx	ebx, byte [esi+veh.movementstat]
	cmp	bl, 0FFh
	jz	near .DontKnowJustQuit						;WHAT SHOULD I DO HERE?
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
	jnz	.DontKnowJustQuit ;loc_165CD8					;WHAT SHOULD I DO HERE?
	test	dl, 40h
	jnz	.DontKnowJustQuit ;loc_165E56					;WHAT SHOULD I DO HERE?
	mov	ax, word [esi+veh.xpos]
	mov	cx, word [esi+veh.ypos]
	and	al, 0F0h
	and	cl, 0F0h
	or	al, dl
	or	cl, dh
	mov	bl, dl
	call	[ScrewWithRVDirection] ;sub_1659E6				;GET ADDRESS
	mov	bl, byte [esi+veh.movementstat]
;----------------------------cut out: (loc_165B05-loc_165B20)
	mov	dh, byte [esi+veh.direction]
	cmp	dl, dh
	jz	.DontKnowJustQuit ;short loc_165B58			;needs work... something to do with stations
	mov	byte [esi+veh.direction], dl
	mov	dl, dh
	mov	bp, word [esi+veh.speed]
	shr	bp, 2
	sub	word [esi+veh.speed], bp
	cmp	dl, bl
	jz	.DontKnowJustQuit ;short loc_165B58			;needs work... something to do with stations
	mov	ax, word [esi+veh.xpos]
	mov	cx, word [esi+veh.ypos]
	movzx	bx, byte [esi+veh.direction]
	call	[SelectRVSpriteByLoad]
	call	[SetRoadVehObjectOffsets]
	call	[UpdateRVPos] ;sub_166376					;GET ADDRESS

.DontKnowJustQuit:
	retn
