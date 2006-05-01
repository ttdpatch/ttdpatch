#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc showprofitinlist, patchshowprofitinlist

begincodefragments

codefragment oldshowprofitdata
	mov eax,[edi+veh.profit]
	mov [textrefstack],eax
	mov eax,[edi+veh.previousprofit]
	mov [textrefstack+4],eax

codefragment newshowprofitdata
	call runindex(showprofitdata)
	setfragmentsize 16


endcodefragments


patchshowprofitinlist:
	multipatchcode oldshowprofitdata,newshowprofitdata,4
	ret
