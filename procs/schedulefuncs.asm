#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>

extern orderhints,patchflags,copyvehordersfn

global patchschedulefuncs

begincodefragments

codefragment oldfullloadtext
	dw 0x8827	// "Full load"
	db 3		// cWinElemTextBox
	db 0xe		// cColorSchemeGray

codefragment newfullloadtext
	dw statictext(newfullloadbutton)

codefragment olddeletetext1
	dw 0x8824	// "Delete"
	db 3		// cWinElemTextBox
	db 0xe		// cColorSchemeGray

codefragment newdeletetext
	dw statictext(newdeletebutton)

codefragment findorderhints
	dw 0x018b	// Close window...
	dw 0x018c	// Window title...
	dw 0x8852	// Orders list...

codefragment olddeletetext2
	dw 0x8824	// "Delete"
	dd 0		// four zeroes for a dummy box

#if WINTTDX
// different offsets in Windows version
codefragment oldcheckgotostation,-6
	and al,0xf0
	cmp al,0x50
	jz $+2+0x31

codefragment newcheckgotostation
	call runindex(checkgotostation)
	jc $+0x49+2
	setfragmentsize 10
#else
codefragment oldcheckgotostation,-4
	and al,0xf0
	cmp al,0x50
	jz $+2+0x2b

codefragment newcheckgotostation
	call runindex(checkgotostation)
	jc $+0x43
#endif

codefragment newcheckgotoowner
	call runindex(checkgotoowner)

codefragment newcheckgototype
	call runindex(checkgototype)

codefragment oldselectorder
	mov al,[ebx]
	and al,0x1f
	cmp al,1

codefragment newselectorder
	call runindex(selectorder)
	jz $+2+0xf
	bts [esi+0x1e],eax
	nop

codefragment newcopyoldorder
	call runindex(copyoldorder)

codefragment oldshoworderhint,9
	js $+6+0x363

codefragment newshoworderhint
	call runindex(showorderhint)
	setfragmentsize 8

endcodefragments

patchschedulefuncs:
	multipatchcode oldfullloadtext,newfullloadtext,4
	patchcode olddeletetext1,newdeletetext,1,1
	storeaddress findorderhints,1,1,orderhints
	multipatchcode olddeletetext2,newdeletetext,3
	patchcode oldcheckgotostation,newcheckgotostation,1,1

	testflags gotodepot
	jnc .skip

	add edi,byte 0x5e+lastediadj+8*WINTTDX
	storefragment newcheckgotoowner
	add edi,byte 0x34+lastediadj
	storefragment newcheckgototype

.skip:
	patchcode oldselectorder,newselectorder,1,1
	mov edi,[copyvehordersfn]
	add edi,17
	storefragment newcopyoldorder
	patchcode oldshoworderhint,newshoworderhint,1,1
	ret
