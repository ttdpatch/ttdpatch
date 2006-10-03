// Houses the fragments for Convert Vehicle

#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <textdef.inc>

extern ConvertEngineHook

patchprocandor experimentalfeatures,BIT(EXP_ENGINECONVERT),, patchconvertengine

begincodefragments

codefragment oldconverthook
	cmp byte [edi+veh.subclass], 0
	db 0x0F, 0x84, 0xA1, 0x00, 0x00, 0x00
	cmp edx, edi

codefragment newconverthook
	icall ConvertEngineHook
	db 0x73, 0x1
	ret
	setfragmentsize 10

endcodefragments

patchconvertengine:
	patchcode oldconverthook, newconverthook
	ret

