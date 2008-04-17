#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <station.inc>
#include <patchproc.inc>

patchproc newstations, patchnewstations

extern checktrainenterstationtile,checktrainenterstationtile.oldfn
extern createrailwaystation,createrailwaystation.oldfn

begincodefragments

codefragment oldaddtracktypetostation
	mov [nosplit landscape3+edi*2], ax
	push bx

codefragment newaddtracktypetostation
	call runindex(alteraddlandscape3tracktype)
	nop
	nop

codefragment newgetstationspritetrl
	call runindex(getstationspritetrl)

codefragment olddispstationsprite,5
	shl eax,16
	or ebx,eax
	db 03	// add ebx,[...]

codefragment oldremoverailstation,-5
	add ax,0x10
	dec dh

codefragment newremoverailstation
	call runindex(removerailstation)
	setfragmentsize 9

codefragment oldsetupstationstruct,41
	mov word [esi+station.flags],0

codefragment newsetupstationstruct
	call runindex(setupstationstruct)
	setfragmentsize 10

codefragment oldsetuprailwaystation
	or byte [esi+station.facilities],1

codefragment newsetuprailwaystation
	call runindex(setuprailwaystation)
	setfragmentsize 7

codefragment oldbadstationintransportzone
	sub ax,15
	cmp ax,-1000

codefragment newbadstationintransportzone
	call runindex(badstationintransportzone)
	setfragmentsize 8

codefragment oldupdatestationwindow
	mov al,0x11
	db 0xe8		// call redrawhandle

codefragment newupdatestationwindow
	call runindex(updatestationwindow)
	setfragmentsize 7

codefragment newcargoinstation
	call runindex(cargoinstation)
	setfragmentsize 7

codefragment oldstationquery
	mov ax,0x305e

codefragment newstationquery
	call runindex(stationquery)
	setfragmentsize 7

codefragment oldaibuildrailstation,-4
	mov bh,ah
	and bh,1

codefragment newaibuildrailstation
	icall aibuildrailstation

codefragment oldaipickconstructionobject
	cmp byte [edi+esi+0x2c7],0xff
	db 0x0f,0x85	// jnz near

codefragment newaipickconstructionobject
	icall aipickconstructionobject
	setfragmentsize 8

codefragment newallowbuildoverstation
	icall allowbuildoverstation
	jz $+2+$78

codefragment olddoestrainstopatstationtile
	cmp dl,0
	jb $+2+9

codefragment newdoestrainstopatstationtile
	icall doestrainstopatstationtile
	setfragmentsize 8

codefragment oldstationanimhandler,-4,-11
	cmp al,0x27
	jb $+2+4

codefragment_call newstationanimhandler,stationanimhandler,6+7*WINTTDX

codefragment oldnewtrainstatcreated,14
	xor si,0x101
	dec dh

codefragment_call newnewtrainstatcreated, newtrainstatcreated

codefragment oldperiodicstationupdate
	bt word [esi+station.flags],0
	jc $+2+1

codefragment_call newperiodicstationupdate, periodicstationupdate
endcodefragments


patchnewstations:
	// Different Station Sets
	patchcode oldaddtracktypetostation,newaddtracktypetostation,1,1
	patchcode olddispstationsprite,newgetstationspritetrl

	patchcode oldremoverailstation,newremoverailstation,1,1
	patchcode oldsetupstationstruct,newsetupstationstruct,2,3
	patchcode oldsetuprailwaystation,newsetuprailwaystation,1,1
	patchcode oldbadstationintransportzone,newbadstationintransportzone,1,1
#if WINTTDX
	patchcode oldupdatestationwindow,newupdatestationwindow,1,3
	patchcode oldupdatestationwindow,newcargoinstation,1,2
	//one of the instances is invalidated, but not overwritten by the new load/unload code
#else
	patchcode oldupdatestationwindow,newcargoinstation,1,3
	//one of the instances is invalidated, but not overwritten by the new load/unload code
	patchcode oldupdatestationwindow,newupdatestationwindow,2,2
#endif
	patchcode oldstationquery,newstationquery
	patchcode oldaibuildrailstation,newaibuildrailstation
	patchcode oldaipickconstructionobject,newaipickconstructionobject,1,4

	mov eax,[ophandler+0x05*8]
	mov edi,[eax+0x18]	// cleartile
	add edi,18
	storefragment newallowbuildoverstation

	mov edi,[eax+0x10]	// actionhandler
	mov edi,[edi+9]
	mov ebx,addr(createrailwaystation)
	xchg ebx,[edi]
	storerelative createrailwaystation.oldfn,ebx,esi

	mov esi,addr(checktrainenterstationtile)
	xchg esi,[eax+0x24]	// routemaphnd
	storerelative checktrainenterstationtile.oldfn,esi

	patchcode doestrainstopatstationtile

	patchcode stationanimhandler
	patchcode newtrainstatcreated
	patchcode periodicstationupdate
	ret
