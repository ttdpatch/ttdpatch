// Support for new town name styles

#include <std.inc>
#include <textdef.inc>
#include <patchdata.inc>
#include <grf.inc>

extern GenerateDropDownMenu,firsttownnamestyle,gettextintableptr
extern specialtext1,ttdtexthandler





// It works this way:
// When the user selects a new town name style, we really set the town name style
// to German, and patch MakeEnglishGermanTownName to show the custom names instead
// of old names. German is the best choice because it doesn't do post-processing on
// the names (filtering obscene words etc.), and stores the random seed value in
// the town struct instead of part numbers. It's also good because loading
// the savegame with unavailable town name parts won't do Bad Things, but show
// old English and German town names instead.

// pointer to the currently used town name part structure or zero if old style is used
uvard currtownname

// The same, but saved on the title screen and restored to currtownname when the user
// goes back to the title screen
uvard currtownnametitle

// Called to generate an English or German town name from the random seed
// given on the text ref. stack
// Generate our custom name if [currtownname] isn't zero
// in:	edi->output buffer
// out:	edi->the new terminating zero in the output buffer
//	word [tempvar]: position flags (always clear for new names)
// safe: eax, edx, esi
global makeenglishgermanname
makeenglishgermanname:
	mov word [tempvar],0		// overwritten
	mov esi, [currtownname]
	or esi,esi
	jnz .ourname
	ret

.ourname:
	pop eax				// clear our return address

	push dword [specialtext1]
	call gettownname
	pop dword [specialtext1]

	push ecx			// adjust textrefstack to remove seed
	push edi
	xor ecx,ecx
	mov cl,7
	mov edi,textrefstack
	mov esi,textrefstack+4
	rep movsd
	pop edi
	pop ecx
	ret

// Called from makeenglishgermanname and recursively from itself to generate a random
// town name according to the namepartlist structure it gets
// in:	esi->namepartlist structure
//	edi->output buffer
// out:	edi->terminating zero in buffer
gettownname:
	pusha
.nextpart:
	mov eax,[textrefstack]			// get seed
	mov cl,[esi+namepartlist.bitstart]
	shr eax,cl
	mov cl,[esi+namepartlist.bitcount]
	neg cl
	add cl,32
	shl eax,cl
// now eax contains the bits available for randomizing the name, starting from the highest bit
	movzx edx, word [esi+namepartlist.maxprob]
	mul edx

// Now edx is a number between 0 and (maxprob-1). Find out which part text is this, with respect
// to the relative probablities
	push esi
	add esi,namepartlist_size
.partloop:
	movzx eax,byte [esi+namepart.probablity]
	and al,0x7f
	sub edx,eax
	jc .gotit
	add esi,8
	jmp short .partloop

.gotit:
	test byte [esi+namepart.probablity],0x80
	mov esi,[esi+namepart.ptr]
	jnz .otherid

.nextchar:
// this is a plain name part - copy it to edi (the terminating zero included), then move
// on to next part

	mov [specialtext1],esi
	mov ax,statictext(special1)
	call [ttdtexthandler]
	jmp short .finished

.otherid:
// this is a reference to another ID - call this function recursively to process it
// (esi is the new pointer now)
	call gettownname

.finished:
// move on to the next part if any
	pop esi
	mov esi,[esi+namepartlist.next]
	or esi,esi
	jnz short .nextpart

	mov [esp],edi			// will be popped to edi
	popa
	ret

// called to check if a town name is longer than 31 characters (and is invalid because of this)
// check for empty names as well (this can't happen with old styles), and mark these invalid as well
// in: esi->town name
// out: carry clear to signal an invalid name
// safe: ebx, ???
global ensuretownnamelength
ensuretownnamelength:
	xor ebx,ebx
.next:
	cmp byte [esi],0
	je .gotlength
	inc ebx
	inc esi
	jmp short .next

.gotlength:
	clc
	or ebx,ebx
	jz .exit

	cmp ebx,31
.exit:
	ret

// Called to create a random seed for English and German names. The old code uses
// bit 31 to distinguish between English and German names, but leave this bit alone
// for new styles so we have 32 bits for randomness instead of 31
// in:	eax: random seed
//	edx: 0 for English names, 1 for German names
// out:	eax bit 31 set accordingly for old style names
global makeenglishgermanseed
makeenglishgermanseed:
	cmp dword [currtownname],0
	jnz .exit
	shl edx,31
	btr eax,31
	or eax,edx
.exit:
	ret

// Called for textIDs CAxx (from newhouses.asm)
// the lower byte of the textid contains the ordinal number of the
// town name style name to display
// in:	ax: text ID -0xC800
// out:	eax: table ptr
//	edi: entry number
global gettownnametexttable
gettownnametexttable:
	cmp ah,2
	jne .invalid

	mov edi,[firsttownnamestyle]
// walk al steps on the chain 
.loop:
	or edi,edi
	jz .notfound		// we reached the end early - something went wrong
	or al,al
	jnz .next		// this isn't the last step yet
	cmp dword [edi+namepartlist.name],0
	je .notfound		// it's the last step, but the style name isn't set - fallback to default
	jmp short .gotit

.next:
	dec al
	mov edi,[edi+namepartlist.nextstyle]
	jmp short .loop

.gotit:
// We've found it - return offset to the name field for table ptr and 0 for index
	lea eax,[edi+namepartlist.name]
	xor edi,edi
	ret

.notfound:
// the needed text was not found - show default text instead
	mov ax,ourtext(unnamedtownnamestyle)
	jmp gettextintableptr

.invalid:
// We shouldn't ever get here, but just in case
	xor eax,eax
	xor edi,edi
	ret

// Called to display the drop-down menu for town name style selection
// in:	dx set to what TTD thinks the style is
//	ebx set according to dx and current game mode (title screen/ingame)
//	buffer at tempvar already filled with the six old style name
// out:	dx and ebx set accordingly if the current style is a new style
//	fill the rest of temp buffer with custom style names and terminate by -1
// safe: eax
// WARNING: we got here by a jump, not a function call !!!
global townnamestyledropdown
townnamestyledropdown:
	push edi
	push esi

	mov edi,tempvar+6*2
	mov esi,[firsttownnamestyle]
	mov ax,0xca00
// go through the linked list of final style definitions, and put the ordinal
// number + 0xca00 of the active one to the temp buffer
// (remember that our new text handler expects ordinal numbers in the low byte
//  of the ID)
.next:
	or esi,esi
	jz .nomore				// last ID
	cmp edi,tempvar+19*2
	je .nomore				// the temp buffer is full - force stop
	cmp byte [esi+namepartlist.active],0
	jz .skip				// skip inactive

	cmp byte [gamemode],0
	jne .nottitle
	cmp esi,[currtownnametitle]
	je .current
	jmp short .notcurrent

.nottitle:
	cmp esi,[currtownname]
	jne .notcurrent
// Do additional things if we reach the currently selected definition
// update edx...
.current:
	mov edx,edi
	sub edx,tempvar
	shr edx,1
// ...and ebx
	xor ebx,ebx
	cmp byte [gamemode],0			// all entries enabled on the title screen
	je .allok
	dec ebx					// everything disabled except the current otherwise
	btr ebx,edx
.allok:
.notcurrent:
	stosw					// store the textID in buffer
.skip:
	inc al
	mov esi,[esi+namepartlist.nextstyle]
	jmp short .next

.nomore:
	pop esi
	mov word [edi],-1			// terminate list
	pop edi
	jmp [GenerateDropDownMenu]		// display the list

// Called to decide which text to display in the dropdown menu box for town name styles
// in:	ax: textid for the style TTD believes is active
// out: textid to be displayed put to [textrefstack+8]
// safe: eax
global townnamestyledisplay
townnamestyledisplay:
	mov [textrefstack+8],ax			// overwritten

	mov eax,[currtownname]

	cmp byte [gamemode],0
	jne .nottitle
	mov eax,[currtownnametitle]
.nottitle:

	or eax,eax
	jz .exit				// old style
	mov eax,[eax+namepartlist.name]
	or eax,eax
	jnz .goodname

// new style, but it hasn't got its name set - use default text
	mov word [textrefstack+8],ourtext(unnamedtownnamestyle)
	jmp short .exit

.goodname:
// new style with correct name - display it as a special text instead of finding its
// ordinal number and pushing that on the text ref. stack
	mov [specialtext1],eax
	mov word [textrefstack+8],statictext(special1)
.exit:
	ret

// Called when the user selects an entry from the town name style dropdown menu
// Update [currtownname] and fool TTD into thinking the user selected German if necessary
// in:	dl: index of the selected item
// out:	dl: town name style TTD should think the user selected
//	eax, ecx =0
global townnameselect
townnameselect:
	and dword [currtownname],0
	cmp dl,6			// indices below 6 are old entries, these need no further processing
	jb .oldstyle

	sub dl,6			// subtract 6 to get ordinal number among active styles
	mov eax,[firsttownnamestyle]

// find the dl-th active style
.nextstyle:
	or eax,eax
	jz .fallback			// reached the end too early - something went wrong
	cmp byte [eax+namepartlist.active],0
	jz .skipstyle			// skip inactive ones
	dec dl				// we've reached the correct one when dl turns to negative
	js .foundit
.skipstyle:
	mov eax,[eax+namepartlist.nextstyle]
	jmp short .nextstyle

.fallback:
// on error, we should set [currtownname] to zero, but since eax is already zero here, falling
// through to foundit will do
.foundit:
	mov [currtownname],eax
	mov dl,2			// fool TTD to use German names

.oldstyle:
	cmp byte [gamemode],0
	jne .nottitle
	mov eax,[currtownname]
	mov [currtownnametitle],eax
.nottitle:
	xor eax,eax
	xor ecx,ecx
	ret

// Auxiliary: find the pointer to the current town name data and update [currtownname] according
// to the grfid and setid stored in the savegame
global findcurrtownname
findcurrtownname:
#if 0
	cmp byte [gamemode],0
	jne .nottitle
	mov eax,[currtownnametitle]
	mov [currtownname],eax
	ret

.nottitle:
#endif
	cmp dword [landscape3+ttdpatchdata.townnamegrfid],0
	jne .havenewtownnames
	and dword [currtownname],0			// saved data is zero - old names are used
	ret

.havenewtownnames:
// try to find the entry with the correct grfid and setid in the linked list
	push eax
	push ebx
	push esi
	mov eax,[landscape3+ttdpatchdata.townnamegrfid]
	mov bl,[landscape3+ttdpatchdata.townnamesetid]
	mov esi,[firsttownnamestyle]

.nextstyle:
	or esi,esi
	jz .notfound				// no match, fall back to old style
	cmp byte [esi+namepartlist.active],0
	jz .skipstyle				// skip inactive
	cmp eax,[esi+namepartlist.grfid]
	jnz .skipstyle
	cmp bl,[esi+namepartlist.setid]
	jz .gotit
.skipstyle:
	mov esi,[esi+namepartlist.nextstyle]
	jmp short .nextstyle

.notfound:
// we should set [currtownname] to zero here, but since esi is already zero when we get here,
// falling through to .gotit will do as well
.gotit:
	mov [currtownname],esi
	pop esi
	pop ebx
	pop eax
	ret
