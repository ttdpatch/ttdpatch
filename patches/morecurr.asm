// Helper functions needed by the morecurrencies patch
// The main code is in newcurrcode.ah

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <curr.inc>
#include <patchdata.inc>
#include <bitvars.inc>

extern morecurropts,newsmessagefn,patchflags,getnumber,gettextandtableptrs,malloccrit
extern getnumber,gettextandtableptrs,morecurropts

global num_powersoften,powersoften_last
num_powersoften equ 16
uvard powersoften,num_powersoften*2
powersoften_last equ powersoften+num_powersoften*2*4-4

// Currencies are in order: pound, dollar, franc, deutschmark, yen, peseta, hungarian forint,
// polish zloty, austrian shilling, belgian franc, danish krone, finnish markka, greek drachma,
// swiss franc, dutch guilder, italian lira, swedish krona, russian rubel, euro

// All of these can be changed with ttdpttxt.dat

// Texts to show in the currency dropdown list, terminated by -1
// The last but one -1 will be changed to Euro after 2002 if it's enabled
svarw currtextlist,currcount+1

// Where to read currency definitions from
varw currtextlistsrc
	dw ourtext(curr_pound), ourtext(curr_dollar), ourtext(curr_franc), ourtext(curr_deutschmark)
	dw ourtext(curr_yen), ourtext(curr_peseta), ourtext(curr_HUF), ourtext(curr_PLN), ourtext(curr_ATS)
	dw ourtext(curr_BEF), ourtext(curr_DKK), ourtext(curr_FIM), ourtext(curr_GRD), ourtext(curr_CHF)
	dw ourtext(curr_NLG), ourtext(curr_ITL), ourtext(curr_SEK), ourtext(curr_RUB), ourtext(curr_EUR)

// Currency multipliers. Their last three decimal digits will be assumed to be after the decimal point,
// so 1234567 will mean 1234.567
vard currmultis
dd 1000,2000,10000,4000,200000,200000,400000,6000,20000,60000,10000,8000,
dd 500000,2000,3000,3000000,15000,5000,2000

// Currency options: thousand separator char in the low byte, the high byte is 1 if currency symbol should
// be shown after the number.
varw curropts
dw "," , "," , "." , "." , "," , "." , 0x100 | "." , 0x100 | " " , "," , "," , "," , "," , "," ,
dw "," , "," , "," , "," , 0x100 | " " , ","

// What currency symbol to use if it's before and after the number. Two separate lists are needed because
// if a symbol needs to be separated with a space, the positon of the space will be different.
// All symbols are stored in a dword, and can be maximum four chars long
vard currsymsbefore
dd 0xA3,"$","FF ","DM ",0xA5,"Pts","Ft ","zl ","S.","FB ","kr ","Mk",
dd "Dr.","FS ","fl.","L.","kr ","P",0x9e

vard currsymsafter
dd 0xA3,"$"," FF"," DM",0xA5,"Pts"," Ft"," zl"," S."," FB"," kr","Mk",
dd " Dr."," FS"," fl.","L."," kr","P",0x9e

// If nonzero, the year when Euro will be introduced instead of the currency
varw eurointr
dw 0,0,2002,2002,0,2002,2008,2010,2002,2002,0,2002,2002,0,2002,2002,0,0,0

endvar

// bitmask of what currencies are disabled
uvard disabledcurrs

// copy of ttdpatchdata.realcurrency, used to preserve the currency selection
// from the main menu into a new game
uvarb realcurrency



// Updates disabledcurrs according to the current year and eurointr
global updatecurrlist
updatecurrlist:

// do it only if both euro and morecurrencies are enabled
	testflags morecurrencies
	jc .doit
.dontneed:
	ret

.beforeeuro:
	mov [disabledcurrs],eax	// enable all currencies (eax is zero)...
	or word [currtextlist+CURR_EURO*2],-1	// ... but hide Euro
	getcurr ebx
	cmp ebx,currcount-1
	jne .noteuro

// The current currency was Euro (this might happen when jumping back in time with cht:Year)
// Change it to pounds

	and byte [currency],0
	mov byte [landscape3+ttdpatchdata.realcurrency],1

.noteuro:
	popa
	ret

.doit:
	pusha
	xor eax,eax
	test byte [morecurropts],morecurrencies_noeuro	// euro is disabled, make sure it's hidden and everything else is available
	jnz .beforeeuro
	mov bl,[currentyear]
	xor bh,bh
	add bx,1920
	cmp bx,2002
	jb .beforeeuro
	mov ecx,currcount-1	// check everything except Euro

.convertcurr:
	mov dx,[eurointr+(ecx-1)*2]
	or dx,dx	// Will it ever be changed?
	jz .next
	cmp dx,bx	// Was it changed by now?
	ja .next
	bts eax,ecx	// This currency was changed to Euro - disable it
.next:
	loop .convertcurr

	mov word [currtextlist+CURR_EURO*2],ourtext(curr_EUR)	// Show Euro

	shr eax,1		// the bits in eax are off by 1 bit since ecx was 1 bigger
				// during the loop
	mov [disabledcurrs],eax	// update disabled currencies list
	getcurr ebx
	bt eax,ebx	// Did the current currency get disabled by the change?
	jnc .end

	and byte [currency],0	// If it did, change current currency to Euro
	mov byte [landscape3+ttdpatchdata.realcurrency],currcount

.end:
	popa
	ret

// Called when a currency is selected in the Game options dialog box
// [currency] is updated already
// In: al: index of selected currency in the dropdown list (zero-based)
// Out: the same
// safe: ???
global currselect
currselect:
	cmp al,5
	jbe .noreset
// If it's a non-default currency, reset the old TTD variable because it would make TTD crash
	mov byte [currency],0
.noreset:
// Store index+1 in the new currency variable in landscape3
	inc al
	mov [landscape3+ttdpatchdata.realcurrency],al
	mov [realcurrency],al	// and save in case it's being set in the main menu
	dec al
	mov ebx,5	// overwritten by the
	call dword [ebp+4]	// runindex call
	ret

// Called when filling the dropdown list of currencies.
// Out: dx should contain the index of the currently selected item.
//	ebx is a mask for the disabled items
// safe: ???
global fillcurrlist
fillcurrlist:
	getcurr dx
	push ecx
	mov ecx,20*2/4			// copy 20 words from currtextlist to tempvar
.copyloop:
	mov ebx,[currtextlist+(ecx-1)*4]
	mov [tempvar+(ecx-1)*4],ebx
	loop .copyloop

	pop ecx
	mov ebx,[disabledcurrs]
	ret

// Called when deciding the text to show in the currency dropdown box
// Out: ax: text to show
// safe: ???
global whatcurrtoshow
whatcurrtoshow:
	getcurr eax
	mov eax,[currtextlist+eax*2]	// save a prefix - the upper half of eax isn't used anyway
	ret

// New Year: check if it's the euro introduction year (2002)
// out:	ZF set = it's 2050
// safe:everything except ESP
global isspecialyear
isspecialyear:
	test byte [morecurropts],morecurrencies_noeuro
	jnz .check2050
	cmp byte [currentyear],82
	jnz .check2050

	mov dx,newstext(eurointroduced)
	mov ebx,0x40001			// category 4 = "economy changes"
	call dword [newsmessagefn]

.check2050:
	call updatecurrlist

	cmp byte [currentyear],130	// overwritten
	ret

uvard pCurrencyDataBackup

// Back up all currency data so it can be restored when GRFs are modified
// just dump all arrays into a dynamically allocated buffer
global backupcurrencydata
backupcurrencydata:

	push dword currcount*(2+4+2+4+4+2)
	call malloccrit
	pop edi

	mov [pCurrencyDataBackup],edi

	mov ecx,currcount
	mov esi,currtextlist
	rep movsw

	mov cl,currcount
	mov esi,currmultis
	rep movsd

	mov cl,currcount
	mov esi,curropts
	rep movsw

	mov cl,currcount
	mov esi,currsymsbefore
	rep movsd

	mov cl,currcount
	mov esi,currsymsafter
	rep movsd

	mov cl,currcount
	mov esi,eurointr
	rep movsw

	ret

// restore all saved currency data saved in the previous proc
global restorecurrencydata
restorecurrencydata:

	mov esi,[pCurrencyDataBackup]

	mov ecx,currcount
	mov edi,currtextlist
	rep movsw

	mov cl,currcount
	mov edi,currmultis
	rep movsd

	mov cl,currcount
	mov edi,curropts
	rep movsw

	mov cl,currcount
	mov edi,currsymsbefore
	rep movsd

	mov cl,currcount
	mov edi,currsymsafter
	rep movsd

	mov cl,currcount
	mov edi,eurointr
	rep movsw

	// *********

	call applycurrencychanges
	call updatecurrlist

	ret

// apply currency changes given in special currency ourtext()-s
// see the wiki for the format of those texts
global applycurrencychanges
applycurrencychanges:
	pusha

	// set default TTD currency texts
	xor ecx,ecx
	mov ax,0x133	// default text for Pound
.nextdefault:
	cmp ecx,6
	jb .ttdcurr
	mov ax,[currtextlistsrc+ecx*2]
.ttdcurr:
	mov [currtextlist+ecx*2],ax
	inc eax
	inc ecx
	cmp ecx,currcount
	jb .nextdefault

	xor ebx,ebx

.dataloop:
	movzx eax,word [currtextlistsrc+ebx*2]
	push eax
	call gettextandtableptrs
	pop eax

	cmp byte [edi],0
	je .keepdefault

	mov [currtextlist+ebx*2],ax

.keepdefault:
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
	popa
	ret

// helper functions

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

// Euro glyph in three font sizes
var euroglyph
	incbin "embedded/eurochar.dat"


// New code to show money
// Starts at the code for pounds, and also overwrites code for two more currencies, but we don't care
// because all other entry points are disabled.
// In:	eax: money in pounds
//	edi: pointer to buffer for text
//	edx: high 32 bits (for 64bit version only)
// Safe: eax, ebx, edx
// Usage of registers inside the proc:
// edx:eax: money multiplied by the current currency multiplier
// cl: number of current currency
// ch: thousand separator for current currency
// 16th bit of ecx is 1 if show currency symbol after the number
exported printcash_64bit
	push ecx
	push esi

	test edx,edx
	jns .notnegative

	mov byte [edi],"-"
	inc edi

	// 64bit negation
	neg eax
	adc edx,0
	neg edx
	js .limit	// too big for 64bit

.notnegative:
	getcurr ecx

	mov esi,eax

	mov eax,edx
	mul dword [currmultis+ecx*4]	//multiply it with the multiplier

	test edx,edx
	jnz .limit	// too big for 64bit

	xchg eax,esi
	mul dword [currmultis+ecx*4]	//multiply it with the multiplier
	add edx,esi
	jnc printcash.display

.limit:
	or eax,byte -1
	mov edx,0x7fffffff
	jmp short printcash.display

exported printcash
	push ecx
	push esi

	or eax,eax
	jns .notnegative 	// if it's negative, write a minus sign then negate it
	mov byte [edi],"-"
	inc edi
	neg eax

.notnegative:
	getcurr ecx
	mul dword [currmultis+ecx*4]	//multiply it with the multiplier

	// here edx:eax = value to display, always positive
.display:
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

