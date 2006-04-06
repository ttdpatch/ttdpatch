#include <defs.inc>
#include <frag_mac.inc>

global patchnewlineup
patchnewlineup:
	patchcode oldlineuptruckstation,newlineupstation,1,1
	patchcode oldlineupbusstation,newlineupstation,1,1
	ret



begincodefragments

codefragment oldlineuptruckstation,7
	test byte [ebp+0x83],3

codefragment newlineupstation
	nop
	nop

codefragment oldlineupbusstation,7
	test byte [ebp+0x82],3


endcodefragments
