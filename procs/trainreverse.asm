#include <defs.inc>
#include <frag_mac.inc>


extern exchtrainvehicles


global patchtrainreverse

begincodefragments

codefragment oldreversetrain,32
	mov edi,esi
	mov dx,0xff00

codefragment newreversetrain
	jmp runindex(reversetrain)


endcodefragments

patchtrainreverse:
	stringaddress oldreversetrain,1,1
	copyrelative exchtrainvehicles,1
	storefragment newreversetrain
	ret
