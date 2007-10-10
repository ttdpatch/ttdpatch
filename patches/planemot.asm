//
// plane motion patches
//

#include <std.inc>
#include <veh.inc>
#include <station.inc>
#include <flags.inc>
#include <airport.inc>

extern airportmovementedgelistptrs,patchflags

//
// called when plane moves
//
// in:	edi=vehicle ptr
// out:
// safe:eax,ebx,ecx,edx,esi,ebp
global moveplane
moveplane:
	cmp byte [edi+veh.subclass],2
	jna .realplane
	ret	// don't move shadows and rotors directly

.realplane:
	mov esi,edi
	call isplaneinflight
	sbb ecx,ecx
	and ecx,0
ovar .factor, -1, $,moveplane
	jz .once

	test byte [esi+veh.vehstatus],1<<7
	jz .domove

	// crashed plane, just process once
.once:
	mov cl,1

.domove:
	push ecx
	call $
ovar .doit, -4, $, moveplane
	pop ecx
	loop .domove
	ret



//
// find effective plane speed
//
// in:	ax=plane speed after acceleration
//	bx=top speed
//	esi=vehicle ptr
//	flags from test[esi+veh.vehstatus],0x40
// out:	ax=new speed
// safe:eax ebx
global planebreakdownspeed
planebreakdownspeed:
	push ecx
	mov cl, byte [esi+veh.movementstat]
	cmp cl, byte [esi+veh.prevmovementstat]
	je .testBreakdown

	// plane movementstat has changed, update speed callback
	push eax
	mov [esi+veh.prevmovementstat], cl
	mov ecx, ebx
	mov ah, 0xC //speeeeed
	mov al, byte [esi+veh.vehtype]	//vehicles are only 0-255
	extcall GetCallback36
	mov word [esi+veh.speedlimit], ax
	pop eax

.testBreakdown:
	test word [esi+veh.vehstatus],0x40
	jz .updateCurrentSpeed

.brokendown:
	// normally TTD just limits the speed to 27 = 216 mph
	// now we make that 5/8 of the top speed
	movzx ecx, word [esi+veh.maxspeed]
	lea ecx,[ecx*5]
	shr ecx,3
	cmp cx,10
	jae .ok
	mov cx,10
.ok:
	cmp cx, [esi+veh.speedlimit]
	jae .finishBreakDown
	mov [esi+veh.speedlimit], cx
.finishBreakDown:

.updateCurrentSpeed:
	cmp ax,[esi+veh.speedlimit]
	jbe .nodecel

	// speed is above new speed limit, need to decelerate
	// decelerate twice as much as normal acceleration to undo
	// the acceleration that has already happened
	movzx ecx,byte [esi+veh.acceleration]
	shl ecx,3
	mov bl,cl
	shr ecx,8

	sub [esi+veh.speedfract],bl
	sbb ax,cx

.nodecel:
	cmp ax,[esi+veh.maxspeed]
	jbe .nottoofast
	mov ax,[esi+veh.maxspeed]
.nottoofast:
	pop ecx
	ret


//
// decide whether plane is in air or on runway accelerating/decelarating
//
// in:	esi=vehicle ptr
// out:	carry set if in flight
// uses:--
global isplaneinflight
isplaneinflight:
	push eax
	push edi
	test byte [esi+veh.vehstatus],$80
	jnz .notinflight
	// in flight only if veh.aircraftop is 7..9 or >= 13
	mov al,[esi+veh.aircraftop]
	cmp al,18	// 18:always in flight
	je .inflight
	testflags newairports
	jnc .nonewcheck

	movzx edi, byte [esi+veh.targetairport]
	imul edi, station_size
	add edi, [stationarrayptr]
	movzx edi, byte [edi+station.airporttype]
	mov edi, [airportmovementedgelistptrs+edi*4]
	test edi,edi
	jnz .newairport

.nonewcheck:
	cmp al,7
	jb .notinflight
	cmp al,10
	jb .onrunway
	cmp al,13
	jb .notinflight

.onrunway:
	mov al,[esi+veh.movementstat]
		// not in flight unless movementstat is 13, 15, or 21+
		// for 13 and 21 only when facing in direction of runway
	cmp al,13
	jb .notinflight
	je .checkdirection

	cmp al,15
	je .checkdirection

	cmp al,21
	ja .inflight
	jb .notinflight

.checkdirection:
	cmp byte [esi+veh.direction],1
	je .inflight

.notinflight:
	clc
	pop edi
	pop eax
	ret

.inflight:
	stc
	pop edi
	pop eax
	ret

.newairport:
	movzx eax,byte [esi+veh.movementstat]
	imul eax, airportmovementedge_size

	cmp byte [edi+eax+airportmovementedge.specaction],1
// cf is set only if specop was 0
	cmc
	pop edi
	pop eax
	ret
