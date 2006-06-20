#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <station.inc>

extern variabletofind,variabletowrite
extern airportstartstatuses,airportlayoutptrs,airportsizes,airportmovementdataptrs

begincodefragments

codefragment findinitialstatestableptr,10
	mov [esi+station.airporttype],al

codefragment findairportsizetable,15
	mov di, [esi+station.airportXY]
	movzx edx, byte [esi+station.airporttype]

codefragment findairportmovementdata,10
	movzx eax, byte [ebx+station.airporttype]

endcodefragments

ext_frag newvariable,findvariableaccess,oilfieldaccepts

exported patchnewairports
	stringaddress findinitialstatestableptr
	mov esi,airportstartstatuses
	xchg esi,[edi]
	push edi
	mov edi,airportstartstatuses
	movsd
	movsw
	pop edi
	mov esi,airportlayoutptrs
	xchg esi,[edi+37]
	mov edi,airportlayoutptrs
	times 3 movsd

	stringaddress findairportsizetable
	mov esi,[edi]
	mov [variabletofind],esi
	mov edi,airportsizes
	mov [variabletowrite],edi
	movsd
	movsw
	mov word [edi],0x101
	patchcode oilfieldaccepts,newvariable,1,1	// generalfixes has overwritten an instance, overwrite it yet again
	multipatchcode findvariableaccess,newvariable,3	// fix the remaining 3 pointers

	stringaddress findairportmovementdata
	mov esi,airportmovementdataptrs
	xchg esi,[edi]
	mov edi,airportmovementdataptrs
	times 4 movsd
	ret
