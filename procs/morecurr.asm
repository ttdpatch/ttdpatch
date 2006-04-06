#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <textdef.inc>
#include <curr.inc>
#include <patchdata.inc>
#include <patchproc.inc>

patchproc morecurrencies, patchmorecurr

extern currmultis,curropts,currsymsafter,currsymsbefore,eurointr,getnumber
extern gettextandtableptrs,morecurropts

begincodefragments

codefragment oldcurrprint,1
	ret
	or eax,eax
	jns $+2+6

// New code to show money
// Starts at the code for pounds, and also overwrites code for two more currencies, but we don't care
// because all other entry points are disabled.
// In:	eax: money in pounds
//		edi: pointer to buffer for text
// Safe: eax, ebx, edx
// Usage of registers inside the proc:
// edx:eax: money multiplied by the current currency multiplier
// cl: number of current currency
// ch: thousand separator for current currency
// 16th bit of ecx is 1 if show currency symbol after the number
codefragment newcurrprint
	push ecx
	push esi

	or eax,eax
	jns .notnegative 	// if it's negative, write a minus sign then negate it
	mov byte [edi],"-"
	inc edi
	neg eax

.notnegative:
	getcurr ecx
	imul dword [currmultis+ecx*4]	//multiply it with the multiplier
	mov bx,[curropts+ecx*2]	//get current currency options (th. sep. and symbol placement)
	test bh,0x1
	jnz .notbefore

	// We should print the symbol before the number, so do it right now
	mov ecx, [currsymsbefore+ecx*4]	// we've just overwritten what currency is selected, but we don't need it anyway
	mov byte [edi+4],0	// maximum symbol length is 4, so force stop there
	mov [edi],ecx	// move the symbol into the buffer
	dec edi	// neutralize the inc for the first loop
.incbef:	//inc edi until the first zero terminator; next char should go there
	inc edi
	cmp byte [edi],0
	jnz .incbef
	xor ecx,ecx	// later code assumes that ecx is clear except the lowest byte
.notbefore:
	shl ebx,8	// put curropts into ecx - ch is now the thousand separator
	or ecx,ebx
	mov bl,(1<<6)|"0"	// to allow skipping leading zeroes and counting separators

	xor esi,esi
	test edx,0xFFFF0000	// make things faster if high bits are clear
	jnz .startprinting

	mov bl,(2<<6)|"0"

	test edx,edx
	jnz near .notverysmall

	add esi,5		// edx is zero, skip 9 digits
	mov bl,(1<<6)|"0"
.notverysmall:			// or at least 4 digits
	add esi,4

.startprinting:
	lea esi,[powersoften+esi*8]

.printdigit:

	// Write the digits. We don't write the last three digits because they are behind the decimal point.
	// More info in morecurrs.asm

	add bl,0x40
	cmp bl,0xc0
	jb .noseparator

	and bl,0xf
	jz .noseparator

	mov [edi],ch
	inc edi

.noseparator:

	mov bh,"0"
.incdigit:
	sub eax,[esi+4]
	sbb edx,[esi]
	jb .digitok
	inc bh
	jmp .incdigit

.digitok:
	add eax,[esi+4]
	adc edx,[esi]
	or bl,bh
	test bl,15
	je .nowrite

	mov [edi],bh
	inc edi

.nowrite:
	add esi,8
	cmp esi,powersoften_last
	jb .printdigit

	test bl,15
	jnz .notzero

	// no digits printed yet; print at least a zero
	mov byte [edi], "0"
	inc edi

.notzero:
	test ecx,0x10000
	jz .done

.after:
	// We should print the currency symbol after the number, so it's time to do it
	movzx ecx,cl	// upper bytes of ecx should be clear
	mov ecx, [currsymsafter+ecx*4]	// get currency symbol
	mov [edi],ecx	// put the symbol into the buffer
	mov byte [edi+4],0	// maximum symbol length is 4, so force stop there
	dec edi	// neutralize the inc for the first loop
.incaft:	//inc edi until the first zero terminator; next char should go there
	inc edi
	cmp byte [edi],0
	jnz .incaft

.done:
	pop esi
	pop ecx
	ret

codefragment olduserightcurrency
	movzx eax,byte [currency]
	db 0xff		// jmp near...

codefragment newuserightcurrency
	xor eax,eax
	setfragmentsize 7

codefragment newlimityear
	call runindex(limityear)
	setfragmentsize 10

codefragment oldlimityear,-10
	mov byte [currentyear],150

reusecodefragment oldisspecialyear,oldlimityear,7

codefragment newisspecialyear
	call runindex(isspecialyear)
	setfragmentsize 7

codefragment oldfillcurrlist
	movzx dx, byte [currency]
//	mov word [tempvar],0x133 //"Dollar ($)"

codefragment newfillcurrlist
	call runindex(fillcurrlist)
	jmp fragmentstart+73

codefragment oldwhatcurrtoshow
	movzx ax, byte [currency]
	add ax,0x133

codefragment newwhatcurrtoshow
	call runindex(whatcurrtoshow)
	setfragmentsize 12

codefragment oldcurrselect,13
	jne $+2+0x18
	mov [currency],al

codefragment newcurrselect
	call runindex(currselect)
	setfragmentsize 8

endcodefragments

patchmorecurr:
	patchcode olduserightcurrency,newuserightcurrency,1,1
	patchcode oldisspecialyear,newisspecialyear,1,1
	patchcode oldfillcurrlist,newfillcurrlist,1,1
	patchcode oldwhatcurrtoshow,newwhatcurrtoshow,1,1
	patchcode oldcurrselect,newcurrselect,1,1
	patchcode oldcurrprint,newcurrprint,2,7

	// set up table of 64-bit factors of 10
	lea ebx,[ecx+10]	// mov ebx,10 in 3 bytes (ecx is zero)
	lea eax,[ecx+100]
	add ecx,num_powersoften
	push edx
	cdq
	mov edi,powersoften_last
	std

.nextpower:
	mov esi,edx
	mul ebx			// now edx:eax = org. eax*10
	stosd
	xchg eax,esi
	mov esi,edx		// esi = this edx
	mul ebx			// now eax= org. edx*10
	add eax,esi
	stosd
	xchg eax,edx
	mov eax,[edi+8]
	loop .nextpower
	cld

	mov ebx,CURR_FIRSTCUSTOM

.dataloop:
	mov ax,firstcuscurrtext-CURR_FIRSTCUSTOM
	add eax,ebx
	call gettextandtableptrs

	xor al,al
	xor ecx,ecx
	dec ecx
	repnz scasb	// skip the menu entry text

	call .readnum
	jz .nonewmulti
	mov [currmultis+ebx*4],edx

.nonewmulti:
	mov al,[edi]
	inc edi
	or al,al
	jz .nonewopts
	mov ah,[edi]
	mov [curropts+ebx*2],ax
	xor al,al
	repnz scasb

.nonewopts:
	lea esi,[currsymsbefore+ebx*4]
	call .readsym

	lea esi,[currsymsafter+ebx*4]
	call .readsym

	call .readnum
	jz .noneweurointr
	mov [eurointr+ebx*2],dx

.noneweurointr:
	inc ebx
	cmp ebx,currcount
	jb .dataloop

	pop edx

	mov al,[morecurropts]

	mov bh,','
	test al,morecurrencies_comma
	jnz .setchar

	mov bh,'.'
	test al,morecurrencies_period
	jz .defaultchar

.setchar:
	mov ecx,currcount //apply it for all currencies

.setcharloop:
	mov [curropts-2+ecx*2],bh
	loop .setcharloop

.defaultchar:
	and al,morecurrencies_symbefore+morecurrencies_symafter
	jz .default // zero means leave them default
	dec eax // else, dec it, so bl is 1 for "after", 0 for "before", just like in curropts
	mov ecx,currcount //apply it for all currencies

.overwriteloop:
	mov [curropts-1+ecx*2],al // overwrite the high bytes of curropts to the given value
	loop .overwriteloop

.default:
	ret

// helper functions for patchmorecurr

// read a number from [edi] and return it in edx
// zf set on error
.readnum:
	xor esi,esi
	push ebx
	mov ebx,edi
	call getnumber
	pop ebx
	xor al,al
	repnz scasb
	cmp edx,-1
	ret

// read a curr. symbol from [edi] and write it to [esi] if not empty
.readsym:
	xchg edi,esi
	lodsb
	or al,al
	jz .symreadexit

	mov dl,4
	and dword [edi],0
	jmp short .storechar

.loadchar:
	lodsb
	or al,al
	jz .symreadexit
.storechar:
	stosb
	dec dl
	jnz .loadchar

	xchg edi,esi
	xor al,al
	repnz scasb
	ret

.symreadexit:
	xchg edi,esi
	ret

// this is here because it shares a codefragment
global patch2070servint
patch2070servint:
	patchcode oldlimityear,newlimityear,1,1
	mov byte [edi+lastediadj-2],0x72	// JNZ -> JB
	ret

// new code to write money

num_powersoften equ 16
uvard powersoften,num_powersoften*2
powersoften_last equ powersoften+num_powersoften*2*4-4
