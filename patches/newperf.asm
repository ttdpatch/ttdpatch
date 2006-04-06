// New performance calculation

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <veh.inc>

extern getvehiclecost,patchflags





// Auxiliary function: Get score for vehicle (must be more than 2 years old)
// in:	edi -> first veh. in consist
// out:	eax: score

global getvehiclescore
proc getvehiclescore
	slocal score,byte
	slocal age,byte
	slocal maxage,byte
	local profit

	_enter
	pusha
// first, estimate the profit for the whole lifetime
	movzx eax,word [edi+veh.maxage]
	shr eax,1
	mov bl,183
	div bl
	mov [%$maxage],al
	mov ebx,[edi+veh.previousprofit]
	testflags noinflation
	jc near .justmultiply

	mov ax,[edi+veh.age]
	shr ax,1
	mov cl,183
	div cl
	mov [%$age],al
	movzx ecx,byte [%$maxage]
	sub cl,al
	jge .continue
	xor ecx,ecx
	mov [%$maxage],al
.continue:
	push edi
	movzx esi,word [interestrate]
	add esi,100
	mov eax,ebx
	push eax
	xor ebx,ebx
	mov edi,100
	jecxz .nofirstloop

.firstprofitloop:
	imul esi
	idiv edi
	add ebx,eax
	loop .firstprofitloop
.nofirstloop:
	pop eax
	movzx ecx,byte [%$age]
	jecxz .nosecondloop

.secondprofitloop:
	add ebx,eax
	imul edi
	idiv esi
	loop .secondprofitloop

.nosecondloop:
	pop edi
	jmp short .getcost

.justmultiply:
	imul ebx,eax
.getcost:
	mov [%$profit],ebx
// get the cost of the consist
	mov esi,[veharrayptr]
	xor eax,eax
.consistloop:
	xchg esi,edi
	call getvehiclecost
	xchg esi,edi
	add eax,edx
	cmp byte [edi+veh.class],0x10
	jne .nomore
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,byte -1
	je .nomore
	shl edi,vehicleshift
	add edi,esi
	jmp short .consistloop
.nomore:
	testflags noinflation
	jc .nocostadjust
	movzx ecx,byte [%$maxage]
	mov bl,byte [%$age]
	sub cl,bl
	sub cl,1
	jle .nocostadjust
	movzx ebx,word [interestrate]
	add ebx,100
	mov esi,100

.costloop:
	imul ebx
	idiv esi
	loop .costloop

.nocostadjust:
	mov ecx,[%$profit]
	xor bl,bl
.perfloop:
	sub ecx,eax
	jl .foundit
	inc bl
	jnz .perfloop	// if bl=0 we've looped, which means eax was 0 and so we break the infinite loop
.foundit:
	mov [%$score],bl
	popa
	movzx eax,byte [%$score]
endproc

global calcperf
calcperf:
	call getvehiclescore
	add dx,ax
	add edx,0x10000	// to count vehicles more than two years old
	ret
