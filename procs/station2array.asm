#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc fifoloading,generalfixes,newcargos,irrstations,patchstation2array

extern malloccrit,miscmodsflags,patchflags,stationarray2ofst
extern stationarray2ptr

begincodefragments

codefragment oldsetupstationstruct_2
	mov byte [esi+station.exclusive],0

codefragment newsetupstationstruct_2
	icall setupstation2
	setfragmentsize 7

codefragment oldsetupoilfield
	mov byte [esi+station.facilities],0x18

codefragment newsetupoilfield
	icall setupoilfield
	setfragmentsize 7

endcodefragments

patchstation2array:
	testflags generalfixes
	jnc .nogenfix
	test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE
	jz .doit
.nogenfix:
	testflags fifoloading
	jc .doit
	testflags newcargos
	jnc .dontdoit
.doit:
	push dword numstations*station2_size
	call malloccrit
	pop edi
	mov [stationarray2ptr], edi
	sub edi, [stationarrayptr]
	mov [stationarray2ofst], edi

	patchcode setupstationstruct_2
	patchcode setupoilfield

.dontdoit:
	ret
