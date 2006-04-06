#include <defs.inc>
#include <frag_mac.inc>

global patchremovebridgeortunnel
patchremovebridgeortunnel:
	patchcode oldbridgeremovable,newbridgeremovable,1,1
	patchcode oldtunnelremovable,newtunnelremovable,1,1
	ret

begincodefragments

codefragment oldbridgeremovable,14
	cmp dh,0x11
	jz short $+2+0x11

codefragment newbridgeremovable
	call runindex(bridgeremovable)

codefragment oldtunnelremovable,12
	mov bl,[landscape1+esi]

codefragment newtunnelremovable
	call runindex(tunnelremovable)


endcodefragments
