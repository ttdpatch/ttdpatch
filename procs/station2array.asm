#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc fifoloading,generalfixes,newcargos,irrstations,patchstation2array

extern malloccrit,miscmodsflags,patchflags,stationarray2ofst
extern stationarray2ptr


patchstation2array:
	testflags generalfixes
	jnc .nogenfix
	test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE
	jz .doit
.nogenfix:
	testflags fifoloading
	jc .doit
	testflags stationsize
	jc .doit
	testflags newcargos
	jnc .dontdoit
.doit:
	push dword numstations*station2_size
	call malloccrit
	pop edi
	mov [stationarray2ptr], edi
	add edi, numstations*station2_size
	extern stationarray2endptr
	mov [stationarray2endptr], edi
	sub edi, numstations*station2_size
	sub edi, [stationarrayptr]
	mov [stationarray2ofst], edi
.dontdoit:
	ret
