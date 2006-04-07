#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>
#include <patchproc.inc>

patchprocandor morestats,enhancegui,, patchmorestats

extern acceptcargofn,comp_aimanage,comp_aiview,comp_humanbuild,comp_humanview
extern companystatsptr,malloccrit
extern player1CompanyWHQWindowElemList,player1CompanyWindowElemList
extern otherCompanyWindowElemList,otherCompanyManageWindowElemList

begincodefragments

codefragment newacceptvehiclecargo
	icall acceptvehiclecargo
	setfragmentsize 7

codefragment findcompanyelems,17
#if 0
	// this doesn't work in all versions; different window sizes :/
	db cWinElemTextBox, cColorSchemeGrey
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar, cColorSchemeGrey
	dw 11, 359, 0, 13, 0x7001
#endif
	mov dx,0x68
	mov ebp,1

codefragment oldopencompanywindow,1
	ret
	mov cl, 0x1D

codefragment newopencompanywindow
	icall opencompanywindow
	setfragmentsize 7

codefragment oldcompanywindowclicked,3
	cmp cl, 9
	jz near $+6+0xB9

codefragment newcompanywindowclicked
	icall companywindowclicked

codefragment oldcompanywindowtimer, 6
	jnz near $+6+0x9B
	btr dword [esi+window.activebuttons], 4

codefragment newcompanywindowtimer
	icall companywindowtimer
	setfragmentsize 7


endcodefragments


patchmorestats:
	push dword 8*4*32
	call malloccrit
	pop dword [companystatsptr]
	
	mov edi, [acceptcargofn]
	add edi, 3
	storefragment newacceptvehiclecargo

	stringaddress findcompanyelems,1,2
	mov edi,[edi]

#if 0
	testflags subsidiaries
	jc near .subs
	mov dword [variabletofind], edi
	mov dword [variabletowrite], player1CompanyWindowElemList
	multipatchcode findvariableaccess,newvariable,2
	add dword [variabletofind], 8*12+1
	mov dword [variabletowrite], player1CompanyWHQWindowElemList
	multipatchcode findvariableaccess,newvariable,1
	add dword [variabletofind], 8*12+1
	mov dword [variabletowrite], otherCompanyWindowElemList
	multipatchcode findvariableaccess,newvariable,1
.subs:
#endif
        mov edi, otherCompanyManageWindowElemList
        mov esi, [comp_aimanage]
        mov ecx, 10*12 /4
        rep movsd
        
	mov edi, player1CompanyWindowElemList
        mov esi, [comp_humanbuild]
        mov ecx, 8*12 /4
        rep movsd

        mov edi, player1CompanyWHQWindowElemList
        mov esi, [comp_humanview]
        mov ecx, 8*12 /4
        rep movsd

        mov edi, otherCompanyWindowElemList
        mov esi, [comp_aiview]
        mov ecx, 10*12 /4
        rep movsd

	mov dword [comp_humanview], player1CompanyWHQWindowElemList
	mov dword [comp_humanbuild], player1CompanyWindowElemList
	mov dword [comp_aiview], otherCompanyWindowElemList
	mov dword [comp_aimanage], otherCompanyManageWindowElemList
	
	patchcode opencompanywindow
	patchcode companywindowclicked
	patchcode companywindowtimer
	ret
