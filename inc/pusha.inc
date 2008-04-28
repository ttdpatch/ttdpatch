// Stack offsets for pusha

struc _pusha
	.di:
	.edi:	resd 1
	.si:
	.esi:	resd 1
	.bp:
	.ebp:	resd 1
	.sp:
	.esp:	resd 1
	.bl:
	.bx:
	.ebx:	resb 1
	.bh:	resb 3
	.dl:
	.dx:
	.edx:	resb 1
	.dh:	resb 3
	.cl:
	.cx:
	.ecx:	resb 1
	.ch:	resb 3
	.al:
	.ax:
	.eax:	resb 1
	.ah:	resb 3
endstruc
%if _pusha_size <> 20h
%error "Bad _pusha struc size!"
%endif
