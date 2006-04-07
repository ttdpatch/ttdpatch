// New non-stop handling

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <station.inc>
#include <veh.inc>

extern brakespeedtable,patchflags



// called when approaching a station square
//
// in:	ebx=tile index
//	dh=station in current train order
//	edi->vehicle
//	[tempvar]=station number we're approaching
// out:	carry set if not stopping here
// safe:???
global checkstation
checkstation:
	// check if station we're approaching is a waypoint
	push eax
	movzx eax,byte [tempvar]
	mov ah,station_size
	mul ah
	add eax,[stationarrayptr]
	test byte [eax+station.flags],1<<6	// waypoint?
	jz .notwaypoint

	// is a waypoint, don't stop. if it's the destination, skip command
	mov al,dl
	and al,0x1f
	cmp al,1
	jne .leavethisnostop	// don't stop here, it's a waypoint

	cmp dh,[tempvar]
	je .arriveatwaypoint	// right station?
	jmp short .leavethisnostop

.notwaypoint:
	testmultiflags usenewnonstop
	jnz .newnonstop

	// replicate TTD's normal station approach code
	test dl,dl
	jns .leavethiswithstop		// nonstop not set -> stop
	and dl,0x1f
	cmp dl,1			// nonstop set
	jne .leavethisnostop		// don't stop if target isn't station
	cmp dh,[tempvar]
	jne .leavethisnostop		// wrong station -> don't stop
	jmp short .leavethiswithstop	// right station -> stop

.newnonstop:
	cmp dh,[tempvar]		// are we at the right station?
	jnz short .leavethisnostop	// no, then don't stop - always
	or dl,dl			// check if non-stop is on (=sign bit)
	jns short .leavethiswithstop	// no non-stop = stop
	and dl,0x1f
	cmp dl,2
	je short .leavethisnostop	// destination is a depot, don't modify commands

.arriveatwaypoint:
	inc byte [edi+veh.currorderidx]	// switch to next command
	mov word [edi+veh.currorder],0		// clear current next station
	and word [edi+veh.traveltime],0	// record that the vehicle isn't lost
.leavethisnostop:
	pop eax
	clc
	ret
.leavethiswithstop:
	pop eax
	stc
	ret
; endp checkstation

global stationbrake
stationbrake:
	bts word [edi+0x32],4
	cmp al,2
	jl short .nobrakes
	push ebx
	mov ebx,dword [brakespeedtable]
	movzx ax,byte [eax+ebx]
	pop ebx
	cmp ax,word [edi+veh.speed]
	jae short .nobrakes
	mov word [edi+veh.speed],ax
.nobrakes:
	ret
; endp stationbrake 

// called to decide the text to show before the station in the order list
//
// in:	ax=order, type 1 (station)
//	bp=ax&E0
// out:	bp=textid to use
// safe:ebp si edi
global showordertype
showordertype:
	shr bp,5
	add bp,0x8806				// calculate default text (overwritten)

	push ebx
	xor ebx,ebx
	movzx edi,ah
	imul edi,station_size
	add edi,[stationarrayptr]
	test byte [edi+station.flags],1<<6	// waypoint?
	setnz bl				// if set -> yes, use "route through"

	testmultiflags usenewnonstop
	jz .notnonstop

	// using nonstop switch, i.e. all "nonstop" orders are also "route through"
	test al,al
	jns .haveit
	or bl,1			// yes was nonstop, make it "route through"
	jmp short .haveit

.notnonstop:
	// not using non-stop switch; waypoints use "route through",
	// nonstop waypoints use "route nonstop through"
	test al,al
	jns .haveit
	add ebx,ebx		// was non-stop; change 0->0, 1->2

.haveit:
	test ebx,ebx
	jz .notspecial
	lea ebp,[bx+ourtext(routethrough)-1]
.notspecial:
	pop ebx
	ret
