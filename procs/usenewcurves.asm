#include <defs.inc>
#include <frag_mac.inc>


extern curvetype
extern curvetypes


global patchusenewcurves
patchusenewcurves:
	mov edi,curvetypes

.nexttype:
	mov al,[curvetype]
	shr al,cl
	and al,3
	stosb
	add cl,2
	cmp cl,8
	jb .nexttype

	mov cl,0

	patchcode oldcurve,newcurve,1,1
	patchcode oldrvcurve,newrvcurve,1,1
	ret



begincodefragments

codefragment oldcurve
	and dh,7
	cmp dh,1

codefragment newcurve
	jmp runindex(curve)

codefragment oldrvcurve,5
	mov [esi+veh.direction],dl
	mov dl,dh

codefragment newrvcurve
	call runindex(rvcurve)
	setfragmentsize 12


endcodefragments
