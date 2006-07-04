// Memory guarding functions
// by eis_os
#include <defs.inc>

#if MAKEGUARD
extern __varlist_start, __varlist_end
global checkmemoryconsistency
checkmemoryconsistency:
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
	// all guards are ok...
	pop esi
	pop eax
	ret
.fail:
	pop esi
	UD2
	pop eax
	ret
#endif
