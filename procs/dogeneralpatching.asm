#include <defs.inc>
#include <frag_mac.inc>
#include <vehtype.inc>
#include <station.inc>
#include <window.inc>
#include <town.inc>
#include <player.inc>
#include <industry.inc>
#include <ptrvar.inc>
#include <bitvars.inc>
#include <patchproc.inc>

patchproc sharedorders, patchsharedorders

extern BringWindowToForeground,CreateTooltip,CreateWindow
extern CreateWindowRelative,DestroyWindow,DistributeProducedCargo
extern DrawStationImageInSelWindow,DrawWindowElements,FindWindow
extern GenerateDropDownMenu,GetMainViewWindow,RefreshLandscapeHighlights
extern RefreshLandscapeRect,RefreshWindowArea,ScreenToLandscapeCoords
extern TransmitAction,WindowClicked,WindowTitleBarClicked,acceptcargofn
extern actionhandler,addexpenses,addgroundsprite,addlinkedsprite
extern addrailgroundsprite,addrelsprite,addsprite,aiactiontable
extern aicargovehinittables,aircraftcosttable,brakespeedtable,bridgedata
extern bridgespritetables,calcexactgroundcornermapcopy,calcprofitfn
extern changecolorscheme,changecolorscheme.origfn,checkvehiclesinthewayfn
extern class8queryhandler,cleartilefn,closecompanywindows,copyspriteinfofn
extern copyvehordersfn,curfileofsptr,currrmsignalcost,currscreenupdateblock
extern curtooltracktypeptr,ddrawpaletteptr,decodespritefn,deductvehruncost
extern delveharrayentry,delvehschedule,doshownewrailveh,drawrectangle
extern drawrighttextfn,drawsplittextfn,drawspritefn,drawspriteonscreen,drawtextfn
extern drawstringfn,endofloadtarget,errorpopup,fillrectangle,fnredrawsquare
extern generatesoundeffect,gennewrailvehtypemsg,getdesertmap,getfullymd
extern getgroundaltitude,getroutemap,gettextwidth,gettileinfo
extern gettileinfoshort,gettunnelotherend,getymd,groundaltsubroutines
extern malloccrit,housepartflags,housespritetable,incomequarterstatslist
extern industrydatabackupptr,industrylayouttableptr
extern infosave,initializegraphics,initializekeymap,initializeveharraysizeptr
extern int21handler,invalidatehandle,invalidaterect,invalidatetile
extern isbigplanetable,landshapetospriteptr,loadchunkfn,mainstringtable
extern makerisingcost,malloccrit,maxverstringlen,moresteamsetting
extern newclass0Bactionhandler,newclassdinithnd,newclassdinithnd.oldfn
extern newdisplayhandlers,newdisplayhandlers_np,newdisplayhandlersize
extern newdisplayhandlersize_np,newgraphicssetsenabled,newscenarioinit
extern newscenarioinit.origfn,newsmessagefn,newspritehandlers
extern newspritehandlersize,newvehicles,newvehtypeinit,newvehtypeinit.oldfn
extern oldindutileacceptsbase,openfilefn,ophandler,textspechandler
extern ophandler_ptr,orgsetsprite,orgsetspriteofs,orgspritebases,patchflags
extern pushownerontextstack,randomfn,readspriteinfofn,readwordfn
extern reloadenginesfn,reloc,removespritefromcache,resetplanesprite
extern resetplanesprite.oldfn,roadvehcosttable,savechunkfn,savevehordersfn
extern scenedactiveptr,searchcollidingvehs,setbasecostmultdefault
extern setcharwidthtablefn,setmainviewxy,setmousecursor,setmousetool
extern shipcosttable,showsteamsmoke,signalchangeopptr,specificpropertybase
extern specificpropertyofs,splittextlines,spritecacheptr,startsignalloopfn
extern stationbuildcostptr,statusbarnewsitem,subsidyfn
extern tempSplittextlinesNumlinesptr,traincosttable,trainpower
extern trainpower_ptr, rvspeed_ptr, shipsprite_ptr, planesprite_ptr
extern treeplantfn,ttdpatchversion,ttdtexthandler,veh2ptr,vehbase,vehbnum
extern vehclassorder,vehtypedataptr,pickrandomtreefn
extern waterbanksprites,exitcleanup,oldclass6maphandler,addcargotostation
extern reduceyeartobyte,reduceyeartoword
extern titlescreenloading, class0procmidsection, checkroadremovalconditions
extern drawcenteredtextfn,drawsplitcenteredtextfn, RefreshWindows
extern CreateTextInputWindow, findroadvehicledepot
extern addrailfence1,addrailfence2,addrailfence3,addrailfence4
extern addrailfence5,addrailfence6,addrailfence7,addrailfence8
extern rvcheckovertake,findFrSpaTownNameFlags,runspectexthandlers
extern fncheckvehintheway,languageid,origlanguageid
extern num_powersoften,powersoften_last
extern initializecargofn
extern CheckForVehiclesInTheWay
extern MakeTempScrnBlockDesc

begincodefragments

codefragment oldstartsignalsloop
	sub esp,0x300

codefragment newstartsignalsloop
	call runindex(signalsstart)

//codefragment oldsignalsloop
//	movzx edi,word ptr [ebp]
//	mov al,[ebp+2]

codefragment newsignalsloop
	call runindex(signalsloop)
	nop

codefragment newsignalsloopend
	call runindex(signalsend)

codefragment oldnewsignalsetup,9
//	and word ptr [edi*2+landscape3],0ff0fh
	and word [nosplit edi*2+landscape3],0xff0f

codefragment newnewsignalsetup
	db 0	// change mask to 000fh to clear pre-signal byte

codefragment oldremovesignal
	test bl,1
	jz short $+2+0x2b+4*WINTTDX

codefragment newremovesignal
	call runindex(removesignalsetup)
	jz short $+2+0x28+4*WINTTDX
	setfragmentsize 16+4*WINTTDX,1

codefragment oldremovesignalcost
//	mov ebx,[signalremovecost]
	mov ebx,[signalremovecost]

codefragment newremovesignalcost
	mov ebx,dword [currrmsignalcost]

codefragment findactionhandler,8
	push dx
	mov esi,0xe0008

reusecodefragment olddemolishtrackcall,findactionhandler,7

codefragment newdemolishtrackcall
	call runindex(demolishtrackcall)
	setfragmentsize 7

codefragment oldenterdepot
	mov di,bx
	shr esi,1

codefragment newenterdepot
	call runindex(enterdepot)

codefragment oldshowendoforders,-5
	mov bx,0x882a	// - - End of orders - -

codefragment newshowendoforders
	call runindex(showendoforders)
	jnz $+2+3
	setfragmentsize 9

codefragment oldadjustorders
	cmp byte [esi+veh.class],0
	jz $+2+0xf
	cmp dword [esi+veh.scheduleptr],byte -1

codefragment newadjustorders
	call runindex(adjustorders)
	setfragmentsize 9

codefragment olddeletepressed
	add edi,[veharrayptr]
	cmp al,[edi+veh.totalorders]

codefragment newdeletepressed
	call runindex(deletepressed)
	setfragmentsize 9

codefragment finddeletevehschedule
	mov ebp,[edx+veh.scheduleptr]
	movzx esi,byte [edx+veh.totalorders]

reusecodefragment olddeletevehschedule,finddeletevehschedule

codefragment newdeletevehschedule
	call runindex(delvehicleschedule)
	setfragmentsize 7

codefragment findgetymd,-2
	mov ebx,0x5b5	// days in four years = 3*365+366

reusecodefragment oldprintdate,findgetymd,-3

codefragment newprintdate
	call runindex(getyear4fromdate)
	add eax,1920		// over the entire 32-bit range
	sub ax,1920		// both date printing functions do ADD AX,1920 later
	jmp fragmentstart+29

codefragment newgetymd
	push addr(reduceyeartobyte)	// RET will jump there
getymd.wordyearentryoffset equ $-fragmentstart
	push addr(reduceyeartoword)	// same here
getymd.fullyearentryoffset equ $-fragmentstart
	call runindex(getyear4fromdate)
	setfragmentsize 24,1

codefragment oldisnewyear,2
	pop ax
	cmp al,[currentyear]

codefragment newisnewyear,2
	call runindex(isnewyear)

codefragment newgetdisasteryear
	call runindex(getdisasteryear)
	setfragmentsize 7

codefragment oldgetvehintroyear,7
	mov ax,[vehtypearray+vehtype.introduced+ebx]

codefragment newgetvehintroyear
	call runindex(getvehintroyear)
	setfragmentsize 9

codefragment getfinanceswindowyears,-7
	add ax,1918

codefragment reccompanylaunchyear,-8
	mov [esi+player.inaugurated],ax

codefragment oldgetgraphstartyear,5
	add si,1920

codefragment newgetgraphstartyear
	call runindex(getgraphstartyear)

codefragment oldshowyearbuilt
	movzx ax,[edi+veh.yearbuilt]

codefragment newshowyearbuilt
	call runindex(showyearbuilt)
	setfragmentsize 9

codefragment nonstop1old
	or dl,dl
	db 0x79,0x18	// jns .noorders
	db 0x80		// and dl,1fh

codefragment nonstop1new
	call runindex(checkstation)
	jc nonstop1new_start+0x1c
	ret

codefragment brakeindex,0xa
	bts word [edi+0x32],4

reusecodefragment nonstop2old,brakeindex,0

codefragment nonstop2new
	jmp runindex(stationbrake)

codefragment oldshowordertype,-4
	add bp,0x8806

codefragment newshowordertype
	icall showordertype
	setfragmentsize 9

codefragment oldint21handler
	cmp ax, 0x4200
	db 0xf		// jz somewhere far

codefragment oldtexthandler
	mov si,ax
	and eax,0x7ff

codefragment_jmp newtexthandler,newtexthandler,5
codefragment_jmp newtextprocessing,textprocessing,5

codefragment newsetintrodate
	call runindex(setintrodate)
	setfragmentsize 7

codefragment findvehiclecosttable,-16
	shr eax,5
	mov dword [esi+veh.value],eax

codefragment findddrawpaletteobj,-6
	call dword [eax+0x18]	// DDrawPalette->SetEntries
	db 0xe9		// jmp ...

codefragment findinvalidaterect,9
	add dx,[esi+8]
	add bp,[esi+0xa]
	db 0xe8

codefragment findinvalidatehandle,7
	mov bx,[edx+0x26]
	mov al,0x12
	db 0xe8

codefragment findinvalidatetile,-34
	sub bx,122

codefragment oldredrawdone
	mov word [screenrefreshmaxy],0

codefragment newredrawdone
	jmp runindex(redrawdone)

codefragment finderrorpopup,-8
	db 0x80
	ret
	and bl,0xfe

glob_frag oldcontrolplanecrashes
codefragment oldcontrolplanecrashes,4
	mov cx,pplanecrashjetonsmall

reusecodefragment findrandomfn,oldcontrolplanecrashes,5

codefragment findmakerisingcost
	push ax
	push ebx
	push cx
	push edi

codefragment findacceptcargo,7
	mov word [esi+veh.currentload],0
	db 0xe8		// call acceptcargo

codefragment findprofitcalc,16
	jnz short $+2+0xe
	cmp ch,0xa
	jnz short $+2+9

codefragment findstatusbarnewsitem,12
	mov word [textrefstack],0x705e

codefragment findisbigplane,6
	movzx edi,word [esi+veh.vehtype]
	db 0xf6,0x87	// test byte ptr [xxxx],1

codefragment finddeleteveharrayentry,-4
	mov di,word [esi+veh.XY]
	movzx cx,byte [esi+veh.movementstat]

codefragment findnewsmsgfunction,5
	mov dx,0xb004
	db 0xe8		// call ...

codefragment findaicargovehinittables,-4
	mov edi,aicargovehicles

codefragment findcurtooltracktype,-8
	add ebx,1263

codefragment findaddsprite,-37
	dec di
	dec si
	dec dh

codefragment findlandshapetosprite, 12
	imul bx, 19
	and edi, 0FFFFh

codefragment findwaterbanksprites
	dw 0, 4063

codefragment findgetgroundaltitude
	push ebx
	push edi
	push ax
	push cx
	and al,0xF0

codefragment_call newcalcexactgroundcornermapcopy,calcexactgroundcornermapcopy,5

codefragment findgetroutemap,-23-2*WINTTDX
	call dword [ebp+0x24]
	ret

codefragment findgetdesertmap
	db 0x8b,0xc3		// mov eax,<r/m> ebx
	shr eax,1
	jb short $+2+0xd

codefragment findcleartilefn,-4
	xor ebx, ebx
	retn
	mov esi, 20050h

//codefragment oldremoveobject, 2
//	db 0x74,0x1E
//	db 0xBB,0x00,0x00,0x00,0x80
//	db 0x66

codefragment findcallcheckvehiclesintheway,-10
	mov word [operrormsg2],0x1007
	push bx

codefragment findcheckroadremovalconditions,-17
	mov     word [operrormsg2], 0FFFFh
	push    bx


glob_frag oldcompletehousecreated
codefragment oldcompletehousecreated,-8
	add [esi+town.population],ax
	db 0x66,0xff		// inc word...

reusecodefragment findhousepopulationtable,oldcompletehousecreated,-4

codefragment findhousespritetable,8
	pop dx
	imul si,si,byte 0x11

codefragment findbridgespritetables, -10
	mov edi, [edi]
	shl ebx, 3

codefragment findbridgespeeds
	dw 32, 48, 64

codefragment findaiactiontable,10
	movzx ebx,byte [esi+player.aiaction]

codefragment oldinitializeveharray
	mov byte [esi],0
	inc esi
	db 0xe2		// loop...

codefragment newinitializeveharray
	call runindex(initializeveharray)

codefragment findcurrscreenupdateblockptr, 13
	mov bx, 4834
 	mov cx, 30
 	mov dx, 439

reusecodefragment finddrawspritefn,findcurrscreenupdateblockptr, 18

codefragment finddrawspriteonscreen
	mov ebx,[es:esi]
	db 0x66,0xFF,5	// inc dword [...]

glob_frag oldenddisplaytownstats
codefragment oldenddisplaytownstats,19
	mov ax,[ebx+town.maxmailtrans]
	db 0x66,0xa3		// mov [textrefstack+2],ax

reusecodefragment finddrawtextfn,oldenddisplaytownstats,15

codefragment finddrawrighttextfn, 12
	mov bx, 170h
	mov ax, [ebp+626h]

codefragment finddrawsplittextfn,-66
	cmp bx, 0xe0

codefragment newsplittextlines_done
	jmp runindex(splittextlines_done)


codefragment findfillrectangle
	cmp word [edi+0x10], 0
	db 0x0F, 0x85	// jnz...	

codefragment finddrawrectangle
	push si
	push dx
	push cx

codefragment findDrawStationImageInSelWindow
	movzx eax, al
	imul eax, 82

glob_frag oldbuslorrystationflatland
codefragment oldbuslorrystationflatland,77
	mov dx,0x101
	push ax

reusecodefragment findstationbuildcostptr,oldbuslorrystationflatland,-8

codefragment findpushownerontextstack,-2
	mov [ebp+6],dl
	test dl,0x80

codefragment findTransmitAction
	cmp byte [numplayers],1
	jz $+2+0x7c

codefragment findDistributeProducedCargo,-4
	push ebp
	push esi
	db 0xc7,0x05	// mov dword [...],-1

codefragment findindustrydatablock,6
	movzx ebx,byte [esi+industry.type]
	db 0x8a, 0x83		// mov al,[ebx+...

codefragment findindustrylayouttable,6
	mul dx
	db 0x8b, 0x2c, 0xdd	// mov ebp,[ebx*8+...

codefragment oldclass8queryhandler
#if WINTTDX
	movzx ebx,byte [landscape5(di)]
#else
	db 0x67,0x65,0xf,0xb6,0x1d
#endif

codefragment_call newclass8queryhandler,class8queryhandler,5+2*WINTTDX

codefragment findgraphicsroutines
	push ax
	push esi
	cmp bx,byte -1

glob_frag oldrecordlastactionxy
codefragment oldrecordlastactionxy
	db 0x66,0x8b,0xf0	// mov si,<r/m> ax
	db 0x66,0x0b,0xf1	// or si,<r/m> cx

reusecodefragment oldchkactionshiftkeys,oldrecordlastactionxy,-81

codefragment newchkactionshiftkeys
	call runindex(recordcurplayerctrlkey)
	setfragmentsize 9

codefragment setcurplayershiftkeys
	call runindex(setcurplayerctrlkey)

codefragment oldmakenewhumans,5
	mov [human1],al
	db 0xc6		// mov imm8

codefragment newmakenewhumans
	call runindex(makenewhumans1)
	setfragmentsize 7

codefragment oldaistationrating,3
	mov ah,byte [esi+station.owner]
	db 0x3a,0x25	// cmp ah,human1

codefragment newaistationrating
	call runindex(aistationrating)

codefragment oldplayertype1,2
	db 06,00,0x3a,5

codefragment newplayertype1
	call runindex(playertype1)
	jmp short $+28

codefragment oldplayertype2,4
	mov ax,0x7002

codefragment newplayertype2
	call runindex(playertype2)

codefragment oldplayertype3,9
	db 06,00,0xf,0xb7,0x1d

codefragment newplayertype3
	call runindex(playertype3)
	jmp short $+28

codefragment oldplayertype4,2
	db 06,00,0x3a,0x1d

codefragment newplayertype4
	call runindex(playertype4)

codefragment oldaibuilding,15
	cmp byte [esi+0x1b],0
	db 0xf	// jnz far

codefragment newaibuilding
	call runindex(aibuilding)
	jnz .continue
	ret
.continue:
	setfragmentsize 16

codefragment oldgetvehsprite,4
	movzx edi,byte [esi+veh.spritetype]

codefragment olddisplayveh,4
	mov ax,6
	db 0x66,3	// add ax,[ebx+vehspritebase+x]

codefragment findvehinfo,6
	db 0
	shr ebx,8
	db 0x8a,0x83	// mov al,[ebx+spritebase]

codefragment oldgetothervehsprite,4
	movzx edi,byte [edi+veh.spritetype]

codefragment newgetshadowsprite
	call runindex(getshadowsprite)
	nop

codefragment olddisprotor1
	mov bx,0xf3d
	sub dx,5

codefragment newdisprotor1
	call runindex(disprotor1)
	setfragmentsize 8

codefragment olddisprotor2
	sub dx,5
	mov bx,0xf3d

codefragment newdisprotor2
	call runindex(disprotor2)
	setfragmentsize 8

codefragment oldinitrotor
	mov word [esi+veh.cursprite],0xf3d

codefragment newinitrotor
	call runindex(initrotor)

codefragment oldcheckrotor
	cmp word [esi+veh.cursprite],0xf40

codefragment newcheckrotor
	call runindex(checkrotor)

codefragment oldstoprotor
	mov bx,0xf3d
	cmp bx,[esi+veh.cursprite]

codefragment newstoprotor
	call runindex(stoprotor)
	setfragmentsize 8

codefragment newadvancerotor
	call runindex(advancerotor)
	stc	// so that the jb is done

codefragment olddisplay1steng,4
	mov ax,6
	db 0x66,0x23	// and ax,[ebx+vehspritebase+y]

codefragment newdisplay1steng
	call runindex(display1stengine)
	setfragmentsize 14

codefragment newdisplay1steng_noplayer
	call runindex(display1stengine_noplayer)
	setfragmentsize 17

codefragment olddecidesmoke
	bt word [esi+veh.vehstatus],4

codefragment newdecidesmoke
	call runindex(decidesmoke)

codefragment oldsteamposition,4
	movzx ebx,byte [esi+veh.direction]

codefragment newsteamposition
	cmp byte [esi+veh.spritetype],0xfe
	jb short .notturned
	xor ebx,4
.notturned:
	call runindex(steamposition)
	setfragmentsize 16

codefragment olddecidesound
	cmp byte [esi+veh.spritetype],8
	db 0x72		// jb...

codefragment newdecidesound
	call runindex(decidesound)
	ret

codefragment oldtunnelsound
	cmp byte [edi+veh.spritetype],8

codefragment newtunnelsound
	call runindex(tunnelsound)
	ret

codefragment olddoessteamelectricsmoke,1
	ret
	db 0xf6,0x46,0x17	// test byte [esi+17],...

codefragment newsteamamount
	test [edi+veh.cycle],ah
	setfragmentsize 4

codefragment olddoesdieselsmoke,11
	cmp word [esi+veh.speed],2
	db 0xf		// jb near ...

codefragment newdoesdieselsmoke
	call runindex(doesdieselsmoke)
	jb newdoesdieselsmoke_start-6
	setfragmentsize 11

codefragment oldsparkprobab,-5
	cmp ax,0x5b0

codefragment newsparkprobab
	call runindex(sparkprobab)
	setfragmentsize 9

codefragment olddieselsmoke,-13
	push esi
	mov ax,word [esi+veh.nextunitidx]

codefragment newdieselsmoke
	ret

codefragment oldadvancesteamplume,3
	xor al,4
	test al,15

codefragment oldcollectsprites_vehcolor
	mov al,[esi+veh.owner]
	mov al,[companycolors+eax]
	add ax,775

codefragment newcollectsprites_vehcolor
	icall getvehiclecolor
	setfragmentsize 13

codefragment oldvehinwindow_color
	mov al,[edi+veh.owner]
	mov al,[companycolors+eax]
	add ax,775

codefragment newvehinwindow_color
	xchg esi,edi
	icall getvehiclecolor
	xchg esi,edi
	setfragmentsize 13

codefragment oldbuyvehwindow_color
	movzx ebx,byte [human1]
	mov bl,[companycolors+ebx]
	add bx,775

codefragment newbuyvehwindow_color
	icall getvehiclecolor_nostruc
	setfragmentsize 18, 1


codefragment oldcompanysold,-6
	mov al,[esi]
	cmp al,0x10
	jz $+2+0x10

codefragment newcompanysold
	call runindex(companysold)

codefragment findclosecompanywindows
	movzx dx,bh
	mov cl,0x1d

codefragment oldclearnextunitidx
	mov word [esi+veh.nextunitidx],-1

codefragment newcreatevehentry
	call runindex(createvehentry)

codefragment oldattachtoedi,-4
	mov [edi+veh.nextunitidx],ax

codefragment newattachboughtveh
	iparam_call checkattachveh,esi,edi

codefragment oldattachtoesi,-4
	mov [esi+veh.nextunitidx],ax

codefragment newattachtoesi
	iparam_call attachveh,edi,esi

codefragment newattachtoedx
	iparam_call attachveh,esi,edx

codefragment newdetachveh
	call runindex(detachveh)
	setfragmentsize 8

codefragment newnextfirstwagon
	call runindex(nextfirstwagon)
	jnc newnextfirstwagon_start-9
	setfragmentsize 9

codefragment newinsertveh
	call runindex(insertveh)
	setfragmentsize 8

codefragment oldattachdisasterveh,-4
	mov [edi+veh.nextunitidx],bx

codefragment newattachdisasterveh
	iparam_call attachveh,esi,edi

codefragment oldsellwagonnewleader
	add ebx,[veharrayptr]
	db 0xc6		// mov [ebx+veh.subclass],4

codefragment newsellwagonnewleader
	call runindex(sellwagonnewleader)

codefragment oldmovedcheckiswaggon
	cmp byte [edi+veh.spritetype],0x42
	db 0xf,0x82

codefragment newmovedcheckiswaggonp2
	setfragmentsize 4

codefragment newmovedcheckiswaggon
	call runindex(movedcheckiswaggon)

codefragment oldmovedcheckiswaggonui,-2
	cmp byte [edx+veh.spritetype],0x42
	jb short $+2+0x65

codefragment newmovedcheckiswaggonui
	call runindex(movedcheckiswaggonui)

codefragment oldgettrainrunningcost,9
	shl ax,1
	db 0x66,0xa3	// mov word ptr...

codefragment newgettrainrunningcost
	call runindex(gettrainrunningcost)

codefragment newgettrainrunningcostmultiplier
	call runindex(gettrainrunningcostmultiplier)

codefragment newshownewrailveh
	jmp runindex(shownewrailveh)

codefragment oldnewvehavailable
	or byte [esi+vehtype.flags],2

codefragment newnewvehavailable
	call runindex(newvehavailable)
	jnc $+24

codefragment oldgetrailengclassname,-4
	cmp ax,byte 54
	jb short $+2+0xC

codefragment newgetvehclassname
	push eax
	movzx eax,al
	call runindex(getrailvehclassname)
	pop eax
	setfragmentsize 22	// need sizes 24 and 22
	setfragmentsize 24

reusecodefragment newgetrailengclassname,newgetvehclassname,,22

reusecodefragment oldgetvehclassname,oldgetrailengclassname,,5

codefragment oldupdaterailtype1
	mov [edx+player.tracktypes],ah

codefragment newupdaterailtype1
	call runindex(updaterailtype1)

codefragment oldupdaterailtype2
	mov [ebx+player.tracktypes],al

codefragment newupdaterailtype2
	call runindex(updaterailtype2)

codefragment findclosevehwindow
	mov cl,0x10
	mov dx,[esi+window.id]

codefragment oldfirstrvarrival
	cmp word [esi+veh.vehtype],byte 0x7b

codefragment newfirstrvarrival
	cmp byte [esi+veh.cargotype],1	// B=bus, AE=truck
	setfragmentsize 5

codefragment findplanttree
	push ax
	push cx
	db 0xC6,0x05	//mov b,[...

codefragment skipnonprintingchars,9
	cmp bx,byte 0x5d
	jb short $+2+9

codefragment finddeductvehruncost,-36
	sbb [ebx+player.cash],edx
	db 0x70		// jo ...

codefragment findaddexpenses,-23
	sub [edx+player.cash],ebx
	db 0x70		// jo ...

codefragment findmakesubsidy,-5
	cmp byte [esi],-1
	jz $+2+0x10

codefragment findsearchcollidingvehs,-0x17
	and cx,0x0ff0
	mov bx,ax

codefragment findBringWindowToForeground, 6
	mov cl, 34h
 	xor dx, dx
	db 0xE8

codefragment findCreateWindow, -4
	mov dword [esi+24h], 0
	mov edx, 7F707F7h
	mov eax, 0

codefragment findWindowClicked, 14
	cmp cl, 0Ch
	jz $+2+0x23
	retn

codefragment findDestroyWindow, -4
	mov cx, 8
	mov ebx, 12E01BEh
	mov dx, 0FFFFh

codefragment findWindowTitleBarClicked,10
	mov ebx, 0Eh
 	call dword [ebp+4]
 	retn

codefragment findDrawWindowElements, -4
	movzx ebx, byte [esi+3]
	mov cx, [esi+8]

codefragment findFindWindow,-11
	jnb $+2+0xf
	cmp cl,[esi]

codefragment findGenerateDropDownMenu
	movzx ecx,cx
	btr [esi+0x1a],ecx

codefragment findCreateTooltip
	pusha
	or ax,ax

codefragment findRefreshWindowArea
	or esi,esi
	jz $+2+0x1d

codefragment findRefreshLandscapeRect,-5
	push cx
	mov cx, 8

codefragment findScreenToLandscapeCoords,-8
	or esi, esi
	db 0x74, 0x11	// jz ...

codefragment findRefreshLandscapeHighlights,-7
	db 0x75, 0x32	// jnz ...
	db 0x66, 0xF7	// test ...

codefragment findsetmousetool, -7
	db 74h, 4ch
	push ax
	push ebx
	push dx
	push esi

codefragment findsetmousecursor,-9
	cmp ebx, byte -1
	db 0x75, 0x26	// jnz short ...

codefragment findgetmainviewwindow,-5
	cmp byte [edi+window.type], 00
	db 0x74, 0x05

codefragment findCreateWindowRelative
	or cl,cl
	jns $+2+0x6b

codefragment findRefreshWindows, 7
	mov     al, 2
	mov     bx, 0

codefragment findsetmainviewxy
	push esi
	mov esi, windowstack_default
	cmp byte [esi], 0

codefragment findloadchunkfn,-5
	mov [es:esi],al
	inc esi
	loop $-9

codefragment findsavechunkfn,1
	ret		// in previous function
	mov al,[es:esi]
	db 0xe8		// call somewhere

codefragment oldloadsave
	mov ecx,datasaveend
	sub ecx,esi
	push ds
	pop es

codefragment newload
	call runindex(newloadproc)
	jc short $-0x16			// error
	jz short $-0x36-WINTTDX*3	// rewind
	jmp $+0x22+WINTTDX*4		// done

codefragment newsave
	call runindex(newsaveproc)
	jmp $+0x26+WINTTDX*4

codefragment newloadtitle
	mov byte [titlescreenloading],1
	push word [human1] 
	call runindex(newloadtitleproc)
	pop word [human1]
	mov byte [titlescreenloading],0
	ja fragmentstart+6+0x26+WINTTDX*4		// done
	pop ax
	jc short fragmentstart+10-0x27			// error
	jmp short fragmentstart+12-0x47-WINTTDX*3	// rewind

codefragment oldendofload,0x30
	mov ebx,6
	call [ebp+4]
	db 0x80

codefragment newendofload
	call runindex(checkloadsuccess)

codefragment oldendoftitleload
	mov ebx,6
	call [ebp+4]
	db 0x66

codefragment newendoftitleload
	call runindex(checktitleloadsuccess)
	setfragmentsize 8

codefragment findgeneratesoundeffect,6
	mov eax,18

codefragment oldsettracktypedefault
	mov [esi+0x2a],cx
	dec cx

codefragment newsettracktypedefault
	call runindex(settracktypedefault)

codefragment findremovespritefromcache,-2-4*WINTTDX
	xchg esi,[spritedata+ecx*4]

#if WINTTDX
codefragment findspritecacheptr,12
	lea ecx,[eax+5]
	db 0x66,0x8e	// mov es,[...]
#endif

codefragment oldsavevehorders
	mov ebp,[esi+veh.scheduleptr]
	mov ax,[ebp]

codefragment oldcopyoldorder,-15
	db 0x8b,0xd0	// mov dx,ax
	and dl,0x1f
	cmp dl,1

codefragment oldshowvehstat
	jz $+2+0x15
	mov bx,0xe2
	mov bp,[edi+veh.maxage]

codefragment newshowvehstat
	je short .isdepot
.notdepot:		// is target of surrounding code
	mov bl,0
	jmp short .getage
.isdepot:
	mov bl,1
.getage:
	mov bp,[edi+veh.maxage]
	call runindex(showvehstat)

	setfragmentsize 23


codefragment oldcleartile
	mov byte [landscape1+esi],0x10
	db 0xc6	// mov byte ...

codefragment newcleartile
	icall cleartile
	setfragmentsize 7

codefragment oldgetsliderposition
	add cx, 0x0A
	sub dx, 9

codefragment newgetsliderposition
	ijmp GetSliderPosition

codefragment oldcalcdropdownmenuwidth
	mov bx, [ebp+windowbox.x2]
	sub bx, ax

codefragment newcalcdropdownmenuwidth
	icall calcdropdownmenuwidth
	setfragmentsize 7

codefragment findgettextwidth,-4
	mov ebx, 14 << 16

codefragment findgettunnellength
	dw 0
	push dx
	push bp

codefragment oldlookforsamewagontype
	cmp byte [edi+veh.subclass],4
	jnz $+2+0x1b
	cmp al,[edi+veh.spritetype]

codefragment newlookforsamewagontype
	call runindex(lookforsamewagontype)
	setfragmentsize 9

codefragment oldpreparenewveharrentry,4
	db 0
	ret
	push ax
	mov al,[curplayer]

codefragment newpreparenewveharrentry
	icall preparenewveharrentry
	jc fragmentstart+61
	js fragmentstart+115
	setfragmentsize 11

codefragment oldsavedefaultname
	db "TRT0",0xc7

codefragment newsavedefaultname
	call runindex(savedefaultname)
	jmp short fragmentstart+39

codefragment finddrawcenteredtextfn,7
	mov     al, 0Dh
	push    cx
	push    dx
	
codefragment finddrawsplitcenteredtextfn,9
	push    cx
	push    dx
	mov     bp, 276

codefragment findCreateTextInputWindow, 7 
 	mov bp, 0x2A9
 	mov bl, 0xF6

codefragment oldtextcopy1
.nextchar:
	mov al,[esi]
	mov [edi],al
	inc esi
	inc edi
	or al,al
	jnz .nextchar
	dec edi
	ret

codefragment oldtextcopy2
.nextchar:
	mov al,[esi]
	mov [edi],al
	inc esi
	inc edi
	or al,al
	jnz .nextchar
	dec edi
	push eax

codefragment oldtextcopy3
.nextchar:
	mov al,[esi]
	mov [edi],al
	inc esi
	inc edi
	or al,al
	jnz .nextchar
	dec edi
	pop esi

codefragment_call newtextcopy123, newtextcopy,11

codefragment oldtextcopy4
.nextchar:
	mov al,[esi]
	mov [edi],al
	inc esi
	inc edi
	or al,al
	jnz .nextchar
	mov dword [edi-1],' & C'
	
codefragment newtextcopy4
	icall newtextcopy
	inc edi
	setfragmentsize 10

codefragment oldtextcopy5
	mov dl,[eax]
	mov [ss:edi],dl

codefragment newtextcopy5
	mov esi,eax
	icall newtextcopy
	ret

codefragment oldSpaTownNameCopy
	mov al,[esi]
	mov [edi],al
	inc esi
	inc edi
	cmp al,0x20

codefragment_call newSpaTownNameCopy,SpaTownNameCopy,19

codefragment oldaddparentdir
	push ss
	pop es
	mov al,1
	xor ebp,ebp

codefragment_call newaddparentdir, addparentdir

codefragment oldadddir1
.nextchar:
	mov al,[esi]
	mov [edi],al
	mov [ebx],al
	inc esi
	inc edi
	inc ebx
	or al,al
	jnz .nextchar

codefragment_call newadddir1, adddir1, 13

codefragment oldadddir2
.nextchar:
	mov al,[esi]
	mov [edi],al
	inc esi
	inc edi
	or al,al
	jnz .nextchar
	mov al,2

codefragment newadddir2
	push ecx
	push edx
	icall newtextcopy
	pop edx
	pop ecx
	setfragmentsize 10

codefragment oldaddsavegame,12
	xor dx,0xaaaa
	cmp dx,[edi]

codefragment_call newaddsavegame, addsavegame, 5

codefragment oldmakestationsigns,-4
	mov byte [edi],0xb4
	inc edi

codefragment newmakestationsigns
	mov edx, 0xb482ee		// E0B4h in UTF-8 with inverse byte order
	xor ecx,ecx
.nextsign:
	mov [edi],edx
	add edx, 0x10000
	shr al,1
	setc cl
	rcl cl,1		// now ecx=3 if the bit was set, 0 if not
	add edi,ecx
	cmp edx,0xb882ee
	jbe .nextsign
	setfragmentsize 40, 1

#if !WINTTDX
codefragment findexitcleanup,-4
	mov ax,0x4C00
	int 0x21

//codefragment findtextmodevar,7
//	mov ah,0xf
//	int 0x10
//	and al,0x7f
#endif

//codefragment findttdcriterrorfn,-27,0
//	cmp ax,0xf005

codefragment findpickrandomtreefn,-27
	xor ch,ch
	imul cx,12

codefragment findclass0procmidsection,1
	pop	ebx
	cmp	byte [climate], 1

codefragment findaddcargotostation,-9
	and cx, 0FFFh
	add cx, ax

codefragment findinitializecargofn,-21
	xor edi,edi
	mov ax,[ebp+edi*2]

codefragment findrvcheckovertake, 5
	mov     dword [esi+veh.delx], ebx
	pop     ebx
	retn
	
codefragment olddemolishroadcall,1
	push edi
	mov esi,0x10010

codefragment newdemolishroadcall
	call runindex(demolishroadcall)
	setfragmentsize 10

codefragment findAddRailFenceSprite1,-3
        push    edi
        push    esi
        inc     cl
        mov     ebx, 1301


codefragment findAddRailFenceSprite2,-3
        push    edi
        push    esi
        add     cl, 0Fh

codefragment findAddRailFenceSprite3, -3
        push    edi
        push    esi
        inc     al
        mov     ebx, 1302

codefragment findAddRailFenceSprite4, -3
        push    edi
        push    esi
        add     al, 0Fh
        mov     ebx, 1302

codefragment findAddRailFenceSprite5, -3
        push    edi
        push    esi
        add     al, 8
        add     cl, 8
        mov     ebx, 1303
        test    di, 1

codefragment findAddRailFenceSprite6, -3
        push    edi
        push    esi
        add     al, 8
        add     cl, 8
        mov     ebx, 1303
        test    di, 4

codefragment findAddRailFenceSprite7, -3
        push    edi
        push    esi
        add     al, 8
        add     cl, 8
        mov     ebx, 1304
        test    di, 8

codefragment findAddRailFenceSprite8, -3
        push    edi
        push    esi
        add     al, 8
        add     cl, 8
        mov     ebx, 1304
        test    di, 2

codefragment vehicleToDepotOld, -4
	mov     edx, ebx
	pop     cx
	pop     ebx
	pop     ax

#if WINTTDX
codefragment oldQuitGameKeycode
	push 0xE0

codefragment oldCheckQuitGameKeycode
	cmp al,0xe0
	jnz $+2+10
#endif

codefragment findCheckForVehiclesInTheWay,1
	ret
	pusha
	db 0xC6,5

codefragment findMakeTempScrnBlockDesc, 13
	mov bx, 469
	mov cx, 358
	mov bp, 11

endcodefragments

ptrvarall industrydatablock

ext_frag oldtrackbuildcheckvehs

ext_frag oldloadfilemask,oldgetdisasteryear

// pointers to the ptrvar ptrs for the specific properties of each vehicle class
vard vehclassspecptr, trainpower_ptr, rvspeed_ptr, shipsprite_ptr, planesprite_ptr

global dogeneralpatching
dogeneralpatching:
	imul eax,[newvehicles],byte veh2_size
	push eax
	call malloccrit
	pop dword [veh2ptr]
	// don't init here yet, it'll mess up searching...

	// this variable is sometimes not initialized properly
	// it should be the current mouse cursor, but sometimes the
	// mouse moves before this variable is initialized
	mov dword [curmousecursor],1

#if !WINTTDX
	storefunctionaddress findexitcleanup,1,1,exitcleanup
#else
	storeaddress oldint21handler,1,1,int21handler
#endif
//	storeaddress findttdcriterrorfn,1,1,ttdcriterrorfn

	//CALLINT3
	storeaddress oldtexthandler,1,1,ttdtexthandler
	storefragment newtexthandler
	add edi,lastediadj+43
	mov byte [edi+7], 0x72 // changes from jbe to jb so 0x10 can be passed through the texthandler (eis_os) 
	storefragment newtextprocessing
	lea eax,[edi+lastediadj+62]
	mov [textspechandler],eax

	// get the address of the main handler array
//	mov eax,[edi+lastediadj+0x1c]
//	mov [mainhandlertable],eax
	param_call reloc, dword [edi+lastediadj-15],ophandler_ptr

#if 0
	// fix some text handlers to return to texthandler.done when done
	mov eax,[opclass(3)]
	mov eax,[eax+8]		// texthandler
	mov esi,[eax+10]
	add esi,0xc1*4
%macro storewrap 2
	extern gen%1_wrap,gen%1_wrap.orgfn
	mov eax,gen%1_wrap
	xchg eax,[esi+%2]
	storerelative gen%1_wrap.orgfn,eax
%endmacro
	storewrap townname1,0
	storewrap townname2,4
	mov eax,[opclass(5)]
	mov eax,[eax+8]
	mov esi,[eax+10]
	storewrap statname,0xd1*4
	mov esi,[opclass(14)]
	storewrap custname,8
	mov eax,[opclass(13)]
	mov eax,[eax+8]
	mov esi,[eax+9]
	add esi,0xe4*4
	// skip 1st and 6th entries, they do proper returning
	storewrap compname2,4
	storewrap compname3,8
	storewrap compname4,12
	storewrap compname5,16
#endif
	// and get the general text table
	mov eax,[edi+lastediadj-4]
	mov [mainstringtable],eax

	call runspectexthandlers

	// check some code that bypasses the text handler and doesn't get Unicode processing

	multipatchcode oldtextcopy1,newtextcopy123,3
	multipatchcode oldtextcopy2,newtextcopy123,4
	patchcode oldtextcopy3,newtextcopy123,1,1
	patchcode oldtextcopy4,newtextcopy4,1,1
	patchcode textcopy5

	stringaddress oldSpaTownNameCopy,1,1
	mov esi,[edi-4]
	call findFrSpaTownNameFlags
	xor ecx,ecx
	storefragment newSpaTownNameCopy

	patchcode addparentdir
	patchcode adddir1
	patchcode adddir2
	multipatchcode oldaddsavegame,newaddsavegame,2

	stringaddress oldmakestationsigns,1,1
#ifdef UTF8
	storefragment newmakestationsigns
#endif

	storeaddress findgetymd,3,3,getymd
	mov [getfullymd],edi

	call initializekeymap

	// install a new vehtype data init handler
	mov edi,[ophandler+0xF*8]
	mov eax,[edi]
	mov [newvehtypeinit.oldfn],eax
	mov dword [edi],addr(newvehtypeinit)

	// while we're at it, get a few other TTD locations
	add eax,byte 11
	mov [reloadenginesfn],eax
	lea edi,[eax+24]
	mov eax,[eax+1]
	mov [vehtypedataptr],eax
	storefragment newsetintrodate

#if WINTTDX
	storeaddresspointer findvehiclecosttable,3,4,traincosttable
	storeaddresspointer findvehiclecosttable,2,4,roadvehcosttable
	storeaddresspointer findvehiclecosttable,4,4,shipcosttable
	storeaddresspointer findvehiclecosttable,1,4,aircraftcosttable
	storeaddresspointer findddrawpaletteobj,1,1,ddrawpaletteptr
#else
	storeaddresspointer findvehiclecosttable,1,4,traincosttable
	storeaddresspointer findvehiclecosttable,2,4,roadvehcosttable
	storeaddresspointer findvehiclecosttable,3,4,shipcosttable
	storeaddresspointer findvehiclecosttable,4,4,aircraftcosttable
#endif
	storefunctionaddress findinvalidaterect,1,1,invalidaterect
	storefunctionaddress findinvalidatehandle,1,0,invalidatehandle
	storeaddress findinvalidatetile,1,1,invalidatetile
	patchcode oldredrawdone,newredrawdone,1,1
	storefunctionaddress finderrorpopup,1,1,errorpopup
	storefunctionaddress findrandomfn,1,1,randomfn
	storefunctionaddress findactionhandler,1,1,actionhandler
	storeaddress findmakerisingcost,1,1,makerisingcost
	stringaddress oldloadfilemask,1,1
	mov eax,[edi+0x23]
	mov dword [scenedactiveptr],eax

	storefunctionaddress findacceptcargo,1,1,acceptcargofn
	storeaddress findprofitcalc,1,1,calcprofitfn
	storeaddress findaddcargotostation,1,1,addcargotostation
	storeaddress initializecargofn

	storefunctionaddress vehicleToDepotOld, 1, 2, findroadvehicledepot

	storeaddresspointer findstatusbarnewsitem,1,1,statusbarnewsitem
	storeaddresspointer brakeindex,1,1,brakespeedtable
	storeaddresspointer findisbigplane,1,1,isbigplanetable
	storefunctionaddress finddeleteveharrayentry,1,1,delveharrayentry
	storeaddress finddeletevehschedule,1,1,delvehschedule
	storefunctionaddress findnewsmsgfunction,1,1,newsmessagefn
	storeaddresspointer findaicargovehinittables,1,1,aicargovehinittables
	storeaddresspointer findcurtooltracktype,1,1,curtooltracktypeptr
	storeaddress findaddsprite,1,1,addsprite
	add edi,0x10c
	mov [addlinkedsprite],edi
	add edi,0xf1
	mov [addrelsprite],edi
	mov eax,[ophandler]
	mov edi,[eax+0x1c]
#if WINTTDX
	// in WinTTDX it's a jump to the function, not the function itself
	mov eax,[edi+0x40]
	lea edi,[edi+eax+0x44]
	storefunctiontarget 1,addgroundsprite
#else
	storefunctiontarget 0x40,addgroundsprite
#endif
	mov [addrailgroundsprite],eax

	storeaddresspointer findlandshapetosprite,1,1,landshapetospriteptr
	storeaddress findwaterbanksprites,1,1,waterbanksprites
	storeaddress findgetgroundaltitude,1,1,getgroundaltitude
	storefunctiontarget 12,gettileinfo	// depends on ^^
	add eax, 0x29
	mov [gettileinfoshort], eax
	mov eax,[edi+40]
	mov [groundaltsubroutines],eax
	// steep slope support (should be in buildonslopes)
	add edi, 24
	mov byte [edi-1], 0x90
	storefragment newcalcexactgroundcornermapcopy

	mov eax,[ophandler+0x06*8]
	mov eax, [eax+0x24]
	mov [oldclass6maphandler], eax

	storeaddress findgetroutemap,1,1,getroutemap
	storeaddress findgetdesertmap,1,1,getdesertmap
	storefunctionaddress findcleartilefn,1,1,cleartilefn
	storefunctionaddress findcallcheckvehiclesintheway,1,1,checkvehiclesinthewayfn
	storefunctionaddress findcheckroadremovalconditions,1,1,checkroadremovalconditions
	
	patchcode olddemolishroadcall,newdemolishroadcall,1,1
	add edi,byte 0x33+lastediadj
	storefragment newdemolishroadcall

	stringaddress findhousepopulationtable,1,1
	mov eax,[edi]
	mov edi,housepartflags
	sub eax,443
	stosd		//baHousePartFlags
	add eax,113
	stosd		//baHouseFlags
	add eax,110
	stosd		//baHouseAvailYears
	add eax,220
	stosd		//baHousePopulations
	add eax,110
	stosd		//baHouseMailGens
	add eax,110
	stosd		//baHouseAcceptPass
	add eax,110
	stosd		//baHouseAcceptMail
	add eax,110
	stosd		//baHouseAcceptGoodsOrFood
	add eax,110
	stosd		//waHouseRemoveRatings
	add eax,220
	stosd		//baHouseRemoveCostMultipliers
	add eax,110
	stosd		//waTownBuildingNames
	add eax,220
	stosd		//waHouseAvailMaskTable
	
	storeaddresspointer findhousespritetable,1,1,housespritetable
	storeaddresspointer findbridgespritetables,1,1,bridgespritetables

	sub eax,0x40
	mov [specificpropertybase+6*4],eax

	storeaddress findbridgespeeds,1,1,bridgedata+0*4

	storeaddresspointer findaiactiontable,1,2,aiactiontable

	patchcode oldinitializeveharray,newinitializeveharray
	lea eax,[edi+lastediadj-10+6*WINTTDX]
	mov [initializeveharraysizeptr],eax

	storeaddresspointer findcurrscreenupdateblockptr,1,1,currscreenupdateblock
	storefunctionaddress finddrawspritefn,1,1,drawspritefn
	storeaddress drawspriteonscreen
	storefunctionaddress finddrawtextfn,1,1,drawtextfn
#if WINTTDX
	inc eax
	add eax,[eax]
	add eax,4
#endif
	lea edi,[eax+42]
#if WINTTDX
	add edi,[edi]
	add edi,5
#endif
	storefunctiontarget 0,drawstringfn
	storefunctionaddress finddrawrighttextfn,1,1,drawrighttextfn
	storefunctionaddress finddrawcenteredtextfn,1,1,drawcenteredtextfn
	storefunctionaddress finddrawsplitcenteredtextfn,1,1,drawsplitcenteredtextfn
	storeaddress finddrawsplittextfn,2,2,drawsplittextfn
	add edi,173
	mov [splittextlines],edi
	mov eax,[edi+12]
	mov [tempSplittextlinesNumlinesptr],eax
	add edi,132
	storefragment newsplittextlines_done
	storeaddress findfillrectangle,1,1,fillrectangle
	storeaddress finddrawrectangle,1,1,drawrectangle

	storeaddress findDrawStationImageInSelWindow,DrawStationImageInSelWindow
	storeaddresspointer findstationbuildcostptr,1,2,stationbuildcostptr
	storeaddress findpushownerontextstack,1,1,pushownerontextstack
	storeaddress findTransmitAction,1,1,TransmitAction

	storeaddress findDistributeProducedCargo,1,1,DistributeProducedCargo

	// these offsets are needed for newindustries save/restore
	// this code *must* run before initializegraphics or industry action 0s will break

	// we have variables relative to the industry data block, so we need a reloc
	stringaddress findindustrydatablock,1,1
	push dword [edi]
	push industrydatablock_ptr
	call reloc
	storeaddresspointer findindustrylayouttable,1,1,industrylayouttableptr

	storeaddress findclass0procmidsection,1,1,class0procmidsection

	stringaddress oldclass8queryhandler
	mov eax,[edi+9+2*WINTTDX]
	mov [oldindutileacceptsbase],eax

	testflags newindustries
	jnc .nonewindus
	storefragment newclass8queryhandler
	push dword 925+296
	call malloccrit
	pop dword [industrydatabackupptr]

.nonewindus:

	stringaddress findgraphicsroutines,1,1

	storefunctiontarget 12,openfilefn
	add edi,56+3*WINTTDX
	mov eax,[edi+8]
	mov dword [curfileofsptr],eax

	storefunctiontarget 17,readwordfn
	add eax,17
	mov [copyspriteinfofn],eax
	add eax,64
	mov [readspriteinfofn],eax
	add eax,0x89
	mov [decodespritefn],eax

	mov al,[languageid]
	mov [origlanguageid],al

	call initializegraphics

	patchcode oldchkactionshiftkeys,newchkactionshiftkeys,1,1
	add edi,lastediadj+0x98
	storefragment setcurplayershiftkeys
	add edi,lastediadj+0xe1
	storefragment setcurplayershiftkeys

	patchcode oldmakenewhumans,newmakenewhumans,1,1
	mov eax,[ophandler+0xc*8]
	mov eax,[eax+4]
	mov eax,[eax+3]
	mov edi,[eax+6*4]
	mov dword [byte eax+6*4],addr(newscenarioinit)
	storerelative newscenarioinit.origfn,edi

	patchcode oldaistationrating,newaistationrating,1,1
	patchcode oldplayertype1,newplayertype1,1,1
	patchcode oldplayertype2,newplayertype2,1,2
	patchcode oldplayertype2,newplayertype2,2,2
	patchcode oldplayertype3,newplayertype3,1,1
	patchcode oldplayertype4,newplayertype4,1,1
	patchcode oldaibuilding,newaibuilding,1,1

		// this code must always be patched so that games
		// saved with new graphics don't crash or display wrong
	xor ebp,ebp
.nextvehclass:
	lea eax,[ebp+1]
	stringaddress oldgetvehsprite,eax,4

	mov eax,[edi+3]
	mov [orgspritebases+ebp*4],eax

#if WINTTDX
		// numbers 0 and 2 change place in WINTTDX
	movzx esi,byte [vehclassorder+ebp]
	%define ORDER esi
#else
	%define ORDER ebp
#endif

	movsx eax,byte [orgsetspriteofs+ORDER]
	add eax,edi
	mov [orgsetsprite+ORDER*4],eax

	// can't do a computed storefragment, so do it by hand...
	mov esi,[newspritehandlers+ebp*4]
	mov cl,[newspritehandlersize+ebp]
	rep movsb

	lea eax,[ebp-4]
	add eax,eax
	neg eax

	stringaddress olddisplayveh,1,eax	// find number 1 out of 8-2*ebp

	mov esi,[newdisplayhandlers+ebp*4]
	mov cl,[newdisplayhandlersize+ebp]
	rep movsb

	stringaddress olddisplayveh,1,0		// just find the next one
						// (this one is for exclusive offers/newspaper announcements)

	mov esi,[newdisplayhandlers_np+ebp*4]
	mov cl,[newdisplayhandlersize_np+ebp]
	rep movsb

	lea eax,[ebp+1]
	stringaddress findvehinfo,eax,4

#if WINTTDX
		// numbers 0 and 2 change place in WINTTDX
	movzx esi,byte [vehclassorder+ebp]
#endif
	setbase ebx,specificpropertybase

	mov edi,[edi]
	mov al,[vehbase+ORDER]
	add edi,eax

	mov al,[vehbnum+ORDER]
	imul byte [specificpropertyofs+ORDER]
	cwde

	add eax,edi
	mov [specificpropertybase+ORDER*4],eax

	test ORDER,ORDER
	jnz .nottrains

	add eax,trainpower-AIspecialflag

.nottrains:
	param_call reloc, eax,dword [vehclassspecptr+ORDER*4]

	setbase none
%undef ORDER

	inc ebp
	cmp ebp,4
	jb .nextvehclass

	// a coupl more for planes: the shadow sprite...
	patchcode oldgetothervehsprite,newgetshadowsprite,1,1

	// and the helicopter rotor
	patchcode olddisprotor1,newdisprotor1,1,1
	patchcode olddisprotor2,newdisprotor2,1,2
	patchcode olddisprotor2,newdisprotor2,1,0
	patchcode oldinitrotor,newinitrotor,1,1
	patchcode oldcheckrotor,newcheckrotor,1,2
	patchcode oldstoprotor,newstoprotor,1,1
	add edi,lastediadj+34
	storefragment newadvancerotor
	mov eax,addr(resetplanesprite)
	xchg eax,[orgsetsprite+3*4]
	storerelative resetplanesprite.oldfn,eax

	// and two more for trains: showing the first engine
	// (above codes finds showing the second one)
	patchcode olddisplay1steng,newdisplay1steng,1,2
	patchcode olddisplay1steng,newdisplay1steng_noplayer,1,0

	call infosave

	patchcode olddecidesmoke,newdecidesmoke,1,1
	storerelative showsteamsmoke,edi+lastediadj+11
	mov byte [edi+lastediadj+12],0x20
	mov byte [edi+lastediadj+16],0x30
	mov byte [edi+lastediadj+24],0x40

	patchcode oldsteamposition,newsteamposition,1,0

	patchcode olddecidesound,newdecidesound,1,1

	patchcode oldtunnelsound,newtunnelsound,1,1

	stringaddress olddoessteamelectricsmoke,1,3
	inc byte [edi+1]
	inc byte [edi+8]
	inc byte [edi+15]

	stringaddress olddoessteamelectricsmoke,1,0
	inc byte [edi+8+4*WINTTDX]
	inc byte [edi+15+4*WINTTDX]
	storefragment newsteamamount

	patchcode olddoesdieselsmoke,newdoesdieselsmoke,1,1
	inc byte [edi+lastediadj-9]
	inc byte [edi+lastediadj+13]

	patchcode oldsparkprobab,newsparkprobab,1,1

	patchcode olddieselsmoke,newdieselsmoke,1,1
	stringaddress oldadvancesteamplume,2,2

	mov cl,[moresteamsetting]	// 1x=>7, 2x=>15, 3x=>31 etc.
	shr cl,4
	mov al,4
	shl al,cl
	dec al
	mov [edi],al

.notmoresteam:

	patchcode collectsprites_vehcolor
	multipatchcode oldvehinwindow_color,newvehinwindow_color,8
	multipatchcode oldbuyvehwindow_color,newbuyvehwindow_color,4

	patchcode oldcompanysold,newcompanysold,1,1
	storeaddress findclosecompanywindows,1,1,closecompanywindows
//	storeaddresspointer findcargoweights,1,1,cargoweightfactors

	// following patchcodes are to maintain veh.engineidx
	patchcode oldclearnextunitidx,newcreatevehentry,byte (1+WINTTDX),7

	// buy waggon/2nd engine and attach to train
	patchcode oldattachtoedi,newattachboughtveh,1,3
	patchcode oldattachtoedi,newattachboughtveh,1,0

#if WINTTDX
	patchcode oldattachtoesi,newattachtoesi,1,2
	add edi,lastediadj+88
	storefragment newattachtoedx
#endif

	// move waggon in depot
	patchcode oldattachtoedi,newdetachveh,1,0		 // detach
	mov byte [edi+lastediadj+24],0x40			 // change esi->eax
	add edi,lastediadj-15
	storefragment newnextfirstwagon
	patchcode oldattachtoesi,newinsertveh,1,byte 2-2*WINTTDX // reattach

#if !WINTTDX
	patchcode oldattachtoesi,newattachtoesi,1,0
	add edi,lastediadj+88
	storefragment newattachtoedx
#endif

	multipatchcode oldattachdisasterveh,newattachdisasterveh,7

	patchcode oldsellwagonnewleader,newsellwagonnewleader

	patchcode oldmovedcheckiswaggon,newmovedcheckiswaggonp2,1,1
	add edi,lastediadj-12
	storefragment newmovedcheckiswaggon

	patchcode oldmovedcheckiswaggonui,newmovedcheckiswaggonui,1,1

		// must be in dogeneralpatching not generalfixes
	multipatchcode oldgettrainrunningcost,newgettrainrunningcost,2

		// this fixes a crash with exclusive offers of new wagons
		// better would be to display a different window which
		// does not display speed/power/running cost at all
		// but that's for later
	add edi,lastediadj+13
	storefragment newgettrainrunningcostmultiplier

	add edi,lastediadj+72
	copyrelative doshownewrailveh,5
	storefragment newshownewrailveh

	patchcode oldnewvehavailable,newnewvehavailable,1,1

	// prevent wagons that may appear during gameplay
	// from affecting construction options;
	// also make sure they display the correct type name
	patchcode oldgetrailengclassname,newgetrailengclassname,1,2
	add edi,lastediadj+115
	dec byte [edi]					// MOVZX reg32,r/m16 -> MOVZX reg32,r/m8
	add edi,80
	dec byte [edi]					// same here
	dec byte [edi+85]				// same here
	add edi,104
	storefragment newgetrailengclassname
	dec byte [edi+lastediadj+39]			// and once again
	patchcode oldgetvehclassname,newgetvehclassname,1,1
	patchcode oldupdaterailtype1,newupdaterailtype1,1,1
	changereltarget lastediadj+0x51,addr(gennewrailvehtypemsg)
	patchcode oldupdaterailtype2,newupdaterailtype2,1,1

	stringaddress findclosevehwindow,4,4
	mov ebx,edi
	stringaddress findclosevehwindow,1+WINTTDX,4
	mov byte [edi],0xe9
	lea eax,[ebx-5]
	sub eax,edi
	mov [edi+1],eax
	stringaddress findclosevehwindow,1,0
	mov byte [edi],0xe9
	lea eax,[ebx-5]
	sub eax,edi
	mov [edi+1],eax

	patchcode oldfirstrvarrival,newfirstrvarrival,1,1

	storeaddress findplanttree,1,3,treeplantfn

	stringaddress skipnonprintingchars,1,1
	mov byte [edi],0x7b
	mov byte [edi+0x6f],0x5b
	mov byte [edi+0xde],0x3b
	add edi,byte -0x60
	mov [setcharwidthtablefn],edi

	stringaddress oldtrackbuildcheckvehs
	copyrelative fncheckvehintheway,-4

	storeaddress finddeductvehruncost,1,1,deductvehruncost
	mov eax,[edi+lastediadj+0x39]
	mov [incomequarterstatslist],eax
	storeaddress findaddexpenses,1,1,addexpenses

	storeaddress findmakesubsidy,1,1,subsidyfn
	storeaddress findsearchcollidingvehs,1,1,searchcollidingvehs
	
	storefunctionaddress findMakeTempScrnBlockDesc,1,1,MakeTempScrnBlockDesc
	// find some GUI functions in TTD
	storefunctionaddress findBringWindowToForeground,1,1,BringWindowToForeground
	storefunctionaddress findCreateWindow,1,2,CreateWindow
	storefunctionaddress findWindowClicked,1,1,WindowClicked
	storefunctionaddress findDestroyWindow,1,1,DestroyWindow
	storefunctionaddress findWindowTitleBarClicked,1,1,WindowTitleBarClicked
	storefunctionaddress findDrawWindowElements,1,2,DrawWindowElements
	storefunctionaddress findCreateTextInputWindow,1,1,CreateTextInputWindow
	storeaddress findFindWindow,1,1,FindWindow
	storeaddress findGenerateDropDownMenu,1,1,GenerateDropDownMenu
	storeaddress findCreateTooltip,1,1,CreateTooltip
	storeaddress findRefreshWindowArea,1,1,RefreshWindowArea
	storeaddress findRefreshLandscapeRect,1,1,RefreshLandscapeRect
	storeaddress findScreenToLandscapeCoords,1,1,ScreenToLandscapeCoords
	storeaddress findRefreshLandscapeHighlights,1,1,RefreshLandscapeHighlights
	storeaddress findsetmousetool,1,1,setmousetool
	storeaddress findsetmousecursor,1,1,setmousecursor
	storeaddress findgetmainviewwindow,1,1,GetMainViewWindow
	storeaddress findCreateWindowRelative,1,1,CreateWindowRelative
	storeaddress findsetmainviewxy,1,1,setmainviewxy
	#if WINTTDX
		storefunctionaddress findRefreshWindows,1,6,RefreshWindows
	#else
		storefunctionaddress findRefreshWindows,1,5,RefreshWindows
	#endif
	
	#if WINTTDX
		storeaddress findrvcheckovertake,1,3,rvcheckovertake
	#else
		storeaddress findrvcheckovertake,2,3,rvcheckovertake
	#endif
    
    storeaddress findAddRailFenceSprite1, 1, 1, addrailfence1
    storeaddress findAddRailFenceSprite2, 1, 1, addrailfence2
    storeaddress findAddRailFenceSprite3, 1, 1, addrailfence3
    storeaddress findAddRailFenceSprite4, 1, 1, addrailfence4
    storeaddress findAddRailFenceSprite5, 1, 1, addrailfence5
    storeaddress findAddRailFenceSprite6, 1, 1, addrailfence6
    storeaddress findAddRailFenceSprite7, 1, 1, addrailfence7
    storeaddress findAddRailFenceSprite8, 1, 1, addrailfence8

	mov eax,[ophandler+0x0b*8]
	mov dword [eax+0x10],addr(newclass0Bactionhandler)

	// patch the load and save code - four occurences: LSLL

	// find the addresses needed by the load and save functions
	storeaddress findloadchunkfn,1,1,loadchunkfn
	storeaddress findsavechunkfn,1,1,savechunkfn

	// patch all four occurences of the save/load routine
	patchcode oldloadsave,newload,1,4	// Load savegame
	patchcode oldloadsave,newsave,1,0	// Save
	patchcode oldloadsave,newloadtitle,1,0	// Load title
	patchcode oldloadsave,newload,1,0	// Load predefined game

	// catch the end of a game load, to signal any errors
	stringaddress oldendofload,1,1
	copyrelative endofloadtarget,2
	storefragment newendofload

	patchcode oldendoftitleload,newendoftitleload,2,3

	mov eax,[ophandler+0x0d*8]
	mov esi,addr(newclassdinithnd)
	xchg esi,[eax]
	storerelative newclassdinithnd.oldfn,esi
	call setbasecostmultdefault

	storefunctionaddress findgeneratesoundeffect,1,1,generatesoundeffect

	patchcode oldsettracktypedefault,newsettracktypedefault,1,1
	storeaddress findremovespritefromcache,1,1,removespritefromcache
#if WINTTDX
	storeaddresspointer findspritecacheptr,1,1,spritecacheptr
#endif
	storeaddress oldsavevehorders,1,1,savevehordersfn
	storeaddress oldcopyoldorder,1,1,copyvehordersfn

	multipatchcode oldshowvehstat,newshowvehstat,4

	patchcode cleartile

	// fix some slider bugs
	patchcode oldgetsliderposition,newgetsliderposition,1,1

	// make dropdown-menu's always wide enought to fit contents
	patchcode oldcalcdropdownmenuwidth,newcalcdropdownmenuwidth,1,1
	storefunctionaddress findgettextwidth,gettextwidth
	
	stringaddress findgettunnellength
	dec word [edi]		// TTD always counts one tile too many
	sub edi,7
	mov [gettunnelotherend],edi

	patchcode lookforsamewagontype
	patchcode preparenewveharrentry

		// refresh caches when changing player color
	mov eax,[ophandler+0x0d*8]
	mov edi,[eax+0x10]	// actionhandler
	mov edi,[edi+8]
	mov esi,addr(changecolorscheme)
	xchg esi,[edi]
	storerelative changecolorscheme.origfn,esi

	storeaddress pickrandomtreefn

#if WINTTDX
	stringaddress oldQuitGameKeycode,1,2
	mov byte [edi+1],3
	stringaddress oldQuitGameKeycode,1,0
	mov byte [edi+1],3
	stringaddress oldCheckQuitGameKeycode
	mov byte [edi+1],3
#endif

	// set up table of 64-bit factors of 10
	lea ebx,[ecx+10]	// mov ebx,10 in 3 bytes (ecx is zero)
	lea eax,[ecx+100]
	add ecx,num_powersoften
	push edx
	cdq
	mov edi,powersoften_last
	std

.nextpower:
	mov esi,edx
	mul ebx			// now edx:eax = org. eax*10
	stosd
	xchg eax,esi
	mov esi,edx		// esi = this edx
	mul ebx			// now eax= org. edx*10
	add eax,esi
	stosd
	xchg eax,edx
	mov eax,[edi+8]
	loop .nextpower
	cld

	pop edx

	stringaddress findCheckForVehiclesInTheWay
	storeaddress CheckForVehiclesInTheWay // Stores the address of this
	ret

global newsavename
newsavename:
	// set default file name
	patchcode oldsavedefaultname,newsavedefaultname,1,1
	mov word [edi+lastediadj-6],0x6890	// nop; push imm32; to push address
	ret

// shares code fragments
global patchusenewnonstop
patchusenewnonstop:
	patchcode nonstop1old,nonstop1new,1,1
	patchcode nonstop2old,nonstop2new,1,1
	patchcode showordertype
	ret

global patcheternalgame
patcheternalgame:
	patchcode oldprintdate,newprintdate,1,3
	patchcode oldprintdate,newprintdate,1,0
	mov edi,[getymd]
	lea eax,[edi+getymd.fullyearentryoffset]
	mov [getfullymd],eax
	storefragment newgetymd
	patchcode oldisnewyear,newisnewyear,1,1
	patchcode oldgetdisasteryear,newgetdisasteryear,1,1
	multipatchcode oldgetvehintroyear,newgetvehintroyear,4
	stringaddress getfinanceswindowyears,1,1
#if WINTTDX
	mov eax,[getymd]				// WinTTD calls a jump to getymd, not getymd itself
	sub eax,edi					// we have to calculate [getymd]-edi, storerelative can't do it
	add eax,byte getymd.wordyearentryoffset-4	// so we do it manually
	mov [edi],eax
#else
	add dword [edi],byte getymd.wordyearentryoffset	// direct call -- we can save on space
#endif
	stringaddress reccompanylaunchyear,1,1
#if WINTTDX
	mov eax,[getymd]				// same here
	sub eax,edi
	add eax,byte getymd.wordyearentryoffset-4
	mov [edi],eax
#else
	add dword [edi],byte getymd.wordyearentryoffset
#endif
	patchcode oldgetgraphstartyear,newgetgraphstartyear,1,1
	multipatchcode oldshowyearbuilt,newshowyearbuilt,4
	ret

patchsharedorders:
	patchcode oldshowendoforders,newshowendoforders,1,1
	multipatchcode oldadjustorders,newadjustorders,2
	patchcode olddeletepressed,newdeletepressed,1,1
	patchcode olddeletevehschedule,newdeletevehschedule,1,1
	ret

global patchsignals
patchsignals:
	storeaddress oldstartsignalsloop,1,1,startsignalloopfn
	testmultiflags presignals,extpresignals
	jz near .nopresignals
	storefragment newstartsignalsloop
	add edi,byte 0x44+lastediadj

	storefragment newsignalsloop
	mov eax,[edi+18+lastediadj]
	mov dword [signalchangeopptr],eax

	add edi,byte 0x9d-0x44+lastediadj
	storefragment newsignalsloopend

	copyrelative fnredrawsquare,lastediadj-15

	patchcode oldnewsignalsetup,newnewsignalsetup,1,1
	patchcode oldremovesignal,newremovesignal,1,1
	mov byte [edi+0xa],-1	// disarm the AND
	patchcode oldremovesignalcost,newremovesignalcost,1,1
	patchcode olddemolishtrackcall,newdemolishtrackcall,1,1

	patchcode oldenterdepot,newenterdepot,1,1

	or byte [newgraphicssetsenabled],1 << 4
.nopresignals:
	ret
