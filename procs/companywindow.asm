#include <defs.inc>
#include <frag_mac.inc>


extern comp_aiview,comp_humanbuild,comp_humanview,manageaiwindow
extern playerwndbase,patchflags,otherCompanyManageWindowElemList.hqmanagebutton

#include <textdef.inc>

global patchcompanywindow

begincodefragments

codefragment oldredrawplayerwindow,-7
	jnz $+2+0x11
	db 0x66,0x83,0xbb		// cmp [ebx.hqlocation],-1

codefragment newredrawplayerwindow
	call runindex(redrawplayerwindow)
	nop


endcodefragments

patchcompanywindow:
	stringaddress oldredrawplayerwindow,1,1

	// store window struct base address
	push edi
	mov esi,[edi+3]
	mov edi,manageaiwindow
	mov [comp_humanbuild],esi
	add esi,byte 0x61
	mov [playerwndbase],esi
	mov [comp_humanview],esi

	// copy AI and human window structs
	add esi,byte 0x61
	mov [comp_aiview],esi
	mov cl,0x79
	rep movsb

	// and change "view HQ" buttons to "Manage"
	testmultiflags subsidiaries
	jz .nomanage
	mov word [edi-0x1b],ourtext(manage)
	mov word [otherCompanyManageWindowElemList.hqmanagebutton],ourtext(manage)
.nomanage:
	pop edi

	storefragment newredrawplayerwindow
	ret
