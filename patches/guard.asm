// Memory guarding functions
// by eis_os
#include <defs.inc>
#include <var.inc>

#if MAKEGUARD
extern __varlist_start, __varlist_end, lastmallocofs
exported checkmemoryconsistency
	push eax
	push esi
	mov esi, dword __varlist_start
	.nextguard:
	cmp esi, dword __varlist_end
	jae .guardend
	lodsd
	cmp dword [eax-8], 'TTDP'
	jne .fail
	cmp dword [eax-4], 'ATCH'
	jne .fail
	jmp .nextguard
	.guardend:
	// all variable guards are ok...

	// now check allocated memory 
	cmp dword [firstallocedptr], 0
	je .done
	mov eax, dword [firstallocedptr]
.nextmalloc:
	cmp dword [eax-12], 'TTDP'
	jne .fail
	cmp dword [eax-4], 'ATCH'
	jne .fail
	cmp dword [eax-8], 0
	je .done
	mov eax, dword [eax-8]
	jmp short .nextmalloc

	// all is ok
.done:
	pop esi
	pop eax
	ret
.fail:
	pop esi
	UD2
	pop eax
	ret

uvard firstallocedptr
uvard lastallocedptr

// in: eax	size request
exported guardallocchangesize
	add eax, 12
	ret

// in: eax	new pointer of memory
// safe: esi
exported guardalloc
	mov dword [eax], 'TTDP'
	mov dword [eax+4], 0
	mov dword [eax+8], 'ATCH'

	add eax, byte 12
	mov [lastmallocofs],eax

	mov esi, dword [lastallocedptr]
	mov [lastallocedptr], eax
	cmp esi, 0
	je .nooldmalloc
	mov dword [esi-8], eax
	ret
.nooldmalloc:
	mov [firstallocedptr], eax
	ret
#endif
