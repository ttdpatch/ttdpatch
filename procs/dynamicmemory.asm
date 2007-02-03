#include <defs.inc>
#include <frag_mac.inc>


extern dynmemend,dynmemstart
extern malloccrit

%define DYNMEMSIZE 0x1c0000

global patchdynamicmemory
patchdynamicmemory:
	mov eax, DYNMEMSIZE

	push eax
	call malloccrit
	pop edi
	
	mov [dynmemstart], edi
	lea esi, [edi + eax]
	mov [dynmemend], esi

	sub eax, 4
	mov dword [edi], eax
	ret
