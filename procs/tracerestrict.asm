#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <window.inc>

extern trpatch_DoTraceRouteWrapper1,trpatch_DoTraceRouteWrapper1.oldfn
extern trpatch_DoTraceRouteWrapper2,trpatch_DoTraceRouteWrapper3
extern signalboxrobjendpt1,sigguiwindimensions
extern tracerestrict_delrobjsignal1,tracerestrict_delrobjsignal1.oldfn
extern robjgameoptionflag,patchflags

patchproc tracerestrict, patchtracerestrict

begincodefragments

/*codefragment oldtracerestrict1
	mov     ah, al
	movzx   eax, ax
	push    ebx

codefragment newtracerestrict1
	icall tracerestrictpatch1func*/

codefragment findtracerestrict_TrainChooseDirection1
xor	 bx, bx
shr	 ch, 1
rcl	 bx, 1
shr	 cl, 1
rcl	 bx, 1
shr	 ch, 1
rcl	 bx, 1
shr	 cl, 1
rcl	 bx, 1

codefragment findtracerestrict_FindNearestTrainDepot1
/*
FindNearestTrainDepot
00576913 66 C7 05 E8 C2	43 00 (FF+		 mov	 ds:word_43C2E8, 0FFFFh
0057691C 56					 push	 esi
0057691D 66 57					 push	 di
0057691F 66 BB 01 00				 mov	 bx, 1
00576923 BA) F5 1F 40 00			 mov	 edx, offset loc_401FF5
*/

db 0xFF, 0xFF, 0x56, 0x66, 0x57, 0x66, 0xBB, 0x01, 0x00, 0xBA

codefragment findtracerestrict_RemoveSignal1
/*_CS:00144EE3 (5F                                      pop     edi
_CS:00144EE4 5A                                      pop     edx
_CS:00144EE5 50                                      push    eax
_CS:00144EE6 51                                      push    ecx
_CS:00144EE7 66 8B C2                                mov     ax, dx
_CS:00144EEA E8) E2 14 00 00                          call    UpdateSignalBlocks*/

pop     edi
pop     edx
push    eax
push    ecx
mov     ax, dx
db 0xE8

endcodefragments

patchtracerestrict:
	//patchcode oldtracerestrict1,newtracerestrict1,1,1

	stringaddress findtracerestrict_TrainChooseDirection1,1,2

	//for testing, disable call to random in TrainChooseDirection
	//mov DWORD [edi-0x572F05+0x572F8E], 0x90C03366	//xor ax, ax	nop
	//mov BYTE [edi-0x572F05+0x572F8E+4], 0x90		//nop

	sub edi,29
	chainfunction trpatch_DoTraceRouteWrapper1,.oldfn
	stringaddress findtracerestrict_TrainChooseDirection1,2,2
	sub edi,29
	storerelative edi,trpatch_DoTraceRouteWrapper1

	stringaddress findtracerestrict_FindNearestTrainDepot1
	add edi,19
	storerelative edi,trpatch_DoTraceRouteWrapper2
	add edi,22
	storerelative edi,trpatch_DoTraceRouteWrapper2
	add edi,22
	storerelative edi,trpatch_DoTraceRouteWrapper2
	add edi,20
	storerelative edi,trpatch_DoTraceRouteWrapper3
	
	stringaddress findtracerestrict_RemoveSignal1
	sub edi,4
	chainfunction tracerestrict_delrobjsignal1,.oldfn
	
	mov BYTE [signalboxrobjendpt1], cWinElemTextBox
	add DWORD [sigguiwindimensions], 0xE0000

	testflags tracerestrict
	bts WORD [robjgameoptionflag], 0
ret
