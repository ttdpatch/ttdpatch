#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

extern patchflags

ext_frag oldremovetunneltrack,findtraceroute

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

codefragment oldbegingettunnelotherend, 4
	//db 0,0	//mov     wTempTunnelLengthCounter, 0
	push    dx
	push    bp
	rol     di, 4	//replace
	mov     ax, di	//replace
	mov     cx, di
	rol     cx, 8
	and     ax, 0FF0h
	and     cx, 0FF0h
	add     al, 8
	add     cl, 8
	push    esi
	db 0xE8		//call    CalcExactGroundAltitude
	
codefragment newbegingettunnelotherend
	icall gettunnelotherendproc
	setfragmentsize 7

codefragment newfixtunnelentry
	icall fixtunnelentry
	setfragmentsize 6
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
	patchcode oldbegingettunnelotherend,newbegingettunnelotherend
	stringaddress findtraceroute,1,2
	extern traceroutefnptr, traceroutefnjmp, trpatch_DoTraceRouteWrapper1.oldfn
	storefunctiontarget 0,traceroutefnptr
	testflags tracerestrict
	jnc .notoverwritten
	//Trace restrict overwrites search function offset!
	mov eax, [trpatch_DoTraceRouteWrapper1.oldfn]
	add eax, trpatch_DoTraceRouteWrapper1.oldfn+4
	mov [traceroutefnptr], eax
.notoverwritten:
	//mov eax, [traceroutefnptr] //already there
	mov [traceroutefnjmp], eax
	cmp BYTE [eax], 0xE9
	jne .nocorrect
	add eax, [eax+1]
	add eax, 5
	mov [traceroutefnptr], eax
.nocorrect:
	lea edi, [eax+265+WINTTDX*3]
	storefragment newfixtunnelentry
	ret
