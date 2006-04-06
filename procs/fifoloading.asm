#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc fifoloading, patchfifoloading

patchfifoloading:
	patchcode oldtrainleavestation,newtrainleavestation
	patchcode oldsendtraintodepot,newsendtraintodepot
	ret


begincodefragments

codefragment oldtrainleavestation, 5
	db 0xE8, 0x28, 0, 0, 0
	test word [esi+veh.currorder], 80h
	mov word [esi+veh.currorder], 4

codefragment newtrainleavestation
	icall trainleavestation

codefragment oldsendtraintodepot,1
	db 0x08
	movzx esi, dx
	shl esi, 7

codefragment newsendtraintodepot
	icall sendtraintodepot


endcodefragments
