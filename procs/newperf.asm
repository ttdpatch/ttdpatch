#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newperformance, patchnewperf

begincodefragments

codefragment oldcalcperf1
	or edx,edx
	jz $+2+5

codefragment newcalcperf1
	call runindex(calcperf)
	setfragmentsize 12

codefragment oldcalcperf2,6
	mov ecx,[tempvar+2]

codefragment newcalcperf2
	mov dx,100/5
	mov ax,cx
	mul dx
	ror ecx,16
	or cx,cx
	jz short .nodivbyzero
	div cx,0	// ,0 to disable div-by-zero handler which would make fragment too large
	cmp ax,100
	jg .max100
	jmp short .end
.max100:
	mov ax,100
	jmp short .end
.nodivbyzero:
	xor ax,ax
	setfragmentsize 45
.end:


endcodefragments

patchnewperf:
	patchcode oldcalcperf1,newcalcperf1,1,1
	patchcode oldcalcperf2,newcalcperf2,1,1
	ret
