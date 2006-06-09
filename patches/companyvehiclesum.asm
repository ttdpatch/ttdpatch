// Even more vehicle support for TTD
// by eis_os

#include <std.inc>
#include <window.inc>
#include <veh.inc>
extern drawtextfn

exported CompanyVehiclesSummary
	add cx, 70			// overwritten
	mov ax, [esi+window.id]	// overwritten

	push ebp
	xor ebx, ebx
	xor ebp, ebp
	
	mov esi, [veharrayptr]
.nextveh:
	cmp al, [esi+veh.owner]
	jnz .advanceptr
	mov ah, [esi+veh.class]
	or ah, ah	// empty slot
	jz .advanceptr

	cmp ah, 0x10
	jz .train

	cmp ah, 0x11
	jz .road

	cmp ah, 0x12
	jz .ships

	cmp ah, 0x13
	jnz .advanceptr
.aircraft:
	cmp byte [esi+veh.subclass], 2
	ja .advanceptr
	inc bp
	jmp .advanceptr
.ships:
	add ebp, 0x10000
	jmp .advanceptr
.road:
	// add code for articulate road vehicles here!
	add ebx, 0x10000
	jmp .advanceptr
.train:
	cmp byte [esi+veh.subclass], 0
	jnz .advanceptr
	inc bx
.advanceptr:
	add esi, 0x80
	cmp esi, [veharrayendptr]
	jb .nextveh

	mov eax, ebx
	or eax, eax
	jnz .atleastone

	or ebp, ebp
	jnz .atleastone

	pop ebp
	mov bx, 0x7042 	//TID no vehicles
	call [drawtextfn]
	ret

.atleastone:
	mov bx, 0x703A	//TID for Trains
	call DisplayNumberOVehicles
	shr eax, 16
	mov bx, 0x703C	//TID for RoadVehicles
	call DisplayNumberOVehicles
	mov eax, ebp
	mov bx, 0x703E	//TID for Aircrafts
	call DisplayNumberOVehicles
	shr eax, 16
	mov bx, 0x7040	//TID for Ships
	call DisplayNumberOVehicles
	pop ebp
	ret

DisplayNumberOVehicles:
	cmp ax, 1
	jb .nodisplay
	pusha
	jz .onlyone
	inc bx
.onlyone:
	mov [textrefstack], ax
	call [drawtextfn]
	popa
	add dx, 10
.nodisplay:
	ret
