#include <defs.inc>
#include <frag_mac.inc>


extern trainspeed_dest
extern trainspeed_edi


global patchshowspeed

begincodefragments

codefragment oldtrainspeed
	mov bx,0x8810
	movzx ebp,ax

codefragment newtrainspeed
	call runindex(trainspeed)
	setfragmentsize 10


endcodefragments

patchshowspeed:
	xor eax,eax
	mov al,4
	mov ecx,eax

.nextsearch:
	push eax
	stringaddress oldtrainspeed,1,ecx

		// follow a short jump
	movzx eax,byte [edi-1]
	add edi,eax

		// read EDI value
	mov eax,[edi+1]
	mov dword [trainspeed_edi],eax

			// store the CALL target in a jmp in trainspeed
	copyrelative trainspeed_dest,6
	storefragment newtrainspeed

	// ECX=0 now, so the next search will continue
	pop eax
	dec eax
	jnz .nextsearch
	ret
