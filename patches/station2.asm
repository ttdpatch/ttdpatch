
#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <bitvars.inc>
#include <loadsave.inc>

extern clearfifodata,miscmodsflags,patchflags,station2switches
extern stationarray2ptr,stationarray2ofst



global station2clear
station2clear:
	pusha
	mov ecx,numstations*station2_size
	mov edi, [stationarray2ptr]
	xor eax,eax
	rep stosb
	and dword [station2switches],0
	popa
	ret

global station2init
station2init:
	pusha
	testflags fifoloading
	jnc .no_fifo
	test dword [station2switches],S2_FIFOLOADING
	jnz .fifo_good
	call clearfifodata
.fifo_good:
.no_fifo:
	testflags generalfixes
	jnc .no_catchment
	test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE
	jnz .no_catchment
	test dword [station2switches],S2_CATCHMENT
	jnz .catchment_good

	mov ecx, numstations
	mov edi, [stationarray2ptr]

.nextcatchment:
	and dword [edi+station2.catchmenttop],0		// clears catchmentbottom as well
	add edi,station2_size
	loop .nextcatchment

.catchment_good:
.no_catchment:

	testflags newcargos
	jnc .no_newcargo
	test dword [station2switches],S2_NEWCARGO
	jnz .newcargo_good

	mov ebx,stationarray
	mov edx,[stationarray2ptr]
	xor ecx,ecx

.nextstation:
	cmp word [ebx+station.XY],0
	je .skipstation

	and dword [edx+station2.acceptedcargos],0
	mov cl,11

.nextcargo:
	test byte [ebx+station.cargos+ecx*stationcargo_size+stationcargo.amount+1],0x80
	jz .noaccept

	bts dword [edx+station2.acceptedcargos],ecx
.noaccept:
	and byte [ebx+station.cargos+ecx*stationcargo_size+stationcargo.amount+1],0x0f

	mov al,cl
	cmp byte [ebx+station.cargos+ecx*stationcargo_size+stationcargo.enroutefrom],-1
	jne .valid

	mov al,0xff
.valid:
	mov [edx+station2.cargos+ecx*stationcargo2_size+stationcargo2.type],al
	dec cl
	jns .nextcargo

.skipstation:
	add ebx,station_size
	add edx,station2_size
	cmp ebx,stationarray+numstations*station_size
	jb .nextstation

.no_newcargo:
.newcargo_good:

	test dword [station2switches],S2_IRRSTATIONS
	jnz .irrstation_good

	mov ecx, numstations
	mov edi, [stationarray2ptr]

.nextirrstation:
	and byte [edi+station2.railxysouth], 0
	add edi,station2_size
	loop .nextirrstation
.irrstation_good:

	popa
	ret

// Called when setting up a new station struc. Init our new fields in
// station2.
// This should basically duplicate the logic in the above proc, but
// for one station only instead of all of them
// NOTE: it won't hurt to initialize a field even when the corresponding
// switch isn't enabled
global setupstation2
setupstation2:
	mov byte [esi+station.exclusive],0	// overwritten
.overwrittendone:
	mov edi,esi
	add edi,[stationarray2ofst]
	and dword [edi+station2.acceptedcargos],0
	and dword [edi+station2.catchmenttop],0		// clears catchmentbottom as well
	push ecx
	xor ecx,ecx
.nextcargo:
	mov word [edi+station2.cargos+ecx+stationcargo2.curveh],-1
	mov byte [edi+station2.cargos+ecx+stationcargo2.type],0xff
	add ecx,stationcargo2_size
	cmp ecx,12*stationcargo2_size
	jb .nextcargo

	pop ecx
	ret

// The same, but called when setting up an oilfield station.
global setupoilfield
setupoilfield:
	mov byte [esi+station.facilities],0x18
	jmp short setupstation2.overwrittendone

