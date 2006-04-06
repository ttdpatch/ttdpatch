#include <defs.inc>
#include <frag_mac.inc>
#include <misc.inc>

extern findwindowstructuse.ptr,gameoptionsclick.savevehnames
extern gameoptionsgrfstat,gameoptionsgrfstathints,gameoptionstimer
extern heapptr,malloc
extern resolvesprites


ext_frag findwindowstructuse

global patchsetnewgraphics

begincodefragments

codefragment olddrawsignal
	mov di,1
	mov si,di
	mov dh,0xa
	db 0xe8	// call addsprite

codefragment newdrawsignal
	call runindex(drawsignal)
	setfragmentsize 7
	mov dh,0x10		// pre-signals may be higher

codefragment findgameoptionswindowstruc,-20
	dw 13
	dw 0xb1

codefragment newgameoptionsclick
	ijmp gameoptionsclick


endcodefragments

patchsetnewgraphics:
	patchcode olddrawsignal,newdrawsignal,1,1

	call resolvesprites

	// use the memory where the sprite info used to be as a new heap block
	// (inserted at the beginning for simplicity)
	mov esi,spritedata

	mov eax,[heapptr]
	mov dword [esi+heap.left],spriteinfoend-(spritedata+heap_size)
	mov dword [esi+heap.ptr],spritedata+heap_size
	mov [esi+heap.next],eax

	mov [heapptr],esi

	// add grf status window to game options
	stringaddress findgameoptionswindowstruc
	mov [findwindowstructuse.ptr],edi

	stringaddress findwindowstructuse
	mov ebx,edi

	mov esi,[findwindowstructuse.ptr]
	push 22*12+2*12+1
	call malloc
	pop edi
	mov [ebx+3],edi
	mov ebx,[ebx-9]	// window handler
#if WINTTDX
	add ebx,[ebx+1]	// resolve indirect jmp
	add ebx,5
#endif

	mov ecx,22*12
	rep movsb	// copy TTD's window elements
	push esi
	mov esi,gameoptionsgrfstat
	mov cl,2*12
	rep movsb	// copy TTDPatch's window elements
	pop esi
	movsb		// copy cWinElemLast

	// copy hints
	add ebx,0x61
	mov edi,gameoptionsgrfstathints
	mov [ebx+128-0x61],edi

	mov cl,22*2
	rep movsb

	mov edi,ebx
	storefragment newgameoptionsclick
	storerelative gameoptionsclick.savevehnames,ebx+40
	lea edi,[ebx+0x3b4]
	storefunctioncall gameoptionstimer
	mov word [edi+15],0x368d	// two-byte nop
	ret

global spritearraysize
spritearraysize: db 4,2,2,2,2,2,4,1,1,2,2
