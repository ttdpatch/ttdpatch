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
	ret
