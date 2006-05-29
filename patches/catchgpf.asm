//
//	Catches a GPF, and generates a useful error message
//	in CRASH###.TXT
//

#include <std.inc>
#include <flagdata.inc>
#include <version.inc>
#include <win32.inc>
#include <grf.inc>

extern cargoids,curcallback,curgrffeature,lasttextids,curmiscgrf
extern curgrffile,curgrfid,curgrfsprite,currentversion,hexdigits
extern startflagdata



#if !WINTTDX && !LINTTDX
#	include "../versiond.h"
#else
#	include "../versionw.h"
#endif



uvard gpflognum

#if WINTTDX
uvard prevexceptionhandler
uvard isbadreadptr

global win2kexceptionhandler
win2kexceptionhandler:
	cmp dword [gpflognum],0
	jne near .abort

	inc dword [gpflognum]

	push ebp
	mov ebp,esp

	pusha
	push es
	push ebp
	push ds
	cld

	mov esi,[ebp+8]
	mov eax,[esi]
	mov ebp,[esi+4]
	add ebp,0x7c

	%define .gs [ebp+0x10]
	%define .fs [ebp+0x14]
	%define .es [ebp+0x18]
	%define .ds [ebp+0x1c]
	%define .edi [ebp+0x20]
	%define .esi [ebp+0x24]
	%define .ebx [ebp+0x28]
	%define .edx [ebp+0x2c]
	%define .ecx [ebp+0x30]
	%define .eax [ebp+0x34]
	%define .ebp [ebp+0x38]
	%define .eip [ebp+0x3c]
	%define .cs [ebp+0x40]
	%define .flags [ebp+0x44]
	%define .esp [ebp+0x48]
	%define .ss [ebp+0x4c]

	push dword .flags
	push dword .ss
	push dword .gs
	push dword .fs
	push dword .es
	push dword .ds
	push dword .ebp
	push dword .esp
	push dword .edi
	push dword .esi
	push dword .edx
	push dword .ecx
	push dword .ebx
	push dword .eax
	push dword [eax]	// exception code


#else
	// address of the original code
	uvard gpfhookaddr, 2	// offset,segment

global catchgpf
catchgpf:

	// we don't want to touch the divide by zero exception,
	// that one's handled properly anyway.
	cmp dword [esp+0x10],byte 0
	jne short .good

.stop:
	mov ds,[esp+4]	// previous code seg

	mov ds,[word 0x2f6e]	// replaced by this call
	mov [word 0x17e8],eax
	iret


.good:
	cmp dword [gpflognum],0
	jne near .abort

	inc dword [gpflognum]

	// the stack structure is like this: (at least on Win98)
	// (counted from EBP as saved later on by the enter instruction)
	// +34	faultss
	// +30	faultesp	esp and ss when the fault occured
	// +2c	faultflags
	// +28	faultcs
	// +24	faulteip	flags, cs, and eip at the fault location
	// +20	??
	// +1c	lidtcs
	// +18	lidteip		a call gate to somewhere?
	// +14  fault
	// +10	ds		ds as saved by the DOS extender fault handler
	// +0c	flags
	// +08	cs
	// +04	eip		flags, cs and eip of the DOS extender fault handler
	// +00	faultebp	(isn't modified yet)

	%define .flags [ebp+0x2c]
	%define .ss [ebp+0x34]
	%define .ebp [ebp]
	%define .esp [ebp+0x30]
	%define .eip [ebp+0x24]
	%define .cs [ebp+0x28]
	%define .ds [ebp+0x10]
	%define .exc [ebp+0x14]

	enter 0,0	// save ebp and setup temp. stack frame

	pusha
	push es

	push ds		// save it for later
	cld

	// -----------------------
	//	Prepare data
	// -----------------------


	// Store the value of every register at the time the crash
	// occurred.  Store them on the stack, in the order that they're
	// going to get printed out.
	push dword .flags
	push dword .ss
	push gs
	push fs
	push es
	push dword .ds
	push dword .ebp
	push dword .esp
	push edi
	push esi
	push edx
	push ecx
	push ebx
	push eax

	// Restore the original GPF handler code
	// so that our code is never used again

	verw word [gpfhookaddr+4]
	jnz short .cantrestorehandler
	les edi,[gpfhookaddr]
	mov esi,originalgpfcode
	mov ecx,11
	rep movsb

.cantrestorehandler:
#endif

#if !WINTTDX
	sti
#endif

	// -----------------------
	// 	Print data
	// -----------------------

	// Now we print the data into the template, and then
	// pop the printed data off the stack

	mov esi,currentversion+version.size
	push ds
	pop es
	mov edi,gpfttdv	// Store TTD version (.EXE file size)
	mov ebx,1
	call hexdwords

	mov edi,gpferr	// Store exception code
#if WINTTDX
	pop eax		// exception code
	mov cl,8
#else
	mov eax,.exc
	mov cl,2
#endif
	call hexnibbles

	lea esi,.eip
	push ss
	pop ds
	mov edi,gpfeip	// Store fault location, CS:EIP
	mov bl,1
	call hexdwords

	sub edi,byte 15	// to gpfcs
	mov bl,1
	call hexwords

	mov esi,esp
	mov edi,gpfeax	// Store EAX, EBX, ECX, EDX
	mov bl,4
	call hexdwords

	mov edi,gpfesi	// Store ESI, EDI, ESP, EBP
	mov bl,4
	call hexdwords

	mov edi,gpfds	// Store DS, ES, FS, GS, SS
	mov bl,5
	call hexwords

	mov bl,1
	call hexdwords			// Store EFLAGS

	lea esi,[esp+8*4]
	mov edi,gpflim
	mov bl,5
	call seglimits

	lea esi,[esp+8*4]
	mov edi,gpfar
	mov bl,5
	call segrights

	add esp,byte 14*4			// remove values from stack

	// See if we can access the segment at the original CS, so
	// that we can record the code at CS:EIP

#if WINTTDX
	// Windows tells us we can't access CS for reading, so try DS
	verr word .ds
	jnz .nocode
	mov ds,.ds
#else
	verr word .cs
	jnz short .nocode
	mov ds,.cs
#endif
	mov edi,gpfcode
	mov bl,16
	mov esi,.eip
	call hexbytes

.nocode:
	// Same as above but now the stack at the original SS:ESP

	verr word .ss
	jnz short .nostack
	mov edi,gpfstk
	mov bl,8*4
	mov ds,.ss
	mov esi,.esp
	call hexdwords

.nostack:
	// And finally our own stack, as provided by the OS and the
	// DOS Extender, so that we might figure out why some crashes
	// don't show useful values

	// First store our stack's location

	push ss
	push ss
	pop ds
	push ebp
	mov esi,esp
	mov edi,gpfhesp
	mov bl,1
	call hexdwords

	sub edi,byte 15	// to gpfhss
	mov bl,1
	call hexwords

	add esp,byte 2*4

	// Now dump our stack

	mov edi,gpfhstk
	mov bl,8*4
	mov esi,ebp
	call hexdwords

	pop ds

	// Now record the patch flags
	mov edi,gpfflags
	mov esi,startflagdata
%ifndef PREPROCESSONLY
	%assign nflagdata (flags_size+3)/4
	mov bl,nflagdata
%endif
	call hexdwords

	// ------------------------
	//     Write to file
	// ------------------------

	// Now we write the output to a CRASH###.TXT file, the first one
	// that doesn't exist
	//

	mov eax,"000."

.openagain:

	mov dword [gpffno],eax

#if WINTTDX
	// unfortunately TTDWin doesn't support int 21/ah=5b
	push 0			// hTemplateFile
	push 128		// dwFlagsandAttributes = FILE_ATTRIBUTE_NORMAL
	push 1			// dwCreationDisposition = CREATE_NEW (fail if it exists)
	push 0			// lpSecurityAttributes
	push 0			// dwShareMode
	push 0x40000000		// dwDesiredAccess = GENERIC_WRITE
	push gpffile		// lpFilename
	call [CreateFile]
	test eax,eax
	jns .isopen
#else
	mov ah,0x5b
	xor ecx,ecx
	mov edx,gpffile
	CALLINT21		// create new file
	jnc short .isopen
#endif

	mov eax,dword [gpffno]

	add eax,0x10000
	cmp eax,("9." << 16) + 0xffff	// allow crash009.txt too
	jbe .openagain

	sub eax,10 << 16
	inc ah
	cmp ah,"9"
	jbe .openagain

	mov ah,"0"
	inc al
	cmp al,"9"
	jbe .openagain
	jmp short .bailout

.isopen:
	push eax
	call makegrfmsg
	call maketextidmsg
#if DEBUG
	call makedebugmsg
#endif
	pop eax

#if WINTTDX
	push eax

	push 0				// lpOverlapped
	push tempvar			// lpBytesWritten
	push gpfdumpend - gpftext	// nBytestoWrite
	push gpftext			// lpBuffer
	push eax			// hFile
	call [WriteFile]

	mov ecx,[cargoids]
	test ecx,ecx
	jle .nogrffile

	pop eax
	push eax			// for CloseHandle below
	push 0
	push tempvar
	push ecx
	push cargoids+4
	push eax
	call [WriteFile]

.nogrffile:
					// eax=hFile still on stack
	call [CloseHandle]
#else
	push eax
	mov bx,ax

	mov ah,0x40
	mov ecx,gpfdumpend - gpftext
	mov edx,gpftext
	CALLINT21		// write to file

	mov ecx,[cargoids]
	test ecx,ecx
	jle .nogrffile

	mov ah,0x40
	mov edx,cargoids+4

	cmp ecx,1024
	jb .sizeok
	mov ecx,1024
	sub edx,4	// want to see what the size was
.sizeok:
	CALLINT21

.nogrffile:
	mov ah,0x3e
	pop ebx
	CALLINT21		// close file
#endif

.bailout:

	// --------------------------
	//	Done, return.
	// --------------------------

	// Restore all registers before returning to the original handler

#if WINTTDX
	pop ebp
#endif

	pop es
	popa

	leave

.abort:

#if WINTTDX
	jmp dword [prevexceptionhandler]

global noprevexceptionhandler
noprevexceptionhandler:
	xor eax,eax	// EXCEPTION_CONTINUE_SEARCH
	ret
#else
	jmp .stop
#endif
; endp catchgpf

	// generate current GRF file message, if any
	// write it over the cargoids data, since we're exiting
	// anyway that won't hurt, and even if it did they'd be
	// reset again for every .grf file
makegrfmsg:
	xor ecx,ecx

	cmp dword [curgrffeature],-2
	sbb al,al	// 0: not in getnewsprite; -1: in getnewsprite

	cmp dword [curgrffile],1
	sbb ah,ah	// -1: no curgrffile; 0: have curgrffile
	cmp al,ah	// 1: nothing, else we have something to report
	jg near .noreport

	mov cl,gpfprocessingend-gpfprocessing
	mov esi,gpfprocessing
	mov edi,cargoids+4
	rep movsb

	test al,al
	jz .nogrfid

	push edi
	lea edi,[byte esi+gpfgetpriteid-gpfprocessingend]
	mov esi,curgrfid
	mov ebx,1
	call hexwords

	add edi,byte gpfgetspriteeature-(gpfgetpriteid+8+2)
	mov esi,curgrffeature
	inc ebx
	call hexbytes

	mov cl,gpfgetspriteend-gpfgetsprite

	mov esi,curcallback
	cmp byte [esi],0
	je .nocallback

	add cl,gpfcallbackend-gpfcallback
	push ecx
	add edi,byte gpfcallbacknum-(gpfgetspriteeature+2+1)
	inc ebx
	call hexbytes
	pop ecx

.nocallback:
	mov esi,gpfgetsprite
	pop edi
	rep movsb

.nogrfid:
	mov eax,[curgrffile]
	test eax,eax
	jz .nogrffile

	mov cl,gpfgrfnameend-gpfgrfname
	mov esi,gpfgrfname
	rep movsb

	mov esi,eax
	mov ebx,256		// we will print at most 256 characters
	call checkbounds	// will exit this proc on error

	mov al,0
	mov ecx,ebx
	lodsb
.nextbyte:
	stosb
	lodsb
	test al,al
	loopnz .nextbyte

	push edi
	mov esi,curgrfsprite
	mov edi,gpfgrfspritenum
	mov ebx,1
	call hexwords
	pop edi

	mov esi,gpfgrfsprite
	mov cl,gpfgrfspriteend-gpfgrfsprite
	rep movsb

.nogrffile:
	mov ecx,edi
	mov dword [ecx-2],0x0A0D2E	// "." CRLF
	sub ecx,cargoids+4-1	// can't use lea ecx,[edi-(cargoids+4-1] (gives "invalid address")

.noreport:
	mov [cargoids],ecx
	ret

maketextidmsg:
	mov edi,[cargoids]
	lea edi,[edi+cargoids+4]	// append to grf msg, if any

	cmp word [lasttextids],byte -1
	je .done

	mov esi,gpftextidstart
	mov ecx,gpftextidfile-gpftextidstart
	rep movsb

	mov esi,lasttextids
.nextid:
	mov ebx,1
	call hexwords
	sub edi,5
	mov byte [edi-1]," "
	sub esi,2
	cmp word [esi],byte -1
	jne .nextid
	dec edi

	mov eax,[curmiscgrf]
	lea esi,[eax+1]		// make esi=1 if eax=0
	test eax,eax
	jz .nogrffile
	mov eax,[eax+spriteblock.filenameptr]
	test eax,eax
	jz .nogrffile

	mov esi,gpftextidfile
	mov cl,gpftextidtail-gpftextidfile
	rep movsb

	mov esi,eax
	mov ebx,256		// we will print at most 256 characters
	call checkbounds	// will exit this proc on error

	mov al,0
	mov ecx,ebx
	lodsb
.nextbyte:
	stosb
	lodsb
	test al,al
	loopnz .nextbyte

	xor esi,esi

.nogrffile:
	add esi,gpftextidtail	// skip first byte ")" if no grf file
	mov ecx,gpdtextidend
	sub ecx,gpftextidtail
	rep movsb

.done:
	mov ecx,edi
	sub ecx,cargoids+4+1
	mov [cargoids],ecx
	ret

extern lastpatchproc

makedebugmsg:
	mov edi,[cargoids]
	lea edi,[edi+cargoids+5]	// append to grf/textid msg, if any

	cmp dword [lastpatchproc],0
	je .done

	mov esi,gpfdebugstart
	mov ecx,gpfdebugend-gpfdebugstart
	rep movsb

	mov esi,lastpatchproc
	sub edi,gpfdebugend-gpfdebugpproc
	mov ebx,1
	call hexdwords

.done:
	mov ecx,edi
	sub ecx,cargoids+4
	mov [cargoids],ecx
	ret

	// make sure we don't accidentally cause a GPF ourselves!
	// Check the segment limit, and reduce the number of output
	// values if necessary

checkbounds:
#if WINTTDX
	pusha

	shl ebx,cl
	mov ch,1
	shl ch,cl
	movzx ecx,ch
.tryagain:
	pusha
	push ebx	// number of bytes
	push esi	// pointer
	call [isbadreadptr]
	test eax,eax
	popa
	jz .canreadall

	sub ebx,ecx
	ja .tryagain

.badreg:
	popa
	pop eax
	ret

.canreadall:
	popa
	ret
#else
	mov eax,ds
	lsl eax,eax
	jnz short .badreg	// bail if no access rights

	inc eax		// we *can* read the very last byte

	// calculate maximum ebx from the segment limit
	sub eax,esi
	jb short .badreg

	shr eax,cl
	jz short .badreg	// bail if zero values available

	cmp ebx,eax	// is ebx within that limit?
	jna short .goodofs

	mov ebx,eax

.goodofs:
	ret

.badreg:
	// can't get any useful bytes out of this, so bail.
	pop eax		// clear caller eip from stack
	ret		// and return to caller's caller
#endif
; endp checkbounds

	// print the num least significant hexnibbles of the value in eax
	// in:	eax=value to print
	//	cl=number of digits to print
	// modifies edi
	// destroys eax,ecx,edx
global hexnibbles
hexnibbles:

	xchg edx,eax
	xor eax,eax

	mov al,cl

	// number of bits to skip = (8-@@num)*4
	mov cl,8
	sub cl,al
	shl cl,2

	rol edx,cl	// skip the digits that aren't to be printed
	mov ecx,eax
.nextdigit:
	rol edx,4
	mov al,dl
	and al,0xf
	mov al,[cs:hexdigits+eax]
	stosb
	loop .nextdigit

	ret
; endp hexnibbles 

	// print ebx byte values from ds:esi
hexbytes:
	mov cl,0
	call checkbounds
.nextbyte:
	lodsb
	mov cl,2
	call hexnibbles
	inc edi
	dec ebx
	jnz .nextbyte
	ret
; endp hexbytes 

	// print ebx word values from ds:esi, advancing esi by four each time
hexwords:
	mov cl,2
	call checkbounds
.nextword:
	lodsd		// on the stack it's all dwords
	mov cl,4	// but only print a word
	call hexnibbles
	add edi,byte 2+4
	dec ebx
	jnz .nextword
	ret
; endp hexwords 

	// print ebx dword values from ds:esi
exported hexdwords
	mov cl,2
	call checkbounds
.nextdword:
	lodsd
	mov cl,8
	call hexnibbles
	add edi,byte 2
	dec ebx
	jnz .nextdword
	ret
; endp hexdwords 

	// print segment limits
seglimits:
	mov cl,2
	call checkbounds
.nextdword:
	lodsd
	lsl eax,eax
	jnz short .notvalid

	mov cl,8
	call hexnibbles
	sub edi,8

.notvalid:
	add edi,10
	dec ebx
	jnz .nextdword
	ret
; endp seglimits

	// print segment access rights
segrights:
	mov cl,2
	call checkbounds
.nextdword:
	lodsd
	lar eax,eax
	jnz short .notvalid

	mov cl,8
	call hexnibbles
	sub edi,8

.notvalid:
	add edi,10
	dec ebx
	jnz .nextdword
	ret
; endp segrights 


// the original handler's code
var originalgpfcode
	mov ds,[cs:dword 0x2f6e]
	mov [word 0x17e8],eax


var gpffile,	db "CRASH"
var gpffno,	db "###.TXT",0

// The output template

var gpftext,	db "TTD V"
var gpfttdv,	db      "######## Crash Log by"
var ttdpatchversion, db			     " TTDPatch ",TTDPATCHVERSION,13,10,13,10

		db "Exception "
#if WINTTDX
var gpferr,	db 	     "######## at "
#else
var gpferr,	db 	     "## at "
#endif
var gpfcs,	db		   "####:"
var gpfeip,	db			"########",13,10,13,10

		db "EAX       EBX       ECX       EDX",13,10
var gpfeax,	db "########  ########  ########  ########",13,10,13,10

		db "ESI       EDI       ESP       EBP",13,10
var gpfesi,	db "########  ########  ########  ########",13,10,13,10

		db "DS        ES        FS        GS        SS        Flags",13,10
var gpfds,	db "####      ####      ####      ####      ####      ########",13,10
var gpflim,	db "########  ########  ########  ########  ######## (Segment limits)",13,10
var gpfar,	db "########  ########  ########  ########  ######## (Access rights)",13,10,13,10

#if WINTTDX
		db "Bytes at DS:EIP",13,10
#else
		db "Bytes at CS:EIP",13,10
#endif
var gpfcode,	db "xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx xx",13,10,13,10

		db "Stack Dump:",13,10
var gpfstk,	db "########  ########  ########  ########  ########  ########  ########  ########",13,10
		db "########  ########  ########  ########  ########  ########  ########  ########",13,10
		db "########  ########  ########  ########  ########  ########  ########  ########",13,10
		db "########  ########  ########  ########  ########  ########  ########  ########",13,10

		db 13,10,"Handler Stack Dump (at "
var gpfhss,	db				"####:"
var gpfhesp,	db				     "########):",13,10
var gpfhstk,	db "########  ########  ########  ########  ########  ########  ########  ########",13,10
		db "########  ########  ########  ########  ########  ########  ########  ########",13,10
		db "########  ########  ########  ########  ########  ########  ########  ########",13,10
		db "########  ########  ########  ########  ########  ########  ########  ########",13,10

		db 13,10,"Patch flags:",13,10
var gpfflags
	times ((nflagdata-1) / 8) db "########  ########  ########  ########  ########  ########  ########  ########",13,10
	times ((nflagdata-1) % 8) db "########  "
		db "########",13,10,13,10

var gpfdumpend

var gpfprocessing, db "While processing sprites for "
var gpfprocessingend

var gpfgetsprite, db "ID "
var gpfgetpriteid, db 	"####; Feature "
var gpfgetspriteeature, db	      "##; "
var gpfgetspriteend

var gpfcallback, db "Callback "
var gpfcallbacknum, db 	     "##; "
var gpfcallbackend

var gpfgrfname,	db "GRF file "
var gpfgrfnameend

var gpfgrfsprite
		db "; Sprite number "
var gpfgrfspritenum
		db		   "#### (hex); "
var gpfgrfspriteend

var gpftextidstart, db "Processing text ID(s) "
var gpftextidfile, db " (misc GRF IDs from "
var gpftextidtail, db ")",13,10
var gpdtextidend

var gpfdebugstart, db "During patchproc ",
var gpfdebugpproc, db			"########",13,10
var gpfdebugend


	// Define TTDPatch version as a DWORD
	// MMmrbbbb  MM=major  m=minor  r=revision  bbbb=build
	// (must be single line, for package script)
global __ttdpatchvercode
__ttdpatchvercode equ (TTDPATCHVERSIONMAJOR<<24)+(TTDPATCHVERSIONMINOR<<20)+(TTDPATCHVERSIONREVISION<<16)+TTDPATCHVERSIONBUILD
var ttdpatchvercode, dd __ttdpatchvercode

global __ttdpatchrevision
__ttdpatchrevision equ TTDPATCHVERSIONSVNREV
