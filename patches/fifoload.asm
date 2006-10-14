
#include <std.inc>
#include <flags.inc>
#include <station.inc>
#include <veh.inc>

extern stationarray2ptr,trainleaveplatform,patchflags

exported vehleavestation
	call removeconsistfromqueue
	cmp byte [esi+veh.class], 10h
	jne .nottrain
	call trainleaveplatform
.nottrain:
	test word [esi+veh.currorder], 80h
	ret

removeconsistfromqueue:
	testflags fifoloading
	jnc .done
	pusha
	movzx eax, byte [esi+veh.laststation]
	mov bx, station2_size
	mul bx
	mov ebx, eax
	add ebx, [stationarray2ptr]

.vehloop:
	cmp word [esi+veh.capacity],0
	je .next
	mov al, [esi+veh.cargotype]
	extcall ecxcargooffset_ebx2
	extern stationarray2ofst
	add ebx, [stationarray2ofst]
	cmp cl, -1
	je .next
	btr dword [esi+veh.modflags], MOD_HASRESERVED
	jnc .dequeue
// Unreserve cargo
	mov dx, [esi+veh.capacity]
	sub dx, [esi+veh.currentload]
	sub [ebx+station2.cargos+ecx+stationcargo2.resamt], dx
	dec byte [ebx+station2.cargos+ecx+stationcargo2.rescount]
	jmp short .next
.dequeue:
	call dequeueveh
.next:
	movzx esi, word [esi+veh.nextunitidx]
	cmp si, -1
	je .exitvehloop
	cvivp
	jmp short .vehloop
.exitvehloop:
	popa
.done:
	ret


// In:	esi->vehicle
//	ebx->station2
//	ecx: cargo offset
// Out:	vehicle has been removed from reserving queue
// Internal:
//	eax->veh2
//	edi->prev veh2
//	edx->next veh2
exported dequeueveh
	pusha
	mov eax, [esi+veh.veh2ptr]
	mov edi, [eax+veh2.prevptr]
	mov dword [eax+veh2.prevptr], 0
	mov edx, [eax+veh2.nextptr]
	mov dword [eax+veh2.nextptr], 0
	test edi,edi
	jz .ishead
	mov [edi+veh2.nextptr], edx
	test edx, edx
	jz .istail
	mov [edx+veh2.prevptr], edi
.istail:
	popa
	ret

.ishead:
	mov bp, [esi+veh.idx]
	cmp bp, [ebx+station2.cargos+ecx+stationcargo2.curveh]
	jne .done	// Not in queue, do nothing

	test edx, edx
	jz .isboth
	mov [edx+veh2.prevptr], edi	// edi == 0, guaranteed.
	mov edi, [edx+veh2.vehptr]
	mov bp, [edi+veh.idx]
	mov [ebx+station2.cargos+ecx+stationcargo2.curveh], bp
.done:
	popa
	ret

.isboth:
	mov word [ebx+station2.cargos+ecx+stationcargo2.curveh], -1
	popa
	ret

// In:	esi->vehicle
//	ebx->station2
//	ecx: cargo offset
//Out:	vehicle has been added to end of reserving queue
// NOTE! Do not clear MOD_HASRESERVED! This vehicle may have reseved and then gone to service.
exported enqueueveh
	test byte [esi+veh.modflags+1], (1<<(MOD_HASRESERVED-8))
	jnz .ret		// This vehicle left to visit a depot after reserving; do nothing.
	pusha
	mov edi, [esi+veh.veh2ptr]
	movzx eax, word [ebx+station2.cargos+ecx+stationcargo2.curveh]
	cmp ax,-1
	je .first
	cvivp eax
	mov eax, [eax+veh.veh2ptr]
.loop:
	mov edx, eax
	cmp edx, edi
	je .done	// This vehicle left to visit a depot after queuing, do nothing.
	mov dword [edi+veh2.nextptr], 0
	mov eax, [eax+veh2.nextptr]
	test eax, eax
	jnz .loop

// Now edx->last queued vehicle
	mov [edx+veh2.nextptr], edi
	mov [edi+veh2.prevptr], edx
.done:
	popa
.ret:
	ret

.first:
	mov dword [edi+veh2.prevptr], 0
	mov si, [esi+veh.idx]
	mov [ebx+station2.cargos+ecx+stationcargo2.curveh], si
	popa
	ret


exported sendvehtodepot
	movzx esi, dx
	shl esi, 7
	add esi, [veharrayptr]

	mov dx,[esi+veh.currorder]
	and dl,0x1f
	cmp dl,3	// are we loading currently?
	jne .notloading

	call removeconsistfromqueue
	cmp byte [esi+veh.class], 10h
	jne .nottrain
	call trainleaveplatform
.nottrain:
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
	mov word [edi+stationcargo2.resamt], 0
	mov word [edi+stationcargo2.curveh], -1
	mov byte [edi+stationcargo2.rescount], 0
	add edi, stationcargo2_size
	dec ecx
	jnz .cargoloop
	pop edi
	pop ecx
	add edi, station2_size
	dec ecx
	jnz .stationloop

	mov esi, [veharrayptr]
extern veh2ptr
	mov edi, [veh2ptr]
	xor eax, eax
.vehloop:
	mov [edi+veh2.prevptr], eax
	mov [edi+veh2.nextptr], eax
	and byte [esi+veh.modflags+1], ~(1 << (MOD_HASRESERVED-8) )
	add edi, veh2_size
	sub esi, 0-veh_size
	cmp esi, [veharrayendptr]
	jb .vehloop
.done:
	ret

// In: esi->consist-head
// Out: all attached vehicles have queued for reserving (IFF full-load)
exported fifoenterstation_load
	mov al, [esi+veh.currorder]

// as above, but also:
// In:	al: bits 5..6 of current order, from order heap
exported fifoenterstation
	or	[esi+veh.currorder], al
	testflags fifoloading
	jnc	.ret
	test	al, 0x40
	jz	.ret

	pusha
	movzx	eax, byte [esi+veh.laststation]
	mov	ebx, station_size
	mul	ebx
	add	eax, [stationarray2ptr]
	mov	ebx, eax
	push	ebx
.vehloop:
	and	byte [esi+veh.modflags+1], ~(1 << (MOD_HASRESERVED-8))
	cmp	word [esi+veh.capacity], 0
	je	.next
	mov	al, [esi+veh.cargotype]
	call	ecxcargooffset_ebx2
	cmp	cl, -1
	jne	.call
	extcall	ecxcargooffset_force
	mov	ebx, [esp]
	cmp	cl, -1
	je	.next
.call:
	mov	ebx, [esp]
	call	enqueueveh
.next:
	movzx	esi, word [esi+veh.nextunitidx]
	cmp	si, -1
	je	.popret
	cvivp
	jmp	short .vehloop
.popret:
	pop	ebx
	popa
.ret:
	ret


exported buildloadlists
	pusha
	mov	ebx, [stationarray2ptr]

.stationloop:
	mov	eax, ebx
	sub	eax, [stationarray2ofst]
	cmp	word [eax+station.XY], 0
	je	near .nextstation
	sub	eax, [stationarrayptr]
	cdq
	xor	ecx, ecx
	mov	cl, station2_size
	div	ecx, 0 // '0' disables the divide-by-zero prep, but there's no way ecx can be 0 in the first place.
	mov	cl, 11*8

.cargoloop:
	mov	word [ebx+station2.cargos+ecx+stationcargo2.curveh], -1
	mov	dh, al
	mov	dl, cl
	lea	edi, [esp-4]
	mov	ebp, edi
	mov	ecx, 256
	xor	eax, eax
	std
	rep stosd
	cld
	sub	esp, 256*4
	mov	al, dh
	mov	cl, dl
	mov	ah, [ebx+station2.cargos+ecx+stationcargo2.type]
	mov	edi, [veharrayptr]

//!!!!	edi points to vehicle, esi to head.
//!!!!	This is reversed from "normal".

.vehloop:
	movzx	esi, word [edi+veh.engineidx]
	cvivp
	mov	edx, [esi+veh.currorder]
	cmp	dh, al
	jne	.nextveh
	and	dl, 47h
	cmp	dl, 43h
	jne	.nextveh
	cmp	word [edi+veh.capacity], 0
	je	.nextveh
	cmp	[edi+veh.cargotype], ah
	jne	.nextveh
	test	byte [edi+veh.modflags+1], 1<<(MOD_HASRESERVED-8)
	jz	.nextveh
	movzx	edx, byte [edi+veh.slfifoidx]
	neg	edx
	cmp	esi, [ebp+edx*4]
	je	.nextveh	// This consist is already in this slot
	xchg	esi, [ebp+edx*4]
	test	esi, esi
	jz	.nextveh	// No consist was in this slot
	// There was already a consist in this slot. Put it at the end.
	push	esi
.nextveh:
	sub	edi, 0-veh_size
	cmp	edi, [veharrayendptr]
	jb	.vehloop

	mov	edi, ebp
.listloop:
	mov	esi, [edi]
	test	esi, esi
	jz	.noveh
	call	fifoenterstation_load
.noveh:
	sub	edi, 4
	cmp	edi, esp
	jnb	.listloop
	lea	esp, [ebp+4]

.nextcargo:
	sub	ecx, stationcargo2_size
	jns	.cargoloop

.nextstation:
	add	ebx, station2_size
	extern	stationarray2endptr
	cmp	ebx, [stationarray2endptr]
	jb	.stationloop
	popa
	ret


// This destroys the linked-lists to generate the indices for SL, and then rebuilds the lists.
exported buildfifoidx
	pusha
	mov	ebx, [stationarray2ptr]

.stationloop:
	mov	eax, ebx
	sub	eax, [stationarray2ofst]
	cmp	word [eax+station.XY], 0
	je	.nextstation

	mov	ecx, 11*8
.cargoloop:
	xor	al, al
.cargocont:
	movzx	esi, word [ebx+station2.cargos+ecx+stationcargo2.curveh]
	cmp	si, -1
	je	.nextcargo
	cvivp
	mov	ah, [esi+veh.cargotype]

	mov	esi, [esi+veh.engineidx]
	cvivp
.vehloop:
	cmp	word [esi+veh.capacity], 0
	js	.nextveh
	cmp	[esi+veh.cargotype], ah
	jne	.nextveh
	mov	[esi+veh.slfifoidx], al
	call	dequeueveh

.nextveh:
	movzx	esi, word [esi+veh.nextunitidx]
	cmp	si, -1
	je	.continue
	cvivp
	jmp	short .vehloop

.continue:
	inc	al
	jmp	short .cargocont

.nextcargo:
	sub	ecx,8
	jnc	.cargoloop

.nextstation:
	add	ebx, station2_size
	cmp	ebx, [stationarray2endptr]
	jb	.stationloop
	
	popa
	// Building the indices is destructive, so rebuild the linked lists
	call buildloadlists
	ret
