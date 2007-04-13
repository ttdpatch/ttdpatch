#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <ptrvar.inc>


extern chkrailroutetargetfn
extern displayregrailsprite,displayregrailsprite.oldfn,findrailroutearg
extern getnexttileconnection,gettileconnection,lastwagoncleartile
extern lastwagoncleartile.oldfn,oldopclass08removesignals
extern opclass08removesignals,pbssettings,raildirbitsptr
extern railroutechkcont,railroutestepfnarg,railroutetargetnotshortest
extern railroutetargetshortest,routemaphndlist,traceroutefn
extern trainchoosedirection
extern wtrackspriteofsptr

glob_frag findtraceroute

global patchpathbasedsignalling

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
	mov byte [edi+3+WINTTDX],77+21*WINTTDX	// do not unreserve crossing immediately

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
