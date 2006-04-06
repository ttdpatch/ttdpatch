// Support translating some locale-dependent things hardcoded in TTD

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <textdef.inc>

extern PrintDword,pLongMonthNameTable,printdate.daymonthtableoffs
extern pLongMonthNameTable,pDefaultCompanyNameTable,pDefaultAIPlayerNameTable
extern pAIFirstNameList,pAIMiddleNameList,pParentDirName,pDirName
extern pTransport1,pTransport2,pTransport3
extern fixuplocalstrings,savetranstexts

begincodefragments

codefragment findPrintDword, -8
	neg eax
	mov bx, '00'

codefragment finddatetotext,41
	and eax,0xffff
	shl eax,2

codefragment newprintshortdate
	mov bx, ourtext(shortdateformat)
	ijmp printdate

codefragment newprintlongdate
	mov bx, ourtext(longdateformat)
	ijmp printdate

codefragment newprintdate_hacked
	pop ebx
	mov bx, ourtext(longdateformat)
	ijmp printdate

codefragment findcompanynamelist,10
	movzx esi, word [textrefstack]
	db 0x8b, 0x34, 0xb5		// mov esi, [esi*4+...

codefragment findmanagernamelist,10
	mul ah
	add ah, cl
	movzx esi,ah

codefragment findmanagerinitials,5
	movzx esi,ah
	db 0x8a, 0x86

codefragment findparentdir,-4
	push ss
	pop es
	mov al,1

codefragment finddir,5
	or al,al
	jnz $+2-13

codefragment findtransport1,7
	inc ebx
	cmp byte [ebx], 0
	jnz $+2-6
	db 0xb9

codefragment findtransport23,4
	call dword [ebp+8]
	db 0xbe

codefragment oldprintliters
	mov dword [edi], ' lit'

codefragment newprintliters
	icall printliters
	setfragmentsize 16

codefragment oldprintmph
	mov dword [edi],'mph'
	add edi,3

codefragment newprintmph
	icall printmph
	setfragmentsize 9

codefragment oldprintkmh
	mov dword [edi], 'kmh'+0xb9000000
	add edi,4

codefragment newprintkmh
	icall printkmh
	setfragmentsize 9

codefragment oldprintandco
	mov dword [edi-1], ' & C'
	mov dword [edi+3], 'o.'
	add edi,5

codefragment newprintandco
	icall printandco
	setfragmentsize 17

codefragment oldrestoredefaultcurr
	mov [currency],ah
	mov [measuresys],al

codefragment newrestoredefaultcurr
	icall restoredefaultcurr
	setfragmentsize 11

endcodefragments

global patchtranslation
patchtranslation:

// first, patch the date printing code so it allows defining the date format

// Until now, translators could use a function in TTD Translator to achieve
// the same result by changing the code in the EXE, but that was basically an ugly hack.
// We must work around this hacked code by adding a special case into the patching logic.
// Remember this: Don't do hacks. They can come back and bite you any time...

	xor edi,edi
	storeaddress findPrintDword,1,0,PrintDword

// find the short date code
	stringaddress finddatetotext,1,2

// look for the hacked code ( original = 50 66; hacked = 66 50 )
	cmp word [edi], 0x5066
	je .hacked

// This is an unhacked version. Before patching, save some important pointers.
	mov eax,[edi+10]
	mov [printdate.daymonthtableoffs],eax

	mov eax,[edi+23]
	mov [pLongMonthNameTable],eax

// patch the short date printing code...
	storefragment newprintshortdate
// and the long date printing one
	patchcode finddatetotext,newprintlongdate,2,2
	jmp short .printpatchdone

.hacked:
// This is the hacked version, which has only one entry point and has the pointers
// at different offsets.
// We can't patch this version perfectly, the long date will be printed instead of the
// short one, but at least we won't crash.
	mov eax,[edi+11]
	mov [printdate.daymonthtableoffs],eax
	
	mov eax,[edi+130]
	mov [pLongMonthNameTable],eax

	storefragment newprintdate_hacked
// We must do the another stringaddress here as well not to confuse the version information.
// Luckily, both appearances of the fragment are untouched here as well, only the second one
// is never executed.
	stringaddress finddatetotext,2,2

.printpatchdone:

// find some pointers and text arrays in the code that haven't got textIDs
	storeaddresspointer findcompanynamelist,1+WINTTDX,2,pDefaultCompanyNameTable
	storeaddresspointer findmanagernamelist,1,2,pDefaultAIPlayerNameTable
	storeaddress findmanagerinitials,1,2,pAIFirstNameList
	storeaddress findmanagerinitials,2,2,pAIMiddleNameList
	storeaddress findparentdir,1,1,pParentDirName
	storeaddress finddir,1,1,pDirName
	storeaddress findtransport1,1,1,pTransport1
	storeaddress findtransport23,1,2,pTransport2
	storeaddress findtransport23,2,2,pTransport3

// patch some code where the text is embedded into an instruction
// we make those use a text with a textID as well
	patchcode printliters
	patchcode printmph
	patchcode printkmh
	patchcode printandco

	patchcode restoredefaultcurr

// find the correct versions of some hard-coded texts that differ between languages
	call fixuplocalstrings
// save the array we just found so they can be restored when a GRF is disabled
	call savetranstexts

	ret
