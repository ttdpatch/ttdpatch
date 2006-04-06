#include <defs.inc>
#include <frag_mac.inc>


extern generateincometexteffect


global patchloadunload
patchloadunload:
	patchcode loadunloadcargo
	storeaddress findgenerateincometexteffect,generateincometexteffect
	ret

begincodefragments

codefragment oldloadunloadcargo
	sub     esp, 10h
	mov     ebp, esp
	mov     word [esi+veh.speed], 0

codefragment newloadunloadcargo
	ijmp LoadUnloadCargo
//	times 653-6 int3

codefragment findgenerateincometexteffect
	mov [textrefstack],ebx
	db 0xe8

endcodefragments
