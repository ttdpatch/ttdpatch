#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>
#include <patchproc.inc>

patchproc morestationtracks,newstations, patchbuildstationwindow

extern addnewtrackbuttons,createstationwindow,stationwindowclickhandler
extern createstationwindow.old,stationwindoweventhandler
extern stationwindoweventhandler.oldhandler,malloccrit


patchbuildstationwindow:
	// build rail station select win add buttons
	stringaddress findwindowrailstationelements,1,1

	call addnewtrackbuttons		// in patches/enhgui.asm

	// install timer handler for flashing left/right buttons when pressed
	mov eax,[ophandler+0x28]
	mov eax,[eax+4]
	mov edi,[eax+3]
	mov esi,addr(stationwindoweventhandler)
	xchg esi,[edi]
	storerelative stationwindoweventhandler.oldhandler,esi

	mov esi,addr(createstationwindow)
	xchg esi,[edi+4]
	storerelative createstationwindow.old,esi

	stringaddress findwindowrailstationselhandleronoff,1,1	// we need to adjust some bytes

	call adjuststationwindow

	stringaddress findwindowrailstationbuttonstate,1,1	// fix clicked buttons

	add byte [edi-2Fh], 3	// length tool adjust

	push esi
	push edi
	add edi, 12
	storefragment newstationwindowactivehandler
	pop edi
	pop esi
	add byte [edi+37h], 5
//	mov eax, [edi-0xC]
//	mov [wcurrentstationsizeptr], eax

#if 0
	patchcode oldshowtrainstorient,newshowtrainstorient,1,1
	add edi,lastediadj+23
	storefragment newshowtrainstnumtr
#endif
	ret

global adjuststationwindow
adjuststationwindow:
	add byte [edi+2h], 3 + 2
	add byte [edi+7h], 3 + 2
	add byte [edi+11h], 3
	add byte [edi+1Ah], 3
	add byte [edi+23h], 3 + 2

	push edi
	sub edi, 1Bh
	storefunctioncall stationwindowclickhandler
	mov dword [edi+5], 0x90909090 //0xC3 // retn
	pop edi

// Tooltips
	push (5+7+7+2+2+4)*2
	call malloccrit
	pop eax

	mov dword [edi+44h], eax	// set the location of tooltips to alloc space
	//mov edi, dword [edi+44h]	// get the new tooltip start location
	xchg edi, eax
	mov dword [edi], 0x018C018B	// rebuild the tooltips before the track buttons
	mov word [edi+4], 0x0000f
	add edi,6

	mov eax, 0x304E
	stosw
	stosw

	inc eax
	mov ecx, 7
	rep stosw	// now create the tooltips for trackbuttons

	inc eax
	mov ecx, 7
	rep stosw	// lenght buttons

	mov ax, 0x3065
	stosw
	mov ax, 0x3064
	stosw

	xor ax, ax
	mov ecx, (2+4)
	rep stosw
	ret




begincodefragments

codefragment findwindowrailstationelements, -12
	db 0x0A,0x07,0x0B,0x00,0x93,0x00,0x00,0x00,0x0D,0x00,0x00,0x30

codefragment findwindowrailstationselhandleronoff
	cmp cl, 0Eh		// 80 F9 0E
      jz $+2+0x67		// 74 67
	cmp cl, 0Fh		// 80 F9 0F                               
	jz $+2+0x43		// 74 43

codefragment findwindowrailstationbuttonstate, 3
	shr bp, 0Fh		// 66 C1 ED 0F
	add bp, 3		// 66 83 C5 03

codefragment newstationwindowactivehandler
	call runindex(stationwindowactivehandler)
	setfragmentsize 33

endcodefragments
