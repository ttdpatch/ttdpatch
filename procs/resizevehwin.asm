#include <frag_mac.inc>

extern normaltrainwindowptr, findwindowstructuse.ptr
extern newRVWindow_elements,newShipWindow_elements,newAircraftWindow_elements,rvwindowsize

begincodefragments

ext_frag findtrainwindowelemliststore, findwindowstructuse, trainwindowdata

codefragment findstartstopbar,-5
	add edx, byte 123
noglobal ovar dxadd, -1

ext_frag findrvwindowptr

codefragment findshipelemlist,-22
	dw 0980Fh
	db 1

codefragment findaircraftelemlist,-22
	dw 0A00Ah
	db 1

endcodefragments

exported patchresizevehwins
	// Patch window elements:
	//	Trains
	mov ebx,normaltrainwindowptr
	storeaddress trainwindowdata,1,1,ebx
	stringaddress findtrainwindowelemliststore
	extern newTrainWindow_elements
	mov eax,newTrainWindow_elements
	mov [edi],eax
	mov [ebx],eax

	//	RVs
	stringaddress findrvwindowptr
	mov esi,newRVWindow_elements
	mov [edi],esi

	//	Aircraft
	mov edi, newAircraftWindow_elements
	mov ecx, rvwindowsize
	push ecx
	push edi
	rep movsb
	storeaddress findaircraftelemlist,findwindowstructuse.ptr
	stringaddress findwindowstructuse
	pop esi
	mov [edi+3], esi
	inc word [esi+0x52]	//depot
	mov word [esi+0x5e],692	//refit

	//	Ships
	mov edi, newShipWindow_elements
	pop ecx
	push edi
	rep movsb
	storeaddress findshipelemlist,findwindowstructuse.ptr
	stringaddress findwindowstructuse
	pop esi
	mov [edi+3], esi
	inc word [esi+0x52]	//depot


	// patch drawing the start/stop bar
	xor ecx,ecx
	mov cl,2		// For trains
	call .patchloop
	mov byte [dxadd],105
	mov cl,6		// For all others

.patchloop:
	extern setflagloc,settextloc
	push ecx
	// patch findstartstopbar with calls to, alternately, setflagloc and settextloc
	// { patchcode findstartstopbar,%2,ecx,ecx
		usesearchfragment findstartstopbar

		push findstartstopbar_start
		test cl,1
		jnz .callsetflag
		push settextloc+(0xE8<<24)
		jmp short .docall
	.callsetflag:
		push setflagloc+(0xE8<<24)
	.docall:
		param_call dopatchcode, /*%1_start, %%addr2,*/ 3, ecx, ecx, 0+findstartstopbar_add, 8

		donesearchfragment
	// }	

	pop ecx
	loop .patchloop
	ret
