#include <defs.inc>
#include <frag_mac.inc>
#include <player.inc>

extern gettextintableptr,malloccrit,maglevclassadjust,patchflags
extern realtracktypes,unimaglevmode
extern vehtypedataconvbackupptr


#include <vehtype.inc>

global patchunifiedmaglev

begincodefragments

codefragment oldtrackconstmenusize
	movzx ecx,byte [edx+player.tracktypes]

codefragment newtrackconstmenusize
	call runindex(trackconstmenusize)
	setfragmentsize 7

codefragment oldsettraintype
	mov al,[vehtypearray+ebx+vehtype.enginetraintype]

codefragment newsettraintype
	call runindex(settraintype)


endcodefragments

patchunifiedmaglev:
	mov bl,[unimaglevmode]

	testmultiflags saveoptdata
	jz .donthavetosave
	cmp bl,3
	je .donthavetosave

	push totalvehtypes*vehtypeinfo_size
	call malloccrit
	pop dword [vehtypedataconvbackupptr]
.donthavetosave:

	cmp bl,2
	jne .notonlymaglev
	testmultiflags electrifiedrail
	jnz .notonlymaglev

	mov bl,255	// marker for next patchcode

	// remove Monorail construction option
	mov byte [maglevclassadjust],1

	// make second menu entry be Maglev
	mov ax,0x1016
	call gettextintableptr

	mov esi,[eax+edi*4+4]
	mov [eax+edi*4],esi

	setbase ebx,realtracktypes
	mov byte [realtracktypes+2],1
	mov byte [realtracktypes+3],1

.notonlymaglev:
	patchcode oldtrackconstmenusize,newtrackconstmenusize,1,1,,{cmp bl,255},e

	multipatchcode oldsettraintype,newsettraintype,2
	ret
