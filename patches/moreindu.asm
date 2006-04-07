#if 0
// More industries & cargo support for climates
//

#include <std.inc>
#include <textdef.inc>
#include <window.inc>
#include <industry.inc>
#include <misc.inc>

extern CreateNewRandomIndustry,actionhandler,errorpopup
extern fundcostmultipliers,fundprospecting_actionnum,generatesoundeffect
extern randomfn,realindustryowner





//uvard paClimatesCargoIconsAndWeights,1,s
//uvard paClimatesCargoNamesTable,1,s

uvard industryquerryacceptlist1,1,s
uvard industryquerryacceptlist2,1,s
uvard industryquerryacceptlist3,1,s

#if 0

//This will fix savegames, new games to support paper.
//It changes the industry accept table(s) on the fly too.
global addnewtemperatecargo
addnewtemperatecargo:
	cmp byte [climate],0
	jnz .nottemperate

	mov word [cargoicons+11*2], 4313
	mov byte [cargounitweights+11], 16

	mov word [cargotypenames+11*2],1Fh
	mov word [cargounitnames+11*2],3Fh
	mov word [cargoamount1names+11*2],5Fh
	mov word [cargoamountnnames+11*2],7Fh
	mov word [cargoshortnames+11*2],9Fh

	// cargopricefactors doesn't need to be changed currently

	// now fix industryquerryacceptlist table for temperate
	push eax
	mov eax, [industryquerryacceptlist2]
	mov dword [eax+0x2B], 0x0B0B0B0B 	//makes "printing works" accept paper in temperate
	pop eax
	ret

.nottemperate:
	// now fix industryquerryacceptlist table for other climates
	push eax
	mov eax, [industryquerryacceptlist2]
	mov dword [eax+0x2B], 0x09090909	//makes "printing works" reaccept the old cargo
	pop eax
	ret
;endp addnewtemperatecargo


global createnewindustryclimate
createnewindustryclimate:
	xchg ax, bx
	mov [esi+industry.type], al
	movzx eax, al
	cmp byte [climate],0
	jz .temperate
	clc
	ret

.temperate:
	cmp al, 07h //Printing works
 	jnz .noprintworks
	mov word [esi+industry.producedcargos], 0xFF05	
	mov dword [esi+industry.accepts], 0xFFFFFF0B
	mov word [esi+industry.prodrates],0x0000
	stc
	ret
.noprintworks:
	cmp al, 0Eh //Paper mill
 	jnz .nopapermill
	mov word [esi+industry.producedcargos], 0xFF0B
	mov dword [esi+industry.accepts], 0xFFFFFF07
 	mov word [esi+industry.prodrates],0x0000
	stc
	ret
.nopapermill:
	clc
	ret
;endp createnewindustryclimate


global fundnewindustrywindowhandler
fundnewindustrywindowhandler:
	// do the things we've overwritten
	push eax
	push esi
	mov esi, 0
	mov eax, 13h
	call [generatesoundeffect]
	pop esi
	pop eax

	// is this button a primary industry?
	push ebx
	movzx ebx, byte [climate]
	shl ebx,1
	add ebx, firstprimaryindustry
	cmp cx, [ebx]
	jnb .newfunction
	
	pop ebx
	jmp .oldfunction
.newfunction:
	movzx ebx, byte [climate]
	shl ebx,1
	add ebx, lastprimaryindustry
	cmp cx, [ebx]
	jna .isbutton
	
	pop ebx
	jmp .nobutton
.isbutton:

	pop ebx
	bt [esi + window.disabledbuttons], cx
	jnb .enabled
	jmp .nobutton
.enabled:
	sub cx, 3
	movzx ecx, cx

	mov bl, 1
	dopatchaction fundprospecting
.nobutton:
	pop esi
.oldfunction:
	ret
#endif

global fundprospecting_newindu
fundprospecting_newindu:
	xchg bl,dl
	movzx ebx,bl
	jmp short fundprospecting.hasindustry

global fundprospecting
fundprospecting:
	mov dl, bl
	movzx ebx, byte [climate]
	shl ebx, 2
	add ebx, fundguitoindustry_index
	mov ebx, [ebx]
	movzx ebx, byte [ebx + ecx]
	
.hasindustry:
	mov word [operrormsg1], ourtext(cannotfundprospecting)
	mov byte [currentexpensetype],expenses_other

	// calculate the cost for this industry
	mov ebp,[fundingcost]
	sar ebp, 8
	mov eax, [fundcostmultipliers]
	add eax, ebx
	movzx eax, byte [eax]
	imul ebp, eax
	push ebx
	mov ebx, ebp

	test dl, 1
	jz near .onlytesting

	// calculate if research will fail
	pop ebx
	push ebx
	push eax
	push edx

	movzx edi, word [numberofindustries]
	movzx cx, byte [edi + minnumberofindustriesallowed]
	
	call getnumindustries

	mov eax, [fundchances + 4*ebx]
	
	cmp dx, cx
	jbe .simplechance

	sub dx, cx
	movzx ecx, dx

	mov ebx, eax
.chanceloop:
	mul ebx
	xchg eax,edx
	loop .chanceloop

.simplechance:

	mov ecx, eax
	call [randomfn]
	cmp ecx, eax

	jbe .fundfailed

	pop eax
	pop edx
	pop ebx

	// create the industry
	// this modifies curplayer, so save that
	mov al,[curplayer]
	mov [realindustryowner],al
	call [CreateNewRandomIndustry]
	cmp al, -1
	mov al,10h
	xchg al,[realindustryowner]
	mov [curplayer],al
	mov byte [currentexpensetype],expenses_other
	je .nosuitableplace

	// skip original function
	ret

.fundfailed:
	pop eax
	pop edx
	pop ebx

.nosuitableplace:
	push ebx
	mov bx, ourtext(fundingfailed)
	mov dx, -1
	xor ax, ax
	xor cx, cx
	call [errorpopup]
	pop ebx

	ret

.onlytesting:
	pop ebp
	ret
;endp fundnewindustrywindowhandler

// check if we need to disable oil-rigs/oil-wells
global drawFundNewIndustryWindow
drawFundNewIndustryWindow:
	push eax
	mov al,[climate]
	cmp al,1
	jb .temperate
	je .arctic
	cmp al,2
	je .tropic
	pop eax
	ret
.tropic:
	mov eax, 0x0008000A
	jmp short .checkoil
.arctic:
	mov eax, 0x000A000C
	jmp short .checkoil
.temperate:
	mov eax, 0x000C000F

.checkoil:
	mov word [esi + window.disabledbuttons], 0
	cmp word [currentdate], (30 * 1461)/4 + 1
	jna .hasoilwell
	bts word [esi + window.disabledbuttons], ax
.hasoilwell:
	shr eax, 16
	cmp word [currentdate], (40 * 1461)/4
	jnb .hasoilrig
	bts word [esi + window.disabledbuttons], ax
.hasoilrig:

	pop eax
	ret
;endp drawFundNewIndustryWindow

// count the number of industries allready on the map
// in:  bl = type of industry to build
// out: ax = total number of industries
//      dx = number of industries of this type
getnumindustries:
	xor ax, ax
	xor dx, dx
	push esi
	push ecx
	mov esi, [industryarrayptr]
	mov ecx, 90
.countloop:
	cmp word [esi], 0
	je .empty
	cmp [esi + industry.type], bl
	jne .wrongtype
	inc dx
.wrongtype:
	inc ax
.empty:
	add esi, 0x36
	dec ecx
	jnz .countloop

	pop ecx
	pop esi

	ret
;endp getnumindustries


var newfundindustrygui_temperate
	db cWinElemTextBox,cColorSchemeDarkGreen
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar,cColorSchemeDarkGreen
	dw 11, 339, 0, 13, 0x0314
	db cWinElemSpriteBox, cColorSchemeDarkGreen
	dw 0, 339, 14, 155, 0

	// secondary industries
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 29, 40, 0x0241
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 42, 53, 0x0242
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 55, 66, 0x0244
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 68, 79, 0x0246
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 81, 92, 0x0247
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 94, 105, 0x024E
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 107, 118, 0x024C
	
	// primary industries
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 29, 40, 0x0240
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 42, 53, 0x0243
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 55, 66, 0x0245
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 68, 79, 0x0248
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 81, 92, 0x0249
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 94, 105, 0x024A
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 107, 118, 0x024B

	db cWinElemText, 0
	dw 4, 167, 16, 27, ourtext(buildindustry)
	db cWinElemText, 0
	dw 171, 334, 16, 27, ourtext(fundprospecting)

	db cWinElemLast

var newfundindustrygui_arctic
	db cWinElemTextBox,cColorSchemeDarkGreen
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar,cColorSchemeDarkGreen
	dw 11, 339, 0, 13, 0x0314
	db cWinElemSpriteBox, cColorSchemeDarkGreen
	dw 0, 339, 14, 155, 0

	// secondary industries
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 29, 40, 0x0241
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 42, 53, 0x024C
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 55, 66, 0x0244
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 68, 79, 0x024D
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 81, 92, 0x024E
	
	// primary industries
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 29, 40, 0x0240
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 42, 53, 0x0243
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 55, 66, 0x0245
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 68, 79, 0x0248
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 81, 92, 0x024A
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 94, 105, 0x024F
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 107, 118, 0x024B

	db cWinElemText, 0
	dw 4, 167, 16, 27, ourtext(buildindustry)
	db cWinElemText, 0
	dw 171, 334, 16, 27, ourtext(fundprospecting)

	db cWinElemLast
	
var newfundindustrygui_tropic
	db cWinElemTextBox,cColorSchemeDarkGreen
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar,cColorSchemeDarkGreen
	dw 11, 339, 0, 13, 0x0314
	db cWinElemSpriteBox, cColorSchemeDarkGreen
	dw 0, 339, 14, 155, 0

	// secondary industries
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 29, 40, 0x0250
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 42, 53, 0x024D
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 55, 66, 0x0244
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 68, 79, 0x0246
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 81, 92, 0x0254
	
	// primary industries
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 29, 40, 0x0245
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 42, 53, 0x0248
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 55, 66, 0x024A
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 68, 79, 0x0251
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 81, 92, 0x0252
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 94, 105, 0x0253
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 107, 118, 0x0255
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 120, 131, 0x0256
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 133, 144, 0x024B

	db cWinElemText, 0
	dw 4, 167, 16, 27, ourtext(buildindustry)
	db cWinElemText, 0
	dw 171, 334, 16, 27, ourtext(fundprospecting)

	db cWinElemLast

var newfundindustrygui_toyland
	db cWinElemTextBox,cColorSchemeDarkGreen
	dw 0, 10, 0, 13, 0x00C5
	db cWinElemTitleBar,cColorSchemeDarkGreen
	dw 11, 339, 0, 13, 0x0314
	db cWinElemSpriteBox, cColorSchemeDarkGreen
	dw 0, 339, 14, 155, 0

	// secondary industries
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 29, 40, 0x0258
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 42, 53, 0x025B
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 55, 66, 0x025C
	db cWinElemTextBox, cColorSchemeGrey
	dw 4, 167, 68, 79, 0x025E
	
	// primary industries
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 29, 40, 0x0257
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 42, 53, 0x0259
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 55, 66, 0x025A
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 68, 79, 0x025D
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 81, 92, 0x025F
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 94, 105, 0x0260
	db cWinElemTextBox, cColorSchemeBrown
	dw 171, 334, 107, 118, 0x0261

	db cWinElemText, 0
	dw 4, 167, 16, 27, ourtext(buildindustry)
	db cWinElemText, 0
	dw 171, 334, 16, 27, ourtext(fundprospecting)

	db cWinElemLast


var fundguitoindustrytabletemperate
	db 01h, 02h, 04h, 06h, 08h, 07h, 0Eh
	db 00h, 03h, 05h, 09h, 12h, 0Bh, 0Ch

var fundguitoindustrytablearctic
	db 01h, 0Eh, 04h, 0Dh, 07h
	db 00h, 03h, 05h, 09h, 0Bh, 0Fh, 10h

var fundguitoindustrytabletropic
	db 19h, 0Dh, 04h, 17h, 16h
	db 05h, 18h, 0Bh, 13h, 14h, 15h, 11h, 0Ah, 10h

var fundguitoindustrytabletoyland
	db 1Bh, 1Eh, 1Fh, 21h
	db 1Ah, 1Ch, 1Dh, 20h, 22h, 23h, 24h

var fundguitoindustry_index
	dd fundguitoindustrytabletemperate
	dd fundguitoindustrytablearctic
	dd fundguitoindustrytabletropic
	dd fundguitoindustrytabletoyland

var fundindustrytooltips_temperate
	dw 0x018B, 0x018C, 0
	dw 0x0263, 0x0264, 0x0266, 0x0268, 0x0269, 0x0270, 0x026E
	dw 0x0262, 0x0265, 0x0267, 0x026A, 0x026B, 0x026C, 0x26D, 0, 0

var fundindustrytooltips_arctic
	dw 0x018B, 0x018C, 0
	dw 0x0263, 0x026E, 0x0266, 0x026F, 0x0270
	dw 0x0262, 0x0265, 0x0267, 0x026A, 0x026C, 0x0271, 0x0272, 0, 0

var fundindustrytooltips_tropic
	dw 0x018B, 0x018C, 0
	dw 0x0273, 0x026F, 0x0266, 0x0268, 0x0277
	dw 0x0267, 0x026A, 0x026C, 0x0274, 0x0275, 0x0276, 0x0278, 0x0279, 0x0272, 0, 0

var fundindustrytooltips_toyland
	dw 0x018B, 0x018C, 0
	dw 0x027B, 0x027E, 0x027F, 0x0281
	dw 0x027A, 0x027C, 0x027D, 0x0280, 0x0282, 0x0283, 0x0284, 0, 0

var firstprimaryindustry
	dw 0x000A, 0x0008, 0x0008, 0x0007

var lastprimaryindustry
	dw 0x0010, 0x000E, 0x0010, 0x000D

var fundchances // chance * 0xffffffff
	dd 0xB3333333 			// 70% coal
	dd 0xFFFFFFFF, 0xFFFFFFFF
	dd 0xBFFFFFFF			// 75% forest
	dd 0xFFFFFFFF
	dd 0x99999999			// 60% oil rig
	dd 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF
	dd 0xD9999999			// 85% farm temp/arctic
	dd 0xB3333333			// 70% copper ore
	dd 0x99999999			// 60% oil wells
	dd 0xA6666666			// 65% bank temp
	dd 0xFFFFFFFF, 0xFFFFFFFF
	dd 0x99999999			// 60% gold
	dd 0xA6666666			// 65% bank trop/arc
	dd 0x99999999			// 60% diamond
	dd 0xB3333333			// 70% iron ore
	dd 0xBFFFFFFF			// 75% fruit
	dd 0xBFFFFFFF			// 75% rubber
	dd 0xB3333333			// 70% water
	dd 0xFFFFFFFF, 0xFFFFFFFF 
	dd 0xD9999999			// 85% farm trop
	dd 0xFFFFFFFF
	dd 0xBFFFFFFF			// 75% candyfloss forest
	dd 0xFFFFFFFF
	dd 0xB3333333			// 70% batery
	dd 0x99999999			// 60% cola
	dd 0xFFFFFFFF, 0xFFFFFFFF
	dd 0xA6666666			// 65% plastic
	dd 0xFFFFFFFF
	dd 0xB3333333			// 70% bubbles
	dd 0xCCCCCCCC			// 80% toffee
	dd 0xBFFFFFFF			// 75% sugar

// if the numer of industries is below this number, the chance will be used, 
//     else chance^(n-m) where m is this number will be used
var minnumberofindustriesallowed
	db 1, 3, 5
#endif
