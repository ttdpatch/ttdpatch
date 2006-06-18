#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

ext_frag oldremovetunneltrack

patchproc enhancetunnels, patchenhancetunnel

begincodefragments

codefragment oldclass9vehenterleavetunneljump, 7
	jns $+2+0x02
	neg dl
	cmp dl, 2
	db 0x0F	// ja  ...

codefragment newclass9vehenterleavetunneljump, 7
	icall Class9VehEnterLeaveTunnelJump

codefragment oldclass9groundaltcorrectiontunnel
	shr dh, 1
	mov dh, cl

codefragment newclass9groundaltcorrectiontunnel
	ijmp Class9GroundAltCorrectionTunnel

codefragment oldclass9routemaphandlertunnel
	and ah, 0x0C
	shr ah, 1
	db 0x38, 0xE0 // cmp al, ah

codefragment newclass9routemaphandlertunnel
	ijmp Class9RouteMapHandlerTunnel

//reusecodefragment oldremovetunneltrack, oldremovebridgetrack, -6

codefragment newremovetunneltrack
	icall enhancetunnelremovetrack

codefragment olddrawtunnelentrance, -21
	jns $+2+4
	add bx, 32

codefragment newdrawtunnelentrance
	icall Class9DrawLandTunnelExt
	nop
	nop

codefragment oldchecktunnelrailtype
	or al, al
	jns $+2+4
	test al, 0x40

codefragment newchecktunnelrailtype
	icall enhancetunneltestrailwaytype

codefragment oldremovetunnel
	jnz near $+6+0xA8
	test bl, 1

codefragment_call newremovetunnel,enhancetunnelremovetunnel,6

endcodefragments

global patchenhancetunnel
patchenhancetunnel:
	patchcode oldclass9routemaphandlertunnel,newclass9routemaphandlertunnel,1,1
	patchcode oldclass9groundaltcorrectiontunnel,newclass9groundaltcorrectiontunnel,1,2
	patchcode oldclass9vehenterleavetunneljump,newclass9vehenterleavetunneljump,1,1
	patchcode oldremovetunneltrack,newremovetunneltrack,1,1
	patchcode olddrawtunnelentrance,newdrawtunnelentrance,1,1
	patchcode oldchecktunnelrailtype,newchecktunnelrailtype,1,1
	patchcode oldremovetunnel,newremovetunnel,1,1
	ret
