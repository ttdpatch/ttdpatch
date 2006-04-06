// full unicode support

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc VARBSET(hasaction12), patchunicode

extern newgraphicssetsavail,newspritexsize,setcharwidthtablefn
extern getcharsprite,drawstringfn,storetextcharacter,gettextwidth
extern splittextlines,hasaction12

begincodefragments

codefragment_jmp newsetcharwidthtables,setcharwidthtables,5
codefragment_jmp newdrawstring,drawstringunicode,5
codefragment_jmp newgettextwidth,gettextwidthunicode,5
codefragment_jmp newsplittextlines,splittextlinesunicode

endcodefragments

patchunicode:
	mov edi,setcharwidthtables
	xchg edi,[setcharwidthtablefn]
	storefragment newsetcharwidthtables
	add edi,lastediadj+10
	mov [getcharsprite],edi
	mov byte [edi+65],0xc3

	mov edi,drawstringunicode
	xchg edi,[drawstringfn]
	storefragment newdrawstring

	mov dword [storetextcharacter],0x0026748d	// lea esi,[byte 0+1*esi]

	mov edi,gettextwidthunicode
	xchg edi,[gettextwidth]
#if WINTTDX
	add edi,[edi+1]
	add edi,5
#endif
	storefragment newgettextwidth

	mov edi,splittextlinesunicode
	xchg edi,[splittextlines]
	storefragment newsplittextlines
	ret
