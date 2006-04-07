//
// loader.ah
//
// Code to patch into the executable that loads and initializes TTDPatch
//

#include <defs.inc>
#include <frag_def.inc>
#include <proc.inc>
#include <flags.inc>
#include <win32.inc>
#include <misc.inc>
#include <var.inc>

extern magicbytes
extern __image_base__
extern loaderdata,kernel32hnd,heapstart
extern oldveharraysize,veharrayendptr,varheap,heapptr,ttdmemsize

def_indirect initialize

vard auxdatapointers
	var versiondataptr, dd 0	// where the loader stored the version data
	var customtextptr, dd 0		// and the custom text data
	var systemtextptr, dd 0		// and the system text data
	var relocofsptr, dd 0		// and the relocation offsets

section .text

// The loaders are actually at variable addresses, hence their code must be
// location-independent.


#if LINTTDX

// For Linux, this is gonna be a chunk in the data segment.  Specify the
// offsets at which to find the loader and the protected mode code, as well
// as the offset at which to load the protected mode code.

var linloaderofs, dd initfunc-linloaderofs
var linloaderlen, dd maxinitfuncsize

var lindataofs, dd protectedfunc - linloaderofs
var lindatalen, dd protectedfuncend - protectedfunc
var lindatabase, dd __image_base__
#endif


initfunc:
#if !WINTTDX

	jmp short .start

.loaderver:
	dw 22-DEBUG		// increase this number by 2 everytime the loader changes

.initialize1ptr:
	dd 0			// will be set by dos.c

.patchver:
	dd auxdatapointers	// if this location changes, ttdload.ovl will be remade

.start:
#if DEBUG>2
	CALLINT3		// enable only to debug loader; will break later anyway
#endif

	push ebp
	mov ebp,esp

	pusha
	call $+5		// "push eip"

.base:
	pop esi

	setbase esi,.base,1

	mov eax,[BASE .initialize1ptr]
	mov edx,[ebp+4]
	sub dword [ebp+4],5	// change return address to before "call initialize1"
	mov [edx-4],eax		// and make sure it points to initialize1 again

	mov eax,ds
	lsl eax,eax
	inc eax

	mov [BASE .ttdmemsize],eax	// size of TTD's data+code segment

	mov ax,0x3d40	// open file
	lea edx,[BASE .datfilename]
	int 21h
	mov bx,ax
	jnc .doload

.abort:				// abort patch loading
	popa
	leave
	ret

		// put variables in the middle so they're
		// not too far from .base
	align 4

.arraytotalsize:dd 0
.arrayfilesize:	dd 0
.memend:	dd __image_base__
.memsize:	dd 0
.ttdmemsize:	dd 0
.datfilename:	db TTDPATCH_DAT_FILE,0

.doload:
	lea eax,[esp-4]
	push eax	// make temp var on stack and push pointer to it
	call .readarray
	jc .abort

	push versiondataptr
	call .readarray
	jc .abort

	push customtextptr
	call .readarray
	jc .abort

	push systemtextptr
	call .readarray
	jc .abort

	push relocofsptr
	call .readarray
	jc .abort

	mov ah,0x3e	// close file
	int 21h
	jc .abort

	mov ah,0x41	// delete file
	lea edx,[BASE .datfilename]
	int 21h
	// jc .abort	// don't need to abort if deletion failed

	mov eax,[BASE .ttdmemsize]
	mov [heapptr],eax
	mov [ttdmemsize],eax

	mov eax,[BASE .memend]
	mov [heapstart],eax

	icall initialize

	popa
	leave
	ret

.readarray:
	mov ah,0x3f	// read file
	mov ecx,8       // first read array size DWORDs
	lea edx,[BASE .arraytotalsize]
	int 21h
	jc .readfail

	mov ecx,[BASE .arraytotalsize]
	cmp ecx,[BASE .memsize]
	jb .memok

		// allocate memory for the array
	pusha
	mov ah,0x4a		// increase segment size to minimum size necessary
	mov ebx,[BASE .memend]
	lea ebx,[ebx+ecx+heap_size+0x2fff]	// add 8KB for good measure
	shr ebx,12

	push ds
	pop es
	int 0x21		// re-size allocated memory
	popa
	jc .readfail

.memok:
	mov edx,[BASE .memend]
	mov edi,[esp+4]
	mov [edi],edx
	lea edi,[edx+ecx+3]
	and edi,byte ~3
	mov [BASE .memend],edi
	mov ecx,ds
	lsl ecx,ecx
	inc ecx
	sub ecx,edi
	mov [BASE .memsize],ecx

	mov ah,0x3f			// read file
	mov ecx,[BASE .arrayfilesize]	// edx set correctly
	int 21h

.readfail:
	ret 4

	setbase none

	align 4		// otherwise the size below will be wrong

initfuncsize equ $ - initfunc

patchdatfile equ .datfilename

#endif
initfuncend:
; endp initfunc



// This is the Windows loader.
// Under Windows, we get the protected mode code from TTDPatch through the
// stdin file handle, and then we write the result code to stdout.

#if !WINTTDX
winloader:
realentrypoint:		// dummy to be exported
winloaderend:
#else
global winloaderbegin.data,winloaderbegin.shmaddr
proc winloader
	local dataofs

	jmp short winloaderbegin.start

realentrypoint:
winloaderbegin:
.data:
	.realentry:		dd MAGIC	// will contain real entry point
	.shmhandle:		dd 0
	.shmaddr:		dd 0
	.khandle:		dd 0
	.memend:		dd __image_base__
	.OpenFileMapping:	dd 0
	.MapViewOfFile:		dd 0
	.kernel:		db "KERNEL32",0
	.progname:		db "TTDPatch",0
	.openshm:		db "OpenFileMappingA",0
	.mapshm:		db "MapViewOfFile",0
	.smhname:		db TTDPATCH_IPC_SHM_NAME,0

.start:
	// preliminaries...  calculate the actual address of .data

#if DEBUG>2
	CALLINT3		// enable only to debug loader; will break later anyway
#endif

	push eax
	_enter
	pushad

	call .eip
.eip:	pop esi		// esi=.eip

	jmp short .realstart

	// moved here to keep some jumps short
	.loaderror:		db "TTDPatch not loaded properly!",0

	%ifndef PREPROCESSONLY
		%if (.loaderror-.data) > 0x7f
			%error ".loaderror too far from .data"
		%endif
	%endif

	setbase esi,.data,1

.error:
	push byte 0x10			// uType = MB_ICONERROR
	lea eax,[BASE .progname]
	push eax			// lpCaption
	lea eax,[BASE .loaderror]
	push eax			// lpText

.abortbox:
	push byte 0			// hWnd
	call dword [MessageBoxA]

.abort:
	push byte 1
	call dword [ExitProcess]


.realstart:
	sub esi,0 + .eip - .data	// initial 0 triggers opimm8.mac checks
	mov [%$dataofs],esi

	// Now the real stuff starts

	lea eax,[BASE .kernel]
	push eax
	call dword [GetModuleHandleA]
	or eax,eax
	jz .error
	mov [BASE .khandle],eax

	// Get addresses of some Win32 API we need

	lea ebx,[BASE .openshm]
	push ebx
	push eax
	call dword [GetProcAddress]
	or eax,eax
	jz .error
	mov [BASE .OpenFileMapping],eax

	lea eax,[BASE .mapshm]
	push eax
	push dword [BASE .khandle]
	call dword [GetProcAddress]
	or eax,eax
	jz .error
	mov [BASE .MapViewOfFile],eax

	// Open and map the shared memory

	lea eax,[BASE .smhname]
	push eax			// lpName
	push 0				// bInheritHandle
	push 2				// dwDesiredAccess = FILE_MAP_WRITE
	call [BASE .OpenFileMapping]
	or eax,eax
	jz .error
	mov [BASE .shmhandle],eax

	xor ebx,ebx
	push ebx			// dwNumberOfBytesToMap // map entire shared memory
	push ebx			// dwFileOffsetLow
	push ebx			// dwFileOffsetHigh
	push 2				// dwDesiredAccess = FILE_MAP_WRITE
	push eax			// hFileMappingObject
	call [BASE .MapViewOfFile]
	or eax,eax
	jz .error
	mov [BASE .shmaddr],eax

	// Check if the shared memory contains TTDPatch code

	cmp dword [eax+8],MAGIC
	jne .error

	// Copy the shared memory contents to where appropriate

	xor ecx,ecx
	call .copyarray
	jc .error

	mov ecx,versiondataptr
	call .copyarray
	jc .error

	mov ecx,customtextptr
	call .copyarray
	jc .error

	mov ecx,systemtextptr
	call .copyarray
	jc .error

	mov ecx,relocofsptr
	call .copyarray
	jc .error

	cmp dword [magicbytes],MAGIC
	jne .error

	mov [loaderdata],esi

	mov eax,[BASE .khandle]
	mov [kernel32hnd],eax

	mov eax,[BASE .memend]
	mov [heapstart],eax

	push ebp
	icall initialize
	pop ebp

	mov esi,[%$dataofs]
	mov eax,[BASE .realentry]	// modify where "ret" returns to
	mov [ebp+4],eax

	popad
	_ret		//	jmp dword ptr cs:[.realentry]


.copyarray:
	mov edi,[BASE .memend]
	mov ebx,[eax]			// destination size required
	lea ebx,[edi+ebx+3]
	and ebx,byte ~3
	mov [BASE .memend],ebx

	jecxz .docopy
	mov [ecx],edi

.docopy:
	mov ecx,[eax+4]			// source size
	add eax,8
	xchg eax,esi
	rep movsb
	xchg eax,esi

	ret

	setbase none

	align 4		// otherwise the size below will be wrong

winloaderend:
endproc // winloader
#endif

