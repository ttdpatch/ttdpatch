
;movzx ebx,word [esi+window.id]  // get the current vehicle from the window data
;shl ebx,vehicleshift
;add ebx,[veharrayptr]

#include <std.inc>
#include <veh.inc>
//#include <ttdvar.inc>
#include <textdef.inc>
#include <window.inc>
#include <misc.inc>
#include <station.inc>
#include <town.inc>
#include <imports/gui.inc>

extern CreateWindow,DrawWindowElements,WindowClicked,DestroyWindow,WindowTitleBarClicked,GenerateDropDownMenu,BringWindowToForeground,invalidatehandle,setmousetool,getnumber,errorpopup
global robjgameoptionflag,robjflags

global tr_siggui_btnclick

uvarb robjgameoptionflag,1
// 1=enabled&load

/*
//Save
uvard robjflags,4
//DWORD 0:	1=enabled&save
uvarw robjidtbl,256*16

uvarb robjs, 0x4000*8
//Length: 16+(256*16*2)+(0x4000*8) = 0x22010
//End Save
*/

uvard robjdataarrays,0x22010/4

robjflags equ robjdataarrays
robjidtbl equ robjdataarrays+16
robjs equ robjidtbl+(256*16*2)

%assign robjnum 0x4000

uvard curvehicleptr, 1
uvard curstepfuncptr, 1

struc robj
	.type resb 1
	.varid resb 1
	.flags resb 1
	.count resb 1
	.word1 resw 1
	.word2 resw 1
endstruc
//flags:
//1=value valid
//80=currently allocated

global trpatch_DoTraceRouteWrapper1,trpatch_DoTraceRouteWrapper1.oldfn,trpatch_DoTraceRouteWrapper2,trpatch_DoTraceRouteWrapper3
trpatch_DoTraceRouteWrapper3:
	mov ecx, [esp+4]
	jmp trpatch_DoTraceRouteWrapper1.common
trpatch_DoTraceRouteWrapper2:
	mov ecx, [esp+6]
	jmp trpatch_DoTraceRouteWrapper1.common
trpatch_DoTraceRouteWrapper1:
	mov ecx, [esp+14]
.common:

	test BYTE [robjflags], 1
	jz .nomodify
	cmp ecx, [veharrayendptr]
	jae .badvehptr
	mov [curvehicleptr], ecx
	sub ecx, [veharrayptr]
	jb .badvehptr
	and ecx, veh_size-1
	jnz .badvehptr

	mov [curstepfuncptr],edx
	mov edx,trpatch_stubstepfunc
.nomodify:
	call $
	ovar .oldfn, -4, $,trpatch_DoTraceRouteWrapper1
	mov DWORD [curvehicleptr],0
ret
.badvehptr:
	//Should never be reached
	//int3
	mov DWORD [curvehicleptr],0
jmp .nomodify

trpatch_stubstepfunc:
	//test BYTE [robjflags], 1
	//jz .norm
	mov al,[landscape5(di)]
	xor al,0x40
	and al,0xC0
	jnz .norm
	test BYTE [landscape3+1+edi*2],16
	jnz .check

.norm:
	jmp DWORD [curstepfuncptr]

.check:
	pusha
	
	mov eax,[curvehicleptr]
	or eax,eax
	jz .tret
	mov bx,di
	call tracerestrict_doesitpass
	or eax,eax
	jz .fret
	.tret:
	popa
	jmp DWORD [curstepfuncptr]

.fret:
	popa
	stc
	ret

//eax=vehicle ptr,bx=xy coords of restrict tile
//trashes: (eax),ebx,ecx,edx
//returns true/false in eax


varb tempdlvar,1
tracerestrict_doesitpass:
	movzx ebx,bx
	mov dl,[landscape7+ebx]
	shr bh,6
	shl bx,2
	mov bl,dl
	mov bx,[robjidtbl+ebx*2]
	
	call .recurse
	mov eax,edx
ret

.recurse:
	movzx ebx,bx
	or ebx,ebx
	jz NEAR .tret
	
	shl ebx, 3
	add ebx, robjs
	mov edx, [ebx]
	or dl,dl
	jz NEAR .tret
	
	cmp dl,7
	jl .cmp
	
	cmp dl,32
	jl NEAR .fret
	je near .and
	
	cmp dl,33
	je near .or
	cmp dl,34
	je near .xor
	jmp .fret


.cmp:
	or dh,dh
	jz NEAR .tret
	test edx, 0x10000
	jz .tret
	
	mov [tempdlvar],dl
	
	cmp dh,1
	je near .trainlen
	cmp dh,2
	je near .maxspeed
	cmp dh,3
	je near .curorder
	cmp dh,4
	je near .curdeporder
	cmp dh,4
	je near .totalpower
	cmp dh,4
	je near .totalweight
	cmp dh,8
	jle near .sigval

.gotvar:
	cmp BYTE [tempdlvar],1
	je .lt
	cmp BYTE [tempdlvar],2
	je .gt
	cmp BYTE [tempdlvar],3
	je .lte
	cmp BYTE [tempdlvar],4
	je .gte
	cmp BYTE [tempdlvar],5
	je .eq
	cmp BYTE [tempdlvar],6
	je .neq

.fret:
	xor edx,edx
ret

.tret:
	mov edx, 1
ret

.lt:
	cmp ecx,edx
	setl dl
	and edx, byte 1
ret
.gt:
	cmp ecx,edx
	setg dl
	and edx, byte 1
ret
.lte:
	cmp ecx,edx
	setle dl
	and edx, byte 1
ret
.gte:
	cmp ecx,edx
	setge dl
	and edx, byte 1
ret
.eq:
	cmp ecx,edx
	sete dl
	and edx, byte 1
ret
.neq:
	cmp ecx,edx
	setne dl
	and edx, byte 1
ret

.trainlen:
	push ebx
	mov ebx,eax
	mov ecx,1
	.tl_loop1:
		movzx ebx, WORD [ebx+veh.nextunitidx]
		cmp bx, -1
		jz .tl_end1
		inc ecx
		shl ebx,vehicleshift
		add ebx, [veharrayptr]
	jmp .tl_loop1
.tl_end1:
	pop ebx
	movzx edx, WORD [ebx+robj.word1]
	jmp .gotvar

.maxspeed:
	movzx ecx, WORD [eax+veh.maxspeed]
	movzx edx, WORD [ebx+robj.word1]
	jmp .gotvar

.curorder:
	mov cx, [eax+veh.currorder]
	and ecx,0xff0f
	cmp cl,1
	je .curordernbl
	mov ecx, -1
.curordernbl:
	shr ecx,8
	movzx edx, BYTE [ebx+robj.word1]
	jmp .gotvar

.curdeporder:
	mov cx, [eax+veh.currorder]
	and ecx,0xff0f
	cmp cl,2
	je .curdepordernbl
	xor ecx,ecx
.curdepordernbl:
	shr ecx,8
	movzx edx, WORD [ebx+robj.word1]
	jmp .gotvar

.totalpower:
	mov ecx, [eax+veh.veh2ptr]
	mov ecx, [ecx+veh2.realpower]
	mov edx, [ebx+robj.word1]
	jmp .gotvar

.totalweight:
	mov ecx, [eax+veh.veh2ptr]
	movzx ecx, WORD [ecx+veh2.fullweight]
	movzx edx, WORD [ebx+robj.word1]
	jmp .gotvar

.sigval:
	push eax
	dec dh	//5-8 --> 4-7, signal bits in L2,L3
	mov cl, dh
	movzx eax, WORD [ebx+robj.word1]
	mov dh, [landscape4(ax,1)]
	shr dh,4
	cmp dl, 1
	jne .sigval_redret
	mov dh, [landscape5(ax,1)]
	mov ch, dh
	and ch, 0xC0
	xor ch, 0x40
	jnz .sigval_redret
	test dh, 3
	jnz .noewtrack
	or cl, 2
	.noewtrack:
	test dh, 0x30
	jnz .nonstrack
	//4-->6
	//5-->4
	//6-->7
	//7-->5
	mov ch,1
	cmp dh, 5
	je .noadd
	cmp dh, 6
	je .noadd
	add ch,ch
	.noadd:
	xor cl, ch
	.nonstrack:
	
	mov dl, 1
	shl dl, cl
	test BYTE [landscape3+eax*2], dl
	jz .sigval_redret
	test BYTE [landscape2+eax], dl
	jz .sigval_redret

.sigval_greenret:
	pop eax
	xor ecx, ecx
	xor edx, edx
	jmp .gotvar
.sigval_redret:
	pop eax
	mov ecx, 1
	xor edx, edx
	jmp .gotvar

.and:
	call .recurseproc2
	and dl,dh
	and edx, byte 1
ret

.or:
	call .recurseproc2
	or dl,dh
	and edx, byte 1
ret

.xor:
	call .recurseproc2
	xor dl,dh
	and edx, byte 1
ret

//proc: returns dl and dh, result
.recurseproc2:
	push ebx
	movzx ebx, WORD [ebx+robj.word1]
	call .recurse
	mov ebx,[esp]
	movzx ebx, WORD [ebx+robj.word2]
	push edx
	call .recurse
	pop ecx
	shl ecx,8
	or edx,ecx
	pop ebx
ret


global clearrobjarrays
clearrobjarrays:

	push edi
	push ecx
	push eax
	mov ecx, 0x22010/4
	xor eax, eax
	mov edi,robjflags
	cld
	rep stosd
	pop eax
	pop ecx
	pop edi

ret

%assign winwidth 505
%assign numrows 20
%assign winheight numrows*12+36

//<,>,<=,>=,==,!=,&&,||,^^

varb tracerestrictwindowelements
	// Close button 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5

	// Title Bar 1
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, winwidth-1, 0, 13, ourtext(tr_restricttitle)
	
	// Background of the Window 2
	db cWinElemSpriteBox, cColorSchemeGrey
	dw 0, winwidth-1, 14, winheight-1, 0

	// unused 3
	db cWinElemDummyBox, 0
	dw 0, 0, 0, 0, 0
	
	// Text Box of the Var Dropdown List 4
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 190, winheight-13, winheight-1
	.vartb: dw statictext(empty)

	// Drop Down List button for Var 5
	db cWinElemTextBox, cColorSchemeGrey
	dw 191, 203, winheight-13, winheight-1, statictext(txtetoolbox_dropdown)

	// Text Box of the Op Dropdown List 6
	db cWinElemTextBox, cColorSchemeGrey
	dw 210, 246, winheight-13, winheight-1
	.optb: dw statictext(empty)

	// Drop Down List button for Op 7
	db cWinElemTextBox, cColorSchemeGrey
	dw 247, 259, winheight-13, winheight-1, statictext(txtetoolbox_dropdown)

	// Value button 8
	db cWinElemTextBox, cColorSchemeGrey
	dw 266, 296, winheight-13, winheight-1, statictext(tr_valuebtn)

	// And button 9
	db cWinElemTextBox, cColorSchemeGrey
	dw 306, 336, winheight-13, winheight-1, statictext(tr_andbtn)

	// Or button 10
	db cWinElemTextBox, cColorSchemeGrey
	dw 343, 373, winheight-13, winheight-1, statictext(tr_orbtn)
	
	// Xor button 11
	db cWinElemTextBox, cColorSchemeGrey
	dw 380, 410, winheight-13, winheight-1, statictext(tr_xorbtn)

	// Delete button 12
	db cWinElemTextBox, cColorSchemeGrey
	dw 417, 457, winheight-13, winheight-1
	.delbtn: dw 0x8824
	
	// Reset button 13
	db cWinElemTextBox, cColorSchemeGrey
	dw 464, 504, winheight-13, winheight-1
	.rstbtn: dw ourtext(resetorders)

	// Text Box 14
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, winwidth-12, 14, winheight-14
	.maintb: dw statictext(empty)
	
	// Slider 15
	db cWinElemSlider, cColorSchemeGrey
	dw winwidth-11, winwidth-1, 14, winheight-14,0

	db 0xb

endvar

varw pre_op_array
dw statictext(empty)
endvar
varw op_array
dw statictext(trdlg_lt_b)
dw statictext(trdlg_gt_b)
dw statictext(trdlg_lte_b)
dw statictext(trdlg_gte_b)
dw statictext(trdlg_eq_b)
dw statictext(trdlg_neq_b)
dw 0xffff
endvar

varw pre_op_array_nc
dw statictext(empty)
endvar
varw op_array_nc
dw statictext(trdlg_lt)
dw statictext(trdlg_gt)
dw statictext(trdlg_lte)
dw statictext(trdlg_gte)
dw statictext(trdlg_eq)
dw statictext(trdlg_neq)
dw 0xffff
endvar

varw op_array2
dw statictext(trdlg_eq)
dw statictext(trdlg_neq)
dw 0xffff
endvar

varw op_array3
dw ourtext(tr_sigval_is_g)
dw ourtext(tr_sigval_is_r)
dw 0xffff
endvar

%assign var_array_num 11
varw pre_var_array
dw statictext(empty)
endvar
varw var_array
dw statictext(tr_trainlen)
dw statictext(tr_maxspeed)
dw statictext(tr_curorder)
dw statictext(tr_curdeporder)
dw statictext(tr_totalpower)
dw statictext(tr_totalweight)
dw statictext(tr_sigval_sw2)
dw statictext(tr_sigval_se2)
dw statictext(tr_sigval_nw2)
dw statictext(tr_sigval_ne2)
dw 0xffff
endvar

varw pre_var_array_nc
dw statictext(empty)
endvar
varw var_array_nc
dw ourtext(tr_trainlen)
dw ourtext(tr_maxspeed)
dw ourtext(tr_curorder)
dw ourtext(tr_curdeporder)
dw ourtext(tr_totalpower)
dw ourtext(tr_totalweight)
dw statictext(tr_sigval_sw)
dw statictext(tr_sigval_se)
dw statictext(tr_sigval_nw)
dw statictext(tr_sigval_ne)
dw 0xffff
endvar

//1: 2op, 2: station, 4: depot, 8: uword, 16: udword, 32: sig
varb var_flags
db 8
db 8
db 3
db 5
db 16
db 16
db 33
db 33
db 33
db 33
endvar

varw waAnimGoToCursorSprites
dw 2CCh, 1Dh, 2CDh, 1Dh, 2CEh, 62h, 0FFFFh
endvar

struc signalguidata
	.xy resw 1	// 00: xy of tile to change
	.x:	resw 1	// 02: x of tile to change
	.y:	resw 1	// 04: y of tile to change
	.life:	resb 1	// 06: seconds left before closing
	.piece:	resb 1	// 07: track piece bit to change
	.type:	resb 1	// 08: signal type (pre/pbs/semaphore) to change
endstruc

uvarb curmode, 1
//0=normal, 1=copy/share shown

uvarb curvarddboxmode, 1
//0=var, 1=bop

uvarw curxypos, 1

uvarw robjidindex,1
uvarw robjid,1
uvard rootobj,1
uvarw curselrobjid,1
uvard curselrobj,1

uvard screenclickxy, 1

global tracerestrict_createwindow
tracerestrict_createwindow:
	pushad
	mov cx, 0x2A
	mov dx,111
	call dword [BringWindowToForeground]
	jnz NEAR .alreadywindowopen
	
	mov esi, [esp+4]

	movzx ecx, WORD [esi+window.data+signalguidata.xy]
	mov [curxypos], cx

	test BYTE [landscape3+1+ecx*2], 0x10
	jz .noinit

	mov edx, ecx

	shr dh,6
	shl dx,2
	mov dl, [landscape7+ecx]
	mov [robjidindex], dx
	movzx edx, WORD [robjidtbl+edx*2]
	mov [robjid], dx
	add edx,edx
	lea edx, [robjs+edx*4]
	mov [rootobj], edx
	
	xor edx, edx
	jmp .initovernocur
.noinit:
	xor edx,edx
	mov [robjidindex], dx
	mov [robjid], dx
	mov [rootobj], edx
.initovernocur:
	mov [curselrobjid], dx
	mov [curselrobj], edx
	
.initover:

	mov cx, 0x2A
	mov dx, -1
	mov eax, (640-winwidth)/2 + (((480-winheight)/2) << 16) // x, y
	mov ebx, winwidth + (winheight << 16) // width , height
	mov ebp, trwin_msghndlr
	call dword [CreateWindow]

	call countrows

	mov dword [esi+window.elemlistptr], tracerestrictwindowelements
	mov DWORD [esi+window.disabledbuttons], 0x1F80
	cmp DWORD [rootobj],0
	je .nodisvar
	or BYTE [esi+window.disabledbuttons], 0x20
	.nodisvar:
	mov word [esi+window.id], 111
	mov byte [esi+window.itemstotal], 0
	mov byte [esi+window.itemsvisible], numrows
	mov byte [esi+window.itemsoffset],0

	mov WORD [tracerestrictwindowelements.vartb],statictext(empty)
	mov WORD [tracerestrictwindowelements.optb],statictext(empty)
	
	mov edx, [curselrobj]
	call updatebuttons

.alreadywindowopen:
	popad
ret

trwin_msghndlr:
	mov bx, cx
 	mov esi, edi

	cmp dl, cWinEventRedraw
	jz .trwin_redraw

	cmp dl, cWinEventClick
	jz .trwin_clickhandler

	cmp dl, cWinEventDropDownItemSelect
	jz near .trwin_dropdown

	cmp dl, cWinEventMouseToolClick
	jz NEAR .mtoolclickhndlr
	
	cmp dl, cWinEventMouseToolClose
	jz NEAR .mtoolclosehndlr
	
	cmp dl, cWinEventTextUpdate
	jz NEAR textwindowchangehandler

ret

.trwin_redraw:
	call dword [DrawWindowElements]
	jmp DisplayTrDlgText

.trwin_clickhandler:

	mov [screenclickxy], ax
	mov [screenclickxy+2], bx

	call dword [WindowClicked] // Has this window been clicked
	js NEAR .ret

	cmp byte [rmbclicked],0 // Was it the right mouse button
	jne .ret
	
	movzx ecx,cl
	bt DWORD [esi+window.disabledbuttons], ecx
	jc .ret

	or cl,cl // Was the Close Window Button Pressed
	jnz .notdestroywindow // Close the Window
	jmp dword [DestroyWindow]
.notdestroywindow:

	cmp cl, 1 // Was the Title Bar clicked
	jne .notwindowtitlebarclicked
	jmp dword [WindowTitleBarClicked] // Allow moving of Window
.notwindowtitlebarclicked:

	cmp cl, 2
	je .ret

	cmp cl, 4
	je .ret
	
	cmp cl, 5
	je NEAR .ddl1
	
	cmp cl, 6
	je .ret
	
	cmp cl, 7
	je NEAR .ddl2
	
	cmp cl, 8
	je NEAR .valuebtn
	
	cmp cl, 9
	je NEAR .andbtn
	
	cmp cl, 10
	je NEAR .orbtn
	
	cmp cl, 11
	je NEAR .xorbtn

	cmp cl, 12
	je NEAR .delbtn
	
	cmp cl, 13
	je NEAR .resetbtn
	
	cmp cl, 14
	je .tbox

.ret:
ret

.tbox:
	mov cx, [screenclickxy]	//x
	mov ax, [screenclickxy+2] //y
	sub cx, [esi+window.x]
	js NEAR .tboxret
	sub ax, [esi+window.y]
	sub ax, 14
	js NEAR .tboxret
	
	mov bp, 12
	xor dx, dx
	div bp
	
	movzx cx, BYTE [esi+window.itemsoffset]
	add ax, cx
	
	mov edx, [rootobj]
	or edx, edx
	jz .tboxret
	
	push DWORD .tbox_1
	inc ax
.tboxrobjrecurse:
	dec ax
	jz .tboxrecurseret
	js .tboxrecurseretincax
	cmp BYTE [edx+robj.type], 32
	jb .tboxrecurseret
	push edx
	movzx edx, WORD [edx+robj.word1]
	shl edx, 3
	add edx, robjs
	call .tboxrobjrecurse
	or ax, ax
	jz .tboxrecurseretnow
	mov edx, [esp]
	movzx edx, WORD [edx+robj.word2]
	shl edx, 3
	add edx, robjs
	call .tboxrobjrecurse
	or ax, ax
	jz .tboxrecurseretnow
	pop edx

.tboxrecurseret:
	ret
.tboxrecurseretnow:
	add esp, 4
ret
.tboxrecurseretincax:
	inc ax
	ret
.tbox_1:
	or ax, ax
	jz .nozerocur
	xor edx, edx
.nozerocur:
	mov [curselrobj], edx
	call updatebuttons
.tboxret:
ret

.ddl1:
	mov eax, [curselrobj]
	or eax, eax
	jz .ddl1_norm
	movzx edx, BYTE [eax+robj.type]
	sub edx, 32
	jb .ddl1_norm
	mov DWORD [tempvar], statictext(tr_andbtn) | statictext(tr_orbtn)<<16
	mov DWORD [tempvar+4], statictext(tr_xorbtn) | 0xffff0000
	mov BYTE [curvarddboxmode], 1

	jmp .ddl1_nodecdx

	.ddl1_norm:
	push ecx
	mov BYTE [curvarddboxmode], 0
	mov eax, var_array-4
	mov ecx, (var_array_num+1)>>1
	.ddl1_loop:
		mov ebx,[eax+ecx*4]
		mov [tempvar-4+ecx*4],ebx
	loop .ddl1_loop
	pop ecx
	mov eax, [curselrobj]
	or eax, eax
	jnz .ddl1_n
	cmp DWORD [rootobj], 0
	jne .ret
	jmp .ddl1_nodecdx
.ddl1_n:
	movzx dx, byte [eax+robj.varid]
	or dx,dx
	jz .ddl1_nodecdx
	dec dx
.ddl1_nodecdx:
 	xor ebx, ebx
	jmp dword [GenerateDropDownMenu]

.ddl2:
	mov eax, [curselrobj]
	or eax, eax
	jz .ret
	movzx dx, byte [eax+robj.type]
	or dx,dx
	jz .ddl2_nodecdx
	dec dx
.ddl2_nodecdx:
	//mov eax, [curoparray]
	movzx ebx, BYTE [eax+robj.varid]
	mov bl, [var_flags-1+ebx]
	mov eax, op_array
	test bl, 1
	jz .ddl_noop2array
	mov eax, op_array2
	test bl, 32
	jz .ddl_noop2array
	mov eax, op_array3
.ddl_noop2array:
	mov ebx, [eax]
 	mov dword [tempvar], ebx
 	mov ebx, [eax+4]
 	mov dword [tempvar+4], ebx
 	mov ebx, [eax+8]
	mov dword [tempvar+8], ebx
	mov word [tempvar+12], 0xFFFF
 	xor ebx, ebx
	jmp dword [GenerateDropDownMenu]

.ddl1_action:
	mov ebx, [curselrobj]
	or ebx, ebx
	jz .ddl1_action_norm
	cmp BYTE [ebx+robj.type], 32
	jb .ddl1_action_norm
	cmp BYTE [curvarddboxmode], 1
	jne .ddl1_action_bop_ret
	add al, 32
	mov [ebx+robj.type], al
.ddl1_action_bop_ret:
	mov edx, ebx
	jmp updatebuttons

.ddl1_action_norm:
	cmp BYTE [curvarddboxmode], 0
	jne .ddl1_action_bop_ret

	movzx eax,al

	/* movzx ecx, BYTE [var_flags+eax]
	and ecx, BYTE 1
	dec ecx
	and ecx, op_array-op_array2
	add ecx, op_array2
	mov [curoparray], ecx */


	or ebx, ebx
	jnz NEAR .ddl1_action_noinit

	push eax
	movzx eax, WORD [curxypos]
	or BYTE [landscape3+1+eax*2], 0x10
	mov ecx, robjnum-1
	mov ebx, robjs+robj_size
	.sbl1:
		test BYTE [ebx+2], 0x80
		jz .sbl1f
		add ebx, robj_size
	loop .sbl1
	call error
	pop eax
	ret

	.sbl1f:
	neg ecx
	lea edx, [ecx+robjnum]
	mov DWORD [ebx], 0x01800000
	mov DWORD [ebx+4], 0
	shr ah,6
	shl ax,2
	xor al,al
	mov ecx,0x100
	lea eax, [robjidtbl+eax*2]
	.sbl2:
		cmp WORD [eax], 0
		je .sbl2f
		add eax,2
	loop .sbl2
	call error
	pop eax
	ret
.sbl2f:
	mov [eax], dx
	mov [robjid], dx
	mov [curselrobjid], dx
	sub eax, robjidtbl
	shr eax, 1
	mov [robjidindex], ax
	mov [rootobj], ebx
	mov [curselrobj], ebx
	movzx edx, WORD [curxypos]
	mov [landscape7+edx], al
	or BYTE [robjflags], 1
	pop eax
	call countrows
.ddl1_action_noinit:
	and BYTE [ebx+robj.flags],~1
	inc eax
	mov [ebx+robj.varid],al
	mov BYTE [ebx+robj.type],0
	mov edx, ebx
	jmp updatebuttons

.ddl2_action:
	movzx eax,al
	
	mov ebx, [curselrobj]
	or ebx, ebx
	jnz .ddl2_action_nret
ret
.ddl2_action_nret:
	movzx ecx, BYTE [ebx+robj.varid]
	movzx ecx, BYTE [var_flags-1+ecx]
	and ecx, BYTE 1
	lea eax, [eax+1+ecx*4]
	mov [ebx+robj.type],al
	mov edx,ebx
	jmp updatebuttons

.trwin_dropdown:
	cmp cl,5
	je .ddl1_action
	cmp cl,7
	je .ddl2_action
ret

.valuebtn:
	mov ebx, [curselrobj]
	or ebx, ebx
	jnz .valuebtn_nret
ret
.valuebtn_nret:
	movzx ecx,BYTE [ebx+robj.varid]
	dec ecx
	mov al,[var_flags+ecx]
	
	test al, 0x26
	jnz .mtool

/*
; AX = text ID (if -1: text in baTempBuffer1)
; BL = max. text width
; CH = max. text length
; CL,DX = origin window type,id
; BP = title (text ID)
CreateTextInputWindow
*/

	test BYTE [ebx+robj.flags], 1
	jz .blank
	mov eax, [ebx+robj.word1]
	mov DWORD [textrefstack], eax
	mov ax, statictext(printdword)
	jmp .nblank
.blank:
	mov ax, -1
	mov dword [baTempBuffer1], 0
.nblank:
	mov bl, 30
	mov cx, 0x7F2A
	mov dx, 111
	mov bp, ourtext(tr_enternumber)
	jmp [CreateTextInputWindow]
.valuebtnret:
ret

.mtool:
	push    esi
	
	btc     DWORD [esi+window.activebuttons], 8
	jb      .undomtool
	mov     dx, [esi+window.id]
	mov     ax, 2A01h
	mov     ebx, -1
	mov     esi, waAnimGoToCursorSprites
	call    [setmousetool]          ; AL = tool type (0 = none)
	                                ; AH = associated window type
	                                ; DX = associated window id
	                                ; EBX = mouse cursor sprite
	                                ; if EBX = -1: ESI -> cursor animation table
jmp .redrawvaluebtn

.undomtool:
	xor ebx,ebx
	xor eax,eax
	xor edx,edx
	call [setmousetool]

.redrawvaluebtn:
	pop esi
.redrawvaluebtnnpopesi:
	mov edx, [curselrobj]
	jmp updatebuttons

.mtoolclickhndlr:
	and BYTE [esi+window.activebuttons+1], ~0x30
	movzx eax, WORD [mousetoolclicklocxy]
	mov ebx, [curselrobj]
	or ebx, ebx
	jnz .mtoolclickhndlr_nret
	cmp BYTE [curmode], 1
	je NEAR copysharelist
ret
.mtoolclickhndlr_nret:

	mov cl, [landscape4(ax,1)]
	shr cl,4
	movzx edx,BYTE [ebx+robj.varid]
	mov dl, [var_flags-1+edx]
	test dl,2
	jz .notstation
	cmp cl,5
	jne NEAR .mtcl_fexit
	
	cmp BYTE [landscape5(ax,1)],7
	ja NEAR .mtcl_fexit
	movzx cx, BYTE [landscape2+eax]
	mov [ebx+robj.word1], cx
	or BYTE [ebx+robj.flags],1
	and BYTE [esi+window.disabledbuttons+1], ~0x10
	jmp .mtcl_exit

.notstation:
	test dl,4
	jz .notdepot
	cmp cl, 1
	jne .mtcl_fexit
	mov dl, [landscape5(ax,1)]
	and dl, 0xC0
	xor dl, 0xC0
	jnz .mtcl_fexit

.searchdepot:
	mov ecx, 0x100
	mov edx, depotarray
	.depotloop:
		cmp WORD [edx+depot.XY], ax
		je .foundepot
		add edx, byte depot_size
	loop .depotloop
	jmp .mtcl_exit

.foundepot:
	neg ecx
	//add ecx,0x100
	and ecx, 0xff
	mov DWORD [ebx+robj.word1], ecx
	or BYTE [ebx+robj.flags],1
	and BYTE [esi+window.disabledbuttons+1], ~0x10
	jmp .mtcl_exit

.notdepot:
	test dl,32
	jz .mtcl_fexit
	
	cmp cl, 1
	jne .mtcl_fexit
	
	mov dl, [landscape5(ax,1)]
	and dl, 0xC0
	xor dl, 0x40
	jnz .mtcl_fexit
	
	mov DWORD [ebx+robj.word1], eax
	or BYTE [ebx+robj.flags],1
	and BYTE [esi+window.disabledbuttons+1], ~0x10

	jmp .mtcl_exit

.mtcl_fexit:
	and BYTE [ebx+robj.flags], ~1
	mov DWORD [ebx+robj.word1],0
.mtcl_exit:
	push esi
	jmp .undomtool

.mtoolclosehndlr:
	and BYTE [esi+window.activebuttons+1], ~1
	jmp .redrawvaluebtnnpopesi

.andbtn:
	mov al, 0
	jmp bophandler
.orbtn:
	mov al, 1
	jmp bophandler
.xorbtn:
	mov al, 2
	jmp bophandler

.delbtn:
	cmp BYTE [curmode], 1
	jne .delnorm
	xor eax, eax
	jmp copysharelistbtn
.delnorm:
	mov edx, [curselrobj]
	or edx, edx
	jz NEAR .delrstret
	mov cl, [edx+robj.type]
	cmp cl, 32
	jae .delbtnbop
	mov DWORD [edx], 0x01800000
	mov DWORD [edx+4], 0
	jmp updatebuttons
.delbtnbop:
	movzx ebp, WORD [edx+robj.word1]
	lea ecx, [ebp*2]
	lea ecx, [robjs+ecx*4]
	movzx eax, WORD [edx+robj.word2]
	lea ebx, [eax*2]
	lea ebx, [robjs+ebx*4]
	or ebp, ebp
	jz .swap
	cmp WORD [ecx], 0
	je .swap
	or eax, eax
	jz .doit
	cmp WORD [ebx], 0
	jnz .bopend1	//end: both children robjs set
	jmp .doit

.swap:
	xchg ecx, ebx
	xchg ebp, eax

.doit:	//clear robj at ebx, transfer robj at ecx to edx if ecx robj not blank, else blank robj at edx
	or eax, eax
	jz .noebxrobj
	xor eax, eax
	mov [ebx], eax
	mov [ebx+4], eax
.noebxrobj:
	or ebp, ebp
	jz .blankedx
	xchg eax, [ecx]
	and eax, 0x00ffffff
	xchg [edx], eax
	and eax, 0xff000000
	or [edx], eax
	xor eax, eax
	xchg eax, [ecx+4]
	mov [edx+4], eax
.bopend1:
	call countrows
	jmp updatebuttons
.blankedx:
	mov DWORD [edx], 0x01800000
	mov [edx+4], eax
	call countrows
	jmp updatebuttons
.delrstret:
ret

.resetbtn:
	cmp BYTE [curmode], 1
	jne .rstnorm
	mov eax, 1
	jmp copysharelistbtn
.rstnorm:
	push esi
	movzx esi, WORD [curxypos]
	call delrobjsignal
	pop esi
	xor edx,edx
	mov [robjidindex], dx
	mov [robjid], dx
	mov [rootobj], edx
	mov [curselrobjid], dx
	mov [curselrobj], edx
	call countrows
	jmp updatebuttons

bophandler:
	mov edx, [curselrobj]
	or edx, edx
	jz NEAR .ret
	
	mov ecx, robjnum-1
	mov ebx, robjs+robj_size
	.sbl1:
		test BYTE [ebx+2], 0x80
		jz .sbl2
		add ebx, robj_size
	loop .sbl1
	jmp error
.sbl2:
	mov ebp, ebx
	jmp .sbl3_1
	.sbl3:
		test BYTE [ebx+2], 0x80
		jz .sbl4
	.sbl3_1:
		add ebx, robj_size
	loop .sbl3
	jmp error
.sbl4:
	mov DWORD [ebp], 0x01800000
	mov DWORD [ebp+4], 0
	mov ecx, [edx+4]
	mov [ebx+4], ecx
	mov ecx, [edx]
	mov [ebx], ecx
	movzx eax, al
	add eax, 0x00800020
	and ecx, 0xff000000
	or eax, ecx
	mov [edx], eax
	sub ebp, robjs
	sub ebx, robjs
	shr ebx, 3
	shl ebp, 13
	or ebx, ebp
	mov [edx+4], ebx
	call countrows
	jmp updatebuttons
.ret:
ret

textwindowchangehandler:
	push esi
	mov ebx, 0
	mov esi, baTextInputBuffer
	call getnumber
	pop esi
	jc .fail
	cmp edx, -1
	je .fail
.setnum:
	mov eax, [curselrobj]
	or eax, eax
	jz .ret
	movzx ebx, BYTE [eax+robj.type]
	or ebx, ebx
	jz .ret
	cmp ebx, 32
	jae .ret
	movzx ebx, BYTE [eax+robj.varid]
	or ebx, ebx
	jz .ret
	mov bl, [var_flags-1+ebx]
	test bl, 0x18
	jz .ret
	mov [eax+robj.word1], edx
	or BYTE [eax+robj.flags], 1
	mov edx, eax
	call updatebuttons
.ret:
ret
.fail:
	xor edx, edx
	jmp .setnum

global tracerestrict_delrobjsignal1,tracerestrict_delrobjsignal1.oldfn

tracerestrict_delrobjsignal1:
	call delrobjsignal
	jmp near $
ovar .oldfn, -4, $,tracerestrict_delrobjsignal1

delrobjsignal:
	btr WORD [esi*2+landscape3],12
	jnc NEAR .end
	pusha
	mov ebx,esi
	shr bh,6
	shl bx,2
	mov bl,[landscape7+esi]
	
	xor eax,eax
	mov [landscape7+esi], al
	xchg WORD [robjidtbl+ebx*2], ax
	shl eax, 3
	lea ebx,[eax+robjs]

	dec BYTE [ebx+robj.count]
	jnz .pret

	//delete relevent restriction object and sub objects
	push DWORD .pret

.recurse:	//ebx=robj
	cmp BYTE [ebx], 32
	jl .norecurse
	push ebx
	movzx ebx, WORD [ebx+robj.word1]
	shl ebx, 3
	add ebx, robjs
	call .recurse
	mov ebx,[esp]
	movzx ebx, WORD [ebx+robj.word2]
	shl ebx, 3
	add ebx, robjs
	call .recurse
	pop ebx
.norecurse:
	mov DWORD [ebx],0
	mov DWORD [ebx+4],0
ret

.pret:
	popa
.end:
	ret

//in: edx=curselrobj,esi=window
updatebuttons:
	pusha
	cmp DWORD [rootobj], 0
	sete al
	mov [curmode], al
	or al, al
	jz .norm
	mov WORD [tracerestrictwindowelements.delbtn], ourtext(tr_copy)
	mov WORD [tracerestrictwindowelements.rstbtn], ourtext(tr_share)
	mov DWORD [esi+window.disabledbuttons], 0x0F80
	jmp .end
.norm:
	mov WORD [tracerestrictwindowelements.delbtn], 0x8824
	mov WORD [tracerestrictwindowelements.rstbtn], ourtext(resetorders)
	or edx, edx
	jnz .noblank
	mov WORD [tracerestrictwindowelements.vartb],statictext(empty)
	mov WORD [tracerestrictwindowelements.optb],statictext(empty)
	mov DWORD [esi+window.disabledbuttons], 0x1FA0
	cmp DWORD [rootobj],0
	je NEAR .end
	or BYTE [esi+window.disabledbuttons], 0x20
	jmp .end

.noblank:
	xor ecx, ecx
	cmp BYTE [edx+robj.type], 32
	jb .cmp
	mov ecx, 0x180
	mov ebx, [edx+robj.word1]
	or bx, bx
	jz .nodisdel
	test ebx, 0xffff0000
	jz .nodisdel

	//both word1 and word2 set
	movzx eax, bx
	shl eax, 3
	shr ebx, 13
	add eax, robjs
	add ebx, robjs
	cmp WORD [eax], 0
	je .nodisdel
	cmp WORD [ebx], 0
	je .nodisdel

	or ecx, 0x1000
.nodisdel:
	mov [esi+window.disabledbuttons], ecx
	movzx ax, BYTE [edx+robj.type]
	add ax, statictext(tr_andbtn)-32
	mov WORD [tracerestrictwindowelements.vartb], ax
	mov WORD [tracerestrictwindowelements.optb],statictext(empty)
	jmp .end

.cmp:
	movzx eax, BYTE [edx+robj.varid]
	or eax, eax
	jnz .novar
	or cx, 0x180
.novar:
	mov ax,[var_array-2+eax*2]
	mov WORD [tracerestrictwindowelements.vartb],ax

	movzx eax, BYTE [edx+robj.type]
	or eax, eax
	jnz .noop
	or ch, 1
.noop:
	mov ax,[op_array-2+eax*2]
	mov WORD [tracerestrictwindowelements.optb],ax
	mov [esi+window.disabledbuttons], ecx

.end:
	mov al,[esi+window.type]
	mov bx,[esi+window.id]
	or al, 0x40
	call dword [invalidatehandle]
	popa
ret

//In: esi,edi
DisplayTrDlgText:

.draw:
	pusha
	mov WORD [curprintrobjnum], 0
	mov eax, [rootobj]
	or eax, eax
	jz NEAR .exit
	call .recurse
	mov DWORD [textrefstack], ourtext(tr_end)+(statictext(empty)<<16)
	movzx ecx, BYTE [eax+robj.count]
	cmp ecx, BYTE 1
	je .notshared
	shl ecx, 16
	mov cx, ourtext(tr_endshare)
	mov DWORD [textrefstack+2], ecx
.notshared:
	push DWORD .exit
	push DWORD -1
	jmp .print

.exit:
	popa
ret

//eax=robj
//trashes: ebx,ecx,edx,ebp
.recurse:
	push eax
	movzx ecx, BYTE [eax+robj.type]
	cmp ecx, 32
	jae NEAR .bop
	movzx ecx, BYTE [eax+robj.varid]
	dec ecx
	js NEAR .dash
	movzx edx, BYTE [var_flags+ecx]
	test edx, 2
	jz NEAR .nostation
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array_nc+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array_nc-2+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jz .dontprintstation
	movzx ecx, BYTE [eax+robj.word1]
	imul ecx, ecx, station_size
	add ecx, [stationarrayptr]
	mov bp, [ecx+station.name]
	mov WORD [textrefstack+6], bp
	mov ebp, [ecx+station.townptr]
	mov dx, [ebp+town.citynametype]
	mov WORD [textrefstack+8], dx
	mov edx, [ebp+town.citynameparts]
	mov DWORD [textrefstack+10],edx
	jmp .print
.dontprintstation:
	mov WORD [textrefstack+6], statictext(empty)
	jmp .print

.nostation:
	test edx, 4
	jz NEAR .nodepot
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array_nc+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array_nc-2+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jnz .printdepot
	mov WORD [textrefstack+6], statictext(empty)
	jmp .print
.printdepot:
	mov WORD [textrefstack+6], statictext(trdlg_txt_depot)
	movzx ecx, BYTE [eax+robj.word1]
	add ecx,ecx
	lea ecx, [depotarray+ecx+ecx*2]
	mov ebp, [ecx+depot.townptr]
	mov dx, [ebp+town.citynametype]
	mov WORD [textrefstack+8], dx
	mov edx, [ebp+town.citynameparts]
	mov DWORD [textrefstack+10], edx

	mov cx, [ecx+depot.XY]
	mov bp,cx
	and cx,0xff
	mov WORD [textrefstack+14], cx
	shr bp,8
	mov WORD [textrefstack+16], bp
	jmp .print

.nodepot:
	test edx, 24
	jz .nodword
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array_nc+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array_nc-2+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jnz .printdword
	mov WORD [textrefstack+6], statictext(empty)
	jmp .print
.printdword:
	mov WORD [textrefstack+6], statictext(printdword)
	mov ecx, [eax+robj.word1]
	mov DWORD [textrefstack+8], ecx
	jmp .print
.nodword:
	test edx, 32
	jz .nosignal
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array_nc+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	cmp ecx, 5
	jb .blank4
	mov bp, [op_array3-10+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jnz .blank6
	mov WORD [textrefstack+6], statictext(trdlg_txt_XY)
	mov cx, [eax+robj.word1]
	mov bp,cx
	and cx,0xff
	mov WORD [textrefstack+8], cx
	shr bp,8
	mov WORD [textrefstack+10], bp
	jmp .print
.nosignal:

	//none
	mov DWORD [textrefstack], statictext(empty)+statictext(empty)<<16
.blank4:
	mov WORD [textrefstack+4], statictext(empty)
.blank6:
	mov WORD [textrefstack+6], statictext(empty)

.print:
	mov cx, [esi+window.x]
	movzx edx, WORD [esi+window.y]
	add cx, 4
	mov ax, [curtextindentlevel]
	shl ax, 4
	add ax, cx
	movzx ebp, BYTE [esi+window.itemsoffset]
	mov cl, [scrollshiftfactor]
	shl ebp, cl
	mov cx, ax
	movzx eax, WORD [curprintrobjnum]
	inc WORD [curprintrobjnum]
	sub eax, ebp
	js .quit
	cmp eax, numrows
	jae .quit
	shl eax, 2
	lea eax, [eax*2+eax]
	lea edx, [edx+eax+18]
	mov al, -1
	mov bx, statictext(blacktext)
	mov ebp, [esp]
	cmp ebp, [curselrobj]
	jne .nohilite
	mov bx, statictext(whitetext)
.nohilite:

	push esi
	call [drawtextfn]
	pop esi

.quit:
	pop eax
ret
.dash:
	mov WORD [textrefstack], statictext(dash)
	jmp .print

.bop:
	sub ecx, 32
	jnz .nand
	mov dx, ourtext(tr_andbtn)
	jmp .bopprnt
.nand:
	dec ecx
	jnz .nor
	mov dx, ourtext(tr_orbtn)
	jmp .bopprnt
.nor:
	dec ecx
	jnz .quit
	mov dx, ourtext(tr_xorbtn)
.bopprnt:
	mov [textrefstack], dx
	push DWORD .bopafterprint
	push eax
	jmp .print
.bopafterprint:
	inc WORD [curtextindentlevel]
	movzx eax, WORD [eax+robj.word1]
	shl eax, 3
	add eax, robjs
	call .recurse
	mov eax, [esp]
	movzx eax, WORD [eax+robj.word2]
	shl eax, 3
	add eax, robjs
	call .recurse
	pop eax
	dec WORD [curtextindentlevel]
ret

countrows:
	push eax
	push edx
	xor eax, eax
	mov edx, [rootobj]
	or edx, edx
	jz .ret
	push DWORD .ret

.recurse:
	inc eax
	cmp BYTE [edx+robj.type], 32
	jb .n5
	push edx
	movzx edx, WORD [edx+robj.word1]
	or edx, edx
	jnz .n1
	inc eax
	jmp .n2
.n1:
	shl edx, 3
	add edx, robjs
	call .recurse
	mov edx, [esp]
.n2:
	movzx edx, WORD [edx+robj.word2]
	or edx, edx
	jnz .n3
	inc eax
	jmp .n4
.n3:
	shl edx, 3
	add edx, robjs
	call .recurse
.n4:
	pop edx
.n5:
ret

.ret:
	inc eax
	xor edx, edx
	jmp .shrtest
.shr1:
	shr eax, 1
	inc edx
.shrtest:
	test eax, 0xffffff00
	jnz .shr1
	mov BYTE [scrollshiftfactor], dl
	mov BYTE [esi+window.itemstotal], al
	pop edx
	pop eax
ret

uvarw curprintrobjnum, 1
uvarw curtextindentlevel, 1
uvarb scrollshiftfactor, 1

//eax: 0=copy,1=share
copysharelistbtn:
	push esi
	lea ecx, [eax+12]
	mov dx, ax
	xor dx, 1
	add dx, 12
	btr     WORD [esi+window.activebuttons], dx
	btc     WORD [esi+window.activebuttons], cx
	jc      .undomtool
	
	inc al
	mov [copyshareaction], al
	
	mov     dx, [esi+window.id]
	mov     ax, 2A01h
	mov     ebx, -1
	mov     esi, waAnimGoToCursorSprites
	call    [setmousetool]          // AL = tool type (0 = none)
	                                // AH = associated window type
	                                // DX = associated window id
	                                // EBX = mouse cursor sprite
	                                // if EBX = -1: ESI -> cursor animation table
	jmp .end
.undomtool:
	xor ebx,ebx
	mov [copyshareaction], bl
	xor eax,eax
	xor edx,edx
	call [setmousetool]
.end:
	pop esi
ret

uvarb copyshareaction, 1
//1=copy,2=share

//eax=coords of source
copysharelist:
	pusha
	push esi
	push eax
	xor ebx,ebx
	xor eax,eax
	xor edx,edx
	call [setmousetool]
	pop eax
	
	mov [tr_copylist_emergency_stack_pointer], esp
	
	cmp BYTE [copyshareaction], 0
	je NEAR .ret
	
	mov cl, [landscape4(ax,1)]
	shr cl, 4
	cmp cl, 1
	jne NEAR .ret
	test BYTE [landscape3+1+eax*2], 0x10
	jz NEAR .ret
	mov cl, [landscape5(ax,1)]
	shr cl, 6
	xor cl, 1
	jnz NEAR .ret
	
	mov ecx, eax
	shr ch,6
	shl cx,2
	mov cl, [landscape7+eax]
	movzx ebx, WORD [robjidtbl+ecx*2]
	or ebx, ebx
	jz NEAR .ret

	movzx eax, WORD [curxypos]
	//note eax now is target tile coords
	mov edx, eax
	shr dh,6
	shl dx,2
	xor dl,dl
	mov ecx,0x100
	lea edx, [robjidtbl+edx*2]
	.sbl2:
		cmp WORD [edx], 0
		je .sbl2f
		add edx,2
	loop .sbl2
	call error
	pop esi
	popa
ret
.sbl2f:
	mov ecx, edx
	sub ecx, robjidtbl
	shr ecx, 1
	mov [robjidindex], cx

	mov DWORD [curselrobj], 0

	cmp BYTE [copyshareaction], 1
	mov BYTE [copyshareaction], 0
	je .copy

.share:
	mov BYTE [landscape7+eax], cl
	or BYTE [landscape3+1+eax*2], 0x10
	mov [edx], bx
	mov [robjid], bx
	shl ebx, 3
	add ebx, robjs
	mov [rootobj], ebx
	inc BYTE [ebx+robj.count]
	jnz NEAR .ret
	//error too many shared
	and BYTE [landscape3+1+eax*2], ~0x10
	xor eax, eax
	mov [robjidindex], ax
	mov [edx], ax
	mov [robjid], ax
	mov [rootobj], eax
	mov BYTE [ebx+robj.count], 0xff
	call error
	jmp .ret

.copy:
	shl ebx, 3
	mov edi, robjs
	add ebx, edi
	push DWORD .endcopy
.recurse:
	cmp BYTE [ebx+robj.type], 32
	jb .cmp

	push ebx
	movzx ebx, WORD [ebx+robj.word1]
	shl ebx, 3
	add ebx, robjs
	call .recurse
	mov ebx, [esp]
	push eax
	movzx ebx, WORD [ebx+robj.word2]
	shl ebx, 3
	add ebx, robjs
	call .recurse
	call .getnextfree //only modifies edi
	pop edx
	pop ebx
	mov ecx, [ebx]
	mov [edi], ecx
	sub edx, robjs
	shr edx, 3
	sub eax, robjs
	shl eax, 13
	or edx, eax
	mov [edi+4], edx
	mov eax, edi
ret
.cmp:
	call .getnextfree
	mov ecx, [ebx]
	mov [edi], ecx
	mov ecx, [ebx+4]
	mov [edi+4], ecx
	mov eax, edi
ret

.endcopy:
	mov [rootobj], eax
	mov BYTE [eax+robj.count], 1
	sub eax, robjs
	shr eax, 3
	mov [robjid], ax
	movzx eax, WORD [curxypos]
	mov cl, [robjidindex]
	mov BYTE [landscape7+eax], cl
	or BYTE [landscape3+1+eax*2], 0x10
.ret:
	pop esi
	and BYTE [esi+window.activebuttons+1], ~3
	mov edx, [curselrobj]
	call updatebuttons
	popa
ret

.getnextfree:
	add edi, robj_size
	test BYTE [edi+robj.flags], 0x80
	jz .gotone
	cmp edi, robjs+robj_size*robjnum
	jb .getnextfree
	call error
	mov esp, [tr_copylist_emergency_stack_pointer]
	jmp .ret
.gotone:
ret

uvard tr_copylist_emergency_stack_pointer, 1

error:
	pusha
	mov bx,ourtext(tr_error1)
	mov dx,-1
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]
	popa
ret
