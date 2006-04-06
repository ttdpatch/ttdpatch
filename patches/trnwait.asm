//
// New time for trains to wait on red signals, before turning back
//

#include <defs.inc>
#include <veh.inc>
#include <ttdvar.inc>

extern signal1waittime,signal2waittime


// Return CF=ZF=0 (cc=A) if it's time to turn back
// Safe: AX,EDI
// For 1-way signals:
global trainwaitforgreen1
trainwaitforgreen1:
	mov	ax,word [signal1waittime]
	jmp	short trainwaitforgreen2.compare

// And for 2-way signals:
global trainwaitforgreen2
trainwaitforgreen2:
	mov	ax,word [signal2waittime]
.compare:
	cmp	word [esi+veh.loadtime],ax
	ret
; endp trainwaitforgreen1 


// Initialization-time procedure:
// convert a byte-sized time (e.g. in days) to internal units
// result = (time==255) ? -1 : (time<<16)/divisor
// in:	DX=time, CX=divisor
// out: EAX=result
// uses:DX
global convertwaittime
convertwaittime:
	or	eax,byte -1
	cmp	dl,al
	je	short .havetime
	inc	eax
	div	cx
.havetime:
	ret
; endp convertwaittime 
