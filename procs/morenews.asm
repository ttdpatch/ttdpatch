#include <defs.inc>
#include <frag_mac.inc>
#include <industry.inc>
#include <station.inc>

global patchmorenews

begincodefragments

codefragment olddestroylargeufo
	mov word [esi+veh.currorder],1
	mov ax,word [edi+veh.xpos]

codefragment newdestroylargeufo
	call runindex(largeufodestroynews)

codefragment oldlmillcuttree1
	sub bx,0x101
	cmp cl,41

codefragment newlmillcuttree1
	call runindex(lmillcuttree1)
	setfragmentsize 8

codefragment oldlmillcuttree2
	add word [esi+industry.amountswaiting],45
	jae $+2+6
	mov word [esi+industry.amountswaiting],0xffff

codefragment newlmillcuttree2
	call runindex(lmillcuttree2)
	setfragmentsize 13

codefragment oldclearzeppelin
	btr word [edi+station.airportstat],7

codefragment newclearzeppelin
	call runindex(clearzeppelin)
	setfragmentsize 9

codefragment oldclearcrashedaircraft
	btr word [ebx+station.airportstat], ax
	push esi

codefragment newclearcrashedaircraft
	call runindex(clearcrashedaircraft)
	setfragmentsize 8


endcodefragments

patchmorenews:
	patchcode olddestroylargeufo,newdestroylargeufo,1,1
	patchcode oldlmillcuttree1,newlmillcuttree1,1,1
	patchcode oldlmillcuttree2,newlmillcuttree2,1,1
	patchcode oldclearzeppelin,newclearzeppelin,1,1
	patchcode oldclearcrashedaircraft,newclearcrashedaircraft,1,1
	ret
