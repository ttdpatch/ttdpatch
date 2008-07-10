// Resolution Patches by Oskar Eisemuth

#if WINTTDX

#include <defs.inc> 
#include <frag_mac.inc> 


extern TTDPatch_prognameW,abortttd,callMessageBoxW,malloc
extern outofmemoryerror,redrawscreen.maxx,redrawscreen.maxy,reserrorstring
extern resheight,reswidth,screenblocks,screenblocksx
extern screenblocksy

global patchresolution

begincodefragments

codefragment oldmov_eax_mainwinsizestart, 1
	mov ebx, 1E00280h

codefragment newwinsize
	dw 0xFFFF
newwinsize.x equ $-2
	dw 0xFFFF
newwinsize.y equ $-2

codefragment oldmov_eax_mainwinsizeedit, 1
	mov ebx, 1CA0280h

codefragment oldmov_eax_mainwinsizegame, 1
	mov ebx, 1BE0280h

codefragment oldmov_eax_maintoolbar, 1
	mov ebx, 160280h

codefragment findmov_eaxstatusbarpos, 1
	mov eax, 1D40000h

codefragment finddragmodebound, 3
	cmp bx, 1D4h

codefragment findmov_dxstatusbartexty, 2
	mov dx, 1D5h

codefragment newdxxother
	dw 0xFFFF
dxxother equ $-2


codefragment findmov_bxstatusbarscry, 2
	mov bx, 1D5h
	db 0x66

codefragment findmov_esinewsfiny1, 4
	mov word [esi+30h], 189h

codefragment findmov_esinewsfiny2, 4
	mov word [esi+30h], 136h

codefragment findmov_esinewsfiny3, 4
	mov word [esi+30h], 15Eh


codefragment oldaddbp_1E0h, 3
//Found 1
add     bp, 1E0h

codefragment newdxmaxy
	dw 0xFFFF
dxmaxy equ $-2

codefragment oldmovbx_27Fh, 2
//Found 3
mov     bx, 27Fh

codefragment newdxmaxx_1
	dw 0xFFFF
dxmaxx_1 equ $-2

codefragment oldcmpax_1E0h, 2
//Found 1
cmp     ax, 1E0h

codefragment oldmovebx_280h, 1
//Found 3
mov     ebx, 280h

global dxmaxx
codefragment newdxmaxx
	dw 0xFFFF
dxmaxx equ $-2

codefragment oldcmpdword_ebp_0CCh__280h, 6
//Found 3
cmp     dword [ebp-0CCh], 280h

codefragment oldpush1E0h, 1
//Found 6
push    1E0h

codefragment oldmoveax_280h, 1
//Found 3
mov     eax, 280h

codefragment oldpush280h, 1
//Found 6
push    280h

codefragment oldsubax_1E0h, 2
//Found 2
sub     ax, 1E0h

codefragment oldmovdword_ebp_98h__280h, 6
//Found 1
mov     dword [ebp-98h], 280h

codefragment oldsubbp_1E0h, 3
//Found 1
sub     bp, 1E0h

codefragment oldsubax_280h, 2
//Found 2
sub     ax, 280h

codefragment oldaddedx_280h, 2
//Found 1
add     edx, 280h

codefragment oldmovdx_1DFh, 2
//Found 8
mov     dx, 1DFh

codefragment newdxmaxy_1
	dw 0xFFFF
dxmaxy_1 equ $-2

codefragment oldmovcx_1E0h, 2
//Found 1
mov     cx, 1E0h

codefragment oldmovdx_280h, 2
//Found 4
mov     dx, 280h

codefragment oldmovesi_280h, 1
//Found 1
mov     esi, 280h

codefragment oldcmpdword_ebp_8__280h, 3
//Found 3
cmp     dword [ebp-8], 280h

codefragment oldmovdi_280h, 2
//Found 1
mov     di, 280h

codefragment oldmovbp_1E0h, 2
//Found 3
mov     bp, 1E0h

codefragment oldmovdword_ebp_4__1E0h, 3
//Found 1
mov     dword [ebp-4], 1E0h

codefragment oldmovbp_280h, 2
//Found 4
mov     bp, 280h

codefragment oldcmpbp_280h, 3
//Found 1
cmp     bp, 280h

codefragment oldcmpdword_ebp_28h__27Fh, 3
//Found 1
cmp     dword [ebp-28h], 27Fh


codefragment oldmovcx_27Fh, 2
//Found 5
mov     cx, 27Fh

codefragment oldcmpcx_280h, 3
//Found 1
cmp     cx, 280h

codefragment oldcmpdword_ebp_4__1E0h, 3
//Found 3
cmp     dword [ebp-4], 1E0h

codefragment oldcmpbp_1E0h, 3
//Found 2
cmp     bp, 1E0h

codefragment oldmovdword_ebp_2Ch__1DFh, 3
//Found 1
mov     dword [ebp-2Ch], 1DFh

codefragment oldmovdword_ebp_8__280h, 3
//Found 1
mov     dword [ebp-8], 280h

codefragment oldcmpdx_1DFh, 3
//Found 1
cmp     dx, 1DFh

codefragment oldcmpdword_ebp_14h__280h, 3
//Found 3
cmp     dword [ebp-14h], 280h


codefragment oldcmpdx_280h, 3
//Found 2
cmp     dx, 280h

codefragment oldmovdword_ebp_28h__27Fh, 3
//Found 1
mov     dword [ebp-28h], 27Fh

codefragment oldcmpcx_27Fh, 3
//Found 1
cmp     cx, 27Fh

codefragment oldsubcx_280h, 3
//Found 1
sub     cx, 280h

codefragment oldsubeax_280h, 1
//Found 1
sub     eax, 280h

codefragment oldimulcx_280h, 3
//Found 1
imul    cx, 280h

codefragment oldmovebp_280h, 1
//Found 2
mov     ebp, 280h

codefragment oldmovcx_280h, 2
//Found 1
mov     cx, 280h

codefragment oldcmpdword_ebp_10h__1E0h, 3
//Found 3
cmp     dword [ebp-10h], 1E0h

codefragment oldcmpdword_ebp_0ACh__280h, 6
//Found 3
cmp     dword [ebp-0ACh], 280h


codefragment oldsubbp_280h, 3
//Found 1
sub     bp, 280h

codefragment oldcmpax_280h, 2
//Found 1
cmp     ax, 280h

codefragment oldcmpeax_280h, 1
//Found 2
cmp     eax, 280h


codefragment oldcmpdx_1E0h, 3
//Found 1
cmp     dx, 1E0h

codefragment oldmovdword_ebp_94h__1E0h, 6
//Found 1
mov     dword [ebp-94h], 1E0h

codefragment oldcmpdword_ebp_0C8h__1E0h, 6
//Found 3
cmp     dword [ebp-0C8h], 1E0h

codefragment oldmovecx_280h, 1
//Found 1
mov     ecx, 280h

codefragment oldaddbx_1E0h, 3
//Found 1
add     bx, 1E0h

codefragment oldaddbp_280h, 3
//Found 1
add     bp, 280h

codefragment oldcmpcx_1E0h, 3
//Found 2
cmp     cx, 1E0h

codefragment oldcmpdword_ebp_2Ch__1DFh, 3
//Found 1
cmp     dword [ebp-2Ch], 1DFh

codefragment oldmovbx_280h, 2
//Found 1
mov     bx, 280h

codefragment oldcmpeax_1E0h, 1
//Found 2
cmp     eax, 1E0h

codefragment oldmovsi_280h, 2 
//Found 1
mov     si, 280h

codefragment oldcmpdword_ebp_0A8h__1E0h, 6
//Found 3
cmp     dword [ebp-0A8h], 1E0h

codefragment findtooltipchecky, 2
	mov ax, 1B4h

codefragment findscreenshotsize, 3
	mov dword [edi+8], 1DF027Fh

codefragment newaddscreenmode
	icall addscreenmode

	
// gigant screenshots:	
codefragment findgiantscreenshotpcxheader, 3
	mov dword [edi+8], 59F077Fh

codefragment findgiantscreenshotsize, 1
	mov ecx, 2A3000h	//1920x1440

codefragment findgiantscreenshotsizeqx, 2
	imul edx, 0E1000h	//640x1440

codefragment findgiantscreenshotwritetotmp, 1
	mov ecx, 4B000h
	mov ah, 40h

codefragment findgiantscreenshotreadfromtmp, 1
	mov ecx, 4B000h
	mov ah, 3Fh
	
codefragment findgiantscreenshotmovepointer, 6
	mov ax, 4201h
	mov dx, 500h
	xor cx, cx

codefragment_call newcalcupdateblockrect,calcupdateblockrect,6

endcodefragments

patchresolution:
	// Some sanity checks would be good here ...
	
	// Mode 5 / UpdateMode=2 has strange mouse problems, so we don't even try to let the user use it:
	// At this time the registry isn't read yet, so no error message, simple set updatemode to 1

	mov byte [0x406A3B], 0xB8	
	mov dword [0x406A3B+1], 1
	mov byte [0x406A3B+5], 0x90

	mov ax, word [reswidth]
	mov word [dxmaxx], ax
	mov word [redrawscreen.maxx], ax
	dec ax
	mov word [dxmaxx_1], ax
	inc ax

	mov bx, word [resheight]
	mov word [dxmaxy], bx
	mov word [redrawscreen.maxy], bx
	dec bx
	mov word [dxmaxy_1], bx
	inc bx

	// "patching" the resolution to 640x480 fails without version data.
	cmp ax, 640
	jne .dopatch
	cmp bx, 480
	jne .dopatch
	// Version-collection forces 800x600, so we don't need to explicitly check that.
	ret
.dopatch:
	
	add ax, 63
	add bx, 7
	shr ax, 6
	shr bx, 3
	
	mov byte [screenblocksx], al
	mov byte [screenblocksy], bl
	
	
	
	/* mov byte [screenblocksx], 16
	mov byte [screenblocksy], 92
	
	xor ebx, ebx
	mov bl, byte [screenblocksx]
	imul bx, 64 
	mov word [dxmaxx], bx
	mov word [redrawscreen.maxx], bx
	dec ebx
	mov word [dxmaxx_1], bx
	
	xor ebx, ebx
	mov bl, byte [screenblocksy]
	imul bx, 8
	mov word [dxmaxy], bx
	mov word [redrawscreen.maxy], bx
	dec ebx
	mov word [dxmaxy_1], bx
	*/

	// Toolbar, Statusbar, Dragbound

	mov ax, word [dxmaxx]
	mov bx, word [dxmaxy]
	mov word [newwinsize.x], ax
	mov word [newwinsize.y], bx
	multipatchcode oldmov_eax_mainwinsizestart,newwinsize,4
	sub word [newwinsize.y], 22
	multipatchcode oldmov_eax_mainwinsizeedit,newwinsize,2
	//sub word [newwinsize.y], 12
	multipatchcode oldmov_eax_mainwinsizegame,newwinsize,2
	
	mov word [newwinsize.y], 22
	multipatchcode oldmov_eax_maintoolbar, newwinsize, 3
	
	
	stringaddress findmov_eaxstatusbarpos,1,1
	
	mov bx, word [dxmaxy]
	sub bx, 12
	mov word [edi+2], bx
	stringaddress finddragmodebound,1,1
	mov word [edi], bx
	mov word [edi+6], bx
	
	// News bar
	inc bx	// (screeny-12) + 1
	mov [dxxother], bx  
	multipatchcode findmov_dxstatusbartexty, newdxxother, 4
	multipatchcode findmov_bxstatusbarscry, newdxxother, 2

	// News fin position
	mov bx, word [dxmaxy]
	stringaddress findmov_esinewsfiny1,1,1

	sub bx, 87
	mov word [edi], bx

	stringaddress findmov_esinewsfiny2,1,1
	sub bx, 83
	mov word [edi], bx

	stringaddress findmov_esinewsfiny3,1,1
	add bx, 40 
	mov word [edi], bx

//	patchcode oldordword_esi_1Ah__280h, newdxmaxx,1,1
	patchcode oldaddbp_1E0h, newdxmaxy,1,1
	multipatchcode oldmovbx_27Fh, newdxmaxx_1,3
	patchcode oldcmpax_1E0h, newdxmaxy,1,1
	multipatchcode oldmovebx_280h, newdxmaxx,3
	multipatchcode oldcmpdword_ebp_0CCh__280h, newdxmaxx,3
	multipatchcode oldpush1E0h, newdxmaxy,6
	multipatchcode oldmoveax_280h, newdxmaxx,3
	multipatchcode oldpush280h, newdxmaxx,6
	multipatchcode oldsubax_1E0h, newdxmaxy,2
//	patchcode oldmovword_4F815Eh__280h, newdxmaxx,1,1
	patchcode oldmovdword_ebp_98h__280h, newdxmaxx,1,1
	patchcode oldsubbp_1E0h, newdxmaxy,1,1
	multipatchcode oldsubax_280h, newdxmaxx,2
//	multipatchcode oldmovword_4F813Ah__280h, newdxmaxx,2
	patchcode oldaddedx_280h, newdxmaxx,1,1
	multipatchcode oldmovdx_1DFh, newdxmaxy_1,8
	patchcode oldmovcx_1E0h, newdxmaxy,1,1
	multipatchcode oldmovdx_280h, newdxmaxx,4
//	patchcode oldmovword_4D07E0h__280h, newdxmaxx,1,1
	patchcode oldmovesi_280h, newdxmaxx,1,1
	multipatchcode oldcmpdword_ebp_8__280h, newdxmaxx,3
	patchcode oldmovdi_280h, newdxmaxx,1,1
//	patchcode oldmovword_4F814Eh__1E0h, newdxmaxy,1,1
	multipatchcode oldmovbp_1E0h, newdxmaxy,3
	patchcode oldmovdword_ebp_4__1E0h, newdxmaxy,1,1
	multipatchcode oldmovbp_280h, newdxmaxx,4
	patchcode oldcmpbp_280h, newdxmaxx,1,1
	patchcode oldcmpdword_ebp_28h__27Fh, newdxmaxx_1,1,1
	multipatchcode oldmovcx_27Fh, newdxmaxx_1,5
	patchcode oldcmpcx_280h, newdxmaxx,1,1
	multipatchcode oldcmpdword_ebp_4__1E0h, newdxmaxy,3
	multipatchcode oldcmpbp_1E0h, newdxmaxy,2
	patchcode oldmovdword_ebp_2Ch__1DFh, newdxmaxy_1,1,1
	patchcode oldmovdword_ebp_8__280h, newdxmaxx,1,1
	patchcode oldcmpdx_1DFh, newdxmaxy_1,1,1
	multipatchcode oldcmpdword_ebp_14h__280h, newdxmaxx,3
	multipatchcode oldcmpdx_280h, newdxmaxx,2
	patchcode oldmovdword_ebp_28h__27Fh, newdxmaxx_1,1,1
	patchcode oldcmpcx_27Fh, newdxmaxx_1,1,1
	patchcode oldsubcx_280h, newdxmaxx,1,1
	patchcode oldsubeax_280h, newdxmaxx,1,1
	patchcode oldimulcx_280h, newdxmaxx,1,1
	multipatchcode oldmovebp_280h, newdxmaxx,2
	patchcode oldmovcx_280h, newdxmaxx,1,1
	multipatchcode oldcmpdword_ebp_10h__1E0h, newdxmaxy,3
	multipatchcode oldcmpdword_ebp_0ACh__280h, newdxmaxx,3
	patchcode oldsubbp_280h, newdxmaxx,1,1
	patchcode oldcmpax_280h, newdxmaxx,1,1
	multipatchcode oldcmpeax_280h, newdxmaxx,2
	patchcode oldcmpdx_1E0h, newdxmaxy,1,1
	patchcode oldmovdword_ebp_94h__1E0h, newdxmaxy,1,1
	multipatchcode oldcmpdword_ebp_0C8h__1E0h, newdxmaxy,3
	patchcode oldmovecx_280h, newdxmaxx,1,1
//	patchcode oldmovword_4F8160h__1E0h, newdxmaxy,1,1
	patchcode oldaddbx_1E0h, newdxmaxy,1,1
	patchcode oldaddbp_280h, newdxmaxx,1,1
	multipatchcode oldcmpcx_1E0h, newdxmaxy,2
	patchcode oldcmpdword_ebp_2Ch__1DFh, newdxmaxy_1,1,1
//	multipatchcode oldmovword_4F813Ch__1E0h, newdxmaxy,2
//	patchcode oldmovword_4D07E2h__1E0h, newdxmaxy,1,1
	patchcode oldmovbx_280h, newdxmaxx,1,1
	multipatchcode oldcmpeax_1E0h, newdxmaxy,2
	patchcode oldmovsi_280h, newdxmaxx,1,1
	multipatchcode oldcmpdword_ebp_0A8h__1E0h, newdxmaxy,3
//	multipatchcode oldmovword_4F814Ch__280h, newdxmaxx,2
	

// old ones, see below
#if 0
	patchcode oldmovword_4F814Eh__1E0h, newdxmaxy,1,1	// sSVGAVideoWindow	
	patchcode oldmovword_4F815Eh__280h, newdxmaxx,1,1	// sSVGAVideoWindow
	multipatchcode oldmovword_4F813Ah__280h, newdxmaxx,2	// sFullScreenUpdateBlock
	multipatchcode oldmovword_4F813Ch__1E0h, newdxmaxy,2	// sFullScreenUpdateBlock
	patchcode oldmovword_4F8160h__1E0h, newdxmaxy,1,1	// sCurrScreenUpdateBlock
	multipatchcode oldmovword_4F814Ch__280h, newdxmaxx,2	// sCurrScreenUpdateBlock
	patchcode oldmovword_4D07E0h__280h, newdxmaxx,1,1	// min_invalidwnd_x
	patchcode oldmovword_4D07E2h__1E0h, newdxmaxy,1,1	// min_invalidwnd_y

	// Change update Screenbuffer
	
	movzx ebx, byte [screenblocksx]
	movzx eax, byte [screenblocksy]
	imul bx, ax
	mov word [screenblocks], bx
	shl ebx, 2
	
	push ebx	// two as buffer, you never know...
	call malloc
	pop ebx
	jc near outofmemoryerror

	stringaddress findmov_eax_offsetblockstoredraw2,1,1
	mov dword [edi], ebx

	stringaddress findadd_ebx_offsetblockstoredraw2,1,1
	mov dword [edi], ebx
	mov al, byte [screenblocksx]
	mov byte [edi-9], al
	mov byte [edi+10], al


	movzx eax, word [screenblocks]
	add ebx, eax
	
	stringaddress findmov_esi_offsetblockstoredraw,1,1
	mov dword [edi], ebx
	mov al, byte [screenblocksx]
	mov byte [edi+46], al
	
	stringaddress findadd_ebx_offsetblockstoredraw,1,1
	mov dword [edi], ebx
	mov al, byte [screenblocksx]
	mov byte [edi-12], al
	mov byte [edi+10], al
#endif

	// Now some magic :)
	// The fragment system doesn't work across different languages with such small fragments,
	// TTDWin uses entrypoints to functions which are always on the same place
	// A error message is shown if we can't get the entry point...
	
	// Entrypoints:
	// 0x4011DB	(only the last once
	//		sSVGAVideoWindow.height 	= + 0x24 + 7
	//		sSVGAVideoWindow.width 		= + 0x5B + 7
	// 		sFullScreenUpdateBlock.width 	= + 0x7C + 7
	//		sFullScreenUpdateBlock.height = + 0x85 + 7
	//		sCurrScreenUpdateBlock.width 	= + 0xAF + 7
	//		sCurrScreenUpdateBlock.height = + 0xB8 + 7
	// 0x401249 blockstoreredraw (mov)		= + 1
	//		min_invalidwnd_x			= + 0xBD + 7
	//		min_invalidwnd_y			= + 0xC6 + 7
	// 0x401E01 blockstoreredraw (add)		= + 0x9F + 2
	// 0x40166D blockstoreredraw2 (mov)		= + 1
	// 0x4018ED blockstoreredraw2 (add)		= + 0x52 + 2

	mov edi, 0x4011DB
	call resgettarget
	mov ax, word [dxmaxx]
	mov bx, word [dxmaxy]
	mov [edi+0x24+7], bx
	mov [edi+0x5B+7], ax
	mov [edi+0x7C+7], ax
	mov [edi+0x85+7], bx
	mov [edi+0xAF+7], ax
	mov [edi+0xB8+7], bx

	// Change update Screenbuffer
	
	movzx ebx, byte [screenblocksx]
	movzx eax, byte [screenblocksy]
	push edx	// Bad experience with it...
	imul bx, ax
	pop edx
	mov word [screenblocks], bx
	shl ebx, 2

	mov edi, 0x4011DB
	call resgettarget

	shl ebx, 2	// 4 buffers, two extra buffers for overflow protection, you never know...
	
	push ebx	
	call malloc
	pop ebx
	jc near outofmemoryerror

	mov edi, 0x40166D // blockstoreredraw2 (mov)		= + 1
	call resgettarget
	mov dword [edi+1], ebx

	mov edi, 0x4018ED // blockstoreredraw2 (add)		= + 0x52 + 2
	call resgettarget
	add edi, 0x54
	mov dword [edi], ebx
	mov al, byte [screenblocksx]
	mov byte [edi-9], al
	mov byte [edi+10], al

	movzx eax, word [screenblocks]
	add ebx, eax
	

	mov edi, 0x401E01 // blockstoreredraw (add)		= + 0x9F + 2
	call resgettarget
	add edi, 0xA1
	mov dword [edi], ebx
	mov al, byte [screenblocksx]
	mov byte [edi-12], al
	mov byte [edi+10], al

	mov edi, 0x401249 // blockstoreredraw (mov)		= + 1 
	call resgettarget
	mov dword [edi+1], ebx
	mov al, byte [screenblocksx]
	mov byte [edi+47], al
	
	mov ax, word [dxmaxx]
	mov bx, word [dxmaxy]
	add edi, 0xC4		//		min_invalidwnd_x			= + 0xBD + 7
	mov word [edi], ax
	mov word [edi+9], bx	//		min_invalidwnd_y			= + 0xC6 + 7

	// Patch Tooltip creation (( Tooltips in the middle of the screen aren't nice ))
	mov bx, word [dxmaxy]
	sub bx, 44
	stringaddress findtooltipchecky, 1, 1
	mov word [edi], bx
	mov word [edi-6], bx
	mov word [edi-16], bx

	// Patch Screenshot
	// Todo: GigantScreenshot
	// Patch Screenshot
	stringaddress findscreenshotsize, 1, 1
	xor eax, eax
	xor ebx, ebx
	mov ax, word [dxmaxx]
	mov bx, word [dxmaxy]
	mov word [edi+16], ax
	push eax
	push ebx
	dec ax
	dec bx	
	mov word [edi], ax
	mov word [edi+2], bx
	pop ebx
	pop eax

	push edx
	imul ebx // ax * bx	// don't screw up edx!
	pop edx
	mov dword [edi+62], eax
	// eax will be used in gigantscreenshot

	
	// Disable Gigantscreenshot so it always failures,
	// sometimes it's good that WinTTD has redirects...
#if 0	
	mov dword [0x401FAA], 0x9090C3F9
	mov byte [0x401FAA+4], 0x90
#else
	mov ebx, eax
	stringaddress findgiantscreenshotwritetotmp, 1, 1
	mov dword [edi], ebx
	stringaddress findgiantscreenshotreadfromtmp, 1, 2
	mov dword [edi], ebx
	mov dword [edi+18], ebx
	stringaddress findgiantscreenshotreadfromtmp, 1, 1
	mov dword [edi], ebx
	mov dword [edi+18], ebx

	xor eax, eax
	xor ebx, ebx
	mov ax, word [dxmaxx]
	mov bx, word [dxmaxy]
	
	push eax
	stringaddress findgiantscreenshotmovepointer
	pop eax
	
	push eax
	shl eax, 1
	mov word [edi], ax
	pop eax
	
	// height * 3
	push edx
	imul bx, bx, 3
	pop edx

	// ax = width
	// bx = height * 3
	push eax
	stringaddress findgiantscreenshotsizeqx, 1, 1
	mov eax, dword [esp]
	
	push edx
	imul eax, ebx
	pop edx
	mov dword [edi], eax
	
	stringaddress findgiantscreenshotsize, 1, 1
	pop eax

	// width * 3
	push edx
	imul ax, ax, 3
	pop edx
	
	push eax	// width * 3
	mov dword [edi+5], eax 

	push edx	// width * 3 * height *3 
	imul eax, ebx
	pop edx
	mov dword [edi], eax 

	stringaddress findgiantscreenshotpcxheader, 1, 1
	pop eax
	// ax = width * 3
	// bx = height * 3	
	mov word [edi+16], ax
	dec ax
	dec bx
	mov word [edi], ax
	mov word [edi+2], bx
#endif

	//Fullscreen Patches
	mov al, [0x40EDED+6]
	cmp al, 0x0A
	jnz resfullerror
	mov bl, byte [screenblocksx]
	mov byte [0x406EE3+6], bl
	mov byte [0x406F56+6], bl
	mov byte [0x4071A6+6], bl
	mov byte [0x40721D+6], bl

	mov byte [0x40EDED+6], bl
	mov byte [0x40EE4E+6], bl
	mov byte [0x40F37C+6], bl
	mov byte [0x40F465+6], bl
	
	movzx ebx, word [screenblocks]
	mov dword [0x40607F+3], ebx
	mov dword [0x406CA3+6], ebx
	mov dword [0x406CDD+6], ebx
	mov dword [0x406F8E+6], ebx
	mov dword [0x40EB3A+3], ebx
	
	mov edi,0x404954
	storefragment newaddscreenmode

	mov edi,0x40F3AA
	storefragment newcalcupdateblockrect
	ret

resfullerror:
	//Normally should never happen,
	//but it's better to crash now before we get into a fullscreen hang somehow...
#if 0
	INT3
	ret
#else
	push 0x10 // MB_ICONSTOP
	push TTDPatch_prognameW
	push reserrorstring
	push 0
	call callMessageBoxW
	jmp abortttd
#endif 

resgettarget:
	cmp byte [edi], 0xE9
	jnz resfullerror
	push eax
	mov eax,[edi+1]
	lea edi,[edi+eax+5]
	pop eax
	ret

#endif
