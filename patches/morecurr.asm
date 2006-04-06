// Helper functions needed by the morecurrencies patch
// The main code is in newcurrcode.ah

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <curr.inc>
#include <patchdata.inc>
#include <bitvars.inc>

extern morecurropts,newsmessagefn,patchflags

// Currencies are in order: pound, dollar, franc, deutschmark, yen, peseta, hungarian forint,
// polish zloty, austrian shilling, belgian franc, danish krone, finnish markka, greek drachma,
// swiss franc, dutch guilder, italian lira, swedish krona, russian rubel, euro

// All of these can be changed with ttdpttxt.dat

// Texts to show in the currency dropdown list, terminated by -1
// The last but one -1 will be changed to Euro after 2002 if it's enabled
var currtextlist,dw 0x133,0x134,0x135,0x136,0x137,0x138,ourtext(curr_HUF),ourtext(curr_PLN),
dw ourtext(curr_ATS),ourtext(curr_BEF),ourtext(curr_DKK),ourtext(curr_FIM),ourtext(curr_GRD),
dw ourtext(curr_CHF),ourtext(curr_NLG),ourtext(curr_ITL),ourtext(curr_SEK),ourtext(curr_RUB),-1,-1

// Currency multipliers. Their last three decimal digits will be assumed to be after the decimal point,
// so 1234567 will mean 1234.567
var currmultis,dd 1000,2000,10000,4000,200000,200000,400000,6000,20000,60000,10000,8000,
dd 500000,2000,3000,3000000,15000,5000,2000

// Currency options: thousand separator char in the low byte, the high byte is 1 if currency symbol should
// be shown after the number.
var curropts,dw "," , "," , "." , "." , "," , "." , 0x100 | "." , 0x100 | " " , "," , "," , "," , "," , "," ,
dw "," , "," , "," , "," , 0x100 | " " , ","

// What currency symbol to use if it's before and after the number. Two separate lists are needed because
// if a symbol needs to be separated with a space, the positon of the space will be different.
// All symbols are stored in a dword, and can be maximum four chars long
var currsymsbefore,dd 0xA3,"$","FF ","DM ",0xA5,"Pts","Ft ","zl ","S.","FB ","kr ","Mk",
dd "Dr.","FS ","fl.","L.","kr ","P",0x9e
var currsymsafter,dd 0xA3,"$"," FF"," DM",0xA5,"Pts"," Ft"," zl"," S."," FB"," kr","Mk",
dd " Dr."," FS"," fl.","L."," kr","P",0x9e

// If nonzero, the year when Euro will be introduced instead of the currency
var eurointr, dw 0,0,2002,2002,0,2002,2008,2010,2002,2002,0,2002,2002,0,2002,2002,0,0,0

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


// Euro glyph in three font sizes
var euroglyph
	incbin "embedded/eurochar.dat"
