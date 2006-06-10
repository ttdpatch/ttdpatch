#include <defs.inc>
#include <frag_mac.inc>
#include <player.inc>
#include <window.inc>

global patchsubsidiaries

begincodefragments

codefragment oldborrow
	add [esi+player.loan],ebx
	add [esi+player.cash],ebx

codefragment newborrow
	call runindex(borrow)

codefragment oldrepay,-16
	sub [esi+player.loan],ebp
	sub [esi+player.cash],ebp

codefragment newrepay
	call runindex(repay)

codefragment_call dorepay,dorepay

codefragment oldclickhq,-10
	mov ax,[esi+window.id]
	db 0x3a,5	// cmp al,[human1]

codefragment newclickhq
	call runindex(clickhq)
	db 0x72		// jc; dest. set later

reusecodefragment oldborrowamount,oldborrow,-21
codefragment newloanamount
	push byte 0xc	// PL_PLAYER+PL_NOTTEMP
	mov [esp+1],dl
	call runindex(ishumanplayer)
	setfragmentsize 14

reusecodefragment oldrepayamount,oldrepay,-37

codefragment oldaibuyout,7
	bts ebp,ebx
	dec cl
	jnz $+2-0x4b

codefragment newaibuyout
	push byte 0x14	// PL_PLAYER+PL_ORG
	mov [esp+1],bl
	call runindex(ishumanplayer)
	setfragmentsize 14


endcodefragments

patchsubsidiaries:
	patchcode oldclickhq,newclickhq,1,1
	mov al,[edi+2]
	inc al
	stosb

	patchcode oldborrowamount,newloanamount,1,1
	patchcode oldrepayamount,newloanamount,1,1
	patchcode oldaibuyout,newaibuyout,1,1
	ret

global patchmaxloanwithctrl
patchmaxloanwithctrl:
	patchcode oldborrow,newborrow,1,1
	patchcode oldrepay,newrepay,1,1
	add edi,16+lastediadj
	storefragment dorepay
	ret
