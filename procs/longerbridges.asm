#include <defs.inc>
#include <frag_mac.inc>


extern newbridgelenmult


global patchlongerbridges
patchlongerbridges:
	stringaddress getbridgelenmult,1,1
	mov dword [edi],newbridgelenmult
	ret



begincodefragments

codefragment getbridgelenmult,6
	db 0,0x75,7,0xf,0xb6,0x92


endcodefragments
