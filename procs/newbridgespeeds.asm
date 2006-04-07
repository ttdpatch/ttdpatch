#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newbridgespeeds, patchnewbridgespeeds

extern bridgespeedlimit.limittable

begincodefragments

codefragment olddisplrailbridgespeed,-77
	db 0xF,0x83,0xA5,0	// jnb near...

codefragment newdisplrailbridgespeed
	call runindex(displrailbridgespeed)
	setfragmentsize 8

codefragment oldbridgespeedlimit,-8
	cmp byte [edi],0x11
	jnz short $+2+3

codefragment newbridgespeedlimit
	call runindex(bridgespeedlimit)
	setfragmentsize 8


endcodefragments


global patchnewbridgespeeds
patchnewbridgespeeds:
	patchcode olddisplrailbridgespeed,newdisplrailbridgespeed,1,1
	stringaddress oldbridgespeedlimit,1,1
	mov eax,[edi+4]
	mov [bridgespeedlimit.limittable],eax
	storefragment newbridgespeedlimit

	// calculating speed limit and applying it now done in tools.asm/postinfoapply.donewbridgespeeds
	ret
