// Even more vehicle support for TTD
// by eis_os
// currently supports only trains
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
	push eax
	xor eax, eax
	xor dx, dx
	
	push ecx
	lea edi, [%$counter]
	mov ecx, 256/4
	rep stosd
	pop ecx

	mov edi, [veharrayptr]
.testvehicle:
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
	jb .testvehicle


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
	stc
	_ret
.fail:
	pop eax
	clc
	_ret
endproc calctrainconsistnumber
