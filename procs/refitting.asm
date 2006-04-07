#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>

extern findwindowstructuse.ptr,malloccrit,refitwindowstruc

#include <textdef.inc>

ext_frag findwindowstructuse

global patchrefitting

begincodefragments

codefragment oldinitrefit,-7
	mov bx,[esi+0x22]

codefragment newinitrefit
	call runindex(drawrefitwindow)
	jmp newinitrefit_start+82

codefragment oldchooserefit,2
	div bl,0	// ,0 to disable div-by-zero handling code
	xor ah,ah
	mov [esi+window.selecteditem],ax

codefragment newchooserefit
	call runindex(chooserefit)

codefragment oldrefitcheck,-2
	mov bl,0
	mov al,[ebp+veh.owner]

codefragment newrefitcheck
	icall refitcheck
	nop

codefragment oldrefitdoact
	mov bl,1
	mov ax,[ebp+veh.xpos]

codefragment newrefitdoact
	icall refitdoact

codefragment oldrvshiprefitcost
	mov ebx,[shipbasevalue]

codefragment newrvshiprefitcost
	call runindex(rvshiprefitcost)
	ret

codefragment oldisplanerefittable
	mov edx,0x80
	db 0x66

codefragment newisplanerefittable
	call runindex(isplanerefittable)
	jc $+2+38
	setfragmentsize 9

codefragment oldupdatevehwnd,6
	mov edi,[tempvar+8]
	mov al,14

codefragment newupdatevehwnd
	icall updatevehwnd

codefragment findaircraftrefitbuttontext,-58
	dw 0xa03d	// text ID
	db 11
	dw 0x18b	// text ID

codefragment newopenrefitwindow
	call runindex(openrefitwindow)
	setfragmentsize 7

codefragment findshiprefitbuttontext,-58
	dw 0x983c	// text ID
	db 11
	dw 0x18b	// text ID

codefragment olddisplaycurplanerefitcargo,-2
	mov bx,0xa041

codefragment oldgetrvshiprefitcap,4
	mov ax,[ebp+veh.capacity]
	mov [textrefstack+2],ax

codefragment newgetrvshiprefitcap
	call runindex(getrvshiprefitcap)

codefragment oldsetnewcargo,3
	xchg bh,[edx+veh.cargotype]

codefragment newsetnewcargo
	call runindex(setnewcargo)


endcodefragments

patchrefitting:
	multipatchcode oldinitrefit,newinitrefit,2
	multipatchcode oldchooserefit,newchooserefit,2
	multipatchcode refitcheck,2
	multipatchcode refitdoact,2
	patchcode oldrvshiprefitcost,newrvshiprefitcost
	patchcode oldisplanerefittable,newisplanerefittable
	patchcode updatevehwnd
	add edi,lastediadj+21
	storefragment newupdatevehwnd

	stringaddress findaircraftrefitbuttontext,1,1

	// adjust window size to allow 12 cargos in list...
	mov ebx,(10<<16)+10
	add [edi+0x20],bx
	add [edi+0x2a],ebx
	add [edi+0x36],ebx

	// change the button text and tooltips
	mov word [edi+58],ourtext(refitvehicle)
	mov word [edi+61+2*2],ourtext(refitcargohint)
	mov word [edi+61+4*2],ourtext(refitbuttonhint)

	// now make copy of window to add slider (it's easier to do this after modifying it)
	push 73
	call malloccrit
	pop esi

	mov [refitwindowstruc],esi
	mov [findwindowstructuse.ptr],edi

	xchg esi,edi
	mov cl,60
	rep movsb	// copy all 5 elements
			// add slider
	mov ax,cWinElemSlider + (cColorSchemeGrey<<8)
	stosw
	mov eax,[esi-36+4]
	sub eax,11
	mov [edi-36-2+4],eax	// resize text box to allow slider
	inc eax
	stosw
	add ax,10
	stosw
	mov eax,[esi-36+6]
	stosd
	xor eax,eax
	stosw
	movsb		// and terminator

	// change the reference to the old window to the new one
	patchcode findwindowstructuse,newopenrefitwindow
	add [edi+lastediadj-16],bx

	stringaddress findshiprefitbuttontext,1,1
	mov [findwindowstructuse.ptr],edi
	patchcode findwindowstructuse,newopenrefitwindow
	add [edi+lastediadj-16],bx

	stringaddress olddisplaycurplanerefitcargo,1,1
	add [edi],bx

	patchcode oldgetrvshiprefitcap,newgetrvshiprefitcap,1,1
	add [edi+lastediadj+22],bx

	multipatchcode oldsetnewcargo,newsetnewcargo,2
	ret
