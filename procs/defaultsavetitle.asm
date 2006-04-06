#include <defs.inc>
#include <frag_mac.inc>


extern defaultsavetitle


global patchdefaultsavetitle

begincodefragments

codefragment olddefaultsavetitle,2
	jnz short $+2+0x3e
	db 0x0f,0xb6,0x35	// movzx esi,byte [human1]

codefragment_call newdefaultsavetitle,defaultsavetitle,5

endcodefragments

patchdefaultsavetitle:
	patchcode defaultsavetitle
	mov word [edi+lastediadj+5],0x3773	// JAE $+2+0x37
	ret
