#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>


global patchmoreairports

begincodefragments

codefragment oldairportcount
	cmp byte [esi+station.airporttype],3
	db 0x74		// jz somewhere

codefragment newairportcount
	call runindex(airportcount)
	setfragmentsize 11,1

codefragment newairportcheck
	call runindex(airportcheck)
	setfragmentsize 9


endcodefragments

patchmoreairports:
	patchcode oldairportcount,newairportcount,1,1
	add edi,byte 10
	storefragment newairportcheck
	ret
