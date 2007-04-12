
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
extern cargotypes,newcargotypenames,cargobits,invalidatetile,cargotypes

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
	jz .norm
	
	test ch, 3
	jnz .check
	
	test ch, 14h	//N or W track
	jz .nonw
	test BYTE [landscape3+edi*2], 0xC0
	jnz .check

	.nonw:
	test ch, 28h	//S or E track
	jz .norm
	test BYTE [landscape3+edi*2], 0x30
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
	jz NEAR .tret
	
	mov [tempdlvar],dl
	
	cmp dh,1
	je near .trainlen
	cmp dh,2
	je near .maxspeed
	cmp dh,3
	je near .curorder
	cmp dh,4
	je near .curdeporder
	cmp dh,5
	je near .totalpower
	cmp dh,6
	je near .totalweight
	cmp dh,10
	jle near .sigval
	cmp dh,11
	je near .maxspeed_mph
	cmp dh,12
	je near .nextorder
	cmp dh,13
	je near .prevst
	cmp dh,14
	je near .cargo
	cmp dh,15
	je near .distsig
	cmp dh,16
	je near .nextdeporder

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
	
.maxspeed_mph:
	movzx ecx, WORD [eax+veh.maxspeed]
	lea ecx, [ecx+ecx*4]
	shr ecx, 3
	movzx edx, WORD [ebx+robj.word1]
	jmp .gotvar

.nextdeporder:
	push DWORD .deporderin
	jmp .nextorderin
.nextorder:
	push DWORD .orderin
.nextorderin:
	movzx edx, BYTE [eax+veh.currorderidx]
	inc edx
	movzx ecx, BYTE [eax+veh.totalorders]
	cmp edx, ecx
	jb .nosubecx
	sub edx, ecx
	.nosubecx:
	mov ecx, [eax+veh.scheduleptr]
	mov cx, [ecx+edx*2]
	ret

.curorder:
	mov cx, [eax+veh.currorder]
.orderin:
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
.deporderin:
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
	push eax
	xor ecx, ecx
.totalweight_next:
		mov edx, [eax+veh.veh2ptr]
		movzx edx, WORD [edx+veh2.fullweight]
		add ecx, edx
		movzx eax, WORD [eax+veh.nextunitidx]
		cmp ax, -1
		je .totalweight_end
		shl eax, vehicleshift
		add eax, [veharrayptr]
	jmp .totalweight_next
.totalweight_end:
	movzx edx, WORD [ebx+robj.word1]
	pop eax
	jmp .gotvar
	
.prevst:
	movzx ecx, BYTE [eax+veh.laststation]
	movzx edx, BYTE [ebx+robj.word1]
	jmp .gotvar
	
.cargo:
	push eax
	mov dl, [ebx+robj.word1]
	xor cl, cl
.cargo_next:
	mov ch, [eax+veh.cargotype]
	cmp WORD [eax+veh.capacity], 0
	movzx eax, WORD [eax+veh.nextunitidx]
	je .no_cargo_check
	cmp ch, dl
	sete ch
	or cl, ch
.no_cargo_check:
	cmp ax, -1
	je .cargo_end
	shl eax, vehicleshift
	add eax, [veharrayptr]
	jmp .cargo_next
.cargo_end:
	movzx ecx, cl
	mov edx, 1
	pop eax
	jmp .gotvar
	
.distsig:
	movzx ecx, WORD [tracertdistance]
	movzx edx, WORD [ebx+robj.word1]
	jmp .gotvar

.sigval:
	push eax
	sub dh, 3	//7-10 --> 4-7, signal bits in L2,L3
	mov cl, dh
	movzx eax, WORD [ebx+robj.word1]
	mov dl, [landscape4(ax,1)]
	shr dl, 4
	cmp dl, 1
	jne .sigval_redret
	mov dh, [landscape5(ax,1)]
	mov ch, dh
	and ch, 0xC0
	xor ch, 0x40
	jnz .sigval_redret
	test dh, 3
	jz .noewtrack
	or cl, 2
	.noewtrack:
	test dh, 0x30
	jz .nonstrack
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

%assign numrows 10
%assign winheight numrows*12+36
%assign buttongap 0
btn_start_end equ -buttongap-1
%define prev_btn start
%macro btndata 2-3 //name,width,follows
%ifstr %3
btn_%1_start equ btn_ %+ %3 %+ _end + buttongap+1
%else
btn_%1_start equ btn_ %+ prev_btn %+ _end + buttongap+1
%endif
btn_%1_end equ btn_%1_start+%2
%xdefine prev_btn %1
%endmacro

%define btnwidths(a) btn_ %+ a %+ _start , btn_ %+ a %+ _end

btndata vartxt, 190
btndata varddl, 12
btndata optxt, 40
btndata opddl, 12
btndata value, 40
btndata valueddl, 12
btndata and, 30
btndata or, 30
btndata xor, 30
btndata delete, 50
btndata reset, 50
btndata sizer, 12
%assign winwidth btn_sizer_end+1

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

	// Set text color 3
	db cWinElemSetTextColor, 0x10
	dw 0, 0, 0, 0, 0
	
	// Text Box of the Var Dropdown List 4
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(vartxt), winheight-13, winheight-1
	.vartb: dw statictext(empty)

	// Drop Down List button for Var 5
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(varddl), winheight-13, winheight-1, statictext(txtetoolbox_dropdown)

	// Text Box of the Op Dropdown List 6
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(optxt), winheight-13, winheight-1
	.optb: dw statictext(empty)

	// Drop Down List button for Op 7
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(opddl), winheight-13, winheight-1, statictext(txtetoolbox_dropdown)

	// Value button 8
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(value), winheight-13, winheight-1, ourtext(tr_valuebtn)

	// And button 9
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(and), winheight-13, winheight-1, ourtext(tr_andbtn)

	// Or button 10
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(or), winheight-13, winheight-1, ourtext(tr_orbtn)
	
	// Xor button 11
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(xor), winheight-13, winheight-1, ourtext(tr_xorbtn)

	// Delete button 12
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(delete), winheight-13, winheight-1
	.delbtn: dw 0x8824
	
	// Reset button 13
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(reset), winheight-13, winheight-1
	.rstbtn: dw ourtext(resetorders)

	// Text Box 14
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, winwidth-12, 14, winheight-14
	.maintb: dw statictext(empty)
	
	// Slider 15
	db cWinElemSlider, cColorSchemeGrey
	dw winwidth-11, winwidth-1, 14, winheight-14,0
	
	// Template for value drop-down list 16
	db cWinElemDummyBox, cColorSchemeGrey
	dw btn_optxt_start, btn_valueddl_end, winheight-13, winheight-1, 0

	// Drop Down List button for Value 17
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(valueddl), winheight-13, winheight-1, statictext(txtetoolbox_dropdown)
	
	// Window sizer 18
	db cWinElemSizer, cColorSchemeGrey
	dw btnwidths(sizer), winheight-13, winheight-1, 0

	// Sizer data 19
	db cWinElemExtraData, cWinDataSizer
	dd TRConstraints, TRSizes
	dw 0

	db 0xb

endvar

vard TRSizes
	dw winwidth, winwidth
	db 1, -1
	dw 0
	dw 2*12+36, 30*12+36
	db 12, 19
	dw 36
endvar

vard TRConstraints
	db 0
	db 0
	db 8
	db 0
	times 10 db 12
	db 8
	db 8
	times 3 db 12
	db 0
endvar

varw pre_op_array
dw statictext(empty)
endvar
varw op_array
dw statictext(trdlg_lt)
dw statictext(trdlg_gt)
dw statictext(trdlg_lte)
dw statictext(trdlg_gte)
dw ourtext(trdlg_eq)
dw ourtext(trdlg_neq)
dw 0xffff
endvar

varw pre_op_array3
dw statictext(empty)
dw statictext(empty)
endvar

// four words between ourtext(tr_sigval_is_g) and first statictext(empty)
// if robj.type==0
// op_array3-8 + robj.type*2 --> first statictext(empty)

varw op_array2
dw ourtext(trdlg_eq)
dw ourtext(trdlg_neq)
dw 0xffff
endvar

varw op_array3
dw ourtext(tr_sigval_is_g)
dw ourtext(tr_sigval_is_r)
dw 0xffff
endvar

varw op_array4
dw ourtext(tr_sigval_is_green)
dw ourtext(tr_sigval_is_red)
dw 0xffff
endvar

%assign var_array_num 17
%assign var_end_mark 16
varw pre_var_array
dw ourtext(tr_vartxt)
endvar
varw var_array
dw ourtext(tr_trainlen)
dw ourtext(tr_maxspeed_kph)
dw ourtext(tr_curorder)
dw ourtext(tr_curdeporder)
dw ourtext(tr_totalpower)
dw ourtext(tr_totalweight)
dw ourtext(tr_sigval_sw)
dw ourtext(tr_sigval_se)
dw ourtext(tr_sigval_nw)
dw ourtext(tr_sigval_ne)
dw ourtext(tr_maxspeed_mph)
dw ourtext(tr_nextorder)
dw ourtext(tr_lastvisitstation)
dw ourtext(tr_carriescargo)
dw ourtext(tr_distancefromsig)
dw ourtext(tr_nextdeporder)
dw 0xffff
endvar

//1: 2op, 2: station, 4: depot, 8: uword, 16: udword, 32: sig, 64: cargo
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
db 8
db 3
db 3
db 65
db 8
db 5
endvar

varw pre_var_compat_id
db -1
endvar
varb var_compat_id
db 0
db 1
db 2
db 3
db 4
db 5
db 6
db 6
db 6
db 6
db 7
db 2
db 2
db 8
db 9
db 3
endvar

%assign j 0

%macro varinfo 2	//%1=variable number, %2=j
var_info_ddlnum_%2_ %+ currentflagnum equ %1
var_info_revddlnum_%2_%1 equ currentflagnum
var_exists_%2_%1 equ 1
var_exists2_%2_ %+ currentflagnum equ 1
%assign currentflagnum currentflagnum+1
%endmacro

%macro tr_mklists 1
varb dropdownorder_%1
%assign i 0
%rep currentflagnum
db var_info_ddlnum_%1_ %+ i
%assign i i+1
%endrep
db var_end_mark
endvar

varb revdropdownorder_%1
%assign i 0
%rep var_end_mark
%if var_exists_%1_ %+ i == 1
db var_info_revddlnum_%1_ %+ i
%else
db var_end_mark
%endif
%assign i i+1
%endrep
db var_end_mark
endvar
%endmacro

%rep 3
%assign j j+1
%assign currentflagnum 0

varinfo 0,j
%if j==2 || j==3
varinfo 1,j	//kph
%else
var_exists_ %+ j %+ _1 equ 0
%endif
%if j==1 || j==3
varinfo 10,j	//mph
%else
var_exists_ %+ j %+ _10 equ 0
%endif
varinfo 2,j
varinfo 11,j
varinfo 12,j
varinfo 3,j
varinfo 15,j
varinfo 4,j
varinfo 5,j
varinfo 13,j
varinfo 14,j
varinfo 6,j
varinfo 7,j
varinfo 8,j
varinfo 9,j

tr_mklists j

%endrep

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
	mov dx,111
	call dword [BringWindowToForeground]
	jnz NEAR .alreadywindowopen

	mov cx, 0x2A
	mov dx, -1
	mov eax, (640-winwidth)/2 + (((480-winheight)/2) << 16) // x, y
	mov ebx, winwidth + (winheight << 16) // width , height
	mov ebp, trwin_msghndlr
	call dword [CreateWindow]

.alreadywindowopen:
	
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

	mov WORD [tracerestrictwindowelements.vartb],ourtext(tr_vartxt)
	mov WORD [tracerestrictwindowelements.optb],ourtext(tr_optxt)

	call countrows
	mov edx, [curselrobj]
	call updatebuttons

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
	jne NEAR .ret
	
	movzx ecx,cl
	bt DWORD [esi+window.disabledbuttons], ecx
	jc NEAR .ret

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
	je NEAR .ddl1
	
	cmp cl, 5
	je NEAR .ddl1
	
	cmp cl, 6
	je NEAR .ddl2
	
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

	cmp cl, 17
	je NEAR .valuebtn

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
	call CheckDDL2
	mov eax, [curselrobj]
	or eax, eax
	jz .ddl1_norm
	movzx edx, BYTE [eax+robj.type]
	sub edx, 32
	jb .ddl1_norm
	mov DWORD [tempvar], ourtext(tr_andbtn) | ourtext(tr_orbtn)<<16
	mov DWORD [tempvar+4], ourtext(tr_xorbtn) | 0xffff0000
	mov BYTE [curvarddboxmode], 1

	jmp .ddl1_nomoddx

	.ddl1_norm:
	push ecx
	mov BYTE [curvarddboxmode], 0
	mov eax, [curddlvarptr]
	mov ecx, var_array_num
	.ddl1_loop:
		movzx ebx,BYTE [eax+ecx-1]
		mov bx, [var_array+ebx*2]
		mov [tempvar-2+ecx*2],bx
	loop .ddl1_loop
	pop ecx
	mov eax, [curselrobj]
	or eax, eax
	jnz .ddl1_n
	cmp DWORD [rootobj], 0
	jne .ret
	mov edx, -1
	jmp .ddl1_nomoddx
.ddl1_n:
	movzx edx, byte [eax+robj.varid]
	or edx,edx
	jnz .ddl1_nodecdx
	dec edx
	jmp .ddl1_nomoddx
.ddl1_nodecdx:
	mov ebx, [currevddlvarptr]
	movzx dx, BYTE [ebx-1+edx]
.ddl1_nomoddx:
 	xor ebx, ebx
 	mov ecx, 5
	jmp dword [GenerateDropDownMenu]

.ddl2:
	call CheckDDL1
	mov eax, [curselrobj]
	or eax, eax
	jz .ret
	movzx dx, byte [eax+robj.type]
	dec dx
	//mov eax, [curoparray]
	movzx ebx, BYTE [eax+robj.varid]
	mov bl, [var_flags-1+ebx]
	mov eax, op_array
	test bl, 1
	jz .ddl_noop2array
	add eax, 8
	or dx, dx
	js .nosubdx4
	sub dx, 4
	.nosubdx4:
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
 	mov ecx, 7
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
	jmp updatebuttons.noddlcheck

.ddl1_action_norm:
	cmp BYTE [curvarddboxmode], 0
	jne .ddl1_action_bop_ret

	movzx eax,al
	mov ecx, [curddlvarptr]
	movzx eax, BYTE [ecx+eax]

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
	call refreshtile
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
	inc eax
	mov ecx, eax
	xchg [ebx+robj.varid],al
	mov dl, [ecx+var_compat_id-1]	//new var
	mov dh, [eax+var_compat_id-1]	//old var
	cmp dl, dh
	je .noclearvalue
	cmp dx, 0x0701
	je .ddl1_action_convert_mph_kph
	cmp dx, 0x0107
	je .ddl1_action_convert_kph_mph
	and BYTE [ebx+robj.flags], ~1
	xor al, al
	test BYTE [var_flags-1+ecx], 32
	jnz .nosetdefopis
	mov al, 5
.nosetdefopis:
	mov BYTE [ebx+robj.type], al
.noclearvalue:
	mov edx, ebx
	jmp updatebuttons.noddlcheck

.ddl1_action_convert_kph_mph:
	movzx edx, WORD [ebx+robj.word1]
	lea edx, [edx+edx*4]
	shr edx, 3
	mov [ebx+robj.word1], dx
	jmp .noclearvalue

.ddl1_action_convert_mph_kph:
	movzx eax, WORD [ebx+robj.word1]
	mov edx, 0x33333333
	mul edx
	add eax, 0x10000000
	adc edx, BYTE 0
	shrd eax, edx, 29
	mov [ebx+robj.word1], ax
	jmp .noclearvalue

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
	jmp updatebuttons.noddlcheck

.ddl3_action:
	movzx eax,al
	
	mov edx, [curselrobj]
	or edx, edx
	jnz .ddl3_action_nret
.ddl3_action_ret:
ret
.ddl3_action_nret:
	movzx ecx, BYTE [edx+robj.varid]
	test BYTE [var_flags-1+ecx], 64
	jz .ddl3_action_ret

	xor ecx, ecx

	.ddl3_action_cargo_loop:
	movzx ebx, BYTE [cargotypes+ecx]
	cmp ebx, 0xFF
	je .ddl3_action_cargo_skip
	bt DWORD [cargobits], ebx
	jnc .ddl3_action_cargo_skip
	dec eax
	js .ddl3_action_cargo_gotit
	.ddl3_action_cargo_skip:
	inc ecx
	cmp cl, 32
	jb .ddl3_action_cargo_loop
	.ddl3_action_cargo_gotit:
	mov [edx+robj.word1], cl
	or BYTE [edx+robj.flags], 1
	jmp updatebuttons.noddlcheck

.trwin_dropdown:
	cmp cl,5
	je NEAR .ddl1_action
	cmp cl,7
	je NEAR .ddl2_action
	cmp cl,17
	je .ddl3_action
ret

.valuebtn:
	call CheckDDL1
	call CheckDDL2
	mov ebx, [curselrobj]
	or ebx, ebx
	jnz .valuebtn_nret
ret
.valuebtn_nret:
	movzx eax,BYTE [ebx+robj.varid]
	dec eax
	mov al,[var_flags+eax]
	
	test al, 0x40
	jnz NEAR .valuebtnddlcargo

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
	mov bl, 0xFF
	mov cx, 0x1E2A
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

.valuebtnddlcargo:
	mov dl, [ebx+robj.word1]
	mov dh, [ebx+robj.flags]
	and dh, 1
	dec dh
	or dl, dh
	mov dh, -1
	xor ecx, ecx
	xor eax, eax
.valuebtnddlcargo_loop:
	movzx ebp, BYTE [cargotypes+ecx]
	cmp ebp, 0xFF
	je .valuebtnddlcargo_skip
	bt DWORD [cargobits], ebp
	jnc .valuebtnddlcargo_skip
	mov bp, [newcargotypenames+ecx*2]
	mov [tempvar+eax*2], bp
	cmp al, dl
	jne .valuebtnddlcargo_nosetcurr
	mov dh, al
	.valuebtnddlcargo_nosetcurr:
	inc eax
	.valuebtnddlcargo_skip:
	inc ecx
	cmp cl, 32
	jb .valuebtnddlcargo_loop
	mov WORD [tempvar+eax*2], 0xffff
	sar dx, 8
 	xor ebx, ebx
 	mov ecx, 17
	jmp dword [GenerateDropDownMenu]

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
	mov WORD [tracerestrictwindowelements.vartb], statictext(empty)
	mov WORD [tracerestrictwindowelements.optb], statictext(empty)
	push esi
	movzx esi, WORD [curxypos]
	call delrobjsignal
	mov eax, esi
	call refreshtile.goteax
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

global tracerestrict_delrobjsignal1,tracerestrict_delrobjsignal1.oldfn,delrobjsignal

tracerestrict_delrobjsignal1:
	call delrobjsignal
	jmp near $
ovar .oldfn, -4, $,tracerestrict_delrobjsignal1

delrobjsignal:
	btr WORD [esi*2+landscape3],12
	jnc NEAR .end
	pusha
	mov ebx, esi
	shr bh, 6
	shl bx, 2
	mov bl, [landscape7+esi]
	
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

uvard curddlvarptr
uvard currevddlvarptr
vard ddlvarptrlist
dd dropdownorder_1
dd dropdownorder_2
endvar
vard revddlvarptrlist
dd revdropdownorder_1
dd revdropdownorder_2
endvar

//in: edx=curselrobj,esi=window
updatebuttons:
	call CheckDDL1
	call CheckDDL2
	call CheckDDL3
.noddlcheck:
	pusha
	movzx ecx, BYTE [measuresys]
	mov eax, [ddlvarptrlist+ecx*4]
	mov [curddlvarptr], eax
	mov eax, [revddlvarptrlist+ecx*4]
	mov [currevddlvarptr], eax
	cmp DWORD [rootobj], 0
	sete al
	mov [curmode], al
	or al, al
	jz .norm
	mov WORD [tracerestrictwindowelements.delbtn], ourtext(tr_copy)
	mov WORD [tracerestrictwindowelements.rstbtn], ourtext(tr_share)
	mov WORD [tracerestrictwindowelements.vartb], ourtext(tr_vartxt)
	mov WORD [tracerestrictwindowelements.optb], ourtext(tr_optxt)
	mov DWORD [esi+window.disabledbuttons], 0x20FC0
	jmp .end
.norm:
	mov WORD [tracerestrictwindowelements.delbtn], 0x8824
	mov WORD [tracerestrictwindowelements.rstbtn], ourtext(resetorders)
	or edx, edx
	jnz .noblank
	mov WORD [tracerestrictwindowelements.vartb], ourtext(tr_vartxt)
	mov WORD [tracerestrictwindowelements.optb], ourtext(tr_optxt)
	mov DWORD [esi+window.disabledbuttons], 0x21FF0
	jmp .end

.noblank:
	cmp BYTE [edx+robj.type], 32
	jb .cmp
	mov ecx, 0x201C0
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
	add ax, ourtext(tr_andbtn)-32
	mov WORD [tracerestrictwindowelements.vartb], ax
	mov WORD [tracerestrictwindowelements.optb], ourtext(tr_optxt)
	jmp .end

.cmp:
	//ecx=0: mph, 1: kph

	mov ebx, ecx
	shl ecx, 3
	lea ecx, [ecx+ebx+2]			//ecx: kph=11, mph=2
	movzx eax, BYTE [edx+robj.varid]	//eax: kph=2, mph=11
	cmp eax, ecx
	jne .nobothmphkph
	mov DWORD [curddlvarptr], dropdownorder_3
	mov DWORD [currevddlvarptr], revdropdownorder_3
.nobothmphkph:
	xor ecx, ecx
	or eax, eax
	jnz .var
	or ecx, 0x1C0
.var:
	mov ebx, op_array
	test BYTE [var_flags-1+eax], 32
	jz .nsigop
	mov ebx, op_array3-8
.nsigop:
	test BYTE [var_flags-1+eax], 64
	jnz .nddl3
	or ecx, 0x20000
.nddl3:
	mov ax,[var_array-2+eax*2]
	mov WORD [tracerestrictwindowelements.vartb],ax

	movzx eax, BYTE [edx+robj.type]
	or eax, eax
	mov ax,[ebx-2+eax*2]
	jnz .noop
	or ecx, 0x20100
	mov ax,ourtext(tr_optxt)
.noop:
	mov WORD [tracerestrictwindowelements.optb],ax
	mov [esi+window.disabledbuttons], ecx

.end:
	mov al,[esi+window.type]
	mov bx,[esi+window.id]
	or al, 0x40
	call dword [invalidatehandle]
	popa
ret

CheckDDL1:
	test BYTE [esi+window.activebuttons], 20h
	jz .end
	pusha
	mov ecx, 5
	mov dx, -1
 	xor ebx, ebx
 	mov word [tempvar], 0xFFFF
	call dword [GenerateDropDownMenu]
	popa
.end:
ret

CheckDDL2:
	test BYTE [esi+window.activebuttons], 80h
	jz .end
	pusha
	mov ecx, 7
	mov dx, -1
 	xor ebx, ebx
 	mov word [tempvar], 0xFFFF
	call dword [GenerateDropDownMenu]
	popa
.end:
ret

CheckDDL3:
	test BYTE [esi+window.activebuttons+2], 2h
	jz .end
	pusha
	mov ecx, 17
	mov dx, -1
 	xor ebx, ebx
 	mov word [tempvar], 0xFFFF
	call dword [GenerateDropDownMenu]
	popa
.end:
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
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array-2+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jz .dontprintstation
	movzx ecx, BYTE [eax+robj.word1]
	imul ecx, ecx, station_size
	add ecx, [stationarrayptr]
	cmp WORD [ecx], 0
	je .clearvalueflag_dontprintstation
	mov bp, [ecx+station.name]
	or bp, bp
	jz .clearvalueflag_dontprintstation
	mov WORD [textrefstack+6], bp
	mov ebp, [ecx+station.townptr]
	or ebp, ebp
	jz .clearvalueflag_dontprintstation
	mov dx, [ebp+town.citynametype]
	mov WORD [textrefstack+8], dx
	mov edx, [ebp+town.citynameparts]
	mov DWORD [textrefstack+10],edx
	jmp .print
.clearvalueflag_dontprintstation:
	and BYTE [eax+robj.flags], ~1
.dontprintstation:
	mov WORD [textrefstack+6], statictext(empty)
	jmp .print

.nostation:
	test edx, 4
	jz NEAR .nodepot
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array-2+ecx*2]
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
	or ebp, ebp
	jz .clearvalueflag_dontprintstation
	mov dx, [ebp+town.citynametype]
	mov WORD [textrefstack+8], dx
	mov edx, [ebp+town.citynameparts]
	mov DWORD [textrefstack+10], edx

	mov cx, [ecx+depot.XY]
	or cx, cx
	jz .clearvalueflag_dontprintstation
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
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array-2+ecx*2]
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
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	cmp ecx, 5
	jb NEAR .blank4
	mov bp, [op_array4-10+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jz NEAR .blank6
	mov WORD [textrefstack+6], statictext(trdlg_txt_XY)
	mov cx, [eax+robj.word1]
	mov bp,cx
	and cx,0xff
	mov WORD [textrefstack+8], cx
	shr bp,8
	mov WORD [textrefstack+10], bp
	jmp .print
.nosignal:
	test edx, 64
	jz .nocargo
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array-2+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jnz .cargotxt
	mov WORD [textrefstack+6], statictext(empty)
	jmp .print
.cargotxt:
	movzx ecx, BYTE [eax+robj.word1]
	mov bp, [newcargotypenames+ecx*2]
	mov [textrefstack+6], bp
	jmp .print
.nocargo:


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
	cmp al, [esi+window.itemsvisible] //numrows
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
	mov edx, [curselrobj]
	jmp updatebuttons

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
	call refreshtile
	mov [edx], bx
	mov [robjid], bx
	shl ebx, 3
	add ebx, robjs
	mov [rootobj], ebx
	inc BYTE [ebx+robj.count]
	jnz NEAR .ret
	//error too many shared
	and BYTE [landscape3+1+eax*2], ~0x10
	call refreshtile
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
	push edx
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
	pop edx
	mov [rootobj], eax
	mov BYTE [eax+robj.count], 1
	sub eax, robjs
	shr eax, 3
	mov [robjid], ax
	mov [edx], ax
	movzx eax, WORD [curxypos]
	mov cl, [robjidindex]
	mov BYTE [landscape7+eax], cl
	or BYTE [landscape3+1+eax*2], 0x10
	call refreshtile
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

refreshtile:	//tile=[curxypos]
	pusha
	movzx eax, WORD [curxypos]
.in:
	xor ecx, ecx
	xchg ah, cl
	shl eax, 4
	shl ecx, 4
	call DWORD [invalidatetile]
	popa
ret
.goteax:
	pusha
	jmp .in
