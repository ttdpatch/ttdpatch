#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <textdef.inc>
#include <curr.inc>
#include <patchdata.inc>
#include <patchproc.inc>

patchproc morecurrencies, patchmorecurr

extern backupcurrencydata,num_powersoften,powersoften_last

begincodefragments

codefragment oldcurrprint,1
	ret
	or eax,eax
	jns $+2+6

codefragment_jmp newcurrprint,printcash

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

	pop edx

	call backupcurrencydata

	ret

// this is here because it shares a codefragment
global patch2070servint
patch2070servint:
	patchcode oldlimityear,newlimityear,1,1
	mov byte [edi+lastediadj-2],0x72	// JNZ -> JB
	ret

