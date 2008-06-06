#include <frag_mac.inc>
#include <window.inc>

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
	mov ebp,normaltrainwindowptr
	storeaddress trainwindowdata,1,1,ebp
// Different versions have different code sizes and different vehicle window widths. Deal with this.
	movzx ebx, word [edi+12*5+windowbox.x2]
	inc ebx
	test bh,bh
	jz .useimm8				// In some versions I need to overwrite add cx, imm8
	mov edi, .patchsettextofst		// In others, it's add cx, imm16
	dec byte [edi]
	inc byte [edi+2]
.useimm8:
	stringaddress findtrainwindowelemliststore
	extern newTrainWindow_elements
	mov esi,newTrainWindow_elements
	mov [edi],esi
	mov [ebp],esi
	call .resizewindowelems

	//	RVs
	stringaddress findrvwindowptr
	mov esi,newRVWindow_elements
	mov [edi],esi
	call .resizewindowelems

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

		// param_call dopatchcode, findstartstopbar_start, %%addr2, 3, ecx, ecx, %1_add, %2_len
		// With variable values for %%addr2, %1_add, and %2_len
		push findstartstopbar_start
		test cl,1
		jnz .callsetflag
		push settextloc+(0xE8<<24)
		push 3
		push ecx
		push ecx
		push byte findstartstopbar_add
		push 8
noglobal ovar .patchsettextofst,-3
		jmp short .docall
	.callsetflag:
		push setflagloc+(0xE8<<24)
		push 3
		push ecx
		push ecx
		push byte findstartstopbar_add
		push 8
	.docall:
		call dopatchcode

		donesearchfragment
	// }	

	pop ecx
	loop .patchloop
	ret

// In:	bx: Width
//	esi->Window elements
.resizewindowelems:
	pusha
	mov edi, esi
	mov dh, cWinDataSizer
	extcall FindWindowData.gotelemlist

	lea eax,[bx-0FAh]
	xor ebx,ebx
	mov edi,[edi+windatabox_sizerextra.eleminfo]
	extcall ResizeWindowElementsDelta
	popa
	ret
