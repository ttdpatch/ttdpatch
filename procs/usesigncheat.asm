#include <defs.inc>
#include <frag_mac.inc>

global patchusesigncheat
patchusesigncheat:
	patchcode oldsetsignsize,newsetsignsize,1,1
	patchcode oldputsign,newputsign,1+WINTTDX,7
	patchcode oldcheckduplicate,newcheckduplicate,1,1
	ret



begincodefragments

codefragment oldsetsignsize,1
	pusha
	mov ax,[esi+2]

codefragment newsetsignsize
	call runindex(signcheat)
	setfragmentsize 8

codefragment oldputsign
	xor ebx,ebx
	call dword [ebp+4]
	mov di,ax

codefragment newputsign
	call runindex(putsign)
	setfragmentsize 8

codefragment oldcheckduplicate
	cmp byte [ebx],0
	jne $+2+7
	mov esi,ebx
	mov ax,bp
	jmp short $+2+0x1f

codefragment newcheckduplicate
	call runindex(checkduplicate)
	jne $+2+0x23
	setfragmentsize 12

endcodefragments
