// Enhanced keyboard handler
// (right now only DOS is supported)

#include <std.inc>
#include <flags.inc>
#include <misc.inc>

extern malloc,int21handler,patchflags



uvarb lastkeyremapped		// nonzero if the key has been remapped

uvard kbdmapptr,1,s		// pointer to the keyboard map file



#if WINTTDX


#define MAX_KBDMAP_SIZE 256	// currently TTDPatchW uses only a direct byte-byte translation table

var kbdmapfilename, db "ttdpatchw.kbd",0

// Translate a character returned by the Windows keyboard driver
// and add it to the character queue
// in:	EAX = character returned by Windows
global translatewinchar
translatewinchar:
	push ebx
	push edx
	mov edx,eax
	mov ebx,[kbdmapptr]
	xlatb
	bts eax,30		// mark as remapped (arbitrary bit above #20)
	or al,al
	jnz .toqueue

	xchg eax,edx		// not remapped, use the original char

.toqueue:
	push eax
	call $
ovar .addtoqueuefn,-4,$,translatewinchar

	pop eax			// stack cleanup
	pop edx
	pop ebx
	ret


// Set variable if the key being removed from queue was remapped
// in:	EAX = code
global chkcurrentkeyremap
chkcurrentkeyremap:
	btr eax,30
	setc byte [lastkeyremapped]
	mov [ebp-4],eax		// replicate the overwritten code
	ret




#else	// *** DOS ***


#define MAX_KBDMAP_SIZE 32768	// currently we just allocate 32KB for the map file and do not load more

var kbdmapfilename, db "ttdpatch.kbd",0

%assign KBDSTATE_BIT_CMDSENT	0        // command sent, waiting for ACK
%assign KBDSTATE_BIT_GOTACK	1        // ACK received
%assign KBDSTATE_BIT_UPDATELEDS	2        // have to update LEDs

var keyboardstate, db 1<<KBDSTATE_BIT_UPDATELEDS	// set on init so that LEDs are updated on first keyboard input
			
			

SHIFT_Shift	equ 0x01
SHIFT_Ctrl	equ 0x02
SHIFT_Alt	equ 0x04
SHIFT_NumLock	equ 0x08
SHIFT_RShift	equ 0x10
SHIFT_RCtrl	equ 0x20
SHIFT_RAlt	equ 0x40
SHIFT_CapsLock	equ 0x80

var shiftkeylist
	db KEY_LShift,	SHIFT_Shift
	db KEY_LCtrl,	SHIFT_Ctrl
	db KEY_LAlt,	SHIFT_Alt
	db KEY_RShift,	SHIFT_Shift+SHIFT_RShift
	db KEY_RCtrl,	SHIFT_Ctrl+SHIFT_RCtrl
	db KEY_RAlt,	SHIFT_Alt+SHIFT_RAlt

// Process a keypress
// in:	AL = Shift pressed: 00h=left or right, 80h=none
//	EBX = scan code (bit 7 set if extended)
// out:	AL = character (extended-ASCII) code
//	CF set = extended mapping, don't check for Ctrl-C etc.
// safe:AH,EBX
global keyscantochar
keyscantochar:
	cld
	pusha
	xchg eax,ebp
	mov byte [lastkeyremapped],0

	// check for 'Lock' keys
	mov edi,kbdflags
	cmp bl,KEY_CapsLock
	jne .notcapslock
	xor byte [edi],4
	jmp short .updateleds

.notcapslock:
	cmp bl,KEY_ScrollLock
	jne .notscrolllock
	xor byte [edi],8
	jmp short .updateleds

.notscrolllock:
	cmp bl,KEY_NumLock
	je .updateleds		// NumLock status is processed by TTD

	btr dword [keyboardstate],KBDSTATE_BIT_UPDATELEDS
	jnc .leds_ok

.updateleds:
	testflags dontshowkbdleds
	jc .leds_ok

	// Update states of the keyboard LEDs
	// [hope this code works for everyone (or at least doesn't crash or hang any machine)...
	//  oh well, one can use -!I- to disable it, anyway -- Marcin]
	mov ah,0xed		// command to set LEDs
	call sendcommandtokbd
	jnz .kbderr
	mov ah,[edi]
	and ah,0xE		// now: bit 1=NumLock, 2=CapsLock, 3=ScrollLock, other bits=0
	btr eax,11		// check bit 3+8 (because in AH)
	adc ah,0		// move ScrollLock to bit 0 of AH
	call sendcommandtokbd
	jz .leds_ok

.kbderr:
	mov ah,0xf4		// try to reset the keyboard
	call sendcommandtokbd

.leds_ok:

	// make a map of shift states
	// EDI still points at keyboard flags map
	xor eax,eax
	test byte [edi],2
	jz .nonumlock
	or al,SHIFT_NumLock
.nonumlock:
	test byte [edi],4
	jz .nocapslock
	or al,SHIFT_CapsLock
.nocapslock:
	xchg eax,edx
	
	mov esi,shiftkeylist
	mov edi,keypresstable
	xor eax,eax
	xor ecx,ecx
	mov cl,6

.shiftkeyloop:
	lodsb
	cmp byte [edi+eax],0
	lodsb
	jnz .nextshiftkey
	or dl,al
.nextshiftkey:
	loop .shiftkeyloop
	
	// now EDX = map of currently active shift keys, EBX = scan code, EBP = saved EAX from entry

	// check the extended map for a match
	mov esi,[kbdmapptr]

.keymaploop:
	lodsd			// now AL=scan-code, AH=shift-mask, EAX<16:23>=shift-stat, EAX<24:31>=ascii
	or al,al
	jz .endofkeymap
	cmp al,bl
	jnz .keymaploop		// not this key
	or ah,ah
	jns .chkshiftmask

	// CapsLock bit set in the mask -- use this mapping only if an edit control is active
	bt dword [uiflags],10
	jnc .keymaploop

.chkshiftmask:
	mov cl,dl
	and cl,ah
	shr eax,16
	cmp al,cl
	jnz .keymaploop		// shift keys don't match

	// this is the right key (character value in AH)
	or ah,ah		// if the character is 0 don't mark the key as remapped
	jz .mapped		// (it won't trigger any hotkey because it's 0, but direct keytable checks will trigger)
	mov byte [lastkeyremapped],1

.mapped:
	stc
	jmp short .done

.endofkeymap:
	// key mapping not found, use TTD mapping
	mov edx,ebp		// restore TTD's shift flag into DL
	movsx eax,bl
	and al,0x80		// table for extended/shifted keys is 0x80 bytes earlier
	or bl,dl
	mov ah,[dword eax+ebx-0x101]
ovar .chartable,-4,$,keyscantochar
	// CF=0 after the last OR

.done:
	mov [esp+0x1c],ah	// have this key returned in AL
	popa
	ret
; endp keyscantochar


// send a command to keyboard, wait for ACK
// in:	AH = command code
// out: ZF set = OK, clear = error
// uses:AX,ECX
sendcommandtokbd:
.wait1:
	in al,0x64
	test al,2
	jnz .wait1

	mov al,ah
	out 0x60,al

.wait2:
	in al,0x64
	test al,2
	jnz .wait2

	// wait for ACK from keyboard
	// ** TODO ** should implement a timeout... otherwise lack of keyboard response will cause TTD to hang
.wait3:
	in al,0x64
	test al,1
	jz .wait3

	in al,0x60
	mov ah,al

	// pulse the high bit of port 61h to reset pending IRQ
	// [don't know if it's really necessary but seems to do no harm -- Marcin]
	in al,0x61
	or al,0x80
	out 0x61,al
	and al,0x7F
	out 0x61,al

	cmp ah,0xfa		// was that an ACK?
	ret


#endif	// !WINTTDX



// initialize the keyboard mapping
// called from within patchprocs, i.e. ES=DS
global initializekeymap
initializekeymap:
	pusha
	mov edx,kbdmapfilename
	mov ax,0x3d00
	CALLINT21
	movzx eax,ax		// file handles are 16-bit
	jnc .loadfile

	// always allocate the buffer if recordversiondata is on
	sbb eax,eax		// EAX = -1
	testflags recordversiondata
	jnc .fail

.loadfile:
	// allocate keyboard map buffer
	push eax
	push MAX_KBDMAP_SIZE
	call malloc
	pop edi
	pop ebx			// EBX = file handle, or -1 if couldn't open
	jc .fail_close

	// clear the buffer
	mov [kbdmapptr],edi
	mov edx,edi
	xor eax,eax
	mov ecx,MAX_KBDMAP_SIZE/4
	rep stosd

	// load the keyboard map file
	test ebx,ebx
	js .nofile
#if WINTTDX
	mov ecx,MAX_KBDMAP_SIZE
#else
	mov ecx,MAX_KBDMAP_SIZE-4	// make sure the last entry is an end mark
#endif
	mov ah,0x3f
	CALLINT21

.fail_close:
	// close the file
	test ebx,ebx
	js .nofile
	mov ah,0x3e
	CALLINT21
.nofile:

#if !WINTTDX
	// read the DOS's Lock keys status
	push es
	push 0x37
	pop es
	mov al,[word es:0x417]
	shl al,1			// get rid of the Insert key status bit
	btr eax,5			// move the Scroll Lock status...
	rcr al,1			// ...to the highest bit
	shr al,4			// now shift the bits to their right places
	mov [kbdflags],al
	pop es
#endif

	testflags enhancedkbdhandler,bts

.fail:
	popa
	ret
; endp initializekeymap


#if !WINTTDX

// Called within mouse emulation code to check if either Alt key is pressed
// if the key was remapped and an edit control is active, disable emulation
// in:	AL = right Alt status (00h=pressed, 80h=released)
//	CX,DX = mouse position
// out:	ZF set = may check for arrows/Insert/Home to emulate mouse
//	BX = 0 (necessary because we may skip the code that does it)
// safe:AX
global checkmouseemualt
checkmouseemualt:
	xor bx,bx
	bt dword [uiflags],10
	jnc .allowed

	cmp byte [lastkeyremapped],0
	jnz .done

.allowed:
	and al,[keypresstable+KEY_LAlt]

.done:
	ret
; endp checkmouseemualt

#endif	// !WINTTDX


// If the key just pressed was remapped and an edit control is active
// don't let code 0xE0 trigger exit window; in DOS, also don't trigger function keys
// character codes 0x7b..0x87 (reserved, not displayed anyway) are always treated as hotkeys
// in:	AL = character code
// out:	CF set = skip to edit control code
//	CF clear and SF set = can only be a hotkey
//	CF, SF and ZF clear = check for function keys
//	otherwise stop processing the key (it's the exit key)
// safe:everything except AL? (EBX for sure)
global checkforexitkey
checkforexitkey:
	cmp al,0x87
	ja .notreserved
	mov bl,al
	add bl,0x80-0x7b
	jns .notreserved

.done:
	ret

.notreserved:
	cmp byte [lastkeyremapped],0
	jz .notedit
	bt dword [uiflags],10
	jc .done

.notedit:
	cmp al,0xe0			// exit key? (overwritten)
	jz .exitkey
	mov ah,0
	sahf				// ensure CF=SF=ZF=0
	ret

.exitkey:
	bts dword [ttdsystriggers],1	// overwritten
	cmp al,al			// ensure CF=SF=0 and ZF=1
	ret
; endp checkforexitkey


// Called to check for arrow keys to move the landscape
// if the key was remapped and an edit control is active, disable the function
// in:	[bored writing that stuff, see location 1257A3 in DOS UK version -- Marcin]
// out:	ZF set = disabled
global checkforarrowkeys
checkforarrowkeys:
	jz .done

	cmp byte [lastkeyremapped],0
	jz .allowed

	bt dword [uiflags],10
	jnc .allowed
	cmp eax,eax		// ZF set

.done:
	ret

.allowed:
	xor ax,ax
	mov bx,ax
	sahf			// crude but effective way to clear ZF
	ret
; endp checkforarrowkeys
