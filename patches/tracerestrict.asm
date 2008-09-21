
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
#include <ptrvar.inc>
#include <flags.inc>
#include <bitvars.inc>

extern CreateWindow,DrawWindowElements,WindowClicked,DestroyWindow,WindowTitleBarClicked,GenerateDropDownMenu,BringWindowToForeground,invalidatehandle,setmousetool,getnumber,errorpopup
global robjgameoptionflag,robjflags
extern cargotypes,newcargotypenames,cargobits,invalidatetile,cargotypes
extern GenerateDropDownEx,GenerateDropDownExPrepare,DropDownExList
extern TransmitAction, MPRoutingRestrictionChange_actionnum, actionhandler,patchflags,miscmodsflags,setmainviewxy
extern zfuncdotraceroutehook,curtracertheightvar, chkrailroutetargetfn

global tr_siggui_btnclick,programmedsignal_turnitred

uvarb robjgameoptionflag,1
// 1=enabled&load

/*
//Save
uvard robjflags,4
//DWORD 0:	1=enabled&save -- restrictions enabled, 2=enabled&save -- programmable signals
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

//Signal tile:
//L3:	bit 12:		Restricted
//	bit 13:		Programmed

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

//type:
//1:	<
//2:	>
//3:	<=
//4:	>=
//5:	=
//6:	!=
//32:	and
//33:	or
//34:	xor
//64:	Restriction/Programmable signal switch

//type: 1-6
//varid:
//1:	Train length
//2:	Max speed
//3:	St of cur order
//4:	Dep of cur order
//5:	Power
//6:	Weight
//7-10:	Signal
//11:	Max speed: mph
//12:	St of next order
//13:	Previous st
//14:	Cargo
//15:	Distance from signal
//16:	Dep of next order
//17:	Days since last service
//18:	Searching for depot?

//19:	Number of green entrance signals in block
//20:	Number of green one-way entrance signals in block
//21:	Number of green two-way entrance signals in block
//22:	Number of red entrance signals in block
//23:	Number of red one-way entrance signals in block
//24:	Number of red two-way entrance signals in block
//25:	Current signal is SW/NW/SE/NE

//25:	Entered side of tile is/is not: SW/NW/SE/NE

//26:	Entered PBS signal tile

//type: 32-34
//word1:ID of first robj
//word2:ID of second robj

//type: 64
//word1:ID of restriction robj
//word2:ID of programmable signal obj

%macro get_reg_letter 1
	%ifidni %1,eax
	%define reg_letter a
	%elifidni %1,ebx
	%define reg_letter b
	%elifidni %1,ecx
	%define reg_letter c
	%elifidni %1,edx
	%define reg_letter d
	%else
	%error Read tracerestrict.asm:119
	%endif
%endmacro

%macro get_root_robj 4-5//coord reg,robjidindex out reg (must have l/h form: eax,ebx,ecx,edx),robjid out reg, rootobj ptr out reg,temp byte register
			//registers 1-4 allowed to clash
			//register 5 must not clash with registers 1/2,and is only needed if reg 1 === reg 2
	get_reg_letter %2
	%ifidn %1, %2
	mov %5,[landscape7+%1]
	%else
	mov %2,%1
	%endif
	shr reg_letter %+ h,6
	shl reg_letter %+ x,2
	%ifidn %1, %2
	mov reg_letter %+ l,%5
	%else
	mov reg_letter %+ l,[landscape7+%1]
	%endif
	movzx %3, WORD [robjidtbl+%2*2]
	lea %4, [robjs+%3*8]
%endmacro

%macro sget_root_robj 2-3	//coord reg, out reg, temp byte register
	get_root_robj %1,%2,%2,%2,%3
%endmacro

%macro get_rt_base_from_root_obj 1-2,"%1"	//robj reg,[robjid reg]
	cmp BYTE [%1+robj.type], 64
	jne %%ret
	movzx %2, WORD [%1+robj.word1]
	lea %1, [robjs+%2*8]
%%ret:
%endmacro

%macro get_ps_base_from_root_obj 1-2,"%1"	//robj reg,[robjid reg]
	cmp BYTE [%1+robj.type], 64
	jne %%ret
	movzx %2, WORD [%1+robj.word2]
	lea %1, [robjs+%2*8]
%%ret:
%endmacro

%macro get_auto_base_from_root_obj 1-2,"%1"	//robj reg,[robjid reg]
	cmp BYTE [%1+robj.type], 64
	jne %%ret
	add %1, [curdispmode]
	add %1, [curdispmode]
	movzx %2, WORD [%1+robj.word1]
	lea %1, [robjs+%2*8]
%%ret:
%endmacro

uvarb depotsearch
uvard tr_pbs_sigblentertile

uvard ps_presig_count,4
//+1=two way
//+2=red (else green)

global trpatch_DoTraceRouteWrapper1,trpatch_DoTraceRouteWrapper1.oldfn,trpatch_DoTraceRouteWrapper2,trpatch_DoTraceRouteWrapper3
trpatch_DoTraceRouteWrapper3:
	mov BYTE [depotsearch], 1
	mov ecx, [esp+4]
	jmp trpatch_DoTraceRouteWrapper1.common
trpatch_DoTraceRouteWrapper2:
	mov BYTE [depotsearch], 1
	mov ecx, [esp+6]
	jmp trpatch_DoTraceRouteWrapper1.common
trpatch_DoTraceRouteWrapper1:
	mov BYTE [depotsearch], 0
	mov ecx, [esp+14]
.common:

	cmp ecx, [veharrayendptr]
	jae .badvehptr
	mov [curvehicleptr], ecx
	sub ecx, [veharrayptr]
	jb .badvehptr
	and ecx, veh_size-1
	jnz .badvehptr

	testflags advzfunctions
	jnc .nozfunccall
	mov ecx, [curvehicleptr]
	movzx edi, di
	call zfuncdotraceroutehook
.nozfunccall:

	testflags tracerestrict
	jnc .nomodify
	test BYTE [robjflags], 1
	jz .nomodify

	mov [curstepfuncptr],edx
	mov edx,trpatch_stubstepfunc
.nomodify:
	call $
	ovar .oldfn, -4, $,trpatch_DoTraceRouteWrapper1
	mov DWORD [curvehicleptr],0
	mov DWORD [curtracertheightvar], 0
ret
.badvehptr:
	//Should never be reached
	//int3
	mov DWORD [curvehicleptr],0
jmp .nomodify

	// in:	ch=rail piece bit mask (one bit set)
	//	cl=rail piece bit number, +8 for "other" direction
	//	di=tile XY
	// out:	CF=1 if route ends
	// safe:eax,ebx
trpatch_stubstepfunc:
	//test BYTE [robjflags], 1
	//jz .norm
	mov al,[landscape4(di)]
	shr al, 4
	cmp al, 1
	jne .norm
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
	movzx eax, cl
	mov cl, [trackpiecesignalmask2+eax]
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
	cmp DWORD [tr_pbs_sigblentertile], 0
	jne .pbsfret
	stc
	ret
.pbsfret:
	push DWORD [chkrailroutetargetfn]
	add DWORD [chkrailroutetargetfn], 0x4F + (4*WINTTDX)
	call DWORD [curstepfuncptr]
	//don't modify flags
	pop DWORD [chkrailroutetargetfn]
	ret

	
var trackpiecesignalmask2, db 0x80,0x80,0x80,0x20,0x40,0x10,0,0,0x40,0x40,0x40,0x10,0x80,0x20,0,0

//eax=vehicle ptr,bx=xy coords of restrict tile,cl=signal bit
//trashes: (eax),ebx,ecx,edx
//returns true/false in eax

uvarb sigbit
varb tempdlvar,1
tracerestrict_doesitpass:
	mov [sigbit], cl
	movzx ebx,bx
	mov dl,[landscape7+ebx]
	shr bh,6
	shl bx,2
	mov bl,dl
	movzx ebx, WORD [robjidtbl+ebx*2]
	cmp BYTE [ebx*8+robjs+robj.type],64
	jne .norminit
	mov bx, [ebx*8+robjs+robj.word1]
.norminit:
	call programmedsignal_turnitred.recurse
	mov eax,edx
ret

//al=signal bit, bx=xy coords of signal tile
//trashes: (eax),ebx,ecx,edx,(edi<--bx)
//returns true/false 1/0 in al

programmedsignal_turnitred:
	movzx ebx,bx
	movzx eax, al
	mov [sigbit], al
	mov edi, ebx
	mov dl,[landscape7+ebx]
	shr bh,6
	shl bx,2
	mov bl,dl
	movzx ebx, WORD [robjidtbl+ebx*2]
	cmp BYTE [ebx*8+robjs+robj.type],64
	jne .norminit
	mov bx, [ebx*8+robjs+robj.word2]
.norminit:
	call .recurse
	or edx, edx
	setnz al
ret

//bx=robj id
//returns true/false in edx
//trashes: eax,ebx,ecx,(edx)
.recurse:
	movzx ebx,bx
	or ebx,ebx
	jz NEAR .tret
	
	lea ebx, [robjs+ebx*8]
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
	cmp dh,17
	je near .servdays
	cmp dh,18
	je near .searchingfordepot
	cmp dh,19
	je near .numgs
	cmp dh,20
	je near .numgos
	cmp dh,21
	je near .numgts
	cmp dh,22
	je near .numrs
	cmp dh,23
	je near .numros
	cmp dh,24
	je near .numrts
	cmp dh,25
	je near .tileside
	cmp dh, 26
	je near .pbssigentertl

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
	mov ecx, [eax+veh.scheduleptr]
	movzx ecx, word [ecx+edx*2]
	and cl, 1Fh
	cmp cl, 5
	jne .notadvorder
	shr ecx, 13
	add edx, ecx
.notadvorder:
	inc edx
	movzx ecx, BYTE [eax+veh.totalorders]
	cmp edx, ecx
	jb .nosubecx
	sub edx, ecx
	.nosubecx:
	shl edx,1
	add edx, [eax+veh.scheduleptr]
	mov cx, [edx]
	ret

.curorder:
	mov cx, [eax+veh.currorder]
	// Not initializing edx here: current order cannot be advanced.
.orderin:
	and ecx,0xff0f
	cmp cl,1
	je .curordernbl
	cmp cl,5
	jne .curorderbl
	and ch, ~11100001b
	cmp ch, 4
	jne .curorderbl
	mov cx, [edx+2]
	jmp short .curordernbl

.curorderbl:
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
	
.servdays:
	movzx ecx, WORD [currentdate]
	sub cx, [eax+veh.lastmaintenance]
	mov edx, [ebx+robj.word1]
	jmp .gotvar

.searchingfordepot:
	movzx ecx, BYTE [depotsearch]
	mov edx, 1
	jmp .gotvar
	
.numgs:
	mov ecx, [ps_presig_count]
	add ecx, [ps_presig_count+4]
	jmp .sigcountcommon_twcg
.numgos:
	mov ecx, [ps_presig_count]
	jmp .sigcountcommon
.numgts:
	mov ecx, [ps_presig_count+4]
	//jmp .sigcountcommon_twcg	//fall through

.sigcountcommon_twcg:
	push ebx
	push eax
	mov ah, 1
	jmp .sigcountcommon_twc

.numrs:
	mov ecx, [ps_presig_count+8]
	add ecx, [ps_presig_count+8+4]
	jmp .sigcountcommon_twcr
.numros:
	mov ecx, [ps_presig_count+8]
	jmp .sigcountcommon
.numrts:
	mov ecx, [ps_presig_count+8+4]
	//jmp .sigcountcommon_twcr	//fall through

.sigcountcommon_twcr:
	push ebx
	push eax
	movzx eax, al
.sigcountcommon_twc:
	extern checkistwoway
	call checkistwoway
	jnz .sigcount_not_tw
	test BYTE [landscape2+edi], dl	//nz if signal green, ah=1 if checking for green signals
	setz al
	xor al, ah
	movzx eax, al
	sub ecx, eax
.sigcount_not_tw:
	pop eax
	pop ebx
.sigcountcommon:
	mov edx, [ebx+robj.word1]
	jmp .gotvar
	
.tileside:

	mov cl, [landscape5(di)]
	and ecx, BYTE 0x3F
	bsf ecx,ecx
	mov cl, [l5bitindextotype+ecx]
	movzx edx, BYTE [sigbit]

	bsf edx,edx
	movzx ecx, BYTE [typesigbitindextoentertileside+edx-4+ecx*4]

	movzx edx, BYTE [ebx+robj.word1]
	jmp .gotvar

.pbssigentertl:
	mov ecx, [tr_pbs_sigblentertile]
	movzx edx, WORD [ebx+robj.word1]
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

//0=X,1=Y,2=H,3=V
var l5bitindextotype, db 0,1,2,2,3,3
//0=NE,1=SE,2=SW,3=NW
var typesigbitindextoentertileside, db -1,-1,0,2,	-1,-1,1,3,	1,2,0,3,	0,1,3,2

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

btndata vartxt, 200
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
btndata switch, 75
btndata finder, 30
btndata sizer, 12
%assign winwidth btn_sizer_end+1

//<,>,<=,>=,==,!=,&&,||,^^

varb tracerestrictwindowelements
	// Close button 0
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5

	// Title Bar 1
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, winwidth-1, 0, 13
	.title: dw ourtext(tr_restricttitle)
	
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

	// Switch button 20
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(switch), winheight-13, winheight-1
	.switchbtn: dw ourtext(tr_ps_gui_text)
	
	// Finder button 21
	db cWinElemTextBox, cColorSchemeGrey
	dw btnwidths(finder), winheight-13, winheight-1
	dw ourtext(tr_findbtn)

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
	times 2 db 12
endvar

varw pre_op_array
dw statictext(empty)
op_array:
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

// four words between ourtext(tr_sigval_is_g) and first statictext(empty)
// if robj.type==0
// op_array3-8 + robj.type*2 --> first statictext(empty)

op_array2:
dw ourtext(trdlg_eq)
dw ourtext(trdlg_neq)
dw 0xffff

op_array3:
dw ourtext(tr_sigval_is_g)
dw ourtext(tr_sigval_is_r)
dw 0xffff

op_array4:
dw ourtext(tr_sigval_is_green)
dw ourtext(tr_sigval_is_red)
dw 0xffff
endvar

%assign var_array_num 27
%assign var_end_mark 26
varw pre_var_array
dw ourtext(tr_vartxt)
var_array:
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
dw ourtext(tr_days_since_last_service)
dw ourtext(tr_searching_for_depot)
dw ourtext(tr_ps_sigcount_g)
dw ourtext(tr_ps_sigcount_go)
dw ourtext(tr_ps_sigcount_gt)
dw ourtext(tr_ps_sigcount_r)
dw ourtext(tr_ps_sigcount_ro)
dw ourtext(tr_ps_sigcount_rt)
dw ourtext(tr_entertileside)
dw ourtext(tr_pbssigblentertl)
dw 0xffff
endvar

varw pre_var_array2
dw ourtext(tr_vartxt)
var_array2:
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
dw ourtext(tr_days_since_last_service)
dw statictext(tr_searchingfordepotdropdown)
dw ourtext(tr_ps_sigcount_g)
dw ourtext(tr_ps_sigcount_go)
dw ourtext(tr_ps_sigcount_gt)
dw ourtext(tr_ps_sigcount_r)
dw ourtext(tr_ps_sigcount_ro)
dw ourtext(tr_ps_sigcount_rt)
dw ourtext(tr_entertileside)
dw ourtext(tr_pbssigblentertl)
dw 0xffff
endvar

//1: 2op (is and is not only), 2: station, 4: depot, 8: uword, 16: udword, 32: sig, 64: cargo, 128=no var, 256=ne,se,sw,nw (0-3),  512=sig (-G/R)
varw var_flags
dw 8
dw 8
dw 3
dw 5
dw 16
dw 16
dw 33
dw 33
dw 33
dw 33
dw 8
dw 3
dw 3
dw 65
dw 8
dw 5
dw 8
dw 129
dw 16
dw 16
dw 16
dw 16
dw 16
dw 16
dw 257
dw 513
endvar

varw pre_var_compat_id
db -1
var_compat_id:
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
db 10
db 11
db 12
db 12
db 12
db 12
db 12
db 12
db 13
db 14
endvar

%assign j 0

%macro varblank 2        //%1=variable number, %2=j
var_exists_%2_%1 equ 0
%endmacro

%macro varinfo 2        //%1=variable number, %2=j
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
varblank 1,j
%endif
%if j==1 || j==3
varinfo 10,j	//mph
%else
varblank 10,j
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
varinfo 16,j
varinfo 17,j
varinfo 24,j
varinfo 25,j
%assign k 18
%rep 6
varblank k, j
%assign k k+1
%endrep
tr_mklists j
%endrep

%assign currentflagnum 0
%assign k 0
%rep 6
varblank k, 4
%assign k k+1
%endrep
%assign k 10
%rep 18-10
varblank k, 4
%assign k k+1
%endrep
varblank 25,4
varinfo 18, 4
varinfo 19, 4
varinfo 20, 4
varinfo 21, 4
varinfo 22, 4
varinfo 23, 4
varinfo 24, 4
varinfo 6, 4
varinfo 7, 4
varinfo 8, 4
varinfo 9, 4
tr_mklists 4

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

uvarw currobjrelhorizpos,1
uvarw robjidindex,1
uvarw robjid,1
uvard rootobj,1
uvarw curselrobjid,1
uvard curselrobj,1

uvard screenclickxy, 1

uvard curdispmode	//0=restriction,1=ps

global tracerestrict_createwindow
tracerestrict_createwindow:
	pushad
	mov esi, [esp+4]
	mov BYTE [curdispmode], 0
	mov WORD [tracerestrictwindowelements.switchbtn], ourtext(tr_ps_gui_text)
	mov WORD [tracerestrictwindowelements.title], ourtext(tr_restricttitle)

	movzx ecx, WORD [esi+window.data+signalguidata.xy]
	mov [curxypos], cx

	mov al, 0x10
	call tr_window_init

	mov cx, cWinTypeTTDPatchWindow
	mov dx, cPatchWindowTraceRestrict
	call dword [BringWindowToForeground]
	jnz NEAR .alreadywindowopen

	mov cx, cWinTypeTTDPatchWindow
	mov dx, -1
	mov eax, (640-winwidth)/2 + (((480-winheight)/2) << 16) // x, y
	mov ebx, winwidth + (winheight << 16) // width , height
	mov ebp, trwin_msghndlr
	call dword [CreateWindow]
	mov byte [esi+window.itemsvisible], numrows
.alreadywindowopen:
	mov dword [esi+window.elemlistptr], tracerestrictwindowelements
	mov DWORD [esi+window.disabledbuttons], 0x1F80
	cmp DWORD [rootobj],0
	je .nodisvar
	or BYTE [esi+window.disabledbuttons], 0x20
	.nodisvar:
	mov word [esi+window.id], cPatchWindowTraceRestrict
	mov byte [esi+window.itemstotal], 0
	mov byte [esi+window.itemsoffset],0
	
	testflags tracerestrict
	jnc .ps_only

	mov WORD [tracerestrictwindowelements.vartb],ourtext(tr_vartxt)
	mov WORD [tracerestrictwindowelements.optb],ourtext(tr_optxt)

	call countrows
	mov edx, [curselrobj]
	call updatebuttons

	popad
ret
.ps_only:
	call trwin_msghndlr.pstrswitch
	popad
ret

tr_window_init:		//al=L3 high bit to test, ecx=coords
			//trashes: eax, ebx, edx
	test BYTE [landscape3+1+ecx*2], al
	jz .noinit

	get_root_robj ecx,eax,ebx,edx
	mov [robjidindex], ax
	get_auto_base_from_root_obj edx,ebx
	mov [rootobj], edx
	mov [robjid], bx
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
	
	cmp dl, cWinEventClose
	jz NEAR .findbtnreset2

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

	cmp cl, 21
	je NEAR .findbtn

	pusha
	call .findbtnreset2
	popa

	cmp cl, 2
	je NEAR .ret

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
	
	cmp cl, 20
	je NEAR .pstrswitch


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
	mov [currobjrelhorizpos], ax
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
	mov ecx, 5
	call GenerateDropDownExPrepare
	jc .tboxret
	call CheckDDL2
	mov eax, [curselrobj]
	or eax, eax
	jz .ddl1_norm
	movzx edx, BYTE [eax+robj.type]
	sub edx, 32
	jb .ddl1_norm
	mov DWORD [DropDownExList], ourtext(tr_andbtn)
	mov DWORD [DropDownExList+4], ourtext(tr_orbtn)
	mov DWORD [DropDownExList+8],  ourtext(tr_xorbtn)
	mov DWORD [DropDownExList+12], -1
	mov BYTE [curvarddboxmode], 1

	jmp .ddl1_nomoddx

.ddl1_norm:
	push ecx
	mov BYTE [curvarddboxmode], 0
	mov eax, [curddlvarptr]
	mov ecx, var_array_num
	.ddl1_loop:
		movzx ebx,BYTE [eax+ecx-1]
		movzx ebx, WORD [var_array2+ebx*2]
		cmp bx, -1
		jne .nosx
		movsx ebx, bx
		.nosx:
		mov [DropDownExList-4+ecx*4],ebx
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
	jmp GenerateDropDownEx

.ddl2:
	call CheckDDL1
	mov eax, [curselrobj]
	or eax, eax
	jz .ret
	movzx dx, byte [eax+robj.type]
	dec dx
	//mov eax, [curoparray]
	movzx ebx, BYTE [eax+robj.varid]
	mov bl, [var_flags-2+ebx*2]
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
	call TransmitRoutingRestrictionLineChangeCurRobj
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

.ddl1_action_norm_init:
	pusha
	xor bh, bh
	call TransmitRoutingRestrictionChangeRobjCurPos
	popa
	push DWORD trwin_msghndlr.ddl1_action_init_nonmpcont
.ddl1_action_norm_init_mp:
	push eax
	movzx eax, WORD [curxypos]
	mov bl, [curdispmode]
	and bl, 1
	inc bl
	shl bl, 4	//0x10/0x20
	or BYTE [landscape3+1+eax*2], bl
	call refreshtile
	xor bl, 0x30
	test BYTE [landscape3+1+eax*2], bl
	jz NEAR .ddl_action_norm_init_not_ps
	mov ebx, eax
	shr bh,6
	shl bx,2
	movzx edx, BYTE [landscape7+eax]
	mov dh, bh
	mov eax, edx
	movzx edx, WORD [robjidtbl+edx*2]
	lea edx, [robjs+edx*8]
	mov ecx, robjnum-1
	mov ebx, robjs+robj_size
	.sbl_ps:
		test BYTE [ebx+2], 0x80
		jz .sbl_psf
		add ebx, robj_size
	loop .sbl_ps
	jmp NEAR .sbl_fail
.sbl_psf:
	cmp DWORD [esp+4], trwin_msghndlr.ddl1_action_init_nonmpcont
	jne .ddl1_action_init_mp_ps_nosetglobvars
	push ebx
	sub ebx, robjs
	shr ebx, 3
	mov [robjid], bx
	mov [curselrobjid], bx
	pop ebx
	mov [robjidindex], ax
	mov [rootobj], ebx
	mov [curselrobj], ebx
	mov WORD [currobjrelhorizpos], 0
.ddl1_action_init_mp_ps_nosetglobvars:
	push eax
	lea eax, [ebx+robj_size]
	dec ecx
	jz NEAR .sbl_fail
	.sbl_ps2:
		test BYTE [eax+2], 0x80
		jz .sbl_psf2
		add eax, robj_size
	loop .sbl_ps2
	pop eax
	jmp NEAR .sbl_fail
.sbl_psf2:	//edx=ps,ebx=new-switch,eax=new-rs,ecx(popped)=robjidindex
	pop ecx
	cmp DWORD [esp+4], trwin_msghndlr.ddl1_action_init_nonmpcont
	jne .ddl1_action_init_mp_trps_nosetglobvars
	mov [robjidindex], cx
	mov [rootobj], eax
	mov [curselrobj], eax
	sub eax, robjs
	shr eax, 3
	mov [robjid], ax
	mov [curselrobjid], ax
	lea eax, [eax*8+robjs]
.ddl1_action_init_mp_trps_nosetglobvars:
	sub ebx, robjs
	shr ebx, 3
	mov [robjidtbl+ecx*2], bx
	lea ebx, [ebx*8+robjs]
	mov DWORD [ebx], 0x800040
	sub edx, robjs
	shl edx, 16-3
	mov ecx, eax
	sub ecx, robjs
	shr ecx, 3
	mov dx, cx
	cmp BYTE [curdispmode], 1
	jne .dd1imp_notreallyps
	rol edx, 16
.dd1imp_notreallyps:
	mov [ebx+4], edx
	mov ebx, eax	//tr-robj
	mov DWORD [ebx], 0x01800000
	mov DWORD [ebx+4], 0
	or BYTE [robjflags], 1
	pop eax
	ret

.ddl_action_norm_init_not_ps:
	mov ecx, robjnum-1
	mov ebx, robjs+robj_size
	.sbl1:
		test BYTE [ebx+2], 0x80
		jz .sbl1f
		add ebx, robj_size
	loop .sbl1
jmp .sbl_fail

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
.sbl_fail:
	call error
	pop eax
	cmp DWORD [esp], trwin_msghndlr.ddl1_action_init_nonmpcont
	jne .sbl_fail_ret
	add esp, 4
.sbl_fail_ret:
	ret
.sbl2f:
	mov [eax], dx
	sub eax, robjidtbl
	shr eax, 1
	or BYTE [robjflags], 1
	cmp DWORD [esp+4], trwin_msghndlr.ddl1_action_init_nonmpcont
	jne .ddl1_action_init_mp_nosetglobvars
	mov [robjid], dx
	mov [curselrobjid], dx
	mov [robjidindex], ax
	mov [rootobj], ebx
	mov [curselrobj], ebx
	mov WORD [currobjrelhorizpos], 0
.ddl1_action_init_mp_nosetglobvars:
	movzx edx, WORD [curxypos]
	mov [landscape7+edx], al
	pop eax
	ret	//conditional fall through
.ddl1_action_init_nonmpcont:
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
	test BYTE [var_flags-2+ecx*2], 32
	jnz .nosetdefopis
	mov al, 5
.nosetdefopis:
	mov BYTE [ebx+robj.type], al
.noclearvalue:
	movzx edx, BYTE [ebx+robj.varid]
	test BYTE [var_flags+edx*2-2], 128
	jz .notvarless
	or BYTE [ebx+robj.flags], 1
.notvarless:
	mov edx, ebx
	call TransmitRoutingRestrictionLineChangeCurRobj
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
	movzx ecx, WORD [var_flags-2+ecx*2]
	and ecx, BYTE 1
	lea eax, [eax+1+ecx*4]
	mov [ebx+robj.type],al
	mov edx,ebx
	call TransmitRoutingRestrictionLineChangeCurRobj
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
	test BYTE [var_flags-2+ecx*2+1], 1
	jnz .ddl3_action_tileside
	test BYTE [var_flags-2+ecx*2], 64
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
	call TransmitRoutingRestrictionLineChangeCurRobj
	jmp updatebuttons.noddlcheck
.ddl3_action_tileside:
	mov cl, al
	jmp .ddl3_action_cargo_gotit

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
	mov ax,[var_flags+eax*2]

	test al, 0x40
	jnz NEAR .valuebtnddlcargo

	test ah, 1
	jnz NEAR .valuebtnddltileside

	test eax, 0x226
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
	mov cx, 0x1E00+cWinTypeTTDPatchWindow
	mov dx, cPatchWindowTraceRestrict
	mov bp, ourtext(tr_enternumber)
	jmp [CreateTextInputWindow]
.valuebtnret:
ret

.mtool:
	push    esi

	btc     DWORD [esi+window.activebuttons], 8
	jb      .undomtool
	mov     dx, [esi+window.id]
	mov     ax, (cWinTypeTTDPatchWindow<<8)+01h
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
	pusha
	mov edi, eax
	mov bh, 7
	call TransmitRoutingRestrictionPosTypeCurRobj
	popa
	push DWORD .mtcl_qexit
.mtoolclickhndlr_mp:
	mov cl, [landscape4(ax,1)]
	shr cl,4
	movzx edx,BYTE [ebx+robj.varid]
	mov dx, [var_flags-2+edx*2]
	test dl,2
	jz .notstation
	cmp cl,5
	jne .mtoolret

	cmp BYTE [landscape5(ax,1)],7
	ja NEAR .mtcl_fexit
	movzx cx, BYTE [landscape2+eax]
	mov [ebx+robj.word1], cx
	or BYTE [ebx+robj.flags],1
.mtoolret:
	ret

.notstation:
	test dl,4
	jz .notdepot
	cmp cl, 1
	jne .mtoolret
	mov dl, [landscape5(ax,1)]
	and dl, 0xC0
	xor dl, 0xC0
	jnz .mtoolret

.searchdepot:
	mov ecx, 0x100
	mov edx, depotarray
	.depotloop:
		cmp WORD [edx+depot.XY], ax
		je .foundepot
		add edx, byte depot_size
	loop .depotloop
	ret

.foundepot:
	neg ecx
	//add ecx,0x100
	and ecx, 0xff
	mov DWORD [ebx+robj.word1], ecx
	or BYTE [ebx+robj.flags],1
	and BYTE [esi+window.disabledbuttons+1], ~0x10
	ret

.notdepot:
	test edx,32|512
	jz .mtoolret2

	cmp cl, 1
	jne .mtoolret2

	mov dl, [landscape5(ax,1)]
	and dl, 0xC0
	xor dl, 0x40
	jnz .mtoolret2

	mov DWORD [ebx+robj.word1], eax
	or BYTE [ebx+robj.flags],1
	and BYTE [esi+window.disabledbuttons+1], ~0x10
.mtoolret2:
ret

.mtcl_fexit:
	and BYTE [ebx+robj.flags], ~1
	mov DWORD [ebx+robj.word1],0
.mtcl_exit:
	call TransmitRoutingRestrictionLineChangeCurRobj
.mtcl_qexit:
	push esi
	jmp .undomtool

.mtoolclosehndlr:
	and BYTE [esi+window.activebuttons+1], ~1
	jmp .redrawvaluebtnnpopesi

.ddlcargoret1:
	ret

.valuebtnddlcargo:
	mov ecx, 17
	call GenerateDropDownExPrepare
	jc .ddlcargoret1
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
	movzx ebp, WORD [newcargotypenames+ecx*2]
	mov [DropDownExList+eax*4], ebp
	cmp al, dl
	jne .valuebtnddlcargo_nosetcurr
	mov dh, al
	.valuebtnddlcargo_nosetcurr:
	inc eax
	.valuebtnddlcargo_skip:
	inc ecx
	cmp cl, 32
	jb .valuebtnddlcargo_loop
	mov DWORD [DropDownExList+eax*4], -1
	sar dx, 8
	mov ecx, 17
	jmp GenerateDropDownEx

.valuebtnddltileside:
	mov ecx, 17
	call GenerateDropDownExPrepare
	jc .ddlcargoret1
	mov DWORD [DropDownExList], ourtext(ne)
	mov DWORD [DropDownExList+4], ourtext(se)
	mov DWORD [DropDownExList+8], ourtext(sw)
	mov DWORD [DropDownExList+12], ourtext(nw)
	mov DWORD [DropDownExList+16], -1
	mov dl, [ebx+robj.word1]
	mov dh, [ebx+robj.flags]
	and dh, 1
	dec dh
	or dh, dl
	sar dx, 8
	mov ecx, 17
	jmp GenerateDropDownEx

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
	pusha
	mov bh, 3
	call TransmitRoutingRestrictionPosTypeCurRobj
	popa
	push DWORD trwin_msghndlr.delguicont
.delgen:
	mov edx, [curselrobj]
	or edx, edx
	jz NEAR .delrstret
	mov cl, [edx+robj.type]
	cmp cl, 32
	jae .delbtnbop
	mov DWORD [edx], 0x01800000
	mov DWORD [edx+4], 0
ret	//cond jmp .delguicont/ret
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
ret	//cond jmp .delguicont/ret
.blankedx:
	mov DWORD [edx], 0x01800000
	mov [edx+4], eax
ret	//cond ret
.delguicont:
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
	pusha
	mov bh, 1
	call TransmitRoutingRestrictionChangeRobjCurPos
	popa
	push DWORD trwin_msghndlr.rstnormcont
.rstbasic:
	push esi
	movzx esi, WORD [curxypos]
	call delautoobjsignal
	mov eax, esi
	call refreshtile.goteax
	pop esi
	ret
.rstnormcont:
	mov edx, [esi+window.elemlistptr]
	mov WORD [edx+tracerestrictwindowelements.vartb-tracerestrictwindowelements], statictext(empty)
	mov WORD [edx+tracerestrictwindowelements.optb-tracerestrictwindowelements], statictext(empty)
	xor edx,edx
	mov [robjidindex], dx
	mov [robjid], dx
	mov [rootobj], edx
	mov [curselrobjid], dx
	mov [curselrobj], edx
	call countrows
	jmp updatebuttons

.pstrswitch:
	xor BYTE [curdispmode], 1
	mov ecx, [esi+window.elemlistptr]
	xor WORD [ecx+tracerestrictwindowelements.switchbtn-tracerestrictwindowelements], ourtext(tr_ps_gui_text)^ourtext(tr_siggui_text)
	xor WORD [ecx+tracerestrictwindowelements.title-tracerestrictwindowelements], ourtext(tr_restricttitle)^ourtext(tr_ps_wintitle)
	mov al, 0x10
	mov cl, [curdispmode]
	and cl, 1
	shl al, cl
	movzx ecx, WORD [curxypos]
	call tr_window_init
	call countrows
	mov edx, [curselrobj]
	jmp updatebuttons
	
.findbtn:
	btr DWORD [esi+window.activebuttons], 21
	jc .findbtnreset
	mov edx, [curselrobj]
	call getcurtritemxy
	or eax, eax
	js .findbtnfail
	movzx ecx, ah
	movzx eax, al
	shl eax, 4
	shl ecx, 4
	test bl, 1
	jz .noflash
	pusha
	bts DWORD [esi+window.activebuttons], 21
	call [invalidatetile]
	xchg [flashtilex], ax
	xchg [flashtiley], cx
	call [invalidatetile]
	popa
.noflash:
	call [setmainviewxy]
.findbtnfail:
	mov al,[esi+window.type]
	mov bx,[esi+window.id]
	or al, 0x40
	call dword [invalidatehandle]
	ret
.findbtnreset2:
	btr DWORD [esi+window.activebuttons], 21
	jnc .findbtnfail
.findbtnreset:
	or ecx, -1
	xchg [flashtiley], cx
	or eax, -1
	xchg [flashtilex], ax
	call [invalidatetile]
	jmp .findbtnfail

bophandler:
	pusha
	mov bh, 2
	movzx edi, al
	call TransmitRoutingRestrictionPosTypeCurRobj
	popa
	push DWORD bophandler.nmpend
.mp:	//curselrobj must be non-zero
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
ret
.nmpend:
	call countrows
	jmp updatebuttons
.ret:
	add esp, 4
	//this should *never* be reached when calling bophandler.mp
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
	mov bx, [var_flags-2+ebx*2]
	test bl, 0x18
	jz .ret
	mov [eax+robj.word1], edx
	or BYTE [eax+robj.flags], 1
	call TransmitRoutingRestrictionLineChangeCurRobj
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
	call delpobjsignal
	jmp near $
ovar .oldfn, -4, $,tracerestrict_delrobjsignal1

delautoobjsignal:
	cmp BYTE [curdispmode], 1
	jne delrobjsignal

delpobjsignal:
	btr WORD [esi*2+landscape3],13
	jc .cont
	ret
.cont:
	pusha
	bt WORD [esi*2+landscape3],12
	jc NEAR delpobjfromcombsignal
	jmp delrobjsignal.in
delrobjsignal:
	btr WORD [esi*2+landscape3],12
	jnc NEAR .end
	pusha
	bt WORD [esi*2+landscape3],13
	jc NEAR delrobjfromcombsignal
.in:
	mov ebx, esi
	shr bh, 6
	shl bx, 2
	mov bl, [landscape7+esi]
	
	xor eax,eax
	mov [landscape7+esi], al
	xchg WORD [robjidtbl+ebx*2], ax
	lea ebx,[eax*8+robjs]
.del:
	dec BYTE [ebx+robj.count]
	jnz .pret

	//delete relevent restriction object and sub objects
	push DWORD .pret

.recurse:	//ebx=robj
	cmp BYTE [ebx], 32
	jb .norecurse
	cmp BYTE [ebx], 34
	ja .norecurse
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
delrobjfromcombsignal:
	xor edi, edi
	jmp delpobjfromcombsignal.common

delpobjfromcombsignal:
	mov edi, 2
.common:
	get_root_robj esi,eax,ebx,ebx
	cmp BYTE [ebx+robj.type], 64
	jne NEAR delrobjsignal.in
	movzx ecx, WORD [ebx+robj.word1+edi]	//to be deleted
	xor edi, 2
	movzx edi, WORD [ebx+robj.word1+edi]	//to be swapped in
	mov [robjidtbl+eax*2], di
	xor eax, eax
	mov [ebx], eax
	mov [ebx+4], eax
	lea ebx, [robjs+ecx*8]
	jmp NEAR delrobjsignal.del

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
	xor ecx, ecx

	call getcurtritemxy
	or eax, eax
	jns .xygood
.xybad:
	or ecx, 1<<21
.xygood:

	testmultiflags tracerestrict,psignals
	jpe .nodisswitch
	or ecx, 1<<20
.nodisswitch:
	mov DWORD [esi+window.disabledbuttons], ecx
	movzx ecx, BYTE [measuresys]
	cmp BYTE [curdispmode], 1
	jne .tr_chooseddlvars
	//ps
	mov bh, 0xC8
	call TransmitRoutingRestrictionChangeRobjCurPos
	popa
	pusha
	mov DWORD [curddlvarptr], dropdownorder_4
	mov DWORD [currevddlvarptr], revdropdownorder_4
	jmp .ddlvarschosen
.tr_chooseddlvars:
	mov eax, [ddlvarptrlist+ecx*4]
	mov [curddlvarptr], eax
	mov eax, [revddlvarptrlist+ecx*4]
	mov [currevddlvarptr], eax
.ddlvarschosen:
	cmp DWORD [rootobj], 0
	sete al
	mov [curmode], al
	mov ebx, [esi+window.elemlistptr]
	or al, al
	jz .norm
	mov WORD [ebx+tracerestrictwindowelements.delbtn-tracerestrictwindowelements], ourtext(tr_copy)
	mov WORD [ebx+tracerestrictwindowelements.rstbtn-tracerestrictwindowelements], ourtext(tr_share)
	mov WORD [ebx+tracerestrictwindowelements.vartb-tracerestrictwindowelements], ourtext(tr_vartxt)
	mov WORD [ebx+tracerestrictwindowelements.optb-tracerestrictwindowelements], ourtext(tr_optxt)
	or DWORD [esi+window.disabledbuttons], 0x20FC0
	jmp .end
.norm:
	mov WORD [ebx+tracerestrictwindowelements.delbtn-tracerestrictwindowelements], 0x8824
	mov WORD [ebx+tracerestrictwindowelements.rstbtn-tracerestrictwindowelements], ourtext(resetorders)
	or edx, edx
	jnz .noblank
	mov WORD [ebx+tracerestrictwindowelements.vartb-tracerestrictwindowelements], ourtext(tr_vartxt)
	mov WORD [ebx+tracerestrictwindowelements.optb-tracerestrictwindowelements], ourtext(tr_optxt)
	or DWORD [esi+window.disabledbuttons], 0x21FF0
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
	or [esi+window.disabledbuttons], ecx
	movzx ax, BYTE [edx+robj.type]
	add ax, ourtext(tr_andbtn)-32
	mov ebx, [esi+window.elemlistptr]
	mov WORD [ebx+tracerestrictwindowelements.vartb-tracerestrictwindowelements], ax
	mov WORD [ebx+tracerestrictwindowelements.optb-tracerestrictwindowelements], ourtext(tr_optxt)
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
	test BYTE [var_flags-2+eax*2], 32
	jz .nsigop
	mov ebx, op_array3-8
.nsigop:
	test WORD [var_flags-2+eax*2], 0x140
	jnz .nddl3
	or ecx, 0x20000
.nddl3:
	test BYTE [var_flags-2+eax*2], 128
	jz .nvar
	or ecx, 0x20100
.nvar:
	mov ax,[var_array2-2+eax*2]
	push ebx
	mov ebx, [esi+window.elemlistptr]
	mov WORD [ebx+tracerestrictwindowelements.vartb-tracerestrictwindowelements],ax
	xchg ebx, [esp]

	movzx eax, BYTE [edx+robj.type]
	or eax, eax
	mov ax,[ebx-2+eax*2]
	jnz .noop
	or ecx, 0x20100
	mov ax,ourtext(tr_optxt)
.noop:
	pop ebx
	mov WORD [ebx+tracerestrictwindowelements.optb-tracerestrictwindowelements],ax
	or [esi+window.disabledbuttons], ecx

.end:
	movzx ebx, WORD [curxypos]
	mov bl, [landscape1+ebx]
	cmp bl, [human1]
	je .nopreventmodotherplayer
	//prevent naughty players from changing other companies' restrictions...
	or DWORD [esi+window.disabledbuttons], 0x23FF0
.nopreventmodotherplayer:
	mov al,[esi+window.type]
	mov bx,[esi+window.id]
	or al, 0x40
	call dword [invalidatehandle]
	popa
ret

//in: edx=robj (or none)
//out: eax=xy or -1, ebx=flags: 1=highlight tile
//trashed=none
getcurtritemxy:
	or edx, edx
	jz .curxy
	test BYTE [edx+robj.flags], 1
	jz .fail
	cmp BYTE [edx+robj.type], 32
	jae .fail
	movzx ebx, BYTE [edx+robj.varid]
	xor eax, eax
	bts eax, ebx
	test eax, (1<<3)+(1<<12)+(1<<13)
	jnz .st
	test eax, (1<<4)+(1<<16)
	jnz .dep
	test eax, (0xF<<7)+(1<<26)
	jnz .sig
.fail:
	or eax, -1
	ret
.curxy:
	movzx eax, WORD [curxypos]
	mov ebx, 1
	ret
.st:
	movzx eax, BYTE [edx+robj.word1]
	imul eax, eax, station_size
	add eax, [stationarrayptr]
	movzx eax, WORD [eax+station.XY]
	xor ebx, ebx
ret
.dep:
	movzx eax, BYTE [edx+robj.word1]
	add eax, eax
	lea eax, [eax+eax*2+depotarray]
	movzx eax, WORD [eax+depot.XY]
	mov ebx, 1
ret
.sig:
	movzx eax, WORD [edx+robj.word1]
	mov ebx, 1
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
	mov ecx, ourtext(tr_end)+(statictext(empty)<<16)
	cmp BYTE [curdispmode], 1
	jne .nosetpsend
	xor ecx, ourtext(tr_ps_end)^ourtext(tr_end)
.nosetpsend:
	mov [textrefstack], ecx
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
	movzx edx, WORD [var_flags+ecx*2]
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

	test dword [miscmodsflags],MISCMODS_NODEPOTNUMBERS
	jz .printdepotnum
	mov WORD [textrefstack+6], statictext(trdlg_txt_depot)
	mov cx, [ecx+depot.XY]
	or cx, cx
	jz .clearvalueflag_dontprintstation
	mov bp,cx
	and cx,0xff
	mov WORD [textrefstack+14], cx
	shr bp,8
	mov WORD [textrefstack+16], bp
	jmp .print
.printdepotnum:
	mov WORD [textrefstack+6], statictext(dpt_number)
	movzx ecx, BYTE [eax+robj.word1]
	inc ecx
	mov WORD [textrefstack+14], cx
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
	test edx, 32|512
	jz NEAR .nosignal
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	cmp ecx, 5
	jb NEAR .blank4
	mov bp, [op_array4-10+ecx*2]
	test edx, 512
	jz .not_noGR
	mov bp, [op_array2-10+ecx*2]
.not_noGR:
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
	test edx, 128
	jz .nonovar
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array-2+ecx*2]
	mov WORD [textrefstack+4], bp
	jmp .blank6
.nonovar:
	test edx, 256
	jz .notileside
	mov WORD [textrefstack], statictext(trdlg_txt_3)
	mov bp, [var_array+ecx*2]
	mov WORD [textrefstack+2], bp
	movzx ecx, BYTE [eax+robj.type]
	mov bp, [op_array-2+ecx*2]
	mov WORD [textrefstack+4], bp
	test BYTE [eax+robj.flags],1
	jz NEAR .blank6
	movzx ecx, BYTE [eax+robj.word1]
	add ecx, ourtext(ne)
	mov WORD [textrefstack+6], cx
	jmp .blank8
.notileside:


	//none
	mov DWORD [textrefstack], statictext(empty)+(statictext(empty)<<16)
.blank4:
	mov WORD [textrefstack+4], statictext(empty)
.blank6:
	mov WORD [textrefstack+6], statictext(empty)
.blank8:
	mov WORD [textrefstack+8], statictext(empty)
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
	mov     ax, (cWinTypeTTDPatchWindow<<8)+01h
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

uvarb copyshareactionmp,1
//0=norm,1=mp
//with mp: robjidindex, robjid, rootobj, curselrobj are modified anyway

//eax=coords of source
copysharelist:
	pusha
	push esi
	cmp BYTE [copyshareactionmp], 0
	jne .nomt
	push eax
	xor ebx,ebx
	xor eax,eax
	xor edx,edx
	call [setmousetool]
	pop eax
.nomt:

	mov [tr_copylist_emergency_stack_pointer], esp
	
	cmp BYTE [copyshareaction], 0
	je NEAR .ret
	
	mov cl, [landscape4(ax,1)]
	shr cl, 4
	cmp cl, 1
	jne NEAR .ret
	mov ch, 0x10
	mov cl, [curdispmode]
	shl ch, cl
	test BYTE [landscape3+1+eax*2], ch
	jz NEAR .ret
	mov cl, [landscape5(ax,1)]
	shr cl, 6
	xor cl, 1
	jnz NEAR .ret
	
	get_root_robj eax,ecx,ebx,edx
	get_auto_base_from_root_obj edx, ebx
	or ebx, ebx
	jz NEAR .ret

	cmp BYTE [copyshareaction], 2
	jne .nodenyshareothercompcheck
	mov al, [landscape1+eax]
	cmp al, [human1]
	jne NEAR .ret		//user tried to share with opponent's restricted signal, deny it, to prevent them from sharing the two signals and thus being able to modify the opponent's restrictions
.nodenyshareothercompcheck:

//ebx=src robjid,ecx=src robjidindex,edx=src robj

	movzx eax, WORD [curxypos]
	//note eax now is target tile coords
	mov ch, 0x20
	mov cl, [curdispmode]
	shr ch, cl
	test BYTE [landscape3+1+eax*2], ch
	jz .normscpinit
	get_root_robj eax,ecx,edx,edi
	mov edi, robjs
	call .getnextfree
	mov DWORD [edi], 0x800040
	mov ebp, edi
	shr ebp, 3
	sub ebp, robjs
	mov [robjidtbl+ecx*2], bp
	mov ebp, [curdispmode]
	xor ebp, 1
	mov [edi+robj.word1+ebp*2], dx
	xor ebp, 1
	lea edx, [edi+robj.word1+ebp*2]
	jmp .scpinitover
.normscpinit:

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
.scpinitover:	//eax=dst coords, cx=dst robjidindex,edx=where to store dst<--src rt robjid,ebx=src root obj id
	mov [robjidindex], cx
	mov DWORD [curselrobj], 0

	cmp BYTE [copyshareaction], 1
	mov BYTE [copyshareaction], 0
	je .copy

.share:
	mov BYTE [landscape7+eax], cl
	mov ch, 0x10
	mov cl, [curdispmode]
	shl ch, cl
	or BYTE [landscape3+1+eax*2], ch
	call refreshtile
	mov [edx], bx
	mov [robjid], bx
	shl ebx, 3
	add ebx, robjs
	mov [rootobj], ebx
	inc BYTE [ebx+robj.count]
	jnz NEAR .ret
	//error too many shared
	not ch
	and BYTE [landscape3+1+eax*2], ch
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
	mov ch, 0x10
	mov cl, [curdispmode]
	shl ch, cl
	or BYTE [landscape3+1+eax*2], ch
	call refreshtile
.ret:
	pop esi
	cmp BYTE [copyshareactionmp], 0
	jne .noguiaction
	and BYTE [esi+window.activebuttons+1], ~3
	mov edx, [curselrobj]
	call updatebuttons
.noguiaction:
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

//ax,cx: coords, bl=constr flags (1), bh=type
//type=0:	create initial restriction
//type=1:	reset signal
//type=2:	insert bop, edx=pos, edi=0,1,2=and,or,xor
//type=3:	delete, edx=pos
//type=4:	change line, ebx-high=pos, edx=dword1, edi=dword2 (ignored for bops)
//type=5:	share, edi=coords of tile to share with
//type=6:	copy, edi=coords of tile to share with
//type=7:	mouse tool value click, station/depot, edi=tile, edx=pos
//type=8:	refresh signal state
//type|=0x40:	always do
//type|=0x80:	programmable signal action
//"pos" means number of a restriction object, as would be seen in the GUI window, zero-based
exported MPRoutingRestrictionChange
	btr ebx, 14
	jc .alwaysdo
	mov bl, [curplayer]
	cmp bl, [human1]
	je .qend
.alwaysdo:
	push WORD [curxypos]
	push DWORD [curdispmode]
	movzx esi, cx
	shl esi, 8
	or si, ax
	shr esi, 4
	mov [curxypos], si
	btr ebx, 15
	setc [curdispmode]
	or bh, bh
	jz .type0
	dec bh
	jz .type1
	dec bh
	jz .type2
	dec bh
	jz .type3
	dec bh
	jz .type4
	dec bh
	jz NEAR .type5
	dec bh
	jz NEAR .type6
	dec bh
	jz NEAR .type7
	dec bh
	jz NEAR .type8
	ud2	//error! bad type
.end:
	pop DWORD [curdispmode]
	pop WORD [curxypos]
.qend:
	xor ebx, ebx
	ret
.type0:
	push DWORD MPRoutingRestrictionChange.end
	jmp trwin_msghndlr.ddl1_action_norm_init_mp
.type1:
	push DWORD MPRoutingRestrictionChange.end
	jmp trwin_msghndlr.rstbasic
.type2:
	call GetMPRoutingRestrictionMPRobjFromPos
	mov ax, di
	push DWORD [curselrobj]
	mov [curselrobj], edx
	call bophandler.mp
	pop DWORD [curselrobj]
	jmp .end
.type3:
	push DWORD MPRoutingRestrictionChange.end
	jmp trwin_msghndlr.delgen
.type4:
	push edx
	mov edx, ebx
	shr edx, 16
	call GetMPRoutingRestrictionMPRobjFromPos
	pop ebx
	mov [edx], ebx
	cmp bl, 32
	jae .end	//don't set the second dword for bops
	mov [edx+4], edi
	jmp .end
.type5:
	mov al, 1
	jmp .type_copyshare
.type6:
	mov al, 2
.type_copyshare:
	xchg [copyshareaction], al
	//copied from below function's comments: //with mp: robjidindex, robjid, rootobj, curselrobj are modified anyway
	mov bx, [robjidindex]
	shl ebx, 16
	mov bx, [robjid]
	mov ecx, [rootobj]
	mov edx, [curselrobj]
	pusha
	mov eax, edi
	call copysharelist
	popa
	mov [robjid], bx
	shr ebx, 16
	mov [robjidindex], bx
	mov [rootobj], ecx
	mov [curselrobj], edx
	mov [copyshareaction], al
	jmp .end
.type7:
	call GetMPRoutingRestrictionMPRobjFromPos
	mov ebx, edx
	mov eax, edi
	call trwin_msghndlr.mtoolclickhndlr_mp
	jmp .end
.type8:
	mov cl, [landscape5(si)]
	and ecx, BYTE 0x3F
	mov dl, [landscape3+esi*2]
	mov edi, esi
.type8loop:
	bsf eax, ecx
	jz NEAR .end
	btr ecx, eax
	test dl, [trackpiecesignalmask+eax]
	jz .type8loop
	pusha
	mov ebx, 3
	mov ebp, [ophandler+1*8]	//edi=coord, ax=track piece bit number
	call [ebp+0x4]			//_CS:001463D1 UpdateSignalBlocks
	popa
	jmp .type8loop

var trackpiecesignalmask, db 0xC0,0xC0,0xC0,0x30,0xC0,0x30

//In: edx=pos
//trashes: eax, edx
//Out: edx=robj ptr
GetMPRoutingRestrictionMPRobjFromPos:
	push edx
	movzx edx, WORD [curxypos]
	sget_root_robj edx, edx, al
	get_auto_base_from_root_obj edx,edx
	pop eax
	inc ax
	call trwin_msghndlr.tboxrobjrecurse
	or ax, ax
	jz .ok
	ud2	//message contained bad robj position/tile coords
.ok:
ret

TransmitRoutingRestrictionLineChangeCurRobj:
	pusha
	call TransmitRoutingRestrictionLineChangeCurRobj2
	popa
ret

//trashes: ax, cx, esi, bl, edx, ebp
TransmitRoutingRestrictionPosTypeCurRobj:
	movzx edx, WORD [currobjrelhorizpos]
	jmp TransmitRoutingRestrictionChangeRobjCurPos

//trashes: ax, cx, esi, ebx, edx, edi, ebp
TransmitRoutingRestrictionLineChangeCurRobj2:
	mov bx, [currobjrelhorizpos]
	shl ebx, 16
	mov bh, 4
	mov edi, [curselrobj]
	mov edx, [edi]
	mov edi, [edi+4]
//trashes: ax, cx, esi, bl, edx, ebp
TransmitRoutingRestrictionChangeRobjCurPos:
	movzx ax, BYTE [curxypos]
	movzx cx, BYTE [curxypos+1]
	shl ax, 4
	shl cx, 4
//trashes: esi, bl, edx, ebp
TransmitRoutingRestrictionChangeRobj:
	mov bl, [curdispmode]
	shl bl, 7
	or bh, bl	//0x80
	//prevent recursion loops
	mov bl, 1
	dopatchaction MPRoutingRestrictionChange
.ret:
ret
