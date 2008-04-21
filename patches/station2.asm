
#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <bitvars.inc>
#include <loadsave.inc>
#include <veh.inc>

extern clearfifodata,miscmodsflags,patchflags,station2switches
extern stationarray2ptr,station2ofs_ptr



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
	test byte [station2switches],S2_FIFOLOADING2
	jnz .fifo_good
.fifo_old:
// Clear the FIFO data in the vehicle array
	mov esi, [veharrayptr]
.vehloop_init:
	mov byte [esi+veh.slfifoidx],1
	sub esi,byte -veh_size
	cmp esi,[veharrayendptr]
	jb .vehloop_init

	test byte [station2switches],S2_FIFOLOADING
	jz .fifo_clear		// Game contains no FIFO info; just clear the remainder.

// Now set it appropriately

	mov eax, [stationarray2ptr]
.stationloop:

	xor ecx, ecx
	mov cl, 11*8
.cargoloop:
	movzx esi, word [eax+station2.cargos+ecx+stationcargo2.curveh]
	cmp si, 0-1
	je .nextcargo_old

	cvivp
	mov dl, [eax+station2.cargos+ecx+stationcargo2.type]
.vehloop:
	cmp dl, [esi+veh.cargotype]
	jne .nextveh
	mov byte [esi+veh.slfifoidx], 0
.nextveh:
	movzx esi, word [esi+veh.nextunitidx]
	cmp si, 0-1
	je .nextcargo_old
	cvivp
	jmp short .vehloop

.nextcargo_old:
	sub ecx, 0+stationcargo2_size
	jnc .cargoloop

	add eax, station2_size
extern stationarray2endptr
	cmp eax, [stationarray2endptr]
	jb .stationloop

	// FIFO data has been moved to veh.slfifoidx; clear the station info
.fifo_clear:
	call	clearfifodata

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
	push ecx
	lea edi, [esi+station2ofs]
	xor ecx,ecx					// MOVing ECX instead of ANDing with zero
							// spares a byte per instruction
	mov [edi+station2.acceptedcargos],ecx
	mov [edi+station2.catchmenttop],ecx		// clears catchmentbottom as well
	mov [edi+station2.acceptedsinceproc],ecx
	mov [edi+station2.acceptedthismonth],ecx
	mov [edi+station2.acceptedlastmonth],ecx
	mov [edi+station2.everaccepted],ecx

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

// called at the end of every month to update station fields
// in: esi->station
// out: zf set if station.exclusive is zero
exported monthlystationupdate
	push esi
	push eax
	add esi,[station2ofs_ptr]

	xor eax,eax
	xchg eax,[esi+station2.acceptedthismonth]
	mov [esi+station2.acceptedlastmonth],eax

	pop eax
	pop esi

	cmp byte [esi+station.exclusive],0		// overwritten
	ret

exported acceptlistupdated
	and dword [esi+station2ofs+station2.acceptedsinceproc],0
	jmp near $
ovar .oldfn,-4,$,acceptlistupdated
