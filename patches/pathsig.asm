// Path-based signalling

#include <std.inc>
#include <human.inc>
#include <station.inc>
#include <veh.inc>
#include <bitvars.inc>
#include <signals.inc>
#include <ptrvar.inc>
#include <flags.inc>

extern addrailgroundsprite,curstationtile,getplatforminfo,getroutemap
extern invalidatetile,ishumanplayer,pbssettings
extern randomstationtrigger, patchflags

uvard traceroutefn		// [TTD] do route tracing
uvard chkrailroutetargetfn	// [TTD] check if a route has arrived at the target
uvard prepareforrailroutecheck	// [TTD] store the current target location(s)
uvard trainchoosedirection	// [TTD] decide track piece to move onto
uvard gettileconnection		// [TTD] get track pieces on tile

uvard raildirbitsptr		// Pointer to array of track pieces for a certain direction
uvard findrailroutearg		// Pointer to where TTD keeps current rail route data
uvard railroutestepfnarg	// Pointer to step function argument of the traceroute call

uvarb curtracesigbit		// Signal bit (in L2/L3) of signal we're tracing through
uvarb curtracesigstate		// 0:signal green, 1:signal red
uvard curtracestartxy		// XY of start of trace route
uvard curtracestartdir		// starting direction of trace route
uvarb curtracestartpiece	// starting track piece
uvarb onlycheckpath		// don't mark path, just check if we can get one

uvarb currouteallowredtwoway	// 0: don't route through red two-ways or wrong-way one-ways
				// 2: try route anyway

uvarb ignorereservedpieces	// set if trace route should ignore reserved pieces
uvard lastsigdistance		// route distance at which we saw the first signal
uvard wantstationpbstrigger	// set if reserving signal tile should trigger random bits


	// pieces that rotate clockwise as function of direction of origin
varb tilebitsclockwise, 0, 0x20, 0, 8, 0, 0x10, 0, 4

varb tiledeltas, 0,-1,-1,0,1,1,0,0,-1

	// which bit stores the signal state as function of source direction and piece
varb sigbitfromsdirpiece
	db 80h,20h,80h,0	// dir 1 (NE), pieces 01,08,10
	db 80h,80h,40h,0	// dir 3 (SE), pieces 02,04,10
	db 40h,40h,10h,0	// dir 5 (SW), pieces 01,04,20
	db 40h,10h,20h,0	// dir 7 (NW), pieces 02,08,20
endvar

	// same but using destination direction
varb sigbitfromddirpiece
	db 80h,80h,20h,0	// dir 1 (NE), pieces 01,04,20
	db 80h,20h,10h,0	// dir 3 (SE), pieces 02,08,20
	db 40h,10h,40h,0	// dir 5 (SW), pieces 01,08,10
	db 40h,40h,80h,0	// dir 7 (NW), pieces 02,04,10
endvar

	// both signals, independent of direction
varb sigbitsonpiece
	db 0xc0,0xc0,0xc0,0x30,0xc0,0x30
endvar


	// final route information
struc finalrt
	.length:	resb 1	// how many tiles long is this route
	.type:		resb 1	// 1: didn't find target, closest approach; 2: shortest route to target
	.norecord:	resb 1	// 1: don't record route
	.pieces:		// track piece bit masks of this route
endstruc

#define MAXDEPTH 64	// maximum depth of recursion in TTD's trace route algo

%define numfinaltracert MAXDEPTH+8+finalrt_size
%define numfinalroutes 1

uvard curtracertdist			// currently traced route length
uvard curtracert,numfinaltracert/4+1	// currently traced route
uvard alttracertdist			// alternative route length
uvard alttracert,numfinaltracert/4+1	// alternative route
#if 0
uvard sigtracertdist			// first-signal route length
uvard sigtracert,numfinaltracert/4+1	// first-signal route
#endif

// the alternative route is any route that is MAXDEPTH-4 tiles long, used if
// the train can't find a route to its destination, nor any useful route at all
//
// the first-signal route is the first route that goes past any signal
// as a last resort

uvard finaltracert,((numfinaltracert+finalrt_size)*numfinalroutes+8)/4,s


// How it works:
//
// When a train approaches a signal, it calls the pathfinding function.
// If it finds a clear path to the end of the signal block, it
// marks the path to the end of the signal block as in use.  When the last
// wagon leaves a tile, it's marked as unused again.  Inside the signal
// block, it never leaves the pre-defined path.
//
// When a train approaches a red signal, it calls the pathfinding function
// too, and if it finds a path to its destination that does not use tiles
// already in use, it marks this path and proceeds past the red signal.
//
// Landscape arrays:
// For plain track, the reserved pieces are stored in L6 using the same bits as L5.
// For signals, L6 has bits set for the red signal bits from L3, and bit 3
//	to indicate that this block is using PBS
// For road crossings, the "closed" state is used to indicate it is reserved
// For stations tiles, L3 bit 7 is used to mark it reserved
// For tunnels and bridge heads, same as for plain track
//
// Signals work a bit differently than the rest.  Reserved signal bits mean
// that the train has a reserved path *through* the signal (except for tiles
// that have two pieces, then this only applies to the piece(s) which actually
// have signals).
//
// Some complications:
// - if the train doesn't find a path, it tries again ignoring reserved pieces
//   if that gives a better path, it waits for those pieces to clear
// - if that didn't give a better path, it waits at a red signal, or
//   proceeds using any path out of the block if the signal is green
// - if it can find no path at all that leads out of the block, it will
//   wait at the signal (whether green or red)


uvarb currouteresult
uvarw currouteclosest

	// called for every tracing step
	//
	// in:	ch=rail piece bit mask (one bit set)
	//	cl=rail piece bit number, +8 for "other" direction
	//	di=tile XY
	// out:	CF=1 if route ends
	// safe:eax ebx
chksignalpathtarget:
	cmp byte [finaltracert+finalrt.norecord],0
	jne .norecord

	movzx eax,word [tracertdistance]
	dec eax
	cmp eax,numfinaltracert-finalrt_size-1
	jae .norecord

	xchg eax,[curtracertdist]

	// tunnels leave holes in the path, fill those
.nexthole:
	inc eax
	cmp eax,[curtracertdist]
	ja .resume
	je .nohole

	mov byte [curtracert+eax],0
	jmp .nexthole

.resume:
	mov eax,[curtracertdist]
	mov byte [currouteresult],0	// when resuming from an earlier place,
					// must reset whether we've found the
					// target

.nohole:
	mov [curtracert+eax],ch

	cmp eax,MAXDEPTH-4
	jne .notalt

	// this should not be necessary now (won't get here if norecord is set)
	// but it doesn't hurt either...
	cmp byte [finaltracert+finalrt.norecord],0
	jne .notalt

	inc eax
	mov [alttracertdist],eax
	and eax,byte ~3

.nextalt:
	mov ebx,[curtracert+eax]
	mov [alttracert+eax],ebx
	sub eax,4
	jnc .nextalt

.notalt:
#if 0
	mov al,[landscape4(di)]
	and al,0xf0
	cmp al,0x10
	jne .notsignal
	test byte [landscape5(di)],0xc0
	jle .notsignal

	mov eax,[curtracertdist]
	inc eax
	mov [sigtracertdist],eax
	and eax,byte ~3

.nextsig:
	mov ebx,[curtracert+eax]
	mov [sigtracert+eax],ebx
	sub eax,4
	jnc .nextsig

.notsignal:
#endif

.norecord:
	mov al,[currouteallowredtwoway]
	or [tracertdistance+3],al

	and byte [currouteresult],~3	// reset whether we got close to the
					// target so we can tell if this tile
					// gets us closer
					// also it breaks the ignore-red-twoways
					// if we don't do this
	call [chkrailroutetargetfn]
	pushf

#if 0
	jnc .notrouteend

	// found end of a route
	// may be useful for reversing trains if they can't find anything better
	cmp byte [currouteallowredtwoway],2
	jne .notrouteend	// but only if actually reversing

	mov eax,[curtracertdist]
	cmp eax,[alttracertdist]
	jb .notrouteend

#if 0
	cmp byte [finaltracert+finalrt.norecord],0
	jne .notrouteend
#endif

	inc eax
	mov [alttracertdist],eax
	and eax,byte ~3

.nextend:
	mov ebx,[curtracert+eax]
	mov [alttracert+eax],ebx
	sub eax,4
	jnc .nextend

.notrouteend:
#endif
	cmp byte [currouteresult],0
	je .done

	// so route is one the train will take if no better route comes up
	// record it for now
	mov ebx,[findrailroutearg]
	movzx eax,byte [ebx+9]	// start track piece bit
	xor ebx,ebx
	bts ebx,eax
	mov ah,bl		// start track piece mask

	mov ebx,finaltracert

	mov al,[curtracertdist]
	inc al
	mov [ebx+finalrt.length],al
	mov al,[currouteresult]
	mov [ebx+finalrt.type],al

	cmp byte [ebx+finalrt.norecord],0
	jne .done

	mov [ebx+finalrt.pieces],ah	// first piece

	push ecx
	xor ecx,ecx
.copynext:
	mov eax,[curtracert+ecx]
	mov [ebx+finalrt.pieces+1+ecx],eax
	add ecx,4
	cmp cl,[curtracertdist]
	jbe .copynext
	pop ecx

.done:
	popf
	ret

	// called if current route doesn't end, but it's the closest to the target
global railroutechkcont
railroutechkcont:
	mov ebx,[findrailroutearg]	// 110B5A
	mov [ebx+6],ax			// 110B60
	mov [currouteclosest],ax
	test byte [ebx],1
	jz .done
	mov al,[tracertresult]
	mov [ebx],al
.done:
	mov byte [currouteresult],1
	clc
	ret

	// called if current route is so far the shortest route to the target
global railroutetargetshortest
railroutetargetshortest:
	mov byte [currouteresult],0x82

	// don't make the route longer after having found the first station tile
	cmp ax,[currouteclosest]
	ja railroutetargetnotshortest
	mov [currouteclosest],ax

	// also get here at the end of the railroutetargetcheck function in all other cases
global railroutetargetnotshortest
railroutetargetnotshortest:
//	stc
	clc	// don't end at first tile of a station, need whole track to next signal or end of line
	ret



// called when checking whether train will have to wait at a red signal
//
// in:	ax=red signal bits on next tile
//	dx=rail pieces on next tile
//	ebx=direction to next tile
//	edi=next tile XY
// out:	dx &= relevant bits
//	ZF if no matching rail pieces
// safe:ebp
global checksignal
checksignal:
	mov ebp,[raildirbitsptr]
	and dx,[ebx+ebp]
	jz .wrongpieces

	movzx ebp,byte [landscape4(di,1)]
	and ebp,byte ~0xf
	cmp ebp,0x10
	jne .goodpieces

	movzx ebp,byte [landscape5(di,1)]
	and ebp,byte ~0x3f
	cmp ebp,0x40
	jne .goodpieces

//	mov ebp,[landscape6ptr]
	test byte [landscape6+edi],8
	jnz .checkpath

.goodpieces:
	test esp,esp	// clear ZF

.wrongpieces:
	ret

	// approaching a signal
	// either dh or dl has one bit set for the piece with the signal
	// (exactly one bit is set, because only one signal can lead from here)
.checkpath:
	push edx
	or dl,dh

	// if we're currently on a station tile, see if we'll stop here
	movzx ebp,word [esi+veh.XY]
	mov dh,[landscape4(bp,1)]
	and dh,0xf0
	cmp dh,0x50
	jne .notstopping

	mov dh,[esi+veh.vehstatus]
	and byte [esi+veh.vehstatus],~(1<<4)
	pusha
	mov bx,[esi+veh.XY]
	mov ax,[esi+veh.xpos]
	mov cx,[esi+veh.ypos]
	mov edi,esi
	mov dl,0
	mov ebp,[ophandler+0x28]// stations
	call [ebp+0x28]		// vehenterleavetile
	popa
	xchg dh,[esi+veh.vehstatus]
	test dh,1<<4
	jnz .stopping

	// not stopping, but see if the order has been updated yet
	mov dh,[esi+veh.currorder]
	and dh,0x1f
	cmp dh,2
	jbe .notstopping

.stopping:
	pop edx
	jmp .goodpieces

.maybestopping:
	pop edx
	testflags tsignals
	jnc .goodpieces
	test BYTE [landscape6+edi], 4	//if bit present, allow pass through, set ZF
	jz .goodpieces
	mov ax, 0
	ret



.notstopping:
	bsf edx,edx
	shr edx,1
	mov dl,[sigbitfromsdirpiece+(ebx-1)*2+edx]	// now dl=signal bit in L3
	test [landscape3+edi*2],dl	// signal in right direction?
	jz .maybestopping

	mov [curtracesigbit],dl
	test [landscape2+edi],dl
	setz [curtracesigstate]
//	mov ebp,[landscape6ptr]
	test [landscape6+edi],dl
	pop edx
	jz .noclearpathyet

.havepath:
	// have determined we have a clear path already
	mov ax,0	// not xor ax,ax to keep ZF=0
	ret

	// ok, so we're approaching a red signal, and we may or may
	// not have a clear path beyond it
.noclearpathyet:
	// this block is usable for pre-tracing, so let's try to find a path
	pusha
	or dl,dh
	mov byte [wantstationpbstrigger],1
	call markrailroute
	mov byte [wantstationpbstrigger],0
	popa
	sbb al,al	// clear ZF, keep CF if CF was set
	mov ax,dx	// pretend signal is red if no path
	jc .nopath
	or al,1
	mov ax,0	// approach signal without slowing down
.nopath:
	ret


	// in:	 di=tile XY
	//	 dl=track piece to use
	//	ebp=old direction
	// out:	 di=next tile XY
	//	ebp=new direction
exported getnextdirandtile
	test dl,0x3c	// hor/ver direction?
	jz .keepdir	// no, go straight

	// rotate clockwise
	inc ebp
	inc ebp
	and ebp,7

	cmp dl,[tilebitsclockwise+ebp]
	je .keepdir

	// oops, should've been counterclockwise
	xor ebp,4

.keepdir:
	add di,[tiledeltas+ebp]
	ret


	// figure out and mark rail route
	//
	// in:	ebx=direction of signal
	//	 dl=tile piece with signal
	//	esi->vehicle
	//	di=signal tile XY
	//	[curtracesigbit] = L2 bitmask holding signal state
	//	[curtracesigstate] = 0:signal green, 1:signal red
	// out:	CF=1 can't find route at all
	//	CF=0 have found route, route marked as in use
	// uses:all
markrailroute:
	cmp word [esi+veh.target],byte -1
	je near .bad	// no target

	pusha
	mov dl,1	// set only one bit so that the prepare function returns without calling DoTraceRoute
	call [prepareforrailroutecheck]
	popa

	mov [curtracestartxy],edi
	mov [curtracestartdir],ebx
	mov [curtracestartpiece],dl

	mov ebp,ebx

	// ok, try to trace the route
	//
	// the following code needs:
	//
	// edi = start tile XY
	// ebp= direction of travel
	// dl = track pieces to choose from (only a single piece allowed here)

	mov ecx,finaltracert
	mov byte [ignorereservedpieces],1
	and dword [ecx],0
	call tracepath //pass veh pointer to tracepath

	cmp byte [currouteallowredtwoway],0	// trying the best to find *any* path?
	jne .trymark

	mov ah,[ecx+finalrt.type]
	test ah,ah
	jz .bad		// no route found at all

	// found a route
	// let's see if using all pieces would give a better route to the target
	// if so, we wait till we can use it

	mov al,[currouteclosest]
	push dword [ecx]
	push dword [curtracertdist]
	and dword [ecx],0
	mov byte [ecx+finalrt.norecord],1
	call tracepath //pass veh pointer to tracepath
	add byte [currouteclosest],5
	sub [currouteclosest],al	// new route at least 5 tiles shorter?
	sbb ah,[ecx+finalrt.type]	// new route has higher quality?
	pop dword [curtracertdist]
	pop dword [ecx]
	jb .bad		// new route is better or shorter, so wait for it to become clear

	// nope, also just getting as close, let's try it and hope for the best

.trymark:
	// mark path
	pusha
	mov ah,0
	call chkmarksignalroute
	popa
	jc .bad

	cmp byte [onlycheckpath],0
	jne .done

	pusha
	mov ah,1
	call chkmarksignalroute
	popa
	jc .undo

.done:
	clc
	ret

.undo:	// if we get here, something bad happened, e.g. a looping path
	// we need undo the partially-reserved route

	mov ah,0x80
	call chkmarksignalroute

.bad:
	stc
	ret

tracepath:
	pusha
	bsf ebx,edx

	mov edx,[railroutestepfnarg]
	mov dword [edx],addr(chksignalpathtarget)	// use our step function

	xor edx,edx

	dec edx
	mov [curtracertdist],edx
	mov [lastsigdistance],edx
	cmp byte [finaltracert+finalrt.norecord],0
	jne .norecord
	mov [alttracertdist],edx
//	mov [sigtracertdist],edx
.norecord:
	inc edx

	//JGR: pass veh ptr in esi to trainchoosedirection
	extern tr_pbs_sigblentertile
	mov [tr_pbs_sigblentertile], edi
	call [trainchoosedirection]		// then call the regular path finding
	mov byte [ignorereservedpieces],0
	mov DWORD [tr_pbs_sigblentertile], 0

	mov esi,[railroutestepfnarg]
	mov eax,[chkrailroutetargetfn]
	mov [esi],eax
	mov esi,finaltracert
	test byte [esi+finalrt.type],0x80
	jz .notfound
	mov byte [esi+finalrt.type],2
.notfound:
	popa
	ret

// macro to check whether bridge piece needs to be marked
// l5reg (a byte register) contains value from L5
// trkpiece is the piece to mark (may be byte reg or mem),
// if trkpiece not given, will not check whether track on or below bridge is meant
// if labels aren't given, will fallthrough in that case
%macro checkbridgepbs 1-5 	// params: l5reg,[trkpiece],[nomarklabel],[marklabel],[markheadlabel]
	%push bridgepbs
	%ifidn {%3},{}
		%define %$nomark %%out
	%else
		%define %$nomark %3
	%endif
	%ifidn {%4},{}
		%define %$mark %%out
	%else
		%define %$mark %4
	%endif
	%ifidn {%5},{}
		%define %$markhead %$mark
	%else
		%define %$markhead %5
	%endif

	test %1,%1		// bit 7 set: bridge, clear: tunnel
	jns %$nomark		// road tunnel

	test %1,01000000b	// bit 6 set for bridge: middle, clear: head
	jz %$markhead		// bridge head, must be rail and thus ok

	%ifnidn {%2},{}
	and %1,~2
	inc %1			// map bit 0 to track piece 1/2
	test %1,%2		// check direction
	jnz %$nomark		// same direction -> not under middle piece
	%endif

	and %1,00111000b	// bit 5 set, bit 4,3=0: rail under it
	cmp %1,00100000b	// bit 5 clear for middle piece: land under it
	%ifidn {%3},{}
	je %$mark		// is rail under bridge
	%else
	jne %$nomark		// not rail under bridge (either land, or road)
	%ifnidn {%4},{}
		jmp %$mark	// opposite direction -> track under it
	%endif
	%endif

%%out:
	%pop
%endmacro

uvarb didmarkroute

chkmarksignalroute:
	mov ebx,finaltracert
	xor ecx,ecx
	xor edx,edx

	test byte [pbssettings],PBS_ALLOWUNSAFEJUNCTION
	setnz [didmarkroute]

	mov edi,[curtracestartxy]
	mov ebp,[curtracestartdir]

	mov esi,landscape6
	mov al,[curtracesigbit]

	mov dl,[ebx+finalrt.pieces]
	inc ecx

	test ah,ah
	jz .nexttile
	js .clearsignal

	test [esi+edi],al
	jnz near .fail

.clearsignal:
	xor [esi+edi],al

	call redrawtileedi

.nexttile:
	mov al,dl
	cmp cl,[ebx+finalrt.length]
	ja near .endofroute

	call getnextdirandtile
	mov dl,[ebx+finalrt.pieces+ecx]
	inc ecx

	test dl,dl
	jnz .nohole

	mov dl,al
	jmp .nexttile

.nohole:
	mov al,[landscape4(di,1)]
	mov dh,[landscape5(di,1)]

	and al,0xf0
	cmp al,0x10
	je near .rail

	cmp al,0x20
	je .roadcrossing

	cmp al,0x50
	je near .station

	cmp al,0x90
	jne .nexttile

.bridgetunnel:
	cmp dh,4
	jae .bridge

	// check direction to see if we're on an enhancetunnels bridge
	test dl, 0x38	//diagonal directions, can't possibly be going through tunnel
	jnz near .markdl
	mov al,dh
	and al,1
	add al,1
	cmp al,dl
	jne near .markdl	// not tunnel direction, therefore bridge -> mark

.tunnel:
	// only reserve far end of tunnel, the close one won't be cleared when train disappears in tunnel
	bts edx,31
	jnc .nexttile

	btr edx,31
	jmp .markdl

.bridge:

	checkbridgepbs dh,dl,.nexttile,near .markdl

.roadcrossing:
	and dh,0xf0
	cmp dh,0x10	// crossing?
	jne .nexttile

	test ah,ah
	jz near .dontmark
	js .clearcrossing

	test byte [landscape5(di,1)],4
	jnz near .fail
	or byte [landscape5(di,1)],4
	jmp .redraw

.clearcrossing:
	test byte [landscape5(di,1)],4
	jz near .fail
	and byte [landscape5(di,1)],~4
	jmp .redraw

.station:
	test ah,ah
	jz near .dontmark
	js .clearstation

	test byte [landscape3+edi*2],0x80
	jnz near .fail
	or byte [landscape3+edi*2],0x80

	// activate "train reserves platform" trigger
	// (reset bit to trigger only once)
	btr dword [wantstationpbstrigger],0
	jnc near .redraw

	call activatestationpbstrigger
	jmp .redraw

.clearstation:
	test byte [landscape3+edi*2],0x80
	jz near .fail
	and byte [landscape3+edi*2],~0x80
	jmp short .redraw

.rail:
	test dh,0xc0
	jz .track
	js .depot

	// signal, check if it's on this track piece
	mov ch,dl
	bsf edx,edx
	mov al,[sigbitsonpiece+edx]
	shr edx,1
	mov dh,[sigbitfromsdirpiece+(ebp-1)*2+edx]
	test [landscape3+edi*2],al
	jz .nsig			//no signal at all on this piece, continue

	//signal is present on this piece
	testflags tsignals
	jnc near .done
	test BYTE [landscape6+edi], 4
	jz near .done			//is this a through signal, if no, done
	test [landscape3+edi*2], dh
	jnz near .done			//terminate route if signal is present in train's direction
.nsig:
	mov dl,ch
	mov ch,0
	jmp short .mark

#if 0
.signal:	// check that signal isn't either a red two-way or one
		// which has a PBS path reserved through it (or else this
		// train would assume the path is reserved for it!)
	mov dh,[sigbitsonpiece+edx]
	test [esi+edi],dh
	jnz .badend	// has a PBS path reserved, don't go there

	mov dl,dh
	and dh,[landscape3+edi*2]
	cmp dh,dl
	jne .done	// one-way signal
#endif

.depot:
	or ecx,byte -1
	and dh,1
	inc dh

.track:
	test dh,dl
	jz near .bad	// wrong track piece?

.markdl:
	mov dh,dl

.mark:
	test ah,ah
	jz .dontmark
	js .cleartile

	test [esi+edi],dh
	jnz near .fail

	or [esi+edi],dh

.redraw:
	call redrawtileedi

.dontmark:
	mov byte [didmarkroute],1

	test ecx,ecx
	js .done
	jmp .nexttile

.cleartile:
	test [esi+edi],dh
	jz .fail
	not dh
	and [esi+edi],dh
	jmp .dontmark

.endofroute:
	// found end of traced route
	// see if the track (not just the route) actually ends here, or if
	// the next tile has a signal
	mov al,dl
	call getnextdirandtile

	push eax
	xor eax,eax
	push esi
	push ebp
	call [getroutemap]
	pop ebp
	pop esi
	or al,ah
	and al,[piececonnections+ebp]
	pop eax		// restore ah at least
	jz .done	// no connection on next tile so it's safe to end here

#if 0
	bsf ecx,eax

	mov al,[landscape4(di,1)]
	and al,0xf0
	cmp al,0x10
	jne .notsignal

	test byte [landscape5(di,1)],0xc0
	jle .notsignal

	shr ecx,1
	mov al,[sigbitfromsdirpiece+(ebp-1)*2+ecx]
	test [landscape3+edi*2],al
	jnz .done	// next track piece has a signal

.notsignal:
#endif
	// route doesn't end either at a signal or a dead end
	// if the signal into the PBS block is red, we wait no matter what
	cmp byte [curtracesigstate],0
	jnz .bad

//&*&	IS THIS STILL USEFUL?

	// signal is green, this route is acceptable if we've found the target
	cmp byte [ebx+finalrt.type],2
	jb .badend

.done:
	cmp byte [didmarkroute],1	// set carry if no pieces marked
	jb .badend
	ret

.badend:
	// let's see if we had any route at all out of the block
	or ebx,byte -1
	xchg ebx,[alttracertdist]
	mov edi,alttracert
	test ebx,ebx
	jg .usealt

	// or any route at all, period (if signal leads to dead end)
	xchg ebx,[curtracertdist]
	mov edi,curtracert
//	xchg ebx,[sigtracertdist]
//	mov edi,sigtracert
	test ebx,ebx
	jle .bad

.usealt:
	// ok, last resort, try the alt or sig route
	inc bl
	mov [finaltracert+finalrt.length],bl
	and ebx,byte ~3
//	mov byte [finaltracert+finalrt.type],3	// what is this supposed to do?
.nextalt:
	mov ecx,[edi+ebx]
	mov [finaltracert+finalrt.pieces+1+ebx],ecx
	sub ebx,4
	jnc .nextalt
	jmp chkmarksignalroute

.fail:	// we get here when trying to reserve track already reserved
	// this implies there's a loop in the route which would cause
	// bad things to happen

.bad:
	stc
	ret

redrawtileedi:
	pusha
	mov eax,edi
	movzx ecx,ah
	movzx eax,al
	shl ecx,4
	shl eax,4
	call [invalidatetile]
	popa
	ret

activatestationpbstrigger:
	push eax
	movzx eax,byte [landscape2+edi]
	mov ah,station_size
	mul ah
	add eax,[stationarrayptr]
	test byte [eax+station.facilities],1	// safety check
	jz .norail

	pusha
	mov [curstationtile],edi
	mov ebx,eax
	mov esi,eax
	call getplatforminfo
	mov ah, cl
	mov al,0x20
	or edx,byte -1
	call randomstationtrigger
	popa
.norail:
	pop eax
	ret


	// see if current distance is beyond "ignore reserved pieces" segment
	//
	// in:	edi=tile XY
	// out:	ebp=current trace route distance
	//	cc=AE if no need to ignore reserved pieces
	//	cc=B if need to ignore reserved pieces
	// returns to previous stack frame with eax=0 if route loops
checkignoredistance:
	cmp byte [ignorereservedpieces],0
	je .done

	cmp edi,[curtracestartxy]
	je .abort

	movzx ebp,word [tracertdistance]
	cmp ebp,[lastsigdistance]
	ja .done

	or dword [lastsigdistance],byte -1	// we resumed a route before that signal
	stc

.done:
	ret

.abort:
	movzx ebp,word [tracertdistance]
	cmp ebp,[lastsigdistance]
	ja .done2

	or dword [lastsigdistance],byte -1	// we resumed a route before that signal
	stc

.done2:
	call [esp]	// call code that would run if we returned

	mov bp,[curtracestartpiece]
	imul bp,0x101	// set both bytes of bp to curtracestartpiece
	not bp
	and ax,bp	// remove starting piece from this tile
	pop ebp		// remove return address from stack
	ret		// return to previous caller


	// in:	 al=transport type
	//	edi=tile XY
	// additional when PBS pathfinding:
	//	ebx=direction
	// out before jmp to old handler:
	//	al=L5[DI]
	//	ZF=0 if transport not rail
	//	ZF=1 and al=track pieces if transport is rail
	// safe:eax ebp
opclass08hroutemaphnd:
	cmp al,0
	je .rail

.exit:
	jmp near $+5

.rail:
	movzx eax,byte [landscape5(di,1)]

	call checkignoredistance
	jae .done

	mov ebp,landscape6

	test al,0xc0
	jle .checkreserved	// not a signal

	// signal on this piece?
	push edx

	and al,[piececonnections+ebx]	// ignore signals on not connected pieces
	mov ah,al
.nextpiece:
	test al,0x3f
	jnz .checkpiece

	pop edx

	test al,0x40	// was there a signal?
	mov al,ah
	jz .done	// no, it was on the other piece apparently

	movzx ebp,word [tracertdistance]
	mov [lastsigdistance],ebp
	jmp short .done

.checkpiece:
	bsf edx,eax
	btr eax,edx

	mov dh,[sigbitsonpiece+edx]
	test [landscape3+edi*2],dh
	jz .nosignal

	or al,0x40
	jmp .nextpiece

.nosignal:
	// no signal, remove piece if it's reserved
	test [edi+ebp],dh
	jz .nextpiece	// not reserved

	mov dh,0
	add edx,8
	btr eax,edx
	jmp .nextpiece

.checkreserved:
	mov ah,[edi+ebp]
	and ah,0x3f
	jz .done

	test al,0xc0
	js .next

	and ah,[landscape5(di,1)]	// in case there was a 'left over' reserved piece
	jz .done

	// remove all pieces incompatible with each bit set in ah
.next:
	bsr ebp,eax	// scans bits in ah (eax bits 16..31 are 0)
	btr eax,ebp

	and al,[compatiblepieces+ebp-8]		// remove incompatible pieces
	jz .done

	test ah,ah
	jnz .next

.done:
	test al,0
	jmp .exit

	// similar as the above, but return al=1 if piece is reserved
	// (preserve ah)
opclass10hroutemaphnd:
	cmp al,0
	jne .exit

	mov al,[landscape5(di,1)]
	and al,0xf0
	cmp al,0x10
	jne .noignore	// not a crossing

	mov al,[landscape5(di,1)]
	and al,4	// crossing active bit
	shr al,2

	cmp byte [ignorereservedpieces],0
	je .noignore

	call checkignoredistance
	jb .exit

.noignore:
	mov al,0

.exit:
	jmp near $+5

opclass28hroutemaphnd:
	cmp al,0
	jne .exit

	mov al,[landscape5(di,1)]
	and al,0x7f
	cmp al,8
	jae .noignore

	mov al,[landscape3+edi*2]
	shr al,7
	cmp byte [ignorereservedpieces],0
	je .noignore

	call checkignoredistance
	jb .exit

.noignore:
	mov al,0

.exit:
	jmp near $+5

opclass48hroutemaphnd:
	cmp al,0
	je .rail

.exit:
	jmp near $+5

.rail:
	mov al,[landscape5(di,1)]
	cmp al,4
	jb .checktunnel	// tunnel

	checkbridgepbs al,,,near .check,near .checkhead
#if 0
	and al,11000110b
	cmp al,10000000b
	je .check	// rail bridge head
#endif

	mov al,0
	call checkignoredistance	// don't ever exit without calling this!
	jmp .exit

.checktunnel:
	mov al, [landscape7+edi]
	or al, al
	jns .check	//not enhanced
	test al, 0x60
	jz .check	//no diagonals
	mov al,0
	call checkignoredistance
	jae .exit
extern tnlrtmppbsflag
	mov BYTE [tnlrtmppbsflag], 1
	call .exit
	mov BYTE [tnlrtmppbsflag], 0
	extern enhtnlconvtbl
	push edx
	movzx edx, BYTE [landscape5(di,1)]
	and dl, 3
	mov dl, [enhtnlconvtbl+edx*4+3]	//get straight direction, this is always non-interfering, all else is fair game
	mov bp, ax
	mov dh, [landscape6+edi]
	movzx si, dl
	and dl, dh			//dl=straight direction track, if reserved
	not dl
	and dh, dl			//clear straight track from reserved list
	mov al, dl
	mov ah, al
	and bp, ax			//remove straight direction if reserved, bp=available track pieces
	mov ah, dh
	mov dx, si			//dl=straight direction track
	mov dh, dl
	mov al, -1
	mov si, bp
	and dx, bp			//dx=straight track directions if available
	call .next_check
	or ax, dx
	pop edx
	ret
	// check for pieces that are marked; since it's a bridge piece they
	// can't be interfering, all are compatible
.check:
	mov al,0
	call checkignoredistance
	jae .exit
	call .exit
	mov si,ax
//	mov ebp,[landscape6ptr]
	mov al,[landscape6+edi]
	not al
	jmp short .done

	// on bridge heads, we need to check what the marked pieces are compatible with
.checkhead:
	mov al,0

	call checkignoredistance
	jae .exit

	call .exit	// call old handler

	mov si,ax
//	mov ebp,[landscape6ptr]
	mov al,0xff
	mov ah,[landscape6+edi]
	and ah,0x3f
	jz .done

	// remove all pieces incompatible with each bit set in ah
.next:
	bsr ebp,eax	// scans bits in ah (eax bits 16..31 are 0)
	btr eax,ebp

	and al,[compatiblepieces+ebp-8]		// remove incompatible pieces
	jz .done

.next_check:
	test ah,ah
	jnz .next

.done:
	mov ah,al
	and ax,si
	ret

%macro defmaphnd 1.nolist
	db opclass %+ %1 %+ routemaphnd.exit - opclass %+ %1 %+ routemaphnd + 5
	db %1
	dd addr(opclass %+ %1 %+ routemaphnd)
%endmacro

var routemaphndlist
	defmaphnd 10h
	defmaphnd 28h
	defmaphnd 48h
	defmaphnd 08h	// rail must be last

	// compatible pieces for each reserved track piece
var compatiblepieces, db 0, 0, 8, 4, 0x20, 0x10


	// called when finding out the pieces to choose from on the next tile
	//
	// in:	esi->vehicle
	//	edi=tile XY
	//	ebp=direction
	// out: dl=all accessible track pieces on tile
	//	dh=track pieces with red signals
	//	flags from test dl,dl
	// safe:---
global getnexttileconnection
getnexttileconnection:
	call [gettileconnection]
	push eax

	// store movementstat for later
	mov al,[esi+veh.movementstat]
	mov [lastmovementstat],al

	cmp byte [esi+veh.subclass],0
	jne near .done

	mov al,[landscape4(di,1)]
	and al,0xf0
	cmp al,0x10
	je .rail
	cmp al,0x90
	jne near .done

	mov al,[landscape5(di,1)]
	cmp al,4
	jb .tunnel

.bridge:
	checkbridgepbs al,dl,near .done
#if 0
	and al,11000110b
	cmp al,10000000b
	jne .done	// middle or road piece
#endif
	mov eax,landscape6
	jmp .track

.tunnel:
	mov ah, [landscape7+edi]
	or ah, ah
	jns NEAR .done	//no enhanced tunnels
	test ah, 0x60
	jz NEAR .done	//no diagonals
	and eax, 3
	lea eax, [eax*2+1]
	cmp eax, ebp
	je NEAR .done	//heading into tunnel
	shr eax, 1
	and al, 1
	inc eax		//eax=2 if tunnel in Y, 1 if tunnel in X
	not al
	and dl, al	//prevent stuff trying to go off tunnel end
	mov eax, landscape6
	jmp .track

.rail:
	mov al,[landscape5(di,1)]
	test al,0xc0
	mov eax,landscape6
	jle .track

.signal:
	test byte [eax+edi],8
	jz .done

	// could be a pre-tracing signal
	push ebx

	bsf ebx,edx
	mov bl,[sigbitsonpiece+ebx]
	test [landscape3+edi*2],bl
	jz .nopath

	bsf ebx,edx
	shr ebx,1
	mov bl,[sigbitfromsdirpiece+(ebp-1)*2+ebx]
	test [landscape3+edi*2],bl
	jz .tsmaybenopath

	mov [curtracesigbit],bl
	test [landscape2+edi],bl
	setz [curtracesigstate]

	test [eax+edi],bl
	jnz .gotpath

	// couldn't find a path yet (or haven't checked)
	// try again now
	or dh,dl	// by default, if we can't get a pre-tracing path, stop at signal
	pusha
	mov ebx,ebp
	call markrailroute
	popa
	jc .nopath

.gotpath:
	mov dh,0	// ignore signal

.nopath:
	pop ebx
	jmp short .done
.tsmaybenopath:
	testflags tsignals
	jnc .nopath
	test BYTE [eax+edi], 4
	jz .nopath
	jmp .gotpath

.track:
	test dl,[eax+edi]
	jz .done	// nothing reserved

	and dl,[eax+edi]	// use the reserved piece and no others

.done:
	pop eax
	test dl,dl
	ret


uvard lastmovementstat
uvard gettunnelotherend

uvard lasttileclearedptr,2
uvarb lasttileclearedbit,2

	// called when last wagon leaves a tile
	//
	// in:	ax=new tile XY
	//	bp=prev tile XY
	//	dl=new direction
	//	[movementstat]=track piece on tile BP (+80h means clear both tiles)
	// out:
	// safe:bx
global lastwagoncleartile
lastwagoncleartile:
	pusha

	or dword [lasttileclearedptr],byte -1
	or dword [lasttileclearedptr+4],byte -1

	// calculate direction from delta XY

	movzx ebx,bp
	sub bh,ah
	sub bl,al
	inc bh
	inc bl
	shl bh,2
	or bl,bh
	mov bh,0
	movzx edi,bp
	movzx ebp,byte [dirfromdeltaxy+ebx]

	mov bl,[landscape4(di,1)]
	and bl,0xf0
	cmp bl,0x90
	jne .nottunnel

	cmp byte [landscape5(di,1)],4
	jnb .nottunnel

	mov ebx,ebp

	// on enhancetunnels bridge?
	test ebx, 1
	jz .nottunnel	//diagonal direction invalid?
	and ebx,7	// now ebx=1: NE, 3:SE, 5:SW, 7:NW
	dec ebx
	shr ebx, 1	// now ebx=0: NE, 1:SE, 2:SW, 3:NW
	xor bl, 2	//flip direction
	mov bh,[landscape5(di,1)]
	and bh,3
	cmp bh,bl
	jne .nottunnel	// direction of motion != direction OUT of tunnel entrance

	// train left tunnel entrance; we need to clear the pieces in front
	// of the other end instead

	mov ebx,ebp
	xor esi,esi
	xor ebx,4
	extern gettunnelotherendprocnocheckflag
	mov BYTE [gettunnelotherendprocnocheckflag], 1	//prevent route fixing of tunnel end calculation
	call [gettunnelotherend]
	or byte [lastmovementstat],0x80

.nottunnel:
	push edi

	xor ebp,4
	mov dl,[lastmovementstat]
	mov dh,dl
	and dx,0x807f
	mov ebx,ebp
	call getnextdirandtile		// get tile before the one in BP

	xor eax,eax
	push esi
	push ebp
	call [getroutemap]
	pop ebp
	pop esi
	or al,ah
	and al,[piececonnections+ebp]
	jz .nothing

	mov [lastmovementstat],al

	mov eax,ebp
	xor eax,4
	mov ebp,edi
	call clearpathtile

	mov ebp,[curcleartileptr]
	mov [lasttileclearedptr],ebp
	mov al,[curcleartilebit]
	mov [lasttileclearedbit],al

.nothing:
	pop ebp

	mov al,dl
	xor ebx,4
	call gettraintiledir.withdirandstat
	jc .done

	xor dh,0x80
	or al,dh
	mov [lastmovementstat],al

	mov al,bl
	call clearpathtile

	mov eax,[curcleartileptr]
	mov [lasttileclearedptr+4],eax
	mov al,[curcleartilebit]
	mov [lasttileclearedbit+1],al
.done:
	test dh,dh
	popa
	jnz near $+5
ovar .oldfn,-4,$,lastwagoncleartile
	ret


uvard curcleartileptr
uvarb curcleartilebit

// clear reserved tile piece
//
// in:	al=direction (only needed for signals)
//	bp=cur tile XY
//	[lastmovementstat]=tile piece; plus 0x80 if only clear pbs signal
// out: ZF if path ended at a signal without reserved path ahead
//	NZ if path does not end yet
// uses:---
clearpathtile:
	push edi
	push ebx
	push ebp
	mov edi,landscape6
	movzx ebp,bp
	mov bl,[lastmovementstat]
	mov bh,[landscape4(bp,1)]
	and bh,0xf0

	cmp bh,0x10
	je near .rail

	test bl,bl
	js .donenz

	cmp bh,0x20
	je .roadcrossing

	cmp bh,0x50
	je .station

	cmp bh,0x90
	je .bridgetunnel

.donenz:
	test esp,esp	// clear ZF

.done:
	pop ebp
	pop ebx
	pop edi
	ret

.roadcrossing:
	mov bl,[landscape5(bp,1)]
	mov bh,bl
	and bl,0xf0
	cmp bl,0x10	// crossing?
	jne .donenz

	test bh,4
	jz .donenz

	mov dword [curcleartileptr],0xff000000	// code for L5
	add [curcleartileptr],ebp
	mov byte [curcleartilebit],4

	and byte [landscape5(bp,1)],~4

	mov bl,1<<(14-8)		// dummy value that won't change anything

	lea ebp,[landscape3+ebp*2+1]
	or [ebp],bl		// set (unused) L3 bit 14
	sub ebp,edi
	jmp .clearbitnorec	// then clear it again (otherwise tile won't be redrawn)

.station:
#if 0
	// trigger when unreserving station tile
	// (not actually needed, trigger 08 does about the same)
	CALLINT3
	movzx ebx,byte [landscape3+ebp*2+1]
	cmp dword [statcargotriggers+ebx*4],0
	je .nostattrigger

	push edx
	or ebx,byte -1
	push 0x40
	call stationplatformtriggerxy
	pop edx

.nostattrigger:
#endif
	mov bl,0x80
.l3:
	lea ebp,[landscape3+ebp*2]
	sub ebp,edi
	jmp .clearbit

.bridgetunnel:
	mov bh,[landscape5(bp,1)]
	cmp bh,4
	jb near .clearbit

	checkbridgepbs bh,bl,.donenz,short .clearbit
#if 0
	and bh,11000110b
	cmp bh,10000000b
	jne .donenz	// don't mark middle or road pieces
	jmp short .clearbit
#endif

.rail:
	mov bh,[landscape5(bp,1)]
	test bh,0xc0
	jle .track

.signal:
	test byte [edi+ebp],0xf0
	jz .done

	push ecx
	bsf ecx,ebx
	movzx ebx,al
	shr ecx,1
	mov cl,[sigbitfromddirpiece+(ebx-1)*2+ecx]
	test [landscape3+ebp*2],cl
	jnz .havesig

	mov bl,[lastmovementstat]
	add bl,0x80			// set CF if clearing signals only

.havesig:
	mov bl,cl
	pop ecx
	jc .donenz

	test [edi+ebp],bl
	jnz .clearbit

.donez:
	test al,0
	jmp .done

.track:
	test byte [edi+ebp],0x3f
	jz .donenz

	test bl,bl
	js .donenz

	and bl,0x3f

.clearbit:
	and bl,[edi+ebp]
	jz .donenz

	mov [curcleartileptr],edi
	add [curcleartileptr],ebp
	mov [curcleartilebit],bl

.clearbitnorec:
	pusha
	movzx eax,byte [esp+0x20]
	movzx ecx,byte [esp+0x21]
	shl ecx,4
	shl eax,4
	call [invalidatetile]
	popa

	not bl
	and [edi+ebp],bl
	jmp .donenz


// mark path out of current signal block
//
// in:	esi->train engine
// out:	CF=1 if could not find path
// uses:---
global forcemarksignalpath
forcemarksignalpath:
	pusha

	// check if cur tile is depot or next tile has signal
	call gettraintiledir
	movzx edi,word [esi+veh.XY]
	mov al,[landscape4(di,1)]
	and al,0xf0
	cmp al,0x10
	jne .notdepot

	test byte [landscape5(di,1)],0xc0
	js near .nopathahead	// getting into depot

.notdepot:
	add di,[tiledeltas+ebx]
	mov al,[landscape4(di,1)]
	and al,0xf0
	cmp al,0x10
	jne .notsignalahead	// not railway track

	mov al,[landscape5(di,1)]
	test al,0xc0
	jle .notsignalahead	// no signal or depot

	and al,[piececonnections+ebx]	// now al can only be a single piece
	bsf eax,eax
	mov al,[sigbitsonpiece+eax]
	test [landscape3+edi*2],al
	jnz near .nopathahead	// don't need to mark ahead, we're approaching a signal anyway

.notsignalahead:
	// see if the tile can be entered at all
	pusha
	xor eax,eax
	call [getroutemap]
	or al,ah
	popa
	jz near .nopathahead

	// check if block is PBS block
	mov byte [waspbsblock],0

	push esi
	mov di,[esi+veh.XY]
	mov ecx,ebx
	mov ebp,[ophandler+1*8]	// Railway track
	mov ebx,1	// UpdateSignals function
	call [ebp+4]	// FunctionHandler
	pop esi

	cmp byte [waspbsblock],0
	je .nopathahead	// no path based signalling block
	jmp short .mark

.havepbs:	// entry point if we're sure it's a pbs block
	pusha

.mark:
	push dword [esi+veh.target]
	cmp word [esi+veh.target],byte -1
	jne .hastarget
	mov ax,[esi+veh.XY]
	add al,128
	add ah,128
	mov [esi+veh.target],ax
.hastarget:
	call gettraintiledir
	mov dl,al

	movzx edi,word [esi+veh.XY]
	mov ah,0
	mov al,[landscape4(di,1)]
	and al,0xf0
	cmp al,0x90
	jne .nottunnel

	mov al,[landscape5(di,1)]
	cmp al,4
	jae .notsignal

	mov ah,dl	// mark tunnel entrance as in use
	jmp short .notsignal

.nottunnel:
	cmp al,0x10
	jne .notsignal

	mov al,[landscape5(di,1)]
	test al,0xc0
	jle .notsignal

	bsf ecx,edx
	shr ecx,1
	mov ah,[sigbitfromddirpiece+(ebx-1)*2+ecx]

.notsignal:
	mov [curtracesigbit],ah		// 0 if it's not a signal
	mov byte [curtracesigstate],0	// to try any route, even not to target

	call gettraintilesrcdir
	mov dl,al
	push esi
	call markrailroute
	pop esi

	// if it failed, tough...  we did our best.

	pop dword [esi+veh.target]

.nopathahead:
	pushf
	cmp byte [onlycheckpath],0
	jne .checkonly
	call reservecurrenttrack
.checkonly:
	popf
	popa
	ret


	// mark the train's current squares as reserved, just to be safe
reservecurrenttrack:
	pusha
	mov edx,landscape6
.marknext:
	call gettraintiledir	// sets al=movementstat, ebx=dir
	jc near .nextveh	// in tunnel

	movzx edi,word [esi+veh.XY]
	mov ah,[landscape4(di,1)]
	mov ch,[landscape5(di,1)]

	and ah,0xf0
	cmp ah,0x10
	je .rail
	cmp ah,0x20
	je .roadcrossing
	cmp ah,0x50
	je .station
	cmp ah,0x90
	jne NEAR .nextveh

.bridgetunnel:
	cmp ch,4
	jae .bridge

	// enhancetunnels bridge?
	mov ah,[esi+veh.direction]
	and ah, 3
	mov cl, ch
	and cl, 1
	inc cl
	cmp al, cl
	jne .mark	//not passing in direction parrallel to tunnel

	// only reserve far end (exit) of tunnel
	mov ah,[esi+veh.direction]
	shr ah,1
	cmp ah,ch
	je .nextveh
	jmp short .mark

.bridge:
	checkbridgepbs ch,al,.nextveh,short .mark
#if 0
	and ch,11000110b
	cmp ch,10000000b
	jne .nextveh	// don't mark middle or road pieces
	jmp short .mark
#endif

.roadcrossing:
	and ch,0xf0
	cmp ch,0x10	// crossing?
	jne .nextveh

	or byte [landscape5(di,1)],4
	jmp short .nextveh

.station:
	or byte [landscape3+edi*2],0x80
	jmp short .nextveh

.rail:
	test ch,0xc0
	jg .signal
	jz .mark

	// depot, check that the movementstat is valid
	test al,al
	jns .mark

	mov al,[esi+veh.direction]
	and al,2
	shr al,1
	inc al

.mark:
	or [edx+edi],al
	jmp short .nextveh

.signal:
	bsf ecx,eax
	shr ecx,1
	mov cl,[sigbitfromddirpiece+(ebx-1)*2+ecx]
	or [edx+edi],cl

.nextveh:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .done
	shl esi,7
	add esi,[veharrayptr]
	jmp .marknext

.done:
	popa
	ret

// clear reserved path of a train
//
// in:	esi->train engine
// uses:---

global cleartrainsignalpath
cleartrainsignalpath:
	pusha
	mov edi,esi

.next:
	// clear reserved pieces on which the train currently runs
	mov bp,[esi+veh.XY]
	call gettraintiledir
	jc .nextveh

	mov [lastmovementstat],al
	mov eax,ebx
	call clearpathtile
.nextveh:
	mov eax,esi
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .donetrain
	shl esi,7
	add esi,[veharrayptr]
	jmp .next

.donetrain:
	// plus the tile behind the last wagon

	mov esi,eax
	call cleartileaftertrain

	mov esi,edi

	// clear reserved path ahead
	call gettraintiledir
	movzx edi,word [esi+veh.XY]
	jc .gotedi	// edi is tunnel entrance

	add di,[tiledeltas+ebx]
.gotedi:
	mov ebp,ebx

.nexttile:
	xor eax,eax
	push esi
	push ebp
	call [getroutemap]
	pop ebp
	pop esi
	and al,[piececonnections+ebp]
	jz .done	// end of route

	mov ah,[landscape4(di,1)]
	and ah,0xf0
	cmp ah,0x90
	je .jct		// might be a custom bridge head with multiple pieces

	cmp ah,0x10
	jne .notjct	// can only have one matching track piece

	test byte [landscape5(di,1)],0xc0
	jg .notjct	// signal means there's only one track piece in al now

.jct:
//	mov ecx,[landscape6ptr]
	and al,[landscape6+edi]	// else find out which one it is that's reserved
	jz .done		// none -> end of path

.notjct:
	mov [lastmovementstat],al
	mov dl,al

	mov ecx,edi
	call getnextdirandtile

	push ebp
	mov eax,ebp
	mov ebp,ecx
	call clearpathtile
	pop ebp

	jnz .nexttile

.done:
	popa
	ret

// clear tile after train
//
// in:	esi->any vehicle of the train
// uses:---
global cleartileaftertrain
cleartileaftertrain:
	pusha

.checknext:
	cmp word [esi+veh.nextunitidx],byte -1
	je .gotlast
	movzx esi,word [esi+veh.nextunitidx]
	shl esi,7
	add esi,[veharrayptr]
	jmp .checknext

.gotlast:
	call gettraintiledir

	mov al,[esi+veh.movementstat]
	or al,0x80
	mov [lastmovementstat],al

	mov bp,[esi+veh.XY]
	mov ax,bp
	add ax,[tiledeltas+ebx]

	mov dl,bl
	call lastwagoncleartile
	popa
	ret

var piececonnections, db 0,1+8+0x10,0,2+4+0x10,0,1+4+0x20,0,2+8+0x20
	db 1+2+4+0x10+0x20,1+2+4+8+0x10,1+2+8+0x10+0x20,1+2+4+8+0x20	// fake directions for statsprit.asm
var dirfromdeltaxy, db 4,3,2,4,5,4,1,4,6,7,0

uvard wtrackspriteofsptr

global displayrailsprites
displayrailsprites:
	mov bx,1005
	push edx

	mov dh,1
	call displayrailsprite
	mov dh,2
	call displayrailsprite
	mov dh,4
	call displayrailsprite
	mov dh,8
	call displayrailsprite
	mov dh,0x20
	call displayrailsprite
	mov dh,0x10
	call displayrailsprite

#if 1
.onlygray:
	mov bx,1005
	mov dh,1
	call displayrailspriteifgray
	mov dh,2
	call displayrailspriteifgray
	mov dh,4
	call displayrailspriteifgray
	mov dh,8
	call displayrailspriteifgray
	mov dh,0x20
	call displayrailspriteifgray
	mov dh,0x10
	call displayrailspriteifgray
#endif

	pop edx
	ret

uvard newpbstracknum
uvarw newpbstrackbase, 1, s

global displayregrailsprite
displayregrailsprite:
	call $
ovar .oldfn, -4, $,displayregrailsprite
	push edx
//	test di,di
//	jnz .notflat

	cmp dword [newpbstracknum], 12 // Must be 12 sprites or it is considered broken
	je .flat

	test di, 2+4+8 // test for 3 corners being flat
	jz .flat
	test di, 1+2+4
	jz .flat
	test di, 1+2+8
	jz .flat
	test di, 1+4+8
	jz .flat

	test di, 1+2 // These are bad and can not exist (yet)
	jz .notflat
	test di, 2+4
	jz .notflat
	test di, 4+8
	jz .notflat
	test di, 1+8
	jz .notflat

.flat:
	test byte [landscape5(si,1)],0xc0
	jz displayrailsprites.onlygray
.notflat:
	pop edx
	ret

displayrailsprite:
	test [esp+5],dh
	jz .notthere

	push ebx
	and ebx,0x3fff
	push ebp

	test byte [esp+5],0xc0
	jnz .notgray		// depot or signals

//	mov ebp,[landscape6ptr]

	test [landscape6+esi],dh
	jz .notgray

#if 1
	pop ebp
	pop ebx
	inc ebx
	ret
#else
	or ebx,0x3248000
#endif

.notgray:
	mov ebp,[wtrackspriteofsptr]
	add bx,[ebp]
	pop ebp
	call [addrailgroundsprite]
	pop ebx

.notthere:
	inc ebx
	ret

#if 1
displayrailspriteifgray:
	test [esp+5],dh
	jz .notthere

	push ebx
	and ebx,0x3fff
	push ebp

	test byte [esp+5],0xc0
	jnz .notgray		// depot or signals

//	mov ebp,[landscape6ptr]

	test [landscape6+esi],dh
	jnz .gray

.notgray:
	pop ebp
	pop ebx
	inc ebx
	ret

.gray:
	test di, di
	jnz .notflat

.finishoffset:
	or ebx,0x3248000

	mov ebp,[wtrackspriteofsptr]
	add bx,[ebp]
.finishoffset2:
	pop ebp
	call [addrailgroundsprite]
	pop ebx

.notthere:
	inc ebx
	ret

.notflat:
	test di, 2+4+8 // test for 3 corners being flat
	jz .finishoffset
	test di, 1+2+4
	jz .finishoffset
	test di, 1+2+8
	jz .finishoffset
	test di, 1+4+8
	jz .finishoffset

; Never try to fix TTD this way, adjust the sprite offsets instead... - Lakie
;	add dl, 8 // for corners and 'straights' the offset should be 8 pixels up

	// Add back when some action5 support has been added for the orignial offset
	test di, 1+2
	jz .flatslope
	test di, 2+4
	jz .flatslope
	test di, 4+8
	jz .flatslope
	test di, 1+8
	jz .flatslope

	jmp .finishoffset


.flatslope: // Selects correct sprite for slope
	mov bx, [newpbstrackbase]
	test di, 1+2
	jz .finishoffset1
	inc bx
	test di, 1+8
	jz .finishoffset1
	inc bx
	test di, 4+8
	jz .finishoffset1
	inc bx

	// Has its own sprite correction code
.finishoffset1:
	or ebx,0x3248000

	push ecx
	push eax
	mov ecx, [wtrackspriteofsptr] // this has the unified maglev corrected track offset
	mov ax, [ecx]
	mov cl, 0x52 // Each offset is 82 sprites
	idiv cl, 0 // fall back of 0
	shl ax, 2 // 4 sprites difference
	add bx, ax
	pop eax
	pop ecx

	jmp .finishoffset2
#endif


	// translate veh.direction into direction in which we leave the tile
	//
	// in:	esi=vehicle
	// out:	al=movementstat
	//	ebx=direction, one of 1 (-X), 3 (+Y), 5 (+X) or 7 (-Y)
	//	CF=1 if vehicle is in tunnel
	// uses:---
gettraintiledir:
	movzx ebx,byte [esi+veh.direction]
.withdir:
	call getvehmovementstat
	jc .done

.withdirandstat:
	shr ebx,1
	jc .gotdir
	cmp al,[tilebitsclockwise+1+ebx*2]
	je .gotdir
	dec ebx
	and ebx,3

.gotdir:
	shl ebx,1
	inc ebx
.done:
	ret

	// same as above, but direction in which we entered the tile
gettraintilesrcdir:
	movzx ebx,byte [esi+veh.direction]
	call getvehmovementstat
	jc .done

	shr ebx,1
	jc .gotdir
	cmp al,[tilebitsclockwise+1+ebx*2]
	jne .gotdir
	dec ebx
	and ebx,3

.gotdir:
	shl ebx,1
	inc ebx
.done:
	ret

	// return effective movementstat
	//
	// in:	esi->vehicle
	// out:	al=movementstat
	//	CF=1 if really in tunnel
getvehmovementstat:
	mov al,[esi+veh.movementstat]
	test al,0x40	// in tunnel?
	jz .done

	mov al,[esi+veh.direction]
	and al,2
	shr al,1
	sub al,-1	// add al,1 that sets carry flag

.done:
	ret


	// called after loading a game without path-based signalling set
global resetpathsignalling
resetpathsignalling:
	pusha

	mov esi,landscape6
	mov ecx,0x10000
.checktile:
	mov al,[landscape4(cx,1)-1]
	mov ah,[landscape5(cx,1)-1]

	and al,0xf0
	cmp al,0x10
	je .rail
	cmp al,0x20
	je .roadcrossing
	cmp al,0x50
	je .station
	cmp al,0x90
	jne .nexttile

.bridgeortunnel:
	mov al,~3

	cmp ah,4
	jb .clearbit

	mov al,~0x3f

	checkbridgepbs ah,,.nexttile,short .clearbit
#if 0
	and ah,11000110b
	cmp ah,10000000b
	jne .nexttile
	jmp short .clearbit
#endif

.roadcrossing:
	and ah,0xf0
	cmp ah,0x10	// crossing?
	jne .nexttile

	and byte [landscape5(cx,1)-1],~4
	jmp short .nexttile

.station:
	and byte [landscape3+(ecx-1)*2],~0x80
	jmp short .nexttile

.rail:
	test ah,0xc0
	mov al,~0x3f
	jle .clearbit

	mov al,~0xf8

.clearbit:
	and [esi+ecx-1],al
.nexttile:
	loop .checktile

	mov cl,2	// two runs: first reserve currently occupied track pieces, then reserve path ahead
.nextround:
	mov esi,[veharrayptr]
.checknext:
	cmp byte [esi+veh.class],0x10
	jne .nextveh

	cmp byte [esi+veh.subclass],0
	jne .nextveh

	cmp ecx,1
	je .ahead

	call reservecurrenttrack
	jmp short .nextveh

.ahead:
	cmp byte [esi+veh.movementstat],0x80
	je .nextveh

	mov byte [currouteallowredtwoway],2	// try the best to find *any* path
	call forcemarksignalpath
	mov byte [currouteallowredtwoway],0

.nextveh:
	sub esi,byte -0x80
	cmp esi,[veharrayendptr]
	jb .checknext
	loop .nextround

	popa
	ret

var dirfrompiece, db 1,3,2,2,4,4

	// called when removing the last wagon of a crashed train
	//
	// in:	bx=engine idx
	//	esi->vehicle to clear
	//	edi->previous vehicle (or same if only the engine is left)
	// safe:eax cx ebp
global clearcrashedtrainpath
clearcrashedtrainpath:
	push ebx

	cmp esi,edi
	jne .done

	call getvehmovementstat
	bsf ebx,eax
	mov bl,[dirfrompiece+ebx]
	mov [esi+veh.direction],bl
	call cleartrainsignalpath
	xor byte [esi+veh.direction],4
	call cleartrainsignalpath

.done:
	pop ebx
	ret


uvarb waspbsblock

	// check that block conforms to either no or all pre/exit/combo rule
global checkpathsigblock
checkpathsigblock:
	mov byte [waspbsblock],0

	pusha
	movzx ecx,word [esi+presignalstack.signalscount]
	mov edx,landscape6
	jecxz .pathsigok

	mov ebp,[esi+presignalstack.signalsbase]
	movzx edi,word [ebp]

	mov ah,[landscape1+edi]
	mov al,PL_ORG+PL_PLAYER
	push eax
	call ishumanplayer
	jne .pathsigok

	mov al,[esi+presignalstack.signalrun]
	test al,0x30
	jz .checksetup		// check setup unless we just manually changed a signal

#if 0
	test byte [miscmodsflags+2],MISCMODS_NOAUTOMATICPBSBLOCKS>>16
	jnz .pathsigok
#endif
	test byte [pbssettings],PBS_AUTOCONVERTPRESIG
	jz .pathsigok

	test byte [pbssettings],PBS_MANUALPBSSIG
	jnz .pathsigok

.clearpbs:
	mov ebp,[esi+presignalstack.signalsbase]
	movzx ecx,word [esi+presignalstack.signalscount]

.clearnext:
	movzx edi,word [ebp]
	mov ah,[ebp+2]
	add ebp,3

	test [landscape3+edi*2],ah
	jz .skip

	and byte [edx+edi],7

.skip:
	loop .clearnext

.pathsigok:
	popa
	ret

.checksetup:
	mov ah,[pbssettings]
#if 0
	mov al,[miscmodsflags+2]
#endif

.nextsig:
	movzx edi,word [ebp]
	mov al,[ebp+2]
	add ebp,3

	test [landscape3+edi*2],al
	jnz .issignal
	testflags tsignals
	jnc .nosignal
	test BYTE [edx+edi], 4	//through signals in opposite direction count as two-way PBS signals as far as auto-pbs setups are concerned
	jz .nosignal
.issignal:
	test byte [edx+edi],8
	jnz .ispbs	// block always converted to PBS if one signal is PBS

	test ah,PBS_AUTOCONVERTPRESIG
	jz .nosignal

#if 0
	test al,MISCMODS_NOAUTOMATICPBSBLOCKS>>16
	jnz .nosignal		// no conversion of pre-signals
#endif

	mov al,[landscape3+1+edi*2]
	test al,0x80
	jz .checkpresig		// not manual

	test ah,PBS_PRESERVEMANUALPRESIG
	jz .checkpresig

	or byte [waspbsblock],4	// don't convert, had manual signals

.checkpresig:
	test al,6	// pre/exit/combo signal?
	jz .nosignal

	or byte [waspbsblock],2

	test ah,PBS_PRESERVEMANUALPRESIG
	jz .ispbs	// definitely convert this block

.nosignal:
	loop .nextsig

	// if we got here, no signals were already PBS
	// now waspbsblock can be:
	// 0: no presignals found -> clear PBS
	// 2: presignals found, none manual and PRESERVEMANUAL on -> set PBS
	// 4: no presignals found, some manual and PRESERVEMANUAL on -> clear PBS
	// 6: presignals found, some manual and PRESERVEMANUAL on -> clear PBS
	cmp byte [waspbsblock],2
	jne .clearpbs

.ispbs:
	mov byte [waspbsblock],1

	cmp byte [esi+presignalstack.signalchangeop],0
	jne .pathsigok

	mov ebp,[esi+presignalstack.signalsbase]
	movzx ecx,word [esi+presignalstack.signalscount]
.marknext:
	movzx edi,word [ebp]
	mov ah,[ebp+2]
	add ebp,3

	test [landscape3+edi*2],ah
	jz .notthis

	or byte [edx+edi],8

.notthis:
	loop .marknext
	popa
	ret


uvard oldopclass08removesignals

global opclass08removesignals
opclass08removesignals:
	push eax
	push ecx
	push ebx
	call [oldopclass08removesignals]
	pop ecx
	test cl,1
	pop ecx
	pop eax
	jz .done

	cmp ebx,0x80000000
	je .done

	// reset reserved track pieces
	push eax
	push ecx
	shr ecx,4
	shr eax,4
	movzx eax,al
	mov ah,cl
//	add eax,[landscape6ptr]
	mov byte [landscape6+eax],0	// remove all bits, because tracks use bits 0..5
	pop ecx			// even though signals only set bits 3..7
	pop eax

.done:
	ret


	// called when checking if signals are safe for train to leave depot
	//
	// in:	esi->vehicle
	//	ebp->popclass1
	// out:	al=0 if signals safe
	// safe:ax ebx ebp esi di
global chktrainleavedepot
chktrainleavedepot:
	mov byte [waspbsblock],0

	push esi
	mov ebx,1	// UpdateSignals function
	call [ebp+4]	// FunctionHandler
	pop esi

	test byte [waspbsblock],1
	je .done	// no path based signalling block

	mov ax,[esi+veh.XY]
	cmp ax,[esi+veh.target]
	je .done	// target not updated, wait one tick

	mov byte [esi+veh.movementstat],1	// needed for the path finding
	test byte [esi+veh.direction],2
	jz .notY
	mov byte [esi+veh.movementstat],2
.notY:
	mov byte [onlycheckpath],1
	call forcemarksignalpath.havepbs
	mov byte [onlycheckpath],0
	jc .cantreserve
	call forcemarksignalpath.havepbs

.cantreserve:
	sbb al,al
	mov byte [esi+veh.movementstat],0x80	// restore to original value

.done:
	ret
	
exported class1routemapsigthrough	//high eax=map of signals which are green/non-existant
	mov	 ah, al		//L5 & 0x3F
	movzx	 eax, ax
	push	 ebx

	mov	 bl, byte [landscape3+edi*2]
	
//new code begins
	test BYTE [landscape6+edi], 4
	jz .nothroughsignal
	push DWORD .nothroughsignal
	push ebx
	not bl
	jmp class1routemapsigthrough_in		//count non-existant signals as green, if through signal
.nothroughsignal:
//new code ends

	mov	 bh, [landscape2+edi]
	test	 bl, 0C0h
	jnz	 short loc_547B97
	or	 bx, 0C0C0h
loc_547B97:
	test	 bl, 30h
	jnz	 short loc_547BA1
	or	 bx, 3030h
loc_547BA1:
	and	 bl, bh
class1routemapsigthrough_in:
	test	 bl, 80h
	jnz	 short loc_547BAD
	or	 eax, 10070000h
loc_547BAD:
	test	 bl, 40h
	jnz	 short loc_547BB7
	or	 eax, 7100000h
loc_547BB7:
	test	 bl, 20h
	jnz	 short loc_547BC1
	or	 eax, 20080000h
loc_547BC1:
	test	 bl, 10h
	jnz	 short loc_547BCB
	or	 eax, 8200000h
loc_547BCB:

	pop ebx
	ret
	
//_CS:0016107C,573050
exported chkrailroutetargettsigchk	//set ZF on blockage
	test BYTE [landscape3+edi*2], bl
	jz .maybe
	ret
.maybe:
	test BYTE [landscape6+edi], 4
	ret
