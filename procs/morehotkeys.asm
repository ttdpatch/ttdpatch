#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc morehotkeys, patchmorehotkeys

begincodefragments

codefragment oldhotkeycenter
	cmp al, 63h
	jnz $+2+4		//00558AAD   75 04    JNZ SHORT TTDLOADW.00558AB3
	xor al,al
	db 0xEB		//jmp 

codefragment newhotkeycenter
	call runindex(hotkeyfunction)
	db 0x74	 //jz

codefragment oldrailtoolselect
	sub al,'1'
	cmp al,4
maxtoolnum equ $-1

codefragment newrailtoolselect
	nop
	mov ah,0
	call runindex(toolselect)
	setfragmentsize 9

reusecodefragment oldrvtoolselect,oldrailtoolselect,-4

codefragment newrvtoolselect
	push ax
	icall rvtoolselect
	jne fragmentstart+0x18c-0x178
	setfragmentsize 13

codefragment oldothertoolsets,-3
	jnz $+2+0xD
	mov ebx,0

codefragment newothertoolsets
	nop
	icall othertoolselect
	jnz $+2+9
	setfragmentsize 10

codefragment WindowElemList,-14
	dw 11,283
ovar WinTitleWidth, $, -2


codefragment findLandscapeGenWindowHandler
	cmp cl,6
	jz near $+6+0x2d2

codefragment findVehOrdersWindowHandler
	jmp $+5+31Dh


codefragment oldcheckNewWindow, 2Dh
	jne short $+2+4Eh
	db 0xC6		// mov m8, imm8 ([vaTemplocation1], cWinTypeVehicle)

codefragment_call newcheckNewWindow, StoreOrderWindow.new, 6

endcodefragments

uvard LandscapeGenWindowHandler
uvard VehOrdersWindowHandler

varw WinTitleWidths
//	dw 283	// RoadConstr (Already stored)
	dw 153	// DockConstr
	dw 129	// AirportConstr
//	dw 142	// PlantTrees
	dw 0
endvar

patchmorehotkeys:
	patchcode oldhotkeycenter,newhotkeycenter,1,1

	mov byte [edi+lastediadj+19],0
	mov byte [edi+lastediadj+23],0
	//mov byte [edi+lastediadj+52],0x90  now patched by othertoolsets

	patchcode railtoolselect
	patchcode othertoolsets
	mov ebx,maxtoolnum
	mov byte [ebx],2	// 2 tools selectable for road vehicles
	patchcode rvtoolselect

	extern saWindowElemLists
	mov ebx, saWindowElemLists
	mov esi, WinTitleWidths

.findWins:
	push esi
	//find the various window element lists
	stringaddress WindowElemList
	pop esi
	mov [ebx],edi
	add ebx, 4
	lodsw
	test ax, ax
	mov [WinTitleWidth], ax
	jnz .findWins

.findHandlers:
	storeaddress LandscapeGenWindowHandler
	storeaddress VehOrdersWindowHandler

	multipatchcode checkNewWindow, 4

#if !WINTTDX
	// remove ASCII code from cursor keys (they aren't supposed to generate letters)
	mov esi,shiftedkeyasciitable+72
	mov al,0xff
	mov byte [esi],al
	mov byte [esi+3],al
	mov byte [esi+5],al
	mov byte [esi+8],al
	sub esi,byte shiftedkeyasciitable-regkeyasciitable
	mov byte [esi],al
	mov byte [esi+3],al
	mov byte [esi+5],al
	mov byte [esi+8],al
#endif
	ret

