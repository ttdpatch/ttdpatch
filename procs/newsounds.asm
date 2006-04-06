#include <defs.inc>
#include <frag_mac.inc>
#include <win32.inc>
#include <patchproc.inc>

patchproc newsounds, patchnewsounds

extern SampleCatDataPtr,SampleCatLoadedOK,generatesound.zoomvolume,malloccrit
extern playorigsound,PlayCustomSound
extern PrepareCustomSound,texthandler
extern spriteerror, spriteerrortype

#include <textdef.inc>

patchnewsounds:
	stringaddress oldgeneratesound,1,1
	mov eax,[edi+11]
	mov [generatesound.zoomvolume],eax
	storefragment newgeneratesound
#if WINTTDX
	pusha

	//CALLINT3
	push NewSoundDllName
	call [LoadLibrary]
	test eax,eax
	push eax
	jz .error

	push aPlayCustomSample
	push eax
	call [GetProcAddress]
	test eax,eax
	jz .error
	mov [PlayCustomSound],eax

	push aPrepareCustomSample
	push dword [esp+4]
	call [GetProcAddress]
	test eax,eax
	jz .error
	mov [PrepareCustomSound],eax
.nocustom:

	pop ebx

// replace old mpssnd_c.dll imports with ours
	mov esi,SoundFuncNamePtrs
	mov edi,0x423548		// address of first import
	mov ecx,5

.nextimport:
	lodsd

	push ebx
	push ecx
	push esi
	push edi

	push eax	// name of proc
	push ebx	// handle of library
	call [GetProcAddress]

	pop edi
	pop esi
	pop ecx
	pop ebx

	test eax,eax
	jz .error
	mov [edi],eax
	add edi,4
	loop .nextimport
	popa
	ret

.error:
	pop eax
	mov ax,ourtext(patchsnd_dll_notfound)
	call texthandler
	mov [spriteerror],esi
	mov byte [spriteerrortype],5
	popa
	ret

#else
	add edi, lastediadj+24
	storefunctioncall playorigsound
	storeaddress findsoundcomstring,1,1,soundcomoffset
	patchcode execsoundcom
	patchcode initsounddriver
	patchcode allocmemfordriver
	patchcode keepsoundplaying
	patchcode stopsound
	patchcode uninstallsound

//now, load sample.cat into memory entirely
	pusha

	mov ax,0x3d00		// open file, read only
	mov edx,SampleCatName	// filename
	int 0x21
	jc .error

	mov bx,ax		// file handle
	mov ax,0x4202		// seek in file, origin: end
	xor ecx,ecx
	xor edx,edx		// offset=0
	int 0x21
	jc .error_close
	shl edx,16
	mov dx,ax

	push edx
	call malloccrit
	pop dword [SampleCatDataPtr]

	mov ebp,edx

	mov ax,0x4200		// seek in file, origin: beginning
	xor ecx,ecx
	xor edx,edx		// offset=0
				// bx still has the handle
	int 0x21
	jc .error_close

	mov ah,0x3f			// read from file
					// bx still has the handle
	mov ecx,ebp			// number of bytes to read
	mov edx,[SampleCatDataPtr]	// pointer to buffer
	int 0x21
	jc .error_close

	mov byte [SampleCatLoadedOK],1

.error_close:
	mov ah,0x3e		// close file
				// bx still has the handle
	int 0x21

.error:
	popa
	ret
#endif

#if WINTTDX
NewSoundDllName: db "patchsnd.dll",0
aPlayCustomSample: db "PlayCustomSample",0
aPrepareCustomSample: db "PrepareCustomSample",0

aReleaseBankFile: db "ReleaseBankFile",0
aSoundInit: db "SoundInit",0
aInitializeBankFile: db "InitializeBankFile",0
aStartFx: db "StartFx",0
aSoundShutDown: db "SoundShutDown",0

SoundFuncNamePtrs: dd aReleaseBankFile,aSoundInit,aInitializeBankFile,aStartFx,aSoundShutDown
#else
SampleCatName: db "SAMPLE.CAT",0
#endif



begincodefragments

codefragment oldgeneratesound
	imul bx,dx
	shr bx, 7

codefragment newgeneratesound
	icall generatesound
	setfragmentsize 8

#if !WINTTDX
codefragment findsoundcomstring
	db "SOUND.COM",0

codefragment oldexecsoundcom
	mov edx, 0
soundcomoffset equ $-4

codefragment newexecsoundcom
	jmp short fragmentstart+28

codefragment oldinitsounddriver,-7
	dd 0
	push 0
	db 0x68

codefragment newinitsounddriver
	ijmp initsounddriver

codefragment oldallocmemfordriver
	jz $+2+0x3a
	db 0x31,0xf6		// "xor esi,esi" , with different encoding than NASM generates by default

codefragment newallocmemfordriver
	db 0xeb

codefragment oldkeepsoundplaying,-7
	dd 3
	push 0

codefragment newkeepsoundplaying
	ijmp keepsoundplaying

codefragment oldstopsound,-6
	dd 1
	push 0

codefragment newstopsound
	icall stopsound
	setfragmentsize 31, 1

codefragment olduninstallsound,-6
	dd 0x14
	push 0

codefragment newuninstallsound
	icall uninstallsound
	setfragmentsize 26, 1
#endif


endcodefragments
