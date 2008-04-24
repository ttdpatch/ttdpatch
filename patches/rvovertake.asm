#include <std.inc>
#include <ptrvar.inc>
#include <veh.inc>

uvard detectedcolidedrvptrptr

global rvotcall1_hook
rvotcall1_hook:
//overwritten...
//_CS:001664BA 24 3F                                   and     al, 3Fh
//_CS:001664BC A8 03                                   test    al, 3
//_CS:001664BE 74 5F                                   jz      short locret_16651F
//_CS:001664C0 A8 3C                                   test    al, 3Ch
//next
//_CS:001664C6 75 0A                                   jnz     short locret_16651F
	and al, 0x3F
	mov ebx, [detectedcolidedrvptrptr]
	mov ebx, [ebx]
	test BYTE [ebx+veh.vehstatus], 2
	jnz .nophail
	cmp WORD [ebx+veh.speed], 0
	je .nophail
	test al, 3
	jz .phail
	test al, 0x3C
	ret
.phail:
	test esp, esp
	ret
.nophail:
	cmp esp, esp
	ret
