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


extern fonttables,drawspriteonscreen,malloc,patchflags
extern tempSplittextlinesNumlinesptr,splittextlines_done

// Initialize the font glyph tables with TTD's characters
exported initglyphtables
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
	jb .special

.drawchar:
	mov bx,[edi+scrnblockdesc.x]
	add bx,[edi+scrnblockdesc.width]
	cmp cx,bx
	jge near .skipline

	mov bx,cx
	add bx,26
	cmp bx,[edi+scrnblockdesc.x]

	// get char info without affecting flags
	movzx ebx,byte [currentfont+1]	// now ebx=0/1/3 for normal/small/large
	mov ebx,[fonttableofs+ebx*4]	// now ebx=0/256/512 for normal/small/large
	mov bl,ah
	mov ebx,[fonttables+ebx*4]
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
	movzx ebx,byte [currentfont+1]
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
getutf8char:
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

// called to get width of string
//
// in:	esi->string
// out:	cx=width in pixels
//	ebx=final font
// safe:eax,esi
exported gettextwidthunicode
	push edx
	or cx,byte -1
	movzx ebx,byte [currentfont+1]	// now ebx=0/1/3 for normal/small/large
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
// out:	eax=width
//	esi->string past character's arguments (if any)
// uses:edx
getutf8charwidth:
	cmp eax,byte " "
	jb .special

	mov bl,ah
	mov edx,[fonttables+ebx*4]
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
	movzx ebx,byte [currentfont+1]	// now ebx=0/1/3 for normal/small/large
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

