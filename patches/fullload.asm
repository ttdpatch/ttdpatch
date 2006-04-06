
// train "full" if any cargo type is full

#include <std.inc>
#include <veh.inc>



	// this determines whether a train/plane is full when full load is set
	// in:   esi=engine
	// safe: eax,edi
	// out:  carry set=full, not set=not full
global checkfull
checkfull:
	btr dword [esi+veh.modflags],MOD_ISFULL
	jc .done
	push ebx
	push ecx

#if 0
	cmp byte [esi+veh.class],0x10
	jne .nochecksignal

	test byte [miscmodsflags+3],MISCMODS_LOADUNTILGREEN>>24
	jz .nochecksignal

	call gettraintiledir
	movzx ecx,word [esi+veh.XY]
	add cx,[tiledeltas+ebx]
	mov al,[landscape4(cx,1)]
	and al,0xf0
	cmp al,0x10
	jne .nochecksignal

.nochecksignal:
#endif
	xor ebx,ebx
	xor ecx,ecx

	mov edi,esi
.nextwaggon:
	mov ax,word [edi+veh.capacity]
	or ax,ax
	jz short .nocargo

	test byte [edi+veh.modflags],0	// set to "1 shl MOD_NOTDONEYET" if gradualloading activated
ovar fullloadtest,-1
	jnz short .notfull

	cmp ax,word [edi+veh.currentload]
	movzx eax,byte [edi+veh.cargotype]
	je short .isfull

	bts ecx,eax	// mark this cargo type as not full
.isfull:
	bts ebx,eax	// mark this cargo type as existing
.nocargo:
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,byte -1
	je short .traindone
	shl edi,vehicleshift
//	add edi,index
	add edi,[veharrayptr]
	jmp .nextwaggon

.traindone:
	xor ebx,ecx	// clear those cargo types that aren't full
		// now ebx has a bit set for every type that is full
	jz short .notfull
	stc
	jmp short .exit
.notfull:
	clc
.exit:
	pop ecx
	pop ebx
.done:
	ret
; endp checkfull
