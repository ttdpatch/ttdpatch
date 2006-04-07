#include <defs.inc>
#include <frag_mac.inc>
#include <town.inc>
#include <station.inc>

extern malloccrit,townarray2ofst

ext_frag oldcompletehousecreated

global patchmoretowndata

begincodefragments

codefragment newcompletehousecreated
	call runindex(completehousecreated)
	mov [esi+town.population],ax
	setfragmentsize 12

codefragment oldhouseconstrcomplete,-8
	add [edi+town.population],ax
	push ebx

codefragment newhouseconstrcomplete
	call runindex(houseconstrcomplete)
	mov [edi+town.population],ax
	setfragmentsize 12

codefragment oldremovehousepopulation,-8
	sub [edi+town.population],bx
	db 0x66

codefragment newremovehousepopulation
	call runindex(removehousepopulation)
	mov [edi+town.population],bx
	setfragmentsize 12

codefragment oldrecordtownstats
	mov [esi+town.actmailtrans],ax
	db 0x8b,0xde		// mov ebx,<r/m> esi

codefragment newrecordtownstats
	call runindex(recordtownextstats)

codefragment oldtownacceptedcargo,3
	mov ebx,[edi+station.townptr]
	cmp ch,11

codefragment newtownacceptedcargo
	call runindex(townacceptedcargo)
	setfragmentsize 18

codefragment oldrecordtransppassmail,6
	db 0x32,0xe4		// xor ah,<r/m> ah
	shr cx,8

codefragment newrecordtransppassmail
	mov dl,0		// will be 2 after the first patching
	call runindex(recordtransppassmail)

codefragment olddisplaypopulation
	movzx eax,word [ebx+town.population]
	db 0xa3			// mov [textrefstack],eax

codefragment newdisplaypopulation
	call runindex(display32bitpopulation)
	setfragmentsize 9

codefragment olddisplaypopulation2,4
	movzx ebx,word [esi+town.population]
	db 0x89			// mov [textrefstack+6],ebx

codefragment newdisplaypopulation2
	call runindex(display32bitpopulation2)


endcodefragments

patchmoretowndata:
	push numtowns*town2_size
	call malloccrit
	pop eax
	sub eax,townarray
	mov [townarray2ofst],eax

	patchcode oldcompletehousecreated,newcompletehousecreated,1,1
	patchcode oldhouseconstrcomplete,newhouseconstrcomplete,1,1
	patchcode oldremovehousepopulation,newremovehousepopulation,1,1
	patchcode oldrecordtownstats,newrecordtownstats,1,1
	patchcode oldtownacceptedcargo,newtownacceptedcargo,1,1
	multipatchcode oldrecordtransppassmail,newrecordtransppassmail,2,{mov byte [esi+ediadj+1],2}
	patchcode olddisplaypopulation,newdisplaypopulation,1,1
	patchcode olddisplaypopulation2,newdisplaypopulation2,1,1
	ret
