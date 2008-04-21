
// Select goods a station will accept

#include <std.inc>
#include <flags.inc>
#include <station.inc>

extern TempCargoOffsetsInCatchmentArea,patchflags
extern stationcargowaitingnotmask





	// called to determine whether a station will
	// want some goods
	//
	// in:	ebp=station array entry
	//	al=cargo type
	//	ah=cargo amount
	// out:	zero flag if ok, nz if not.  If OK, do a cmp b:[ebp+84h],0
	// safe:-
global findstations
findstations:
	push eax
	movzx eax,al
	shl eax,3
	testflags newcargos
	jnc .gotoffset
	movzx eax,byte [TempCargoOffsetsInCatchmentArea+ebx]
.gotoffset:
	cmp byte [ebp+station.cargos+stationcargo.lastspeed+eax],0	// speed of last train with that cargo
	pop eax
	jz short .notgood	// no train yet
	cmp byte [ebp+0x84],0
	ret
.notgood:
	or ebp,ebp		// clear zero flag (ebp > 40000 !)
	ret
; endp findstations 

// Called in the periodic update loop of a station for every cargo type, every 185 ticks
// Delete a cargo from the list if it wasn't picked up for the given period
// in:	al: time since last pick-up of this cargo type
//	ebx: cargo type*8
//	esi -> station
// out:	increase the according variable
// safe: al,dx
global inctimesincepickedup
inctimesincepickedup:
	cmp al,0
ovar .forgettime,-1, $, inctimesincepickedup
	jae .expired
	inc al							// overwritten
	jz .overflow						// by the
	mov [esi+ebx+station.cargos+stationcargo.timesincevisit],al	// runindex call
.overflow:
	ret

.expired:
	testflags newcargos
	jnc .nonewcargos

	mov byte [esi+station2ofs+ebx+station2.cargos+stationcargo2.type], 0xff	// make the slot unused

.nonewcargos:
	mov dx,[stationcargowaitingnotmask]
	and word [esi+ebx+station.cargos+stationcargo.amount],dx	// clear cargo waiting
	mov byte [esi+ebx+station.cargos+stationcargo.enroutefrom],-1	// indicate no cargo
	mov byte [esi+ebx+station.cargos+stationcargo.rating],175	// next time it should have default rating again
	mov byte [esi+ebx+station.cargos+stationcargo.lastspeed],0	// to prevent cargo from appearing
	mov bp,1
	pop edx		// restart this iteration of the loop to force skipping further code
	sub edx,33	// ( enroutefrom=-1 types are skipped)
	jmp edx
