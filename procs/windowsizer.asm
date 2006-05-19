#include <defs.inc>
#include <frag_mac.inc>


extern aircraftdepotwindowsizes,airvehoffset,calloccrit
extern depotwindowconstraints,malloccrit,mapwindowconstraints
extern mapwindowelementsptr,mapwindowsizes,newgraphicssetsenabled
extern railvehoffset,roadvehoffset,rvdepotwindowsizes,shipdepotwindowsizes
extern shipvehoffset,temp_windowclicked_element,traindepotwindowsizes
extern variabletofind,variabletowrite,vehlistwinsizesptr,windowsizesbufferptr
extern winelemdrawptrs,drawresizebox,DrawWinElemCheckBox

#include <window.inc>

ext_frag findvariableaccess,newvariable

global patchwindowsizer

begincodefragments

codefragment finddrawwindowelementslist,7
	movzx ebx, byte [ebp+windowbox.type]
	db 0xff // jmp ...

codefragment oldwindowclicked, 5
	db 0xEB, 0xAA
	mov cx, di
	
codefragment newwindowclicked
	icall windowclicked

codefragment oldprocwindowdragmode
	test word [esi+window.flags], 8

codefragment newprocwindowdragmode
	icall procwindowdragmode

codefragment oldclosewindow
	mov cl, [esi+window.type]
	mov dx, [esi+window.id]
	push cx
	push dx
	push esi

codefragment newclosewindow
	icall CloseWindow

codefragment olddrawwindowelements
	mov ebp, [esi+window.elemlistptr]
	db 0xbf	// mov edi,

codefragment newdrawwindowelements
	icall drawwindowelements
	setfragmentsize 8

codefragment oldwindowclickedelement
	cmp dl, cWinElemDummyBox
	db 0x74, 0x42

codefragment newwindowclickedelement
	icall windowclickedelement
	setfragmentsize 8

codefragment findmapwindowelements, -12
	db cWinElemTitleBar, cColorSchemeBrown
	dw 11, 233

codefragment oldmapwindowdragmode, -13
	cmp cx, 0xFE0

codefragment newmapwindowdragmode
	setfragmentsize 14*4-1

codefragment oldopenmapwindowpre
	mov ebx, 248 + (212 << 16)

codefragment newopenmapwindowpre
	icall openmapwindowpre
	setfragmentsize 9

codefragment oldopenmapwindowpost
	bts dword [esi+window.activebuttons], 5
	bts dword [esi+window.activebuttons], 11

codefragment newopenmapwindowpost
	icall openmapwindowpost
	setfragmentsize 10

codefragment newopenmapwindowxadjust
	icall openmapwindowxadjust
	setfragmentsize 8

codefragment newopenmapwindowyadjust
	icall openmapwindowyadjust
	setfragmentsize 8

codefragment olddrawmapwindow
//	push esi
//	push bx
//	mov bx, ax
	mov cx, [esi+window.x]
	mov dx, [esi+window.y]
	add dx, [esi+window.height]

codefragment newdrawmapwindow
	icall drawmapwindow
	setfragmentsize 8

codefragment oldlast7vehdrawn
	cmp bl, -7

codefragment newlastrailvehdrawn
	setfragmentsize 3
	icall lastrailvehdrawn

codefragment newlastroadvehdrawn
	setfragmentsize 3
	icall lastroadvehdrawn

codefragment oldlast4vehdrawn
	cmp bl, -4

codefragment newlastshipvehdrawn
	setfragmentsize 3
	icall lastshipvehdrawn

codefragment newlastairvehdrawn
	setfragmentsize 3
	icall lastairvehdrawn

codefragment olddrawtrainlist
	add dx, 6
	mov al, 10

codefragment newdrawtrainlist
	icall drawtrainlist

codefragment oldvehlist7click,2
	div dl,0	// ,0 to disable div-by-zero handling code
	cmp al, 7

codefragment newvehlistclick
	setfragmentsize 8

codefragment oldvehlist4click,2
	div dl,0	// ,0 to disable div-by-zero handling code
	cmp al, 4
	db 0x0f, 0x83	// jnb ...

codefragment findgreywinelemlist,-12
	db cWinElemTitleBar, cColorSchemeGrey
	dw 0xFF, 0xFF
greywinelemx1 equ $-4
greywinelemx2 equ $-2

codefragment oldlastdepotrowdrawn
	cmp bl, -15
negdepotsize equ $-1
	db 0x0f, 0x8c	// jl ...

codefragment newlastdepotrowdrawn
	push eax
	mov al, 0xFF
depotjmpoffset equ $-1
	setfragmentsize 3
	icall lastdepotrowdrawn

codefragment oldlasttraindepotrowdrawn,-4
	cmp bl, -6
	db 0x7c, 0x3f	// jl short ...

codefragment newlasttraindepotrowdrawn
	icall lasttraindepotrowdrawn
	setfragmentsize 7

codefragment olddrawtrainindepot
	add cx, 21
	mov al, 10

codefragment newdrawtrainindepot
	icall drawtrainindepot

codefragment olddrawtrainwagonsindepot
	add cx, 50
	mov al, 9

codefragment newdrawtrainwagonsindepot
	icall drawtrainwagonsindepot
	
codefragment oldtraindepotclick, 2
	div dl,0	// ,0 to disable div-by-zero handling code
	cmp al, 6

codefragment newtraindepotclick
	setfragmentsize 8

codefragment oldtraindepotwindowhandler
	mov bx, cx
	mov esi, edi
	cmp dl, cWinEventRedraw
	db 0x74, 0xF1	// jz ...
	cmp dl, cWinEventClick
	db 0x0F, 0x84, 0xB1	// jz near ...

codefragment newtraindepotwindowhandler
	icall traindepotwindowhandler
	setfragmentsize 8

codefragment oldlastdepotcoldrawn
	add cx, 56
depotcolsize equ $-1
	inc bh

codefragment newlastdepotcoldrawn
	icall lastdepotcoldrawn

codefragment olddepotdrawoffset
	imul bx, 5
depotdrawoffset_sizex equ $-1
	mov cx, [esi+window.x]

codefragment newdepotdrawoffset
	icall depotdrawoffset
	setfragmentsize 8

codefragment olddepotwindowxytoveh_checkx
	cmp al, 5
depotcheckx_size equ $-1
	db 0x73, 0x50	// jnb ...
depotcheckx_jump equ $-1

codefragment newdepotwindowxytoveh_checkx
	icall depotwindowxytoveh.checkx

codefragment olddepotwindowxytoveh_checky
	cmp al, 3
depotchecky_size equ $-1
	db 0x73, 0x3c	// jnb ...
depotchecky_jump equ $-1

codefragment newdepotwindowxytoveh_checky
	icall depotwindowxytoveh.checky

codefragment olddepotwindowxytoveh_calcoffset
	xor ah, ah
	imul ax, 5
depotcalcoffset_sizex equ $-1

codefragment newdepotwindowxytoveh_calcoffset
	icall depotwindowxytoveh.calcoffset

codefragment oldcalcdepottotalitems
	add ax, 4
depottotalsizexdec equ $-1
	mov bl, 5
depottotalsizex equ $-1

codefragment newcalcdepottotalitems
	icall calcdepottotalitems


endcodefragments

patchwindowsizer:
	//first patch the code to make resizing possible at all
	stringaddress finddrawwindowelementslist
	push edi
	mov esi, [edi]
	mov edi, winelemdrawptrs
	mov ecx, 11*4
	rep movsb
	pop edi
	mov dword [edi], winelemdrawptrs
	mov dword [winelemdrawptrs+4*cWinElemSizer], addr(drawresizebox)
	mov dword [winelemdrawptrs+4*cWinElemCheckBox], addr(DrawWinElemCheckBox)
	mov eax, [winelemdrawptrs+4*cWinElemDummyBox]
	mov dword [winelemdrawptrs+4*cWinElemExtraData], eax
	stringaddress oldwindowclicked
	mov eax, [edi+2]
	mov [temp_windowclicked_element], eax
	storefragment newwindowclicked
	patchcode oldprocwindowdragmode,newprocwindowdragmode,1,1
	patchcode oldclosewindow,newclosewindow,1,1
	patchcode olddrawwindowelements,newdrawwindowelements,1,1
	patchcode oldwindowclickedelement,newwindowclickedelement,1,1

	push dword 2*4*4
	call calloccrit
	pop dword [vehlistwinsizesptr]
	push dword 40
	call malloccrit
	pop dword [windowsizesbufferptr]

	or byte [newgraphicssetsenabled],1 << 7

	//than make some windows resizable:
	//first the mini-map
	push dword 13*12+1+4*12
	call malloccrit
	pop dword [mapwindowelementsptr]
	stringaddress findmapwindowelements
	push edi
	mov esi, edi
	mov edi, [mapwindowelementsptr]
	mov ecx, 13*12+1
	rep movsb
	
	mov edi, [mapwindowelementsptr]
	mov word [edi+12*1+4], 247
	mov byte [edi+12*2+0], cWinElemDummyBox
	mov byte [edi+12*17], cWinElemLast
	mov word [edi+12*13+0], cWinElemSizer + (cColorSchemeBrown << 8)
	mov dword [edi+12*13+2], 237 + (247 << 16)
	mov dword [edi+12*13+6], 222 + (233 << 16)
	mov word [edi+12*14+0], cWinElemExtraData + (cWinDataSizer << 8)
	mov dword [edi+12*14+2], mapwindowconstraints
	mov dword [edi+12*14+6], mapwindowsizes
	mov word [edi+12*15+0], cWinElemSpriteBox + (cColorSchemeBrown << 8)
	mov dword [edi+12*15+2], 226 + (247 << 16)
	mov dword [edi+12*15+6], 168 + (189 << 16)
	mov word [edi+12*15+10], 708
	mov word [edi+12*16+0], cWinElemSpriteBox + (cColorSchemeBrown << 8)
	mov dword [edi+12*16+2], 226 + (247 << 16)
	mov dword [edi+12*16+6], 190 + (189 << 16)
	mov word [edi+12*16+10], 0
	mov dword [edi+12*12+6], 190 + (233 << 16)
	mov word [edi+12*3+8], 189
	mov word [edi+12*4+8], 187
	
	mov dword [variabletowrite], edi
	pop edi
	mov [variabletofind], edi
        multipatchcode findvariableaccess,newvariable,4

	patchcode oldmapwindowdragmode,newmapwindowdragmode,1,1
	multipatchcode oldopenmapwindowpre,newopenmapwindowpre,2
	patchcode oldopenmapwindowpost,newopenmapwindowpost,1,1
	add edi,lastediadj+22
	storefragment newopenmapwindowxadjust
	add edi,lastediadj+20
	storefragment newopenmapwindowyadjust
	patchcode olddrawmapwindow,newdrawmapwindow,1,1

	//then the vehicle-lists (most of this code is patched in the sortvehlist patchproc)
	stringaddress oldlast7vehdrawn,1,2
	mov al, [edi+5]
	mov [railvehoffset], al
	storefragment newlastrailvehdrawn
	stringaddress oldlast7vehdrawn,1,1
	mov al, [edi+5]
	mov [roadvehoffset], al
	storefragment newlastroadvehdrawn
	stringaddress oldlast4vehdrawn,3,4
	mov ax, [edi+5]
	mov [shipvehoffset], ax
	storefragment newlastshipvehdrawn
	stringaddress oldlast4vehdrawn,2,3
	mov ax, [edi+5]
	mov [airvehoffset], ax
	storefragment newlastairvehdrawn
	
	patchcode olddrawtrainlist,newdrawtrainlist,1,1

	multipatchcode oldvehlist7click,newvehlistclick,2
	multipatchcode oldvehlist4click,newvehlistclick,2

	//and some depot's
	//RV depot
	mov byte [depottotalsizex], 5
	mov byte [depotcheckx_jump], 0x50
	mov byte [depotchecky_jump], 0x3C
	mov byte [depotchecky_size], 3
	mov byte [depotcolsize], 56
	mov byte [negdepotsize],-15
	mov word [.depotheight], 56
	mov dword [.depotwindowsizes], rvdepotwindowsizes
	mov byte [.depotrownum], 1
	mov byte [.depotrowcount], 1
	call .patchdepotwindow

	//ship depot
	mov byte [depottotalsizex], 3
	mov byte [depotchecky_jump], 0x3E
	mov byte [depotcheckx_jump], 0x52
	mov byte [depotchecky_size], 2
	mov byte [depotcolsize], 90
	mov byte [negdepotsize],-6
	mov word [.depotheight], 62
	mov dword [.depotwindowsizes], shipdepotwindowsizes
	mov byte [.depotrownum], 2
	mov byte [.depotrowcount], 2
	call .patchdepotwindow

	//aircraft hangar
	mov byte [depottotalsizex], 4
	mov byte [depotchecky_jump], 0x44
	mov byte [depotcheckx_jump], 0x58
	mov byte [depotchecky_size], 2
	mov byte [depotcolsize], 74
	mov byte [negdepotsize],-8
	mov word [.depotheight], 62
	mov dword [.depotwindowsizes], aircraftdepotwindowsizes
	mov byte [.depotrownum], 1
	mov byte [.depotrowcount], 3
	call .patchdepotwindow

	//and the train-depot, but this one is a bit more complicated
	mov word [greywinelemx1], 11
	mov word [greywinelemx2], 348
	stringaddress findgreywinelemlist
	push edi
	mov esi, edi
	push dword 7*12+1 + 2*12
	call malloccrit
	pop edi
	push edi
	mov ecx, 7*12+1
	rep movsb
	pop esi
	push edx
	mov bl, 7
	mov ax, 338
	mov cx, 98
	mov edi, depotwindowconstraints
	mov edx, traindepotwindowsizes
	call .addsizer
	pop edx
	sub word [esi+6*12+windowbox.x2], 11
	mov [variabletowrite], esi
	pop edi
	mov [variabletofind], edi
	patchcode findvariableaccess,newvariable,1,1
	mov byte [negdepotsize],-6
	stringaddress oldlastdepotrowdrawn,1,1
	mov al, [edi+5]
	mov [depotjmpoffset], al
	storefragment newlastdepotrowdrawn
	patchcode oldlasttraindepotrowdrawn,newlasttraindepotrowdrawn,1,1
	patchcode olddrawtrainindepot,newdrawtrainindepot,1,1
	patchcode olddrawtrainwagonsindepot,newdrawtrainwagonsindepot,1,1
	patchcode oldtraindepotclick,newtraindepotclick,1,1
	patchcode oldtraindepotwindowhandler,newtraindepotwindowhandler,1,1

	ret

.patchdepotwindow:
	mov al, [depottotalsizex]
	mov byte [depotcheckx_size], al
	mov byte [depotcalcoffset_sizex], al
	mov byte [depotdrawoffset_sizex], al
	dec al
	mov byte [depottotalsizexdec], al
	mov al, [depotcolsize]
	mov ah, [depottotalsizex]
	mul ah
	add ax, 24
	mov [.depotwidth], ax
	add ax, 10
	mov [greywinelemx2], ax
	mov word [greywinelemx1], 11

	push dword 7*12+1 + 2*12
	call malloccrit
	pop edi
	mov [.depotwinelemlist], edi

	stringaddress findgreywinelemlist
	push edi
	mov esi, edi
	mov edi, 0xffffffff
.depotwinelemlist equ $-4
	mov [.depotwinelemlist2], edi
	mov [.depotwinelemlist3], edi
	mov ecx, 7*12+1
	rep movsb

	push edx
	mov bl, 7
	mov esi, 0xffffffff
.depotwinelemlist2 equ $-4
	mov ax, 0xffff
.depotwidth equ $-2
	mov cx, 0xffff
.depotheight equ $-2
	mov edi, depotwindowconstraints
	mov edx, 0xffffffff
.depotwindowsizes equ $-4
	call .addsizer
	pop edx
	sub word [esi+6*12+windowbox.x2], 11
	pop edi
	mov [variabletofind], edi
	mov dword [variabletowrite], 0xffffffff
.depotwinelemlist3 equ $-4
	patchcode findvariableaccess,newvariable,1,1
	patchcode oldlastdepotcoldrawn,newlastdepotcoldrawn,1,1

	mov eax,2
.depotrownum equ $-4
	mov ecx,2
.depotrowcount equ $-4
	stringaddress oldlastdepotrowdrawn,eax,ecx
	mov al, [edi+5]
	mov [depotjmpoffset], al
	storefragment newlastdepotrowdrawn
	patchcode olddepotdrawoffset,newdepotdrawoffset,1,1
	patchcode olddepotwindowxytoveh_checkx,newdepotwindowxytoveh_checkx,1,1
	patchcode olddepotwindowxytoveh_checky,newdepotwindowxytoveh_checky,1,1
	patchcode olddepotwindowxytoveh_calcoffset,newdepotwindowxytoveh_calcoffset,1,1
	patchcode oldcalcdepottotalitems,newcalcdepottotalitems,1,1
	ret
//IN: bl==index of last window element
//    esi==windowelemlistptr
//    ax,cx==x,y of sizer
//    edi==windowconstraints,edx==windowsizes
.addsizer:
	movzx ebx, bl
	shl ebx, 2
	lea ebx, [ebx*3]
	mov byte [esi+ebx+2*12+windowbox.type], cWinElemLast
	mov byte [esi+ebx+0*12+windowbox.type], cWinElemSizer
	mov byte [esi+ebx+0*12+windowbox.bgcolor], cColorSchemeGrey
	mov word [esi+ebx+0*12+windowbox.x1], ax
	add ax, 10
	mov word [esi+ebx+0*12+windowbox.x2], ax
	mov word [esi+ebx+0*12+windowbox.y1], cx
	add cx, 11
	mov word [esi+ebx+0*12+windowbox.y2], cx
	mov byte [esi+ebx+1*12+windowbox.type], cWinElemExtraData
	mov byte [esi+ebx+1*12+1], cWinDataSizer
	mov dword [esi+ebx+1*12+2], edi
	mov dword [esi+ebx+1*12+6], edx
	ret
