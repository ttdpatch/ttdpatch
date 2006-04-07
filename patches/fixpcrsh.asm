//
// when a plane crashes, free the terminal it was heading for
//

#include <defs.inc>
#include <veh.inc>
#include <ttdvar.inc>

// in:   eax = offset of the station at which the crash occured
//       esi = vehicle struct
// safe: ebx,edx,edi

global freeterminaloncrash
freeterminaloncrash:
//	add	eax,[stationdata]	// overwritten by the call
	add eax,[stationarrayptr]
	mov	dl,byte [esi+veh.aircraftop]
	sub	dl,7
	cmp	dl,2
	ja	short .continue
	jne	short .clearterminal	// 0 -> 1, 1 -> 2, 2 -> 4
	inc	dl
.clearterminal:
	inc	dl
	not	dl
	and	[eax+0x86],dl	// XOR might work as well, but AND NOT is safer
.continue:
	ret
; endp freeterminaloncrash 
