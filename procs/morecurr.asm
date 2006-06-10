#include <defs.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <textdef.inc>
#include <curr.inc>
#include <patchdata.inc>
#include <patchproc.inc>

patchproc morecurrencies, patchmorecurr

extern backupcurrencydata

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

	call backupcurrencydata

	ret

// this is here because it shares a codefragment
global patch2070servint
patch2070servint:
	patchcode oldlimityear,newlimityear,1,1
	mov byte [edi+lastediadj-2],0x72	// JNZ -> JB
	ret

