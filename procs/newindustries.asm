#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>
#include <ptrvar.inc>

patchproc newindustries, patchnewindustries
patchproc enhanceddiffsettings, patchdifficultysettings

extern CreateNewRandomIndustry,baIndustryTileTransformBack
extern baIndustryTileTransformOnDistr,canindubuiltonwater,caninduonlybigtown
extern caninduonlyneartown,caninduonlytown,checkindustileslope
extern createinitialindustry_nolookup,fundcostmultipliers,getindunamebp
extern getindunamebx,industilespritetable,industry_closedown,industry_primaryprodchange
extern malloccrit,newinduwindowitemlist
extern oldinduwindowitemlist,displayfoundation,correctexactalt.chkslope
extern monthlyupdateindustryproc,monthlyupdateindustryproc.oldfn
extern callback_extrainfo,enddrawindustrywindow,enddrawindustrywindow.oldfn
extern indutilesellouthandler,industry_showchangemsg

#include <industry.inc>
#include <textdef.inc>

begincodefragments

codefragment findCreateNewRandomIndustry,12
       shr eax, 10h
       and eax, 1Fh
       db 0x8A, 0x98

codefragment findDifficultySettingsData
	dw 0, 7, 1, 0
	dw 0, 3, 1, 0x6830
	dw 0, 2, 1, 0x6816
	dw 0, 2, 1, 0x6816

codefragment oldCreateInitialRandomIndustries, -17
	mov cx, [esi+ecx*2]
	push cx
	mov cx, 2000
	push bx
	push cx
	
codefragment newCreateInitialRandomIndustries
	call runindex(createInitialRandomIndustries)
	setfragmentsize 10

codefragment oldgetindustrytilegraphics
	push di
	movzx di,dh
	
codefragment newgetindustrytilegraphics
	icall getindustrytilegraphics
	jmp short fragmentstart+33

codefragment oldindustileconststatechange
	jz $+2+0x42+2*WINTTDX
#if WINTTDX
	mov al,[landscape5(bx)]
#else
	// nasm puts prefixes in wrong order, need to do them manually
	db 0x67,0x65,0x8a,0x7
#endif

codefragment newindustileconststatechange
	icall industileconststatechange
	setfragmentsize 6+2*WINTTDX

codefragment oldclass8periodicproc0
	mov al,[landscape1+ebx]
	test al,0x80

codefragment newclass8periodicproc0
	icall class8periodicproc0

codefragment oldclass8periodicproc1
	jz near $+6+0xa3+6*WINTTDX
#if WINTTDX
	movzx esi,byte [landscape5(bx)]
#else
	db 0x67,0x65,0xf,0xb6,0x37
#endif

codefragment newclass8periodicproc1
	icall class8periodicproc1
	setfragmentsize 11+2*WINTTDX

codefragment oldclass8periodicproc2,-7
	jz $+2+0x30+2*WINTTDX
	db 0x8a,0x86		// mov al,[...

codefragment newclass8periodicproc2
	icall class8periodicproc2
	setfragmentsize 7

codefragment olddistributeindustrycargo1,-8
	sub [edx+industry.amountswaiting],cx

codefragment newdistributeindustrycargo1
	setfragmentsize 8

codefragment olddistributeindustrycargo2,4
	or al,al
	jz $+2+0x37+2*WINTTDX

codefragment newdistributeindustrycargo2
	icall distributeindustrycargo2

codefragment oldclass8animationhandler
#if WINTTDX
	mov dl,[landscape5(bx)]
#else
	db 0x67,0x65,0x8a,0x17
#endif
	cmp dl,0xae

codefragment newclass8animationhandler
	icall class8animationhandler
	setfragmentsize 7+2*WINTTDX

codefragment oldgetlayoutbyte,-11
	movzx esi,byte [ebp+2]
	db 0x8a, 0xbe	// mov bh,[esi+...

codefragment newgetlayoutbyte
	icall getlayoutbyte
	setfragmentsize 21, 1

codefragment oldputindutile,10,14
#if WINTTDX
	and byte [landscape4(di)],0x0f
	or  byte [landscape4(di)],0x80
#else
	// hard code because nasm puts the prefixes in the wrong order
	db 0x67,0x64,0x80,0x25,0x0F
	db 0x67,0x64,0x80,0x0D,0x80
#endif

	mov al,[ebp+2]

codefragment newputindutile
	icall putindutile
	setfragmentsize 7+2*WINTTDX

reusecodefragment findcreateinitialindustry_nolookup,oldCreateInitialRandomIndustries,4

codefragment oldcreateinitialindustries
	movzx cx, byte [esi]
	mov bl,[esi+1]

codefragment newcreateinitialindustries
	icall createinitialindustries
	nop
	nop
	db 0xeb		// jcxz -> jmp short

codefragment oldingamerandomindustry
	shr eax,16
	and eax,31

codefragment newingamerandomindustry
	icall ingamerandomindustry
	setfragmentsize 12

codefragment olddrawmapindustrymode
#if !WINTTDX
	db 0x67,0x65,0x0f,0xb6,0x2f		// movzx ebp, byte [gs:bx]
#else
	ss movzx ebp, byte [landscape5(bx)]
#endif
	db 0x8a,0x95				// mov dl,[ebp+...

codefragment newdrawmapindustrymode
	icall drawmapindustrymode
	setfragmentsize 11+3*WINTTDX

codefragment oldgetindunamebx
	add bx,0x4802

codefragment oldgetindunamebp
	add bp,0x4802

codefragment oldgetindunameaxecx
	movzx ax,[ecx+industry.type]
	add ax,0x4802

codefragment newgetindunameaxecx
	icall getindunameaxecx
	setfragmentsize 9

codefragment oldgetindunameaxedi
	movzx ax,[edi+industry.type]
	add ax,0x4802

codefragment newgetindunameaxedi
	icall getindunameaxedi
	setfragmentsize 9

codefragment oldgetindunameaxesi
	movzx ax,[esi+industry.type]
	add ax,0x4802

codefragment newgetindunameaxesi
	icall getindunameaxesi
	setfragmentsize 9

codefragment oldputfarmfields1
	cmp byte [esi+industry.type],9
	jne $+2+0x5

codefragment newputfarmfields1
	icall putfarmfields1

codefragment oldcutlmilltrees
	cmp byte [esi+industry.type],0x19
	jne $+2+0xd

codefragment newcutlmilltrees
	icall cutlmilltrees
	setfragmentsize 14

codefragment oldinducheckempty
	cmp bl,0x38
	je near $+6+0x25d

codefragment newinducheckempty
	icall inducheckempty
	setfragmentsize 23, 1

codefragment oldcanindubuiltonwater
	cmp byte [esp+6],5

codefragment oldcaninduonlybigtown
	cmp byte [esp+6],0x0c

codefragment oldcaninduonlytown
	cmp byte [esp+6],0x10

codefragment oldcaninduonlyneartown
	cmp byte [esp+6],0x1e

codefragment oldcaninduonlytown2,5
	cmp byte [esp+6],0x16

codefragment newcaninduonlytown2
	db 0xeb		// jnz -> jmp short

codefragment oldputfarmfields2
	cmp byte [esi+industry.type], 0x18
	jz $+2+0x6

codefragment newputfarmfields2
	icall putfarmfields2
	setfragmentsize 10
	db 0x74		// jnz -> jz

codefragment oldinducantincrease
	cmp bl,0x0b
	jnz $+2+0x9

codefragment newinducantincrease
	icall inducantincrease
	setfragmentsize 12

codefragment oldrandominducantcreate
	cmp bl,0x0b
	jnz $+2+0xf

codefragment newrandominducantcreate
	icall randominducantcreate
	jmp short fragmentstart+0x22

codefragment oldaioilrigcheck1
	cmp word [ebx+industry.XY],0
	je $+2+0x20
	cmp byte [ebx+industry.type],5

codefragment newaioilrigcheck
	icall aioilrigcheck
	setfragmentsize 10
	db 0x74			// jnz -> jz

codefragment oldaioilrigcheck2
	cmp word [ebx+industry.XY],0
	je $+2+0x52
	cmp byte [ebx+industry.type],5

codefragment oldgenmilairplane
	cmp word [edi+industry.XY],0
	jz $+2+0x18
	cmp byte [edi+industry.type],4

codefragment newgenmilairplane
	icall genmilairplane
	setfragmentsize 10
	db 0x74			// jnz -> jz

codefragment oldtickprocmilairplane
	cmp byte [edi+industry.type],4
	jnz $+2+0x2d

codefragment newtickprocmilairplane
	icall tickprocmilairplane

codefragment oldgenmilhelicopter
	cmp word [edi+industry.XY],0
	jz $+2+0x18
	cmp byte [edi+industry.type],6

codefragment newgenmilhelicopter
	icall genmilhelicopter
	setfragmentsize 10
	db 0x74			// jnz -> jz

codefragment oldtickprocmilhelicopter
	cmp byte [edi+industry.type],6
	jnz $+2+0x48

codefragment newtickprocmilhelicopter
	icall tickprocmilhelicopter

codefragment oldgencoalminesubs
	cmp word [edi+industry.XY],0
	jz $+2+0xa
	cmp byte [edi+industry.type],0

codefragment newgencoalminesubs
	icall gencoalminesubs
	setfragmentsize 10
	db 0x74			// jnz -> jz

codefragment oldnewindumessage
	cmp byte [esi+industry.type],3
	jnz .notforest
	inc dx
.notforest:

codefragment newnewindumessage
	icall newindumessage
	setfragmentsize 8

codefragment oldcheckinduinput,-6
	cmp ch,[esi+industry.producedcargos]
	je $+2+0x1c

codefragment_call newcheckinduinput, adjustindustrypos, 9

codefragment oldindustryproducecargo
	add [edi+industry.amountswaiting],bx
	jnc .nooverflow
	mov word [edi+industry.amountswaiting],0xffff
.nooverflow:

codefragment newindustryproducecargo
	icall industryproducecargo
	setfragmentsize 12

codefragment oldopenfundindustrywindow
	mov cl,0x40
	xor dx,dx

codefragment newopenfundindustrywindow
	ijmp openfundindustrywindow

codefragment oldopengenerateindustrywindow
	mov cl,0x3b
	xor dx,dx

codefragment newopengenerateindustrywindow
	ijmp openfundindustrywindow

codefragment oldinitnewindustry
	mov dword [esi+0x2e],0
	mov dword [esi+0x32],0
	mov al,[currentyear]

codefragment newinitnewindustry
	icall initnewindustry
	setfragmentsize 14

codefragment oldcreateindustrywindow
	mov dx,0x40
	mov ebp,0

codefragment newcreateindustrywindow
	icall createindustrywindow
	setfragmentsize 21

codefragment olddrawinduacceptlist,-6
	movzx eax,byte [ebp+industry.accepts]
	cmp al,-1

codefragment newdrawinduacceptlist
	icall drawinduacceptlist
	setfragmentsize 12
	db 0xeb			// jz -> jmp short

codefragment oldskipproducelist
	add dx,10
	cmp byte [ebp+industry.producedcargos],-1

codefragment_call newskipproducelist,skipproducelist,8

codefragment oldskipfirstproducedcargo
	add dx,10
	movzx eax,byte [ebp+industry.producedcargos]

codefragment_call newskipfirstproducedcargo,skipfirstproducedcargo,8

codefragment olddrawinduproducelist
	mov [textrefstack],ax
	mov [textrefstack+2],bx

codefragment newdrawinduproducelist
	push edi
	mov byte [callback_extrainfo],3
noglobal ovar cargonum, -1
	icall drawinduproducelist
	setfragmentsize 14

codefragment newfinishinduproducelist
	stosd
	pop edi
	setfragmentsize 5

codefragment oldcreateindustry_chkplacement,-7
	mov ebp,[ebp+4*edx]

codefragment newcreateindustry_chkplacement
	icall createindustry_chkplacement
	jc .endfragment+5
	setfragmentsize 11
.endfragment:

codefragment oldfundindustry_chkplacement
	push edx
	push ebp
	mov ebp,[ebp+(edx-1)*4]

codefragment newfundindustry_chkplacement
	icall fundindustry_chkplacement

codefragment oldfundindustry_overwriteerrmsg,2
	jnz $+2-18
	mov word [operrormsg2],0x0239

codefragment newfundindustry_overwriteerrmsg
	setfragmentsize 9

codefragment oldindustryrandomprodchange,-6
	test al,3
	jnz $+2+0x29

codefragment newindustryrandomprodchange
	icall industryrandomprodchange

codefragment oldindustryprodchange_shownewsmsg
	mov [textrefstack+6],ax
	mov ebp,[esi+industry.townptr]

codefragment_call newindustryprodchange_shownewsmsg, industryprodchange_shownewsmsg, 6

codefragment oldmonthlyupdateindustryproc,11
	mov cl,NUMINDUSTRIES
	cmp word [esi+industry.XY],0
	jz $+2+9
	push cx

codefragment oldcheckindustileslope,-5
	jz $+2+0x26
	push bx
	push dx
	push di

codefragment oldindustryrandomsound,-5
	cmp ax,0x1249

codefragment newindustryrandomsound
	icall industryrandomsound
	setfragmentsize 9

codefragment olddrawindustryfundation,9
	and bx,0x0f
	add bx,989

codefragment newdrawindustryfundation
	mov ebp,edi
	add dl,8
	icall displayfoundation
	setfragmentsize 14

codefragment oldenddrawindustrywindow,7
	pop ebp
	pop esi
	pop dx
	pop cx
	db 0xe9

codefragment oldplantrandomfields,-5
	cmp ax,0x2000
	ja $+2+0x2c

codefragment_call newplantrandomfields, plantrandomfields, 5

codefragment oldFundNewIndustry_saveplayer
	mov bh, [curplayer]
	push ax

codefragment_call newFundNewIndustry_saveplayer, FundNewIndustry_saveplayer

codefragment oldFundNewIndustry_restoreplayer,2
	pop ax
	mov [curplayer],bh

codefragment_call newFundNewIndustry_restoreplayer, FundNewIndustry_restoreplayer

codefragment oldcheckinduclosedown
	mov al,[currentyear]
	sub al,[esi+industry.lastyearprod]

codefragment newcheckinduclosedown
	icall checkinduclosedown
	setfragmentsize 8

codefragment oldindudecreaseprod
	cmp byte [esi+industry.prodmultiplier],4
	jz fragmentstart-0x2b	// jz .closedown

codefragment newindudecreaseprod
	icall checkindudecprod
	jc fragmentstart-0x2b	// jc .closedown
	jz fragmentstart+0x33	// jz .done
	setfragmentsize 18

codefragment oldtoyfactoryanimation,8
	mov [nosplit landscape3+ebx*2],ax
	cmp ah,8

codefragment newtoyfactoryanimation
	clc
	setfragmentsize 3

codefragment oldindustryproductionquery
	mov bl,[esi+industry.producedcargos]
	cmp bl,-1

codefragment_jmp newindustryproductionquery,industryproductionquery,5

codefragment findmakeindudropdown, -17
	db 30h
	dw 313h		// mov word [esi+window.data.menu.firsttext], 313h
	
codefragment findCreateIndustry,4
	mov [esi+industry.owner],al
	
codefragment findRemoveIndustry,8
	mov word [esi],0
	db 0B1h		// mov cl,cWinTypeIndustry

endcodefragments

ext_frag oldindustryclosedown

extern industry2arrayptr

patchnewindustries:
	// allocate the industry2 array
	push dword NUMINDUSTRIES*industry2_size
	call malloccrit
	pop dword [industry2arrayptr]

	// these two are needed for the prospecting code, so it works even with moreindustriesperclimate disabled
	storeaddress findCreateNewRandomIndustry,1,1,CreateNewRandomIndustry
	mov dword [fundcostmultipliers],industryfundcostmultis

	patchcode getindustrytilegraphics
	mov eax,[edi+lastediadj+35]
	mov [industilespritetable],eax
	patchcode industileconststatechange
	patchcode class8periodicproc0
	patchcode class8periodicproc1
	stringaddress oldclass8periodicproc2
	mov eax,[edi+2]
	mov [baIndustryTileTransformBack],eax
	storefragment newclass8periodicproc2
	patchcode distributeindustrycargo1
	stringaddress olddistributeindustrycargo2
	mov eax,[edi+2]
	mov [baIndustryTileTransformOnDistr],eax
	storefragment newdistributeindustrycargo2
	patchcode class8animationhandler
	patchcode getlayoutbyte
	patchcode putindutile
	storeaddress findcreateinitialindustry_nolookup,1,1,createinitialindustry_nolookup
	patchcode createinitialindustries
	patchcode ingamerandomindustry
	patchcode drawmapindustrymode

	// patch industry names
	stringaddress oldgetindunamebx,1,2
	storefunctioncall getindunamebx
	stringaddress oldgetindunamebx,1,0
	storefunctioncall getindunamebx
	stringaddress oldgetindunamebp,1,3
	storefunctioncall getindunamebp
	stringaddress oldgetindunamebp,1,0
	storefunctioncall getindunamebp
	stringaddress oldgetindunamebp,1,0
	storefunctioncall getindunamebp
	patchcode getindunameaxecx
	patchcode getindunameaxedi
	multipatchcode oldgetindunameaxesi,newgetindunameaxesi,2

	patchcode putfarmfields1
	patchcode cutlmilltrees
	patchcode inducheckempty
	stringaddress oldcanindubuiltonwater,1,1
	storefunctioncall canindubuiltonwater
	stringaddress oldcaninduonlybigtown,1,1
	storefunctioncall caninduonlybigtown
	stringaddress oldcaninduonlytown
	storefunctioncall caninduonlytown
	stringaddress oldcaninduonlyneartown,1,1
	storefunctioncall caninduonlyneartown
	patchcode caninduonlytown2
	patchcode putfarmfields2
	stringaddress oldinducantincrease,1,1
	mov [industry_primaryprodchange],edi
	storefragment newinducantincrease
	patchcode randominducantcreate
	patchcode oldaioilrigcheck1,newaioilrigcheck,1,1
	patchcode oldaioilrigcheck2,newaioilrigcheck,1,1
	patchcode genmilairplane
	patchcode tickprocmilairplane
	patchcode genmilhelicopter
	patchcode tickprocmilhelicopter
	patchcode gencoalminesubs
	patchcode newindumessage

	patchcode checkinduinput
	patchcode industryproducecargo

	patchcode openfundindustrywindow
 	patchcode opengenerateindustrywindow

	patchcode initnewindustry

	stringaddress oldcreateindustrywindow,1,1
	mov eax,[edi+17]
	mov [oldinduwindowitemlist],eax
	storefragment newcreateindustrywindow

	mov ecx,85
	push ecx
	call malloccrit
	pop edi
	mov [newinduwindowitemlist],edi
	mov esi,[oldinduwindowitemlist]

	rep movsb

	mov eax,[newinduwindowitemlist]

	add word [eax+56],40
	add word [eax+66],40
	add word [eax+68],40
	add word [eax+78],40
	add word [eax+80],40

	mov eax,[oldinduwindowitemlist]

	add word [eax+56],10
	add word [eax+66],10
	add word [eax+68],10
	add word [eax+78],10
	add word [eax+80],10

	patchcode drawinduacceptlist
	patchcode skipproducelist
	patchcode skipfirstproducedcargo
%macro finishproducelist 0
	add edi, 27+lastediadj
	storefragment newfinishinduproducelist
	inc byte [cargonum]
%endmacro
	multipatchcode olddrawinduproducelist,newdrawinduproducelist,2,finishproducelist

	stringaddress oldenddrawindustrywindow,1,1
	chainfunction enddrawindustrywindow,.oldfn

	patchcode createindustry_chkplacement
	patchcode fundindustry_chkplacement
	patchcode fundindustry_overwriteerrmsg

	patchcode industryrandomprodchange
	storeaddress oldindustryclosedown,1,1,industry_closedown
	stringaddress oldindustryprodchange_shownewsmsg,1,1
	lea eax,[edi-9]
	mov [industry_showchangemsg],eax
	storefragment newindustryprodchange_shownewsmsg
	stringaddress oldmonthlyupdateindustryproc,1,1
	chainfunction monthlyupdateindustryproc,.oldfn
	add edi, 9Eh-7Ah
extern monthlyinduwinupdate, monthlyinduwinupdate.oldfn, newinduinduwinupdate
extern closeinduinduwinupdate, closeinduinduwinupdate.oldfn
	chainfunction monthlyinduwinupdate,.oldfn
	stringaddress findCreateIndustry
	changereltarget 0,newinduinduwinupdate
	stringaddress findRemoveIndustry
	chainfunction closeinduinduwinupdate,.oldfn

	stringaddress oldcheckindustileslope,2-WINTTDX,2
	storefunctioncall checkindustileslope

	// for newsounds support, the random sound code needs patched
	patchcode industryrandomsound

// allow merging adjacent industry tiles by modifying the altitude correction func and
// the foundation drawing code
	mov eax,[ophandler+(8*8)]
	mov dword [eax+0x14],correctexactalt.chkslope
	patchcode olddrawindustryfundation,newdrawindustryfundation,2-WINTTDX,2

	patchcode plantrandomfields

	patchcode FundNewIndustry_saveplayer
	multipatchcode oldFundNewIndustry_restoreplayer,newFundNewIndustry_restoreplayer,2
	mov eax,[ophandler+8*8]
	mov dword [eax+0x38],indutilesellouthandler

	patchcode checkinduclosedown
	patchcode indudecreaseprod

// fix toy factory animations messing up the high byte of L3
	patchcode toyfactoryanimation

	patchcode industryproductionquery
	
	stringaddress findmakeindudropdown
	inc byte [edi]
	mov byte [edi-(564665h+4)+(564641h+3)],16h
	mov byte [edi-(564665h+4)+(564633h+7)],15h
	ret

// shares a code fragment
global patchdifficultysettings
patchdifficultysettings:
	stringaddress findDifficultySettingsData, 1,1
	mov word [edi+24], -1
	mov word [edi+30], ourtext(low)
	patchcode oldCreateInitialRandomIndustries,newCreateInitialRandomIndustries,1,1
	ret
