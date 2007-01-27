#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <vehtype.inc>

extern dailyvehproc,dailyvehproc.oldaircraft,drawsplittextfn
extern vehtickproc.oldaircraft
extern vehtickproc_aircraft


global patchnewplanes

begincodefragments

codefragment oldsetplanecargotype
	mov byte [esi+veh.cargotype],0
	mov byte [edi+veh.cargotype],2

codefragment newsetplanecargotype
	icall setplanecargotype
	setfragmentsize 8

codefragment oldshowplanestats
	mov bx,0xa007

codefragment newshowplanestats
	icall showplanestats
	call [drawsplittextfn]
	setfragmentsize 14

codefragment oldshownewplaneinfo,-8
	mov bx,0xa02e

codefragment newshownewplaneinfo
	icall shownewplaneinfo
	setfragmentsize 8

codefragment findopennewplanewnd
	dw 98h	// aircraft class offset
	mov ebp,4

glob_frag oldshipplanestartsound
codefragment oldshipplanestartsound,12
	push eax
	movzx eax,word [esi+veh.vehtype]

glob_frag newvehstartsound
codefragment newvehstartsound
	icall vehstartsound
	pop eax
	ret

codefragment oldtouchdownsound
	mov eax,0x15

codefragment newtouchdownsound
	icall touchdownsound
	setfragmentsize 10

codefragment oldhelitakeoffsound
	mov eax,0x16
	db 0xe8

codefragment newhelitakeoffsound
	icall helitakeoffsound
	setfragmentsize 10

codefragment oldaicheckheli
	test ch,1
	jnz $+2+9
	cmp bx,253

// called when the AI looks for a usable aircraft type
// the old code identified helicopters using their type ID, but this
// doesn't work when aircraft types can be changed
// in:	bx: type ID
//	ch=1 if we need a heli, 0 otherwise
//	edx->vehtype struc for the current type
// out: cf clear if type is OK
// safe: ebp, ???
codefragment newaicheckheli
// extend type into ebp so we can use bl
	movzx ebp,bx
	mov bl,[dword 0+(ebp-AIRCRAFTBASE)]
noglobal ovar planesubclassarrofst,-4
// now bl=0 for helis, bl=2 otherwise
	shr bl,1
	xor bl,ch
// now bl=1 if type is OK; shift this into CF
	shr bl,1
// invert CF to get the needed meaning
	cmc
// restore bx
	mov ebx,ebp
	setfragmentsize 19

endcodefragments

patchnewplanes:
	patchcode setplanecargotype
	patchcode showplanestats
	patchcode shownewplaneinfo
	stringaddress findopennewplanewnd,1,2
	mov ebx,(50 << 16)+50
	add word [edi-4],bx
	stringaddress findopennewplanewnd,2,1
	add [edi-4],bx

	mov edi,[edi+15]
	add [edi+56],bx
	add [edi+66],ebx
	add [edi+78],ebx

	mov esi,vehtickproc_aircraft
	mov eax,[ophandler+0x13*8]	// aircraft vehicle class
	xchg esi,[eax+0x14]		// vehtickproc
	mov [vehtickproc.oldaircraft],esi

	mov esi,dailyvehproc
	xchg esi,[eax+0x1c]		// dailyvehproc
	mov [dailyvehproc.oldaircraft],esi

	patchcode oldshipplanestartsound,newvehstartsound,3-2*WINTTDX,3
	patchcode touchdownsound
	patchcode helitakeoffsound

extern specificpropertybase
	mov eax,[specificpropertybase+3*4]
	add eax,NAIRCRAFTTYPES
	add [planesubclassarrofst],eax
	patchcode aicheckheli

	ret
