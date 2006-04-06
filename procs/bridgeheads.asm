#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>

extern class9routemaphandler,drawrailwaytile,newclass9drawland
extern oldclass9drawland2,oldclass9routemaphandler
extern temptracktypeptr

glob_frag oldremovetunneltrack

global patchbridgeheads

begincodefragments

codefragment finddrawrailwaytile
	mov esi, ebx
	or di, di

codefragment oldbuildbridgetrack, -10
	mov dl, dh
	and dl, 0C7h
	or dl, 20h

codefragment newbuildbridgetrack
	icall buildbridgetrack
	setfragmentsize 8

codefragment oldremovebridgetrack, -14
	mov dl, dh
	and dl, 0C7h
	test dh, 1

// tunbridg.asm
glob_frag oldremovetunneltrack
reusecodefragment oldremovetunneltrack, oldremovebridgetrack, -6

codefragment newremovebridgetrack
	icall removebridgetrack
	setfragmentsize 8

codefragment oldbuildbridgeroad,2
	dw 1007h	// Already built
	mov dl, dh
	and dl, 0F9h
	cmp dl, 0E8h

codefragment newbuildbridgeroad
	icall buildbridgeroad
	setfragmentsize 8

codefragment oldremovebridgeroad
	mov dl, dh
	and dl, 0F9h
	cmp dl, 0E8h

codefragment newremovebridgeroad
	icall removebridgeroad
	setfragmentsize 8

codefragment oldbuildbridgehead,-12
	pop bx
	pop ebp
	db 0xff	// inc ...

codefragment newbuildbridgehead
	icall buildbridgehead
	setfragmentsize 7


endcodefragments

patchbridgeheads:
	mov eax, [ophandler+0x09*8]
	mov ecx, [eax+0x1C]
	mov [oldclass9drawland2], ecx
	mov dword [eax+0x1C],addr(newclass9drawland)
	mov ecx, [eax+0x24]
	mov [oldclass9routemaphandler], ecx
	mov dword [eax+0x24],addr(class9routemaphandler)

	storeaddress finddrawrailwaytile, 1,1, drawrailwaytile

	stringaddress oldbuildbridgetrack,1,1
	mov eax, [edi-67]
	mov [temptracktypeptr], eax
	storefragment newbuildbridgetrack
	patchcode oldremovebridgetrack,newremovebridgetrack,1,1
	patchcode oldbuildbridgeroad,newbuildbridgeroad,1,1
	patchcode oldremovebridgeroad,newremovebridgeroad,1,1 // depends on ^^

	multipatchcode oldbuildbridgehead,newbuildbridgehead,2	// patch both bridgeheads
	ret
