#include <textdef.inc>
#include <grfdef.inc>
#include <var.inc>
#include <newvehdata.inc>

// baseyear is a 16-bit value padded to 32 bits. This way 16 or 32 bit ops may be used.
uvard baseyear, 15
ovar baseyear_days, 4, baseyear

// Words in TTD code equal to 1920, terminated by a 0
ovar ttdbaseyearlocs, 4, baseyear_days



exported newbaseyear
	mov al,INVSP_BADID
	or ebx, ebx
	jnz .error
	jmp short .idok

.badval:
	mov al, INVSP_INVPROPVAL
.error:
	shl eax,16
	mov ax, ourtext(invalidsprite)
	stc
	ret

.idok:
	lodsw
	test al, 3		// Ensure leap years don't do funny things (maybe?)
	jnz .badval
	cmp ah, 0xFF		// make sure the 1920..2175 range remains valid
	je .badval

.valueok:
	extern grfstage
	cmp byte [grfstage+1], 2	// Only when activating
	jne short .done
	mov [baseyear], ax
.done:
	clc
	ret


exported setbaseyear
	mov esi, baseyear
	lodsd
	xchg eax, ebx
	mov edi, esi
	lodsd		// add esi, 4
.ttdloop:
	lodsd
	test eax,eax
	jz .setdays		// All TTD 1920s have been modified or patched out.
	mov [eax], bx
	jmp short .ttdloop

.setdays:
	xchg eax,ebx
	extcall yeartodate
	//           ebx = <desired value> - [edi]
	// [edi] + ebx = <desired value>
	add [edi], ebx
	ret
