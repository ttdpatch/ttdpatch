#include <defs.inc>
#include <frag_mac.inc>


extern dynmemend,dynmemstart
extern malloccrit

%define DYNMEMSIZE 0x1c0000

global patchdynamicmemory
patchdynamicmemory:
	mov ebx, DYNMEMSIZE

	push ebx
	call malloccrit
	pop eax
	
	mov [dynmemstart], eax
	mov [eax], ebx

	add eax, ebx
	mov [dynmemend], eax
	ret
