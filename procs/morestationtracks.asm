#include <defs.inc>
#include <frag_mac.inc>

extern largestationlayout, maxrstationspread, stationsizevalue, patchflags


global patchmorestationtracks

begincodefragments

codefragment oldcheckistrainstation
#if WINTTDX
//	mov al,getgs(di)
	mov al,[landscape5(di)]
#else
	db 0x67,0x65,0x8A,0x5	//	mov al,gs:[di] with different order of prefixes
#endif
	cmp al,0

codefragment newcheckistrainstation
	call runindex(checkistrainstation)
	setfragmentsize 6+2*WINTTDX

codefragment oldcheckhastrainstation
	db 0x72,0x14	// j somewhere
	cmp word [esi+0xa],byte 0

codefragment newcheckhastrainstation
	call runindex(hastrainstation)
	nop

codefragment oldsetstationsize
	mov al,dl
	shl al,3
	or al,dh

codefragment newsetstationsize
	call runindex(setstationsize)
	nop

codefragment oldgetstationlayout,-10
	movzx eax,dl
	mov ebp,[eax*4+ebp-4]

codefragment newgetstationlayout
	mov ebp,largestationlayout
	push es
	push ds
	pop es
	pusha
	call runindex(getstationlayout)
	popa
	pop es
	setfragmentsize 17

codefragment oldtracknumsel,2
	pop esi
	pop eax
	sub cl,5

codefragment newtracknumsel
	call runindex(tracknumsel)
	nop

codefragment oldtracklensel,2
	pop esi
	pop eax
	sub cl,9

codefragment oldgetplatformsforremovestation 
	mov dh, dl
 	and dx, 3807h
 	shr dh, 3

codefragment newgetplatformsforremovestation 
	call runindex(convertplatformsinremoverailstation)
	setfragmentsize 10

codefragment oldgetplatformsforcargoacceptlist
	mov ah, al
	and ax, 3807h
	shr ah, 3

codefragment newgetplatformsforcargoacceptlist 
	call runindex(convertplatformsincargoacceptlist)
	setfragmentsize 9


endcodefragments

patchmorestationtracks:
	patchcode oldcheckistrainstation,newcheckistrainstation,1,1
	patchcode oldcheckhastrainstation,newcheckhastrainstation,1,1
	patchcode oldsetstationsize,newsetstationsize,1,1

	patchcode oldgetstationlayout,newgetstationlayout,1,1

#if 0
	testflags enhancegui
	sbb bl,bl		// 0 = patch it, -1 = only search
#endif

	patchcode oldtracknumsel,newtracknumsel // ,1,1,,{test bl,bl},z
	stringaddress oldtracklensel,1,1
#if 0
	test bl,bl
	jnz short .wehaveenhguidone
	storefragment newtracklensel
	mov esi,[edi]
	mov dword [stationsizeofs],esi
	mov eax,0x90909090
	stosd
	stosw

.wehaveenhguidone:
#endif
	// Patches for real big stations
	//patchcode oldcalcplatformsfornewstation, newcalcplatformsfornewstation,1,1
	patchcode oldgetplatformsforremovestation,newgetplatformsforremovestation,1,1
	patchcode oldgetplatformsforcargoacceptlist,newgetplatformsforcargoacceptlist,1,1
	
	mov al, 15	//default max station size
	testflags stationsize
	jnc .usedefaultstationsize
	mov al, [stationsizevalue]
.usedefaultstationsize:
	mov [maxrstationspread], al
	ret
