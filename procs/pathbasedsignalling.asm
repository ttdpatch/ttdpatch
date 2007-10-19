#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <ptrvar.inc>
#include <window.inc>
#include <patchproc.inc>

extern chkrailroutetargetfn
extern displayregrailsprite,displayregrailsprite.oldfn,findrailroutearg
extern getnexttileconnection,gettileconnection,lastwagoncleartile
extern lastwagoncleartile.oldfn,oldopclass08removesignals
extern opclass08removesignals,pbssettings,raildirbitsptr
extern railroutechkcont,railroutestepfnarg,railroutetargetnotshortest
extern railroutetargetshortest,routemaphndlist,traceroutefn
extern trainchoosedirection
extern wtrackspriteofsptr
extern patchflags

glob_frag findtraceroute

global patchpathbasedsignalling

patchproc tsignals, isignals, tisignalpatchproc

begincodefragments

codefragment findtraceroute,35
	mov si,0x3000
	db 0xba	// mov edx,ChkRailRouteTarget

codefragment findgetnexttiledirandbits,15
	pop ax
	pop bx
	jmp $+2+0x75

codefragment oldcheckredsignal,7
	pop esi
	mov dx,ax
	shr eax,16

codefragment newcheckredsignal
	icall checksignal
	setfragmentsize 7

codefragment oldsignalblocktrace,15
	mov si,0xc000

codefragment oldlastwagoncleartile,3
	xchg ax,bp
	call $+8

codefragment oldchktrainleavedepot,-26
	jz .notY
	mov byte [esi+veh.movementstat],2
.notY:

codefragment newchktrainleavedepot
	icall chktrainleavedepot
	setfragmentsize 8

codefragment olddisplayrailsprites
	test dh,1
	jz $+2+16

codefragment newdisplayrailsprites
	icall displayrailsprites
	jmp newdisplayrailsprites_start+133

codefragment oldclass1routemaphandlersignal, 0x11
//547B69
//_CS:001465F9
	cmp     ah, 40h
	jz      short loc_14660A
	mov     ah, al
	cmp     al, 3
	jnz     short loc_146606
	or      al, 40h
loc_146606:                                     ; CODE XREF: Class1RouteMapHandler+1Dj
        movzx   eax, ax
        retn
//_CS:0014660A
//insert jmp here (547B7A)
loc_14660A:                                     ; CODE XREF: Class1RouteMapHandler+17j
        mov     ah, al
        movzx   eax, ax
        push    ebx

codefragment newclass1routemaphandlersignal
	ijmp class1routemapsigthrough
	
codefragment newchkrailroutetargettsigchk
	icall chkrailroutetargettsigchk
	setfragmentsize 7
codefragment newchkrailroutetargettsigchkinv
	icall chkrailroutetargettsigchkinv
	setfragmentsize 7

endcodefragments

patchpathbasedsignalling:
	stringaddress findtraceroute,1,2
	storefunctiontarget 0,traceroutefn


	lea esi,[edi-30]
	mov [railroutestepfnarg],esi
	mov esi,[esi]
#if WINTTDX
	add esi,[esi+1]
	add esi,5
#endif
	mov [chkrailroutetargetfn],esi

	add esi,192+4*WINTTDX
	storefunctionjump railroutechkcont,0,esi

	mov eax,addr(railroutetargetshortest)-4-81
	sub eax,esi
	mov [esi+81],eax
	add eax,addr(railroutetargetnotshortest)+11
	sub eax,addr(railroutetargetshortest)
	mov [esi+70],eax

	mov eax,[edi-24]
	mov [findrailroutearg],eax

	sub edi,81
	mov [trainchoosedirection],edi

	stringaddress findgetnexttiledirandbits
	storefunctiontarget 0,gettileconnection
	changereltarget 0,addr(getnexttileconnection)


	stringaddress oldcheckredsignal
	mov eax,[edi+3]
	mov [raildirbitsptr],eax

	storefragment newcheckredsignal

	mov cl,4
	mov esi,routemaphndlist
.nextmaphnd:
	xor eax,eax
	lodsb
	mov ebx,eax
	lodsb
	mov edi,[ophandler+eax]	// opClassxx
	lodsd
	add ebx,eax
	xchg eax,[edi+0x24]	// routemaphnd
	mov ebp,eax
	sub ebp,ebx
	mov [ebx-4],ebp
	loop .nextmaphnd

	mov word [eax],0x368d		// 2-byte nop
#if WINTTDX
	mov word [eax+8],0xb68d		// 6-byte nop
	and dword [eax+10],0
#else
	mov dword [eax+8],0x26748d	// 4-byte nop
#endif
	mov edi,[edi+0x10]
	mov edi,[edi+9]
	mov eax,addr(opclass08removesignals)
	xchg eax,[edi+14*4]
	mov [oldopclass08removesignals],eax

	mov eax,[ophandler+2*8]
	mov edi,[eax+0x28]	// Class2VehEnterLeave
// do not unreserve crossing immediately
// we can't skip the whole "leave" branch because abandonedroads has a patch in it
// instead, we sabotage the "is it a train?" check so the unreserving never happens
	mov byte [edi+0x87+0x20*WINTTDX],0xEB	// jne -> jmp short

	stringaddress oldsignalblocktrace
//	changereltarget 0,addr(signalblocktrace)

	stringaddress oldlastwagoncleartile
	chainfunction lastwagoncleartile

	patchcode chktrainleavedepot

	mov bl,[pbssettings]
	stringaddress olddisplayrailsprites
	mov eax,[edi+lastediadj+33]
	mov [wtrackspriteofsptr],eax
	test bl,PBS_SHOWRESERVEDPATH
	jz .noshow
	storefragment newdisplayrailsprites

	test bl,PBS_SHOWNONJUNCTIONPATH
	jz .noshow

	chainfunction displayregrailsprite,.oldfn,lastediadj+0x81

extern newgraphicssetsenabled
	or dword [newgraphicssetsenabled], 1<<15 // Allow new slope sprites to be used

.noshow:
	ret
	
tisignalpatchproc:

	stringaddress oldclass1routemaphandlersignal
	testflags tsignals
	jnc .no_tsignals
	testflags pathbasedsignalling
	jnc .no_tsignals
	storefragment newclass1routemaphandlersignal
	mov edi, [chkrailroutetargetfn]
	add edi, 0x2F+WINTTDX*4
	storefragment newchkrailroutetargettsigchk
	mov BYTE [signalboxptbtnwnstruc1], cWinElemSpriteBox
.no_tsignals:
	testflags isignals
	jnc .no_isignals
	mov edi, [chkrailroutetargetfn]
	add edi, 0x2F+WINTTDX*4+23
	storefragment newchkrailroutetargettsigchkinv
	mov BYTE [signalboxptbtnwnstruc1+12], cWinElemSpriteBox
.no_isignals:
	extern signalboxrobjendpt1, signalboxptbtnwnstruc1, sigguiwindimensions, signalboxtopbarwnstruc1
	add WORD [signalboxrobjendpt1+4], 20
	add WORD [signalboxtopbarwnstruc1+4], 20
	add WORD [sigguiwindimensions], 20
	ret
