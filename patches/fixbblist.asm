#include <std.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>
#include <veh.inc>

extern vehicledatafactor, veharrayendptr, veharrayptr

uvard UpdateBBlockVehicleLists
uvarw maxveh
uvard autoresetcount

exported UpdateBBlockVehicleLists_anticrash_proc
	cmp edi, [veharrayendptr]
	jae .error
	mov bp, [edi+veh.idx]
	mov di, [edi+veh.nextinbblockidx]
	cmp di, [maxveh]
	jae .error
	ret
.error:
	pop ebp	//kill return address

	pop ebp
	pop edi
	pop dx
	pop cx
	pop ebx
	pop ax
	cmp DWORD [autoresetcount], 16
	jae .epicfail
	inc DWORD [autoresetcount]
	call ResetBBlockVehicleLists
	jmp [UpdateBBlockVehicleLists]	//redo the requested update
.epicfail:

	ret


exported ResetBBlockVehicleLists
	pushad
	mov edi, [UpdateBBlockVehicleLists]
	mov edi, [0x55FCB3-0x55FC55+edi]
	//edi=address of _FirstVehInBBlockArray
	mov ecx, 0x800
	or eax, byte -1
	rep stosd		//nuke array
	mov esi, [veharrayptr]
	or ebp, byte -1
	mov edi, [veharrayendptr]
.loop:
	cmp BYTE [esi+veh.class], 0
	je .next
	mov ax, 0x8000
	xchg ax, [esi+veh.box_coord]
	mov cx, [esi+veh.box_coord+4]
	mov [esi+2], bp
	cmp ax, 0x8000
	je .next
	call [UpdateBBlockVehicleLists]
	mov [esi+veh.box_coord], ax
.next:
	add esi, 0x80
	cmp esi, edi
	jb .loop
	popad
	clc
	ret


