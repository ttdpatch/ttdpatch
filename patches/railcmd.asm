//IN: ax,cx=x,y
//    bl=actionflags
//    bh=pre+exit+semaphore bits
//    dl=bitmask for the signals to be build (4-7) or 0 to only give an error
//    dh=0 for non-pbs, 1 for pbs

#include <std.inc>

extern invalidatetile,pushownerontextstack,startsignalloopfn




global buildsignal
buildsignal:
	cmp dl, 0
	mov word [operrormsg2], 0x1005
	je near .error
	xor edi, edi
	and al, 0F0h
	and cl, 0F0h
	rol cx, 8
	mov di, cx
	rol cx, 8
	or di, ax
	ror di, 4

	mov ebp, [signalplacecost]

	test byte [landscape5(di)], 40h
	jnz .withsignals
	test bl, 1
	jz .onlytest1
	and byte [landscape3 +2*edi], 0Fh
.onlytest1:
	jmp .nosignals
.withsignals:
	mov word [operrormsg2], 0x1007
	push dx
	mov dh, [landscape3 +2*edi]
	and dh, dl
	cmp dh, dl
	pop dx
	je .error
.nosignals:

	push dx
	mov word [operrormsg2], 0x013B
	mov dh, [landscape1 + edi]
	cmp dh, [curplayer]
	jne .ownererror
	pop dx

	bt word [landscape5(di)], 6
	jnc .havesignals
	mov ebp, 0
.havesignals:

	test bl, 1
	jz .onlytesting
	
	or [landscape3 + 2*edi], dl
	bts word [landscape5(di)], 6
	mov byte [landscape3 + 2*edi + 1], bh

	cmp dh, 0
	je .nopbs
//	push edi
//	add edi, [landscape6ptr]
	or byte [landscape6+edi], 8
//	pop edi
.nopbs:
	push ebp
	push edi
	call [invalidatetile]
	pop edi
	call UpdateSignals
	pop ebp
.onlytesting:	
	mov ebx, ebp
	ret

.ownererror:
	mov dl, dh
	mov ebp, textrefstack
	call [pushownerontextstack]
	pop dx
.error:
	mov ebx, 0x80000000
	ret

UpdateSignals:
	push ax
	push cx
	push edi
	mov cx, 1
	call [startsignalloopfn]
	mov edi, [esp]
	mov cx, 3
	call [startsignalloopfn]
	mov edi, [esp]
	mov cx, 5
	call [startsignalloopfn]
	mov edi, [esp]
	mov cx, 7
	call [startsignalloopfn]
	pop edi
	pop cx
	pop ax
	ret
