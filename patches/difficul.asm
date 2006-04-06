
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
