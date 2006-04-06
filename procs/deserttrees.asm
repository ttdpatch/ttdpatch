#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

//patchproc canmodifygraphics, patchallowtreesindesert
patchproc VARBIT(grfmodflags,0), patchallowtreesindesert
patchproc VARBIT(grfmodflags,1), patchpavementindesert
patchproc VARBIT(grfmodflags,2), patchhigherfields

extern class0procmidsection,grfmodflags,variabletofind

ext_frag findvariableaccess

begincodefragments

codefragment oldplantdeserttree,-10
	imul	cx, 7
	shr	cx, 8
	add	cl, 14h

codefragment newplantdeserttree
	ijmp	addtreesindesert
	
codefragment oldplantdeserttree2
	and	ax, 0F807h
	cmp	al, 3

codefragment newplantdeserttree2
	icall	plantmoretreesindesert
	setfragmentsize 6
	
codefragment oldchecktileforfarm
	and	dh, 1Ch

codefragment newchecktileforfarm
	icall	keepfieldsinthedesert
	setfragmentsize 8	

codefragment oldchecktileforfarm2
	cmp dh,14h

codefragment newchecktileforfarm2
	icall	keepfieldsinthedesert2
	jmp	[class0procmidsection]

codefragment oldchecktileforfarm3
	cmp dh,14h

codefragment newchecktileforfarm3
	icall	keepfieldsinthedesert3
	jmp newchecktileforfarm3_start+40+2*WINTTDX

codefragment olddrawgroundfield,-21
	add	bx,0FB7h

codefragment newdrawgroundfield
	icall	addgroundspritewithbounds
	setfragmentsize 7

codefragment oldpavementindesert,-13
	add	bx, byte -19

codefragment newpavementindesert
	icall	allowpavementindesert
	jmp newpavementindesert_start+17

codefragment oldlevelcrossingsdesert,-29
	and	ebx, 0FFFFh
	or	ebx, 3178000h

codefragment newlevelcrossingsdesert
	icall	changedesertlevelcrossings
	jmp newlevelcrossingsdesert_start+50

endcodefragments

patchallowtreesindesert:
	patchcode plantdeserttree		//not only new trees... but replant randomly
	patchcode plantdeserttree2		//in desert
	patchcode checktileforfarm,1,2		//chunks to allow farms in deserts
	patchcode checktileforfarm2,1+WINTTDX,3
	patchcode checktileforfarm3,1+WINTTDX,2
	ret

patchhigherfields:
	patchcode drawgroundfield		//allow fields to have hieght+boundingbox
	ret

patchpavementindesert:
	patchcode pavementindesert		//pavement in desert
	patchcode levelcrossingsdesert,3-WINTTDX,3
	ret

