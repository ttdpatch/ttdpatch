#include <defs.inc>
#include <frag_mac.inc>

global patchsetnewservinterval
patchsetnewservinterval:
	patchcode oldsettrainint,newsetservint,1,2
	patchcode oldsetroadint,newsetservint,1,1
	patchcode oldsetshipint,newsetservint,1,1
	patchcode oldsetplaneint,newsetservint,1,1
	ret



begincodefragments

codefragment oldsettrainint
	mov word [esi+veh.serviceinterval],0x96

codefragment newsetservint
	call runindex(setservint)

reusecodefragment oldsetroadint,oldsettrainint

codefragment oldsetshipint
	mov word [esi+veh.serviceinterval],0x168

codefragment oldsetplaneint
	mov word [esi+veh.serviceinterval],0x64


endcodefragments
