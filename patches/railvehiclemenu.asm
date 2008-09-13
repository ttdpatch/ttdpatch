#include <std.inc>
#include <misc.inc>
#include <textdef.inc>
#include <human.inc>
#include <veh.inc>
#include <window.inc>
#include <windowext.inc>
#include <imports/gui.inc>
#include <ptrvar.inc>

extern actionhandler
extern actionrailvehmenu_actionnum

extern isengine

extern RefreshWindows

// called when a rail vehicle drag and drop fails
//
// in:
//	esi=window
//	edi=the vehicle
//	ebx=the train of the vehicle consist
// out:	cf set if the trainwindow should be opened
exported TrainDepotDragDropFailed
	push byte CTRL_ANY + CTRL_MP
	extcall ctrlkeystate
	jz near OpenRailVehicleMenu
		
	or ebx, ebx
	jz .done	// no front engine found
	cmp byte [ebx+veh.subclass], 0
	je .opentrainwindow
.done:	
	clc
	ret
.opentrainwindow:
	stc
	ret
	
guiwindow win_railvehmenu,65,20
	guiele caption_close,cWinElemTextBox,cColorSchemeGrey,x,0,w,11,y,0,h,14,data,0x00C5
	guiele captionbar,cWinElemSpriteBox,cColorSchemeGrey,x,0,w,11,y,14,-y2,0,data,0
	
	guiele reverse,cWinElemSpriteBox,cColorSchemeGrey,x,11,w,18,y,0,h,20,data,715
	guiele refit,cWinElemSpriteBox,cColorSchemeGrey,x,29,w,18,y,0,h,20,data,692
	guiele changelook,cWinElemSpriteBox,cColorSchemeGrey,x,47,w,18,y,0,h,20,data,683
endguiwindow

struc win_railvehmenudata
	.vehidx resw 1
	.window resd 1
endstruc


// in:
//	esi=calling window
//	edi=the vehicle
//	ebx=the train of the vehicle consist
// out:	no carry flag as it is called directly by above code!
OpenRailVehicleMenu:
	pusha
	push edi
	 
	mov cl, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowRailVehMenu
	call [FindWindow]
	test esi,esi
	jz .noold
	call [DestroyWindow]
.noold:
	movzx eax, word [mousecursorscry]
	shl eax, 16
	mov ax, word [mousecursorscrx]
	
	//mov eax, 286 + (22<<16) // x + (y << 16)
	mov ebx, win_railvehmenu_width + (win_railvehmenu_height << 16)
	mov cx, cWinTypeTTDPatchWindow  	// window type
	mov dx, -1	// operation class offset
	mov ebp, RailVehicleMenu_WinHandler
	call dword [CreateWindow]
	mov word [esi+window.id], cPatchWindowRailVehMenu
	mov dword [esi+window.elemlistptr], win_railvehmenu_elements
	pop edi
	
	movzx eax, word [edi+veh.idx]
	mov word [esi+window.data+win_railvehmenudata.vehidx], ax
	
	popa
	clc
	ret

	

RailVehicleMenu_WinHandler:
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	jnz .noredraw
	jmp [DrawWindowElements]
.noredraw:
	cmp dl, cWinEventClick
	jz RailVehicleMenu_ClickHandler
	cmp dl, cWinEventTimer
	je RailVehicleMenu_Timer
	
	ret
	
RailVehicleMenu_Timer:
	mov dword [esi+window.activebuttons], 0
	jmp [DestroyWindow]
	ret

RailVehicleMenu_ClickHandler:
	call dword [WindowClicked]
	jns .click
	ret
.click:
	cmp cl, win_railvehmenu_elements.caption_close_id
	jne .notdestroy
	jmp [DestroyWindow]
.notdestroy:
	cmp cl, win_railvehmenu_elements.captionbar_id
	jne .nottilebar
	jmp dword [WindowTitleBarClicked]
.nottilebar:

	cmp cl, win_railvehmenu_elements.reverse_id
	je .reverse
	cmp cl, win_railvehmenu_elements.refit_id
	je .refit
	cmp cl, win_railvehmenu_elements.changelook_id
	je .changelook
	ret
	
.refit:
	call .pressit
	movzx edx, word [esi+window.data+win_railvehmenudata.vehidx]
	extjmp openrefitwindowalt

.changelook:
	call .pressit
	pusha
	mov bl, 1		// DoIt
	mov bh, 1		// action sub feature
	jmp short .callaction
.reverse:
	pusha
	mov bl, 1		// DoIt
	mov bh, 0		// action sub feature
.callaction:
	movzx edi, word [esi+window.data+win_railvehmenudata.vehidx]
	
	xor eax, eax
	xor ecx, ecx
	mov word [operrormsg1], 0x8869
	dopatchaction actionrailvehmenu
	popa
.noreverse:
	ret

.pressit:
	movzx ecx, cl
	bts dword [esi+window.activebuttons], ecx
	or byte [esi+window.flags], 7
	mov al, [esi]
	mov bx, [esi+window.id]
	jmp [invalidatehandle]
	


// in:	ax,cx=x,y coordinates of action or zero
//		bl=construction code
//		bh=type of operation  0=reverse 1=changelook
//		edi=vehicle index
//		edx 

// out: ebx=cost or 0x80000000 if action failed
exported actionrailvehmenu
	mov word [operrormsg2], 0x0006
	shl edi, vehicleshift
	add edi, [veharrayptr]
	
	cmp bh, 0
	je .reversetrain
	
	// movzx ebx, byte [edi+veh.artictype]
	mov ebx, 0x80000000
	ret
	
	
.reversetrain:
	push eax
	push ecx
	
	movzx esi,word [edi+veh.vehtype]
	bt [isengine],esi
	jc .isengine
//  wagon
//	pop ecx
//	pop eax
//	ret
.isengine:
	// esi = vehidx
	// edi = vehicle
	
	cmp byte [edi+veh.artictype],0xfe	// if we clicking on a artic second piece
	jae .fail

	movzx ecx,word [edi+veh.nextunitidx]
	cmp cx,byte -1
	je .nonext
	
	shl ecx, 7
	add ecx, [veharrayptr]
	cmp byte [ecx+veh.artictype],0xfe
	jae .articreverse
.nonext:


	mov al,[edi+veh.spritetype]
	mov ah,[trainsprite+esi]
	
	cmp al, 0xFD
	jae .ttdpatchtyp
	
	mov cl, 1
	add cl, byte [numheads+esi]	// if numheads = 1 we have to add 2
	jmp short .toggle
	
.ttdpatchtyp:
	cmp ah, 0xFE		// a TTDPatch one should never be 0xFE
	jne .ttdpatchtypok
	CALLINT3		// Should never happen, so crash now for easy debug
.ttdpatchtypok:
	mov cl, 2
	
.toggle:
	cmp ah, al		// not equal = reversed, reset back to default
	jne .setdirection
	add ah, cl
	
.setdirection:
	test bl,1
	jz .dontchangediryet
	mov [edi+veh.spritetype], ah
.dontchangediryet:
// Refresh window
	pusha
	mov al, cWinTypeDepot
	mov bx, [edi+veh.XY]
	call [RefreshWindows]
	popa
	
	pop eax
	pop ecx
	xor ebx, ebx
	ret
	
.fail:
	pop eax
	pop ecx
	mov ebx, 0x80000000
	ret
	
	
.articreverse:
	jmp .fail
#if 0
	// edi a engine with a 0xFF
	pusha
	
	test bl,1
	jz .dontdoit
	
	movzx eax, word [edi+veh.idx]
	// in: eax = veh.idx
	// out: eax= veh.idx of prev
	//	esi= vehicle of prev
	call findprevvehicle
	mov dword [reverseartictempstart], esi
	
	
	xor ecx, ecx
	mov esi, edi
	
	
.nextMapEntry:
	movzx eax, word [esi+veh.idx]
	mov bh, byte [esi+veh.artictype]
	cmp bh, 0x00	
	je .afront
	cmp bh, 0xFF
	je .asec

	jmp .endMapEntry
	
.afront:
	cmp ecx, 0
	jne .endMapEntry
	mov byte [esi+veh.artictype], 0xFF
	jmp .adone
.asec:
	mov byte [esi+veh.artictype], 0xFE
	
.adone:
	mov [reverseartictemp+ecx*2], ax
	inc ecx
	
	
	movzx eax, [esi+veh.nextunitidx]
	cmp ax, -1
	je .endMapEntry
	shl eax,7
	add eax,[veharrayptr]
	mov esi, eax
	jmp .nextMapEntry
	
.endMapEntry:

	// eax = next non artic consist engine idx
	mov word [reverseartictempstop], ax
	
// 721
//X234 <-
//X112
//X443
//X10
// 401

	mov esi, dword [reverseartictempstart]
.nextAZ:
	movzx eax, word [reverseartictemp+ecx*2]
	cmp esi, -1
	je .novaildstartAZ
	mov [esi+veh.nextunitidx], ax
.novaildstartAZ:
	dec ecx
	cmp ecx, 0
	je .doneAZ
	
	shl eax, 7
	add eax,[veharrayptr]
	mov esi,eax
	jmp .nextAZ
.doneAZ:
	movzx eax, word [reverseartictempstop]
	mov [esi+veh.nextunitidx], ax
	
	
	
.dontdoit:
	popa
.fail:
	pop eax
	pop ecx
	mov ebx, 0x80000000
	ret
uvard reverseartictempstart,1
uvarw reverseartictempend,1
uvarw reverseartictemp,30



// in:	
//	eax=vehicle index
// out:
//	esi=vehicle
findprevvehicle:
	mov esi,[veharrayptr]
	
.nextvehicle:
	cmp byte [esi],0
	jz .empty
	
	cmp word [esi+veh.nextunitidx], ax
	je .found
	
.empty:
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	cmp esi,[veharrayendptr]
	jb .nextvehicle
	// none found :(
	mov eax, -1
	stc
	ret
.found:
	movzx eax, word [esi+veh.idx]
	clc
	ret

#endif
