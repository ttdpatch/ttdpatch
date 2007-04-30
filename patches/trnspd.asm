//
// Show vehicle speed in vehicle caption
//

#include <std.inc>
#include <textdef.inc>
#include <veh.inc>
#include <bitvars.inc>

extern calc_te_a,isplaneinflight,lasttractiveeffort,mountaintypes
extern postredrawhandle
extern miscmodsflags

// Makes text handler use our own string and sets up the data array

// in:	ah=depot number where applicable (text codes 9017,981B,8811)
// out:	bx=text number, edi as in TTD code
// safe:bx,ebp

global trainspeed
trainspeed:
	mov ebp,textrefstack
	cmp bh,0xa0
	je short .hangarspeed
	cmp bh,0x90	// bx=9017: Road Depot; 981B: Ship Depot; A013: Hangar
	jae short .otherdepotspeed
	cmp bl,0x10	// bx=8810: Heading for (station)
	je short .stationspeed
	cmp bl,0x11	// bx=8811: Heading for (depot)
	je short .traindepotspeed
	cmp bl,0x22	// bx=8822: No orders
	je short .noorderspeed

.done:
	mov edi,0
ovar trainspeed_edi,-4
	jmp $+256	// to force tasm to generate a far jump
ovar trainspeed_dest,-4

.hangarspeed:
	add ebp,byte 8	// otherwise the same as other hangars
	mov ebx, ourtext(headingfordepot4)
	jmp .changeitkeepbx

.otherdepotspeed:
	mov WORD [ebp+6], statictext(empty)
	test dword [miscmodsflags],MISCMODS_NODEPOTNUMBERS
	jnz .nodepotnum_other1
	mov WORD [ebp+6], statictext(dpt_number2)
	movzx ax, ah
	inc ax
	mov [ebp+8], ax
	add ebp, BYTE 2
.nodepotnum_other1:
	add ebp,byte 8
	shr ebx,11
	and ebx,byte 7	// now ebx=2 for road; 3 for ship
	add ebx,ourtext(headingfordepot2v2)-2
	jmp short .changeitkeepbx

.noorderspeed:
	mov [ebp],bx		// show text "No orders" as destination
	add ebp,byte 2
	jmp short .changeit

.stationspeed:
	add ebp,byte 8
	jmp short .changeit

.traindepotspeed:
	mov WORD [ebp+6], statictext(empty)
	add ebp,byte 8
	test dword [miscmodsflags],MISCMODS_NODEPOTNUMBERS
	jnz .changeit
	mov WORD [ebp-2], statictext(dpt_number2)
	movzx ax, ah
	inc ax
	mov [ebp], ax
	add ebp, BYTE 2
	mov bx,ourtext(headingfordepot1v2)
	jmp .changeitkeepbx
.changeit:
	mov bx,ourtext(headingfor)

.changeitkeepbx:
	push ebx

	push edi
	call getspeed
	pop dword [ebp]	// store speed for text handler

	push eax

	and dword [ebp+2],0

	mov ebx,3
	movzx eax,word [edi+veh.speed]
	shr eax,1	// for RVs, convert to mph*1.6 from mph*3.2
	cmp byte [edi+veh.class],0x11
	ja .dontshow
	je .gotclass

	movzx eax,word [edi+veh.speed]	// for trains, keep mph*1.6
	movzx ebx,byte [edi+veh.tracktype]

.gotclass:
	cmp byte [mountaintypes+ebx],3
	jne .notrealistic

	// calculate tractive effort and acceleration
	xchg esi,edi
	call calc_te_a
	xchg esi,edi

.gotaccel:
	mov ebx,[lasttractiveeffort]
	shr ebx,8
	mov [ebp+2],bx
	imul eax,100
	jmp short .showaccel

.notrealistic:
	mov eax,[edi+veh.veh2ptr]
	movzx eax,word [edi+veh2.fullaccel]
	test eax,eax
	jnz .ok
	mov al,[edi+veh.acceleration]
.ok:
	imul eax,50		// not 100 because realistic accel. is *2

.showaccel:
	sar eax,8
	mov [ebp+4],ax

.dontshow:
	mov al,[ebp]
	sub al,[ebp+2]
	sub al,[ebp+4]		// refresh window if any of speed, TE, or acc changes

.checkspeed:
	mov ebx,[edi+veh.veh2ptr]
	cmp al,[ebx+veh2.lastspeed]
	je .nochange

	mov [ebx+veh2.lastspeed],al

	mov ax,0x48d		// invalidate and redraw status bar
	mov bx,word [edi+veh.idx]
	call postredrawhandle	// but only after the current draw cycle is done!

.nochange:

	pop eax
	pop ebx
	jmp .done

; endp trainspeed

var speedfactors, db 3,4,4,2

// Calculates the speed of a vehicle
// It needs to be divided by 1.6 as well as taken *2 for planes
// Calling syntax:
//	push <vehicle-offset>
//	call getspeed
//	pop <speed>
// i.e. the speed is left at the top of the stack to be popped into where
// ever you need it.  This makes it safe to use this function even when no
// registers are safe to overwrite.
getspeed:
	enter 0,0
	pusha
	mov esi,[ebp+8]

	movzx eax,byte [esi+veh.class]
	cmp al,0x10
	jne short .notrain

	// if [esi+loadtime] is not zero, the train is waiting for something
	// in such a case the speed is cycling wildly but is really zero
	cmp word [esi+veh.loadtime],byte 0
	jne short .waiting
	cmp byte [esi+0x62],0x80	// check if in depot
	jne short .notwaiting

.waiting:
	xor ebx,ebx
	jmp short .done

.notrain:
.notwaiting:
	movzx ebx,word [esi+veh.speed]
	cmp al,0x13
	jne short .noplane
	call isplaneinflight	// planes in flight have a totally different formula
	jc .airplaneinflight

.noplane:
	mov cl,byte [speedfactors+eax-0x10]
	mov eax,ebx
	shl ebx,2		// convert to mph ( = speed*5/8 )
	add ebx,eax
	shr ebx,cl

.done:
	mov [ebp+8],ebx
	popa
	leave
	ret

.airplaneinflight:
	shl ebx,3
	jmp .done
; endp getspeed 
