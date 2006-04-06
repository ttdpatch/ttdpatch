#include <std.inc>
#include <var.inc>
#include <patchdata.inc>
#include <textdef.inc>

extern gettextandtableptrs,mainstringtable,languageid,malloccrit,realcurrency
extern specialtext1,ttdtexthandler,texthandler

uvard PrintDword

global pLongMonthNameTable,pDefaultCompanyNameTable,pDefaultAIPlayerNameTable,pAIFirstNameList
global pAIMiddleNameList,pParentDirName,pDirName,pTransport1,pTransport2,pTransport3

// This list contains pointers to text pointer lists. These lists will be mapped to the
// textID range 0xE0xx in the order of appearance. Some "lists" are only one pointer
// inside the code, so we can modify pointers embedded into code. 

vard TranslatableStringArrays

pLongMonthNameTable:		dd -1
pDefaultCompanyNameTable:	dd -1
pDefaultAIPlayerNameTable:	dd -1
pAIFirstNameList:		dd -1
pAIMiddleNameList:		dd -1
pParentDirName:			dd -1
pDirName:			dd -1
pTransport1:			dd -1
pTransport2:			dd -1
pTransport3:			dd -1
pOtherHardcodedTable:		dd OtherHardcodedTable

section .text

// Lengths of the lists defined above, terminated by a zero byte
varb TranslatableArrayLengths, 12,13,41,1,1,1,1,1,1,1,4,0

// Table of texts previously embedded into code. Now that they're accessed via
// a pointer, GRFs are able to change them
vard OtherHardcodedTable
	pLiters			dd -1
	pKmh			dd aKmh
	pMph			dd aMph
	pAndCo			dd aAndCo
section .text

// three versions of the liter display, for American, English and anything else
varb aLiters, " liters",0
varb aLitres, " litres",0
varb aLitre,  " litre",0

// Copies of other hard-coded texts embedded into code. These are the same in all languages.
varb aKmh, "kmh", 0xb9, 0
varb aMph, "mph", 0
varb aAndCo, " & Co.", 0

// There's another special text that has it's own textID (0x00bf), but isn't zero-terminated
// correctly. The code handles it as if it had a 0x80 at the end, so make versions that
// have that and are zero-terminated. We'll overwrite the old pointer with a pointer to one
// of these, so this ID will work as intended.
varb aEnUsGraphics, 0x98, "Graphics: ", 0x80, 0
varb aGeGraphics, 0x98, "Grafiken: ", 0x80, 0
varb aFrGraphics, 0x98, "Carte Graphique: ", 0x80, 0
varb aSpGraphics, 0x98, "Gr", 0xe1, "ficos: ", 0x80, 0

vard GraphicsTexts, aEnUsGraphics,aEnUsGraphics,aGeGraphics,aFrGraphics,aSpGraphics

// Set default TTD language if given from 
global setdeflanguage
setdeflanguage:
	mov ax,ourtext(grflanguage)	// see if ttdpttxt.dat specifies a
	call texthandler		// different grf language
	lodsb
	sub al,'1'
	jb .deflang

	mov [languageid],al

.deflang:
	ret

// Find the correct versions of language-dependent hard-coded texts
// safe: all but edx and ecx
global fixuplocalstrings
fixuplocalstrings:
// find the correct version of liters/litres/litre
	movzx eax, byte [languageid]
	mov dword [pLiters], aLiters
	test al,al
	jz .litreok
	mov dword [pLiters], aLitres
	cmp al,1
	je .litreok
	mov dword [pLiters], aLitre
.litreok:

// find the correct version of "Graphics"
	mov eax,[GraphicsTexts+4*eax]
	mov ebx,[mainstringtable]
	mov [ebx+0x00be*4],eax
	ret

// Called to get texts of class 0xE000.
// We map all previously hard-coded texts to this range so they can be modified via action4.
// in:	edi=textID&7ff
// out:	eax->string table
//	edi=index into table
//	carry set if eax has to be added to value in table
global getextratranstable
getextratranstable:
	push ebx
// find the table belonging to the ID
	xor eax,eax
.nexttable:
	movzx ebx,byte [TranslatableArrayLengths+eax]
	test ebx,ebx
	jz .error
	inc eax
	sub edi,ebx
	jnb .nexttable

// get table address from number
	mov eax,[TranslatableStringArrays+(eax-1)*4]
// undo the last sub so edi becomes the index into the table
	add edi,ebx
	clc
	pop ebx
	ret

.error:
	ud2

uvard pTransTextBackup

// Make a backup copy from the hard-coded text pointers so they can be restored when a GRF is disabled
global savetranstexts
savetranstexts:
	pusha

// calculate the sum of the table lengths to find out how many memory to allocate
	xor eax,eax
	mov esi,TranslatableArrayLengths

.nextlen:
	movzx ebx, byte [esi]
	inc esi
	add eax,ebx
	test ebx,ebx
	jnz .nextlen

// allocate the memory
	shl eax,2
	push eax
	call malloccrit
	pop edi

	mov [pTransTextBackup],edi

// dump the contents of each table into the buffer
	xor eax,eax
	mov ebx,TranslatableArrayLengths

.nexttable:
	movzx ecx, byte [ebx]
	test ecx,ecx
	jz .done
	inc ebx
	mov esi,[TranslatableStringArrays+eax*4]
	inc eax
	rep movsd
	jmp short .nexttable

.done:
	popa
	ret

// restore the tables saved above
global restoretranstexts
restoretranstexts:
	pusha

	mov esi, [pTransTextBackup]
// in the DOS version, this code seems to be called before the backup takes place
// to avoid crashing, exit if the backup isn't done yet
	test esi,esi
	jz .done

// restore the content of each table sequentially
	xor eax,eax
	mov ebx,TranslatableArrayLengths

.nexttable:
	movzx ecx, byte [ebx]
	test ecx,ecx
	jz .done
	inc ebx
	mov edi,[TranslatableStringArrays+eax*4]
	inc eax
	rep movsd
	jmp short .nexttable

.done:
	popa
	ret

// The following procs are each called instead of code like "mov dword [edi], 'foo'"
// They use a null-terminated text instead, so GRFs can alter the text.

global printliters
printliters:
	mov eax, [pLiters]

.copy:
	push dword [specialtext1]
	mov [specialtext1],eax
	mov ax,statictext(special1)

	push esi
	call [ttdtexthandler]
	pop esi
	pop dword [specialtext1]

	ret

global printmph
printmph:
	mov eax,[pMph]
	jmp short printliters.copy

global printkmh
printkmh:
	mov eax,[pKmh]
	jmp short printliters.copy

global printandco
printandco:
	dec edi
	mov eax,[pAndCo]
	jmp short printliters.copy

// Called to put a date into the output buffer. We process a format string instead of the old
// hard-coded format, so GRFs can change it.
// in:	eax: year-1920
//	bx: textID of format string
//	dx: day of year (0-based)
//	edi-> output buffer
// out:	edi-> remaining part of output buffer
// safe: eax, ebx, edx, ???
global printdate
printdate:

	movzx edx,dx
	mov dx,[dword 0+edx*2]
ovar .daymonthtableoffs,-4,$,printdate
// now dx= (month<<5)+day

// save month, day and year to the stack
	push edx
	add ax,1920
	push eax

// find the format string
	push edi
	mov eax,ebx
	call gettextandtableptrs
	mov edx,edi
	pop edi

// now edx-> format string
// the format string can have four special characters:
//	#01: print year
//	#02: print day
//	#03: print abbreviated month name (Jan, Feb...)
//	#04: print full month name (January, February...)
.nextchar:
	mov al,[edx]
	inc edx
	test al,al
	jz .done
	cmp al,1
	je .year
	cmp al,2
	je .day
	cmp al,3
	je .shortmonth
	cmp al,4
	je .longmonth

// non-special chars get copied verbatim
	stosb
	jmp short .nextchar

// print year: it's just a plain number
.year:
	mov eax,[esp]
	call [PrintDword]
	jmp short .nextchar

// print day: because of the -st, -nd etc., these have a text each
.day:
	mov eax,[esp+4]
	and eax,0x1f
	add eax,0x01ac-1
	jmp short .copy

// print abbreviated month: these have their own texts as well
.shortmonth:
	mov eax,[esp+4]
	shr eax,5
	add eax,0x0162
	jmp short .copy

// print full month: these don't have textIDs, so use the table pointer we found in the original
.longmonth:
	mov eax,[esp+4]
	shr eax,5
	add eax,0xe000

.copy:
	push ecx
	push edx
	push esi
	push ebp
	call [ttdtexthandler]
	pop ebp
	pop esi
	pop edx
	pop ecx

	jmp short .nextchar

.done:
// free temporary vars from stack
	add esp,8
	ret


global languagesettings
svard languagesettings

uvarb languagesettings_applied

global restoredefaultcurr
restoredefaultcurr:
	cmp byte [languagesettings_applied],0
	jne .noapply

	mov ebx,[languagesettings]
	cmp ebx,-1
	je .noapply

	shr ebx,8
	mov eax,ebx

	mov byte [languagesettings_applied],1

.noapply:
	mov [measuresys],al

	inc ah
	mov [landscape3+ttdpatchdata.realcurrency],ah
	mov [realcurrency],ah
	dec ah
	cmp ah,5
	jbe .notcustom
	xor ah,ah
.notcustom:
	mov [currency],ah
	ret
