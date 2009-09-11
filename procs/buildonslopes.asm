#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>

extern actionhandler,addrailgroundsprite,buildroadslopeext
extern buildroadslopeext.goodexit,correctrailexactalt,correctroadexactalt
extern correctspecialexactalt,correctstationalt,correctstationalt.oldfnoffset
extern correctstationexactalt,displbridgeendsprite,displdepotgroundsprite
extern displhqgroundsprite,displrailnextsprite,displrailroadgroundsprite
extern displstationgroundsprite,initchkhqflatland
extern initchkhqflatland.oldfnoffset,newgraphicssetsenabled
extern displbridgeendgroundsprite,chkrailstationflatland

ext_frag oldbuslorrystationflatland,oldcanstartendbridgehere

def_indirect displbridgeendgroundsprite
def_indirect chkrailstationflatland
def_indirect chkairportflatland
def_indirect displbridgeendgroundsprite
def_indirect isbridgeendingramp

global patchbuildonslopes

begincodefragments

codefragment newcanalwaysremovespecial
	call runindex(canalwaysremovespecial)
	setfragmentsize 7

codefragment newchkhqflatland
	call runindex(chkhqflatland)
	jnz $+2+0x17
	push bx
	xor esi,esi
	setfragmentsize 12

codefragment oldbridgeendexactalt,-15
	db 0x66,0x0b,0xff	// or di,<r/m> di
	jz short $+2+0x2a

codefragment newbridgeendexactalt
	call runindex(correctbridgeendexactalt)

codefragment oldbegindrawraildepot,-3
	shr di,6
	and edi,byte 0x7e

codefragment newbegindrawdepot
	mov ebp,edi
	mov edi,edx

codefragment oldbegindrawroaddepot,-3
	shr di,6
	and edi,byte 0x3c

codefragment oldinitrailspritedispl,5
	db 0x8b,0xf3		// mov esi,<r/m> ebx
	db 0x66,0x0b,0xff	// or di,<r/m> di
	jz short $+2+0x18

codefragment newinitrailspritedispl
	call runindex(initrailspritedispl)
	jz short $+2+0x12

codefragment oldinitroadspritedispl
	movzx esi,bx
	db 0x66,0x0b,0xff	// or di,<r/m> di

codefragment newinitroadspritedispl
	call runindex(initroadspritedispl)

codefragment olddisplbridgeendground,-27
	and ebx,byte 0xc
	mov ebx,[esi+ebx*8]

codefragment newdisplbridgeendground
	call runindex(isbridgeendingramp)
displbridgeendground.fn equ $-4-fragmentstart
	setfragmentsize 6
	jmp $+2+0x23

reusecodefragment newisbridgeendingramp,newdisplbridgeendground,,6

codefragment olddisplbridgemid2ndpart
	mov si,1
	mov dh,0x28

codefragment newdisplbridgemid2ndpart
	call runindex(displbridgelastmid2ndpart)

codefragment displayhqgndsprite,11
	push ebp
	mov ebx,[byte ebp+0]
	db 0x0b,0x1d		// or ebx,...

codefragment olddispllighthousegnd,5
	cmp dh,3
	jz $+2+0x67

codefragment newdispllighthousegnd
	call runindex(displlighthouseground)
	setfragmentsize 9

codefragment oldairportflatland,84
	movzx esi,bh
	db 0x66,0x8b,0x14	// mov dx,[...]

codefragment newstationflatland
	call runindex(chkairportflatland)
newstationflatland.fn equ $-4-fragmentstart
	jnz $+2+0x38
	xor esi,esi
	setfragmentsize 12

codefragment oldrailstationflatland,59
	ror di,4
	db 0x0a,0xff		// or bh,<r/m> bh

codefragment newbuslorrystationflatland
	call runindex(chkbuslorrystationflatland)
	jnz $+2+0x29
	xor esi,esi
	setfragmentsize 12

codefragment olddepotflatland,-7
	dw 7			// "Flat land required"
	db 0x66,0x0b,0xff	// or di,<r/m> di
	db 0x0f			// (jnz near)

codefragment newdepotflatland
	call runindex(chkdepotflatland)
	setfragmentsize 9

codefragment oldchkbuildroadslope,-9
	cmp di,3
	jz short $+2+6

codefragment newchkbuildroadslope
	call runindex(chkbuildroadslope)
	setfragmentsize 9

codefragment newbuildtrackroadslopecost
	push edi
	xor esi,esi
	call [actionhandler]
	pop edi
	add edi,ebx

codefragment oldremoveroadonslope
	db 0x8a,0xd7		// mov dl,<r/m> bh
	and dl,0xc

codefragment newremoveroadonslope
	call runindex(removeroadonslope)
	jnz short $+14

glob_frag oldchecktracktype
codefragment oldchecktracktype,-1
	movzx ebx,si
	mov bl,[nosplit landscape3+ebx*2]

reusecodefragment oldbuildtrackslopecost,oldchecktracktype,62

codefragment newcanbuildtrackslope
	call runindex(canbuildtrackslope)

codefragment newcanstartendbridgehere
	add ebx,byte 0
newstartendbridge.end equ $-1-fragmentstart
	call runindex(canstartendbridgehere)
	jb $+12
	setfragmentsize 16

codefragment newcanraiselowertrack
	call runindex(canraiselowertrack)
	setfragmentsize 6+2*WINTTDX
	jnz $+2+0x27

codefragment oldremovetrackfences,52
	test dh,0x40
	jz short $+2+0x27

codefragment newremovetrackfences
	call runindex(removetrackfences)
	setfragmentsize 7+5*WINTTDX
	jc $+2+0x62

codefragment oldchklighthouseflatland
	cmp bl,0
	jnz short $+2+0x35+0x10*WINTTDX

codefragment newchklighthouseflatland
	call runindex(chklighthouseflatland)
	setfragmentsize 8

codefragment oldcanraiselowertrack,-18,-20
	cmp ah,2
	jb short $+2+0xe
	jz short $+2+0x12

endcodefragments

patchbuildonslopes:
	or byte [newgraphicssetsenabled],1 << 6

	mov dword [addrailgroundsprite],addr(displrailnextsprite)

	mov ebp,ophandler
	mov ebx,[ebp+0xa*8]
	mov dword [byte ebx+0x14],addr(correctspecialexactalt)	// explicit "byte" b/o bug in NASM (see #696589 on NASM Bugtracker page)
	mov edi,[ebx+0x18]
	add edi,9
	xor ecx,ecx
	storefragment newcanalwaysremovespecial

	mov edi,[ebx+0x10]
	mov edi,[edi+9]
	mov edi,[edi]
	mov ebx,[edi+8]
	storerelative initchkhqflatland.oldfnoffset,edi+8+4+ebx
	changereltarget 8,addr(initchkhqflatland)
	lea edi,[edi+8+4+ebx+43]
	storefragment newchkhqflatland

	mov edi,[ebp+5*8]
	mov esi,[ebp+1*8]
	mov ebx,[ebp+2*8]
	mov eax,[edi+0x1c]
	mov dword [byte edi+0x1c],addr(correctstationalt)	// explicit "byte" b/o bug in NASM, see above
	mov dword [byte edi+0x14],addr(correctstationexactalt)	// same here
	mov dword [byte esi+0x14],addr(correctrailexactalt)
	mov dword [byte ebx+0x14],addr(correctroadexactalt)
	lea edi,[eax+0x68]
	storerelative correctstationalt.oldfnoffset,eax
	changereltarget 0,addr(displstationgroundsprite)	// call our own function instead of [addgroundsprite]
	patchcode oldbridgeendexactalt,newbridgeendexactalt,1,1

	patchcode oldbegindrawraildepot,newbegindrawdepot,1,1
	changereltarget lastediadj+36,addr(displdepotgroundsprite)
	patchcode oldbegindrawroaddepot,newbegindrawdepot,1,1
	changereltarget lastediadj+19,addr(displdepotgroundsprite)

	patchcode oldinitrailspritedispl,newinitrailspritedispl,1,1
	add edi,lastediadj+0xb7
	mov cl,6
.railloop:
	changereltarget 0,addr(displrailnextsprite)
	add edi,21
	loop .railloop
	mov eax,[edi-21+7]
	lea edi,[edi-21+7+4+eax]
	changereltarget 42,addr(displrailroadgroundsprite)

	patchcode oldinitroadspritedispl,newinitroadspritedispl,1,1
	changereltarget lastediadj+0x6f,addr(displrailroadgroundsprite)

	patchcode olddisplbridgeendground,newisbridgeendingramp,1,1
	add dword [esi+lastediadj+displbridgeendground.fn],0+displbridgeendgroundsprite_indirect-isbridgeendingramp_indirect
	add edi,lastediadj+27+15
	storefragment newdisplbridgeendground
	changereltarget lastediadj+0x5c,addr(displbridgeendsprite)
	patchcode olddisplbridgemid2ndpart,newdisplbridgemid2ndpart,1,1

	stringaddress displayhqgndsprite,1,1
	changereltarget 0,addr(displhqgroundsprite)
	patchcode olddispllighthousegnd,newdispllighthousegnd,1,1

	patchcode oldairportflatland,newstationflatland,1,1
	add dword [esi+lastediadj+newstationflatland.fn],0+chkrailstationflatland_indirect-chkairportflatland_indirect
	patchcode oldrailstationflatland,newstationflatland,1,1
	mov word [edi+lastediadj+77],0x1000		// "Land sloped in wrong direction"
	multipatchcode oldbuslorrystationflatland,newbuslorrystationflatland,2,{mov word [edi+ediadj+62],0x1000}
	multipatchcode olddepotflatland,newdepotflatland,2
	patchcode oldchkbuildroadslope,newchkbuildroadslope,1,1
	storerelative buildroadslopeext.goodexit,edi+lastediadj+70
	changereltarget lastediadj+26,addr(buildroadslopeext)
	changereltarget lastediadj+46,addr(buildroadslopeext)
	changereltarget lastediadj+55,addr(buildroadslopeext)
	add edi,lastediadj+84
	storefragment newbuildtrackroadslopecost
	patchcode oldremoveroadonslope,newremoveroadonslope,1,1
	patchcode oldbuildtrackslopecost,newbuildtrackroadslopecost,1,1
	mov word [edi+lastediadj-11],0xEF89		// MOV EDI,EBP
	mov eax,[edi+lastediadj-28]			// follow a call
	lea edi,[edi+lastediadj-28+4+eax+13]
	mov word [edi-8], 0x9090		// steepslopes
	storefragment newcanbuildtrackslope
	multipatchcode oldcanstartendbridgehere,newcanstartendbridgehere,2,{mov byte [esi+ediadj+newstartendbridge.end],2}
	patchcode oldcanraiselowertrack,newcanraiselowertrack,1,1
	patchcode oldremovetrackfences,newremovetrackfences,1,1
	multipatchcode oldchklighthouseflatland,newchklighthouseflatland,2
	ret
