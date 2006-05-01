// full unicode support

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc VARBSET(hasaction12), patchunicode

extern newgraphicssetsavail,newspritexsize,setcharwidthtablefn
extern getcharsprite,drawstringfn,storetextcharacter,gettextwidth
extern splittextlines,hasaction12,setwindowtitle

begincodefragments

codefragment_jmp newsetcharwidthtables,setcharwidthtables,5
codefragment_jmp newdrawstring,drawstringunicode,5
codefragment_jmp newgettextwidth,gettextwidthunicode,5
codefragment_jmp newsplittextlines,splittextlinesunicode

#if WINTTDX
codefragment oldtextinputchar,-16
	db 0
	cmp al,0x1b
	db 0x0f,0x84	// jz CloseWindow

codefragment newtextinputchar
	icall textinputchar
	jc fragmentstart+19
	jz fragmentstart+27
	ret

codefragment oldsetwindowtitle,9
	mov ax,0x2BA

codefragment_call newsetwindowtitle,setwindowtitle,5

codefragment_call newtextinputokbutton,textinputokbutton,5
#endif

codefragment oldbuildcompanyname
	mov al,[ecx]
	mov [ebx],al
	inc ecx

codefragment newbuildcompanyname
	icall buildcompanyname

codefragment oldformatnewsmsg,-15
	cmp al,0x88
	jb $+2+4
	cmp al,0x99

codefragment newformatnewsmsg
	icall formatnewsmessage
	jmp fragmentstart+39

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

	patchcode buildcompanyname

#if WINTTDX
	patchcode textinputchar
	add edi,lastediadj+162
	storefragment newtextinputokbutton
	patchcode setwindowtitle
#endif

	patchcode formatnewsmsg
	ret
