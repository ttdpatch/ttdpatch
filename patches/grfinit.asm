//
// GRF initialization code
// also does some other, non-grf vehicle initialization
// (such as unimaglev conversion)
//

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <vehtype.inc>
#include <grf.inc>
#include <veh.inc>
#include <newvehdata.inc>
#include <curr.inc>
#include <industry.inc>
#include <bitvars.inc>
#include <misc.inc>
#include <ptrvar.inc>
#include <patchdata.inc>
#include <house.inc>
#include <font.inc>
#include <textdef.inc>

#include <vehspecificprops.inc>

extern SwapDockWinPurchaseLandIco,SwapLomoGuiIcons,activatedefault,activatetype
extern addnewtemperatecargo,basecostmult,callbackflags
extern cargoid,cargotypes,catenaryspritebase,clearhousedataids
extern clearindustiledataids,clearstationgameids,copyorghousedata,costrailmul
extern costrailmuldefault,currsymsafter,currsymsbefore,currtownname
extern defaultindustriesofclimate,defcargoid,defcargotypes,defclimatecargobits
extern deftwocolormaps,defvehsprites,desynchtimeout,dummyspriteblock
extern elrailsprites.trackicons,enhancegui_newgame
extern euroglyph,exsresetspritecounts,externalvars
extern findcurrtownname,gettexttableptr,grferror,grfidlistnum,grfresources
extern grfstat_titleclimate,grfvarreinitstart,industileoverrides,initisengine
extern initrailvehsorttable,initveh2,isengine,isfreight,isfreightmult,lastextrahousedata
extern lastextraindustiledata,lastperfcachereset,lasttreepos
extern monthlyengineloop,morecurropts,newgraphicsspritebases,newspritedata
extern newspritenum,newttdsprites,newvehdata,newvehicles,numactsprites
extern numgrfvarreinit,numnewgraphicssprites,numsiggraphics,numstationclasses
extern numstationsinclass,oldplanerefitlist,oldshiprefitlist
extern overrideembeddedsprite,patchflags,procallsprites
extern procallsprites_noreset,procallsprites_replaygrm,recalchousecounts
extern reloadspriteheaders,resolvecargotranslations,restoreindustrydata
extern rvpowerinit,savedvehclass,saveindustrydata,setactivegrfs
extern setbasecostmult,setbridgespeedlimits,setcargoclasses
extern setcharwidthtablefn,setdefaultcargo,soundoverrides
extern specificpropertybase,specificpropertyofs
extern spritecacheptr,spriteerror
extern stationclassesused,stationidgrfmap,stationpylons,temp_snowline
extern textcolortablewithcompany,undogentextnames,unimaglevmode
extern updatecurrlist,veh2ptr,vehbnum,vehsorttable,setwillbeactive
extern vehtypedataptr,numpredefstationclasses,spritecache,editTramMode
extern cargobits,resetourtextptr,restorecurrencydata,applycurrencychanges
extern languagesettings,languageid,setdeflanguage,resetcargodata
extern disabledoldhouses,enhancetunnelshelpersprite
extern initglyphtables,setcharwidthtables,fonttables,hasaction12
extern snowlinetableptr,getymd,restoresnowytrees,snowytemptreespritebase
extern applysnowytemptrees,alwaysminusone
extern updateTramStopSpriteLayout,setelrailstexts,gettextintableptr
extern gettextandtableptrs,defaultstylename,fixupvehnametexts
extern origlanguageid
extern ChangeCoastSpriteTable
extern grfmodflags
extern ResizeOpenWindows, depotscalefactor
extern clearairportdata
// Custom RV stop sprite support.
extern updateRVStopSpriteLayout


// New class 0xF (vehtype management) initialization handler
// does additional things before calling the original function
//
// Note: this is called both for random games and games started from a
//	 scenario, which might already have valid TTDPatch data, so don't
//	 initialize those here, but rather for random games above and
//	 for loading savegame data
//
// in:	ax=0 don't do initialization
//	ax=1 do initialization (new game/scenario)
//	ax=0x100 called by Cht: ResetVehicles/Graphics/Grfstat apply button
// safe:everything
global newvehtypeinit
newvehtypeinit:
	or ax,ax		// the original handler does the same
	jnz .start
	ret

.start:
	push eax
	push es
	push ds
	pop es
	mov [activatetype],ah

	testflags fifoloading
	jnc .nosavefifo
	
	test ah, ah
	jz .nosavefifo

	extcall buildfifoidx	// inforeset destroys the FIFO linked lists in veh2, so copy that data to veh
	call inforeset		// reset all vehtype data
	call initveh2
	extcall buildloadlists	// ... and restore it
	jmp short .donereset
.nosavefifo:
	call inforeset		// reset all vehtype data
	call initveh2

.donereset:
	mov [activatedefault],al	// new game -> activate all graphics
					// but not for Cht: ResetVehicles
	test ah,ah
	jnz .dontresetgraphics
	mov byte [editTramMode], 0h
	mov al,[grfstat_titleclimate]
	cmp al,[climate]
	je .usegrflist
	and dword [grfidlistnum],0
.usegrflist:
	xor eax,eax
	mov edi,stationidgrfmap
	lea ecx,[eax+256/4]
	rep stosd
	extern persgrfdata
	mov edi,persgrfdata
	add ecx,persgrfdatastruc_size/4
	rep stosd

.dontresetgraphics:
	extern resetgrm
	call resetgrm		// reset house and industry substitions

	extcall makerelations

	cmp byte [activatedefault],0
	jne .notnewgame2

	extern updategamedata
	call updategamedata

.notnewgame2:
	call infoapply		// and apply newgrf and other modifications

	pop es

	// use original random seed, if any
	mov eax,[vehrandseed]
	test eax,eax
	jnz .gotvehrandseed

	mov eax,[randomseed2]
	mov [vehrandseed+4],eax
	mov eax,[randomseed1]
	mov [vehrandseed],eax

.gotvehrandseed:
	// set randomseed1/2 to what was used originally
	xchg eax,[randomseed1]
	push eax
	mov eax,[vehrandseed+4]
	xchg eax,[randomseed2]
	push eax

	mov al,1
	mov ebp,dword -1
ovar .oldfn,-4,$,newvehtypeinit
	call ebp

	// and restore randomseed1/2 afterwards
	pop eax
	mov [randomseed2],eax
	pop eax
	mov [randomseed1],eax

	// now do the persistent engines thing
	call monthlyengineloop

	cmp dword [spriteerror],0
	je .done

	call grferror

.done:
	mov byte [activatetype],1
	pop eax
	test al,al
	jz .notnewgame

	call enhancegui_newgame
// update town name GRFID and setid in the landscape array,
// or zero them for old styles
	push eax
	mov eax,[currtownname]
	or eax,eax
	jnz .havename

	mov [landscape3+ttdpatchdata.townnamegrfid],eax
	mov [landscape3+ttdpatchdata.townnamesetid],al
	jmp short .townnameok

.havename:
	mov ebx,[eax+namepartlist.grfid]
	mov [landscape3+ttdpatchdata.townnamegrfid],ebx

	mov bl,[eax+namepartlist.setid]
	mov [landscape3+ttdpatchdata.townnamesetid],bl

.townnameok:
	pop eax

.notnewgame:
	test ah,ah
	jz .notresetgraphics
	testflags newtownnames
	jnc .notownnames
// Graphics settings are modified - the current town name style may have become
// unavailable - find it again and recalc town name positions in case they did
	call findcurrtownname
	pusha
	mov ebp,[ophandler+3*8]
	mov ebx,6
	call [ebp+4]
	popa
.notownnames:
.notresetgraphics:
	ret



//
// The following procs deal with saving and restoring some of TTD's internal
// data, including vehicle info.  It is saved once at the initialization of
// the patch, and restored before a new game is started, the scenario editor
// is opened or a game is loaded.
//
// Then, after loading the game, the new vehicle data from .grf files is
// applied, and the postinfoapply proc is called to let the patches do their
// work.
//


struc ttdvehinfo
	.vehtypedata:	resb totalvehtypes*vehtypeinfo_size		// vehtypeinfo structs
	.traindata:	resb NTRAINTYPES*0x11 // spectraindata_totalsize	// train data
	.rvdata:	resb NROADVEHTYPES*0x0b // specrvdata_totalsize		// road veh data
	.shipdata:	resb NSHIPTYPES*0x09 // specshipdata_totalsize		// ship data
	.aircraftdata:	resb NAIRCRAFTTYPES*0x0b // specplanedata_totalsize	// aircraft data
	.vehtypenames:	resb 256*4					// default vehtype name ptrs
endstruc

uvarb ttdvehinfobackup, ttdvehinfo_size

// As a special case, if unifiedmaglev is on, railway vehicle types may have to be converted
// depending on unimaglevmode and the electrifiedrail flag.  Unlike all the other actions,
// this conversion must not be applied more than once.
// To keep the vehtype data consistent also when saved and loaded via the extra type=0 chunk
// (see loadsave.asm) we keep a secondary backup of the data just before the conversion.

uvard vehtypedataconvbackupptr	// 0 if the area is not used (see patches.ah/patchunifiedmaglev)


var specificpropertylistsizes, dd spectraindata_totalsize,specrvdata_totalsize,specshipdata_totalsize,specplanedata_totalsize

global specvehdatalength
specvehdatalength equ \
 totalvehtypes*vehtypeinfo_size + \
 NTRAINTYPES*spectraindata_totalsize + \
 NROADVEHTYPES*specrvdata_totalsize + \
 NSHIPTYPES*specshipdata_totalsize + \
 NAIRCRAFTTYPES*specplanedata_totalsize

// in:	EBX=class, 0..3 for railway..aircraft
// out:	ESI->property base
//	ECX=EAX=total length
global getspecificpropertyarea
getspecificpropertyarea:
	mov esi,[specificpropertybase+ebx*4]
	mov eax,[specificpropertylistsizes+ebx*4]
	mul byte [vehbnum+ebx]
	movzx ecx,ax
	ret


proc copyinfo
	arg direction
	slocal src_dst,dword,2

	_enter

	mov edx,[%$direction]

	mov edi,ttdvehinfobackup
	mov [%$src_dst],edi
	mov [%$src_dst+4],edi

	mov eax,[vehtypedataptr]
	mov [%$src_dst+edx*4],eax

	mov ecx,totalvehtypes*vehtypeinfo_size
	call .docopy

	xor ebx,ebx
.nextvehtype:
	call getspecificpropertyarea
	mov [%$src_dst+edx*4],esi

	call .docopy

	inc ebx
	cmp ebx,4
	jb .nextvehtype

	mov ah,0x80
	call gettexttableptr
	mov [%$src_dst+edx*4],eax
	mov ch,4
	call .docopy
	_ret

.docopy:
	mov esi,[%$src_dst]
	mov edi,[%$src_dst+4]
	rep movsb
	mov [%$src_dst],esi
	mov [%$src_dst+4],edi
	ret
endproc

	// save all TTD data that is modified in any of preinfoapply,
	// grfinfoapply or postinfoapply
global infosave
infosave:
	pusha

	param_call copyinfo, 0

	// save default sprite ids in a convenient table
	xor ebx,ebx
	mov edi,defvehsprites

.nextvehtype:
	mov esi,[specificpropertybase+ebx*4]
	movsx eax,byte [specificpropertyofs+ebx]
	movzx ecx,byte [vehbnum+ebx]
	imul eax,ecx
	sub esi,eax
	rep movsb
	inc ebx
	cmp ebx,4
	jb .nextvehtype

	testflags newindustries
	jnc .dontsaveinddata
	call saveindustrydata	// in newindu.asm
.dontsaveinddata:
	popa
	ret


	// reset the vehicle data
	// called before loading a new game
global inforeset
inforeset:
	pusha
	param_call copyinfo, 1
	call initttdpatchdata
	call undogentextnames
	extcall bridgeresettodefaults
	call setwagonmaxage
	popa
	ret


	// apply the new info from .grfs
	// called after loading a new game
global infoapply
infoapply:
	pusha
	call preinfoapply
	call setactivegrfs
	mov dword [numactsprites],baseoursprites
	call exsresetspritecounts

	extern grfstage
	mov eax,PROCALL_RESERVE
	mov byte [grfstage+1],1
	call procallsprites
	mov byte [grfstage+1],0
	call postinforeserve

	// reset "(in)active" to "will be (in)active"
	call setwillbeactive

	mov byte [procallsprites_replaygrm],1
	mov byte [procallsprites_noreset],1
	mov eax,PROCALL_ACTIVATE
	mov byte [grfstage+1],2
	call procallsprites
	mov byte [grfstage+1],0

	call postinfoapply
	popa
	ret

	// at this point, only newcargo action 0, action D and action E are processed
global postinforeserve
postinforeserve:
	call resolvecargotranslations
	mov al,[origlanguageid]
	mov [languageid],al
	call setdeflanguage
	mov eax,[languagesettings]
	cmp eax,-1
	je .nonewsetting
	mov [languageid],al
.nonewsetting:
	ret

	// reset each of the new TTDPatch vehicle properties
global initttdpatchdata
initttdpatchdata:
	mov dword [externalvars+4*3],climate
	mov dword [externalvars+4*0x12],gamemode
	mov dword [deftwocolormaps],775
	mov ebx,[vehrandseed]
	mov edx,[vehrandseed+4]
	mov edi,newvehdata
	mov ecx,newvehdatastruc_size/4
	xor eax,eax
	rep stosd
	mov dword [newvehdata+newvehdatastruc.flags],newvehdata_flags_init
	mov [vehrandseed],ebx
	mov [vehrandseed+4],edx

	// initialize newvehdata.loadamount
	mov edi,loadamount
	mov al,5
	mov cl,NTRAINTYPES+NROADVEHTYPES
	rep stosb
	mov al,10
	mov cl,NSHIPTYPES
	rep stosb
	mov al,20
	mov cl,NAIRCRAFTTYPES
	rep stosb

	mov al,0

	// clear newgrf data
	mov edi,grfvarreinitstart
	mov ecx,numgrfvarreinit
	rep stosd

	// clear action 5 data
	mov esi,newgraphicsspritebases
	mov ecx,numnewgraphicssprites

.nextaction5ent:
	lodsd
	test eax,eax
	jle .noaction5ent
	or word [eax],byte -1
.noaction5ent:
	loop .nextaction5ent

	mov ecx,numnewgraphicssprites

.nextaction5num:
	lodsd
	test eax,eax
	jle .noaction5num
	and dword [eax],0
.noaction5num:
	loop .nextaction5num

	// train smoke type and vehsorttable
	xor eax,eax
	mov edi,traintractiontype
	mov ebx,defvehsprites
	mov esi,vehsorttable
	mov cl,NTRAINTYPES
.setnexttrain:
	mov [esi],al
	xlatb
	stosb
	lodsb		// restore unXLATed al and increase ESI
	inc eax
	loop .setnexttrain

	mov cl,256-NTRAINTYPES
	mov edi,esi
.setnextother:
	stosb
	inc eax
	loop .setnextother

	// initialize the train and road vehicle TE coefficients
	mov edi,traintecoeff
	mov al,0x4c	// 0.3
	mov cl,NTRAINTYPES+NROADVEHTYPES
	rep stosb

	// initialize road vehicle power and weight
	mov esi,rvpowerinit
	mov edi,rvpowers
.initnextset:
	mov cl,7
	rep movsb	// first the busses
	mov cl,27
	lodsd		// then the sets of 3 trucks each
.initnexttriple:
	stosd		// write 4 bytes
	dec edi		// then set edi back so only 3 bytes are stored
	loop .initnexttriple
	test eax,eax
	js .initnextset

	// initialize the sprite translation table
	mov edi,newttdsprites
	xor eax,eax
	mov ecx,totalsprites
.nextsprite:
	stosw
	inc eax
	loop .nextsprite

	testflags generalfixes
	jnc .dontswap

	// swap monorail and maglev tunnels; #2435 and #2436
	rol dword [newttdsprites+2435*2],16

.dontswap:
	xor eax,eax
	mov ecx,9
	mov edi,lasttreepos
	rep stosw

	// also clear various TTDPatch arrays
	mov edi,[veh2ptr]
	imul ecx,[newvehicles],byte veh2_size
	rep stosb	// al is still zero

	mov edi,[veh2ptr]
	mov ecx,[newvehicles]
.nextaircraft:
	mov dword [edi+veh2.curraircraftact],AIRCRAFTACT_UNKNOWN
	add edi, veh2_size
	loop .nextaircraft

	and word [lastperfcachereset],0		// this will be simply ignored if the corresponding switches aren't set
	mov byte [savedvehclass],0
	testflags newhouses
	jnc .dontcopydata
	call copyorghousedata			// in newhouse.asm
.dontcopydata:

	//testflags newindustries
	//jnc .dontcopyindus
//	call copyorgcargodata
//.dontcopyindus:

	xor eax,eax
	testflags electrifiedrail
	adc eax,eax

	mov eax,[costrailmuldefault+eax*4]
	mov [costrailmul],eax

	// reset station pylons
	mov edi,stationpylons
	mov al,00001111b	// types 0..3 have pylons, 4..7 don't
	mov ch,1
	rep stosb

	mov dword [numstationclasses],numpredefstationclasses

	// reset industries available as grf resources
	movzx ebx,byte [climate]
	mov edi,grfresources+256*4
	lea esi,[defaultindustriesofclimate+ebx*8]
	xor ecx,ecx
	mov cl,NINDUSTRYTYPES
.nextindres:
	bt [esi],ecx
	sbb eax,eax
	and eax,[dummyspriteblock]
	stosd
	inc ecx
	cmp ecx,NINDUSTRYTYPES
	jb .nextindres

	// after this follow the cargo IDs
	// first mark the first 12 as in use
	mov cl,12
	mov eax,[dummyspriteblock]
	rep stosd

	// then clear 0B in temperate and 08 in arctic
	mov cl,0x0B
	cmp ebx,1
	ja .gotcargores
	jb .markcargo
	mov cl,0x08
.markcargo:
	and dword [edi-12*4+ecx*4],0
.gotcargores:
	add edi,4*(32-12)	// skip remaining cargos, always available

	// now mark the bits that are in use
	xor ecx,ecx
.nextcargobit:
	bt [defclimatecargobits+ebx*4],ecx
	sbb eax,eax
	and eax,[dummyspriteblock]
	stosd
	inc ecx
	cmp ecx,32
	jb .nextcargobit


	// reset base cost multipliers
	or edx,byte -1
	call setbasecostmult
	mov edi,basecostmult
	mov al,8
	mov cl,49
	rep stosb

	// reset freight train bits
	testflags freighttrains	// by default everything 
	sbb eax,eax		// unless freighttrains is off
	mov edx,~0101b		// default freight types: all but pass+mail
	and eax,edx		// and remove pass+mail
	mov [isfreightmult],eax	// set to 0 if freight trains off, else default freight types
	mov [isfreight],edx	// set to default freight types

	and dword [snowlinetableptr],0
	call restoresnowytrees

	// also clear all TTDPatch overridden graphics
	// (i.e. those that have the immutable flag set)
	// that way TTD will use its own graphics again
	// in the scenario/savegame currently being loaded

	mov ebx,[newspritedata]
	mov ebp,[newspritenum]
	imul edx,ebp,19
	add edx,ebx

	xor eax,eax
	xor edi,edi

.checknextsprite:
	cmp [edx+edi],al		// check immutable flag (al is zero)
	je .ttdsprite

	mov [edx+edi],al		// remove immutable flag
	mov dword [ebx+edi*4],eax	// remove from "cache" (it wasn't actually in the cache)

	// and restore sprite info
	pusha
	call reloadspriteheaders
	popa

.ttdsprite:
	inc edi
	cmp edi,totalsprites
	jb .checknextsprite

	// mark the rest of the sprites as present and immutable
	// all the way up to number 16384, so that if TTD "accidentally"
	// accesses such a sprite, it will only show the wrong one and
	// not try to load it from trg1.grf

#if WINTTDX
	mov eax,[spritecacheptr]
	test eax,eax
	jle .done

	mov eax,[eax]
#else
	mov eax,[spritecache]
#endif

	test eax,eax
	jle .done

	add eax,5	// use first entry from sprite cache instead, whatever that is

.setnextsprite:
	cmp edi,ebp
	jb .dosetsprite

.done:
	ret

.dosetsprite:
	mov [ebx+edi*4],eax	// set sprite data cache pointer
	mov byte [edx+edi],1	// set immutable flag

	inc edi
	jmp .setnextsprite


	// things to do before the .grfs modify the vehicles
preinfoapply:
	mov edx,patchflags
	testflagbase edx

	call resetourtextptr

	call initisengine

	// set TTD's default refit cargos for trains and planes
	// also set the default train refit cost
	mov edi,newshiprefit
	xor ecx,ecx
	mov cl,NSHIPTYPES
	mov eax,oldshiprefitlist
	rep stosd

	xor edi,edi
	mov cl,NTRAINTYPES
//	mov esi,[enginepowerstable]

.nexttrainveh:
	bt [isengine],edi
	sbb eax,eax
	and eax,oldplanerefitlist	// now eax=0 (wagon) or oldplanerefitlist (engine)
	mov [newtrainrefit+edi*4],eax

	mov al,[traincost+edi]
	shr al,1	// default refit cost is 25% of purchase cost, rounded up
	adc al,0	// (will be divided by 2 again later, so only shr al,1)
	mov [trainrefitcost+edi],al
	inc edi
	loop .nexttrainveh

	mov edi,newplanerefit
	mov cl,NAIRCRAFTTYPES
	mov eax,oldplanerefitlist
	rep stosd

	// reset the callback list, must be zero unless grf actively sets it
	mov edi,callbackflags
	mov cl,256/4
	xor eax,eax
	rep stosd

	// set the list of vehicles that never expire
	mov esi,eternalvehicleslist
	mov edi,[vehtypedataptr]
	testmultiflags persistentengines
	jnz .nexteternalset
	mov esi,eternalvehicleslistwagons
.nexteternalset:
	xor eax,eax
	lodsb
	mov ecx,eax
	jecxz .seteternaldone
	lodsb
	imul ebx,eax,byte vehtypeinfo_size
	lodsb
	imul eax,byte vehtypeinfo_size
	add eax,edi
.nexteternalveh:
	mov byte [eax+vehtypeinfo.basedurphase2],0xff
	add eax,ebx
	loop .nexteternalveh
	jmp .nexteternalset

.seteternaldone:

	// *********

	// reset the railway vehicle sort table so that waggons will end up at the end of the list, after engines
	// (used in the New Vehicles windows)
	testmultiflags unifiedmaglev,newtrains
	jz .notrainsorting

.trainsorting:
	call initrailvehsorttable

	// *********

.notrainsorting:

#if 0
	// make paper wagon and trucks available in temperate with moreindustriesperclimate
	testmultiflags moreindustriesperclimate
	jz .nopaperintemperate

	cmp byte [climate],0
	jne .nopaperintemperate

	// doing this manually instead of using the newgrf action 0 mechanism
	// because this should happen even if newtrains/newrvs is off
	mov eax,[vehtypedataptr]
	mov bl,1
	or [eax+39*vehtypeinfo_size+vehtypeinfo.climates],bl	// rail
	or [eax+69*vehtypeinfo_size+vehtypeinfo.climates],bl	// monorail
	or [eax+101*vehtypeinfo_size+vehtypeinfo.climates],bl	// maglev

	lea eax,[eax+(NTRAINTYPES+43)*vehtypeinfo_size]
	or [eax+0*vehtypeinfo_size+vehtypeinfo.climates],bl
	or [eax+1*vehtypeinfo_size+vehtypeinfo.climates],bl
	or [eax+2*vehtypeinfo_size+vehtypeinfo.climates],bl

	mov eax,[specificpropertybase+0*4]
	lea eax,[eax+(0x15-8)*NTRAINTYPES+39]
	mov bl,11
	mov [(eax-39)+39],bl
	mov [(eax-39)+69],bl
	mov [(eax-39)+101],bl

	mov eax,[specificpropertybase+1*4]
	lea eax,[eax+(0x10-8)*NROADVEHTYPES]
	mov [eax+43],bl
	mov [eax+44],bl
	mov [eax+45],bl

	// *********

.nopaperintemperate:
#endif

	testflags newindustries
	jnc .dontrestoreinddata
	call restoreindustrydata	// in newindu.asm
.dontrestoreinddata:

	mov byte [snowline],0x38
	testflags tempsnowline
	jnc .dontrisesnow
	cmp byte [climate],0
	jne .dontrisesnow
	mov byte [snowline],0xff

.dontrisesnow:
	movzx eax,byte [snowline]
	mov [temp_snowline],eax

	testflagbase none

	movzx ecx,byte [climate]
	mov eax,[defclimatecargobits+ecx*4]
	mov [cargobits],eax

	imul esi,ecx,32
	add esi,defcargotypes
	mov edi,cargotypes
	mov ecx,32/4
	rep movsd

	mov esi,defcargoid
	mov edi,cargoid
	mov cl,32/4
	rep movsd

	xor eax,eax
	mov edi,soundoverrides
	mov cl,73
	rep stosd

	// set cargo classes for the default cargos
	// using the action 0 handler for that

	xor ebx,ebx	// start with first cargo
	movzx esi,byte [climate]
	shl esi,3
	lea esi,[defaultcargoclasses+esi*3]
	xor eax,eax
	lea ecx,[eax+12]
	call setcargoclasses

	// set global cargo names for the default cargos
	movzx esi,byte [climate]
	shl esi,4
	lea esi,[defaultglobalcargolabels+esi*3]
	mov edi,globalcargolabels
	mov cl,12
	rep movsd
	or eax,byte -1
	mov cl,NUMCARGOS-12
	rep stosd

	testflags morecurrencies
	jnc .nocurrs
	call restorecurrencydata
.nocurrs:

	testflags newcargos
	jnc .nonewcargos
	call resetcargodata
.nonewcargos:
	cmp byte [hasaction12],0
	je .nounicode
	call initglyphtables
.nounicode:

	or dword [languagesettings], byte -1
	btr dword [grfmodflags], 3 // Clear this flag so that it needs the actual grf to be active (32px depots)

	testflags newairports
	jnc .noclearairportdata
	call clearairportdata
.noclearairportdata:

	call bridgeresettodefaults

	ret

// set default wagons to have a max age of FF (available forever)
setwagonmaxage:
	call initisengine
	mov esi,[vehtypedataptr]
	xor ecx,ecx
.setnext:
	bt [isengine],ecx
	jc .nextveh
	mov byte [esi+vehtypeinfo.basedurphase2],0xff
.nextveh:
	add esi,0+vehtypeinfo_size
	inc cl
	jnz .setnext
	ret
	
	

var cargowagonspeedlimit, db 0,96,0,96,80,120,96,96,96,96,120,120

uvarw firsttracktypeengine,3

	// action 0 data for cargo prop 16
	// one for each climate; must be exactly 12 words large
var defaultcargoclasses
	dw 1<<0,1<<4,1<<1,1<<6,1<<5,1<<2,1<<4,1<<5,1<<4,1<<5,1<<3,1<<5		// Temperate
	dw 1<<0,1<<4,1<<1,1<<6,1<<5,1<<2,1<<4,1<<5,1<<4,1<<5,1<<3,(1<<2)+(1<<7)	// Arctic
	dw 1<<0,1<<6,1<<1,1<<6,(1<<4)+(1<<7),1<<2,1<<4,1<<5,1<<4,1<<6,1<<3,(1<<2)+(1<<7) // Tropic
	dw 1<<0,1<<4,1<<1,1<<5,1<<5,1<<2,1<<4,1<<6,1<<4,1<<5,1<<6,1<<5		// Toyland

var defaultglobalcargolabels
	dd "PASS","COAL","MAIL","OIL_","LVST","GOOD","GRAI","WOOD","IORE","STEL","VALU",  -1
	dd "PASS","COAL","MAIL","OIL_","LVST","GOOD","WHEA","WOOD",  -1  ,"PAPR","GOLD","FOOD"
	dd "PASS","RUBR","MAIL","OIL_","FRUT","GOOD","MAIZ","WOOD","CORE","WATR","DIAM","FOOD"
	dd "PASS","SUGR","MAIL","TOYS","BATT","SWET","TOFF","COLA","CTCD","BUBL","PLST","FZDR"

var oslashglyphs
	incbin "embedded/oslash.dat"

	// things to do after the .grfs modify the vehicles
postinfoapply:
	cmp byte [gamemode],0
	jne .nottitle
	mov byte [grfstat_titleclimate],-1
.nottitle:
	CHECKMEM

	mov al,[temp_snowline]
	mov [snowline],al

	testflags tempsnowline
	setc al
	or al,[climate]
	dec al
	jnz .nosnow

	mov ecx,[snowlinetableptr]
	test ecx,ecx
	jz .notable

.update:
	mov ax,[currentdate]
	call [getymd]
	shl edx,5
	add edx,ebx
	mov al,[ecx+edx]
	mov [snowline],al
	jmp short .havesnow

.nosnow:
	// if snow is disabled, set the snow line height to FFh to make GRF coder's life easier
	mov byte [snowline],0xFF

.notable:
.havesnow:
	// make sure all train vehicles have a valid running cost base
	xor eax,eax
.nextrcostbase:
	cmp dword [trainrunningcostbase+eax*4],0
	jne .rcostbaseok
	mov dword [trainrunningcostbase+eax*4],alwaysminusone
.rcostbaseok:
	inc eax
	cmp eax,NTRAINTYPES
	jb .nextrcostbase

	// make bitmask out of new signal sprite number

	mov eax,[numsiggraphics]
	shr eax,4
	add eax,eax		// eax=(numsiggraphics>>3)&~1 = number of signal blocks
	mov [numsiggraphics],eax

	// for the newstations code, make the standard TTD station available
	// (eventually it might be possible to turn this off)

	bts dword [stationclassesused],0
	inc byte [numstationsinclass+0]

	//enhancegui - Transparent Station Signs

	testflags enhancegui
	jnc .donewithnewcolortable

	mov cl,0x2B
	mov esi, textcolortablewithcompany
	call overrideembeddedsprite
.donewithnewcolortable:

	testflags enhancetunnels
	jnc .doneenhancetunnels

	mov cx, 0
	mov esi, enhancetunnelshelpersprite
	call overrideembeddedsprite

.doneenhancetunnels:
	testmultiflags generalfixes
	jz .nooslash

	mov esi, oslashglyphs
	mov cl,10
	call overrideembeddedsprite
	mov cl,10
	call overrideembeddedsprite

.nooslash:
	testmultiflags morecurrencies
	jz .noeuro

		// add Euro glyph unless it's there already
		// or if the Euro is not to be introduced
	test byte [morecurropts],morecurrencies_noeuro
	jnz .noeuro

	mov esi,euroglyph
	mov cl,10
	call overrideembeddedsprite
	mov cl,10
	call overrideembeddedsprite
	mov cl,10
	call overrideembeddedsprite

.noeuro:
	cmp byte [hasaction12],0
	je .nounicode

	call setcharwidthtables
	mov ebx,[fonttables+0x20*4]	// Euro character is U+20AC
	test ebx,ebx
	jz .noeuroglyph

	cmp word [ebx+0xAC*fontinfo_size+fontinfo.sprite],0
	je .noeuroglyph
	jmp short .haveeurogrf

.nounicode:
	// .grfs or the above may have modified the font, calculate the new width
	push es
	call [setcharwidthtablefn]
	pop es

	// set euro currency symbol to EUR unless Euro glyph is available
	cmp byte [charwidthtables+0x7e],1
	ja .haveeurogrf

.noeuroglyph:
	mov dword [currsymsbefore+CURR_EURO*4],"EUR "
	mov dword [currsymsafter+CURR_EURO*4]," EUR"

.haveeurogrf:
	mov edx,patchflags
	testflagbase edx

	// *********

	testmultiflags newbridgespeeds
	jz .nonewbridgespeeds

.donewbridgespeeds:
	call setbridgespeedlimits

	// *********

.nonewbridgespeeds:
	extcall postbridgeapply

	call initisengine
	call setdefaultcargo

	// *********

	testmultiflags electrifiedrail
	jz near .typeconversion

	call setelrailstexts

	movzx ebx,byte [unimaglevmode]

	// change build menu sprites and cursors

	mov edi,newttdsprites+1255*2
	mov ecx,4

	movzx eax,word [catenaryspritebase]
	test ax,ax
	jg .haveelrailgrf

	mov eax,0x800004e3	// without graphics, set el.rails to normal railway (1251=0x4e3)
	jmp short .next1	// bit 31 marks it such for later

.haveelrailgrf:
	add eax,elrailsprites.trackicons

	// set monorail build icon to electrified rail
.next1:
	stosw
	inc eax
	loop .next1

	xchg eax,esi

	// set maglev to unimaglev mode
	lea eax,[1251+ebx*4]
	mov cl,4
.next2:
	stosw
	inc eax
	loop .next2

	// somehow last two icons are reverse...
	// need to fix that if unimaglev mode == 1
	cmp ebx,1
	jne .notmrmode

	rol dword [edi-4],16

.notmrmode:
	push edx
	testflagbase none

	lea edx,[eax+8]

	add edi,byte (1267-1263)*2

	// set build cursors
	mov cl,4
	xchg eax,esi

	test eax,eax
	jns .next3

	mov ax,1263
.next3:
	stosw
	inc eax
	loop .next3

	xchg eax,edx
	mov cl,4
.next4:
	stosw
	inc eax
	loop .next4

	// set tunnel icon
	xchg eax,edx

	test eax,eax
	jns .next5

	mov ax,2430

.next5:
	add edi,(2431-1275)*2
	stosw
	inc eax
	mov [edi+4*2],ax

	lea eax,[2430+ebx]
	stosw
	add eax,4
	mov [edi+2*2],ax

	pop edx
	testflagbase edx

	// *********

.typeconversion:
	// Convert between electric, monorail and maglev railway vehicles depending on flags

	// make a backup of the vehtype data if necessary
	mov esi,[vehtypedataptr]
	xor ecx,ecx
	mov edi,[vehtypedataconvbackupptr]
	test edi,edi
	jz .conversionloop

	push esi
	mov cx,totalvehtypes*vehtypeinfo_size/4
	rep movsd
	pop esi

.conversionloop:
	// Note: the same conditions are checked on every loop iteration, over and over again.
	// This is slower, but takes up less space than two separate loops.

	testmultiflags electrifiedrail
	jnz .electrify

	testmultiflags unifiedmaglev
	jz .notypeconversion

	mov al,[unimaglevmode]
	cmp al,3
	je .notypeconversion

	mov bl,3
	sub bl,al			// AL=target type, BL=the 'other' type

	// without electrification:
	// convert one type of maglev to the other
	cmp [esi+vehtypeinfo.traintype],bl
	jne short .next
	bt [isengine],ecx
	jnc short .next
	mov [esi+vehtypeinfo.traintype],al
	jmp short .next

.electrify:
	// with electrification:
	// convert type=1 engines to type=2, and electric type=0 engines to type=1
	mov al,[esi+vehtypeinfo.traintype]
	test al,al
	jne short .notrailroad

	mov al,[traintractiontype+ecx]
	cmp al,0x28
	jb short .next		// not electric
	cmp al,0x42
	jae short .next		// waggon

	mov byte [esi+vehtypeinfo.traintype],1
	jmp short .next

.notrailroad:
	cmp al,1
	jne short .next
	bt [isengine],ecx
	jnc short .waggon
	mov byte [esi+vehtypeinfo.traintype],2
	jmp short .next

.waggon:
	mov byte [esi+vehtypeinfo.climates],0	// not available

.next:
	add esi,byte vehtypeinfo_size
	inc ecx
	cmp cl,NTRAINTYPES
	jb short .conversionloop

	// *********

	testflagbase none

	// set introduction date of first engine for each track type
.notypeconversion:
	mov esi,[vehtypedataptr]
	mov edi,firsttracktypeengine

	or dword [edi],byte -1
	or dword [edi+2],byte -1

	xor eax,eax
.nextengine:
	bt [isengine],eax
	jnc .notbefore

	mov bx,[esi+vehtypeinfo.baseintrodate]
	movzx edx,byte [esi+vehtypeinfo.traintype]
	cmp bx,[edi+edx*2]
	ja .notbefore

	mov [edi+edx*2],bx

.notbefore:
	inc eax
	add esi,0+vehtypeinfo_size
	cmp eax,NTRAINTYPES
	jb .nextengine

	testmultiflags wagonspeedlimits
	jz near .nospeedlimits

//	mov esi,[enginepowerstable]

	xor eax,eax
.nextwagonspeed:
	bt [isengine],eax
	jc .gotlimit

	mov bx,[trainspeeds+eax*2]
	inc bx
	cmp bx,1
	jb .nolimit 	// was -1 -> set to 0
	ja .gotlimit	// was >0 -> keep

	movzx ebx,byte [traincargotype+eax]
	mov bl,[cargowagonspeedlimit+ebx]

	imul edx,eax,byte vehtypeinfo_size
	add edx,[vehtypedataptr]

	mov cl,[edx+vehtypeinfo.baseintrodate+1]
	movzx edx,byte [edx+vehtypeinfo.traintype]
	mov dl,[firsttracktypeengine+edx*2+1]
	cmp cl,dl
	jae .nottooearly
	mov cl,dl
.nottooearly:
	cmp cl,(1940-1920)*365>>8	// -> -1/4
	sbb edx,edx
	cmp cl,(1970-1920)*365>>8	// -> +0/4
	sbb edx,0
	cmp cl,(1985-1920)*365>>8	// -> +1/4
	sbb edx,0
	cmp cl,(1997-1920)*365>>8	// -> +2/4
	sbb edi,edi
	lea edx,[edx+edi*2]
	cmp cl,(2020-1920)*365>>8	// -> +4/4
	sbb edi,edi
	lea edx,[edx+edi*4+8]		// -> +8/4
	imul edx,ebx
	sar edx,2
	add ebx,edx

.nolimit:
	mov [trainspeeds+eax*2],bx

.gotlimit:
	inc eax
	cmp al,NTRAINTYPES
	jb .nextwagonspeed

	// *********

.nospeedlimits:

	// use default value for train vehicles that didn't set trainviseffect
	mov esi,trainviseffect
	xor ecx,ecx

.getnexteffect:
	lodsb
	cmp al,0x10
	jnb .notdefault

	movzx eax,byte [esi-1-trainviseffect+traintractiontype]
	mov bl,4

	bt [isengine],ecx
	jnc .wagon

	cmp al,8
	sbb bl,ah	// subtract 1 if al<8 (steam)

	cmp al,0x28
	sbb bl,ah	// subtract 1 if al<0x28 (steam or diesel)

	cmp al,0x32
	adc ah,0
	sub bl,ah	// (steam, diesel or electric)

	// now bl=1, 2, 3, 4 for steam, diesel, electric, monorail/maglev
	// and ah=1 for everything but monorail/maglev

	shl ah,2
	shl bl,4
	add bl,ah
.wagon:
	mov [esi-1],bl	// now bl=0x14, 0x24, 0x34 or 0x40

.notdefault:
	inc ecx
	cmp cl,NTRAINTYPES
	jb .getnexteffect

	// *********

	// calculate coefficient of air resistance
	// depending on max speed if not set by the .grf file

	mov edi,trainc2coeff

	test byte [newvehdata+newvehdatastruc.flags],1
	jnz .notoldformat

	push edi
	xor eax,eax
	mov cl,(NTRAINTYPES+NROADVEHTYPES)/4
	rep stosd
	pop edi

.notoldformat:
	xor edx,edx
.nextc0:
	mov al,[edi]
	cmp al,0
	jne .gotc0

	cmp dl,NTRAINTYPES
	jb .trainspeed

	movzx eax,byte [rvhspeed+edx-ROADVEHBASE]
	shl eax,maxrvspeedshift
	jnz .gotspeed

	mov al,[rvspeed+edx-ROADVEHBASE]
	jmp short .gotspeed

.trainspeed:
	movzx eax,word [trainspeeds+edx*2]
.gotspeed:
	mov cl,1
	cmp eax,32
	jb .gotit

	// TODO: Rewrite this bit, some of it is redundant

	bsr ecx,eax

	shr eax,cl
	sbb ch,ch
	sub cl,4

	add cl,cl
	sub cl,ch	// double cl, and add 1 if carry was set

	// now recalculate as fraction of 1/256

	shr cl,1
	adc ch,0
	add cl,ch
	add cl,ch

	xor eax,eax
	mov ah,1

	test ch,ch
	jz .notadded
	lea eax,[eax*3]

.notadded:
	shr eax,cl
	add al,1
	jnc .gotit

	mov al,255

.gotit:

.gotc0:
	stosb
	inc edx
	cmp dl,NTRAINTYPES+NROADVEHTYPES
	jb .nextc0

#if 0
// moreindustriesperclimate: for adding new cargo
	testflags moreindustriesperclimate
	jnc .nomoreindustriesperclimate
	call addnewtemperatecargo
.nomoreindustriesperclimate:
#endif

	call SwapDockWinPurchaseLandIco
	call SwapLomoGuiIcons
	mov byte [desynchtimeout],0

	xor edx,edx
	inc edx
	call setbasecostmult

extern recalctownpopulations

	testflags newhouses
	jnc .nohousecountrecalc
	call recalchousecounts
	call recalctownpopulations
.nohousecountrecalc:

	testflags tempsnowline
	jnc .notempsnow
	cmp word [snowytemptreespritebase],-1
	je .notempsnow
	call applysnowytemptrees

.notempsnow:
	testflags trams
	jnc .notrams
	call updateTramStopSpriteLayout
.notrams:

// Update RV roadside stop station layouts to use sprites defined by
// action 5 type 11.
	testmultiflags newstations
	jz .noRVStops
	call updateRVStopSpriteLayout

.noRVStops:
	testflags electrifiedrail
	jc .noshufflemenu
	testflags unifiedmaglev
	jnc .noshufflemenu
	cmp byte [unimaglevmode],2
	jne .noshufflemenu

	// make second menu entry be Maglev
	mov ax,0x1016
	call gettextintableptr

	mov esi,[eax+edi*4+4]
	mov [eax+edi*4],esi

.noshufflemenu:
	mov ax,ourtext(unnamedtownnamestyle)
	call gettextandtableptrs
	mov [defaultstylename],edi

	testflags generalfixes
	jnc .nofixupvehtexts
	test dword [miscmodsflags],MISCMODS_USEVEHNNUMBERNOTNAME
	jnz .nofixupvehtexts

	call fixupvehnametexts

.nofixupvehtexts:
	test byte [miscmodsflags+2], MISCMODS_NODIAGONALFLOODING>>(8*2)
	jnz .nochangecoastspritetable

	call ChangeCoastSpriteTable
.nochangecoastspritetable:
	testflags enhancegui
	jnc .lnoenhancegui

	push bx
	mov bl, [depotscalefactor]
	mov bh, 29
	bt dword [grfmodflags], 3
	jnc .lnot32
	add bh, 3
.lnot32:
	cmp bh, bl
	pop bx
	je .lendofdepots

	// Correct the depot size limits incase the 32 bit flag has changed
extern ChangeRailDepotSizeLimits
	call ChangeRailDepotSizeLimits
	
	// Resize all open depot windows for the new scaling
	call ResizeOpenWindows

	jmp .lendofdepots
.lnoenhancegui:
	// Disable 32px depots completely (no enhancegui active) until I can workout some fragments.
	btr dword [grfmodflags], 3
.lendofdepots:

testmultiflags clonetrain
	jz .noclonetrain
extern CloneTrainChangeGrfSprites
	call CloneTrainChangeGrfSprites

.noclonetrain:

	// Set persgrfdata.statnonenter and statrventer
	mov esi,stationidgrfmap
	xor ecx,ecx
.nextnonenter:
	mov ax,0
	xor edx, edx
	xor edi, edi
	cmp word [esi+ecx*stationid_size+stationid.numtiles],0
	je .nostationdata	// ID not in use, reset it

	movzx ebx,byte [esi+ecx*stationid_size+stationid.gameid]
	test ebx,ebx
	jz .nogameid		// ID in use but grf missing, keep values

	extern cantrainenterstattile
	mov al,[cantrainenterstattile+ebx]
	
	extern canrventerrailstattile
	mov edx,[canrventerrailstattile+ebx*8]
	mov edi,[canrventerrailstattile+ebx*8+4]
	
.nostationdata:
	mov [stationnonenter+ecx],al
	mov [stationrventer+ecx*8],edx
	mov [stationrventer+ecx*8+4],edi

.nogameid:
	inc cl
	jnz .nextnonenter

	CHECKMEM
	ret

// List of vehicles the should be made eternal
// first+second list if persistenengines is on
// second list otherwise (makes train wagons eternal)
varb eternalvehicleslist
	// start with ranges (number, increment, start ID)
	db  3,1,24	// SH.40, TIM and Asiastar
	db  3,1,54	// X2001, Z1, Z99
	db  3,1,86	// Pegasus, Chimera, Rocketeer
	db 29,3,119	// 29 Road vehicles, one per cargo type
	db  2,2,205	// Oil tanker and Ferry
	db  4,2,208	// Hovercraft, Toyland Ferry, Cargo ships (reg.&toyland)
	db  2,1,246	// Dinger 200,1000
	db  2,1,250	// Toyland planes
	db  2,1,254	// Regular and Toyland helicopters
var eternalvehicleslistwagons
	db 27,1,27	// Rail wagons
	db 27,1,57	// Monorail wagons
	db 27,1,89	// Maglev wagons
	// end of list
	db 0
