#if WINTTDX

#include <defs.inc>
#include <frag_mac.inc>

extern reswidth

global patchpanning
patchpanning:
	patchcode olddefaultpanning,newdefaultpanning,1,1
	push edx
	xor edx,edx
	mov eax,640<<16
	movzx ebx, word [reswidth]
	div ebx
	mov [panmultiplier],eax
	pop edx
	patchcode olddecidepanning,newdecidepanning,1,1
	ret


begincodefragments

// The sound code of TTDWin is capable of panning sounds in 320 positions
// between left and right (0-leftmost, 319- rightmost), so the pixel
// coordinate should be simply divided by two to get the panning value.
// However, FISH didn't modify the DOS GenerateSoundEffect function,
// and it decides the panning between 0 and 8. The later code assumes
// that this is a pixel coordinate, and divides it by two. As a result,
// all sounds come from left as if everything happened on pixels 0..8.
// We patch GenerateSoundEffect to return pixel coordinates instead of
// panning values.

//out:  ecx: default panning

codefragment olddefaultpanning
	mov ecx,4
	or esi,esi

codefragment newdefaultpanning
	mov ecx,320

//In:	dx: pixel x coordinate
//Out:	ecx: panning value

codefragment olddecidepanning
	xor ecx,ecx
	cmp dx,0x47

codefragment newdecidepanning
	movzx ecx,dx
	imul ecx,dword 0
panmultiplier equ $-4
	shr ecx,16
	setfragmentsize 15
	db 0xeb		// jl -> jmp short

endcodefragments
#endif
