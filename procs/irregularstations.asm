#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>
#include <patchproc.inc>

patchproc irrstations, patchirregularstations

extern irrremoverailstation.origfn

begincodefragments

codefragment oldremoverailwaystation
	mov di, [esi+station.railXY]
	mov dl, [esi+station.platforms]
	
codefragment newremoverailwaystation
	ijmp irrremoverailstation
	setfragmentsize 7
	
codefragment findremoverailwaystation2, 7
	and byte [esi+station.facilities], 0xFE

codefragment oldgetrailsouthacceptlist, -12
	sub ax, 0x101
	mov di, dx

codefragment newgetrailsouthacceptlist
	mov di, dx
	call runindex(irrconvertplatformsincargoacceptlist)
	jmp newgetrailsouthacceptlist_start+31+5*WINTTDX


endcodefragments

patchirregularstations:
	patchcode oldremoverailwaystation,newremoverailwaystation,1,1
	stringaddress findremoverailwaystation2
	storerelative irrremoverailstation.origfn, edi

	// overwrites newgetplatformsforcargoacceptlist !!!
	patchcode oldgetrailsouthacceptlist, newgetrailsouthacceptlist,1,1
	ret
