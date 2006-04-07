#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc moretoylandfeatures, patchtoylandfeatures


extern toylandfeatures

begincodefragments

codefragment oldskiptoylandclassa,6
	cmp byte [climate],3
	db 0x0f,0x84		// jz near...

// codefragment newskiptoylandclassa in patches.ah

codefragment oldskiptoylandwoodlands,6
	cmp byte [climate],3
	jz short $+2+5

// codefragment newskiptoylandwoodlands in patches.ah

endcodefragments


patchtoylandfeatures:
	mov bl,[toylandfeatures]
	stringaddress oldskiptoylandclassa,1,1
	test bl,1
	jz .nolighthouses
	mov byte [edi],-1			// impossible climate, so the test always fails
.nolighthouses:
	stringaddress oldskiptoylandwoodlands,1,1
	test bl,2
	jz .nowoodlands
	mov byte [edi],-1			// ditto
.nowoodlands:
	ret
