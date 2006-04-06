#include <defs.inc>
#include <frag_mac.inc>
#include <ptrvar.inc>

extern dailyvehproc,dailyvehproc.oldships,drawsplittextfn
extern patchnewtrains.expandnewvehwindow,vehtickproc
extern vehtickproc.oldships

ext_frag oldshipplanestartsound,newvehstartsound,newbreakdownsound

global patchnewships

begincodefragments

codefragment oldshiptopspeed
	mov ax,[esi+veh.speed]
	inc ax
	db 0x66	// mov bx,[esi+veh.maxspeed]

codefragment newshiptopspeed
	call runindex(shiptopspeed)
	setfragmentsize 10

codefragment drawnewshipnamexy,3
	add cx,byte 75
	db 0x66,0x83	// add dx,byte...

codefragment drawshipdetails2xy,3
	add cx,byte 71
	push cx

//codefragment findnewshipswindow,-20
//	db 0x0D,0x00,0x08,0x98,0x07,0x0E

codefragment createnewshipswindowsize,-4
	mov dx,0x90
	db 0xbd,6	// mov ebp,6

codefragment oldshowshipinfo
	mov bx,0x980a

glob_frag newshowvehinfo
codefragment newshowvehinfo
	icall showvehinfo
	call [drawsplittextfn]
	setfragmentsize 14

glob_frag oldtrainshipbreakdownsound
codefragment oldtrainshipbreakdownsound,-11
	mov eax,14


endcodefragments

patchnewships:
	patchcode oldshiptopspeed,newshiptopspeed

	// increase width of the new ships window to accomodate for larger sprites
	xor ebx,ebx
	mov bl,20		// X size increase

	stringaddress drawnewshipnamexy
	add [edi],bl
	stringaddress drawshipdetails2xy
	add [edi],bl
	mov cl,2		// ECX=0 after the stringaddress above
.crnswsizeloop:
	push ecx
	stringaddress createnewshipswindowsize,ecx,2
	add [edi],ebx
	add word [edi+2],50
	pop ecx
	loop .crnswsizeloop
	call patchnewtrains.expandnewvehwindow

	// also make the info box longer by five lines
	mov ebx,(50 << 16)+50
	add [edi+56],bx
	add [edi+66],ebx
	add [edi+78],ebx

	mov esi,vehtickproc
	mov eax,[ophandler+0x12*8]	// ship vehicle class
	xchg esi,[eax+0x14]		// vehtickproc
	mov [vehtickproc.oldships],esi

	mov esi,dailyvehproc
	xchg esi,[eax+0x1c]		// dailyvehproc
	mov [dailyvehproc.oldships],esi

	patchcode oldshowshipinfo,newshowvehinfo

	patchcode oldtrainshipbreakdownsound,newbreakdownsound,2,2
	patchcode oldshipplanestartsound,newvehstartsound,2+WINTTDX,3
	ret
