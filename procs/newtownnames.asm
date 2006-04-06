#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newtownnames, patchnewtownnames


extern defaultstylename,gettextandtableptrs

#include <textdef.inc>

begincodefragments

codefragment oldmakeenglishgermanname
	mov word [tempvar],0

codefragment newmakeenglishgermanname
	call runindex(makeenglishgermanname)
	setfragmentsize 9

codefragment oldensuretownnamelength
.next:
	inc esi
	cmp byte [esi], 0
	jnz .next
	db 0x81

codefragment newensuretownnamelength
	call runindex(ensuretownnamelength)
	setfragmentsize 12

codefragment oldmakeenglishgermanseed
	shl edx,31
	and eax,0x7fffffff

codefragment newmakeenglishgermanseed
	call runindex(makeenglishgermanseed)
	setfragmentsize 10

codefragment oldtownnamestyledropdown,9
	mov word [tempvar+10],0x02f3
	mov word [tempvar+12],-1

codefragment newtownnamestyledropdown
	jmp runindex(townnamestyledropdown)

codefragment oldtownnamestyledisplay,4
	add ax,0x02ee
	mov [textrefstack+8],ax

codefragment newtownnamestyledisplay
	call runindex(townnamestyledisplay)

codefragment oldtownnameselect,8
	jnz near $+6+0x108
	mov dl,al
	xor ax,ax

codefragment newtownnameselect
	call runindex(townnameselect)

endcodefragments

patchnewtownnames:
	patchcode oldmakeenglishgermanname,newmakeenglishgermanname,1,1
	patchcode oldensuretownnamelength,newensuretownnamelength,1,1
	patchcode oldmakeenglishgermanseed,newmakeenglishgermanseed,1,1
	mov ax,ourtext(unnamedtownnamestyle)
	call gettextandtableptrs
	mov [defaultstylename],edi
	patchcode oldtownnamestyledropdown,newtownnamestyledropdown,1,1
	patchcode oldtownnamestyledisplay,newtownnamestyledisplay,1,1
	patchcode oldtownnameselect,newtownnameselect,1,1
	ret
