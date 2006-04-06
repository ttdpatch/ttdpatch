#include <defs.inc>
#include <frag_mac.inc>


extern patchflags


global patchenterstation

begincodefragments

codefragment oldenterstation,4
	mov ax,word [esi+veh.currorder]
	db 0x66,0xc7	// mov word ptr [esi+0ah],3

codefragment newentertrainstation
	call runindex(entertrainstation)

codefragment newenterrvstation
	call runindex(enterrvstation)

codefragment oldenterairport
	mov al,byte [esi+veh.targetairport]
	mov byte [esi+veh.laststation],al

codefragment newenterairport
	call runindex(enterairport)

codefragment oldenterdock
	mov ax,word [esi+veh.currorder]
	mov byte [esi+veh.laststation],ah

codefragment newenterdock
	call runindex(enterdock)
	setfragmentsize 7


endcodefragments

patchenterstation:
	testflags gradualloading
	sbb bl,bl

	testflags feederservice
	sbb bl,0	// now bl==0 if neither gradualloading nor feederservice are on

	patchcode oldenterstation,newentertrainstation,1+WINTTDX,2	// trains
	patchcode oldenterstation,newenterrvstation,1,1,,{test bl,bl},nz// truck/bus
	patchcode oldenterairport,newenterairport,1,1,,{test bl,bl},nz
	patchcode oldenterdock,newenterdock,1,1,,{test bl,bl},nz
	ret


		// test for either presignals or extpresignals
		// if either is set we can have pre-signals
		// only presignals is set: only automatic setups
		// only extpresignals is set: no automatic setups
