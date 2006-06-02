
#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <veh.inc>

extern stationarray2ptr,trainleaveplatform,patchflags

global trainleavestation
trainleavestation:
	call removetrainfromqueue
	call trainleaveplatform
	test word [esi+veh.currorder], 80h
	ret

removetrainfromqueue:
	testflags fifoloading
	jnc .done
	pusha
	movzx eax, byte [esi+veh.laststation]
	mov bx, station2_size
	mul bx
	shl edx, 16
	or eax, edx
	mov ebx, eax
	add ebx, [stationarray2ptr]
	
	sub esi, [veharrayptr]
	shr esi, vehicleshift
	
	lea edi, [ebx+station2.cargos]
	mov ecx, 12
.cargoloop:
	
	cmp [edi+stationcargo2.curveh], si
	jne .notreserved
	mov word [edi+stationcargo2.curveh], -1
.notreserved:

	add edi, stationcargo2_size
	dec ecx
	jnz .cargoloop
	
	popa
.done:
	ret

global sendtraintodepot
sendtraintodepot:
	movzx esi, dx
	shl esi, 7
	add esi, [veharrayptr]

	mov dx,[esi+veh.currorder]
	and dl,0x1f
	cmp dl,3	// are we loading currently?
	jne .notloading

	call removetrainfromqueue
	call trainleaveplatform
.notloading:
	ret

global clearfifodata
clearfifodata:
	mov ecx, numstations
	mov edi, [stationarray2ptr]
	test edi,edi
	jle .done
.stationloop:
	push ecx
	push edi
	lea edi, [edi+station2.cargos]
	mov ecx, 12
.cargoloop:
	mov word [edi+stationcargo2.curveh], -1
	add edi, stationcargo2_size
	dec ecx
	jnz .cargoloop
	pop edi
	pop ecx
	add edi, station2_size
	dec ecx
	jnz .stationloop
.done:
	ret
