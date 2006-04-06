#include <defs.inc>
#include <frag_mac.inc>
#include <misc.inc>
#include <patchproc.inc>

patchproc gamespeed, patchgamespeed


extern initgamespeed,setgamespeed
extern waitforretrace

begincodefragments

#if !WINTTDX
codefragment oldcalcsimticks
	xor dx,dx
	mov cx,8

codefragment newcalcsimticks
	call runindex(calcsimticks)
	setfragmentsize 7

codefragment findwaitforretrace
	jnz $-3
	in al,dx
	test al,8
#endif


endcodefragments
begincodefragments

#if WINTTDX
codefragment oldtickcheck
	mov ebx, 0x1b
	div ebx

codefragment newtickcheck
	call runindex(tickcheck)
	setfragmentsize 7
#endif


endcodefragments


patchgamespeed:
#if WINTTDX
	patchcode oldtickcheck,newtickcheck,1,1
#else
	patchcode oldcalcsimticks,newcalcsimticks,1,1
	storeaddress findwaitforretrace,3,3,waitforretrace
#endif

	mov cl,[initgamespeed]
	add cl,GS_DEFAULTFACTOR
	call setgamespeed
	ret
