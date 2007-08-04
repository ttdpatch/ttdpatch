#include <defs.inc>
#include <frag_mac.inc>


extern startyear
extern yeartodate


global patchstartyear

begincodefragments

codefragment oldexpirevehtype,4
	mov [esi+6],ax
	mov word [esi],0

codefragment newexpirevehtype
	jmp runindex(expirevehtype)	// overwrites a RET

codefragment olddatelowerbound,7
	cmp word [currentdate],0x2ACE
	db 0x76				// jbe short

codefragment newdatelowerbound
	dw 366			// 1921-1-1

codefragment olddateupperbound,7
	cmp word [currentdate],0x4E79

codefragment newdateupperbound
	dw 40177		// 2030-1-1

codefragment initdatecode,6
	mov byte [currentyear],30

codefragment oldRedrawOptionsWindow,61
	shr al, 4
	and ax, 1
	add ax, 0x02E9

codefragment newRedrawOptionsWindow
extern gameoptionsstartyrtredraw
	icall gameoptionsstartyrtredraw
	ret
	setfragmentsize 11

codefragment storenewdate
extern usenewstartyear
	icall usenewstartyear
	setfragmentsize 17

endcodefragments

patchstartyear:
//	patchcode oldinitvehtypeavail,newinitvehtypeavail,1,1
	patchcode oldexpirevehtype,newexpirevehtype,1,1

	patchcode olddatelowerbound,newdatelowerbound,1,1
	patchcode olddateupperbound,newdateupperbound,1,1
	changeloadedvalue initdatecode,1,1,b,startyear
	movzx eax,al
	pusha
	call yeartodate			// preserves EDI
	mov [edi-10],ebx
	popa
		
	cmp dword [StartYearDataPointers], -1 ; Then we need to do some more things
	jne .PatchOptionsWindow
	ret

extern gameoptionsnewstartyear, gameoptionsstartyrthints, gameoptionsgrfstat
.PatchOptionsWindow:
	; Time to do a little patching of our own
	lea edi, [edi - 16]
	storefragment storenewdate

	; If newgrf has been instalized (which since its technically impossible to to turn off it should have been)
	patchcode oldRedrawOptionsWindow, newRedrawOptionsWindow

	mov edi, [StartYearDataPointers + 4] ; Find the pointer to the address of the list
	sub edi, 22 ; One call (5), one mov dword (5) and 2 mov words (4), then back one dword (4)
	add dword [edi], 0x2A0000 ; It should be about 42 pixels longer
	
	mov edi, [StartYearDataPointers] ; Get the pointer the window element list is stored
	add word [edi + 2*12 + 8], 42 ; Increase this to be an extra 42 px

	add dword [edi + 18*12 + 6], 0x002A002A ; Move the save custom vehicle names down
	add dword [edi + 19*12 + 6], 0x002A002A ; This is 4 elements 
	add dword [edi + 20*12 + 6], 0x002A002A
	add dword [edi + 21*12 + 6], 0x002A002A
	
	mov edi, [StartYearDataPointers] ; Copy across the new window elements
	add edi, 22*12 + 2*12
	mov esi, gameoptionsnewstartyear
	mov cl, 4*12 + 1 ; All elements plus a new terminator
	rep movsb
	ret
	
global StartYearDataPointers, newgamestartyear
StartYearDataPointers:
	; These are broken down to, option windows, pointer for entry point
	dd -1, -1

