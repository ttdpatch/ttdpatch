#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <ptrvar.inc>

extern BusLorryStationDrawHandler,Class5ClearTileBusStopError
extern Class5CreateBusStationAction,Class5CreateLorryWinOrient
extern newbusorienttooltips,oldclass5createbusstation
extern oldclass5createlorrywinorient,paStationEntry1
extern paStationbusstop1,paStationbusstop2,rvmovementscheme
extern rvmovementschemestops,salorrystationguielements
extern ttdstationspritelayout

extern paStationtramstop1, paStationtramstop2

global patchbusstop

begincodefragments

codefragment findrvmovementscheme, 8
	and edx, 0x7F
	add dl, bl

codefragment oldcheckfield63busstop
	cmp byte [edi+veh.targetairport], 0
	jnz $+2+0x5A+WINTTDX*7

codefragment newcheckfield63busstop
	icall Class5VehEnterLeaveBusStop

codefragment oldclass5cleartilebusstop
	cmp dh, 0x47
	jb $+2+0x05
	cmp dh, 0x4B
	jb $+2+0x38

codefragment newclass5cleartilebusstop
	icall Class5ClearTileBusStop
	nop 
	nop
	db 0x72

codefragment findrvmovementschemestops, 21
	movzx ebx, byte [esi+veh.movementstat]
	sub bl, 0x20

codefragment findwindowlorrystationelements, 26
	mov cx, 0x9A
	mov ebx, 0xB1008C

codefragment findwindowbusstationelements, -12
	db 0x0A,0x07,0x0B,0x00,0x8B,0x00,0x00,0x00,0x0D,0x00,0x42,0x30

codefragment findwindowbusstationcreatesize, 5
	mov cx, 0x99
	mov ebx, 0xB1008C

codefragment oldbuslorrystationwindowclickhandler, -6
	cmp cl, 7
	je $+2+0x5D
	cmp cl, 8

codefragment newbuslorrystationwindowclickhandler
	icall BusLorryStationWindowClickHandler

codefragment findwindowbusstationtooltipdisp, 22
	js $+6+0x274
	movzx ebx, cx
	
codefragment oldclass5queryhandlerbusstop
	mov ax, 0x3062
	cmp cl, 0x4B

codefragment newclass5queryhandlerbusstop
	icall Class5QueryHandlerBusStop
	nop

codefragment oldclass5cleartilebusstoperror, 2
	jb $+2+0x05
	cmp dh, 0x4B
	jb $+2+0x4B

codefragment_call newclass5cleartilebusstoperror,Class5ClearTileBusStopError,5

codefragment oldbuslorrystationwindowdrawhandler, -5
	add dx, 34h
	inc bl
	xor al, al

codefragment_call newbuslorrystationwindowdrawhandler,BusLorryStationDrawHandler,5

endcodefragments

patchbusstop:
	storeaddresspointer findrvmovementscheme,1,1,rvmovementscheme
	patchcode oldcheckfield63busstop, newcheckfield63busstop,1,1
	patchcode oldclass5cleartilebusstop, newclass5cleartilebusstop,1,1

	mov eax, [ophandler+0x5*8]			
	mov eax, [eax+0x10]
	mov edi, [eax+9]
	mov eax, [edi+5*4]
	mov dword [oldclass5createbusstation], eax
	mov dword [edi+5*4], addr(Class5CreateBusStationAction)

	mov edi, [rvmovementscheme]
	mov eax, [edi]
	mov [edi+4*0x24], eax
	mov eax, [edi+4]
	mov [edi+4*0x25], eax
	
	mov eax, [edi+4*8]
	mov [edi+4*0x2C], eax
	mov eax, [edi+4*9]
	mov [edi+4*0x2D], eax
	
	mov eax, [edi+4*16]
	mov [edi+4*(0x24+16)], eax
	mov eax, [edi+4*(1+16)]
	mov [edi+4*(0x25+16)], eax
	
	mov eax, [edi+4*(8+16)]
	mov [edi+4*(0x2C+16)], eax
	mov eax, [edi+4*(9+16)]
	mov [edi+4*(0x2D+16)], eax

	stringaddress findrvmovementschemestops,1,1
	
	pusha
	mov esi, dword [edi]
	mov edi, rvmovementschemestops
	mov ecx, 7
	rep movsd
	popa
	mov esi, rvmovementschemestops
	mov dword [edi], esi
	mov dword [esi+0x4], 0x05050505
	mov dword [esi+0xC], 0x05050505
	mov dword [esi+0x4+16], 0x05050505
	mov dword [esi+0xC+16], 0x05050505

	pusha
	mov esi, [ttdstationspritelayout]
	mov esi, [esi]
	mov edi, paStationEntry1
	mov ecx, 7
	rep movsd
	popa

	mov edi, [ttdstationspritelayout]
	mov dword [edi], paStationEntry1

	add edi, 0x53*4
	mov dword [edi], paStationbusstop1
	mov dword [edi+4], paStationbusstop2
	mov dword [edi+8], paStationtramstop1
	mov dword [edi+12], paStationtramstop2

	// rewrite the window system
	stringaddress findwindowlorrystationelements,1,1
	pusha
	mov esi, dword [edi]
	mov edi, salorrystationguielements
	mov ecx, 27
	rep movsd
	movsb
	popa
	mov dword [edi], salorrystationguielements

	stringaddress findwindowbusstationelements,1,1
	add edi, 12
	mov word [edi+4], 0xCF
	add edi, 12
	mov word [edi+4], 0xCF
	add edi, 12*7

	mov word [edi], 0x0E01
	mov dword [edi+2], 0x00CC008B // reversed x1 & x2
	mov dword [edi+6], 0x00420011 // reversed y1 & y2
	mov word [edi+10], 0
	add edi, 12
	mov word [edi], 0x0E01
	mov dword [edi+2], 0x00CC008B // reversed x1 & x2
	mov dword [edi+6], 0x00760045 // reversed y1 & y2
	mov word [edi+10], 0
	add edi, 12
	mov byte [edi], cWinElemLast

	stringaddress findwindowbusstationcreatesize,1,1
	mov dword [edi], 0x00B100D0
	patchcode oldbuslorrystationwindowclickhandler, newbuslorrystationwindowclickhandler,1,1
	
	stringaddress findwindowbusstationtooltipdisp,1,1
	mov dword [edi], newbusorienttooltips

	mov eax, [ophandler+0x5*8]			
	mov eax, [eax+0x4]
	mov edi, [eax+3]
	mov eax, [edi+7*4]
	mov dword [oldclass5createlorrywinorient], eax
	mov dword [edi+7*4], addr(Class5CreateLorryWinOrient)

	// Some Error Handler...
	patchcode oldclass5queryhandlerbusstop, newclass5queryhandlerbusstop,1,1
	patchcode class5cleartilebusstoperror
	patchcode buslorrystationwindowdrawhandler
	ret
