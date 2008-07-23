#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

extern patchflags,isnexttileconnectedgetroutemaphook,isnexttileconnectedgetroutemaphook.oldfn

ext_frag oldremovetunneltrack,findtraceroute

patchproc enhancetunnels, patchenhancetunnel
patchproc enhancetunnels, advzfunctions, patchzfunctionsenhtunnelcommon

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
	
codefragment newzfunctionsfixtunnelentry
	icall TraceRouteFirstStep_PushZAndCheck
	setfragmentsize 6
	
codefragment newzfunctionspopheightval	//56008D, _CS:00137068
	icall TraceRouteFirstStep_PopZ
	setfragmentsize 7

codefragment oldtunnelsteamcheck,-(5 + 2*WINTTDX)	//win: 572291, dos: ShowSteamPlume, _CS:001602EB
	jz $+2+0x36
	push esi
	mov ax, [esi+1Ah]
	mov cx, [esi+1Ch]
	movzx ebx, byte [esi+1Fh]
	
codefragment isnexttileconnectedgetroutemapsearchfrag1,13
	xor bp, 4
	ret
	push eax
	push esi
	push ebp
	mov ax, 0
	db 0xE8

codefragment_call newtunnelsteamcheck, tunnelsteamcheck, 5 + 2*WINTTDX

endcodefragments

global patchenhancetunnel
patchenhancetunnel:
	patchcode oldtunnelsteamcheck,newtunnelsteamcheck,1,1
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
ret

global patchzfunctionsenhtunnelcommon
patchzfunctionsenhtunnelcommon:
	mov eax, [traceroutefnptr]
	testflags advzfunctions
	jc .overwritten
	testflags tracerestrict
	jnc .notoverwritten
.overwritten:
	//Trace restrict/advzfunctions overwrite search function offset!
	mov eax, [trpatch_DoTraceRouteWrapper1.oldfn]
	add eax, trpatch_DoTraceRouteWrapper1.oldfn+4
	mov [traceroutefnptr], eax
.notoverwritten:
	mov [traceroutefnjmp], eax
	cmp BYTE [eax], 0xE9
	jne .nocorrect
	add eax, [eax+1]
	add eax, 5
	mov [traceroutefnptr], eax
.nocorrect:
	lea edi, [eax+265+WINTTDX*3]
	testflags advzfunctions
	jc .nostoretunfrag
	storefragment newfixtunnelentry
	ret
.nostoretunfrag:
	storefragment newzfunctionsfixtunnelentry
	mov eax, [traceroutefnptr]
	lea edi, [eax+0x21B+WINTTDX*9]
	storefragment newzfunctionspopheightval
	extern trfs_pzac_retaddr
	mov eax, [traceroutefnptr]
	lea edi, [eax+265+6+WINTTDX*3]
	mov [trfs_pzac_retaddr], edi
	
	stringaddress isnexttileconnectedgetroutemapsearchfrag1
	chainfunction isnexttileconnectedgetroutemaphook,.oldfn
	ret
