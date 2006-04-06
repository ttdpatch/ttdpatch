#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc canmodifygraphics,buildonslopes, patchspritesorting

extern miscmodsflags,patchflags,spritesorter,spritesorter.spritelistptr
extern spritesorter.spritesorttableofs
extern usecurrspritedescptr

def_indirect usecurrspritedescptr
def_indirect savecurrspritedescptr

patchspritesorting:
	stringaddress oldsavecurrspritedescptr

	test byte [miscmodsflags+2],MISCMODS_NONEWSPRITESORTER>>16
	jz .newsorter

	testmultiflags recordversiondata
	jnz .newsorter

	storefragment newsavecurrspritedescptr
	add dword [esi+lastediadj+currspritedescptr.fn],0+usecurrspritedescptr_indirect-savecurrspritedescptr_indirect
	add edi,lastediadj+77
	storefragment newsavecurrspritedescptr
	ret

.newsorter:
	mov eax,[edi-47]
	mov [spritesorter.spritelistptr],eax

	mov eax,[edi+68]
	mov [spritesorter.spritesorttableofs],eax

	stringaddress oldcallspritesorter

	mov eax,addr(spritesorter)-4
	sub eax,edi
	mov [edi],eax
	ret



begincodefragments

codefragment oldsavecurrspritedescptr
	mov [tempvar],edi
	db 0x83			// add...

codefragment newsavecurrspritedescptr
	call runindex(savecurrspritedescptr)
currspritedescptr.fn equ $-4-fragmentstart

codefragment oldcallspritesorter,-24
	add esp,21000


endcodefragments
