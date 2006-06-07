#include <defs.inc>
#include <frag_mac.inc>
#include <textdef.inc>
#include <town.inc>
#include <patchproc.inc>

patchprocandor generalfixes,BIT(MISCMODS_DISPLAYTOWNSIZE),, patchdisplaytownsize

begincodefragments

codefragment oldtowntextid,2
	mov bx, 0x2001

codefragment newtowntextid
	dw statictext(townnamesize)

codefragment olddrawtownsize
	shl edx, 10h
	shr ebp, 10h

codefragment newdrawtownsize
	icall drawtownsize

codefragment oldSetTownNamePosition,5
	mov [esi+town.nameposy],cx
	push esi
	mov eax, [esi+town.citynameparts]

codefragment newSetTownNamePosition
	icall SetTownNamePosition
	setfragmentsize 12

codefragment oldsettownnamepositionend
	add cx, 2
	mov [esi+town.namewidthsmall], cl

codefragment newsettownnamepositionend
	ijmp settownnamepositionend


endcodefragments

patchdisplaytownsize:
	multipatchcode oldtowntextid,newtowntextid,2
	patchcode olddrawtownsize,newdrawtownsize,1,3
	patchcode olddrawtownsize,newdrawtownsize,1,0
	patchcode SetTownNamePosition
	patchcode settownnamepositionend
	ret
