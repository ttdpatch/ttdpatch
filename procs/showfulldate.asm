#include <defs.inc>
#include <frag_mac.inc>


extern patchflags


global patchshowfulldate
patchshowfulldate:
	stringaddress oldshowdate
	testmultiflags showfulldate
	jz .notfulldate
	push edi
	add edi,7
	storefragment newshowdate
	pop edi
.notfulldate:
	testmultiflags gamespeed
	jz .notgamespeed
	storefragment newshowgamespeed
.notgamespeed:
	ret



begincodefragments

codefragment oldshowdate,4
	mov bx,0xae
	db 0x80		// cmp ...

codefragment newshowdate
	setfragmentsize 2

codefragment newshowgamespeed
	icall showgamespeed
	setfragmentsize 7


endcodefragments
