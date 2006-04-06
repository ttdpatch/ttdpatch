
// Text handler
// Allows displaying our own text by setting a flag

#include <std.inc>
#include <textdef.inc>
#include <systexts.inc>
#include <grf.inc>

extern curspriteblock,customtextptr,gethousetexttable,getmiscgrftable
extern getstationtexttable,gettextintableptr,ntxtptr
extern systemtextptr



uvarb textprocesstodisplay		// set to 1 if the text will be displayed, so the text. ref. stack can be modified

// in:  eax = text code
//	text code & 07ff is the offset into an array of pointers for TTD
//	text code & f800 is a code indicating what type of text to display
// out:	CF=0, si=ax and eax &= 7ff for TTD strings
//	CF=1 and esi=stringptr for TTDPatch strings (custom or static)
global texthandler
texthandler:
	movzx esi,ax
#if DEBUG
	mov word [.lastcode],ax
#endif
	and eax,0x7ff
	cmp si,0xc000
	jae short .ourtext
.noitsnotourtext:
	clc
	ret

.ourtext:
	shr esi,11
	push edi
	mov edi,eax

	mov byte [textprocesstodisplay],1
	call [getttdpatchtables+(esi-0x18)*4]
	mov byte [textprocesstodisplay],0

	mov esi,[eax+edi*4]
	pop edi
	jnc .noadd
	add esi,eax
.noadd:
	stc
	ret

	// this is useful to trap on access to a certain string in memory
	// and then use this variable to figure out what the text index was
#if DEBUG
	align 2
.lastcode: dw 0
#endif

; endp texthandler


	align 4
	// patch text table handlers
	//
	// in:	edi=textID&7ff
	// out:	eax->string table
	//	edi=index into table
	//	carry set if eax has to be added to value in table
var getttdpatchtables
	dd addr(getstationtexttable)	// C000
	dd addr(gethousetexttable)	// C800
	dd addr(getmiscgrftable)	// D000
	dd addr(getpersistentgrftable)	// D800
	dd addr(getnotable)		// E000
	dd addr(getnewstexttable)	// E800
	dd addr(getnotable)		// F000	(used by TTD's critical error numbers?)
	dd addr(getcustomtexttable)	// F800


global getnotable
getnotable:
	mov eax,emptytexttable
	xor edi,edi
	ret

var emptytext, db 0
var emptytexttable, dd emptytext


getnewstexttable:
	mov eax,ntxtptr
	ret


getcustomtexttable:
	cmp edi,ourtext(last) & 0x7ff		// last available entry
	jb .custom

	sub edi,statictext(first) & 0x7ff
	jb getnotable

	mov eax,stxtptr
	ret

.custom:
	mov eax,[customtextptr]
	stc
	ret


// macro to define static texts (i.e. text strings that are not language
// dependent and don't appear in ttdpttxt.dat)
//
// define static texts in patches/stat_txt.ah
//
%macro stxt 2+.nolist	// params: id,textdefinition...
	%ifnctx stxtdef
		%error "stxt macro used outside of stat_txt.ah"
	%endif
	%assign %$stxtnum %$stxtnum+1
%ifndef PREPROCESSONLY
	%define %$thistext %1_addr
%endif
	%if %$stxtnum>1
		%xdefine %$stxts %$stxts,%$thistext
	%else
		%xdefine %$stxts %$thistext
	%endif
	var %1_addr, db %2
%endmacro
%macro stxt_cont 1+.nolist
	%1
%endmacro

%push stxtdef
%assign %$stxtnum 0
#include "stat_txt.ah"

// define four special texts that can be modified by writing
// the text address to specialtext1..specialtext4
// and using statictext(special1/2)
// WARNING: do not use special# strings in error messages
//	    error messages must use specialerr#

	align 4
var stxtptr, dd %$stxts
var specialtext1, dd 0
var specialtext2, dd 0
var specialtext3, dd 0
var specialtext4, dd 0
var specialerrtext1, dd 0
var specialerrtext2, dd 0
var specialerrtext3, dd 0
var specialerrtext4, dd 0

%pop


// Get address of a 'system' text loaded from TTDPatch language data
// in:	AL = text index
// out:	EAX -> text
// NOTE:in WinTTDX text is in UCS-2LE (or UTF-16LE)
//	otherwise it's in an 8-bit DOS codepage
global getsystextaddr
getsystextaddr:
	push esi
	movzx esi,al
	mov eax,[systemtextptr]
	add eax,[eax+esi*4]
	pop esi
	add eax,4*numsystemtexts
	ret

struc persistentgrftext
	.grfid:		resd 1
	.textid:	resw 1
	.stackuse:	resb 1
endstruc_32

uvard persistentgrftextlist,0x400*2

uvard persistentgrfptrs,0x400

var speccharstackchanges, db 4,2,1,2,4,2,0,2,2,2,2,0,2

uvard persistentoverflow

// Called to get or set texts associated to new house types
// in:	edi=text ID & 7ff
//	0xx-3xx = get persistent text (ID must be already resolved)
//	4xx-7xx = set persistent text (ID must be unresolved)
// out:	eax=table ptr
//	edi=table index
// safe: none
getpersistentgrftable:
	btr edi,10
	jc .set
	mov eax,persistentgrfptrs
	cmp byte [textprocesstodisplay],0
	je .exit
	cmp dword [eax+edi*4],0
	jne .exit

	pusha
	movzx esi,byte [persistentgrftextlist+edi*8+persistentgrftext.stackuse]
	mov edi,textrefstack
	add esi,edi
	xor ecx,ecx
	mov cl,32/4
	rep movsd
	popa
	mov ax,ourtext(grftextnotfound)
	jmp gettextintableptr


.set:
	mov eax,[curspriteblock]
	mov eax,[eax+spriteblock.grfid]
	push ecx
	xor ecx,ecx
.nextslot:
	cmp dword [persistentgrftextlist+ecx*8+persistentgrftext.grfid],0
	je .gotit

	cmp [persistentgrftextlist+ecx*8+persistentgrftext.grfid],eax
	jne .notit
	cmp [persistentgrftextlist+ecx*8+persistentgrftext.textid],di
	je .gotit
.notit:
	inc ecx
	cmp ecx,$400
	jb .nextslot

	mov eax,persistentoverflow
	xor edi,edi
	pop ecx
.exit:
	ret

.gotit:
	mov [persistentgrftextlist+ecx*8+persistentgrftext.grfid],eax
	mov [persistentgrftextlist+ecx*8+persistentgrftext.textid],di
	mov byte [persistentgrftextlist+ecx*8+persistentgrftext.stackuse],0xff
	mov eax,persistentgrfptrs
	mov edi,ecx
	pop ecx
	clc
	ret

global lookuppersistenttextid
lookuppersistenttextid:
	push ebx
	movzx eax,ax
	mov ebx,eax
	and bh,0xf8
	cmp bh,0xd8
	jne .exit

	and eax,0x3ff		// mask out bit 10 as well, so GRFs can use both D8xx and DCxx
	mov ebx,[curspriteblock]
	mov ebx,[ebx+spriteblock.grfid]
	push ecx
	xor ecx,ecx

.nextslot:
	cmp [persistentgrftextlist+ecx*8+persistentgrftext.grfid],ebx
	jne .notit
	cmp [persistentgrftextlist+ecx*8+persistentgrftext.textid],ax
	je .gotit

.notit:
	inc ecx
	cmp ecx,$400
	jb .nextslot

	pop ecx
	pop ebx
	mov ax,ourtext(grftextnotfound)
	ret

.gotit:
	mov eax,ecx
	pop ecx
	cmp byte [persistentgrftextlist+eax*8+persistentgrftext.stackuse],0xff
	jne .nogetstackuse
	call .getstackuse
.nogetstackuse:
	or ah,0xd8
.exit:
	pop ebx
	ret

.getstackuse:
	pusha
	mov esi,[persistentgrfptrs+eax*4]
	test esi,esi		// during initialization, there may be cases when the pointer is uninitialized
	jz .finished
	lea edi,[persistentgrftextlist+eax*8+persistentgrftext.stackuse]
	mov byte [edi],0
	mov ebx,speccharstackchanges-0x7b

.nextchar:
	lodsb
	or al,al
	jz .finished
	cmp al,0x7b
	jb .nextchar
	cmp al,0x87
	ja .nextchar

	xlatb
	add [edi],al
	jmp short .nextchar

.finished:
	popa
	ret

global clearpersistenttexts
clearpersistenttexts:
	xor eax,eax
	mov edi,persistentgrftextlist
	mov ecx,$400*2
	rep stosd

	mov edi,persistentgrfptrs
	mov ecx,$400
	rep stosd
	ret
