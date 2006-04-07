#include <defs.inc>
#include <frag_mac.inc>

global patchkeepsmallairports

begincodefragments

codefragment oldcanselectsmallap,7
	test byte [airportavailmask],1


endcodefragments

patchkeepsmallairports:
	stringaddress oldcanselectsmallap,1,1
	mov byte [edi],0xeb		// JMP instead of JNZ
	ret
