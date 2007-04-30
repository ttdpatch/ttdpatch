// Text handler
// Allows displaying our own text by setting a flag

#include <std.inc>
#include <textdef.inc>
#include <systexts.inc>
#include <grf.inc>
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>

extern curspriteblock,customtextptr,gethousetexttable,getmiscgrftable
extern getstationtexttable,gettextintableptr,ntxtptr
extern systemtextptr,mainstringtable,getextratranstable,hasaction12
extern restoreelrailstexts,patchflags,applycurrencychanges,ttdtexthandler
extern storeutf8char
extern failpropwithgrfconflict,lastextragrm,curextragrm
extern restorevehnametexts

uvard ourtext_ptr, ourtext(last)-ourtext(base)+1	// +1 otherwise last overwrites the following uvard in memory

uvarb textprocesstodisplay		// set to 1 if the text will be displayed, so the text. ref. stack can be modified
svarb textrecursionlevel		// -1 = primary call, 0+ = recursive
uvard textrefstackind			// current index into textrefstack
uvard textutf8flag			// 32 bits of UTF-8-ness for each recursion level
uvard continueflag			// same but just specifying whether we've check UTF-8-ness or not
uvard textprocchar			// handler to process one character (UTF-8 or regular)
uvard textspechandler			// TTD's handlers for special text codes

uvard fonttables,3*256			// Pointer to font info for sizes normal,small,large

uvard newtexthandlerfunctrap		//optional callback whenever text handler function parameters or text ref need to be trapped/modified


// in:  ax=text ID
//	text ID & 07ff is the offset into an array of pointers for TTD
//	text ID & f800 is a code indicating what type of text to display
//	edi->buffer where to store text
// safe:eax ebx (ecx?) edx esi ebp
global newtexthandler,textprocessing
newtexthandler:
	mov esi, [newtexthandlerfunctrap]
	or esi, esi
	jz .notrap
	call esi
.notrap:
	push .strangeret		// for detecting handlers that do not return
	shl dword [continueflag],1
	jc .rectoodeep
	shl dword [textutf8flag],1
	or esi,byte -1
	add byte [textrecursionlevel],1
	js .strangeadd
	adc esi,0
	and [textrefstackind],esi	// set to 0 for primary call, leave alone for recursive ones

	movzx esi,byte [textrecursionlevel]
	mov word [lasttextids+esi*2],ax

	movzx esi,ah
	and eax,0x7ff
	shr esi,3
	cmp esi,0xc0>>3
	jae short .ourtext

	cmp word [textclass_maxid+esi*2],0
	je .valid
	cmp ax,[textclass_maxid+esi*2]
	jae .invalid

.valid:
	test esi,esi
	jnz .classtext

.generaltext:
	mov esi,[mainstringtable]
	mov esi,[esi+eax*4]
	jmp short .doproc

.rectoodeep:	// more than 32 levels of recursion
	ud2

.strangeret:	// something messed up the stack
	ud2

.strangeadd:	// overflow, should be impossible
	ud2

.strangedec:	// underflow, should be impossible
	ud2

.invalid:
	xor esi,esi
	jmp short .doproc

.ourtext:
	call texthandler.ourtext_noshr

.doproc:
	call textprocessing
	jmp short .done

.classtext:
	mov ebp,[ophandler+esi*8-8]
	call [ebp+8]

.done:
	pop eax
	movzx eax,byte [textrecursionlevel]
	mov word [lasttextids+eax*2],-1
	dec byte [textrecursionlevel]
	jo .strangedec
	shr dword [textutf8flag],1
	shr dword [continueflag],1
	mov al,0
	mov [edi],al
	ret

global texthandler
texthandler:
	movzx esi,ah
	and eax,0x7ff
	cmp esi,0xc0
	jae .ourtext
.noitsnotourtext:
	clc
	ret

.ourtext:
	shr esi,3
.ourtext_noshr:
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

textprocessing:
	bts dword [continueflag],0
	jc .continue

	test esi,esi
	jle .undef

.resumeundef:
	cmp word [esi],0x9EC3		// first char = Thorn (C3 9E) -> UTF-8
	jne .continue

.utf8:
	lodsw				// remove code character from string
	or dword [textutf8flag],1	// set bit 0

.continue:
	bt dword [textutf8flag],0
	sbb ebx,ebx
	and ebx,byte .procutf8-.procnonutf8
	add ebx,.procnonutf8
	mov [textprocchar],ebx
	jmp ebx

.undef:
	movzx eax,byte [textrecursionlevel]
	mov ax,[lasttextids+eax*2]
	mov esi,undefid
	mov ecx,4
.nextdigit:
	mov ebx,eax
	and ebx,15
	extern hexdigits
	mov bl,[hexdigits+ebx]
	mov [esi+undefid.id1-undefid+ecx-1],bl
	mov [esi+undefid.id2-undefid+ecx-1],bl
	shr eax,4
	loop .nextdigit
	jmp .resumeundef

.done:
	ret

.procutf8:		// get UTF-8 sequence start byte and validate
	xor eax,eax
	lodsb
	cmp al,0x7b
	jb .gotchar
	mov bl,1
	cmp al,0x80	// is it ASCII that'd be a format statement? if so, just store it
	jb near .store	// C0 and C1 would decode to ASCII, so they're invalid
	cmp al,0xc2	// and 80..BF are continuation characters, they cannot
	jb .trlchar	// start a sequence, so use them verbatim to support
	cmp al,0xfe 	// the old-style \80 etc. codes;
	ja .trlchar	// FE/FF are always invalid in UTF-8

	// otherwise, decode the UTF-8 sequence
	mov dl,al
	mov dh,-1
	mov bl,0xff	// first count how many bytes are in the sequence
.count:			// which is given by how many high bits al had set
	inc dh		// so count those by shifting them out until SF=0
	shr bl,1	// also adjust the mask in BL that we'll use to
	add dl,dl	// extract value bits from al
	js .count

	// we could do some more validation here, we have an overlong (invalid)
	// sequence if [esi] & bl == 80; but since these have security
	// implications only if comparing UTF-8 strings, we'll skip this

	and ebx,eax	// ebx will contain the full character code

	// now dh=sequence length-1; ebx=value of first byte
.getbyte:
	lodsb
	cmp al,0x80	// make sure the next byte is a continuation character
	jb .invutf8	// which means it must be 80..BF; below is ASCII and
	cmp al,0xbf	// above is a sequence start character; both would be
	ja .invutf8	// invalid here

	shl ebx,6	// next byte in sequence provides 6 new bits (LSB)
	and al,0x3f
	or bl,al
	dec dh
	jnz .getbyte
	mov eax,ebx
	jmp short .gotchar

.invutf8:	// invalid UTF-8 sequence; have to put the new byte back
	dec esi
	mov [esi],al
	mov al,' '	// substitute a space; FIXME: use a "invalid char" code here
	jmp short .gotchar

.trlchar:	// invalid UTF-8 start character, use it as TTD string code
	cmp byte [hasaction12],0
	je .gotchar

	// when using unicode fonts, translate old codes to allow access
	// to full latin-1 supplement block (U+00A0..U+00FF)
	cmp al,0x9e
	jb .gotchar
	cmp al,0xbd
	ja .gotchar

	mov ax,[.chartrl+(eax-0x9e)*2]

	// make sure the block exists
	movzx ebx,ah
	cmp dword [fonttables+ebx*4],0	// check normal font; if it exists all of them do
	je .badchar
	jmp short .gotchar

noglobal varw .chartrl
	dw 0x20AC	// 9E Euro character
	dw 0x0178	// 9F Capital Y umlaut
	dw 0xE0A0	// A0 Scroll button up
	dw 0xA1,0xA2,0xA3,0xA4,0xA5,0xA6,0xA7,0xA8,0xA9
	dw 0xE0AA	// AA Scroll button down
	dw 0xAB
	dw 0xE0AC	// AC Tick mark
	dw 0xE0AD	// AD X mark
	dw 0xAE
	dw 0xE0AF	// AF Scroll button right
	dw 0xB0,0xB1,0xB2,0xB3
	dw 0xE0B4	// B4 Train symbol
	dw 0xE0B5	// B5 Truck symbol
	dw 0xE0B6	// B6 Bus symbol
	dw 0xE0B7	// B7 Plane symbol
	dw 0xE0B8	// B8 Ship symbol
	dw 0xE0B9	// Superscript -1
	dw 0xBA,0xBB
	dw 0xE0BC	// Small scroll button up
	dw 0xE0BD	// Small scroll button down
endvar

.badchar:
	mov eax,' '
	jmp short .gotchar

.procnonutf8:
	xor eax,eax
	lodsb

.gotchar:
	mov bl,1
	test eax,eax
	jz .done

	cmp eax,10
	jb .two	// changed from jbe to jb so 0x10 can be passed through the texthandler (eis_os)

	cmp eax,15
	jbe .store

	cmp eax,31
	jbe .three

	cmp eax,0x7b
	jb .store

	cmp eax,0x9e
	jb .special

	cmp eax,0x100
	jae .unicode

	mov ah,0xe0
	jmp short .store	// E0 is ignored in non-utf8 mode

.unicode:
	cmp eax,0xe07b
	jb .store

	cmp eax,0xe09e
	jnb .store

.special:
	cmp al,0x99
	je .two
	ja .extspecial
	cmp al,0x88
	jnb .coloring
	movzx eax,al
	mov ebx,[textspechandler]
	jmp [ebx+(eax-0x7b)*4]

.extspecial:
	jmp [extspechandler+(eax-0x9A)*4]

.three:
	inc bl

.two:
	inc bl

.coloring:
	cmp byte [skipcolor],0
	jne storetextcharacter.skipcolor

.store:
global storetextcharacter
storetextcharacter:
	stosb			// this and the jmp will be nopped out
	jmp short .storenext	// if unicode fonts are loaded
	nop			// nop to make it exactly 4 bytes

	call storeutf8char

.storenext:
	dec bl
	jz .resume
	// copy arguments for codes 01 and 1F
	movsb
	jmp .storenext
.skipcolor:
	dec byte [skipcolor]
.resume:
	jmp [textprocchar]


	// this is useful to trap on access to a certain string in memory
	// and then use this variable to figure out what the text index was
svarw lasttextids, 32

varb undefid
	db "(",0x8b,"UD:"
.id1:	db "####",0x98,":"
.id2:	db "####)",0
endvar

; endp texthandler

// string code 9A handlers
vard extstringformat
	dd print64bitcost,print64bitcost,skipnextcolor
numextstringformat equ ($-extstringformat)/4
endvar

// handlers for string codes 9A, 9B, 9C, 9D
vard extspechandler, .extformat, .nothing, .nothing, .nothing

.extformat:
	xor eax,eax
	lodsb
	cmp eax,0+numextstringformat
	jae .nothing
	call [extstringformat+eax*4]
.nothing:	
	jmp textprocessing

print64bitcost:
	mov ebx,[textrefstack]
	mov edx,[textrefstack+4]

	mov eax,[textrefstack+8]
	mov [textrefstack],eax
	mov eax,[textrefstack+0xC]
	mov [textrefstack+4],eax
	mov eax,[textrefstack+0x10]
	mov [textrefstack+8],eax
	mov eax,[textrefstack+0x14]
	mov [textrefstack+0xC],eax

	mov eax,ebx
	extern printcash_64bit
	jmp printcash_64bit

noglobal uvarb skipcolor

skipnextcolor:
	inc byte [skipcolor]
	ret

	// patch text table handlers
	//
	// in:	edi=textID&7ff
	// out:	eax->string table
	//	edi=index into table
	//	carry set if eax has to be added to value in table
vard getttdpatchtables
	dd addr(getstationtexttable)	// C000
	dd addr(gethousetexttable)	// C800
	dd addr(getmiscgrftable)	// D000
	dd addr(getpersistentgrftable)	// D800
	dd addr(getextratranstable)	// E000
	dd addr(getnewstexttable)	// E800
	dd addr(getnotable)		// F000	(used by TTD's critical error numbers?)
	dd addr(getcustomtexttable)	// F800
endvar

// maximum ID defined in each class, for action 4
varw textclass_maxid
	dw 0x0334,0x0810,0x1024,0x1818,0x205c,0x2810,0x306c,0x3807
	dw 0x4010,0x483b,0x5029,0x5807,0x6018,0x6838,0x707f,0
	dw 0x8107,0x886b,0x9037,0x9842,0xa043,0,     0xb005,0
	dw 0xc3ff,0xcbff,0xd3ff,0xdbff,0xe04c,0,     0,     ourtext(last)-1
endvar


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
	mov eax,ourtext_ptr
	cmp edi,ourtext(last) & 0x7ff		// last available entry
	jnb .notourtext
	clc
	ret

.notourtext:
	sub edi,statictext(first) & 0x7ff
	jb getnotable

	mov eax,stxtptr
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
#include <stat_txt.inc>

%if %$stxtnum > 510
%error "Too many static texts: %$stxtnum"
%endif

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
endstruc

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

	pusha
	mov al,GRM_EXTRA_PERSTEXTS
	call failpropwithgrfconflict
	popa

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

global initourtextptr
initourtextptr:
	mov edi,ourtext_ptr
	mov eax,emptytext
	mov ecx,ourtext(last)-ourtext(base)
	push edi
	rep stosd
	pop edi

	mov esi,[customtextptr]
	xor eax,eax
.nexttxt:
	lodsw
	mov ebx,eax
	cmp ax,byte -1
	je .done
	cmp ax,ourtext(last)-ourtext(base)
	jbe .ok
	ud2
.ok:
	lodsw
	mov [edi+ebx*4],esi
	add esi,eax
	jmp .nexttxt
.done:
	ret

global resetourtextptr
resetourtextptr:
	pusha
	call initourtextptr
	testmultiflags electrifiedrail
	jz .noelrails
	call restoreelrailstexts
.noelrails:
	call applycurrencychanges

	testflags generalfixes
	jnc .norestorevehtexts
	test dword [miscmodsflags],MISCMODS_USEVEHNNUMBERNOTNAME
	jnz .norestorevehtexts

	call restorevehnametexts

.norestorevehtexts:
	popa
	ret

global newtextcopy
newtextcopy:
	push dword [specialtext1]
	mov [specialtext1],esi
	mov ax,statictext(special1)
	call [ttdtexthandler]
	pop dword [specialtext1]
	ret

uvarb FrSpaTownNameFlags,156

global findFrSpaTownNameFlags
findFrSpaTownNameFlags:
	xor ecx,ecx

.nexttext:
	mov eax,[esi]
	add esi,4
.nextchar:
	cmp byte [eax],0x20
	jb .foundit
	inc eax
	jmp short .nextchar

.foundit:
	mov bl,[eax]
	mov [FrSpaTownNameFlags+ecx],bl
	mov byte [eax],0

	inc ecx
	cmp ecx,156
	jb .nexttext

	ret

global SpaTownNameCopy
SpaTownNameCopy:
	mov eax,[textrefstack]
	mov al,[FrSpaTownNameFlags+eax]
	mov [tempvar],al
	jmp short newtextcopy

global addparentdir
addparentdir:
	mov edi,baTempBuffer1

	push ss
	pop es

	push dword [specialtext1]
	push ecx
	push edx
	mov [specialtext1],esi
	mov ax,statictext(special1)
	call [ttdtexthandler]
	pop edx
	pop ecx
	pop dword [specialtext1]

	mov esi,baTempBuffer1

	mov al,1
	xor ebp,ebp
	ret

global adddir1
adddir1:
	push ss
	pop es

	push esi

.nextchar:
	mov al,[esi]
	mov [ebx],al
	inc esi
	inc ebx
	test al,al
	jnz .nextchar

	pop esi

	push dword [specialtext1]
	push ecx
	push edx
	mov [specialtext1],esi
	mov ax,statictext(special1)
	call [ttdtexthandler]
	pop edx
	pop ecx
	pop dword [specialtext1]

	inc edi
	ret

global addsavegame
addsavegame:
	mov edi,baTempBuffer2

	push dword [specialtext1]
	push ecx
	push edx
	mov dword [specialtext1],baTempBuffer1
	mov ax,statictext(special1)
	call [ttdtexthandler]
	pop edx
	pop ecx
	pop dword [specialtext1]

	mov esi,baTempBuffer2
	ret
