#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc abandonedroads, patchabandonedroads


extern tunnelotherendfn


patchabandonedroads:
	//expiring road ownership
	patchcode oldvehleaveroadtile,newvehleaveroadtile,2,2
	patchcode oldperiodicroadproc,newperiodicroadproc,1,2
	patchcode oldbuildnewroad,newbuildnewroad,1,1
	patchcode oldbuildroadtorail,newbuildroadtorail,1,1
	patchcode oldbuildroadunderbridge,newbuildroadunderbridge,1,1
	patchcode oldbuildtunnel1,newbuildtunnel,1,1
	patchcode oldbuildtunnel2,newbuildtunnel,1,1
	storeaddress findtunnelotherend,1,1,tunnelotherendfn
	patchcode oldvehenterleaveclass9,newvehenterleaveclass9,1,1
	patchcode oldperiodicclass9proc,newperiodicclass9proc,1,1
	patchcode oldbuildbridgenorthhead,newbuildbridgenorthhead,1,2
	ret

begincodefragments

codefragment oldvehleaveroadtile,2
	mov dh,dl
	and dh,0xf0
	cmp dh,0x10
	db 0x75		// jnz ...

codefragment newvehleaveroadtile
	call runindex(vehleaveroadtile)

codefragment oldperiodicroadproc
	cmp byte [climate],2
	jnz $+2+0x3d

codefragment newperiodicroadproc
	call runindex(periodicroadproc)
	setfragmentsize 7

codefragment oldbuildnewroad
#if WINTTDX
	and byte [landscape4(si)],0xf
	or byte [landscape4(si)],0x20
	mov byte [landscape5(si)],0
#else
	db 0x67,0x64,0x80,0x24,0x0f	// same as above, but with different order of prefixes
	db 0x67,0x64,0x80,0x0c,0x20
	db 0x67,0x65,0xc6,0x04,0x00
#endif

codefragment newbuildnewroad
	call runindex(buildnewroad)
	setfragmentsize 10+4*WINTTDX

codefragment oldbuildroadtorail
	mov edi,[roadbuildcost]
	shl edi,1
	pop bx

codefragment newbuildroadtorail
	call runindex(buildroadtorail)

codefragment oldbuildroadunderbridge,2
	pop bx
	mov edi,[roadbuildcost]

codefragment newbuildroadunderbridge
	call runindex(buildroadunderbridge)

codefragment oldbuildtunnel1,5,2
	push dx
#if !WINTTDX
	movzx esi,si
#endif
	mov dl,[curplayer]

codefragment newbuildtunnel
	call runindex(buildtunnel)

codefragment oldbuildtunnel2,5,2
	push si
#if !WINTTDX
	movzx esi,si
#endif
	mov dl,[curplayer]

codefragment findtunnelotherend,-9
	push dx
	push bp
	rol di,4

codefragment oldvehenterleaveclass9
	or dl,dl
	jz $+2+1

codefragment newvehenterleaveclass9
	call runindex(vehenterleaveclass9)
	setfragmentsize 10+7*WINTTDX

reusecodefragment oldperiodicclass9proc,oldperiodicroadproc

codefragment newperiodicclass9proc
	call runindex(periodicclass9proc)
	setfragmentsize 7

codefragment oldbuildbridgenorthhead
#if WINTTDX
	mov [landscape5(si)],dl
#else
	db 0x67,0x65,0x88,0x14		// mov [gs:si],dl with different order of prefixes
	movzx esi,si
#endif
	mov dl,[curplayer]

codefragment newbuildbridgenorthhead
	call runindex(buildbridgenorthhead)
	setfragmentsize 7-WINTTDX


endcodefragments
