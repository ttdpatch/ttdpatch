#include <defs.inc>
#include <frag_mac.inc>


extern aitryairroute,aitryairroute.origfn,aitryroadcargoroute
extern aitryshipcargoroute,aitrytrainroute,aitrytrainroute.origfn
extern goodairoutefnofst


global patchairandomroutes

begincodefragments

codefragment aitryrandomroute,7
	cmp ax,0xd89b
	jb short $+2+0x15


endcodefragments

patchairandomroutes:
	stringaddress aitryrandomroute
	mov ebx,[edi]
	lea ebx,[edi+ebx+4+29]
	chainfunction aitrytrainroute,.origfn,7
	chainfunction aitryairroute,.origfn,21
	mov eax,[edi+14]
	lea edi,[edi+eax+4+14+71]
	chainfunction aitryroadcargoroute,goodairoutefnofst,0,1
	changereltarget 252,addr(aitryroadcargoroute)
	changereltarget 536,addr(aitryroadcargoroute)
	changereltarget 792,addr(aitryroadcargoroute)
	changereltarget 0,addr(aitryshipcargoroute),ebx
	ret
