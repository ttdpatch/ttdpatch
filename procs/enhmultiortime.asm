#if WINTTDX
#include <defs.inc>
#include <frag_mac.inc>

global patchenhmultiortime

begincodefragments

codefragment oldwaitforconnection2,5
	call dword [eax+0x34]
	test eax,eax
	jnz near $+6+0x14

codefragment newwaitforconnection2
	call runindex(waitforconnection2)

codefragment oldrecresult
	mov [ebp-8],eax
	cmp dword [ebp-0xc],byte 0

codefragment newrecresult
	call runindex(recresult)
	setfragmentsize 7



#ifdef LOGDPLAYERRORS
codefragment oldsendresult
	call dword [eax+0x5c]
	mov [ebp-4],eax

codefragment newsendresult
	call runindex(sendresult)
#endif

endcodefragments

patchenhmultiortime:
	patchcode oldwaitforconnection2,newwaitforconnection2,1,1
	patchcode oldrecresult,newrecresult,1,1
	ret



#endif
