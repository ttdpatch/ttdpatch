#include <defs.inc>
#include <frag_mac.inc>

global patchlongerbridges

varb newbridgelenmult
	db 0,1,2,3,5,7,10,13,16,20,24,28,32,36,40,45,50,55,60,65	// 0..19
	db 70,78,86,94,102,109,115,122,128,134,139,144,149,154,159	// 20..34
	db 163,167,171,175,179,182,186,189,192,195,197,200,203,205	// 35..48
	db 207,209,212,214,215,217,219,221,222,224,225,226,228,229	// 49..62
	db 230,231,232,233,234,235,236,237,238,239,240,241,242,243	// 63..76
	db 244,245,246,246,247,247,248,248,249,249,250,250,251,251	// 77..90
	db 251,252,252,252,253,253,253,253,254,254,254,254,254,254	// 91..104
	times 255-100 db 255

begincodefragments

codefragment getbridgelenmult,6
	db 0,0x75,7,0xf,0xb6,0x92


endcodefragments

patchlongerbridges:
	stringaddress getbridgelenmult,1,1
	mov dword [edi],newbridgelenmult
	ret
