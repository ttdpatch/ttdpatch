
#include <defs.inc>
#include <ttdvar.inc>

global createInitialRandomIndustries
createInitialRandomIndustries:
	movzx ecx, cx
	movsx esi, word [numberofindustries]
	;check type to see if this one should be created
	cmp esi, -1
	jnz .normal
	pop esi
.normal:
	ret

extern int21handler

exported fixindustriesnone
#if !WINTTDX
	mov ecx, 22		// overwritten
	mov ah, 3Fh		// ...
#endif
	push edx
	CALLINT21		// and again
	pop edx
	cmp word [edx+6], byte -1
	jne .ok
	and word [edx+6], 0
.ok:
	ret
