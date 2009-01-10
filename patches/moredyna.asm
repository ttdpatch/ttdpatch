
// Better dynamite:
// - remove all city roads
// TODO: - remove HQ
// TODO: - remove other things

#include <std.inc>
#include <flags.inc>
#include <human.inc>
#include <town.inc>

extern actionhandler,ishumanplayer,patchflags,demolishroadflag





	// called after the check how many connections a city-owned road has
	//
	// in:	dl=number of connections
	//	di=position
	// out: zf=removable, nz=not removable
	// safe:eax,ebx,ecx,edx
	// note:on stack before call: saved ecx,ebx,eax
	//	saved ebx bit 0: set if doing it
global roadremovable
roadremovable:
	cmp dl,1
	jbe short .setzero	// no other checks necessary

	cmp byte [demolishroadflag],0
	jz short .nomodify	// it's not the dynamite tool

	// too many connections, so adjust the city rating if human player
	push byte PL_RETURNCURRENT
	call ishumanplayer	// returns ecx=current player number
	jne short .nomodify	// not human player

	// is a human player
	mov bl,[dword -1]	// the address will be stored here
ovar .getroadowner,-4,$,roadremovable

	and ebx,byte 0x7f
	imul ebx,byte town_size
	add ebx,townarray

	cmp word [ebx+town.ratings+ecx*2],byte 0
	jl short .nomodify	// can only destroy road if "Mediocre" rating

	test byte [esp+8],1	// do it?
	jz short .notreallydestroyingyet

	sub word [ebx+town.ratings+ecx*2],4*0x23	// adjust rating by about four trees
	bts dword [ebx+town.companiesrated],ecx	// and mark this company as rated

.notreallydestroyingyet:

	// mark it as destroyable, if the rating is at least "Excellent"
	mov dl,1

.nomodify:     	// now just set the flags correctly
	cmp dl,1
	jbe short .setzero
	or ah,ah		// the original test, overwritten
	ret

.setzero:
	xor ah,ah
	ret

; endp roadremovable 


exported DemolishRoad		// This is now a patchaction, so demolishroadflag gets set on the correct side of DoAction.
	or byte [demolishroadflag],1
	mov esi,0x10010
	call dword [actionhandler]		// nested call to DoAction
	and byte [demolishroadflag],0
	ret


	// called to check if the player can remove a bridge
	// (scenario editor mode already checked)
	//
	// in:	EDI=location of the first square of the bridge
	//	BL:0=1 if destroying, 0 if checking cost
	//	DH=current player
	// out:	ZF=1 if can remove, 0 otherwise
	// safe:EDX,ESI
global bridgeremovable
bridgeremovable:
	mov dl,[edi+landscape1]		// get the owner byte
	cmp dl,0x10			// no owner?
	jz short .done			// ... then everybody can remove it

	cmp dh,dl			// (the runindex call replaces cmp dh,[edi+landscape1])
	jz short .done			// that's our bridge

	testflags morethingsremovable	// leaves ZF undefined... we have to do it a more complicated way
	cmc
	sbb esi,esi			// now ESI is nonzero if the flag is not set
	jnz short .done

	sub dl,0x80
	jb short .done			// not a city-owned bridge

	mov word [operrormsg2],0x2009	// "... local authority refuses to allow this"
	cmp dh,7			// safety check
	ja short .done

	movzx esi,dl
	imul esi,byte town_size
	add esi,townarray			// now esi->town
	movzx edx,dh
	cmp word [esi+town.ratings+edx*2],601	// allowed only if excellent
	jl short .done

	// OK, so we can remove the bridge, although at a penalty

	test bl,1			// do it?
	jz short .done

	sub word [esi+town.ratings+edx*2],8*0x23	// adjust rating by about eight trees
	bts dword [esi+town.companiesrated],edx	// and mark this company as rated
	xor edx,edx			// done, set the zero flag

.done:
	ret
; endp bridgeremovable 


	// called to check if the player can remove a tunnel
	// (scenario editor mode already checked)
	//
	// in:	ESI=location of a tunnel's entrance/exit
	//	BL=owner (=landscape1[ESI])
	//	AX,CX,DL,DH,DI as returned by gettileinfo
	// out:	ZF=1 if can remove (is the right player), 0 otherwise
	// safe:EBX,ESI,EBP
global tunnelremovable
tunnelremovable:
					// is it our tunnel?
	cmp bl,[curplayer]		// (the runindex call overwrites this check)
	jz short .done

	cmp bl,0x10			// no owner?

.done:
	ret
; endp tunnelremovable
