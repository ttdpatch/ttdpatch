#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

extern patchflags

patchproc advzfunctions, patchzfunctions

begincodefragments

codefragment oldclass9bridgeroutemaphandler1, 2
	jns $+2+0x54+6*WINTTDX
	xor si, si
	and ah, 6
	db 0x38, 0xE0 //cmp al, ah
	
codefragment newclass9bridgeroutemaphandler1
	ijmp zfuncclass9bridgeroutemaphandler

codefragment oldtrrtstepadjustxycoordfromdir1,10
	pop bx
	jmp short $+2+0xD
	and ebx, 0xFFFF

codefragment newtrrtstepadjustxycoordfromdir1
	icall trrtstepadjustxycoordfromdir
	setfragmentsize 7

codefragment oldcreatebridgecheckrailtile1
	jnz $+2+7
	cmp dh, 2
	jnz $+2+0xB
	jmp short $+2+5
	cmp dh, 1
	jnz $+2+4

codefragment newcreatebridgecheckrailtile1
	icall createbridgecheckrailtile
	setfragmentsize 9
	
codefragment oldremovebridgerestoreroutetile1 //,7
//	mov     dl, al
//	and     eax, 18h
//	shr     eax, 1
	and     dl, 1
	shl     dl, 1
	or      al, dl
	db 0x66,0x8B,0x90
	
codefragment newremovebridgerestoreroutetile1
	icall removebridgerestoreroutetile
	setfragmentsize 7

endcodefragments

exported patchzfunctions
	patchcode class9bridgeroutemaphandler1
	patchcode trrtstepadjustxycoordfromdir1
	patchcode createbridgecheckrailtile1
	patchcode removebridgerestoreroutetile1
ret
