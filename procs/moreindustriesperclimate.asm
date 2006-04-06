#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc moreindustriesperclimate, patchmoreindustriesperclimate


extern CreateNewRandomIndustry,defscenariocargo,fundcostmultipliers
extern fundguitoindustrytablearctic,fundguitoindustrytabletemperate
extern fundguitoindustrytabletoyland,fundguitoindustrytabletropic
extern fundindustrytooltips_arctic,fundindustrytooltips_temperate
extern fundindustrytooltips_toyland,fundindustrytooltips_tropic
extern industryquerryacceptlist1,industryquerryacceptlist2
extern industryquerryacceptlist3,newfundindustrygui_arctic
extern newfundindustrygui_temperate,newfundindustrygui_toyland
extern newfundindustrygui_tropic

#include <window.inc>
#include <industry.inc>

patchmoreindustriesperclimate:
	patchcode oldcreatenewindustry, newcreatenewindustry,1,1
	
	stringaddress findfundguitoindustrytableptrs,1,1
	mov ebx, [edi]
	mov dword [ebx], fundguitoindustrytabletemperate
       mov dword [ebx+4], fundguitoindustrytablearctic
       mov dword [ebx+8], fundguitoindustrytabletropic
       mov dword [ebx+12], fundguitoindustrytabletoyland
	
	stringaddress findoldindustryguielements,1,1
	mov dword [locindustryguielements], edi

	//patchcode oldindustryguielementstemperate, newindustryguielementstemperate,1,1
	stringaddress oldindustryguielementstemperate,1,1
       mov dword [edi+3], newfundindustrygui_temperate
       mov dword [edi-18], 009C0154h

       // arctic
       sub edi, 31
       mov dword [edi+3], newfundindustrygui_arctic
       mov dword [edi-18], 009C0154h

	// desert
       sub edi, 31
       mov dword [edi+3], newfundindustrygui_tropic
       mov dword [edi-18], 009C0154h

       // toyland
       sub edi, 31
       mov dword [edi+3], newfundindustrygui_toyland
       mov dword [edi-18], 009C0154h

	//Find accept lists in memory
	stringaddress oldindustryquerryacceptlist1,1,1
	mov eax, [edi]
	mov dword [industryquerryacceptlist1],eax

	stringaddress oldindustryquerryacceptlist3,1,1
	mov eax, [edi]
	mov dword [industryquerryacceptlist3],eax

	stringaddress oldindustryquerryacceptlist2,1,1
	mov eax, [edi]
	mov dword [industryquerryacceptlist2],eax

	bts dword [defscenariocargo],27
	// bts dword [scenariocargo+4],28	// for new arctic cargo when defined

       storeaddress findCreateNewRandomIndustry,1,1,CreateNewRandomIndustry
       storeaddress findFundCostMultipliers,1,1,fundcostmultipliers
       patchcode oldFundNewIndustryWindowHandler, newFundNewIndustryWindowHandler,1,1
       patchcode oldDrawFundNewIndustryWindow, newDrawFundNewIndustryWindow, 1, 1

       // patch tooltips
       stringaddress findfundnewindustrytooltip,2,2
       mov dword [edi+4], fundindustrytooltips_toyland
       add edi, 13
       mov dword [edi+4], fundindustrytooltips_tropic
       add edi, 13
       mov dword [edi+4], fundindustrytooltips_arctic
       add edi, 13
       mov dword [edi+4], fundindustrytooltips_temperate

	ret



begincodefragments

codefragment oldcreatenewindustry
	xchg ax, bx
 	mov [esi+industry.type], al
 	movzx eax, al

codefragment newcreatenewindustry
	call runindex(createnewindustryclimate)
	jc $+0x36

codefragment findfundguitoindustrytableptrs, -4
 	mov dl, [ebx+ebp]
 	mov bl, 1

codefragment findoldindustryguielements, 7
	db 0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x03

codefragment oldindustryguielementstemperate
	mov dword [esi+24h], 0xFFFFFFFF
locindustryguielements equ $-4

// Doesn't work will create:
//  C7 86 24 00 00 00 B4 10 61 00
// it should look like this:
//  C7 46 24 B4 10 61 00
// nasm bug? Anyway, now it's done by code in patches
//codefragment newindustryguielementstemperate
//	mov dword [esi+24h], addr(newfundindustrygui)


codefragment oldindustryquerryacceptlist1, -8
 	inc ah
	cmp al, 0

reusecodefragment oldindustryquerryacceptlist3,oldindustryquerryacceptlist1,12
reusecodefragment oldindustryquerryacceptlist2,oldindustryquerryacceptlist1,26

glob_frag findCreateNewRandomIndustry
codefragment findCreateNewRandomIndustry,12
       shr eax, 10h
       and eax, 1Fh
       db 0x8A, 0x98

codefragment findFundCostMultipliers
       db 0xFF, 0xF0, 0xE0, 0xFF, 0xF4, 0xFF, 0xD0, 0xD0
       db 0xD7, 0xFF, 0xFF, 0xFF, 0xFF, 0xCE, 0xE3, 0xFF

codefragment oldFundNewIndustryWindowHandler,-33
       push ecx
       push esi
       mov ebx, 4081
       mov ax, 0x4001
       xor dx, dx

codefragment newFundNewIndustryWindowHandler
       call runindex(fundnewindustrywindowhandler)
       setfragmentsize 19

codefragment oldDrawFundNewIndustryWindow,-18
       mov cx, [esi + window.x]
       mov dx, [esi + window.y]
       add cx, 85
       add dx, [esi + window.height]
       sub dx, 21
       db 0x0F

codefragment newDrawFundNewIndustryWindow
       call runindex(drawFundNewIndustryWindow)
       cmp dword [esi+window.activebuttons], 0
       jnz .label
       ret
.label:
       setfragmentsize 18

codefragment findfundnewindustrytooltip,12
       or al, al
       db 0x74, 0x2F
       cmp al, 1
       db 0x74, 0x1E
       cmp al, 2
       db 0x74, 0x0D


endcodefragments
