#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <human.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <player.inc>
#include <bitvars.inc>
#include <misc.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>

extern patchflags
extern drawtextfn, currscreenupdateblock

exported extradetailswagon
	pusha
	
	push edi
	mov bx, 0x882D	// TextID
	mov edi, [currscreenupdateblock]
	mov al, 0x10
	call [drawtextfn]
	pop edi
	
	extcall showyearbuilt
	mov [textrefstack+2],ax
	
	movzx ebx, byte [edi+veh.vehtype]
	pusha
	mov esi, edi
	xor eax, eax	// to be sure, blank eax
	extcall GetTrainCallbackSpeed
	imul ax, 10
	shr ax, 4
	mov [textrefstack],ax	// for later
	popa
	
	testmultiflags wagonspeedlimits
	jz .nolimit
	cmp word [textrefstack],0
	je .nolimit
	cmp word [textrefstack],byte -1
	je .nolimit
	
	mov bx, statictext(extradetailswagons)
	mov edi, [currscreenupdateblock]
	mov al, 0x10
	add cx, 10
	call [drawtextfn]
.nolimit:
	popa
	ret
