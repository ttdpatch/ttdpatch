
// Pre-signals

#include <std.inc>
#include <flags.inc>
#include <textdef.inc>
#include <bitvars.inc>
#include <signals.inc>

extern actionhandler,checkpathsigblock,curplayerctrlkey,currrmsignalcost
extern patchflags
extern pbssettings
extern altersignalsbygui_flags

	align 4
var signalchangeopptr, dd -1	// Index to signal change operation. 0=set green, 1=set red
var startsignalloopfn, dd -1	// Pointer to function that handles the signal changing

var currunstack, dd -1 	// stack frame of this signal setting run
var lastrunstack, dd -1	// stack frame of calling run (if any)

var presignalspritebase, dd -1	// First new sprite with presignal graphics
uvard numsiggraphics		// For how many signals do we have new graphics

var newruntype, db 0		// run type of the new signal run
var skipsignalmod, db 0	// number of times we need to skip the modifications check
var skipconstruction, db 0	// number of times we need to skip the track construction check
var recursespossible, db 9	// maximum level of recursion is 9.  Each one takes about 380h bytes on the stack.

//
//  CONCEPTS
// ----------
//
// automatic pre-signal setup if
//  - one side has more than one two-way signals, and at least one
//    one-way signal.  This is called the pre-block side.
//  - the other side has exactly one two-way, and at most one one-way
//    (a terminal station would have none).  This is the exit block side.
//
//
// Only changes to green are affected, red works as always
//
// The side that the function has been called to change is the "this"
// side.  The other side of the two-way signal in question is the "other"
// side.
//
// Two cases are possible _if_ there is a pre-signal setup:
// a) "this" the pre-block side.  Set "this" green if there are any other green
//    exit signals, or set two-ways green if there are one-way out signals.
//    This happens when the train leaves the pre-block section into the exit
//    block section (or elsewhere)
// b) "this" is the exit block side.  Set the pre-block side green, because there
//    is at least one free green exit now (this one)
//

//
// Pre-signal state is stored in the high byte of the landscape3 array
// i.e. at ds:landscape3[esi*2+1].  This it a bitcoded value:
//	 0 = regular signal
//	 1 = known setup (this is cleared until we have determined that
//	     a signal really is a pre-signal or exit.  Unless the tracks
//	     change this signal will not be checked again)
//	 2 = pre-signal
//	 4 = exit
//	 8 = signals are semaphore signals
//	10 = (maybe for combo signals; set for exits that are "reserved" by
//	     a train in a pre-signal block)
//	20+40 = (maybe for pre-signal & exit IDs, to support separate sets of
//		exits in a single block?) **)
//	80 = manual setup
//
//	87h = any pre-signal bits
//	78h = all other bits (e.g. and X,78h to clear pre-signal setup)
//
// *)	The reason is that the signal type must be multiplied by 16. Ignoring
//	bit 1 means that everything is already multiplied by 2, and we can
//	use the CPU's scaled index to multiply by 8, e.g. mov ebx,[esi+ebx*8]
//
// **)	One idea would be to support four IDs, 0, 20, 40, 60.  If a pre-signal
//	has a certain ID, only exits with the same ID count, *except* if the
//	ID is zero.
//	Zero ID pre-signals always consider all exits, no matter what their
//	ID is.
//	Zero ID exits always count for all pre-signals, no matter what their
//	ID is.
//	Problem: Combo signals might need two seperate IDs
//


// called at the start of the signal change loop
// safe:	eax ebx edx esi
global signalsstart
signalsstart:
		// this subtracts 300h from the previous stack frame
		// which is what this function replaces
		// it also reserves some extra space for our own variables
		// and sets everything up properly

	pop eax		// eip
	mov esi,[esp]	// orig. caller
	cmp dword [esi-4],0x455ff00		// ..0; call [ebp+4]
	setne bl	// bl=1 if this call is due to track modifications

	sub esp,byte presignalstack_size
	mov dword [currunstack],esp
	mov esi,esp

	sub esp,0x300
	push eax

	// zero the stack
	xor eax,eax
	lea edx,[eax+(presignalstack_size)/4-1]	// mov ebx,... in 3 bytes :)

.clearnext:
	mov [esi+edx*4],eax
	dec edx
	jns .clearnext

	mov eax,dword [lastrunstack]
	mov dword [esi+presignalstack.previousstack],eax
	or eax,eax
	mov al,byte [newruntype]
	jns short .notfirst

	// this is the first call, no recursion yet
	// for first calls, check where we're coming from

	shr byte [skipsignalmod],1
	// now if we have carry, we came from manually modifying a pre-signal
	// (note, shr has the advantage of having no overflow, unlike dec/sub)
	jnc short .notmanual

	or al,0x30		// call due to manual pre-signal change

.notmanual:

	shr byte [skipconstruction],1
	jc short .notfirst

	or bl,bl
	jz short .notfirst	// not due to track modifications

	or al,0x20

.notfirst:
	and al,~ 1
	mov byte [esi+presignalstack.signalrun],al
	mov byte [esi+presignalstack.signalchangeop],0xff

	ret
; endp signalsstart


// called whenever the state of a signal changes
// safe:	all but ebp, cx
// out:		edi=landscape index
//		al=signal bit to change
global signalsloop
signalsloop:
	// since ebp is used so extensively for the signal loops,
	// we'll use esi as stack base pointer and define the stack
	// as a structure instead
	// (we could use esp but that would be very tedious)
	mov esi,dword [currunstack]

	mov ah,byte [esi+presignalstack.signalrun]

	test ah,1		// is this the first loop time?
	jnz short .knowitalready

	mov edi,dword [signalchangeopptr]
	mov bl,[edi]
	mov byte [esi+presignalstack.signalchangeop],bl

	mov word [esi+presignalstack.signalscount],cx
	mov dword [esi+presignalstack.signalsbase],ebp

	test ah,2		// do we check the "other" dir only?
	jz short .nototherdir
	call thisisotherdir
.abortloop:
	xor al,al			// do nothing with this signal
	mov cx,1			// so that this is the last iteration
	mov ebp,dword [esi+presignalstack.signalsbase]
	movzx edi,word [ebp]	// set the landscape pointer before exiting
	ret

.nototherdir:
	test ah,8			// do we check the presignal setup only?
	jz short .notsetupcheck
	call checkpresignalsetup
	jmp short .abortloop

.notsetupcheck:
	call countandsetpresigs

	or byte [esi+presignalstack.signalrun],1

	// set the signal change op to whatever it should be
	mov edi,dword [signalchangeopptr]
	mov bl,byte [esi+presignalstack.signalchangeop]
	mov [edi],bl

	// restore loop variables
	mov ebp,dword [esi+presignalstack.signalsbase]
	mov cx,word [esi+presignalstack.signalscount]

.knowitalready:
	// so now all signals are known to be either normal, presig, exit
	// or combined.  For each we have to do the appropriate thing.

	movzx edi,word [ebp]
	mov al,[ebp+2]

	// if it's an exit, remember to recurse later on
	test byte [nosplit landscape3+1+edi*2],4
	jz short .notanexit

	or byte [esi+presignalstack.signalrun],0x40

.notanexit:
	call getchangeop
	mov esi,dword [signalchangeopptr]
	mov [esi],ah
	ret

; endp signalsloop 

	// called at the end of the signals loop.  Is supposed to clear
	// up the stack and return:
	// in:	al=signal change op
	// out:	al=signal change op
	// safe:all
global signalsend
signalsend:
	mov esi,dword [currunstack]
	cmp byte [esi+presignalstack.signalchangeop],0xff
	jne .havechangeop

	mov [esi+presignalstack.signalchangeop],al

.havechangeop:
	test byte [esi+presignalstack.signalrun],0x40
	jz short .neednotrecurse

	// Recurse into all exits
	//
	// If this was an exit (or combined), we need to set
	// all previous pre-signals to the correct state.  So figure this
	// state out first by seeing if there are any green signals

	// restore loop variables
	mov ebp,dword [esi+presignalstack.signalsbase]
	mov cx,word [esi+presignalstack.signalscount]

.nextsignal:
	movzx edi,word [ebp]
	mov al,[ebp+2]
	add ebp,byte 3
	test byte [nosplit landscape3+1+edi*2],4
	jz short .noexit

	// ok, so this was an exit; we need to set the corresponding
	// pre-signals accordingly.  But first make sure we don't enter
	// a block that is handled in one of the previous stack frames
	// so as to avoid infinite loops

	pusha
	mov ebx,esi

.checknextframe:
	mov ebx,dword [ebx+presignalstack.previousstack]
	or ebx,ebx
	js short .notdoneyet

	mov ebp,dword [ebx+presignalstack.signalsbase]
	mov cx,word [ebx+presignalstack.signalscount]

.checknextsignal:
	cmp di,[ebp]
	je short .donerecursion	// we handled this one already
	add ebp,byte 3
	loop .checknextsignal
	jmp .checknextframe

.notdoneyet:
	// al and edi are already set appropriately
	call getcomplicatedotherdir
	mov al,4
	call signalsrecurse

.donerecursion:
	popa

.noexit:
	loop .nextsignal

.neednotrecurse:
	testflags pathbasedsignalling
	jnc .nopathsig

	call checkpathsigblock	// in pathsig.asm

.nopathsig:
	mov al,byte [esi+presignalstack.signalchangeop]

	// this fragment replaces sub esp,300h, so clear the data from stack
	ret 0x300+presignalstack_size
; endp signalsend


	// figures out what to set a signal to, depending on whether there
	// is a pre-signal present, whether there are green exits, or one-way
	// out signals
	// in:	al, edi from signal data
	// out:	ah=signal change op
getchangeop:
	// by default use normal change op
	mov ah,byte [esi+presignalstack.signalchangeop]
	mov dl,[nosplit landscape3+1+edi*2]

	// mustsetstate can be 0,1,2,4,-1
	// 0: everything changed normally
	// 1: all pre-signals set to specialchangeop, everything else normal
	// 2: pre-signals and exits set to specialchangeop,
	//    everything else normal  (OBSOLETE, NOT USED)
	// 4: (NOT USED YET)
	// -1: everything normal except a green two way combined signal
	//     which is special instead
	// this is a neat way to distinguish five cases with a single cmp

	cmp byte [esi+presignalstack.mustsetstate],1
	// now jb if 0, je if 1, js if -1 (unless jb), jpe if 4 else 2.

	jb short .normal		// 0
	js short .specialcombined	// -1 (must be below jb because "b" also has "s")
//	je short @@setspecial		// 1
//	jpe short @@normal		// 4
//	jmp short @@normal		// 2

// the above are now equivalent to:
	jne short .normal

	and dl,2
	jz short .normal		// not a pre-signal

.setspecial:
	// "or" ah with the special op so that we don't accidentally
	// set something to green that shouldn't be
	or ah,byte [esi+presignalstack.specialchangeop]

.normal:
	ret

.specialcombined:
	// if this is a green two-way combined signal, it is special,
	// otherwise normal
	and dl,6
	cmp dl,6
	jne short .normal	// not a combined signal
	call checkistwoway
	jne short .normal	// not a two-way signal

	// is it green in the other direction? (i.e. a green exit)
	test byte [landscape2+edi],dl
	jz short .normal	// not green
	jmp short .setspecial	// green combined signal is special

; endp getchangeop 


// find out whether a signal is a pre-signal, an exit, and if an exit
// whether it's green
// set one of the following bits in ah accordingly:

#define MAXCOUNTGREENSIGNALS 3	// must be (power of 2)-1 and less than all of the below values
#define HAVEEXIT 10h		// have any type of exit (red or green)
#define HAVEPRESIG 20h		// pre-signal(s) in this block
#define HAVEGREENEXIT 40h	// green exit(s) in this block
#define HAVEGREENTWOWAYCOMBO 80h // green two-way combo signal(s) in this block

getpresigtype:

	// if there are more than two signals in the block,
	// it might be necessary to do an automatic pre-signal conversion

	cmp byte [esi+presignalstack.signalscount],2
	jbe short .isdefinedtype

	// check whether automatic setups are enabled

	testflags presignals
	jnc short .isdefinedtype	// nope, no automatic pre-signals

	mov bl,[nosplit landscape3+1+edi*2]

	// if we're doing automatic setups, clear them upon track modifications

	mov bh,byte [esi+presignalstack.signalrun]
	and bh,0x30
	jz short .notamodification

	and bh,0x10
	jnz short .isdefinedtype	// manual modification, don't touch, but don't reset either

	or bl,bl
	js short .notamodification	// don't touch manual signals

		// clear pre-sig bits
	and byte [nosplit landscape3+1+edi*2],~ 0x87
	call updatesquaregraphics
.nextloop:
	ret

.notamodification:
	test bl,0x81
	jnz short .isdefinedtype

	// ok, so it's an unknown type.  Figure out actual type
	// unless we don't want automatic setups

	pusha
	call checkpresignalsetup
	popa

	// now we can reliably check the "is exit" status
.isdefinedtype:
	call checkistwoway

	mov bl,[nosplit landscape3+1+edi*2]
	and bl,6
	jz short .nextloop	// no pre-signalling bits set; ignore

	test bl,2
	jz short .notapresig

	// it's a pre-signal

	test bh,al		// is it in the right direction though?
	jz short .notapresig	// no signal in this direction -> don't count

	or ah,HAVEPRESIG

.notapresig:
	test bl,4
	jz short .nextloop	// not an exit either

#if 0
	// so it's neither a pre-signal nor an exit.
	// if it's a one-way signal leading out, it means some signals can
	// go green

.neitherpresignorexit:
	call checkistwoway
	je short .nextloop

	// one-way signal.  Maybe it's an exit, so check that
	cmp bh,dl			// is it the other dir?
	jne short .nextloop

	or ah,0x20
	jmp short .nextloop

.itsanexit:
#endif

	// it's an exit

	// is it green?
	test bh,dl		// dl=the other direction
	jz short .nextloop2	// no signal in that direction -> can't be green

	or ah,HAVEEXIT

	test byte [landscape2+edi],dl
	jz short .nextloop2	// not green

	// yes, it's green
	or ah,HAVEGREENEXIT
	mov al,ah
	and al,MAXCOUNTGREENSIGNALS
	cmp al,MAXCOUNTGREENSIGNALS
	jae short .couldbecombo

	inc al		// increase up to MAXCOUNTGREENSIGNALS
	and ah,~ MAXCOUNTGREENSIGNALS
	or ah,al

.couldbecombo:
	cmp bl,6	// is it a green two-way combo signal?
	jne short .nextloop2
	cmp bh,dh	// two-way?
	jne short .nextloop2

	or ah,HAVEGREENTWOWAYCOMBO

.nextloop2:
	ret

; endp getpresigtype 

	// the state of an exit signal changed so we have to count the green
	// exits, and if there is one set the pre-signals to green otherwise
	// red.  If there are no exits at all, pre-signals go green too.
countandsetpresigs:

	xor ah,ah	// ah: bitcoded (see above for bit values)
			// 	lower bits: number of green exits, up to 3.

.nextsig:
	movzx edi,word [ebp]
	mov al,[ebp+2]
	add ebp,byte 3

	call getpresigtype

	loop .nextsig

	// so now we know what signals we have.  By default everything is
	// normal.

	xor al,al
	test ah,HAVEPRESIG
	jz short .done		// no pre-signals, all is normal

	// so we have pre-signals.  If there is only one green exit and it is
	// in fact a combined signal, this signal must not go green, because
	// it would count its other direction as exit but that is absurd

	test ah,HAVEGREENTWOWAYCOMBO
	jz short .notsinglecombine
	mov bl,ah
	and bl,MAXCOUNTGREENSIGNALS
	cmp bl,1
	ja short .notsinglecombine

	// so the combined signal is the only green exit.  All other pre-signals
	// can go green, but not this one
	mov al,-1
	mov byte [esi+presignalstack.specialchangeop],1	// keep it red
	jmp short .done

.notsinglecombine:
	// if the pre-signal has no exits at all, it's green by default
	mov al,0
	test ah,HAVEEXIT
	jz short .done


	test ah,HAVEGREENEXIT
	setz byte [esi+presignalstack.specialchangeop]	// green(0) if there are green exits

	mov al,1

.done:
	mov byte [esi+presignalstack.mustsetstate],al
	ret

; endp countandsetpresigs 


	// called to make TTD re-draw a square
	// this is useful if a signal is converted to
	// a pre-signal, because otherwise TTD might
	// not re-draw it unless the state changes
	//
	// in:	di=landscape index
updatesquaregraphics:
	pusha

	rol di,4
	mov eax,edi
	mov ecx,edi
	rol cx,8

	and ax,0xff0
	and cx,0xff0

	call $
ovar fnredrawsquare,-4

	popa
	ret
; endp updatesquaregraphics 

	// same as above, but only do so if the signal actually changes
	// type
	//
	// in:	edi=byte in landscape2 array that indicates pre-signal type
	//	bl=new pre-signal type
	//	[edi-3]=landscape index
	// out:	edi undefined
updatesignalgraphics:
	cmp [edi],bl
	jne short .settype
	ret

.settype:
	mov [edi],bl
	mov edi,[ebp-3]
	jmp updatesquaregraphics
; endp updatesignalgraphics 




	// this is a recursive call from a pre-signal setup checking loop
	// we must count the signals and return whether this is the exit block
	// or not
thisisotherdir:
	xor eax,eax
.nextothersquare:
	movzx edi,word [ebp]
	mov al,[ebp+2]
	add ebp,byte 3

	call checkistwoway
	setz al		// zero = is a two way => al=1
	inc byte [esi+presignalstack.signaltypecount+eax]
	loop .nextothersquare

	mov edi,dword [esi+presignalstack.previousstack]	// where we store the result
	mov byte [edi+presignalstack.othersidetype],0

	// If we have exactly one two-way and up to one one-way, we are an exit block

	cmp byte [esi+presignalstack.signaltypecount+0],1
	ja short .done
	cmp byte [esi+presignalstack.signaltypecount+1],1
	jne short .done

	// OK, so this is really an exit block
	inc byte [edi+presignalstack.othersidetype]

.done:
	ret
; endp thisisotherdir 




	// find out whether this block is a pre-signal setup
	//
	// find out which case it is.
	// a) "this" is pre-block  -> mark pre-signals and check two-ways
	// b) "this" is exit block -> do nothing

checkpresignalsetup:

	// restore loop variables
	mov ebp,dword [esi+presignalstack.signalsbase]
	mov cx,word [esi+presignalstack.signalscount]

	or dword [esi+presignalstack.twowaysignalpos],byte -1
	xor eax,eax
        mov word [esi+presignalstack.signaltypecount],ax

.nextsignal:
	movzx edi,word [ebp]
	mov al,[ebp+2]
	add ebp,byte 3

	call checkistwoway
	mov al,0
	jne short .isoneway
	mov dword [esi+presignalstack.twowaysignalpos],edi
	mov byte [esi+presignalstack.twowaysignalbits],al
	mov al,1

.isoneway:
	inc byte [esi+presignalstack.signaltypecount+eax]		// count this type
	loop .nextsignal


	// restore loop variables
	mov ebp,dword [esi+presignalstack.signalsbase]
	mov cx,word [esi+presignalstack.signalscount]


	// Three cases
	// 1) No two-way signals -> no pre-signal setup
	// 2) One two-way signal -> could be exit block; do nothing
	// 3) >1 two-way signals -> could be pre-block; check each two-way signal

	cmp byte [esi+presignalstack.signaltypecount+1],1
	jb short .clearall		// not any two-way signals
	ja short .mightbepreblock

	// exactly one two-way, could be "single"
	// but we don't modify this automatically, only when a train
	// enters the pre-signal block
	ret



	// get next signal
	// in:	ebp=pointer to signal structure
	// out:	ebp+=3
	//	edi=pointer to pre-signal type byte
	//	bl=pre-signal type byte (from [edi])
	//	other regs according to "checkistwoway"
	//	sign flag set if it's a manual signal
	//      zero(equal) flag set if it's a two-way
.getnextsignal:
	movzx edi,word [ebp]
	mov al,[ebp+2]
	add ebp,byte 3

	call checkistwoway
	setne ah
	lea edi,[nosplit landscape3+1+edi*2]
	mov bl,[edi]
	test bl,0x80
	jns short .getsignaldone
	or ah,0x80
.getsignaldone:
	or ah,ah
	ret

	// block is neither pre-block nor exit block
	// no two-ways, or two-ways but no one-way
	// clear pre-signal and exit status of all involved signals leading in
.clearall:

.clearnext:
	call .getnextsignal
	js short .manual2

	// is it leading in?
	test bh,al
	jz short .notin

	and bl,~ 6

.notin:
	or bl,1
	call updatesignalgraphics

.manual2:
	loop .clearnext
	ret


	// could be a pre-block, has at least two two-ways
	// to actually be a pre-block, there must be at least one one-way in
	// and at least two of those two-ways must be exits
.mightbepreblock:
	cmp byte [esi+presignalstack.signaltypecount+0],1	// any one-way signals?
	jl short .clearall		// no -> no pre-signals

	// so, this might still be a pre-block, check the setup for the other
	// side for each of the two-ways, and set them to exit or not-exit status
	// as well as count them

	mov byte [esi+presignalstack.signaltypecount+1],0	// this now counts exits, not two-ways

	mov eax,ecx

	// create a sub-stack frame the size of (ecx+1)/8 (rounded up) without ebp
	// this is used to remember what two-way signals were exits to change
	// only those and leave others as they are
	neg eax
	dec eax		// because e.g. ecx=8 needs 9 bits (0..8)
	sar eax,3	// rounds towards -infty, i.e. rounds down
	add eax,esp
	and eax,byte ~ 3	// re-align to a dword

	xchg esp,eax	// now eax=old esp, esp=old esp-ecx/8

	push eax	// so that later we can just pop esp...
	push ecx
	push ebp

.checknext:
	btr [esp+12],ecx			// clear "is exit" bit
	call .getnextsignal
	jne short .notanexit

	test bl,0x81
	jnz short .knowitalready	// has been set already

	// need to figure out whether this two-way is an exit
	pusha
	movzx edi,word [ebp-3]	// ebp is already +3
	mov al,[ebp-3+2]
	call getcomplicatedotherdir
	mov al,2			// mark it as "check other dir" run
	call signalsrecurse
	popa

	cmp byte [esi+presignalstack.othersidetype],1
	jne short .notanexit		// it's not an exit
	or bl,4

.knowitalready:
	test bl,4
	jz short .notanexit

	inc byte [esi+presignalstack.signaltypecount+1]
	bts [esp+12],ecx		// set "is exit" bit

.notanexit:
	loop .checknext

	pop ebp
	pop ecx

	// now we know how many exits there are.  If there isn't at least 1,
	// no pre-signal setup exists, so clear all.
	// Otherwise, the one-ways are pre-signals, and some of the two-ways
	// are exits

	cmp byte [esi+presignalstack.signaltypecount+1],0
	ja short .ispresignalsetup

	// no exits
	pop esp		// restore stack frame
	jmp .clearall

.ispresignalsetup:

.setnext:
	call .getnextsignal
	js short .manual4
	je short .itsatwoway

	// it's a one-way.  If it's "in", it's a pre-signal, otherwise it's not
	cmp bh,dl
	je short .markthis

	or bl,2		// it's an actual pre-signal
	jmp short .markthis

.itsatwoway:
	bt [esp+4],ecx
	jnc short .markthis	// two-way, but not an exit

.isanexit:
	or bl,4

.markthis:
	or bl,1
	mov [edi],bl

.manual4:
	loop .setnext

.presignalsmarked:		// we're done
	pop esp		// restore stack
	ret

; endp checkpresignalsetup 


	// recurse into another signal setting loop
	// in:	al = new run type (80h will be set automatically)
	//	cx,edi as necessary for the signal loop
	// all registers should already have been saved
signalsrecurse:
	dec byte [recursespossible]
	js short .done

	or al,0x80
	mov ah,byte [esi+presignalstack.signalrun]
	and ah,0x30			// keep some bits
	or al,ah
	mov byte [newruntype],al

	push dword [lastrunstack]		// also set save last stack,
	mov eax,dword [currunstack]
	mov dword [lastrunstack],eax	// then set last stack=cur stack

	call dword [startsignalloopfn]

	mov esi,dword [lastrunstack]
	mov dword [currunstack],esi	// restore current stack
	pop dword [lastrunstack]		// restore last stack

	mov byte [newruntype],0		// it'll be totally new by default

	mov al,byte [esi+presignalstack.signalchangeop]
	mov ebx,dword [signalchangeopptr]
	mov [ebx],al			// restore signal change operation

.done:
	inc byte [recursespossible]
	ret
; endp signalsrecurse 

	// checks whether the signal at landscape index edi
	// is a two-way signal in the direction given by al
	//
	// in:	al = byte with the bit set that corresponds to the direction of the signal
	//	edi= landscape index
	// out: zf = yes, it's a two-way
	//	nz = no, it's a one-way
	//	eax unchanged
	//      dl = direction opposite to al [e.g., 10h <=> 20h]
	//	dh = both directions [=dl or al]
	//	bl = bit number of the other direction
	//	bh = which directions are actually set
	// destroys: ebx
checkistwoway:
	mov dl,al
	mov dh,al
	bsf ebx,edx	// which bit is set in edx=al?
	xor bl,1	// to get the number of the other bit
	bts edx,ebx	// now dl has the mask for the both ways the signals can be set
	xchg dl,dh	// but we want it in dh
	xor dl,dh	// and make dl get the other bit

	// see which of these are actually set
	mov bh,[nosplit landscape3+edi*2]

	and bh,dh		// clear all but these two directions
	cmp bh,dh		// now if bh==dh it's a two-way
	ret
; endp checkistwoway 


	// Find the other direction, if we only know the bits of the signal
	// for the "this" direction, but not the direction itself

	// in:	al=one bit set for the signal
	//	edi=landscape index
getcomplicatedotherdir:
	bsf edx,eax
	sub dl,4		// now dl = this direction (not bit!)

	mov al,[landscape5(di)]
	and al,~ 0xc0

	xor ecx,ecx
	test al,1
	jnz short .getotherdir

	inc ecx
	test al,2
	jnz short .getotherdir

	inc ecx
	test al,0xc
	jnz short .getotherdir

	inc ecx

.getotherdir:
	mov cl,byte [.trackdir+ecx*4+edx]
	ret

	// this is an array translating a signal bit number to a
	// track direction bit number
.trackdir:
	// the lines mean: orig dl<->real dir<->other dir
	// ecx=0: diagonal tracks, from bottom left to top right
	// dl 0<->x<->x; 1<->x<->x 2<->5<->1 3<->1<->5;

	db 1,1,1,5

	// ecx=1: diagonal tracks, from bottom left to top right
	// dl 0<->x<->x; 1<->x<->x 2<->7<->3 3<->3<->7;

	db 1,1,3,7

	// ecx=2: vertical tracks
	// dl 0<->5<->3; 1<->3<->5 2<->7<->1 3<->1<->7;

	db 3,5,1,7

	// ecx=3: vertical tracks
	// cx 0<->3<->1; 1<->1<->3 2<->5<->7 3<->7<->5;

	db 1,3,7,5

; endp getcomplicatedotherdir 



#if 0
// this is not used anymore
	// find out the other direction if we know the this direction
	//
	// in:	cx=this direction
	//	edi=landscape index
	// out:	cx=other direction
geteasyotherdir:

	mov al,[landscape5(di)]
	and al,~ 0xc0
	test al,3		// are the tracks diagonal?
	jnz short .diagonally

	test al,0xc		// or horizontal?
	jnz short .horizontally

				// tracks go vertically
	// change 1<->3, 5<->7
	xor cl,2
	ret

.diagonally:			// tracks go diagonally
	// change 1<->5, 3<->7
	xor cl,4
	ret

.horizontally:			// tracks go horizontally
	// change 1<->7, 3<->5
	sub cl,8
	neg cl
	ret
; endp geteasyotherdir 
#endif



global drawsignal
drawsignal:
	mov esi,[esp+4]		// landscape offset

	// show pre-signal or semaphore graphics
	mov dh,6+8
	and dh,[landscape3+1+esi*2]

	testflags pathbasedsignalling
	jnc .gotbits

//	mov edi,[landscape6ptr]
	test byte [landscape6+esi],8
	jz .gotbits

	or dh,0x10

	// show green if there's a reserved path
	push edx

	mov edx,[esp+16]
	mov dh,[edx-6]		// imm8 of test dl,imm8 before call
	cmp dh,0x90		// (or a NOP, which we change to 80h)
	jne .notnop

	mov dh,0x80

.notnop:
	test [landscape6+esi],dh
	pop edx

	jz .gotbits

	// show green (round ebx up to an even number)
	inc ebx
	and ebx,byte ~1

.gotbits:
	movzx esi,dh
	and esi,[numsiggraphics]
	jz .nopresignal

	movzx ebx,bx

	// ebx-4fbh=org signal state, esi*8-16=(type of signal)*16
	lea ebx,[ebx-0x4fb+esi*8-16]
	add ebx,[presignalspritebase]

.nopresignal:
	mov di,1
	mov si,di
	mov dh,0x10
	ret
; endp drawsignal


var signalsprites, dw 1289,1287,1289,1287,1285,1283,1285,1283,1279,1281,1275,1277
var signaloffsets
	// the original offsets for signals on the left side:
	db 0x8,0xE,0x1,0x9,0x1,0x3,0xB,0xE,0x3,0xD,0xB,0x4	// X offsets
	db 0x5,0x1,0xE,0xB,0x0,0xA,0x4,0xE,0x4,0xB,0x3,0xD	// Y offsets
	// and now the offsets for signals on the right side:
	db 0xE,0xA,0x5,0x1,0xA,0x0,0xE,0x4,0xD,0x3,0xB,0x4      // X offsets
	db 0x1,0x8,0x7,0xE,0x3,0x1,0xE,0xB,0x4,0xB,0xD,0x3      // Y offsets

// Called to compute landscape offsets of a signal (12 occurences in the class 1 land drawing routine)
// In:	BL = number of the occurence
//	AX,CX = X,Y coordinates (precise) of the north corner of the tile
// I/O:	ESI = tile XY coordinates (offset into landscape)
//	DL = L2[ESI]
//	DH = L5[ESI] & 0x3F
// Out:	EBX = sprite number
//	AX,CX = X,Y coordinates of the signal
// Safe:EDI
global setsignaloffsets
setsignaloffsets:
	movzx ebx,bl
	mov edi,[roadtrafficside]
	and edi,byte 0x10
	shr edi,1			// 24/16 == 3/2
	lea edi,[edi*3+signaloffsets]	// NASM can handle this -- it'll output [edi+edi*2+offset32]
	or al,[edi+ebx]
	or cl,[edi+ebx+12]
	mov bx,[signalsprites+ebx*2]
	test dl,0x80			// for the 5th occurence, this gets overwritten
					// for all the other occurences, another "test dl,imm8" will follow it immediately
	ret
; endp setsignaloffsets


// Called when clicking on track with the signal tool
//
// In:	EDI=landscape index
//	BH =mask with bits to keep in landscape3 array
//	BL =mask with bits to set
// Out:	BL same or zero if nothing to set
// Safe:rest of EBX
global modifysignals
modifysignals:
	push edi
	push eax
	lea edi,[landscape3+edi*2]

	// is there already a signal?  If not, we can't modify it...
	// so do the default which is place a new one
	test byte [edi],0xf0
	jz short .newsignal

	testmultiflags extpresignals
	jz .regularsig

	cmp byte [altersignalsbygui_flags], 0
	jne .altersignalsbygui
	
	cmp byte [curplayerctrlkey],1
	jz short .isctrl

.regularsig:
	and [edi],bh

.done:
	pop eax
	pop edi
	ret

.newsignal:
	testmultiflags semaphoresignals
	jz .regularsig

	and [edi],bh
	inc edi
	mov al,[edi]
	and al,~8
	cmp word [currentdate],0x4e7b 	// 1975
ovar semaphoredate, -2
	jae .nosemaphores
	or al,8
.nosemaphores:
	cmp byte [curplayerctrlkey],1
	jnz .noinvert
	xor al,8
.noinvert:
	mov [edi],al
	jmp .done
	
.altersignalsbygui:
	// we want to switch signal type by gui
	mov edi,[esp+4]
	mov al, [landscape3+edi*2+1]
	mov bl, [altersignalsbygui_flags]
	test bl, 8
	jz .nosemaphoretoggle
	xor al,8	
.nosemaphoretoggle:
	and byte [landscape6+edi], ~8
	test bl, 16
	jz .nopbstoggle
	or byte [landscape6+edi],8
.nopbstoggle: 	
	and bl, 110b
	and al, ~110b
	or al, bl
	or al, 0x81
	mov [landscape3+edi*2+1], al
	jmp .notpbs
	
.isctrl:
	// we want to switch normal=>pre=>exit=>combined=>normal

	inc edi
	mov al,[edi]
	mov bl,al
	add al,2
	and al,3*2+1
	or al,0x81
	and bl,~ (3*2)
	or al,bl
	mov [edi],al

	test al,6
	jnz .notpbs

	testflags pathbasedsignalling
	jnc .notpbs

	test byte [pbssettings],PBS_MANUALPBSSIG
	jz .notpbs

#if 0
	test byte [miscmodsflags+2],MISCMODS_NOAUTOMATICPBSBLOCKS>>16
	jz .notpbs
#endif

	mov edi,[esp+4]
//	add edi,[landscape6ptr]
	xor byte [landscape6+edi],8

.notpbs:
	// prevent pre-signal setup to be reset.  After this modification,
	// the signal function is called twice, make sure we skip the
	// resetting

	// set skipsignalmod to 2 times = 2 bits set. (3 times would be "7")
	mov byte [skipsignalmod],3

	xor bl,bl
	jmp .done
; endp modifysignals


var demolishtrackflag, db 0

// Called when a signal is removed
// In:	ESI=tile index
//	BL:0=0 if checking cost, 1 if doing it
// Out: ZF=1 if checking cost, 0 if doing it
//	DX=track layout (needed only if ZF=0)
// Sets [currrmsignalcost] to either [signalremovecost] or 0
global removesignalsetup
removesignalsetup:
	mov edx,[signalremovecost]
	mov dword [currrmsignalcost],edx

	cmp byte [demolishtrackflag],0
	jnz short .costset			// dynamite used, must remove

	cmp byte [curplayerctrlkey],1
	jnz short .costset

	// removing pre-signal setup only -- zero cost
	and dword [currrmsignalcost],byte 0

.costset:
	test bl,1	// overwritten by runindex call
	jz short .done

	movzx edx,byte [landscape5(si)]
	and dl,0xbf

	or dword [currrmsignalcost],byte 0
	jz short .removepresigsetup

// normal remove signal routine
	mov [landscape5(si)],dl
	and byte [esi+landscape2],0xf	// this must be killed in the original routine

.removepresigsetup:
	push edi
	lea edi,[nosplit landscape3+1+esi*2]
	test byte [edi],0x87
	jz short .iscleared

	and byte [edi],~ 0x87

	mov edi,esi
	call updatesquaregraphics

.iscleared:
	pop edi
	or bl,bl	// clear ZF

.done:
	ret
; endp removesignalsetup 


// Set demolishtrackflag when needed
global demolishtrackcall
demolishtrackcall:
	or byte [demolishtrackflag],1
	call dword [actionhandler]
	and byte [demolishtrackflag],0
	mov esi,ebx		// overwritten by runindex call
	ret
; endp demolishtrackcall 


// Called to determine the text when an info window is opened for train track
// In:	EDI=tile index
//	CL=GS:[DI]
// Out:	ZF=1 if done with decisions
//	AX=text number (1021=plain track, 1022=w/signals, 1023=depot)
//	ECX=text params
// Safe:-
global showtrackinfo
showtrackinfo:
	mov ax,0x1021	// regular track
	and cl,0xc0
	jnz short .hassignals
.done:
	test al,0	// set zero flag
	ret

.hassignals:
	mov al,0x23	// depot
	cmp cl,0x40
	jne short .done	// no, it's a depot

	// so there are signals.  See if it's a pre-signal setup.
	xor ecx,ecx
	testflags pathbasedsignalling
	jnc .nopbs

//	mov ecx,[landscape6ptr]
	movzx ecx,byte [landscape6+edi]
	and ecx,8

.nopbs:
	mov al,0x22	// signals
	mov ch,[nosplit edi*2+landscape3+1]
	test cx,0x8708
	jz short .done

	// we have pre-signals
	mov al,ch
	sets ch		// ch=1 if manual

	shr cl,2
	or cl,ch
	mov ch,0

	and eax,byte 0x6
	jnz short .notplain

	// show plain signals only if they were set manually
	or cl,cl
	jnz short .notplain

	// automatic plain signals -> show normally
	mov ax,0x1022
	jmp .done

.notplain:
	add cx,ourtext(presigautomatic)
	shl ecx,16	// store that in the higher 16 bits

			// lower 16 bits=what signal type
	shr eax,1
	lea cx,[ourtext(wplainsignals)+eax]
	mov ax,ourtext(withsignals)
	jmp .done
; endp showtrackinfo 


// Called when train enters a depot
// which calls the track construction handler
// need to prevent automatic presignals from
// getting reset
//
// in:
// out:
// safe:
global enterdepot
enterdepot:
	mov byte [skipconstruction],3	// skip two construction call checks

	// replaced by the fragment
	mov di,bx
	shr esi,1
	ret
; endp enterdepot 
