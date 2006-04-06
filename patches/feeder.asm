// Feeder service
// Forced unload on a station that accepts that type of cargo
// will leave the cargo at the station, not deliver it there

#include <std.inc>
#include <veh.inc>
#include <station.inc>
#include <player.inc>
#include <misc.inc>

extern calcprofitfn,stationplatformtrigger

checkunload:

global entertrainstation
entertrainstation:		// trains
	push edx
	or edx,byte -1
	push 4
	call stationplatformtrigger
	pop edx
	mov word [esi+veh.currorder],3
	jmp short resetloadcycle

global enterrvstation
enterrvstation:			// truck, bus
	mov word [esi+veh.currorder],3
	jmp short resetloadcycle

// same for planes
global enterairport
enterairport:
	mov al,byte [esi+veh.targetairport]
	mov byte [esi+veh.laststation],al
	jmp short resetloadcycle

// and ships
global enterdock
enterdock:
	mov ax,word [esi+veh.currorder]
	mov byte [esi+veh.laststation],ah
	// jmp short resetloadcycle

resetloadcycle:
	and byte [esi+veh.modflags],~ (1 << MOD_NOTDONEYET)

	// clear "did unload already" flag if we have something to unload
	or byte [esi+veh.modflags],1 << MOD_DIDUNLOAD

	push edi
	mov edi,esi

.next:
	cmp word [esi+veh.currentload],byte 0
	je short .noload

	and byte [edi+veh.modflags],~ (1 << MOD_DIDUNLOAD) 	// clear "did unload already" flag

.noload:

	// reset unload/load cycle for gradualloading
	or byte [esi+veh.modflags],1 << MOD_MORETOUNLOAD

	mov si,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je short .done

	movzx esi,si
	shl esi,vehicleshift
	add esi,[veharrayptr]
	jmp .next

.done:
	mov esi,edi
	pop edi
	ret
; endp checkunload 


var expensesfromclass, db expenses_trainincome,expenses_rvincome,expenses_shipincome,expenses_aircrincome

// add feeder profit to company expenses
global addfeederprofittoexpenses
addfeederprofittoexpenses:
	movzx ebx,byte [edi+veh.class]
	mov bl,[expensesfromclass+ebx-0x10]
	movzx esi,byte [edi+veh.owner]
	imul esi,player_size
	add esi,[playerarrayptr]
	add [esi+player.thisyearexpenses+ebx],eax
	jno .ok
	sub [esi+player.thisyearexpenses+ebx],eax
.ok:
	ret


// find out profit for cargo in transit
// (replicates a part of TTD's [acceptcargofn])
//
// in:	al, ah: source and destination stations
//	bx: amount
//	ch: cargo type
//	dl: time in transit
// out:	eax=profit (a negative number)
// preserves:esi,edi
global transferprofit
transferprofit:
	// find out the distance between stations
	push ebx
	mov ebp,[stationarrayptr]
	movzx ebx,ah
	imul bx,station_size
	mov ebx,[ebx+ebp+station.XY]
	mov ah,station_size
	mul ah
	movzx eax,ax
	mov eax,[eax+ebp+station.XY]

	sub al,bl
	jnc .xpos
	neg al

.xpos:
	sub ah,bh
	jnc .ypos
	neg ah

.ypos:
	add al,ah
	mov ah,0		// doesn't touch flags
	adc ah,ah
	pop ebx

	// calculate the profit
	// split cargo in parts up to 255 units each for [calcprofitfn]
	xor ebp,ebp

.calcloop:
	mov cl,0xff
	cmp bx,0xff
	jae .haveamount
	mov cl,bl

.haveamount:
	sub bl,cl
	sbb bh,0

	pusha
	call [calcprofitfn]
	add [esp+8],eax		// add to EBP on stack
	popa

	or bx,bx
	jnz .calcloop

	xchg eax,ebp
	ret
; endp transferprofit 
