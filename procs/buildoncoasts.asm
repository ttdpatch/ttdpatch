#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc buildoncoasts, patchbuildoncoasts


extern dofloodcoast


patchbuildoncoasts:
	patchcode oldcanbuildonwater,newcanbuildonwater,1,1
	patchcode oldcanalwaysremoveroad,newcanalwaysremoveroad,1,1
	stringaddress prepfloodcoast,1,1
	changereltarget 0,addr(dofloodcoast)
	ret



begincodefragments

codefragment oldcanbuildonwater,-3
	dd operrormsg2
	dw 0x3807	// "Can't build on water"

codefragment newcanbuildonwater
	call runindex(canbuildonwater)
	jmp short $+6

codefragment oldcanalwaysremoveroad
	db 0x8a,0xfe		// mov bh,<r/m> dh
	and bh,0xf

codefragment newcanalwaysremoveroad
	call runindex(canalwaysremoveroad)
	jc short $+2+17

codefragment prepfloodcoast,13
	dd curplayer		// mov byte [curplayer],0x11
	db 0x11
	mov bl,3


endcodefragments
