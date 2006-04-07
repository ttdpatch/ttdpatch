
#include <defs.inc>
#include <ttdvar.inc>

global cantownextendroadhere
cantownextendroadhere:
	pop eax

	cmp byte [scenarioeditmodeactive], 0
	je .realret
	
	push ebx
	push di
	movzx edi, di
	push eax
	ret

.realret:
	pop di
	pop ebx
	stc
	ret
