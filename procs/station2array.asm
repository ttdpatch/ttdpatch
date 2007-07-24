#include <defs.inc>
#include <frag_mac.inc>
#include <station.inc>
#include <bitvars.inc>
#include <patchproc.inc>

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

codefragment oldmonthlystationupdate
	cmp byte [esi+station.exclusive],0

codefragment_call newmonthlystationupdate,monthlystationupdate,7

codefragment oldacceptlistupdated,9
	cmp edx,0x60
	jb $+2-0x53

codefragment oldcalccatchment
	add ch,4
	jnc .nooverflow
	mov ch,0xff
.nooverflow:
	sub cx,bx

	push bx
	push cx
	push bx
	push cx

codefragment_call newcalccatchment,calccatchment,7


endcodefragments

exported patchstation2array
	xor ebx,ebx
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
	inc ebx
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
	patchcode oldsetupstationstruct_2,newsetupstationstruct_2,1,1,,{test ebx,ebx},nz
	patchcode oldsetupoilfield,newsetupoilfield,1,1,,{test ebx,ebx},nz
	patchcode oldmonthlystationupdate,newmonthlystationupdate,1,1,,{test ebx,ebx},nz
	stringaddress oldacceptlistupdated
	test ebx,ebx
	jz .nochain
extern acceptlistupdated,acceptlistupdated.oldfn
	chainfunction acceptlistupdated,.oldfn
.nochain:
	patchcode oldcalccatchment,newcalccatchment,1,4
	ret
