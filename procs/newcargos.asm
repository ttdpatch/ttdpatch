#include <defs.inc>
#include <frag_mac.inc>
#include <grf.inc>
#include <window.inc>
#include <station.inc>
#include <misc.inc>
#include <patchproc.inc>

patchproc newcargos, patchnewcargos

extern newcargoamountnnames,newcargodelaypenaltythresholds1
extern newcargodelaypenaltythresholds2,newcargounitnames
extern newcargounitweights



extern DrawGraph,cargoamount1namesptr,cargoamountnnamesptr
extern cargotypenamesptr,cargounitnamesptr,cargounitweightsptr
extern gettextandtableptrs,malloccrit,newcargoamount1names
extern newcargoicons,newcargopricefactors,newcargoshortnames
extern newcargotypenames,pdaTempStationPtrsInCatchArea
extern stationarray2ofst,stationcargowaitingmask
extern stationcargowaitingnotmask,variabletofind,variabletowrite

begincodefragments

codefragment oldinitcargoprices
	mov dword [edi+4], 0
	add esi, 4

codefragment newinitcargoprices
	icall initcargoprices
	setfragmentsize 7

codefragment oldreadcargoprices
	imul eax,dword [cargopricefactors+ebx*8]

codefragment newreadcargoprices
	imul eax,dword [newcargopricefactors+ebx*8]

codefragment oldinflatecargoprices,9
	mov esi, cargopricefactors
	mov cx, 12

codefragment newinflatecargoprices
	icall inflatecargoprices
	setfragmentsize 27, 1

codefragment oldcargopaymentrateswinelemlist,36
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, 567, 0, 13, 0x7061

codefragment newcargopaymentrateswinelemlist
	db cWinElemTiledBox, cColorSchemeOrange
	dw 493, 555, 24, 119
	db 1, 12
	db cWinElemSlider, cColorSchemeGrey
	dw 556, 566, 24, 119, 0
	db cWinElemLast

codefragment oldinitpaymentwindow
	mov word [esi+window.data],1
	ret

codefragment newinitpaymentwindow
	ijmp initpaymentwindow

codefragment oldpaymentwindow_listclick
	sub cl,3
	btc word [esi+window.data], cx

codefragment newpaymentwindow_listclick
	icall paymentwindow_listclick
	setfragmentsize 8

codefragment olddrawpaymentwindow
	movzx eax, word [esi+window.data]
	shl eax,3

codefragment newdrawpaymentwindow
	ijmp drawpaymentwindow

codefragment oldpaymentwindoweventhandler,-5
	cmp dl,1
	jz near $+6-0x1e7

codefragment newpaymentwindoweventhandler
	icall paymentwindoweventhandler
	setfragmentsize 8

codefragment findDrawGraph,-5
	push ebp
	mov ax,[ebp+graphdata.X]

codefragment oldaddcargotostation
	shr ax,8
	mov cx, [ebx+esi+station.cargos+stationcargo.amount]
	and cx, 0FFFh

codefragment newaddcargotostation
	jmp runindex(addcargotostation_2)

codefragment olddistribcargo_foundstation
	test word [ebp+station.flags],0x40
	jnz $+2+-72

codefragment newdistribcargo_foundstation
	icall distribcargo_foundstation

codefragment olddistribcargo_1station
	mov al,ah
	mul byte [ebx+esi+station.cargos+stationcargo.rating]

codefragment newdistribcargo_1station
	icall distribcargo_1station

codefragment olddistribcargo_2stations,5
	db 0x01, 0x00, 0x00
	xor ebp, ebp
	db 0x8B, 0x3D

codefragment newdistribcargo_2stations
	icall distribcargo_2stations
	jmp fragmentstart+134

codefragment oldmovbxcargoicons
	mov bx, [nosplit newcargoicons+ebx*2]

codefragment newmovbxcargoicons
	call runindex(movbxcargoicons)
	setfragmentsize 8

codefragment oldmovbxcargoamountnames,10
	and ax, 0FFFh
	mov word [textrefstack+2], ax
	mov bx, [nosplit newcargoamount1names+ebx*2]
	dec ax
	jz .lbl
	add bx, 20h
.lbl:
	mov word [textrefstack], bx

codefragment newmovbxcargoamountnames
	call runindex(movbxcargoamountnames)
	setfragmentsize 16

codefragment oldmovaxcargotypenames, 3
	movzx eax, ax
	mov ax, [nosplit newcargotypenames+eax*2]

codefragment newmovaxcargotypenames
	call runindex(movaxcargotypenames)
	setfragmentsize 8

codefragment oldmovbxcargoamountname2
	mov bx, [nosplit newcargoamount1names+ebx*2]
	dec ax
	jz .singular
	add bx, 20h
.singular:

codefragment newmovbxcargoamountname2
	icall movbxcargoamountname2
	setfragmentsize 16,1

codefragment oldmovbxcargoshortnames
	mov bx, [nosplit newcargoshortnames+ebp*2]

codefragment newmovbxcargoshortnames
	call runindex(movbxcargoshortnames)
	setfragmentsize 8

codefragment oldgetcargocolor,8
	add ax,7
	shr ax,3

codefragment newgetcargocolor
	icall getcargocolor
	setfragmentsize 8

codefragment oldmovaxcargoamountnames
	mov ax, [nosplit newcargoamount1names+eax*2]
	cmp bx, 1
	jz .lbl
	add ax, 20h
.lbl:

codefragment newmovaxcargoamountnames
	call runindex(movaxcargoamountnames)
	setfragmentsize 18

codefragment findupdatestationacceptlist1
	sub esp, 18h
	mov ebp, esp
	push esi

codefragment findupdatestationacceptlist2 
	db 0x72, 0xAD
	add esp, 18h

codefragment newupdatestationacceptlist
	call runindex(updatestationacceptlist)
	jmp newupdatestationacceptlist_start+27+36

codefragment olddisplayconstacceptlist,14
	cmp word [ebp],8

codefragment newdisplayconstacceptlist
	icall displayconstacceptlist

codefragment oldinsrvorder
	mov ah,4
	cmp byte [esi+veh.cargotype],0

codefragment newinsrvorder
	icall insrvorder

codefragment oldcheckrvtype1
	cmp byte [esi+veh.cargotype],0
	jnz $+2+4

codefragment newcheckrvtype1
	icall checkrvtype1

codefragment oldcheckrvtype2
	cmp byte [esi+veh.cargotype],0
	jz $+2+4

codefragment newcheckrvtype2
	icall checkrvtype2

codefragment oldcheckrvstation
	cmp byte [esi+veh.cargotype],0
	jz $+2+0x27

codefragment newcheckrvstation
	icall checkrvstation

codefragment oldcheckdistcargo
	test byte [ebp+station.facilities], ~4

codefragment newcheckdistcargo
	icall checkdistcargo
	jz newcheckdistcargo_start+26
	jmp newcheckdistcargo_start+39

codefragment oldsetupstationstruct_2
	mov byte [esi+station.exclusive],0

codefragment newsetupstationstruct_2
	icall setupstation2
	setfragmentsize 7

codefragment oldsetupoilfield
	mov byte [esi+station.facilities],0x18

codefragment newsetupoilfield
	icall setupoilfield
	setfragmentsize 7

codefragment oldgetacceptbitmask
	xor ebx,ebx
	mov ecx,1

codefragment newgetacceptbitmask
	mov eax,esi
	add eax,[stationarray2ofst]
	mov eax,[eax+station2.acceptedcargos]
	ret

codefragment oldcollectacceptedcargos,3
	add ebp,3
	xor bx,bx

codefragment newcollectacceptedcargos
	icall collectacceptedcargos
	jmp short fragmentstart+50

codefragment oldgenacceptmessages,2
	cmp ebx,12
	jb $+2-0x40

codefragment newgenacceptmessages
	db 32

codefragment olddrawplannedaccepts1
	sub esp, 2*12
	mov ebp, esp
	push ax
	push dx
	mov eax, 12-1

codefragment newdrawplannedaccepts1
	sub esp, 2*32
	mov ebp, esp
	push ax
	push dx
	mov eax, 32-1

codefragment olddrawplannedaccepts2
	cmp bx, 12
	jb $+2-0x4b

codefragment newdrawplannedaccepts2
	cmp bx, 32

codefragment olddrawplannedaccepts3,14
	mov bp,144

codefragment newdrawplannedaccepts3
	add esp, 2*32

codefragment oldgetcargounitnames
	pop ebx
	or eax, eax
	js .typenames
	add ax,0x20
.typenames:

codefragment newgetcargounitnames
	or eax,eax
	icall getcargounitnames
	pop ebx

codefragment oldinitcargodata, 3
	loop fragmentstart-6,cx
	movzx esi,byte [climate]

codefragment newinitcargodata
	icall initcargodata
	setfragmentsize 7

codefragment oldaitestcargotypes1
	sub esp,4*12
	mov ebp,esp
	push cx
	mov eax,12-1

codefragment newaitestcargotypes1
	add esp,byte -(4*32)		// -80h can be coded as a single byte, +80 can't
	mov ebp,esp
	push cx
	mov eax,32-1

codefragment oldaitestcargotypes2
	add esp, 4*12
	pop di
	ret

codefragment newaitestcargotypes2
	sub esp,byte -(4*32)

codefragment oldstationwindow_linenum,5
	test word [ebx+station.cargos+edi+stationcargo.amount],0x0fff

codefragment newcargowaitingmask
	dw 0xffff

codefragment oldtestemptyslot_esi,4
	test word [esi+station.cargos+stationcargo.amount],0x0fff

codefragment oldgetcargowaiting_esi,6
	mov ax, [esi+station.cargos+stationcargo.amount]
	and ax, 0x0fff

codefragment oldgetcargowaiting_ebxesi,8
	mov di, [ebx+station.cargos+esi+stationcargo.amount]
	and di, 0x0fff

codefragment oldmodifycargowaiting_ebxesi,5
	and word [ebx+station.cargos+esi+stationcargo.amount], 0xf000
	or [ebx+station.cargos+esi+stationcargo.amount], di

codefragment newcargowaiting_notmask
	dw 0

codefragment oldgetcargowaiting_esiebp,7
	mov ax, [esi+station.cargos+ebp*8+stationcargo.amount]
	and ax, 0x0fff

codefragment oldclearcargowaiting,5
	and word [edx+station.cargos+ebx+stationcargo.amount],0xf000


endcodefragments


ext_frag newvariable,findvariableaccess

patchnewcargos:
// cargotypenames
	mov dword[variabletofind], cargotypenames
	mov dword [variabletowrite], newcargotypenames
	multipatchcode findvariableaccess,newvariable,17
// cargounitnames
	mov dword[variabletofind], cargounitnames
	mov dword [variabletowrite], newcargounitnames
	multipatchcode findvariableaccess,newvariable,1 // this one is only written, and never read???
// cargoamount1names
	mov dword[variabletofind], cargoamount1names
	mov dword [variabletowrite], newcargoamount1names
	multipatchcode findvariableaccess,newvariable,9
// cargoamountnnames
	mov dword[variabletofind], cargoamountnnames
	mov dword [variabletowrite], newcargoamountnnames
	multipatchcode findvariableaccess,newvariable,15
// cargoshortnames
	mov dword[variabletofind], cargoshortnames
	mov dword [variabletowrite], newcargoshortnames
	multipatchcode findvariableaccess,newvariable,2
// cargoicons
	mov dword[variabletofind], cargoicons
	mov dword [variabletowrite], newcargoicons
	multipatchcode findvariableaccess,newvariable,2
// cargounitweights
	mov dword[variabletofind], cargounitweights
	mov dword [variabletowrite], newcargounitweights
	multipatchcode findvariableaccess,newvariable,3
// cargodelaypenaltytresholds1
	mov dword[variabletofind], cargodelaypenaltythresholds1
	mov dword [variabletowrite], newcargodelaypenaltythresholds1
	multipatchcode findvariableaccess,newvariable,2
// cargodelaypenaltytresholds2
	mov dword[variabletofind], cargodelaypenaltythresholds2
	mov dword [variabletowrite], newcargodelaypenaltythresholds2
	multipatchcode findvariableaccess,newvariable,2
// cargopricefactors
//	mov dword[variabletofind], cargopricefactors
//	mov dword [variabletowrite], newcargopricefactors
//	multipatchcode findvariableaccess,newvariable,4

	patchcode initcargoprices
	multipatchcode oldreadcargoprices,newreadcargoprices,2
	patchcode inflatecargoprices

	mov dword [cargotypenamesptr],newcargotypenames
	mov dword [cargounitnamesptr],newcargounitnames
	mov dword [cargoamount1namesptr],newcargoamount1names
	mov dword [cargoamountnnamesptr],newcargoamountnnames
	mov dword [cargounitweightsptr],newcargounitweights

//patch the payment rate graph window

	patchcode cargopaymentrateswinelemlist
	patchcode initpaymentwindow
	patchcode paymentwindow_listclick
	patchcode drawpaymentwindow
	patchcode paymentwindoweventhandler
	storeaddress findDrawGraph,1,4,DrawGraph

	patchcode oldaddcargotostation,newaddcargotostation,1,1

	patchcode distribcargo_foundstation
	patchcode distribcargo_1station
	stringaddress olddistribcargo_2stations,1,1
	mov ebx, [edi+2]
	mov [pdaTempStationPtrsInCatchArea], ebx
//	mov ebx, [edi+12]
//	mov [pbaTempStationIdxsInCatchArea], ebx
	storefragment newdistribcargo_2stations

//patch the station window handler
	patchcode oldmovbxcargoicons,newmovbxcargoicons,1,1
	multipatchcode oldmovbxcargoamountnames,newmovbxcargoamountnames,2
	patchcode oldmovaxcargotypenames,newmovaxcargotypenames,1,1

//patch the vehicle window handlers
	multipatchcode oldmovbxcargoamountname2,newmovbxcargoamountname2,4

//patch the station list window handler
	patchcode oldmovbxcargoshortnames,newmovbxcargoshortnames,1,1
	patchcode getcargocolor

//patch the industry window handler
	multipatchcode oldmovaxcargoamountnames,newmovaxcargoamountnames,2

//patch the UpdateStationAcceptList function
	stringaddress findupdatestationacceptlist1,1,1
	mov byte [edi+2], (12+20)*2	// change the number of bytes reserved on stack
	mov dword [edi+7], 11+20	// change the number of words initialized to 0
	stringaddress findupdatestationacceptlist2,1,1
	mov byte [edi+4], (12+20)*2	// change the number of bytes freed on stack
	sub edi, 27+36
	storefragment newupdatestationacceptlist

	// patch cargo class 0 for bus stations
	patchcode displayconstacceptlist
	mov byte [edi+lastediadj+22],0	// disarm the jz

	patchcode insrvorder
	patchcode oldcheckrvtype1,newcheckrvtype1,2,3
	patchcode oldcheckrvtype2,newcheckrvtype2,1,2
	patchcode oldcheckrvtype2,newcheckrvtype2,1,0
	patchcode checkrvstation
	patchcode checkdistcargo

	patchcode setupstationstruct_2
	patchcode setupoilfield

	patchcode getacceptbitmask
	patchcode collectacceptedcargos
	patchcode genacceptmessages

	patchcode drawplannedaccepts1
	patchcode drawplannedaccepts2
	patchcode drawplannedaccepts3

	mov ax,0x300c
	call gettextandtableptrs

	mov [variabletofind], edi

	push dword 170
	call malloccrit
	pop dword [variabletowrite]

	multipatchcode findvariableaccess,newvariable,3
	add dword [variabletofind],3
	add dword [variabletowrite],3
	multipatchcode findvariableaccess,newvariable,2

	multipatchcode oldgetcargounitnames,newgetcargounitnames,2

	patchcode initcargodata

//	call copyorgcargodata

// patch some AI functions
	multipatchcode oldaitestcargotypes1,newaitestcargotypes1,4
	multipatchcode oldaitestcargotypes2,newaitestcargotypes2,4

// use all 16 bits of stationcargo.amout instead of just 10
	patchcode oldstationwindow_linenum,newcargowaitingmask,1,1
	multipatchcode oldtestemptyslot_esi,newcargowaitingmask,2
	multipatchcode oldgetcargowaiting_esi,newcargowaitingmask,3
	patchcode oldgetcargowaiting_ebxesi,newcargowaitingmask,1,1
	multipatchcode oldmodifycargowaiting_ebxesi,newcargowaiting_notmask,2
	patchcode oldgetcargowaiting_esiebp,newcargowaitingmask,1,1
	patchcode oldclearcargowaiting,newcargowaiting_notmask,1,1

	mov dword [stationcargowaitingmask],0x7fff
	and dword [stationcargowaitingnotmask],0x8000
	ret

// Enable adding new house types
