#include <defs.inc>
#include <var.inc>
#include <frag_mac.inc>
#include <bitvars.inc>
#include <win32.inc>

extern miscmodsflags,patchflags
extern TransmitAction
extern MPtransferbuffer,MPpacketnum,MPtimeout


global patchnetplay
patchnetplay:
#if WINTTDX
// Replace functions loaded from dplay.dll with ones loaded from dplayx.dll.
// This needs at least DirectX 5, but seems to work much better under WinXP.

	pusha
	push adplayx
	call dword [LoadLibrary]	// LoadLibrary("dplayx.dll")
	or eax,eax
	jz .nodplayxdll
	mov [dplayxhandle],eax

	push dword aDirectPlayEnumerate
	push dword [dplayxhandle]
	call dword [GetProcAddress]	// GetProcAddress(dplayx,"DirectPlayEnumerate")
	or eax,eax
	jz .noenum
	mov [DirectPlayEnumerate],eax
.noenum:

	push dword aDirectPlayCreate
	push dword [dplayxhandle]
	call dword [GetProcAddress]	// GetProcAddress(dplayx,"DirectPlayCreate")
	or eax,eax
	jz .nocreat
	mov [DirectPlayCreate],eax
.nocreat:
.nodplayxdll:
	popa

	mov edi,[TransmitAction]
	mov eax,[edi+12]
	mov [MPtransferbuffer],eax

	testmultiflags disconnectontimeout
	setnz bl
	stringaddress oldretrytransfer,1,3
	mov eax,[edi+31]
	mov [MPpacketnum],eax
	mov eax,[edi+6]
	mov [MPtimeout],eax
	mov dword [edi+1],100		// decrease waiting before re-send
	test bl,bl
	jz .dontpatch
	storefragment newretrytransfer
.dontpatch:
	stringaddress oldretrytransfer,1,0
	inc edi
	mov dword [edi],100		// decrease waiting before re-send
	stringaddress oldretrytransfer,1,0
	mov dword [edi+1],100		// decrease waiting before re-send
	test bl,bl
	jz .dontpatch2
	storefragment newretrytransfer
.dontpatch2:
#if DEBUGNETPLAY
	pusha
	push aOutputDebugStringA
	push dword [kernel32hnd]
	call dword [GetProcAddress]
	mov [DebugMsg],eax
	popa
#endif
#endif

	patchcode oldtransmitendofactions,newtransmitendofactions,1,1,,{test word [miscmodsflags],MISCMODS_NODESYNCHWARNING},z
	ret

#if WINTTDX
adplayx: db "dplayx.dll",0

uvard dplayxhandle

aDirectPlayEnumerate: db "DirectPlayEnumerate",0
aDirectPlayCreate: db "DirectPlayCreate",0

#if DEBUGNETPLAY
aOutputDebugStringA: db "OutputDebugStringA",0 
#endif
#endif


	// fix screenshots (and other keyboard-related things)
	// if win2k or generalfixes or enhancedkbdhandler is turned on

begincodefragments

codefragment oldtransmitendofactions
	cmp byte [numplayers],1
	jz $+2+14

codefragment newtransmitendofactions
	call runindex(transmitendofactions)
	setfragmentsize 7


endcodefragments

begincodefragments

#if WINTTDX
codefragment oldretrytransfer
	add eax,1000

codefragment newretrytransfer
	call runindex(retrytransfer)
	setfragmentsize 10
#endif


endcodefragments
