#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc losttrains,lostrvs,lostships,lostaircraft, patchlostvehs


extern aircraftlosttime,patchflags,rvlosttime,shiplosttime
extern trainlosttime

begincodefragments

codefragment oldagevehicle
	mov ax,[esi+veh.age]
	sub ax,[esi+veh.maxage]
	db 0x72

codefragment newagevehicle
	call runindex(agevehicle)
	jo $+70

codefragment oldcreatevehicle
	mov word [esi+2],-1
	db 0xc7

codefragment newcreatevehicle
	call runindex(createvehicle)


endcodefragments


patchlostvehs:
	testflags losttrains
	jc .haslosttrains
	mov word [trainlosttime],0
.haslosttrains:
	testflags lostrvs
	jc .haslostrvs
	mov word [rvlosttime],0
.haslostrvs:
	testflags lostships
	jc .haslostships
	mov word [shiplosttime],0
.haslostships:
	testflags lostaircraft
	jc .haslostaircraft
	mov word [aircraftlosttime],0
.haslostaircraft:

	patchcode oldagevehicle,newagevehicle,1,1
	patchcode oldcreatevehicle,newcreatevehicle,1,1
	ret
