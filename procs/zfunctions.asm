#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

extern patchflags,ppTempLocalRouteMap

patchproc advzfunctions, patchzfunctions

begincodefragments

codefragment oldclass9bridgeroutemaphandler1, 2
	jns $+2+0x54+6*WINTTDX
	xor si, si
	and ah, 6
	db 0x38, 0xE0 //cmp al, ah
	
codefragment newclass9bridgeroutemaphandler1
	ijmp zfuncclass9bridgeroutemaphandler

codefragment oldtrrtstepadjustxycoordfromdir1,10
	pop bx
	jmp short $+2+0xD
	and ebx, 0xFFFF

codefragment newtrrtstepadjustxycoordfromdir1
	icall trrtstepadjustxycoordfromdir
	setfragmentsize 7

codefragment oldcreatebridgecheckrailtile1
	jnz $+2+7
	cmp dh, 2
	jnz $+2+0xB
	jmp short $+2+5
	cmp dh, 1
	jnz $+2+4

codefragment newcreatebridgecheckrailtile1
	icall createbridgecheckrailtile
	setfragmentsize 9
	
codefragment oldremovebridgerestoreroutetile1 //,7
//	mov     dl, al
//	and     eax, 18h
//	shr     eax, 1
	and     dl, 1
	shl     dl, 1
	or      al, dl
	db 0x66,0x8B,0x90
	
codefragment newremovebridgerestoreroutetile1
	icall removebridgerestoreroutetile
	setfragmentsize 7
	
codefragment oldistraininsignalblckdircheck1,5
	cmp     di, [ebx]
	db 0x75,0x17				//jnz     short loc_1465D6
	mov     cl, [esi+veh.movementstat]
	mov     ch, cl
	test    [ebx+2], cx
	db 0x0F,0x84,0x35,0xFF,0xFF,0xFF	//jz      loc_146503              ; next vehicle

/*
codefragment newistraininsignalblckdircheck1
	icall istraininsignalblckcheckz1
	setfragmentsize 8
codefragment newistraininsignalblckdircheck2
	icall istraininsignalblckcheckz2
	setfragmentsize 9

codefragment newaddsignaltoblockhook1
	icall addsignaltoblockhook
	setfragmentsize 6+WINTTDX*5
*/

codefragment oldaddtolocalroutemap1
	push    ax
	movzx   ax, ch
	test    cl, 8
	jz      short loc_1371AD
	xchg    al, ah
loc_1371AD:                                     ; CODE XREF: AddToLocalRouteMap+12j
	mov     bx, di
	shl     bl, 3
	shr     bx, 2
	and     ebx, 7FEh

codefragment newaddtolocalroutemap1
	icall addtolocalroutemaphook

codefragment newaddsignaltoblockhook3
	icall addsignaltoblockhook3
	setfragmentsize 0x547B0D-0x547AEA
	
codefragment olddotraceroutehook1
	xor     eax, eax
	mov     ecx, 200h
	repe stosd
	xchg    di, dx
	
codefragment newdotraceroutehook1
	icall dotraceroutehook
	setfragmentsize 7

endcodefragments

exported patchzfunctions
	patchcode class9bridgeroutemaphandler1
	patchcode trrtstepadjustxycoordfromdir1
	patchcode createbridgecheckrailtile1
	patchcode removebridgerestoreroutetile1
	stringaddress oldistraininsignalblckdircheck1

	add edi, 0x547AEA-0x547B2D
	storefragment newaddsignaltoblockhook3

//	push edi
//	storefragment newistraininsignalblckdircheck2
//	mov edi, [esp]
//	add edi, 0x547B05-0x547B2D
//	storefragment newistraininsignalblckdircheck1
//	pop edi
//	add edi, (WINTTDX^1)*(0x146499-0x1465BF)+WINTTDX*(0x547A00-0x547B2D)
//	storefragment newaddsignaltoblockhook1
	stringaddress oldaddtolocalroutemap1
	mov eax, [edi+0x5601E4-0x5601C5]
	mov [ppTempLocalRouteMap], eax
	storefragment newaddtolocalroutemap1
	
	patchcode dotraceroutehook1

ret
