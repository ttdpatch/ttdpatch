
// Various tools needed
// e.g. ctrl key checking

#include <std.inc>
#include <flags.inc>
#include <proc.inc>
#include <textdef.inc>
#include <human.inc>
#include <patchdata.inc>
#include <veh.inc>
#include <misc.inc>
#include <systexts.inc>
#include <ptrvar.inc>
#include <player.inc>

extern MessageBoxW,addexpenses,clearindustrygameids,clearindustryincargos
extern clearpersistenttexts,companystatsclear,companystatsptr
extern consistcallbacks,curplayerctrlkey,deftwocolormaps,didinitialize
extern drawtextfn,getgroundaltitude,getsystextaddr,getttdpatchtables
extern invalidatehandle,invalidaterect,isremoteplayer,landscape6_ptr
extern landscape6clear,landscape6init,landscape7_ptr,landscape7clear
extern landscape7init,lastdetachedveh,lasthousedataid,lastindustiledataid
extern mainstringtable,newshistclear,newshistinit,newshistoryptr
extern orighumanplayers,patchflags,randomfn,recalchousecounts
extern searchcollidingvehs,specialtext1,station2clear,station2init
extern stationarray2ptr,tmpbuffer1,ttdpatchactions,ttdtexthandler
extern varheap,exitcleanup,player2clear,player2array


#define __no_extern_vars__ 1
#include <win32.inc>

	// Data initialized by the loader (must not be placed in the fake BSS section)

	align 4
var heapptr, dd 0		// pointer to linked list of heap structures
var heapstart, dd 0		// start of unused heap after initialization
#if WINTTDX
var kernel32hnd, dd -1		// handle for KERNEL32 DLL
#else
var ttdmemsize, dd 0		// size of TTD memory
#endif

	// checks if a ctrl key is pressed
	// in:	on stack, above CTRL bit(s)
	// out: zf is pressed, nz if not
global ctrlkeystate
ctrlkeystate:
	push ecx

	test byte [esp+8],CTRL_ANY
	jnz short .ishuman	// any player is ok

	push dword [esp+8]
	call ishumanplayer
	jnz short .haveit	// computer players never press their Ctrl key

.ishuman:
	test byte [esp+8],CTRL_MP
	jnz short .issingleplayer

	// in multiplayer, Ctrl is disabled
	cmp byte [numplayers],1
	jne short .haveit

.issingleplayer:
	mov ecx,keypresstable+0x80	// make offsets fit in a byte

#if WINTTDX
	cmp byte [ecx-0x80+KEY_Ctrl],0
#else
	cmp byte [ecx-0x80+KEY_LCtrl],0
	jz short .haveit
	cmp byte [ecx-0x80+KEY_RCtrl],0
#endif
.haveit:
	pop ecx
	ret 4
; endp ctrlkeystate


	// checks if the current player is a human player
	// in:	PL_xxx flags on stack
	// out:	ecx with the current player if PL_RETURNCURRENT is set
	// 	nz if not a human player
	//	zf if a human player.  In that case, we also
	//	clear carry if first human player, set carry if second one
global ishumanplayer
proc ishumanplayer
	arg playertype
	local player

	_enter

	push eax
	push ecx

	movzx eax,byte [curplayer]

	test byte [%$playertype],PL_PLAYER
	jz short .notspecific

	mov al,[%$playertype+1]

.notspecific:
#if WINTTDX
	cmp byte [numplayers],2
	jb .notmulti
	testflags enhancemultiplayer
	jc short .newmulti	// this still breaks if "manage" is enabled in MP
.notmulti:
#endif

	mov ecx,[human1]

	test byte [%$playertype],PL_NOTTEMP
	jz short .curhuman

	// humans temporarily managing an AI company don't count
	// i.e. if cl!=human1 or ch!=human2, remove from the list

	cmp cl,[landscape3+ttdpatchdata.orgpl1]
	je short .nottemp1

	mov cl,0xf0

.nottemp1:
	cmp ch,[landscape3+ttdpatchdata.orgpl2]
	je short .nottemp2

	mov ch,0xf0

.nottemp2:

.curhuman:
	mov [%$player],ecx

	mov cx,0xf0f0
	test byte [%$playertype],PL_ORG
	jz short .notorg

	// also wants original human companies
	mov ecx,[landscape3+ttdpatchdata.orgpl1]
	and cx,0x7f7f

.notorg:
	cmp al,cl
	je short .knowit
	cmp al,byte [%$player]
	je short .knowit

	cmp al,ch
	je short .player2

	cmp al,[%$player+1]

.player2:
	stc

.knowit:
	pop ecx
	lahf
	test byte [%$playertype],PL_RETURNCURRENT
	jz short .notreturn

	movzx ecx,al

.notreturn:
	sahf
	pop eax
	_ret

#if WINTTDX
.newmulti:
	cmp al,7
	ja .knowit	// player numbers above 7 can't be human. (ja means zf is clear)

	mov ecx,[isremoteplayer]
	push eax
	mov al,[human1]
	bts ecx,eax
	pop eax

	test byte [%$playertype],PL_ORG
	jz .noorig
	or cl,[orighumanplayers]
.noorig:
	test byte [%$playertype],PL_NOTTEMP
	jz .tempisok
	and cl,[orighumanplayers]
.tempisok:

	bt ecx,eax
	setnc cl
	test cl,cl
	jnz .knowit
	cmp al,[human1]
	setnz cl
	shr cl,1	// cl will become zero -> zf set again; cf becomes clear if al=human1, set otherwise
	jmp short .knowit
#endif

endproc // ishumanplayer

// check only real human player
// this is to save 2 bytes (PUSH BYTE PL_DEFAULT) per each instance of the most common check
global isrealhumanplayer
isrealhumanplayer:
	push byte PL_DEFAULT
	call ishumanplayer
	ret


// Handle memory allocation at the end of the heap(s)
// Memory allocated using this function cannot be easily freed,
// however the most recent allocation can be resized
// Use this function at the initialization stage *only*

// in:	on stack: requested size
// out:	on stack: pointer (will be DWORD aligned)
//	will abort loading if out of memory
global malloccrit
malloccrit:
global malloc
malloc:
	pusha

	mov eax,[esp+0x24]
	add eax,byte 3
	and eax,byte ~3

	mov esi,[heapptr]

.trynext:
	cmp [esi+heap.left],eax
	jae .gotit

	mov esi,[esi+heap.next]
	test esi,esi
	jnz .trynext
	jmp short .allocmore

.gotit:
	mov [lastheapptr],esi
	mov [lastmallocsize],eax
	sub [esi+heap.left],eax
	xchg eax,[esi+heap.ptr]
	add [esi+heap.ptr],eax
	mov [lastmallocofs],eax

.return:
	mov [esp+0x24],eax

	popa
	ret

.allocmore:
#if !WINTTDX
	// fail if TTD is running already (can't reallocate memory)
	test byte [didinitialize],2
	jnz .fail

	// try making DS larger
	push eax
	push es
	mov ebx,ds
	mov es,ebx
	lsl ebx,ebx
	inc ebx
	shr ebx,12
	add ebx,32		// request memory in 32 4K page chunks = 128KB
	mov ah,0x4a
	int 0x21		// re-size allocated memory
	pop es
	jc .fail

.ok:
	pop eax
	mov esi,[varheap]
	mov ebx,ds
	lsl ebx,ebx
	inc ebx
	sub ebx,[esi+heap.ptr]
	mov [esi+heap.left],ebx
	jmp .trynext

#else

	push eax
	mov ecx,2		// try reserving not more than twice
	mov esi,[varheap]
	test esi,esi
	jz .reserve

.commit:
	// commit in 128 KB chunks

	mov eax,[varheapsize]
	add eax,32*4096
	mov ebx,eax
	push ecx

	push byte 4		// PAGE_READWRITE
	push 0x1000		// AllocateType MEM_COMMIT
	push eax		// dwSize
	push esi		// Address
	call dword [VirtualAlloc]
	pop ecx
	test eax,eax
	jz short .reserve

	cmp dword [esi+heap.ptr],esi
	ja short .notnew

	lea eax,[esi+heap_size]
	mov [esi+heap.ptr],eax
	or dword [esi+heap.left],byte -heap_size

.notnew:
	mov [varheapsize],ebx
	add dword [esi+heap.left],32*4096
	pop eax
	jmp short .trynext

.reserve:

	// find end of heap chain to append this chunk to
	mov eax,[heapptr]

.next:
	xchg eax,esi
	mov eax,[esi+heap.next]
	test eax,eax
	jnz short .next

	// now esi=last valid heap structure

	// reserve in 2 MB chunks
	push ecx

	push byte 4		// PAGE_READWRITE
	push 0x2000		// AllocateType MEM_RESERVE
	push 0x200000		// Reserve (without committing) a 2 MB chunk
	push 0			// Address
	call dword [VirtualAlloc]
	pop ecx
	test eax,eax
	jz short .fail

	mov [esi+heap.next],eax
	mov [varheap],eax
	and dword [varheapsize],byte 0
	xchg eax,esi
	loop .commit		// don't try committing more than twice

#endif

.fail:
	jmp outofmemoryerror
#if 0
	stc
	pop eax
	sbb eax,eax
	jmp .return
#endif

uvard varheapsize	// current varheap chunk size in bytes

// same as above but guarantee memory is set to zero
global calloccrit
calloccrit:
global calloc
calloc:
	pusha
	push dword [esp+0x24]
	call malloc
	pop edi
//	jc .fail

	mov ecx,edi
	xchg ecx,[esp+0x24]
	shr ecx,2
	xor eax,eax
	rep stosd
	popa
	ret
#if 0
.fail:
	sbb eax,eax
	mov [esp+0x24],eax
	popa
	ret
#endif

// Change the allocated size of the most recent (only!) malloc result
//
// in:	on stack:
//	starting address (as returned by malloc)
//	new size (must be smaller, or fit within the current allocation block)
// out:	stack cleared up
//	carry clear if successful
//	carry set if address wasn't last malloc, or size could not be
//		accomodated; in this case nothing at all is done
realloc:
	push eax
	push esi
	mov eax,[esp+16]
	cmp eax,[lastmallocofs]
	stc
	jne .done

	mov esi,[lastheapptr]
	mov eax,[esp+12]
	add eax,3
	and eax,byte ~3
	sub eax,[lastmallocsize]
	jb .sizeok		// making size smaller
	cmp [esi+heap.left],eax
	jb .done

.sizeok:
	sub [esi+heap.left],eax
	add [esi+heap.ptr],eax
	clc			// carry was set if eax was negative

.done:
	pop esi
	pop eax
	ret 8

uvard lastheapptr
uvard lastmallocofs
uvard lastmallocsize


// Force the whole screen to be redrawn
global redrawscreen
redrawscreen:
	pusha
	xor ax,ax
	mov dx,640
ovar .maxx, -2,$,redrawscreen
	xor bx,bx
	mov bp,480
ovar .maxy, -2,$,redrawscreen
	call dword [invalidaterect]
	popa
	ret
; endp redrawscreen


// Find the table and offset of a TTD text ID
//
// in:	AX=text id (can be specific or general)
//	doesn't work for text IDs 7800..7FFF (refer to customstringarray for those)
// out:	EAX=table ptr
//	EDI=text ptr
global gettextandtableptrs
gettextandtableptrs:
	call gettextintableptr
	mov edi,[eax+edi*4]
	jnc .notadded
	add edi,eax
.notadded:
	ret

// same as above, except:
// out:	EDI=offset to text ptr
//	carry set if EAX must be added to text ptr
global gettextintableptr
gettextintableptr:
	mov edi,eax
	and edi,0x7ff
	// fall through to gettexttableptr

// same as above, except it does not return offset to text ptr and does not use EDI
global gettexttableptr
gettexttableptr:
	movzx eax,ah
	and al,0xF8
	jz .gentable

	cmp al,0xC0
	jae .ttdpatchtables

	sub al,8

	push ebx
	mov ebx,eax
	shr ebx,3
	movzx ebx,byte [texttableoffsets+ebx]

	mov eax,[ophandler+eax]
	mov eax,[eax+8]
	mov eax,[eax+ebx]
	pop ebx
	// carry is clear here
	ret

.gentable:
	mov eax,[mainstringtable]
	// and here too
	ret

.ttdpatchtables:
	shr eax,1
	jmp [getttdpatchtables+eax-0x18*4]
; endp gettexttableptr

var texttableoffsets, db 4,4,4,18,4,18,4,4,4,4,4,4,4,16,-128,4,4,4,4,4,4,4

// finds a vehicle on a given tile
// I don't know which one it returns if there are multiple vehicles on the tile.
// in: di: tile XY coords
// out: edi: pointer to vehicle data or -1 if there are no vehs
// zf set if no vehicles are found
global findvehontile
findvehontile:
	pusha
	mov dword [foundveh],-1
	mov [vehcoords],di
	mov eax,addr(findvehontile_helper)
	call dword [searchcollidingvehs]
	popa
	mov edi,[foundveh]
	cmp edi,byte -1
	ret

findvehontile_helper:
	push eax
	mov ax,[vehcoords]
	cmp ax,[esi+veh.XY]
	jnz .exit
	movzx eax, word [esi+veh.engineidx]
	shl eax,vehicleshift
	add eax,dword [veharrayptr]
	mov [foundveh],eax
.exit:
	pop eax
	ret

uvarw vehcoords
uvard foundveh
uvard numvehshared

// Decides whether a schedule is shared (referred by more than one vehicle)
// in: ebp: pointer to schedule
// out: cf set if shared
global isscheduleshared
isscheduleshared:
	push eax
	and dword [numvehshared],0
	mov eax,[veharrayptr]
	
.checkvehicle:
	cmp byte [eax+veh.class],0
	je .nextveh
	cmp ebp,[eax+veh.scheduleptr]
	jne .nextveh

	inc dword [numvehshared]

.nextveh:
	sub eax,byte -vehiclesize
	cmp eax,[veharrayendptr]
	jb .checkvehicle

	cmp dword [numvehshared],2
	cmc
	pop eax
	ret

// the following procs all serve to maintain the veh.engineidx variable

global createvehentry
createvehentry:
	push eax
	mov word [esi+veh.nextunitidx],-1
	mov ax,[esi+veh.idx]
	mov [esi+veh.engineidx],ax
// Don't generate random numbers for pseudo-vehicles because they might not be created
// for both players in multiplayer. Calling randomfn would cause loss of synch in this case.
	test bl,2
	jnz .dontrandom
	call dword [randomfn]
	mov [esi+veh.random],al
.dontrandom:
	xor eax,eax
	mov [esi+veh.newrandom],al
	mov [esi+veh.currorderidx],al
	mov [esi+veh.refitcycle],al
	mov [esi+veh.modflags],ax
	mov eax,[esi+veh.veh2ptr]
	and dword [eax+veh2.colormap],0
	pop eax
	ret

// attach new vehicle to previous vehicle of consist
global checkattachveh
checkattachveh:
	test byte [esp+14],8
	jz attachveh
	ret 8

global attachveh
proc attachveh
	arg new,previous

	_enter
	push eax
	push esi

	// old+veh.nextunitidx = new+veh.idx
	// new+veh.engineidx = old+veh.engineidx

	mov esi,[%$new]
	mov ax,[esi+veh.idx]

	mov esi,[%$previous]
	mov [esi+veh.nextunitidx],ax

	mov ax,[esi+veh.engineidx]

	mov esi,[%$new]
	mov [esi+veh.engineidx],ax

	call consistcallbacks

	pop esi
	pop eax
	_ret
endproc

// remove vehicle from consist
// in:	esi->vehicle to remove
//	edi->vehicle before esi
// out:	eax->last vehicle removed
// safe:ax
global detachveh
detachveh:
	mov ax,[esi+veh.idx]

	push esi
	push edi
	mov edi,esi
.nextartic:
	mov [edi+veh.engineidx],ax
	mov esi,edi
	movzx edi,word [edi+veh.nextunitidx]
	cmp di,byte -1
	je .gotit

	shl edi,7
	add edi,[veharrayptr]
	cmp byte [edi+veh.currorderidx],0xff
	je .nextartic

.gotit:
	pop edi

	movzx eax,word [esi+veh.nextunitidx]
	mov [edi+veh.nextunitidx],ax

	cmp ax,byte -1
	je .islast

	shl eax,7
	add eax,[veharrayptr]
	mov [lastdetachedveh],eax

.islast:
	mov eax,esi

	mov esi,edi
	call consistcallbacks
	pop esi
	ret

// insert vehicle esi into consist after edi
// in:	 ax=new vehicle idx
//	esi=new vehicle
//	edi=vehicle to be inserted after
// safe:ax
global insertveh
insertveh:
	push edx
	push eax
	push esi

	mov edx,esi
.next:
	mov ax,[edi+veh.engineidx]
	mov [edx+veh.engineidx],ax
	mov byte [edx+veh.subclass],2

	mov eax,edx
	movzx edx,word [edx+veh.nextunitidx]
	cmp dx,byte -1
	je .gotit

	shl edx,7
	add edx,[veharrayptr]
	cmp byte [edx+veh.currorderidx],0xfe
	jae .next

.gotit:
	mov edx,eax	// now edx=last vehicle inserted

	mov eax,edi
.next2:
	mov edi,eax
	movzx eax,word [eax+veh.nextunitidx]
	cmp ax,byte -1
	je .gotit2

	shl eax,7
	add eax,[veharrayptr]
	cmp byte [eax+veh.currorderidx],0xfe
	jae .next2

.gotit2:
	mov ax,[esi+veh.idx]
	xchg ax,[edi+veh.nextunitidx]	// attach esi to edi
	mov [edx+veh.nextunitidx],ax	// attach orig. edi follower to esi

	call consistcallbacks

	pop esi
	pop eax
	pop edx
	ret

// called after selling first wagon in "unattached" row of depot
// need to set new first wagon to be engine of all that follow
//
// in:	ebx=new first idx<<7
// out:	ebx->new first veh
// safe:ax cx di
global sellwagonnewleader
sellwagonnewleader:
	add ebx,[veharrayptr]
	push ebx
	mov ax,[ebx+veh.idx]
.setnext:
	mov [ebx+veh.engineidx],ax
	movzx ebx,word [ebx+veh.nextunitidx]
	cmp bx,byte -1
	je .done
	shl ebx,7
	add ebx,[veharrayptr]
	jmp .setnext
.done:
	pop ebx
	ret

// end of procs that serve to maintain the veh.engineidx variable


// Get the first day of a given year (with 32-bit date range support)
// in:	EAX=year-1920
// out:	EBX=date
//	CF set if overflow
// destroys EAX,ECX,EDX
global yeartodate
yeartodate:
	xor ecx,ecx
	mov cl,100
	xor edx,edx
	div ecx				// EAX = year/100; EDX = year%100

	shld ecx,eax,30			// ECX = year/400 (note: ECX was 100, i.e. the low 2 bits were zero)
	imul ebx,ecx,146097		// accumulate days in EBX
	jc short .quit

	and eax,byte 3
	imul ecx,eax,36525
	cmp dl,80			// 2000, 2100, 2200 etc.
	ja short .leapc_adjust
	dec eax
	js short .leapc_adjusted
.leapc_adjust:
	sub ecx,eax
.leapc_adjusted:
	add ebx,ecx
	jc short .quit

	mov eax,edx
	shr edx,2
	imul edx,1461
	and al,3
	imul ecx,eax,366
	add edx,ecx
	dec eax
	js short .leapadjusted
	sub edx,eax
.leapadjusted:
	add ebx,edx

.quit:
	ret


// Initialize the vehicle array, and additional TTDPatch data that
// needs initializing both when starting a new random game
// or after quitting a game
//
// in:	esi->veharray
//	ecx=veharray size
//
global initializeveharray
initializeveharray:
	pusha

	mov al,0
	mov edi,esi
	rep stosb

	// work that needs to be done to initialize new game goes here

	cmp dword [landscape6_ptr],0
	jle .no_l6
	call landscape6clear	// new game -> init landscape6 if present
	call landscape6init
.no_l6:
	cmp dword [landscape7_ptr],0
	jle .no_l7
	call landscape7clear	// new game -> init landscape7 if present
	call landscape7init
.no_l7:
	cmp dword [newshistoryptr],0
	je .no_newshist
	call newshistclear
	call newshistinit
.no_newshist:
	mov byte [lasthousedataid],0
	mov byte [lastindustiledataid],0
	call clearindustrygameids
	call clearindustryincargos
	cmp dword [stationarray2ptr],0
	je .no_station2
	call station2clear
	call station2init
.no_station2:
	cmp dword [companystatsptr],0
	je .no_companystats
	call companystatsclear
.no_companystats:
	cmp dword [player2array],0
	jle .noplayer2
	call player2clear
.noplayer2:

	call clearpersistenttexts

	testflags newhouses
	jnc .nohousecountreset
	call recalchousecounts
.nohousecountreset:

	popa
	ret
uvard initializeveharraysizeptr


//
// --- End of TTD data management procs ---
//


// System error handlers
// (display message via system API rather than inside TTD)

#if WINTTDX
var TTDPatch_progname, db "TTDPatch",0
var TTDPatch_prognameW, dw 'T','T','D','P','a','t','c','h',0
var TTDPatch_error_nodetails, db "[Cannot display error details]",0

// Auxiliary Windows procedure:
// call MessageBoxW, or display an error if unavailable
global callMessageBoxW
callMessageBoxW:
	pop dword [callMessageBoxW_retaddr]
	mov eax,[MessageBoxW]
	test eax,eax
	jz .bad
	call eax
	test eax,eax
	jz .bad
	push dword [callMessageBoxW_retaddr]
	ret

.bad:
	mov edx,TTDPatch_error_nodetails

.fallthrough:

uvard callMessageBoxW_retaddr

#else
var TTDPatch_sysmsg_leader, db "TTDPatch: ",'$'
var TTDPatch_sysmsg_trailer, db 13,10,'$'

// Auxiliary DOS procedure:
// display a null-terminated msg pointed to by EAX on the stdout
// preserves: nothing
displaysysmsg:
	call .notrailer

.trailer:
	mov edx,TTDPatch_sysmsg_trailer
	mov ah,9
	int 0x21

.done:
	ret

.notrailer:
	// display the TTDPatch prefix
	push eax
	mov edx,TTDPatch_sysmsg_leader
	mov ah,9
	int 0x21
	pop esi

.unsuffixed:			// this one requires ESI->text
.loop:
	lodsb
	or al,al
	jz .done
	xchg eax,edx
	mov ah,2
	push esi		// for safety
	int 0x21
	pop esi
	jmp .loop

// Auxiliary DOS procedure: cleanup before exiting TTD if needed
// preserves: nothing
dopreexitcleanup:
	test byte [didinitialize],2
	jz .nocleanupneeded

	call [exitcleanup]

.nocleanupneeded:
	ret

#endif

// Display a critical error message (static, not translated) and terminate TTD
// in: EDX -> string to display (should be in the OS's native code page)
global criticalerror
criticalerror:
#if WINTTDX
%ifndef PREPROCESSONLY
	%if $<>callMessageBoxW.fallthrough
		%error "Fall-through broken in callMessageBoxW"
	%endif
%endif
	push byte 0x10		// MB_ICONSTOP
	push TTDPatch_progname
	push edx
	push byte 0
	call [MessageBoxA]	// MessageBoxA

global abortttd
abortttd:
	test byte [didinitialize],2
	jnz .running

	// TTD has not created its window yet
	push 3			// uExitCode
	call [ExitProcess]

.running:
	// TTD is already running, perform a standard quit
	mov esi,0x20000
	mov dl,2
	mov bl,1
	mov ebp,[ophandler+7*8]
	call [ebp+0x10]
	ud2		// we should never get here

#else
	push edx

.msgonstack:
	call dopreexitcleanup
	pop eax
	call displaysysmsg

	mov ax,0x4c03		// exit code 3 = TTDPatch error
	int 0x21

#endif

// Display an error message and terminate TTD
// in: AL = message index (systext_XXXX)
systemerror:
	call getsystextaddr

#if WINTTDX
	push 0x10			// MB_ICONSTOP
	push TTDPatch_prognameW
	push eax
	push 0
	call callMessageBoxW

	jmp abortttd

#else
	push eax
	jmp criticalerror.msgonstack

#endif

// Display a warning message and let user continue or abort
// in: AL = message index (systext_XXXX)
// NOTE: Use at the initialization stage ONLY!
global systemwarning
systemwarning:
	call getsystextaddr

#if WINTTDX
	push 0x31			// MB_ICONEXCLAMATION + MB_OKCANCEL
	push TTDPatch_prognameW
	push eax
	push 0
	call callMessageBoxW

	dec eax				// cmp eax,IDOK
	jz .done

	push 127			// uExitCode
	call [ExitProcess]

#else
	call displaysysmsg
	mov al,systext_LANG_PRESSESCTOEXIT
	call getsystextaddr
	xchg eax,esi
	call displaysysmsg.unsuffixed

	mov ah,8
	int 0x21

	push eax
	call displaysysmsg.trailer
	pop eax
	cmp al,27
	jne .done

	mov ax,0x4c7f		// exit code 127 = user break
	int 0x21
#endif
.done:
	ret


// Abort TTD with 'out of memory' message
global outofmemoryerror
outofmemoryerror:
	mov al,systext_LANG_PMOUTOFMEMORY
	jmp systemerror


#if 0
// 'Critical' memory allocation: abort TTD if failed
// for the calling convention see malloc above
malloccrit:
global malloccrit
malloccrit:
	push dword [esp+4]
	call malloc
	pop dword [esp+4]
	jc outofmemoryerror
	ret

global calloccrit
calloccrit:
	push dword [esp+4]
	call calloc
	pop dword [esp+4]
	jc outofmemoryerror
	ret
#endif

// Convert location in AX,CX into tile XY offset in ESI
// (assume AX and CX are within the landscape range, i.e. 0x000..0xFFF)
global locationtoxy
locationtoxy:
	movzx esi,cx
	and esi,byte ~15
	shl esi,8
	or si,ax
	shr esi,4
	ret


// Get ground altitude, but preserve all registers except the result in (E)DX
// in:	AX,CX = X,Y location
// out:	DL = altitude (=height<<3)
//	DH = 1 if under bridge
global getgroundalt
getgroundalt:
	push esi
	call [getgroundaltitude]
	pop esi
	ret


// Add expenses to a specific company's data
// in:	EBX = amount to subtract from the player's cash
//	AL = player
//	AH = expense type (if ...withtype form is used, else set currentexpensetype)
// out:	AL = current player
global addexpensestoplayerwithtype
addexpensestoplayerwithtype:
	mov [currentexpensetype],ah
addexpensestoplayer:
	xchg al,[curplayer]
	push edx
	call [addexpenses]
	pop edx
	mov [curplayer],al
	ret


// New handler for class 0B actions, used to call new TTDPatch actions
global newclass0Bactionhandler
newclass0Bactionhandler:
	shr esi,14
	jmp dword [ttdpatchactions+esi]


// Called after current dirty screen area has been redrawn,
// see if we need to re-redraw some things
//
// in:	---
// out:	---
// safe:?
global redrawdone
redrawdone:
	mov word [screenrefreshmaxy],0	// overwritten

	cmp byte [numpostredrawinvals],0
	jne .domoreredraws
	ret

.domoreredraws:
	pusha
	xor ecx,ecx
	xchg cl,[numpostredrawinvals]
	mov esi,postredrawdata
.next:
	lodsw
	mov ebx,eax
	lodsw
	call [invalidatehandle]
	loop .next
	popa
	ret

uvarb numpostredrawinvals
%define maxnumpostredrawinvals 4
uvard postredrawdata,maxnumpostredrawinvals

// Called to add another postredraw handle
//
// in,out:	same as invalidatehandle
global postredrawhandle
postredrawhandle:
	pusha
	movzx ecx,byte [numpostredrawinvals]
	cmp ecx,maxnumpostredrawinvals
	jae .done

	mov [postredrawdata+ecx*2],bx
	mov [postredrawdata+ecx*2+2],ax

	inc ecx
	mov [numpostredrawinvals],cl

.done:
	popa
	ret

uvarb curbasecostmult,49
uvarb basecostmult,49

// apply the base cost multipliers
// in:	edx=+1 to apply, -1 to unapply
global setbasecostmult
setbasecostmult:
	pusha
	mov ebp,costs
	xor esi,esi
	mov edi,basecostmult
	test edx,edx
	jns .next
	sub edi,byte basecostmult-curbasecostmult
.next:
	movsx ecx,byte [edi+esi]
	mov [curbasecostmult+esi],cl
	sub ecx,8
	jz .donext

	mov eax,[ebp]
	mov ebx,[ebp+2]		// really only want word at edi+4 in ebx(16:31)

	imul ecx,edx
	test ecx,ecx
	js .negative


.check32:
	cmp ecx,32
	jb .once

	mov eax,ebx
	xor ebx,ebx
	sub ecx,32
	jmp .check32

.once:
	shld eax,ebx,cl
	shl ebx,cl
	jmp short .store

.negative:
	neg cl

.checkm32:
	cmp cl,32
	jb .onceneg

	mov ebx,eax
	xor eax,eax
	sub cl,32
	jmp .checkm32

.onceneg:
	shrd ebx,eax,cl
	sar eax,cl

.store:
	mov [ebp+2],ebx		// value from ebx(0:15) at edi+2 will be overwritten
	mov [ebp],eax		// by this instruction

.donext:
	inc esi
	add ebp,6
	cmp esi,49
	jb .next

	popa
	test edx,edx
	js setbasecostmultdefault
	ret

global setbasecostmultdefault
setbasecostmultdefault:
	pusha
	mov al,8
	xor edi,edi
.next:
	mov [curbasecostmult+edi],al	// can't do rep stosb because ES may be wrong
	inc edi
	cmp edi,49
	jb .next
	popa
	ret

global newclassdinithnd
newclassdinithnd:
	call $+5
ovar .oldfn,-4,$,newclassdinithnd

	call setbasecostmultdefault
	ret

// load a byte from [esi], and then a word if that byte was FF
// adjusts esi unless the _noadjust version is used
//
// in:	esi->data
// out:	eax=value (byte or word)
//	esi->following data (unless the _noadjust version is used)
// uses:---
global getextendedbyte
getextendedbyte:
	xor eax,eax
	lodsb
	cmp al,0xff
	jne .done

	lodsw

.done:
	ret

global getextendedbyte_noadjust
getextendedbyte_noadjust:
	movzx eax,byte [esi]
	cmp al,0xff
	jne .done
	mov ax,[esi+1]
.done:
	ret

//IN: CX,DX = screen X,Y position
//    AL = text color
//    EDI -> screen update block descriptor
//    BX = text ID
//    BP = max length
global drawtextlen
drawtextlen:
	push ax
	push cx
	push dx
	push edi
	mov edi, tmpbuffer1
	mov ax, bx
	call [ttdtexthandler]
	pop edi
	pop dx
	pop cx
	pop ax

	pusha
	mov esi, tmpbuffer1
	xor eax, eax
	movzx ebx, word [currentfont]
	mov cx, -1
.loop:
	lodsb
	or al, al
	jz .done
	cmp al, 7Bh
	jae .loop
	sub al, 20h
	jb .nochar
	add cl, [charwidthtables+ebx+eax]
	adc ch, 0
	cmp cx, bp
	ja .toolong
	jmp .loop
.nochar:
	add al, 20h
	cmp al, 0Ah
	jbe .skipnext
	cmp al, 0Eh
	jz .fontE0
	cmp al, 0Fh
	je .font1C0
	cmp al, 0Fh
	jbe .loop
	add esi, 2
	jmp .loop
	
.skipnext:
	inc esi
	jmp .loop
.fontE0:
	mov ebx, 0xE0
	jmp .loop
.font1C0:
	mov ebx, 0x1C0
	jmp .loop
	
.toolong:
	dec esi
	mov byte [esi], 0
.done:
	popa

	mov bx, statictext(special1)
	mov dword [specialtext1], tmpbuffer1
	jmp [drawtextfn]

global getwincolorfromdoscolor
getwincolorfromdoscolor:
	cmp al,10
	jb .remapfirstten
	cmp al,245
	jb .done
	cmp al,254
	ja .done
	sub al,245-217
.done:
	ret

.remapfirstten:
	mov al,[addr(.dostowincolmap)+eax]
	ret

.dostowincolmap:
	db 0,215,216,136,88,106,32,33,40,245

// called when changing company color scheme
//
// in:	dh=new colour index
//	otherwise usual action variables
//
global changecolorscheme
changecolorscheme:
	cmp byte [curplayerctrlkey],0
	je .regular

	cmp dword [deftwocolormaps],0
	jne .second

.regular:
	test bl,1
	jz .checkonly
	push eax
	call resetcolmapcache
	pop eax
.checkonly:
	call $
ovar .origfn,-4,$,changecolorscheme
	ret

	// set second company colour
.second:
	test bl,1
	jz .done	// always succeeds (need not be unique)
	cmp dword [player2array],0
	jle .done	// no player 2 array??
	movzx esi,byte [curplayer]
	imul esi,0+player2_size
	add esi,[player2array]
	mov [esi+player2.col2],dh
	or byte [esi+player2.colschemes],1<<COLSCHEME_HAS2CC
	call resetcolmapcache
	call redrawscreen
.done:
	xor ebx,ebx
	ret

global resetcolmapcache
resetcolmapcache:
	mov esi,[veharrayptr]
.next:
	mov eax,[esi+veh.veh2ptr]
	and dword [eax+veh2.colormap],0
	sub esi,byte -veh_size
	cmp esi,[veharrayendptr]
	jb .next	
	ret
