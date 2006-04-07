#include <defs.inc>
#include <frag_mac.inc>
#include <flagdata.inc>

extern mountaintypes
extern patchflags


global patchusenewmountain

begincodefragments

codefragment oldmountain
	cmp dl,[esi+veh.zpos]
	je $+2+29

codefragment newmountain
	jmp runindex(mountain)

codefragment oldrvhillhandler
	cmp dl,[esi+veh.zpos]
	je $+2+0x21

//codefragment newrvhillhandler
//	jmp runindex(rvhillhandler)
//

endcodefragments

patchusenewmountain:
	mov edi,mountaintypes

.nexttype:
	mov al,[mountaintype]
	shr al,cl
	and al,3
	stosb
	add cl,2
	cmp cl,8
	jb .nexttype
	cmp byte [mountaintypes+3],3
	jb .notrvpower

	testflags rvpower,bts

.notrvpower:
	mov cl,0

	patchcode oldmountain,newmountain
	patchcode oldrvhillhandler,newmountain,1,1
	ret
