#include <defs.inc>
#include <frag_mac.inc>

global patchscreenshots
patchscreenshots:
	// fix screenshot keys
	patchcode oldcheckscreenshotkeys,newcheckscreenshotkeys,1,1
	mov byte [edi+lastediadj-5],0xbb
	mov word [edi+lastediadj+8],0x2588
	mov byte [edi+lastediadj+14],0x90
	mov byte [edi+lastediadj+26],0xeb	// avoid repeated check with a remapped key

#if WINTTDX
	// the rest of the stuff is WinTTDX-specific
	patchcode oldreadpalette,newreadpalette,1,2
	patchcode oldreadpalette,newreadpalette,1,1
	patchcode oldint21create,newint21create,1,1
	patchcode oldbackspacefrombuffer,newbackspacefrombuffer,1,1
	multipatchcode oldisbackspace,newisbackspace,2
	stringaddress oldgenbackspace
	mov byte [edi],0x2e
	mov byte [edi+8],0x7f		// delete generates character 0x7f (ASCII DEL)
#endif
	ret


begincodefragments

codefragment oldcheckscreenshotkeys,-44
	jl $+2+15
	db 0xfe,0xd	// dec byte ptr ...

codefragment newcheckscreenshotkeys
	call runindex(checkscreenshotkeys)

#if WINTTDX
//codefragment findtmpfilename,-4
//	mov cx,9
//	push cx
//
//codefragment oldfixscreenshot,-7
//	xor cx,cx
//	xor dx,dx
//	db 66h,0b8h	// mov ax,....
//
//codefragment newfixscreenshot
//	call runindex(fixscreenshot)
//	nop

codefragment oldreadpalette,-6
	mov dx,0x3c7

codefragment newreadpalette
	call runindex(readpalette)
	jmp newreadpalette_start+31

codefragment oldint21create,2
	db 0x0,0x0,0x40	// push 40000000h
	db 0x8b		// mov eax,[....]

codefragment newint21create
	db 0xc0		// change mode to read/write

codefragment oldbackspacefrombuffer,-3
	cmp dword [ebp-4],byte 8
	db 0x0f,0x84,0x12		// jz near $+6+0x12

codefragment newbackspacefrombuffer
	call runindex(chkcurrentkeyremap)
	setfragmentsize 13

codefragment oldisbackspace,3
	jmp short $+2-0x13
	cmp al,0x2e
	db 0x74			// jz short...

codefragment newisbackspace
	db 8

codefragment oldgenbackspace,-1
	jnz near $+6+0xa
	push byte 0x2e

// no codefragment newgenbackspace -- replacement defined in patches.ah
#endif

endcodefragments
