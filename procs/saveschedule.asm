#include <defs.inc>
#include <frag_mac.inc>


extern savevehordersfn


global patchsaveschedule
patchsaveschedule:
	// store custom name (if any) when selling vehicle, and restore when buying
	mov edi,[savevehordersfn]
	storefragment newsavevehorders

	patchcode oldrestorevehorders,newrestorevehorders,1,1

	patchcode oldcalcrefreshrect,newcalcrefreshrect,1,1
	ret



begincodefragments

codefragment newsavevehorders
	jmp runindex(savevehorders)

codefragment oldrestorevehorders,2
	xor bh,bh
	mov ax,[edi]

codefragment newrestorevehorders
	call runindex(restorevehorders)

codefragment oldcalcrefreshrect
	sub ax,31

codefragment newcalcrefreshrect
	mov dx,ax
	mov bp,bx
	call runindex(calcrefreshrect)
	setfragmentsize 23


endcodefragments
