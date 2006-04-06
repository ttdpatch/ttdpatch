#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc mammothtrains, patchmammothtrains

patchmammothtrains:
	patchcode oldcounttrainsindepot,newcounttrainsindepot,1,1
	patchcode oldfindnexttrain,newchecktrainindepot,1,2
	add edi,lastediadj+67
	storefragment newshowtrain
	add edi,lastediadj+37
	storefragment newshowtrainnum
	add edi,lastediadj+51
	storefragment newshowtrainflag
	patchcode olddepotclick,newdepotclick,1,1
	ret



begincodefragments

codefragment oldcounttrainsindepot,13
	mov cl,[edi+1]
	cmp cl,0

codefragment newcounttrainsindepot
	call runindex(counttrainsindepot)
	setfragmentsize 10

glob_frag oldfindnexttrain
codefragment oldfindnexttrain,4
	add dx,15
	cmp byte [edi+veh.class], 0x10

codefragment newchecktrainindepot
	call runindex(checktrainindepot)
	jc $+2+35
	setfragmentsize 13

codefragment newshowtrain
	call runindex(showtrain)

codefragment newshowtrainnum
	call runindex(showtrainnum)
	jc $+2+13	// $+2+13 to write, $+2+27 to skip writing,

codefragment newshowtrainflag
	call runindex(showtrainflag)
	jc $+2+22	// $+2+6 to draw it, $+2+22 to skip drawing
	setfragmentsize 10

codefragment olddepotclick,9
	db 0
	jnz $+2+16
	cmp dx,[edi+veh.XY]

codefragment newdepotclick
	call runindex(depotclick)
	setfragmentsize 8


endcodefragments
