#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc generalfixes,morecurrencies, patchdiffsettings


extern fndrawstring
extern gettextandtableptrs


patchdiffsettings:
	mov ax,0x6809	// "Initial loan size:..."
	call gettextandtableptrs

	// find the first 0x7f
	mov al,0x7f
	xor ecx,ecx
	dec ecx	// ecx is the maximum now
	repne scasb

//	mov esi,edi
//	add esi,4	// delete four chars (",000")
	lea esi,[edi+4]
.delloop:
	lodsb
	stosb
	or al,al
	jnz .delloop

	xor ecx,ecx
	stringaddress oldshowdifficultynums,1,1
	copyrelative fndrawstring,lastediadj+6
	storefragment newshowdifficultynums
	ret



begincodefragments

codefragment oldshowdifficultynums,-10
	pop ebp
	pop dx
	pop cx
	add dx,0xb

codefragment newshowdifficultynums
	call runindex(showdifficultynums)
	setfragmentsize 10


endcodefragments
