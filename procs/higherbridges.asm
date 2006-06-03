#include <defs.inc>
#include <frag_mac.inc>


extern bridgechecklandscapeforstartorend,bridgedrawmiddlepartpillar
extern bridgedrawrailunder,bridgedrawroadunder,bridgeendfoundation
extern bridgeendfoundationhigherbridges,bridgevehmaxspeed
extern selectgroundforbridge


global patchhigherbridges

begincodefragments

codefragment oldvehzisonthebridge, -12
	cmp dl, [esi+0x1e]
	jz $+2+3
	add dl, 8

codefragment newvehzisonthebridge
	//mov dl, [esi+0x1e]
	call runindex(bridgevehzisonthebridge)
	setfragmentsize 20

codefragment oldbridgemiddlezcorrect
	add dl, 8
	xor dh, dh
	ret
	mov dh, 1

codefragment newbridgemiddlezcorrect
	jmp runindex(bridgemiddlezcorrect)

codefragment findbridgevehmaxspeed
	cmp dl, 2
	jbe $+2+0x2E

codefragment oldbridgedrawmiddlepart
	add dl, 5
	mov di, 10h
	
codefragment newbridgedrawmiddlepart
	call runindex(bridgedrawmiddlepart)
	nop

codefragment oldbridgedrawrouterail, 33
	or esi, ebx
	shl esi, 1

codefragment oldbridgedrawrouteroad, 5
	or bx, bx
	jz $+2+0x05


codefragment oldbridgedrawmiddlepartpillar, 8
	mov ebx, [ebx+edi+8]
	or ebx, ebx
	jz $+2+05

glob_frag oldselectgroundforbridge
codefragment oldselectgroundforbridge, 33
	and esi, 1800h
	shr esi, 9
	push ebx

glob_frag oldcanstartendbridgehere
codefragment oldcanstartendbridgehere,2
	jb short $+2+0x15
	pop bx
	pop ebp

reusecodefragment oldbridgecheckzstartend, oldcanstartendbridgehere, -21

codefragment oldbridgemiddlecheckslopeok, -7
	dw 0x5009
	or di, di
	jz $+2+12

codefragment newbridgemiddlecheckslopeok
 	call runindex(bridgemiddlecheckslopeok)
	//setfragmentsize 26 <-- crap
	jmp short $+2+18
	nop
	
codefragment oldbridgeendsaveinlandscape
	mov byte [landscape2+esi], dl
	db 0x8A, 0x15	// mov dl,...

codefragment newbridgeendsaveinlandscape
	call runindex(bridgeendsaveinlandscape)
	

codefragment oldbridgemiddlesaveinlandscape
	or byte [nosplit landscape3+edi*2], dl
	db 0xE8

codefragment newbridgemiddlesaveinlandscape
	call runindex(bridgemiddlesaveinlandscape)
	nop

codefragment oldremovebridgewater
	mov dx, 6000h
	db 0xeb, 0x39	// jmp short ...

codefragment newremovebridgewater
	icall removebridgewater

codefragment oldgetnormalclassunderbridge
	mov dl, al
	and eax, byte 0x18
	shr eax, 1

codefragment newgetnormalclassunderbridge
	icall getnormalclassunderbridge
	nop


endcodefragments

patchhigherbridges:
	multipatchcode oldvehzisonthebridge, newvehzisonthebridge,2
	
	patchcode oldbridgemiddlezcorrect, newbridgemiddlezcorrect,1,1
	
	stringaddress findbridgevehmaxspeed,1,1
	storefunctioncall bridgevehmaxspeed
	mov word [edi-9], 0x9090
	
	patchcode oldbridgedrawmiddlepart, newbridgedrawmiddlepart,1,1
	
	stringaddress oldbridgedrawrouterail,1,1
	storefunctioncall bridgedrawrailunder
	stringaddress oldbridgedrawrouteroad,1,1
	storefunctioncall bridgedrawroadunder

	stringaddress oldbridgedrawmiddlepartpillar,1,1
	storefunctioncall bridgedrawmiddlepartpillar
// now in patchcanalshigherbridges
//	stringaddress oldselectgroundforbridge
//	storefunctioncall selectgroundforbridge

// Manage Bridge building
	stringaddress oldbridgecheckzstartend,1,2
	storefunctioncall bridgechecklandscapeforstartorend
	stringaddress oldbridgecheckzstartend,2,2		// just find the next one
	storefunctioncall bridgechecklandscapeforstartorend
	patchcode oldbridgemiddlecheckslopeok,newbridgemiddlecheckslopeok,1,1

	multipatchcode oldbridgeendsaveinlandscape, newbridgeendsaveinlandscape,2
	patchcode oldbridgemiddlesaveinlandscape,newbridgemiddlesaveinlandscape,1,1

	// switch slope build mask
	mov esi, [bridgeendfoundationhigherbridges]
	mov [bridgeendfoundation], esi
	mov esi, [bridgeendfoundationhigherbridges+4]
	mov [bridgeendfoundation+4], esi

	patchcode oldremovebridgewater,newremovebridgewater,1,1

	patchcode oldgetnormalclassunderbridge, newgetnormalclassunderbridge,1,1
	ret
