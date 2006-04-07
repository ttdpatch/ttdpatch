//
// better algorithm for counting whether a new airport can be built
//

#include <defs.inc>
#include <station.inc>

extern airportweight





// count all old airports
// in:	esi=station struct
// out:	dh=new count
// safe:ax,ebx,cx

global airportcount
airportcount:
	movzx ebx,byte [esi+station.airporttype]
	add dh,byte [airportweight+ebx]	// high 16 bits of ebx are zero!
	ret
; endp airportcount 



// check whether we can build the new one
// in:	on stack: cx,bx,ax
//	dh=airport count (weighed)
// out:	carry=can build, no carry=can't build; get cx,bx,ax from stack
global airportcheck
airportcheck:
	movzx ebx,byte [esp+7]	// new airport type
	add dh,byte [airportweight+ebx]
	mov ax,[esp+8]
	mov bx,[esp+6]
	mov cx,[esp+4]
	cmp dh,10	// up to 9 is allowed
			// i.e. 3 big ones, 4 small ones, or 9 heliports
	ret 6	// remove regs from stack
; endp airportcheck 
