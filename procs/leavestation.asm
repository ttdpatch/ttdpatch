#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc fifoloading,newstations, patchleavestation

begincodefragments

codefragment oldvehleavestation
	test word [esi+veh.currorder], 80h

codefragment_call newvehleavestation,vehleavestation

codefragment oldsendvehtodepot
	movzx esi, dx
	shl esi, 7

codefragment_call newsendvehtodepot,sendvehtodepot,19

endcodefragments

patchleavestation:
	multipatchcode oldvehleavestation,newvehleavestation,4
	multipatchcode oldsendvehtodepot,newsendvehtodepot,4
	ret
