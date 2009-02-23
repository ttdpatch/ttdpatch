//
// Unicode / UTF-8 drawing support
//
#include <defs.inc>
#include <proc.inc>
#include <var.inc>
#include <font.inc>
#include <misc.inc>
#include <ttdvar.inc>
#include <flags.inc>
#include <bitvars.inc>
#include <win32.inc>
#include <textdef.inc>
#include <window.inc>

extern fonttables,drawspriteonscreen,malloc,patchflags
extern tempSplittextlinesNumlinesptr,splittextlines_done
extern invalidatehandle,newtexthandler,specialtext1,specialtext2

// Strings that were hardcoded into TTD and are used without the texthandler
varb str_window_slider_up, 0xEE, 0x82, 0xA0, 0
varb str_window_slider_dn, 0xEE, 0x82, 0xAA, 0

// Initialize the font glyph tables with TTD's characters
exported initglyphtables
	mov esi,fonttables	// first make sure all allocated font tables are cleared
.clearnext:
	lodsd
	test eax,eax
	jle .notable
	mov edi,eax
	xor eax,eax
	mov ecx,fontinfo_size*256/4
	rep stosd
.notable:
	cmp esi,fonttables+4*3*256
	jb .clearnext

	xor eax,eax
	call allocfonttable	// make sure at least first block is allocated
	mov edi,eax

	mov eax,0xE0		// as well as the "Private Use Area" we reserve
	call allocfonttable

	mov ebx," "
	mov edx,2
	mov ecx,0xe0		// number of characters in trg1.grf per font
	mov esi,[edi]
	mov ebp,[eax]
.nextcharfont1:
	mov [esi+ebx*fontinfo_size+fontinfo.sprite],dx
	mov [ebp+ebx*fontinfo_size+fontinfo.sprite],dx
	inc ebx
	inc edx
	loop .nextcharfont1
	mov ebx," "
	mov ecx,0xe0
	mov esi,[edi+256*4]
	mov ebp,[eax+256*4]
.nextcharfont2:
	mov [esi+ebx*fontinfo_size+fontinfo.sprite],dx
	mov [ebp+ebx*fontinfo_size+fontinfo.sprite],dx
	inc ebx
	inc edx
	loop .nextcharfont2
	mov ebx," "
	mov ecx,0xe0
	mov esi,[edi+512*4]
	mov ebp,[eax+512*4]
.nextcharfont3:
	mov [esi+ebx*fontinfo_size+fontinfo.sprite],dx
	mov [ebp+ebx*fontinfo_size+fontinfo.sprite],dx
	inc ebx
	inc edx
	loop .nextcharfont3

	// also the U+20xx block for the euro symbol, if enabled
	testmultiflags morecurrencies
	jz .noeuro
	test byte [morecurropts],morecurrencies_noeuro
	jnz .noeuro

	mov eax,0x20
	call allocfonttable
	mov esi,[eax]
	mov word [esi+0xAC*fontinfo_size+fontinfo.sprite],0x80
	mov esi,[eax+256*4]
	mov word [esi+0xAC*fontinfo_size+fontinfo.sprite],0x160
	mov esi,[eax+512*4]
	mov word [esi+0xAC*fontinfo_size+fontinfo.sprite],0x240
.noeuro:

	// and finally the Capital Y umlaut U+0178
	mov eax,0x01
	call allocfonttable
	mov esi,[eax]
	mov word [esi+0x78*fontinfo_size+fontinfo.sprite],0x81
	mov esi,[eax+256*4]
	mov word [esi+0x78*fontinfo_size+fontinfo.sprite],0x161
	mov esi,[eax+512*4]
	mov word [esi+0x78*fontinfo_size+fontinfo.sprite],0x241
	ret

// Allocate font table for one block
//
// in:	eax=block number
// out:	eax->fonttables+block*4
// uses:eax
exported allocfonttable
	lea eax,[fonttables+eax*4]
	cmp dword [eax],0
	jne .ok

	push fontinfo_size*3*256	// 3 fonts with 256 tables each
	call malloc
	xchg ebx,[esp]
	mov [eax],ebx
	add ebx,fontinfo_size*256
	mov [eax+256*4],ebx
	add ebx,fontinfo_size*256
	mov [eax+512*4],ebx
	pop ebx

.ok:
	ret

// Replacement for TTD's SetCharWidthTables proc
proc setcharwidthtables
	local font,table,ftable,char

	_enter

	and dword [%$font],0
	and dword [%$table],0
	and dword [%$ftable],0

.nexttable:
	mov edi,[%$table]
	mov edi,[fonttables+edi*4]
	test edi,edi
	jz .notable

	and dword [%$char],0
.nextchar:
	mov ebx,[%$char]
	movzx ebx,word [edi+ebx*fontinfo_size+fontinfo.sprite]
	test ebx,ebx
	jz .nochar

	call [getcharsprite]

	mov ebx,[%$char]

	// now esi->sprite data
	mov al,[esi+2]

	cmp dword [%$font],0
	je .first

	inc al	// all but normal font have an extra pixel width (why?)

.first:
	cmp dword [%$ftable],0
	jne .notempty

	cmp bl,' '
	jb .empty	// control characters have no width
	cmp bl,0x7b
	jb .notempty
	cmp bl,0x9d
	ja .notempty

.empty:		// this character has no width, not even the one minimum pixel in the grf
	mov al,0

.notempty:
	mov [edi+ebx*fontinfo_size+fontinfo.width],al

.nochar:
	inc byte [%$char]
	jnz .nextchar

.notable:
	inc dword [%$table]
	inc byte [%$ftable]
	jnz .nexttable

	and dword [%$ftable],0
	inc dword [%$font]
	cmp dword [%$font],3
	jb .nexttable

	_ret
endproc

uvard getcharsprite	// DO NOT use this unless UTF-8 support is active!


// draw string, with UTF-8 support
//
// in:	esi->string
//	edi->screen update block descriptor
//	cx,dx = screen X/Y
//	al=colour
// out:	cx/dx = position at which drawing stopped
// safe:all but edi
exported drawstringunicode
	mov [xpos],cx
	mov [ypos],dx

	cmp al,-2
	je .skipcheck

	mov bx,[edi+scrnblockdesc.x]
	add bx,[edi+scrnblockdesc.width]
	cmp cx,bx
	jge .done

	mov bx,cx
	add bx,1280
	cmp bx,[edi+scrnblockdesc.x]
	jle .done

	mov bx,[edi+scrnblockdesc.y]
	add bx,[edi+scrnblockdesc.height]
	cmp dx,bx
	jge .done

	mov bx,dx
	add bx,480
	cmp bx,[edi+scrnblockdesc.y]
	jnle .isinview

.done:
	ret

.isinview:
	cmp al,-1
	je .skipcheck

.getcolor:
	push edi
	push esi
	movzx eax,al
	mov ebx,674
	call [getcharsprite]

	// get colours for the two font colours
	mov ax,[esi+eax*2+8]
	mov [currenttextcolor],ax

	// "fake" color translation map, uses currenttextcolor for indices 0 and 1
	mov dword [temprecolormapsprite],currenttextcolor-1
	mov [temprecolormapsprite+4],ds
	pop esi
	pop edi

.skipcheck:
	mov ax,dx
	add ax,13h
	cmp ax,[edi+scrnblockdesc.y]
	jle near .skipline

	mov ax,[edi+scrnblockdesc.y]
	add ax,[edi+scrnblockdesc.height]
	cmp ax,dx
	jle near .skipline

.nextchar:
	call getutf8char
.checkchar:
	test eax,eax
	jz .done
	cmp eax,99h
	je near .getccol
	ja .drawchar
	cmp eax,88h
	jae near .getnewcol
	cmp eax,20h
	jb near .special

.drawchar:
	mov bx,[edi+scrnblockdesc.x]
	add bx,[edi+scrnblockdesc.width]
	cmp cx,bx
	jge near .skipline

	mov bx,cx
	add bx,26
	cmp bx,[edi+scrnblockdesc.x]

	// get char info without affecting flags
	mov ebx,ecx
	movzx ecx,word [currentfont]
	lea ecx,[ecx*2]			// double ebx without affecting flags
	movzx ecx,ch			// now ebx=0/1/3 for normal/small/large
	mov ecx,[fonttableofs+ecx*4]	// now ebx=0/256/512 for normal/small/large
	mov cl,ah
	mov ecx,[fonttables+ecx*4]
	jecxz .badtable			// skip bad chars without affecting flags
	xchg ebx,ecx
.getfontinfo:
	movzx eax,al
	mov ebx,[ebx+eax*fontinfo_size]	// now ebx=fontinfo

	movzx eax,bl	// width

	// because we need the flags to be intact here
	jl .skipcharwidth

	shr ebx,16
	jz .skipcharwidth	// no sprite?

	push eax
	push ecx
	push edx
	push edi
	push esi
	call [getcharsprite]
	mov ax,1
	call [drawspriteonscreen]
	pop esi
	pop edi
	pop edx
	pop ecx
	pop eax
.skipcharwidth:
	add ecx,eax
	jmp .nextchar

.badtable:
	mov ebx,[fonttables]
	mov al,'?'
	jmp .getfontinfo

.special:
	cmp al,13
	je .linefeed
	cmp al,1
	je .xspace
	cmp al,1fh
	je .xyspace
	cmp al,0eh
	je .fontsize1
	cmp al,0fh
	jne .nextchar

.fontsize2:
	mov word [currentfont],0x1c0
	jmp .nextchar

.fontsize1:
	mov word [currentfont],0xe0
	jmp .nextchar

.xyspace:
	lodsw
	mov cx,[xpos]
	add cl,al
	adc ch,0
	mov dx,[ypos]
	add dl,ah
	adc dh,0
	jmp .nextchar

.xspace:
	lodsb
	mov cx,[xpos]
	add cl,al
	adc ch,0
	jmp .nextchar

.linefeed:
	movzx ebx,word [currentfont]
	lea ebx,[ebx*2]
	movzx ebx,bh			// now ebx=0/1/3 for normal/small/large
	mov cx,[xpos]
	add dx,[lineheight+ebx*2]
	jmp .nextchar

.getccol:
	call getutf8char
	// fall through

.getnewcol:
	sub al,0x88
	jmp .getcolor

.skipline:
	call getutf8char
	cmp eax,20h
	jb .checkchar
	cmp eax,99h
	jnb .skipline
	cmp eax,88h
	jnb .getnewcol
	jmp .skipline

uvarw xpos
uvarw ypos
varw lineheight, 10,6,0,22

vard fonttableofs, 0,256,0,512

// read UTF-8 encoded character
// does no validity checking, the string must be correct UTF-8
//
// in:	esi->string data
// out:	eax=character
//	esi adjusted
// uses:---
exported getutf8char
	push ebx
	xor eax,eax
	lodsb
	cmp al,0xc2
	jb .done
	// see texthndl.asm for how this works; this is merely a simpler version
	mov bh,al
	mov ah,-1
	mov bl,0xff
.count:
	inc ah
	shr bl,1
	add bh,bh
	js .count
	and bl,al
	movzx ebx,bl
.next:
	lodsb
	shl ebx,6
	and al,0x3f
	or bl,al
	dec ah
	jnz .next
	mov eax,ebx
.done:
	pop ebx
	ret

// store UTF-8 encoded character
//
// in:	eax=character
//	edi->string
// out:	edi->string past encoded character
// uses:eax ebx edx
exported storeutf8char

.storeutf8:
	cmp eax,0x7f		// ASCII?
	jbe .gotutf8code

	mov dl,al		// edx: all-but-last sequence bytes
	and dl,~0x40		// LSB of eax will be last byte in sequence
	or dl,0x80
	movzx edx,dl		// (now edx=eax[0:5] with bit 7 set)

	// check how long the sequence will be
	// bh is the high-bit mask for the start-of-sequence byte
	mov bh,011100000b	// for U+0080..U+07FF, use two-byte sequence
	cmp eax,0x7ff
	jbe .nextutf8byte

	mov bh,011110000b	// for U+0800..U+FFFF, use three-byte sequence
	cmp eax,0xffff
	jbe .nextutf8byte

.badchar:		// U+10000 and above not supported (beyond the BMP)
	mov eax,' '	// substitute a space; FIXME: use a "invalid char" code here
	jmp .storeutf8

.nextutf8byte:
	shl edx,8		// push back bytes so far
	shr eax,6		// and get next 6 bits from eax
	cmp eax,0x40		// do we have more bits after this?
	jb .lastutf8byte
	mov dl,al
	and dl,0x3f
	or dl,0x80		// make dl the next sequence byte
	jmp .nextutf8byte
.die:
	ud2
.lastutf8byte:
	or eax,edx
	test al,bh	// check that eax has no high bits set
	jnz .die	// if this happens, something is wrong in the algorithm above
	add bh,bh	// remove lowest high bit from bl
	or al,bh	// and use bl to make al the sequence start byte

.gotutf8code:	// now eax holds the 1-byte ASCII code or
		// 2-3 bytes of the UTF-8 sequence in LSB->MSB order

.storenextutf8:
	stosb
	shr eax,8
	jnz .storenextutf8
	ret

// find out number of bytes needed to UTF-8 encode character
//
// in:	eax=character
// out:	edx=number of bytes
// uses:---
exported getutf8numbytes
	mov edx,4
	cmp eax,0x80
	sbb edx,0
	cmp eax,0x800
	sbb edx,0
	cmp eax,0x10000
	sbb edx,0
	ret

// called to get width of string
//
// in:	esi->string
// out:	cx=width in pixels
//	ebx=final font
// safe:eax,esi
exported gettextwidthunicode
	push edx
	or cx,byte -1
	movzx ebx,word [currentfont]
	lea ebx,[ebx*2]
	movzx ebx,bh			// now ebx=0/1/3 for normal/small/large
	mov ebx,[fonttableofs+ebx*4]	// now ebx=0/256/512 for normal/small/large

.nextchar:
	call getutf8char
	test eax,eax
	jz .done

	call getutf8charwidth
	add cx,ax
	cmp cx,[maxtextwidth]
	jbe .nextchar

	or word [maxtextwidth],byte -1

.done:
	imul ebx,0xe0
	pop edx
	ret

svarw maxtextwidth

// get width of next character in UTF-8 encoded string
//
// in:	eax=character
//	esi->string past character
//	bh=font type (normal/micro/big)
// out:	eax=width
//	esi->string past character's arguments (if any)
//	bh=updated font type
// uses:edx
getutf8charwidth:
	cmp eax,byte " "
	jb .special

	movzx edx,ah
	add dh,bh
	mov edx,[fonttables+edx*4]
	movzx eax,al
	mov al,[edx+eax*fontinfo_size+fontinfo.width]
.done:
	ret

.special:
	cmp al,0x0a
	jbe .skip
	cmp al,0x0e
	jb .done
	je .smallfont
	cmp al,0x0f
	je .largefont
	add esi,2

.nochar:
	xor eax,eax
	ret

.skip:
	inc esi
	jmp .nochar
.smallfont:
	mov bh,1
	jmp .nochar
.largefont:
	mov bh,2
	jmp .nochar

// split text into lines of max. width
//
// in:	esi->string
//	di=max. width
// out:	di=number of lines
//	ebx=final font
// safe:eax,cx,esi
exported splittextlinesunicode
	push edx
	movzx ebx,word [currentfont]
	lea ebx,[ebx*2]
	movzx ebx,bh			// now ebx=0/1/3 for normal/small/large
	mov ebx,[fonttableofs+ebx*4]	// now ebx=0/256/512 for normal/small/large
	mov edx,[tempSplittextlinesNumlinesptr]
	and word [edx],0

.nextline:
	xor cx,cx
	and dword [lastspace],0

.nextchar:
	call getutf8char
	test eax,eax
	jz .done

	cmp eax,byte " "
	jne .notspace

	dec esi
	mov [lastspace],esi
	inc esi

.notspace:
	cmp eax,13
	je .newline

	call getutf8charwidth

	add cx,ax
	cmp cx,di
	jbe .nextchar

	mov esi,[lastspace]
	test esi,esi
	jz .done

.breakline:
	mov edx,[tempSplittextlinesNumlinesptr]
	inc word [edx]
	mov byte [esi],0
	inc esi
	jmp .nextline

.newline:
	dec esi
	jmp .breakline

.done:
	mov edx,[tempSplittextlinesNumlinesptr]
	mov di,[edx]
	imul ebx,0xe0
	pop edx
	jmp splittextlines_done

uvard lastspace
uvarb hasaction12

#if WINTTDX
uvard codepagechar
uvard unicodechar

// process input character
//
// in:	
//	on stack: (in order of pushing)
//		dword: parameter to be given to invalidatehandle
//		dword: window ID to be given to invalidatehandle
//		dword: bits 0-7: max length, bits 8-15: max width
// out:	CF=1 ZF=1 if Escape key
//	CF=0 ZF=1 if Enter/Return key
//	otherwise ax=character
// safe:all but ESI
exported textinputchar
	xor eax,eax
	xchg al,[bTextInputInputChar]
	test al,al
	jnz .gotchar

.ret:
	test esp,esp	// clear ZF,CF
	ret 12

.gotchar:
	push esi
	mov [codepagechar],eax

	// now we need to convert that to Unicode
	push 1			// cchWideChar
	push unicodechar	// lpWideCharStr
	push 1			// cbMultiByte
	push codepagechar	// lpMultiByteStr
	push 1			// dwFlags = MB_PRECOMPOSED
	push dword 0			// CodePage = CP_ACP
	call [MultiByteToWideChar]
	test eax,eax
	jz near .donenz

	mov eax,[unicodechar]
	cmp eax,0x1b
	stc
	je near .done
	cmp eax,0x0d
	je near .done
	cmp eax,8
	je .isvalid

	// check that the character exists
	movzx edx,ah
	mov edx,[fonttables+edx*4]
	test edx,edx
	jle near .donenz
	movzx ebx,al
	cmp byte [edx+ebx*fontinfo_size+fontinfo.width],0
	je near .donenz

.isvalid:
	// process character
	xor ebx,ebx
	mov esi,baTextInputBuffer
	mov ebp,eax

.getnextlen:
	mov ecx,esi
	call getutf8char
	test eax,eax
	jz .gotlength

	call getutf8charwidth
	add ebx,eax
	jmp .getnextlen

.gotlength:
	mov eax,ebp
	cmp eax,8
	je near .delete

	cmp eax,' '
	jb .done

	call getutf8numbytes
	lea edx,[edx+esi+2]	// +2 for the UTF-8 code
	sub edx,baTextInputBuffer

	// now edx=new string length incl. final 0
	test dh,dh
	jnz .done
	cmp dl,[esp+8]		// max. length
	jnb .donenz

	mov ebp,eax
	call getutf8charwidth
	test eax,eax
	jz .donenz

	add ebx,eax
	mov eax,ebp

	test bh,bh
	jnz .done

	cmp bl,[esp+9]		// max. width
	ja .done

	lea edi,[esi-1]
	call storeutf8char
	mov byte [edi],0

.refresh:
	mov ax,[esp+16]
	mov ebx,[esp+12]
	call [invalidatehandle]

.donenz:
	test esp,esp

.done:
	pop esi
	ret 12

.delete:
	test ecx,ecx
	jz .donenz

	dec esi
.delnext:
	dec esi
	cmp byte [esi],0x80
	jb .delthis
	cmp byte [esi],0xC0
	jb .delnext
.delthis:
	mov byte [esi],0
	jmp .refresh

exported textinputokbutton
	// check if we can convert the buffer back to Latin-1
	push esi
	mov esi,baTextInputBuffer
	movzx ecx,byte [bTextInputMaxLength]
	call checklatin1conv
	mov edi,baTextInputBuffer
	pop esi
	ret

// Like the above, but called from the Save Game window, so it needs
// to save different registers
exported textinputokbutton_savewindow
	bts dword [esi+window.activebuttons],9	// overwritten

	push eax
	push ecx
	push esi
	push edi
	mov esi,baTextInputBuffer
	mov ecx, 46
	call checklatin1conv
	pop edi
	pop esi
	pop ecx
	pop eax

	ret
#endif

// check if text buffer can be converted to Latin-1
// if so do it, if not prepend UTF-8 code
//
// in:	ecx=max. length in bytes
//	esi->buffer
// uses:eax edi
checklatin1conv:
	mov edi,esi
.checknext:
	call getutf8char
	cmp eax,0x100
	ja .notlatin1
	test eax,eax
	jnz .checknext

	// no char > 0xff, so convert to Latin-1
	mov esi,edi
.convnext:
	call getutf8char
	stosb
	test eax,eax
	jnz .convnext
	ret

.notlatin1:	// prepend the utf-8 code
	sub ecx,2
	lea esi,[edi+ecx-2]
	add edi,ecx
	std
	rep movsb
	cld
	mov word [edi],0x9EC3
	ret

#if WINTTDX
// called before constructing the company name for the window title
//
// in:	ax=text ID
//	edi->buffer
// safe:all
exported setwindowtitle
	push eax
	push edi
	or eax,byte -1
	mov edi,baTempBuffer1
	call texthandler_ACP
	pop edi
	pop eax

	// fall through to texthandler_ACP
  
// convert text ID output string or buffer to Windows ANSI codepage
//
// in:	ax=text ID or eax=-1 to omit the texthandler call
//	edi->buffer to hold text
// uses:all

noglobal vard codepages
	dd 65001	// input: UTF-8
	dd 0		// output: ACP
endvar
noglobal vard mb_len, 256

proc texthandler_ACP
	slocal unicode,word,256
	local buffer

	_enter

	mov [%$buffer],edi
	cmp eax,byte -1
	je .gotbuffer

	push ebp
	call newtexthandler
	pop ebp

.gotbuffer:
	// now we convert that to UTF-16
	lea esi,[%$unicode]
	push 256		// cchWideChar
	push esi		// lpWideCharStr
	push byte -1		// cbMultiByte
	push dword [%$buffer]	// lpMultiByteStr
	push 0			// dwFlags
	push dword [codepages]	// CodePage (default CP_UTF8)
	call [MultiByteToWideChar]
	test eax,eax
	jz .fail	// most likely CP_UTF8 not available (win95), so keep buffer as is

	// there are E0xx codes in the texts, these actually represent the character
	// with code xx, fix that now
	lea esi,[%$unicode]
.nextchar:
	lodsw
	test ax,ax
	jz .e0xx_replaced
	cmp ah,0xE0
	jne .nextchar
	mov byte [esi-1],0
	jmp short .nextchar
.e0xx_replaced:

	// and back to the ANSI codepage
	lea esi,[%$unicode]
	push 0			// lpUsedDefaultChar
	push 0			// lpDefaultChar
	push dword [mb_len]	// cbMultiByte
	push dword [%$buffer]	// lpMultiByteStr
	push byte -1		// cchWideChar
	push esi		// lpWideCharStr
	push 0			// dwFlags
	push dword [codepages+4]// CodePage (default CP_ACP)
	call [WideCharToMultiByte]
.fail:
	_ret
endproc
#endif

// construct new company for unnamed company after manager name changed
//
// in:	ecx->suffix text (" Transport")
//	ebx->end of manager name using textrefstack as buffer (!)
//	esi->company
// out:	ebx->end of new company name (must still be on textrefstack)
// safe:all but edx
proc buildcompanyname
	slocal buffer,byte,96

	_enter
	push edx
	mov dword [specialtext1],textrefstack
	mov [specialtext2],ecx
	mov ax,statictext(special12)
	lea edi,[%$buffer]
	call newtexthandler

	lea esi,[%$buffer]
	mov ecx,94
	call checklatin1conv

	lea esi,[%$buffer]
	mov edi,textrefstack
	mov ecx,31
.copyback:
	lodsb
	stosb
	test al,al
	loopnz .copyback
	mov ebx,edi
	mov al,0
	pop edx
	_ret
endproc

#if WINTTDX
// convert ACP filename to UTF-8
// in:	esi->filename
// out:	esi->filename
// safe:?
exported convertfilenameunicode
	pusha
	mov ebx,codepages
	mov ecx,[ebx]
	xchg ecx,[ebx+4]
	mov [ebx],ecx
	mov dword [ebx+mb_len-codepages],32
	or eax,byte -1
	mov edi,esi
	call texthandler_ACP
	mov ebx,codepages
	mov ecx,[ebx]
	xchg ecx,[ebx+4]
	mov [ebx],ecx
	mov dword [ebx+mb_len-codepages],256
	popa
	ret
#endif
