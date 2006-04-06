#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor experimentalfeatures,BIT(EXP_COOPERATIVE),, patchcoop

begincodefragments

codefragment oldadddenyorder, -2
	movzx ax, [esi+veh.class]
 	cmp al, 12h

codefragment newadddenyorder
	setfragmentsize 2

codefragment olddenytrainonothercompany, 2
	jnz $+2+0x24
	cmp ah, [landscape1+ebx]
	jnz $+2+0x18

codefragment newdenytrainonothercompany
	setfragmentsize 8


endcodefragments

patchcoop:
	// Experimental cooperative play (Bit 1)
	patchcode oldadddenyorder, newadddenyorder,1,1
	patchcode olddenytrainonothercompany, newdenytrainonothercompany,1,1
	ret
