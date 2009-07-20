// full unicode support

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>
#include <window.inc>
#include <imports/gui.inc>

patchproc VARBSET(hasaction12), patchunicode

extern newspritexsize,setcharwidthtablefn
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
	push 0x5a0	// cWinTypeTextEdit or cWinElemRel or cWinElem5
	push 0		// no window ID needed
	push dword [bTextInputMaxLength]	// the max. length and max. width vars
						// are adjacent in memory, so this really pushes both
	icall textinputchar
	jc .esc
	jz fragmentstart+162
	ret
.esc:
	jmp [DestroyWindow]

codefragment oldtextinputchar_savewindow, -11
	jz near $+6+0x23f

codefragment newtextinputchar_savewindow
	push 21h+80h+(7 << 8)			// cWinTypeLoadSave+80h+(7 shl 8)
	movzx eax, word [esi+window.id]
	push eax
	push 46 + (240 << 8)			// max. lenght is 46 chars, max. width is 240 pixels
	icall textinputchar
	jc .done	// ignore ESC
	jz fragmentstart-0x269
.done:
	ret

codefragment oldsetwindowtitle,9
	mov ax,0x2BA

codefragment_call newsetwindowtitle,setwindowtitle,5

codefragment_call newtextinputokbutton,textinputokbutton,5

codefragment_call newtextinputokbutton_savewindow,textinputokbutton_savewindow,5
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

codefragment newMakeStationFacilitiesIconString
	mov eax,0xB382EE	// 0xE0B3 in UTF-8 encoding
.next:
	add eax,0x10000
	shr byte [textrefstack],1
	jnc .nowrite
	mov [edi],eax
	add edi,3
.nowrite:
	jz fragmentstart+45
	jmp .next

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

	patchcode textinputchar_savewindow
	add edi,lastediadj-0x269
	storefragment newtextinputokbutton_savewindow

	patchcode setwindowtitle
#endif

	patchcode formatnewsmsg

	mov eax,[opclass(5)]
	mov eax,[eax+8]		// text handler
	mov eax,[eax+10]	// special handler for 30D2
	mov edi,[eax+0xD1*4]
	storefragment newMakeStationFacilitiesIconString

	extern winelemdrawptrs,str_window_slider_up,str_window_slider_dn
	mov eax,[winelemdrawptrs+cWinElemSlider*4]
	mov dword [eax+121],str_window_slider_up
	mov dword [eax+146],str_window_slider_dn
	ret
