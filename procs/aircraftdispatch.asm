#include <defs.inc>
#include <frag_mac.inc>


extern dispatchaircraftop.optable


global patchaircraftdispatch

begincodefragments

codefragment olddispatchaircraftop,4
	movzx ebx,byte [esi+veh.aircraftop]
	db 0xff,0x24		// jmp <r/m>...

codefragment newdispatchaircraftop
	jmp runindex(dispatchaircraftop)


endcodefragments

patchaircraftdispatch:
	patchcode olddispatchaircraftop,newdispatchaircraftop,1,1
	lea eax,[edi+lastediadj+7]
	mov [dispatchaircraftop.optable],eax
	ret
