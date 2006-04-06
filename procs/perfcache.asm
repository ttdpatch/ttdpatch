#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchprocandor newperformance,showprofitinlist,, patchperfcache


extern malloccrit,newvehicles
extern perfcacheptr


patchperfcache:			// alloc a cache for performance scores so vehicle lists can be drawn faster
	push dword [newvehicles]
	call malloccrit
	pop dword [perfcacheptr]
	ret


