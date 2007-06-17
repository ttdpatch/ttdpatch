#include <defs.inc>
#include <frag_mac.inc>


extern wantedtracktypeofs

ext_frag oldchecktracktype

global patchmanuconv

begincodefragments

glob_frag oldtrackbuildcheckvehs
codefragment oldtrackbuildcheckvehs,-6
	mov word [operrormsg2],0x1007
	push bx

codefragment newtrackbuildcheckvehs
	call runindex(trackbuildcheckvehs)

codefragment oldbuildtrackoncrossing
	test dh,0x08
	jnz $+2+14
	cmp bh,2

codefragment newbuildtrackoncrossing
	call runindex(buildtrackoncrossing)
	jmp fragmentstart+22

codefragment oldbuildtrackunderbridge,-6
	test dh,1
	jnz $+2+14
	cmp bh,2

codefragment newbuildtrackunderbridge
	call runindex(buildtrackunderbridge)
	jmp fragmentstart+28

codefragment oldbuildtrackonbridgeortunnel
	mov dl,dh
	and dl,0xf8
	cmp dl,0xc0

codefragment newbuildtrackonbridgeortunnel
	call runindex(buildtrackonbridgeortunnel)
	setfragmentsize 8

codefragment newchecktracktype
	call runindex(checktracktype)
	jmp fragmentstart+21

//codefragment oldfinaltrackcost
//	add edi,[trackcost]
//
//codefragment newfinaltrackcost
//	call runindex(finaltrackcost)


endcodefragments

patchmanuconv:
	stringaddress oldtrackbuildcheckvehs,1,1
	storefragment newtrackbuildcheckvehs
	patchcode oldbuildtrackoncrossing,newbuildtrackoncrossing,1,1
	patchcode oldbuildtrackunderbridge,newbuildtrackunderbridge,1,1
	patchcode oldbuildtrackonbridgeortunnel,newbuildtrackonbridgeortunnel,1,1
	ret

exported patchtracktype
	stringaddress oldchecktracktype,1,1
	mov ebx,[edi+lastediadj+16]
	mov [wantedtracktypeofs],ebx
extern patchflags
	testflags manualconvert
	jnc .ret
	storefragment newchecktracktype
.ret:
	ret


	// allocate the extra town array if needed; patch in common town data code
