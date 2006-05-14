//
// init.asm
//
// Contains all the stuff that isn't an actual patch, i.e. setup routines
// and initializations etc.
//

// To prevent the div overflow handlers being made externs
#define realoverflowreturn _realoverflowreturn_
#define overflowhandler _overflowhandler_
#include <defs.inc>
#undef realoverflowreturn
#undef overflowhandler

#include <var.inc>
#include <flags.inc>
#include <textdef.inc>
#include <proc.inc>
#include <vehtype.inc>
#include <win32.inc>
#include <misc.inc>
#include <version.inc>
#include <systexts.inc>
#include <ptrvar.inc>
#include <ttdvar.inc>
#include <smartpad.inc>

// prevent calldofindstring and dopatchcode from being declared extern
#define __no_extern__ 1
#include <frag_def.inc>

extern __pbss_size_dwords,__pbss_start,__psbss_size_dwords,__psbss_start
extern criticalerror,currentversion,flagdatasize,grfstage,grfswitchparam
extern grfswitchparamlist,hexnibbles,inforeset,initveh2,long_flags_end
extern numgrfswitchparam,patchflagsfixedmap,patchflagsfixedmaplength
extern patchflagsunimaglevmode,patchlist,protectedstart,ptr_ofs,relocofsptr
extern setexceptionhandler,systemwarning,texthandler
extern ubyte_flags_end,versiondataptr,winloaderbegin.shmaddr,winloaderbegin.data
extern word_flags_end,flag_data_size,ttdvar_base_ptr
extern patchflagsunimaglevmode_d8,patchflagsunimaglevmode_a7,patchflagsunimaglevmode_a7_s3_n
extern originalgpfcode,gpfhookaddr,catchgpf,vehicledatafactor
extern isengine,newveharraysize,__image_base__
extern MessageBoxW,cleardata,didinitialize,expswitches,findstring,gdi32hnd
extern languageid,loaderdata,miscmodsflags
extern patchflags,patchflagsfixed,ttdmemsize,setvehiclearraysize
extern startflagvars,unimaglevmode
extern user32hnd,vehsorttable,heapstart,heapptr
extern oldveharraysize,varheap,Sleep
extern initourtextptr,initnoregist
extern hexdwords

ext_frag oldfixcommandaddr

#if DEBUG
uvard realoverflowreturn

global overflowhandler
overflowhandler:
	CALLINT3
	jmp [realoverflowreturn]

#endif


// First, the initializing code

// initialize the isengine bit array (see vars.ah)
// has to be redone if the rail vehicles set is modified
// uses: EAX,ECX,EDI
// assumes ES==DS
global initisengine
initisengine:
	xor eax,eax
	mov edi,isengine
	xor ecx,ecx
	mov cl,(totalvehtypes+31)/32
	rep stosd

.nextvehicle:
	cmp al,ROADVEHBASE
	jae .isengine
	cmp word [trainpower+eax*2],byte 0
	jz short .notanengine
.isengine:
	bts [edi-((totalvehtypes+31)/32)*4],eax
.notanengine:
	add al,1
	jnc .nextvehicle
		// there are 116 rail vehicles, the remaining 140 are always set
	ret
; endp initisengine


// Initialize the vehsorttable (see vars.ah) so that all engines come before waggons
// assumes isengine valid
// uses:EAX,EBX,EDI
global initrailvehsorttable
initrailvehsorttable:
	mov ebx,isengine
	mov edi,vehsorttable
	xor eax,eax
.enginesloop:
	bt [ebx],eax
	jnc short .nextengine
	stosb
.nextengine:
	inc eax
	cmp al,NTRAINTYPES
	jb short .enginesloop

	xor eax,eax
.waggonsloop:
	bt [ebx],eax
	jc short .nextwaggon
	stosb
.nextwaggon:
	inc eax
	cmp al,NTRAINTYPES
	jb short .waggonsloop
	ret
; endp initrailvehsorttable


#if WINTTDX
// called exactly once by initialize, to do the relocations that
// can't be done by Windows because they depend on the version of
// TTD.
dorelocations:

	// find out offset of the start of the data
	xor edx,edx
;	extern oldfixcommandaddr_start,oldfixcommandaddr_len,oldfixcommandaddr_add
	stringaddress oldfixcommandaddr,1,1
;	param_call calldofindstring, addr(oldfixcommandaddr_start), oldfixcommandaddr_len, 1, 1, oldfixcommandaddr_add

.knowtheaddress:
	mov edi,[edi+1]
	sub edi,oldveharray_abs	// relocation offset
	param_call reloc, edi,ttdvar_base_ptr

	// resolve some functions we're going to need
	push aSleep
	push dword [kernel32hnd]
	call [GetProcAddress]
	or eax,eax
	jnz short .sleep_ok

.fnfail:
	mov edx,.getprocaddrfail

.jcritter:
	jmp criticalerror

.getmodhndfail:
	mov edx,.getmodhandlefail
	jmp .jcritter

.sleep_ok:
	mov [Sleep],eax

	push aUSER32
	call [GetModuleHandleA]
	mov [user32hnd],eax
	or eax,eax
	jz .getmodhndfail

	push aMessageBoxW
	push eax
	call [GetProcAddress]
	mov [MessageBoxW],eax	// allowed to fail (EAX=0)

	push aGDI32
	call [GetModuleHandleA]
	mov [gdi32hnd],eax
	or eax,eax
	jz .getmodhndfail
	ret

.getprocaddrfail: db "Critical error: GetProcAddress() failed",0
.getmodhandlefail: db "Critical error: GetModuleHandleA() failed",0

; endp dorelocations

var aSleep, db "Sleep",0
var aUSER32, db "USER32",0
var aMessageBoxW, db "MessageBoxW",0
var aGDI32, db "GDI32",0

#endif


// do relocations of a pointer variable (or ttdvar in WINTTDX)
//
// usage:	param_call reloc address, varname_ptr
//
// address is the address to be stored in varname_ptr, and which accesses
//	to varname are relative to
// varname_ptr is the real variable, where the address is stored

global reloc
reloc:
	// CALLINT3
	pusha
	mov esi,[esp+0x24]
	mov edi,[esp+0x28]
#if DEBUG
	test esi,esi
	jg .ok
	ud2			// forgot _ptr when pushing ptrvar (second parameter)
.ok:
#endif
	sub edi,[esi]		// this makes it safe to call reloc again if ptrvar changes
	mov esi,[esi+4]
	add esi,[relocofsptr]	// offset to var.reloc in reloc.inc
	add esi,[esi]		// add offset to actual relocation start
	mov eax,__image_base__	// offset of protectedfunc
	xor ebx,ebx

.nextset:			// do relocations in sets of blocks
	lodsb			// load code = skipblock + (nument<<4)
	movzx ecx,al		// a block is 256 bytes
	jecxz .done

	and al,15		// skipblock
	cmp al,15		// special code to skip many blocks
	jne .notskipping	// in which case code = 0xf + numblocks (a multiple of 16)
	xor al,cl		// remove lower bits, add numblocks from cl
	xor ecx,ecx		// and there are no actual relocations
.notskipping:
	mov bh,al
	add eax,ebx		// ebx=0000xx00 where xx=skipblock
	shr ecx,4		// nument
	jz .nextset

.nextreloc:
	lodsb			// load only lowest 8bits, rest is the block
	add [eax],edi
	loop .nextreloc
	jmp .nextset

.done:
	popa
	ret 8

// this is called just after this code fragment has been copied
global initialize
initialize:
#if DEBUG>1
	CALLINT3
#endif

	bts dword [didinitialize],0
	jc short .notagain

	cmp dword [currentversion+version.ttdversion],byte -1
	jne short .useversiondata	// default is not to search

		// use known addresses only if we have them (Duh!)
	add dword [findstring],byte addr(dofindstring) - addr(useknownaddress)

.useversiondata:

#if DEBUG
	cmp dword [versiondataptr],currentversion
	je .versionmemgood

	ud2		// something isn't aligned properly between
			// loader.ah and ttdprot.asm
.versionmemgood:
	cmp dword [flagdatasize],flag_data_size
	je .flagdatagood

	ud2		// C code has different size for flagdata struct
.flagdatagood:
#endif

	// initialize the uninitialized variables
	xor eax,eax
	mov edi,__pbss_start
	mov ecx,__pbss_size_dwords
	rep stosd
#if DEBUG
	cmp edi,__psbss_start
	je .isgoodsbss
	ud2
.isgoodsbss:
#endif
	dec eax
	mov ecx,__psbss_size_dwords
	rep stosd
#if DEBUG
	cmp edi,currentversion
	je .isgoodsbss2
	ud2
.isgoodsbss2:
#endif

#if WINTTDX
	call dorelocations	// only do this once
#endif

.notagain:

#if !WINTTDX && !LINTTDX

	cld

	// patch GPF handler to give more information

	// find code segment of gpf handler in the DOS extender code
	// the offset is always the same
	push es
	mov eax,cs
	sub eax,byte -0x80

.nextselector:
#ifndef DEBUGSEL
.skipselector:
#endif
	add eax,byte 8
	cmp eax,0x1ff
	ja short .giveup1

	xor edx,edx
	xor ebx,ebx

	lar edx,eax
	jnz .skipselector
	and edx,0x401a00
	cmp edx,0x401200
	jne .skipselector

	lsl ebx,eax
	cmp ebx,0x12fff
	jne .skipselector

	mov esi,originalgpfcode
	mov es,eax
	mov edi,0x1e31
	mov ecx,11
	repe cmpsb
	jne .skipselector

#ifdef DEBUGSEL
	call .showselector
#endif

	mov eax,ds
	cmp eax,byte 0x7f
	ja short .giveup2

	shl eax,8
	or eax,0x9c1f006a
	sub edi,byte 11		// move back to the beginning of the original code

	// store the adress
	mov word [gpfhookaddr+4],es
	mov dword [gpfhookaddr],edi

	stosd		// push (newds); pop ds; pushf;
	mov al,0x9a	// call far...
	stosb
	mov eax,addr(catchgpf)	// ... :eip
	stosd
	mov eax,cs	// ... cs:
	stosw

#ifdef DEBUGSEL
	jmp near .yay
.giveup1:
	ud2
.giveup2:
	ud2
.skipselector:
	call .showselector
	jmp .nextselector

.showselector:
	pusha
	push es
	push ds
	pop es
	xor ecx,ecx
	cmp ebx,0x1e40
	jb .nocode
	mov ecx,[es:0x1e31]
.nocode:
	push ecx
	push ebx
	push edx
	push eax
	mov esi,esp
	mov edi,.sellog
	mov ebx,4
	call hexdwords
	mov eax,ds
	mov es,eax
	mov ah,9
	mov edx,.sellog
	int 0x21
	add esp,16
	pop es
	popa
	ret
.sellog:
	times 75 db ' '
	db 13,10,'$'
.yay:
#else
.giveup1:
.giveup2:
#endif
	pop es
#endif
#if WINTTDX
	call setexceptionhandler
#endif

	// set new vehicle array size

	mov esi,vehicledatafactor
	mov al,1
	xchg al,[esi]			// if no larger array make sure vehicledatafactor is 1
	testmultiflags uselargerarray
	jz short .nochanges
	mov [esi],al			// otherwise leave it as it is

	mov edx,[heapstart]

#if WINTTDX
	add dword [heapstart],newveharraysize+4
#else

	// if lowmemory is on, a factor of one means we leave the array
	// where it is (can't reduce too large arrays that way, but that's fine)

	mov ah,40	// maximum size, for memory requirements

	testmultiflags lowmemory
	jz .notlowmem

	mov ah,al
	cmp al,1
	jbe .nochanges

.notlowmem:
	movzx ebx,ah
	imul ebx,oldveharraysize
	lea ebx,[ebx+edx+4]

	// allocate memory for the array

	push ebx
	add ebx,0xfff+12	// add 12 bytes for the heap structure
	shr ebx,12

	mov ah,0x4a
	push ds
	pop es
	int 0x21		// re-size allocated memory
	pop eax
	jnc .ok

	// no memory, turn on lowmemory, turn off uselargerarray
	testflags lowmemory,bts
	testflags uselargerarray,btr
	mov byte [vehicledatafactor],1
	jmp short .nochanges

.ok:
	mov [heapstart],eax
#endif

	cmp dword [veharrayptr],oldveharray
	jne short .nochanges

	lea eax,[edx+2]		// original heapstart+2
	mov [veharrayptr],eax	// (aligned on odd WORD)

.nochanges:
	call setvehiclearraysize
	call cleardata

	push ds
	pop es

		// setup the heap, at the moment three blocks in the DOS version:
		// - the memory from the end of TTD's memory to begin of
		//   TTDPatch code
		// - without lowmemory, the memory originally in the vehicle
		//   array
		// - the memory after the end of the vehicle array
		//   (either all 40 without lowmemory of actual size with
		//   lowmemory)
		//
		// in the Windows version, the heap is only the part after
		// the vehicle array plus whatever is allocated in addition
#if WINTTDX
	mov esi,[heapstart]
	mov [heapptr],esi
	lea eax,[esi+heap_size]
	mov [esi+heap.ptr],eax

	neg eax
	add eax,addr(protectedstart)+6*1024*1024
	mov [esi+heap.left],eax
	xor eax,eax
	mov [esi+heap.next],eax

#else

	mov esi,[heapptr]		// original size of TTD's code
	lea eax,[esi+heap_size]
	mov [esi+heap.ptr],eax

	neg eax
	add eax,__image_base__
	mov [esi+heap.left],eax

		// we'll have three cases (in al):
		//  0:	without lowmemory, add two blocks: org. veharray and
		//	block from heapstart onwards
		// -1:	with lowmemory and factor <= 1, add single block from
		//	heapstart onwards (same if uselargerarray is off)
		// -2:	with lowmemory and factor > 1, add two blocks: org.
		//	veharray and from [veharrayend]
		//
		// With WINTTDX, only the first case can happen

	mov ebx,[heapstart]
	mov al,-1
	testmultiflags uselargerarray
	jz .nofullarray

	testflags lowmemory
	sbb al,al	// lowmemory on: -1, off: 0
	jnc .gotit

.nofullarray:
	cmp byte [vehicledatafactor],2
	adc al,al	// factor <= 1: -1, > 1: -2
	jp .onlyoneblock	// jump if bl==-1

	cmp dword [currentversion+version.ttdversion],byte -1
	je .onlyoneblock // don't reuse TTD's memory if we have to search (or it might accidentally contain search strings)

	mov ebx,[veharrayendptr]
	inc ebx
	inc ebx

.gotit:
	mov eax,oldveharray+2		// +2 for DWORD alignment
	mov [esi+heap.next],eax

	xchg eax,esi
	lea eax,[esi+heap_size]
	mov [esi+heap.ptr],eax
	mov dword [esi+heap.left],850*128-heap_size-4

.onlyoneblock:
		//
		// ebx contains the start of last block now
		//

	mov [esi+heap.next],ebx

		// in DOS varheap starts at end of vehiclearray,
		// in Windows it's entirely separate chunks
	mov [varheap],ebx

	lea esi,[ebx+heap_size]
	mov [ebx+heap.ptr],esi

	mov esi,ds
	lsl esi,esi
	inc esi		// can access the very last byte
	sub esi,ebx
	sub esi,byte heap_size
	mov [ebx+heap.left],esi

	xor esi,esi
	mov [ebx+heap.next],esi

#endif	// WINTTDX

	//
	// heap is set up now, we can start doing the patching work
	//

	mov edx,patchflags
	testflagbase edx

	// set some flags and flagdata before applying the patches
	xor ebp,ebp
	xor ecx,ecx
	mov cl,nflags
.nextflag:
	or ebp,dword [edx+ecx*4-4]
	loop .nextflag

	je short .noflagsset
	testflags anyflagset,bts		// set "anyflagset" if any flag is set

.noflagsset:
	testmultiflags miscmods
	jnz .havemiscmods
	and dword [miscmodsflags],0		// let code access miscmodsflags without checking the miscmods flag

.havemiscmods:
	testmultiflags experimentalfeatures
	jnz .haveexpfeatures
	and word [expswitches],0		// same for experimentalfeatures

.haveexpfeatures:
#if WINTTDX
	testmultiflags usenoregistry
	jz .notnoregistry
	pusha
	call initnoregist
	popa

.notnoregistry:
#endif
	// initialize patchflagsfixed
	xor ecx,ecx
	mov esi,patchflagsfixedmap
	mov edi,patchflagsfixed
	xor eax,eax

.copyflagloop:
	lodsb
	testflags eax
	jnc .copynextflag
	bts [edi],ecx

.copynextflag:
	inc ecx
	cmp ecx,patchflagsfixedmaplength
	jne .copyflagloop

	testmultiflags unifiedmaglev
	jz .nounimaglev

	mov al,[unimaglevmode]
	mov ah,[edi+patchflagsunimaglevmode_d8]
	push ecx
	mov ecx,patchflagsunimaglevmode_a7
	rol al,cl
	and ah,[patchflagsunimaglevmode_a7_s3_n]
	pop ecx
	or al,ah
	mov [edi+patchflagsunimaglevmode_d8],al

.nounimaglev:
	testflagbase none

	call initourtextptr

	mov ecx,numgrfswitchparam
	mov esi,grfswitchparamlist
	mov edi,grfswitchparam
	mov ebx,startflagvars

.nextgrfswitchparam:
	xor eax,eax
	lodsb
	cmp eax,long_flags_end
	jb .dword
	cmp eax,word_flags_end
	jb .word
	cmp eax,ubyte_flags_end
	jb .ubyte

	movsx eax,byte [ebx+eax]
	jmp short .storeparam

.ubyte:
	xlatb	// mov al,[ebx+al]
	jmp short .storeparam
.word:
	mov ax,[ebx+eax]
	jmp short .storeparam
.dword:
	mov eax,[ebx+eax]
.storeparam:
	stosd
	loop .nextgrfswitchparam

	call applypatches
	mov byte [grfstage],1		// .grf initialization done

#if WINTTDX
	// Notify ttdpatchw.exe we're done
	xor esi,esi
	push .ipcopeneventfn
	push dword [kernel32hnd]
	call [GetProcAddress]
	or eax,eax
	jnz short .ipcopenfnok

.ipcerror:
	mov al,systext_LANG_PMIPCERROR
	call systemwarning
	jmp short .ipcdone

.ipcopenfnok:
	push .ipceventname
	push 0
	push 2				// EVENT_MODIFY_STATE
	call eax			// OpenEvent
	or eax,eax
	jz .ipcerror

	xchg esi,eax

	push .ipcseteventfn
	push dword [kernel32hnd]
	call [GetProcAddress]
	or eax,eax
	jz .ipcerror

	push esi
	call eax			// SetEvent
	or eax,eax
	jz .ipcerror

.ipcdone:
	// Close the IPC event
	// (we leave shared memory open so if another instance of ttdpatchw.exe starts
	// it'll know we're already running)

	or esi,esi
	jz short .noeventhandle
	push esi
	call [CloseHandle]
.noeventhandle:

#endif
	xor edx,edx
	testmultiflags onlygetversiondata
	jz .dontexit
#if WINTTDX
	push 0
	call [ExitProcess]
#else
	mov ax,0x4c00
	int 0x21
#endif
.dontexit:

		// make sure all variables are initialized, in case
		// title.dat can't be loaded to reset them
	testmultiflags anyflagset
	jz .endinitialize
	call inforeset
	call initveh2

.endinitialize:
	or byte [didinitialize],2
	ret

#if WINTTDX
.ipcopeneventfn: db "OpenEventA",0
.ipcseteventfn: db "SetEvent",0
.ipceventname: db TTDPATCH_IPC_EVENT_NAME,0
#endif
; endp initialize

	// record the version data, called at the end of "applypatches",
	// if the recordversiondata bit is set
global dorecordversiondata
dorecordversiondata:
#if WINTTDX
	mov esi,currentversion
	mov [esi+version.numoffsets],edx
	lea ecx,[edx*4+version_size]
	mov dword [esi+version.ttdversion],MOREMAGIC

	mov ebp,[loaderdata]
	setextbase ebp,winloaderbegin.data

	mov edi,[BASE winloaderbegin.shmaddr]
	rep movsb

	setbase none
	ret

#elif !LINTTDX

	push edx
		// store version information back in ttdpatch.dat
		// FIXME: get filename from loader code
	mov ah,0x3c	// create file
	mov edx,datfilename
	int 21h		// ecx is already zero
	jc .abort

	mov bx,ax
	mov ah,0x40	// write file
	mov edx,currentversion
	pop ecx		// number of version offsets
	push ecx
	mov [edx+version.numoffsets],ecx
	shl ecx,2
	add ecx,version_size

	mov dword [edx+version.ttdversion],MOREMAGIC
	int 21h
	jc .abort

	mov ah,0x3e	// close file
	int 21h
	// jc .abort

.abort:
	pop edx
#endif
	ret
; endp dorecordversiondata

var datfilename, db TTDPATCH_DAT_FILE,0

uvard lastpatchproc

proc applypatches
	local origedx,skipnum

	_enter

	xor edx,edx
#if WINTTDX
	inc edx		// has searched for datastart already
#endif
	mov esi,patchlist

.nextpatch:
	xor eax,eax
	cmp dword [currentversion+version.ttdversion],byte -1
	je .unknown
	xchg al,byte [currentversion+version.offsets+edx*4+3]

.unknown:
	mov [%$skipnum],eax
	mov [%$origedx],edx

#if DEBUG
	mov [lastpatchproc],esi
#endif

	lodsb
	test al,al
	jne near .orbits

	lodsb
	test al,al
	jne .andbits

	// done, that was the last entry
#if DEBUG
	and dword [lastpatchproc],0
#endif
	_ret

.getflag:
	lodsb
	cmp al,patchprocbitflag
	jne .gotflag

	push ecx
	lodsd
	mov ecx,[eax]
	xor eax,eax
	lodsb
	test al,0x40
	jnz .vartest
.bittest:
	bt ecx,eax	// using only bits 0..4 of al
	jmp short .checkflag
.vartest:
	mov ah,al
	and ah,0x7f
	cmp ah,0x7e
	mov ah,0
	jb .bytevar
	je .wordvar
.dwordvar:
	cmp ecx,1
	jmp short .checkvarflag
.wordvar:
	cmp cx,1
	jmp short .checkvarflag
.bytevar:
	cmp cl,1
.checkvarflag:
	cmc		// was CF=1 if not set
.checkflag:
	mov cl,al
	mov al,0
	adc al,0	// now al=1 if bit was set and al=0 if bit was clear
	test cl,cl
	jns .notinv	// want bit to be clear?
	xor al,1	// now al=1 if bit was clear and al=0 if bit was set
.notinv:
	add al,noflag	// now al=noflag if bit was wrong and al=anyflagset if bit was right
	pop ecx

.gotflag:
	ret


.andbits:
	mov ecx,eax

.nextand:
	call .getflag
	bt [patchflags],eax
	jnc .dontapply
	loop .nextand

	lodsb
	test al,al
	jz .doneskipping
	jmp short .orbits

.dontapply:
	dec ecx
	jz .noand

.andskip:
	call .getflag
	loop .andskip
.noand:
	lodsb
	mov ecx,eax
	jecxz .notset
.orskip:
	call .getflag
	loop .orskip
	jmp short .notset

.orbits:
	mov ecx,eax

.trynext:
	call .getflag
	bt dword [patchflags],eax		// the processor nicely picks the right variable
	jc short .applypatch

		// bit not set, try next option if any
	loop .trynext

		// no more options, none of the bits was set
.notset:

//#if DEBUG
		// make sure the patch isn't skipped when making a versiondata file
	testmultiflags recordversiondata
	jnz .applypatch
//	jz short .ok
//
//	cmp dword [%$skipnum],byte 0
//	je badversionindex
//
//.ok:
//#endif

		// skip the appropriate number of entries in the version offsets
	add edx,[%$skipnum]

		// and in the patchlist
	lodsd
	jmp .nextpatch

	// bit is set, do the patch
.applypatch:
	// but first skip remaining non-zero bit numbers
	jecxz .doneskipping
	dec ecx

	jz short .doneskipping

.skipnext:
	call .getflag
	loop .skipnext

.doneskipping:
	lodsd			// load patch proc pointer

#if !WINTTDX && defined(SHOWPPROC)
	pusha
	push esi
	mov esi,esp
	mov edi,.log
	mov ebx,1
	call hexdwords
	mov eax,ds
	mov es,eax
	mov ah,9
	mov edx,.log
	int 0x21
	pop eax
	popa
	jmp short .skiplog
.log:	db "########",13,10,'$',0
.skiplog:
#endif

	push ebp
	push esi
	xor edi,edi
	call eax
	pop esi
	pop ebp

	// if skipnum is unknown, store the number of searches
	// otherwise use it to adjust edx (e.g. because of empty entries)

	mov eax,[%$skipnum]
	mov ecx,[%$origedx]

	or eax,eax
	jz short .savenumber

	lea edx,[eax+ecx]
	jmp .nextpatch

.savenumber:
	// store number of entries in versionoffsets for this patch
	mov eax,edx
	sub eax,ecx
	jnz short .good

	// patch didn't do any searching, so we'll create an empty entry
	inc eax
	inc edx

.good:
#if DEBUG
	// while debugging, make sure that not more than 255 searches are
	// done per patch block
	cmp eax,0xff
	ja badversionindex
#endif

	mov byte [currentversion+version.offsets+ecx*4+3],al
	jmp .nextpatch
endproc // applypatches



#if DEBUG
var debug_outofversiondataspace, db "DEBUG: Out of version data space!",13,10,0
badversionindex:
	; getting here means we have run out of space to put version data
	; therefore increase TOTALOFFSETS in common.h
	; Oskar: you can only have 255 searches per patchproc
	; if it is less check versions.h, TOTALOFFSETS is outdated, look for ALLOCEMPTYOFFSETS
	mov edx,debug_outofversiondataspace
	jmp criticalerror
#endif

storeversionaddress:
	mov dword [currentversion+version.offsets+edx*4],edi
	inc edx
#if DEBUG
	cmp edx,[currentversion+version.numoffsets]
	jbe .goodindex

	// if we're terminating immediately, it doesn't matter if we
	// overwrite custom texts or the vehicle array
	testflags onlygetversiondata
	jnc badversionindex

.goodindex:
#endif
	ret
; endp storeversionaddress


getversionaddress:
.neednosearch:
	mov edi,dword [currentversion+version.offsets+edx*4]
	inc edx
#if DEBUG
	cmp edx,[currentversion+version.numoffsets]
	ja badversionindex
#endif
	xor ecx,ecx
	ret
; endp getversionaddress

	// instead of searching, use the known address values
global useknownaddress
useknownaddress:
	call getversionaddress
	ret 0x14
; endp useknownaddress


	// dofindstring - finds a string
	// In:	- pointer to string to look for
	//	- number of bytes in the string
	//	- occurence info:
	//	  lo word: number of times string may be found*
	//	  hi word: which occurence to return
	// Out: 	edi:	address where it was found
	// Destroys al,esi
	// Clears ecx
	// Adjusts edx for next version offset
	//
	// If the string is not found, or if it's found too few
	// or too many times, an error message is displayed
	// and TTD is aborted.
	// lastsearchcalladdr should be set to the address
	// to display in the error message, plus 5 bytes
	// (i.e. it is assumed to be return address from CALL label)
	//
	// Note: Make sure dir flag is unset. If maxcount=occurence-1,
	//	 return that occurence and don't check for further ones.
	//	 Also, this special kind of search starts at the current
	//	 value of EDI, to allow continuing a search.
	//

proc dofindstring

	arg string,strlen,occurence,maxcount,correction

	// note! If the argument list changes, make sure to adjust the ret xx
	// in useknownaddresses accordingly

	local found,granularity,orgcount,findcount

	_enter
	push ebx

#if 0 && !WINTTDX	// disabled because it suddenly breaks some fragments ???
	push edx
	mov ah,0x02
	mov dl,0x2e
	CALLINT21
	pop edx
#endif

	cmp dword [%$strlen],byte 3		// can't find shorter than 3 bytes
	jl near .failmiserably

	mov al,0x90		// by default check first five bytes
	mov ecx,5
	cmp dword [%$strlen],byte 5
	jge short .notwordsize

	mov al,0x66		// only check first three bytes in < 5 in total
	sub ecx,byte 2

.notwordsize:
	mov byte [.cmpinstr],al
	mov [%$granularity],ecx

	mov esi,[%$string]	// first 3/5 bytes are checked differently, so
	sub [%$strlen],ecx	// account for that



	lodsb		// load first 5 bytes, and go looking for them
	xchg eax,ebx
	lodsd
	xchg eax,ebx    // now al=1 byte, ebx=next 4 bytes

	mov ecx,[%$maxcount]
	mov [%$orgcount],ecx
	and dword [%$findcount],0
	inc ecx
	cmp ecx,[%$occurence]	// if maxcount+1==occurence, continue at edi
	je short .notfromstart
	xor edi,edi

.notfromstart:

#if WINTTDX
	// fix edi=0 into edi=datastart to not start searching at offset 0
	or edi,edi
	jnz short .notzero
	mov edi,0x400000

.notzero:
#endif

	mov ecx,searchend
	sub ecx,edi

.lookagain:
	repne scasb		// byte search because of unknown alignment
	jne short .searchfailed


.cmpinstr:
	// this will be cmp bx, or cmp ebx, depending on length of string
	cmp bx,[edi]	// check next 2 (or 4) bytes
	jne short .lookagain

	cmp dword [%$strlen],byte 0
	je short .stringmatched

	push ecx		// not exactly 3 or 5 bytes in string, check the rest
	push edi

	mov ecx,[%$strlen]
	mov esi,[%$string]
	dec edi
	add esi,[%$granularity]	// skip the already checked bytes, and then
	add edi,[%$granularity]
	repe cmpsb		// check rest of the string
	pop edi
	pop ecx
	jne short .lookagain	// no, not all bytes matched

.stringmatched:
	inc dword [%$findcount]
	dec dword [%$occurence]	// is this the occurence we want?
	jnz short .itsnottheone	// no.

	mov [%$found],edi		// yes, save the value
	cmp dword [%$maxcount],0	// does the maximum count have a limit?
					// (note; this really checks maxcount==occurence-1 !!)
	je short .goodsearch		// no

.itsnottheone:
	dec dword [%$maxcount]	// must we find more?
	jns short .lookagain	// yes, there's more to find
				// no, it was already too many!
	jmp short .failmiserably

.searchfailed:			// Called if a search fails
	cmp dword [%$occurence],0
	jg short .failmiserablydec	// we didn't find it yet

	cmp dword [%$maxcount],0
	jng short .goodsearch

.failmiserablydec:
	dec dword [%$maxcount]	// so the error message reports right count
	jmp short .failmiserably

.goodsearch:
	// good. we found it exactly as often as wished!
	mov edi,[%$found]
	dec edi			// edi always points to next byte, so take -1
	add edi,[%$correction]

	call storeversionaddress

	xor ecx,ecx

.searchdone:

	pop ebx
	_ret	// does leave automatically

	global dofindstring.failmiserably
.failmiserably:		// it wasn't found often enough, or too often
	mov [%$found],edi		// for the error message
	mov edi,findstringerr_strnum
	xchg eax,edx
#ifndef RELEASE
	sub eax,[lastpatchprocstartedx]
#endif
	mov cl,4
	call hexnibbles		// in patches/catchgpf.asm

	add edi,byte findstringerr_callfrom-findstringerr_strnum-4
	mov eax,[lastsearchcalladdr]
	sub eax,5
	mov cl,8
	call hexnibbles

	add edi,byte findstringerr_occurence-findstringerr_callfrom-8
	mov eax,[%$findcount]
	mov cl,2
	call hexnibbles

	inc edi	// add edi,byte findstringerr_outof-findstringerr_occurence-2
	mov eax,[%$orgcount]
	mov cl,2
	call hexnibbles

	add edi,byte findstringerr_at-(findstringerr_outof+2)
	mov eax,[%$found]
	mov cl,8
	call hexnibbles

#ifndef RELEASE
	mov esi,[lastsearchfragmentname]
	test esi,esi
	jle .noname
	mov edi,findstringerr_name
	mov ecx,findstringerr_name_len
.copy:
	lodsb
	test al,al
	stosb
	loopnz .copy
	sub ecx,3
	jbe .noproc
	dec edi
	mov ax,"in"
	stosw
	mov esi,[lastpatchprocname]
	test esi,esi
	jle .noproc
.copyproc:
	lodsb
	test al,al
	stosb
	loopnz .copyproc
.noproc:
#if !WINTTDX
	dec edi
	mov eax,0x1013	// CRLF<nul>
	stosd
#endif
.noname:
#endif

	mov edx,findstringerror
	jmp criticalerror

endproc // dofindstring

var findstringerror
	db "Failed to find string #"
var findstringerr_strnum, db	  "#### at "
var findstringerr_callfrom, db		  "########, found "
var findstringerr_occurence, db				  "##/"
var findstringerr_outof, db				     "## at "
var findstringerr_at, db					   "########"
#ifndef RELEASE
	db " for"
var findstringerr_name
	db " ????",13,10,0,"                                            ",0
findstringerr_name_len equ $-findstringerr_name-4
#else
	db 13,10,0
#endif

uvard lastpatchprocname
uvard lastpatchprocstartedx
uvard lastsearchfragmentname
uvard lastsearchcalladdr

	//
	// Wrapper functions to perform the most common tasks
	// (using these in macros saves a few bytes per instance)
	//

// Just set lastsearchcalladdr and call dofindstring or useknownaddress.
// Parameters as to dofindstring.  (Note: Using direct call saves 1 byte per search.)
global calldofindstring
calldofindstring:
	pop dword [lastsearchcalladdr]	// remove the return address from stack and save it for later
	call [findstring]
	push dword [lastsearchcalladdr]
	ret

// Patch an occurence of code.  Use the patchcode macro (see ttdprot.ah) to call this function.
global dopatchcode
proc dopatchcode
	arg string,patch,strlen,occurence,maxcount,correction,patchlen

	_enter
	mov ecx,[ebp+4]
	mov [lastsearchcalladdr],ecx
	param_call [findstring],dword [%$string],dword [%$strlen],dword [%$occurence],dword [%$maxcount],dword [%$correction]

	mov esi,[%$patch]
	mov ecx,[%$patchlen]
	test esi,0xff000000
	jnz .store_cf
	rep movsb
.done:
	_ret	// does leave automatically
.store_cf:
	push esi
	push ecx
	call store_cj_fragment
	jmp .done
endproc // dopatchcode

// Store a call/jmp fragment
global store_cj_fragment
proc store_cj_fragment
	arg target,size

	_enter
	mov esi,[%$target]
	mov ecx,[%$size]
.gotargs:
	shld eax,esi,8
	stosb
	and esi,0xffffff
	lea eax,[esi-4]
	sub eax,edi
	stosd
	sub ecx,5
	jz .done
	cmp ecx,8
	jb .pad
	mov al,0xeb		// do pads 8+ with a jmp short
	stosb
	lea eax,[ecx-2]
	stosb
	jmp short .done
.pad:
	lea esi,[ecx-1]		// pad with the appropriate entry from below
	imul esi,ecx		// calculate esi=fragpad+ecx*(ecx-1)/2
	shr esi,1
	add esi,fragpad
	rep movsb
.done:
	_ret
endproc

varb fragpad
	db __pad_1
	db __pad_2
	db __pad_3
	db __pad_4
	db __pad_5
	db __pad_6
	db __pad_7
section .text	// in case someone wants to put some code below

