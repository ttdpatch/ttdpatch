// Even more vehicle support for TTD
// by eis_os
// aircraft, road and ship support added by JGR
#include <std.inc>
#include <veh.inc>
#include <proc.inc>

//in:	esi = new vehicle
//	bl = build flags
//out: dl = consistnumber
global calctrainconsistnumber
proc calctrainconsistnumber
	slocal counter,byte,256
	_enter
	push ebx
	push eax
	mov ebx, testvehicle_train
	jmp calctrainconsistnumber_start
exported calcshipconsistnumber
	_enter
	push ebx
	push eax
	mov ebx, testvehicle_ship
	jmp calctrainconsistnumber_start
exported calcairconsistnumber
	_enter
	push ebx
	push eax
	mov ebx, testvehicle_air
	jmp calctrainconsistnumber_start
exported calcrvconsistnumber
	_enter
	push ebx
	push eax
	mov ebx, testvehicle_rv
	//jmp calctrainconsistnumber_start
calctrainconsistnumber_start:
	xor eax, eax
	xor dx, dx
	
	push ecx
	lea edi, [%$counter]
	mov ecx, 256/4
	rep stosd
	pop ecx

	mov edi, [veharrayptr]

	call ebx

	mov dl, 0xFF 
.next:
	inc dl
	cmp dl, 0xFF
	je .fail
	mov eax, 1
.nextconsistnumber:
	cmp dl, [%$counter+eax]
	jnb .found
	inc eax
	cmp eax, 0xFF
	je .next
	jmp .nextconsistnumber

.found:
	mov dl, al

	pop eax
	pop ebx
	stc
	_ret
.fail:
	pop eax
	pop ebx
	clc
	_ret

testvehicle_train:
	cmp byte [edi+veh.class], 0x10
	jnz .nextveh
	cmp byte [edi+veh.subclass], 0
	jnz .nextveh

	mov dl, byte [edi+veh.owner]
	cmp dl, byte [curplayer]
	jnz .nextveh

	mov al, byte [edi+veh.consistnum]
	inc byte [%$counter+eax]
.nextveh:
	sub edi,byte -vehiclesize	//add esi,vehiclesize
	cmp edi,[veharrayendptr]
	jb testvehicle_train
	ret
	
testvehicle_ship:
	cmp byte [edi+veh.class], 0x12
	jnz .nextveh

	mov dl, byte [edi+veh.owner]
	cmp dl, byte [curplayer]
	jnz .nextveh

	mov al, byte [edi+veh.consistnum]
	inc byte [%$counter+eax]
.nextveh:
	sub edi,byte -vehiclesize	//add esi,vehiclesize
	cmp edi,[veharrayendptr]
	jb testvehicle_ship
	ret
	
testvehicle_air:
	cmp byte [edi+veh.class], 0x13
	jnz .nextveh
	cmp byte [edi+veh.subclass], 2
	ja .nextveh

	mov dl, byte [edi+veh.owner]
	cmp dl, byte [curplayer]
	jnz .nextveh

	mov al, byte [edi+veh.consistnum]
	inc byte [%$counter+eax]
.nextveh:
	sub edi,byte -vehiclesize	//add esi,vehiclesize
	cmp edi,[veharrayendptr]
	jb testvehicle_air
	ret
	
testvehicle_rv:
	cmp byte [edi+veh.class], 0x11
	jnz .nextveh

	mov dl, byte [edi+veh.owner]
	cmp dl, byte [curplayer]
	jnz .nextveh

	mov al, byte [edi+veh.consistnum]
	inc byte [%$counter+eax]
.nextveh:
	sub edi,byte -vehiclesize	//add esi,vehiclesize
	cmp edi,[veharrayendptr]
	jb testvehicle_rv
	ret
	


endproc calctrainconsistnumber
