#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc tempsnowline, patchtempsnowline

patchtempsnowline:
	patchcode oldclass0_snow,enabletemp_long,1,1
	patchcode oldfields_snow,enabletemp_short,1,1
	patchcode oldclass4_snow,enabletemp_long,1,1
	patchcode oldclass1_snow,enabletemp_short,1,1
	multipatchcode oldclass2_9_snow,enabletemp_short,2
	patchcode map_snow
	ret


begincodefragments

codefragment oldclass0_snow,8
	cmp byte [climate],1
	jne near $+6+0xa9+2*WINTTDX

codefragment enabletemp_long
	db 0x87		// jne near -> ja near

codefragment oldfields_snow,7
	cmp byte [climate],1
	jne $+2+0x2f

codefragment enabletemp_short
	db 0x77		// jne -> ja

codefragment oldclass4_snow,8
	cmp byte [climate],1
	jne near $+6+0xe0

codefragment oldclass1_snow,7
	cmp byte [climate],1
	jne $+2+0x61

codefragment oldclass2_9_snow,7
	cmp byte [climate],1
	jne $+2+0x59

codefragment oldmap_snow,8
	cmp byte [ss:climate],1
	je $+2+0x0a

codefragment newmap_snow
	db 0x76		// je -> jbe


endcodefragments
