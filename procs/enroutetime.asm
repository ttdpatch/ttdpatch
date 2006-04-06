#include <defs.inc>
#include <frag_mac.inc>

global patchenroutetime
patchenroutetime:
	patchcode oldenroutetimenextveh,newenroutetimenextveh,1,2
	patchcode oldenroutetimenextveh,newenroutetimenextveh,1,1
	ret



begincodefragments

codefragment oldenroutetimenextveh,3
	inc byte [edi+veh.cargotransittime]
	db 0x66,0x8b	// mov di,[edi.nextwaggon]

codefragment newenroutetimenextveh
	or di,byte -1

endcodefragments
