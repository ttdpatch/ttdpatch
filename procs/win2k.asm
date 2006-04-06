#if WINTTDX
#include <defs.inc>
#include <frag_mac.inc>
#include <win32.inc>

extern int21handler, int21seekfrombegin, int21restofhandler
extern savedplaysound, savedsendstring, alignedsendstring
extern savedstrcmp1, savedstrcmp2

def_indirect alignedsendstring

global patchwin2k
patchwin2k:
	mov edi,dword [int21handler]
	copyrelative int21seekfrombegin,6
	storerelative int21restofhandler,edi+10
	storefragment newint21handler

	patchcode oldtickcount,newtickcount,2,2

	stringaddress oldselectremover,1,1
	mov byte [edi],0x90		// nop out the cli
	mov byte [edi+0x23],0x90	// and sti

	stringaddress oldplaysound,1,1
	copyrelative savedplaysound,4
	storefragment newplaysound

	mov edi,mciSendString
	mov eax, [edi]
	mov dword [ savedsendstring], eax
	mov eax, [alignedsendstring_indirect]
	mov [edi], eax

	stringaddress oldcheckifplaying,1,1
	copyrelative savedstrcmp1,13
	copyrelative savedstrcmp2,13
	storefragment newcheckifplaying

	// this is the same for both known and unknown
	// versions, so save some bytes by making a proc out of it
	// (it's in win2k.asm)
// don't need this anymore I think
//	call fixdirectxmethodcalls
	// we patch the imports from winmm.dll to use the dxmcimidi.dll calls instead
	// we could have just hard-patched the .exe, but decided not to.
	call runindex(initdxmidi)

	mov cl,4
	xor edi,edi

.nextvehwindow:
	push ecx
	dec ecx
	setz cl
	patchcode oldsetupvehwindow,newsetupvehwindow,1,ecx
	pop ecx
	loop .nextvehwindow

	mov byte [0x404dad],0		// disable Windows platform check

	// remove all FS prefixes to allow execution on Windows XP 64
	// not using stringaddress etc. because there are too many occurences
	// and this is compact and fast enough anyway

	mov eax,0x18048A64	// mov al,[fs:eax+ebx]
	mov edi,0x500000
	mov ecx,0x100000
.findnextfs:
	repne scasb
	jecxz .done
	cmp [edi-1],eax
	jne .findnextfs
	mov byte [edi-1],0x26	// mov al,[es:eax+ebx]
	jmp .findnextfs
.done:
	ret

begincodefragments

codefragment newint21handler
	jmp runindex(alignedint21handler)

codefragment oldtickcount
	call dword [GetTickCount]
	// 0x423000 is the .idata section, so it should be .idata+03e8h, can't use getds
	// this is a patch changing code in the .text segment,
	// .text and .idata segments are constant between english/american/spanish/german/spanish
	// comments ?

codefragment newtickcount
	xor  edx,edx
	setfragmentsize 6

codefragment oldselectremover
	cli
	db 0x66, 0x0f, 0xba	//bts	word ptr [4F81A6h],5

codefragment oldplaysound
	push	ecx
	push	ebx
	push	eax
	db 0xe8		// call playsound
	
codefragment newplaysound
	jmp	runindex(alignedplaysound)

codefragment oldcheckifplaying
	push	0x41E51C	// db "playing",0
	// this needs to be done better!
	// prehaps find a better string to search on
	// this was the best i could find :-(

codefragment newcheckifplaying
	call	runindex(strcmpplayingseeking)
	setfragmentsize 20,1

codefragment oldsetupvehwindow
	movzx eax,dx
	shl eax,vehicleshift

codefragment newsetupvehwindow
	call runindex(setupvehwindow)

endcodefragments

#endif

