// New loading and saving functions to support more vehicles

#include <std.inc>
#include <town.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <industry.inc>
#include <patchdata.inc>
#include <veh.inc>
#include <player.inc>
#include <vehtype.inc>
#include <loadsave.inc>
#include <station.inc>
#include <bitvars.inc>
#include <grf.inc>
#include <news.inc>
#include <house.inc>
#include <newvehdata.inc>

extern LoadWindowSizesFinish,SaveWindowSizesPrepare
extern actionhandler,activatedefault,animarraysize,calcaccel
extern calcconsistweight,calcpowerandspeed,cleardata,clearhousedataids
extern clearhouseidsfromlandscape,clearindustiledataids
extern clearindustileidsfromlandscape,clearindustrygameids
extern clearindustryincargos,clearpersistenttexts,clearstationcargodata
extern cleartrainsignalpath,companystatsptr,consistcallbacks
extern convertbridgeheads,copyorgcargodata,delveharrayentry,delvehschedule
extern dogrferrormsg,enhancegui_insave_init,enhancegui_insave_setdefaultuse
extern enhanceguioptions_savedata,errorpopup,findcurrtownname,flag_data_size
extern getspecificpropertyarea,grfidlist,grfidlistnum,havestationidgrfmap
extern housedataidtogameid,houseoverrides,industiledataidtogameid
extern industileoverrides,industrydataidtogameid,industryincargos,infoapply
extern inforeset,initttdpatchdata,isremoteplayer,landscape6_ptr
extern landscape6clear,landscape6init,landscape7_ptr,landscape7clear
extern landscape7init,lastextrahousedata,lastextraindustiledata
extern lasthousedataid,lastindustiledataid,loadchunkfn,makegrfidlist
extern makegrfidlistsize,miscmodsflags,newanimarray,newcargoamount1names
extern newcargoamountnnames,newcargocolors,newcargodatasize
extern newcargodelaypenaltythresholds1,newcargodelaypenaltythresholds2
extern newcargographcolors,newcargoicons,newcargopricefactors
extern newcargoshortnames,newcargotypenames,newcargounitnames
extern newcargounitweights,newshistclear,newshistinit,newshistoryptr
extern newvehdata,oldhuman1,oldveharraysize,oldvehicles
extern orighumanplayers,patchflags,persistentgrftextlist,realplayernum
extern recalchousecounts,recalctownpopulations,resetnewsprites,savechunkfn
extern setbasecostmult,setbasecostmultdefault,setrvweightandpower
extern setvehiclearraysize,specialerrtext1,specificpropertybase
extern specvehdatalength
extern spriteerror,spriteerrorparam,spriteerrortype,startflagdata
extern station2clear,station2init,stationarray2ptr,stationidgrfmap
extern townarray2ofst,ttdpatchvercode,veh2ptr,vehicledatafactor
extern vehtypedataconvbackupptr,vehtypedataptr
extern windowsizesbufferptr
extern player2array,player2clear,cargoids
extern disabledoldhouses,savevar40x

// Known (defined) extra chunks.
// The first table defines chunk IDs.
var knownextrachunkids
// Optional chunks (no real loss of game state if they're discarded)
	dw 0		// TTD Vehicle data
	dw 1		// TTDPatch Vehicle data
	dw 2		// (old) list of GRF IDs that we know about
	dw 3		// TTDPatch version and configuration
	dw 4		// enhancegui options
	dw 5		// List of animated tiles
	dw 6		// News history
	dw 7		// Window sizes
	dw 8		// Company statistics

// Mandatory chunks (needed to preserve the full state of a game)
	dw 0x8000	// Town array extension
	dw 0x8001	// Landscape 6 array
	dw 0x8002	// New Station ID map
	dw 0x8003	// Landscape 7 array
	dw 0x8004	// List of GRF IDs that we know about
	dw 0x8005	// New house ID map
	dw 0x8006	// New industry tile ID map
	dw 0x8007	// New industry map
	dw 0x8008	// Persistent texts
	dw 0x8009	// Secondary station array
	dw 0x800a	// incoming industry cargo data
	dw 0x800b	// new cargo type data
	dw 0x800c	// player 2 array

knownextrachunknum equ (addr($)-knownextrachunkids)/2

// The load functions for each chunk
var knownextrachunkloadfns
	dd addr(loadspecvehdata)
	dd addr(loadttdvehdata)
	dd addr(loadgrfidlist)
	dd addr(skipchunkonload)
	dd addr(loadenhanceguioptions)
	dd addr(loadanimtiles)
	dd addr(loadnewshistory)
	dd addr(loadwindowsizes)
	dd addr(loadcompanystats)

	dd addr(loadtown2array)
	dd addr(loadlandscape6array)
	dd addr(loadstationidmap)
	dd addr(loadlandscape7array)
	dd addr(loadgrfidlist)
	dd addr(loadhouseidmap)
	dd addr(loadindustileidmap)
	dd addr(loadindustrymap)
	dd addr(loadpersistenttexts)
	dd addr(loadstation2array)
	dd addr(loadinduincargodata)
	dd addr(loadnewcargotypes)
	dd addr(loadplayer2array)
%ifndef PREPROCESSONLY
%if knownextrachunknum <> (addr($)-knownextrachunkloadfns)/4
	%error "Inconsistent number of chunk functions"
%endif
%endif

// The save functions for each chunk
var knownextrachunksavefns
	dd addr(savespecvehdata)
	dd addr(savettdvehdata)
	dd 0	// if this is used, something went wrong
	dd addr(savepatchconfig)
	dd addr(saveenhanceguioptions)
	dd addr(saveanimtiles)
	dd addr(savenewshistory)
	dd addr(savewindowsizes)
	dd addr(savecompanystats)

	dd addr(savetown2array)
	dd addr(savelandscape6array)
	dd addr(savestationidmap)
	dd addr(savelandscape7array)
	dd addr(savegrfidlist)
	dd addr(savehouseidmap)
	dd addr(saveindustileidmap)
	dd addr(saveindustrymap)
	dd addr(savepersistenttexts)
	dd addr(savestation2array)
	dd addr(saveinduincargodata)
	dd addr(savenewcargotypes)
	dd addr(saveplayer2array)
%ifndef PREPROCESSONLY
%if knownextrachunknum <> (addr($)-knownextrachunksavefns)/4
	%error "Inconsistent number of chunk functions"
%endif
%endif

// The query functions for each chunk (to determine if the chunk is to be saved/loaded)
// In:	CF=0 for loading, CF=1 for saving
// Out:	CF=1 if chunk is to be saved/loaded, CF=0 if not
var knownextrachunkqueryfns
	dd addr(canhavespecvehdata)
	dd addr(canhavettdvehdata)
	dd addr(canhaveoldgrfidlist)
	dd addr(canhavepatchconfig)
	dd addr(canhaveenhanceguioptions)
	dd addr(canhaveanimtiles)
	dd addr(canhavenewshistory)
	dd addr(canhavewindowsizes)
	dd addr(canhavecompanystats)

	dd addr(canhavetown2array)
	dd addr(canhavelandscape6array)
	dd addr(canhavestationidmap)
	dd addr(canhavelandscape7array)
	dd addr(canhavegrfidlist)
	dd addr(canhavehouseidmap)
	dd addr(canhaveindustileidmap)
	dd addr(canhaveindustrymap)
	dd addr(canhavepersistenttexts)
	dd addr(canhavestation2array)
	dd addr(canhaveinduincargodata)
	dd addr(canhavenewcargotypes)
	dd addr(canhaveplayer2array)
%ifndef PREPROCESSONLY
%if knownextrachunknum <> (addr($)-knownextrachunkqueryfns)/4
	%error "Inconsistent number of chunk functions"
%endif
%endif



// Temporary variables used in load/save code
uvarb chunkstosave,(knownextrachunknum+8)/8	// bit map of chunks to be saved (in reverse order)
				// +8 not +7 because bits are indexed by loop counter...
uvarb loadstage		// used to retry the loading after checking veh. multiplier if lowmemory
uvarb loadproblem
uvarb loadreduced	// nonzero: had to reduce vehicle array from this value
uvarw loadremovedvehs	// had to remove this many vehicles
uvarw loadremovedcons	// ...in this many consists (these 2 vars are also accessed as a single DWORD)
uvarw loadremovedsfxs	// ... and this many pseudo-/special vehicles

%assign LOADPROBLEM_UNKNOWNCHUNK	0x1
%assign LOADPROBLEM_BADCHUNK		0x2
%assign LOADPROBLEM_RCHUNKNOTLOADED	0x4	// required (mandatory) chunk present but not loaded

// Additional flags to indicate whether some specific data have been loaded
//%assign LOADED_X1_TTDVEHDATA		0x?	// ** currently unused **
%assign LOADED_X1_TOWN2			0x1
%assign LOADED_X1_L6ARRAY		0x2
%assign LOADED_X1_ENHGUI		0x4
%assign LOADED_X1_L7ARRAY		0x8
%assign LOADED_X1_HOUSEIDARRAY		0x10
%assign LOADED_X1_ANIMTILES		0x20
%assign LOADED_X1_NEWSHISTORY		0x40
%assign LOADED_X1_INDUSTILEIDARRAY	0x80

%assign LOADED_X2_WINDOWSIZES		0x01
%assign LOADED_X2_INDUSTRYMAP		0x02
%assign LOADED_X2_PERSISTENTTEXTS	0x04
%assign LOADED_X2_STATION2		0x08
%assign LOADED_X2_INDUINCARGO		0x10
%assign LOADED_X2_NEWCARGOTYPES		0x20
%assign LOADED_X2_PLAYER2		0x40

uvarb extrachunksloaded1		// a combination of LOADED_X1_*
uvarb extrachunksloaded2		// a combination of LOADED_X2_*
uvarb extrachunksloaded3		// a combination of LOADED_X3_*
uvarb extrachunksloaded4		// a combination of LOADED_X4_*

uvard l6switches

uvard l7switches

uvard station2switches

struc extrachunkhdr
	.id:	resw 1
	.length:resd 1
endstruc

var extrachunkheader
	istruc extrachunkhdr
		dw -1
		dd 0
	iend


%macro CALLLOADSAVECHUNK 0
	call ebp		// AFAICT [loadchunkfn] and [savechunkfn] preserve everything except AL,ECX,ESI
%endmacro

// Load or save the main data. In: EBP->load or save function, ESI->startdata, BL = 0=load, 1=save
loadsavemaindata:
	// first chunk: up to oldveharray
	// here's where ESI pointing to datastart comes in handy
	mov ecx,oldveharray-datastart
	push ds
	pop es
	CALLLOADSAVECHUNK

	// second chunk: the vehicle array
	mov esi,[veharrayptr]
	test bl,bl
	jnz .saving

	// we're loading; make sure we load exactly as much as we need
	movzx eax,byte [landscape3+ttdpatchdata.vehfactor]
	cmp al,2
	adc al,0			// 0->1, 1->2, other values left as they are
	mov [loadreduced],al		// will be checked later and zeroed if OK
	imul ecx,eax,oldveharraysize
	jmp short .dosecondchunk

.saving:
	// we're saving; here it's simple, just save everything
	mov ecx,[veharrayendptr]
	sub ecx,esi

.dosecondchunk:
	CALLLOADSAVECHUNK

	// third chunk: the rest
	mov esi,oldveharray
	add esi,oldveharraysize
	mov ecx,datasaveend
	sub ecx,esi
	CALLLOADSAVECHUNK

	// fourth chunk: the L4 array
#if WINTTDX
	mov esi,landscape4base
#else
	xor esi,esi
	push fs
	pop es
#endif
	mov ecx,0x10000
	CALLLOADSAVECHUNK

	// fifth chunk: the L5 array
#if WINTTDX
	mov esi,landscape5base
#else
	xor esi,esi
	push gs
	pop es
#endif
	mov ecx,0x10000
	CALLLOADSAVECHUNK

#if !WINTTDX
	push ds
	pop es
#endif
	ret


// Things to do before and after saving the main game data

presaveadjust:
	mov edx,addr(adjaivehicleptrssave)
	call adjaivehicleptrs

	// reset base cost multipliers
	or edx,byte -1
	call setbasecostmult

	or byte [landscape3+ttdpatchdata.flags],1

	testflags moreanimation
	jnc .nocopyanim
	// we copy the beginning of the extended data to the old array in case it'll be loaded with the switch being off
	push esi
	mov edi,animatedtilelist
	mov esi,[newanimarray]
	mov ecx,256*2/4
	rep movsd
	pop esi
.nocopyanim:

	and byte [landscape3+ttdpatchdata.flags],0xfd
	testflags newcargos
	jnc .nonewcargos
	call copybackcargodata
	or byte [landscape3+ttdpatchdata.flags],2
.nonewcargos:

	ret

postsaveadjust:
	mov edx,addr(adjaivehicleptrsload)
	call adjaivehicleptrs

	// set base cost multipliers
	xor edx,edx
	inc edx
	call setbasecostmult
	ret


// New save function
// in:	ESI -> datastart
global newsaveproc
newsaveproc:
	mov dword [landscape3+ttdpatchdata.magic],L3MAGIC	// indicate new TTDPatch extra data format

	// record the vehicle array multiplier
	mov al,[vehicledatafactor]
	cmp al,1
	jne .isnotone
	mov al,0			// 1,0->0  2 etc. ok

.isnotone:
	mov [landscape3+ttdpatchdata.vehfactor],al

#if WINTTDX
	cmp byte [numplayers],2
	jne .nomultiinfo
	testflags enhancemultiplayer
	jnc .nomultiinfo
	cmp byte [realplayernum],2
	jne .dontsethuman2

	bsf eax,dword [isremoteplayer]
	mov [human2],al
	movzx eax,byte [orighumanplayers]
	movzx ebx,byte [landscape3+ttdpatchdata.orgpl1]
	btr eax,ebx
	bsf eax,eax
	mov [landscape3+ttdpatchdata.orgpl2],al

.dontsethuman2:
	mov al,[isremoteplayer]
	mov [landscape3+ttdpatchdata.remoteplayers],al
	mov al,[orighumanplayers]
	mov [landscape3+ttdpatchdata.orighumanplayers],al

.nomultiinfo:
#endif

	// record the number of extra chunks
	mov ebx,chunkstosave
	mov edx,knownextrachunkqueryfns
	xor ecx,ecx
	mov cl,knownextrachunknum	// if knownextrachunknum exceeds 255 in some far future, NASM will complain
	xor eax,eax

.extrachunkpreploop:
	btr [ebx],ecx
	pusha
	stc
	call [edx]
	popa
	jnc .prepnextchunk
	bts [ebx],ecx
	inc eax

.prepnextchunk:
	add edx,byte 4
	loop .extrachunkpreploop

	mov [landscape3+ttdpatchdata.extrachunks],ax

	// save the main data
	call presaveadjust

	mov ebp,[savechunkfn]
	mov bl,1
	call loadsavemaindata

	call postsaveadjust

	cmp word [landscape3+ttdpatchdata.extrachunks],byte 0
	jz .noextrachunks

	// save all the extra chunks
	mov ebx,extrachunkheader
	mov esi,knownextrachunkids
	mov edx,knownextrachunksavefns
	xor ecx,ecx
	mov cl,knownextrachunknum	// if knownextrachunknum exceeds 255 in some far future, NASM will complain

.extrachunkloop:
	lodsw
	bt [chunkstosave],ecx
	jnc .nextchunk
	mov [ebx+extrachunkhdr.id],ax
#if DEBUG
	or dword [chunksize], byte -1
#endif
	pusha
	call [edx]
	popa
#if DEBUG
	cmp dword [chunksize],0
	je .ok
	ud2	//	SF clear: Insufficient bytes saved. SF set: savechunkheader not called.
.ok:
#endif

.nextchunk:
	add edx,byte 4
	loop .extrachunkloop

.noextrachunks:
	// we're through

	// PreSaveCleanup erases the veh2 ptr of unused slots, so reset it here
	call initveh2
	ret
; endp newsaveproc


postloadadjust:
	mov edx,addr(adjaivehicleptrsload)
	call adjaivehicleptrs
	call setbasecostmultdefault

	// check if veh array has valid high byte of .modflags
	test byte [landscape3+ttdpatchdata.flags],1
	setz dh
	dec dh		// now dh=00 if bit was not set, FF if set

	// adjust veharray data
	mov edi,[veharrayptr]
.next:
	and [edi+veh.modflags+1],dh	// zero high byte if bit wasn't set

	cmp word [esi+veh.speedlimit], 0
	jne .dontSetSpeedLimit
	mov ax,[esi+veh.maxspeed]
	mov [esi+veh.speedlimit],ax

.dontSetSpeedLimit:
	sub edi,byte -veh_size
	cmp edi,[veharrayendptr]
	jb .next

	ret

uvarb titlescreenloading

// New load function
// in:	ESI -> datastart
// out: CF=1 - failed
//	CF=0 and ZF=1 - rewind, otherwise finished
global newloadproc
newloadproc:
#if MEASUREVAR40X
	call savevar40x
#endif

	cmp byte [gamemode],2
	je newloadtitleproc

	mov byte [gamemode],1	// needs to be set early for .grfs that check it

global newloadtitleproc
newloadtitleproc:
	push ds
	pop es
	mov ebp,[loadchunkfn]

#if WINTTDX
	mov al,[human1]
	mov [oldhuman1],al
#endif

	// if lowmemory is on, check if vehicle array will fit
	// abort with "Game Load Failed" if no, rewind the file and proceed with loading if yes
	mov al,0
	xchg al,[loadstage]
	or al,al
	jnz .proceedwithload		// already checked the veharray size

	testflags lowmemory
	jnc .proceedwithload		// in the normal memory mode the array *should* always suffice

	mov esi,loadreduced
	mov ecx,landscape3+ttdpatchdata.vehfactor+1-datastart

.vehfactorloadloop:
	pusha
	xor ecx,ecx
	inc ecx				// load 1 byte at a time
	call ebp
	popa
	loop .vehfactorloadloop

	mov al,[esi]
	cmp al,2
	adc al,0			// 0->1, 1->2, other values left as they are
	cmp [vehicledatafactor],al	// CF=1 if too large to fit
	jc .rewindorabort
	mov byte [loadstage],1
	xor al,al

.rewindorabort:
	ret

.proceedwithload:
	and byte [loadproblem],0

	// start by resetting all the vehicle type data
	push ebp
	push esi

	call inforeset
	and dword [extrachunksloaded1],0	// indicate that extra data are no longer valid
	and dword [grfidlistnum],0	// clear list of GRF IDs
	mov byte [activatedefault],0	// don't activate by default if we have no grf id list block

	call setvehiclearraysize	// probably unnecessary but just in case
	call cleardata

	pop esi
	pop ebp

	// load the main data
	mov bl,0
	call loadsavemaindata

	call postloadadjust

 	call clearpersistenttexts	// this must be called before extra chunks are loaded

	movzx ecx,word [landscape3+ttdpatchdata.extrachunks]

	// convert the old-style TTDPatch extra data in L3 if necessary
	cmp dword [landscape3+ttdpatchdata.magic],L3MAGIC
	je .ttdpatchdataOK

	mov esi,landscape3
	setbase edi,landscape3+ttdpatchdata.start
	mov eax,[esi+ttdpatchdataold.chtused]
	mov [BASE landscape3+ttdpatchdata.chtused],eax
	mov eax,[esi+ttdpatchdataold.orgpl1]
	mov [BASE landscape3+ttdpatchdata.orgpl1],ax	// also copies .orgpl2
	mov eax,[esi+ttdpatchdataold.yearsadd]
	mov [BASE landscape3+ttdpatchdata.yearsadd],ax
	mov eax,[esi+ttdpatchdataold.daysadd]
	mov [BASE landscape3+ttdpatchdata.daysadd],eax
	mov al,[esi+ttdpatchdataold.realcurrency]
	mov [BASE landscape3+ttdpatchdata.realcurrency],al
	setbase none

	movzx ecx,word [esi+ttdpatchdataold.extrachunks]

.ttdpatchdataOK:
	// now, are there any extra chunks to load or skip?
	jecxz .noextrachunks

	// there are extra chunks, load or skip them as appropriate
	mov ebx,extrachunkheader

.extrachunkloop:
	pusha

	// load a chunk's header
	mov esi,ebx
	xor ecx,ecx
	mov cl,extrachunkhdr_size
	call ebp

	// try to identify the chunk
	mov dx,[ebx+extrachunkhdr.id]
	mov eax,[ebx+extrachunkhdr.length]
	xor ecx,ecx

.findchunk:
	cmp word [knownextrachunkids+ecx*2],dx
	je .found
	inc ecx
	cmp ecx,0+knownextrachunknum	// leading 0+ makes the macro in opimm8.mac work
	jb .findchunk

	// not found, skip the chunk
	or byte [loadproblem],LOADPROBLEM_UNKNOWNCHUNK

.skipchunk:
	call skipchunkonload
	jmp short .nextchunk

.found:
	pusha
	clc
	call dword [knownextrachunkqueryfns+ecx*4]
	popa
	jnc .skipchunk

#if DEBUG
	mov [chunksize], eax
	mov [realloadsavefn], ebp
	mov ebp, loadsavechunkhelper
#endif
	call dword [knownextrachunkloadfns+ecx*4]
#if DEBUG
	cmp dword [chunksize], 0
	je .ok
	ud2	// Insufficient bytes read/written.
.ok:
#endif

.nextchunk:
	popa
	loop .extrachunkloop

.noextrachunks:
	// find engines in consists
	mov esi,loadreduced
	movzx ebx,byte [esi]		// now EBX=loaded array's multiplier
	mov edi,veharrayendptr
	push dword [edi]
	mov eax,[veharrayptr]
	imul ebp,ebx,oldveharraysize
	add ebp,eax			// now EBP->loaded array's end
	mov [edi],ebp			// temporarily set veharrayendptr to this value

	call findengines

	// check the loaded veharray's multiplier
	// EAX->vehicle array, EBX=loaded array's multiplier, EBP->loaded array's end,
	// ESI->loadreduced, EDI->veharrayendptr
	movzx ecx,byte [vehicledatafactor]
	cmp bl,cl
	ja .reduceveharray
	mov byte [esi],0
#if WINTTDX
	jmp .veharrayok
#else
	jmp short .veharrayok
#endif

.reduceveharray:
	// reduce the vehicle array to vehicledatafactor*850 entries
	// EAX->vehicle array, EBX=loaded array's multiplier, ECX=vehicledatafactor,
	// ESI->loadreduced, EDI->veharrayendptr, EBP->loaded array's end
#if WINTTDX
	xor edx,edx
	inc edx				// EDX=1, add datastart to pointers
	call adjustscheduleptrs
#endif

	mov edx,loadremovedvehs
	and dword [edx],byte 0
	and word [byte edx+loadremovedsfxs-loadremovedvehs], byte 0

	imul ecx,ecx,oldvehicles
	mov esi,dayprocnextveh
	cmp [esi],cx
	jbe short .procvehOK
	mov [esi],cx

.procvehOK:
	shl ecx,vehicleshift
	add ecx,eax			// now ECX->start of the discarded area of vehicle array

.consistloop:
	cmp byte [ecx+veh.class],0
	je short .nextconsist

	call deleteconsist

.nextconsist:
	sub ecx,byte -vehiclesize
	cmp ecx,ebp
	jb short .consistloop

#if WINTTDX
	or edx,byte -1				// EDX=-1, subtract datastart back from pointers
	call adjustscheduleptrs
#endif

.veharrayok:
	// still EAX->vehicle array, EBX=loaded array's multiplier,
	// EDI->veharrayendptr, EBP->loaded array's end
	pop dword [edi]			// restore veharrayendptr

	call initveh2

	// check validity of some variables
	mov eax,[landscape3+ttdpatchdata.orgpl1]
	cmp al,ah
	jne short .validcompanies

	mov eax,[human1]
	mov [landscape3+ttdpatchdata.orgpl1],ax

.validcompanies:
	// now check extra arrays (which typically go to mandatory chunks)
	// if any is needed but has not been loaded, initialize it

	// check town array extension
	mov eax,[townarray2ofst]
	test eax,eax
	jz .town2array_ok
	test byte [extrachunksloaded1],LOADED_X1_TOWN2
	jnz .town2array_ok

	// town array extension is used but was not loaded
	// initialize using the standard data
	lea edi,[eax+townarray]
	mov esi,edi			// save for later
	mov ecx,numtowns*town2_size/4
	xor eax,eax
	rep stosd			// clear the array first

	call recalctownpopulations

	// convert the old-style bribe fail data
	mov edi,townarray
	xor ecx,ecx
	mov cl,numtowns

.copybribedata:
	movzx edx,byte [edi+0x2f]
	bsf edx,edx			// check if a company is unwanted (old-style data can have only one)
	jz .nextbribedata

	// check for how long a company, if any, will be unwanted yet
	mov ax,[edi+0x30]
	sub ax,[currentdate]
	jbe .nextbribedata		// already expired

	// convert to months
	mov bl,30
	cmp ah,bl
	jae .bribemonthsoverflow
	div bl
.bribemonthsoverflow:

	inc eax
	mov [esi+town2.companiesunwanted+edx],al

.nextbribedata:
	and dword [edi+0x2e],0xff	// clear the old-style data
	add esi,0+town_size
	add edi,0+town_size
	loop .copybribedata

.town2array_ok:

	// check landscape6 array
	cmp dword [landscape6_ptr],0
	jle .no_l6
	test byte [extrachunksloaded1],LOADED_X1_L6ARRAY
	jnz .l6_ok

	call landscape6clear

.l6_ok:
	call landscape6init	// in l6array.asm
.no_l6:


	// check landscape7 array
	cmp dword [landscape7_ptr],0
	jle .no_l7
	test byte [extrachunksloaded1],LOADED_X1_L7ARRAY
	jnz .l7_ok
	call landscape7clear
.l7_ok:
	call landscape7init
.no_l7:

	// Enhancegui is everywhere :o
	// Load savegame specific settings if they are present, 
	// or make new 
	cmp dword [enhanceguioptions_savedata],0
	je .no_enhanceguioptions
	test byte [extrachunksloaded1],LOADED_X1_ENHGUI
	jnz .enhanceguioptions_loaded
	call enhancegui_insave_setdefaultuse

.enhanceguioptions_loaded:
	call enhancegui_insave_init
.no_enhanceguioptions:

	test byte [extrachunksloaded2],LOADED_X2_WINDOWSIZES
	jz .nowindowsizesloaded
	call LoadWindowSizesFinish
.nowindowsizesloaded:


	testflags newhouses
	jnc .nonewhouses
	test byte [extrachunksloaded1],LOADED_X1_HOUSEIDARRAY
	jnz .hashouseids
	mov byte [lasthousedataid],0
	call clearhouseidsfromlandscape
.hashouseids:

	mov byte [lastextrahousedata],0

	xor eax,eax			// clear house overrides
	mov edi,houseoverrides
	lea ecx,[eax+110]
	rep stosb

	and dword [disabledoldhouses+0],0
	and dword [disabledoldhouses+4],0
	and dword [disabledoldhouses+8],0
	and dword [disabledoldhouses+12],0

	call recalchousecounts
.nonewhouses:

	testflags moreanimation
	jnc .no_animlist
	test byte [extrachunksloaded1],LOADED_X1_ANIMTILES
	jnz .animlist_ok

	mov edi, [newanimarray]
	mov ecx, [animarraysize]
	xor eax,eax
	rep stosw
	mov esi, animatedtilelist
	mov edi,[newanimarray]
	mov ecx,256*2/4
	rep movsd

.no_animlist:
.animlist_ok:

	// check newshistory
	cmp dword [newshistoryptr],0
	je .no_newshist
	test byte [extrachunksloaded1],LOADED_X1_NEWSHISTORY
	jnz .newshist_ok
	call newshistclear
.newshist_ok:
	call newshistinit
.no_newshist:

	testflags newindustries
	jnc .nonewindus
	test byte [extrachunksloaded1],LOADED_X1_INDUSTILEIDARRAY
	jnz .hasnewindusids
	mov byte [lastindustiledataid],0
	call clearindustileidsfromlandscape
.hasnewindusids:

	test byte [extrachunksloaded2],LOADED_X2_INDUSTRYMAP
	jnz .hasindustrymap
	call clearindustrygameids

.hasindustrymap:
	test byte [extrachunksloaded2],LOADED_X2_INDUINCARGO
	jnz .hasincargo
	call clearindustryincargos

.hasincargo:
.nonewindus:

	mov byte [lastextraindustiledata],0

	// check station2 array
	cmp dword [stationarray2ptr],0
	je .no_station2
	test byte [extrachunksloaded2],LOADED_X2_STATION2
	jnz .station2_ok
	call station2clear
.station2_ok:
	call station2init
.no_station2:

	// check player2 array
	cmp dword [player2array],0
	jle .noplayer2
	test byte [extrachunksloaded2],LOADED_X2_PLAYER2
	jnz .player2ok
	call player2clear
.player2ok:
.noplayer2:

	testflags newcargos
	jnc .copynewcargodata	// initialize newcargo* vars with default TTD values
	test byte [extrachunksloaded2],LOADED_X2_NEWCARGOTYPES
	jnz .newcargodata_ok
.copynewcargodata:
	call copyorgcargodata
	jmp short .newcargodata_ok
.nonewcargodata:
	test byte [landscape3+ttdpatchdata.flags],2
	jz .newcargodata_ok
	call clearstationcargodata
.newcargodata_ok:

	xor eax,eax			// clear industry tile overrides
	mov edi,industileoverrides
	lea ecx,[eax+0xAF]
	rep stosb

#if WINTTDX
	cmp byte [numplayers],2
	jne .enhmulti_done
	testflags enhancemultiplayer
	jnc .enhmulti_done
	cmp byte [titlescreenloading],0
	jnz .enhmulti_done

	mov byte [orighumanplayers],0
	and dword [isremoteplayer],0
	cmp byte [realplayernum],2
	je .oldformat
	mov al,[landscape3+ttdpatchdata.remoteplayers]
	mov [isremoteplayer],al
	mov al,[landscape3+ttdpatchdata.orighumanplayers]
	mov [orighumanplayers],al
	jmp short .enhmulti_done

.oldformat:
	movzx eax,byte [human2]
	cmp eax,8
	jae .enhmulti_done
	bts dword [isremoteplayer],eax
	movzx eax,byte [landscape3+ttdpatchdata.orgpl1]
	bts [orighumanplayers],eax
	movzx eax,byte [landscape3+ttdpatchdata.orgpl2]
	bts [orighumanplayers],eax
.enhmulti_done:
#endif

	call updategamedata
	
	// looks like it's all. Whew!

	// now initialize the newgrfs.  this needs to run after loading
	// a game because the grfs may need to know some savegame data
	// like the climate

	call infoapply
	call updatevehvars

	// finally make sure all vehicles have correct new sprites
	// in case newgrf.txt has changed

	call resetnewsprites

	testflags newtownnames
	jnc .nofindtownname
	call findcurrtownname
.nofindtownname:

	testflags custombridgeheads
	jnc .nobridgeheads
	call convertbridgeheads
.nobridgeheads:
	or al,1				// indicate success (CF=ZF=0)
	ret
; endp newloadproc


// Called after loading a savegame/scenario or after generating a random game
//
exported updategamedata
	extern followvehicleidx
	or dword [followvehicleidx],byte -1	// reset followvehicle
	extjmp makerelations


// Delete an entire consist from the vehicle array
//
// in:	eax->veharray
//	ecx->vehicle within consist
//	edx->loadremovedvehs
// uses:esi
global deleteconsist
deleteconsist:
	movzx esi,word [ecx+veh.engineidx]
	shl esi,vehicleshift
	add esi,eax

	testflags pathbasedsignalling
	jnc .dontclearpbs
	call cleartrainsignalpath
.dontclearpbs:

	cmp byte [esi+veh.class],0x14
	jae short .delspec
	inc word [byte edx+loadremovedcons-loadremovedvehs]

.delloop:
	inc word [edx]
	jmp short .delschedule

.delspec:
	inc word [byte edx+loadremovedsfxs-loadremovedvehs]

.delschedule:
	cmp dword [esi+veh.scheduleptr],byte -1
	jz short .delveh
	pusha
	mov edx,esi
	call [delvehschedule]
	popa

.delveh:
	call dword [delveharrayentry]		// preserves all registers
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	jne .next

	ret

.next:
	shl esi,vehicleshift
	add esi,eax
	cmp byte [esi+veh.class],0x14
	jae short .delspec
	jmp short .delloop



// Save a chunk's header.  Assume [extrachunkheader.id] already contains the ID, and EAX=length
// also assumes ES=DS, EBP->save function
// preserves all registers
savechunkheader:
#if DEBUG
	cmp ebp,loadsavechunkhelper
	jne .ok
	ud2	// savechunkheader called twice
.ok:
#endif
	pusha
	mov esi,extrachunkheader
	mov [esi+extrachunkhdr.length],eax
	xor ecx,ecx
	mov cl,extrachunkhdr_size
	call ebp
	popa
#if DEBUG
	mov [realloadsavefn],ebp
	mov [chunksize],eax
	mov ebp,loadsavechunkhelper
#endif
	ret
	
#if DEBUG
uvard chunksize
uvard realloadsavefn
	
loadsavechunkhelper:
	sub [chunksize], ecx
	jns .ok
	ud2	// too many bytes read/written.
.ok:
	jmp [realloadsavefn]
#endif


// Bad chunk (see below for registers)
badchunk:
	or byte [loadproblem],LOADPROBLEM_BADCHUNK
	// fallthrough

// Unknown or bad chunk, skip
// in:	EAX=length, EBP->load function, ES=DS
// uses:EAX,ECX,ESI
// note: assumes [extrachunkheader.id] contains the chunk ID
// note: EBP may not be valid if EAX=0
skipchunkonload:
	mov esi,extrachunkheader		// used later in this function as a bit bucket
	test byte [esi+extrachunkhdr.id+1],0x80	// is it a non-optional chunk?
	jz .notrequired
	or byte [loadproblem],LOADPROBLEM_RCHUNKNOTLOADED

.notrequired:
	xor ecx,ecx
	inc ecx				// load byte by byte (no need to optimize, the load function does the same)
	inc eax
	jmp short .startloop		// EAX may be 0 on entry!

.skiploop:
	pusha
	call ebp
	popa

.startloop:
	dec eax
	jnz .skiploop
	ret


// Load, save and query functions for the extra chunks.
// All these functions are called with ES=DS.
// Load and save functions are called with:
//	EBX->extrachunkheader (for convenience)
// Load functions are additionally called with:
//	EBP=[loadchunkfn] (i.e. points at TTD's chunk load function)
//	EAX=number of bytes to read (=extrachunkheader.length)
// Save functions are additionally called with:
//	EBP=[savechunkfn] (i.e. points at TTD's chunk save function)
// Query functions are additionally called with:
//	CF=0 if loading, 1 if saving
// Load and save functions return no value.
// Query functions return with CF set (can save/load this chunk) or clear (do not save/load this chunk).
//
// Save functions are supposed to start with determining the size the chunk will have and calling savechunkheader.
// They *MUST* save at least a valid header, no matter what. The only way they're allowed to fail is by setting
// EAX to zero and jumping through savechunkheader (or an equivalent action), but it's better to fail
// in the corresponding query function.
//
// Load functions are called after a header has been read; if the chunk itself cannot or should not be read,
// they should call (or jump to) badchunk or skipchunkonload. In any case, the correct number of bytes must be read.
//
// All registers except the stack and segment registers are safe and need not be preserved.


// All query functions for chunks that depend only on saveoptdata being ON go here
canhavepersistenttexts:
canhavespecvehdata:
canhavettdvehdata:
canhavepatchconfig:
canhaveoptionaldata:		// generic label
	testflags saveoptdata
	ret

// Query functions for optional chunks that depend on other features as well as saveoptdata

canhaveenhanceguioptions:
	testflags enhancegui		// currently equivalent to checking if [enhanceguioptions_savedata] is nonzero
	jc canhaveoptionaldata
	ret

canhavewindowsizes:
	testflags enhancegui
	jc canhaveoptionaldata
	ret

loadspecvehdata:
	cmp eax,specvehdatalength
	jne badchunk
	jmp short loadsavespecvehdata

savespecvehdata:
	mov eax,specvehdatalength
	call savechunkheader

	mov esi,[vehtypedataconvbackupptr]
	test esi,esi
	jnz short loadsavespecvehdata.usevehdatabackup

loadsavespecvehdata:
	mov esi,[vehtypedataptr]

.usevehdatabackup:
	mov ecx,totalvehtypes*vehtypeinfo_size
	call ebp

#if WINTTDX
	mov edx,datastart
	neg edx
	call adjspecvehdataptrs
#endif
	xor ebx,ebx

.saveloop:
	call getspecificpropertyarea		// sets ESI,ECX
	call ebp
	inc ebx
	cmp ebx,4
	jb .saveloop

.done:
#if WINTTDX
	mov edx,datastart
	call adjspecvehdataptrs
#endif
//*	or byte [extrachunksloaded1],LOADED_X1_TTDVEHDATA	// meaningless when saving
	ret

#if WINTTDX
adjspecvehdataptrs:
	xor ecx,ecx
	mov esi,[specificpropertybase]
	add esi,NTRAINTYPES*6
	mov cl,NTRAINTYPES
.loop1:
	cmp dword [esi],byte 0
	je .next1
	add [esi],edx
.next1:
	add esi,byte 4
	loop .loop1

	mov esi,[specificpropertybase+4]
	add esi,NROADVEHTYPES*2
	mov cl,NROADVEHTYPES
.loop2:
	add [esi],edx
	add esi,byte 4
	loop .loop2
	ret
#endif


// load and save TTDPatch vehicle data (from newvehdata struct)
loadttdvehdata:
	// this is probably superfluous, but it won't hurt either
	// the intent is mainly to make sure that if the data is from
	// an older version that saved fewer bytes, that the remainder
	// is initialized properly
	pusha
	call initttdpatchdata
	popa

	xor ebx,ebx
	mov ecx,newvehdatastruc_size
	sub ecx,eax
	jae .nottoomuch

	add eax,ecx
	sub ebx,ecx

.nottoomuch:
	jmp short loadsavettdvehdata

savettdvehdata:
	mov eax,newvehdatastruc_size
	call savechunkheader
	xor ebx,ebx

loadsavettdvehdata:
	mov esi,newvehdata
	xchg ecx,eax
	call ebp

	// we may have to get rid of surplus data on load
	// so that the following chunks (if any) will load properly
	xchg eax,ebx
	jmp skipchunkonload		// for now we don't indicate this condition; perhaps we should
					// also, this relies on skipchunkonload doing nothing when EAX=0...


canhaveoldgrfidlist:	// old style, only load, don't save
	cmc
	ret

canhavegrfidlist:
	jc .checksave
	stc		// always load (whether it ends up being used or not)
	ret

.checksave:
	testflags canmodifygraphics	// and save if canmodifygraphics is set
	ret

// load the list of GRF IDs we know about
loadgrfidlist:
	mov ecx,eax
	jecxz .nothing

	xor edx,edx
	lea ebx,[edx+5]
	div ebx		// find out how many entries
	mov [grfidlistnum],eax

	call makegrfidlistsize

	mov esi,[grfidlist]
	call ebp

	// with a GRF ID list loaded, only activate those .grfs that we know
#if 0
	// unless loadallgraphics is on
	testflags loadallgraphics
	setc [activatedefault]
#endif
	mov byte [activatedefault],0

	// add grf IDs that we have now that weren't in the list before
	// setting them to the activatedefault
	mov dh,0
	call makegrfidlist

.nothing:
	ret


// save the list of GRF IDs we know about
savegrfidlist:
	mov dh,1
	call makegrfidlist
	imul eax,[grfidlistnum],5
	call savechunkheader
	mov esi,[grfidlist]
	mov ecx,eax
	jecxz .nothing
	call ebp
.nothing:
	ret


// save the current configuration and variables
savepatchconfig:
	mov eax,flag_data_size + 4
	call savechunkheader

	mov esi,ttdpatchvercode
	mov ecx,4
	call ebp

	mov esi,startflagdata
	mov ecx,flag_data_size
	call ebp
	ret


// Query, load and save functions for the town array 2
canhavetown2array:
	mov eax,[townarray2ofst]
	neg eax				// set CF if EAX is nonzero
	ret


loadtown2array:
	cmp eax,numtowns*town2_size
	jne badchunk
	jmp short loadsavetown2array

savetown2array:
	mov eax,numtowns*town2_size
	call savechunkheader

loadsavetown2array:
	xchg ecx,eax
	mov eax,[townarray2ofst]
	lea esi,[eax+townarray]
	call ebp

	or byte [extrachunksloaded1],LOADED_X1_TOWN2	// meaningless when saving
	ret


// Load and save functions for enhancegui options
loadenhanceguioptions:
	cmp eax,12
	jne badchunk
	jmp short loadsaveenhanceguioptions

saveenhanceguioptions:
	mov eax,12
	call savechunkheader

loadsaveenhanceguioptions:
	xchg ecx,eax
	mov esi, [enhanceguioptions_savedata]
	call ebp

	or byte [extrachunksloaded1],LOADED_X1_ENHGUI	// meaningless when saving
	ret

loadwindowsizes:
	cmp eax,40
	jne badchunk
	jmp short loadsavewindowsizes

savewindowsizes:
	mov eax,40
	call savechunkheader
	call SaveWindowSizesPrepare

loadsavewindowsizes:
	mov ecx, eax
	mov esi, [windowsizesbufferptr]
	call ebp
	or byte [extrachunksloaded2],LOADED_X2_WINDOWSIZES	// meaningless when saving
	
	ret
// Query, load and save functions for the landscape6 array
canhavelandscape6array:
	mov eax,landscape6
	shl eax,1
	cmc
	ret

loadlandscape6array:
	cmp eax,0x10000+4
	jne badchunk
	call loadsavelandscape6array
	ret


savelandscape6array:
	mov eax,0x10000+4
	call savechunkheader
	xor ecx,ecx
	testflags abandonedroads
	jnc .noaban
	or ecx,L6_ABANROAD
.noaban:
	testflags newstations
	jnc .nonewstat
	or ecx,L6_NEWSTATIONS
.nonewstat:
	testflags newhouses
	jnc .nonewhouses
	or ecx,L6_NEWHOUSES
.nonewhouses:
	testflags pathbasedsignalling
	jnc .nopathsig
	or ecx,L6_PATHSIG
.nopathsig:
	testflags newindustries
	jnc .nonewindustries
	or ecx,L6_NEWINDUSTRIES
.nonewindustries:
	or ecx,L6_SIZECORRECT
	mov [l6switches],ecx

loadsavelandscape6array:
	xor ecx,ecx
	mov cl,4
	sub eax,ecx
	push eax
	mov esi,l6switches
	call ebp
	pop ecx

	mov esi,landscape6
	call ebp

	test dword [l6switches],L6_SIZECORRECT
	jnz .sizewascorrect

	// there are four bytes of garbage following the chunk
	push eax	// save them to the stack
	mov esi,esp
	mov ecx,4
	call ebp
	pop eax

.sizewascorrect:
	or byte [extrachunksloaded1],LOADED_X1_L6ARRAY	// meaningless when saving
	ret


// Functions for the new station map
canhavestationidmap:
	jc .saving

	// can always load it, set that we have it if so
	mov byte [havestationidgrfmap],1
	stc
	ret

.saving:
	// save only if the mapping list isn't empty
	cmp byte [havestationidgrfmap],1
	cmc
	// carry set if value was 1
	ret

loadstationidmap:
	cmp eax,256*2*4
	jne badchunk

	call savestationidmap.doloadsave

global clearstationgameids
clearstationgameids:
	// reset all .gameids; they'll get their proper value later
	xor eax,eax
.setnext:
	mov [stationidgrfmap+eax*8+stationid.gameid],ah
	add al,1
	jnc .setnext
	ret


savestationidmap:
	mov eax,256*2*4
	call savechunkheader

.doloadsave:
	xchg ecx,eax
	mov esi,stationidgrfmap
	call ebp
	ret

// Query, load and save functions for the landscape7 array
canhavelandscape7array:
	mov eax,landscape7
	shl eax,1
	cmc
	ret

loadlandscape7array:
	cmp eax,0x10000
	jne .notoldformat
	mov dword [l7switches],L7_HIGHERBRIDGES
	xchg eax,ecx
	jmp short loadsavelandscape7array.oldformat

.notoldformat:
	cmp eax,0x10000+4
	jne badchunk
	jmp short loadsavelandscape7array

savelandscape7array:
	mov eax,0x10000+4
	call savechunkheader
	xor ecx,ecx
	testflags higherbridges
	jnc .nohigh
	or ecx,L7_HIGHERBRIDGES
.nohigh:
	testflags newhouses
	jnc .nonewhouses
	or ecx,L7_NEWHOUSES
.nonewhouses:
	testflags newindustries
	jnc .nonewindustries
	or ecx,L7_NEWINDUSTRIES
.nonewindustries:

	testflags onewayroads
	jnc .noonewayroads
	or ecx,L7_ONEWAYROADS
.noonewayroads:
	testflags newstations
	jnc .nonewstations
	or ecx,L7_NEWSTATIONS
.nonewstations:

	mov [l7switches],ecx

loadsavelandscape7array:
	xor ecx,ecx
	mov cl,4
	sub eax,ecx
	push eax
	mov esi,l7switches
	call ebp
	pop ecx

.oldformat:
	mov esi,landscape7
	call ebp

	or byte [extrachunksloaded1],LOADED_X1_L7ARRAY	// meaningless when saving
	ret

canhavehouseidmap:
	testflags newhouses
	ret

loadhouseidmap:
	cmp eax,256*8+4
	jne badchunk
	call loadsavehouseidmap
	jmp clearhousedataids		// gameids are no longer valid

savehouseidmap:
	mov eax,256*8+4
	call savechunkheader

loadsavehouseidmap:
	xor ecx,ecx
	mov cl,4
	sub eax,ecx
	push eax
	mov esi,lasthousedataid
	call ebp
	pop ecx

	mov esi,housedataidtogameid
	call ebp

	or byte [extrachunksloaded1],LOADED_X1_HOUSEIDARRAY	// meaningless when saving
	ret
	
canhaveanimtiles:
	testflags moreanimation
	ret

loadanimtiles:
	mov ebx,eax
	shr ebx,1
	cmp ebx,dword [animarraysize]
	ja .truncate

	mov esi, [newanimarray]
	mov ecx,eax
	push eax
	call ebp
	pop eax
	or byte [extrachunksloaded1],LOADED_X1_ANIMTILES
	mov edi, [newanimarray]
	add edi,eax
	mov ecx,[animarraysize]
	shl ecx,1
	sub ecx,eax
	xor al,al
	rep stosb
	ret

.truncate:
	push eax
	mov esi, [newanimarray]
	mov ecx, [animarraysize]
	shl ecx,1
	push ecx
	call ebp
	pop ecx
	pop eax
	sub eax,ecx
	or byte [extrachunksloaded1],LOADED_X1_ANIMTILES
	jmp skipchunkonload

saveanimtiles:
	mov eax,[animarraysize]
	shl eax,1
	call savechunkheader
	mov ecx,eax
	mov esi, [newanimarray]
	jmp ebp
		

// Query, load and save functions for the newshistory array
canhavenewshistory:
	mov eax,[newshistoryptr]
	neg eax
	ret

loadnewshistory:
	cmp eax,NEWS_HISTORY_SIZE*newsitem_size
	jne badchunk
	jmp short loadsavenewshistory

savenewshistory:
	mov eax,NEWS_HISTORY_SIZE*newsitem_size
	call savechunkheader

loadsavenewshistory:
	xchg ecx,eax
	mov esi, [newshistoryptr]
	call ebp

	or byte [extrachunksloaded1],LOADED_X1_NEWSHISTORY	// meaningless when saving
	ret

canhaveindustrymap:
canhaveindustileidmap:
canhaveinduincargodata:

	testflags newindustries
	ret

loadindustileidmap:
	cmp eax,256*8+4
	jne badchunk
	call loadsaveindustileidmap
	jmp clearindustiledataids		// gameids are no longer valid

saveindustileidmap:
	mov eax,256*8+4
	call savechunkheader

loadsaveindustileidmap:
	xor ecx,ecx
	mov cl,4
	sub eax,ecx
	push eax
	mov esi,lastindustiledataid
	call ebp
	pop ecx

	mov esi,industiledataidtogameid
	call ebp

	or byte [extrachunksloaded1],LOADED_X1_INDUSTILEIDARRAY	// meaningless when saving
	ret

loadindustrymap:
	cmp eax,8*NINDUSTRYTYPES
	jne badchunk
	jmp short loadsaveindustrymap

saveindustrymap:
	mov eax,8*NINDUSTRYTYPES
	call savechunkheader

loadsaveindustrymap:
	xchg ecx,eax
	mov esi,industrydataidtogameid
	call ebp

	or byte [extrachunksloaded2],LOADED_X2_INDUSTRYMAP	// meaningless when saving
	ret

loadpersistenttexts:
	cmp eax,8*$400
	jne badchunk
	jmp short loadsavepersistenttexts

savepersistenttexts:
	mov eax,8*$400
	call savechunkheader

loadsavepersistenttexts:
	xchg ecx,eax
	mov esi,persistentgrftextlist
	call ebp

	or byte [extrachunksloaded2],LOADED_X2_PERSISTENTTEXTS	// meaningless when saving
	ret

// Query, load and save functions for the station2 array
canhavestation2array:
	mov eax,[stationarray2ptr]
	neg eax
	ret

loadstation2array:
	cmp eax,(station2_size*numstations)+4
	jne badchunk
	call loadsavestation2array
	ret


savestation2array:
	mov eax,(station2_size*numstations)+4
	call savechunkheader
	xor ecx,ecx
	testflags fifoloading
	jnc .nofifoloading
	or ecx,S2_FIFOLOADING
.nofifoloading:
	testflags generalfixes
	jnc .nocatchment
	test dword [miscmodsflags],MISCMODS_NOEXTENDSTATIONRANGE
	jnz .nocatchment
	or ecx,S2_CATCHMENT
.nocatchment:
	testflags newcargos
	jnc .nonewcargos
	or ecx,S2_NEWCARGO
.nonewcargos:

	testflags irrstations
	jnc .noirrstations
	or ecx,S2_IRRSTATIONS
.noirrstations:
	mov [station2switches],ecx

loadsavestation2array:
	xor ecx,ecx
	mov cl,4
	sub eax,ecx
	push eax
	mov esi,station2switches
	call ebp
	pop ecx

	mov esi,[stationarray2ptr]
	call ebp

	or byte [extrachunksloaded2],LOADED_X2_STATION2	// meaningless when saving
	ret

loadinduincargodata:
	cmp eax,8*NUMINDUSTRIES
	jne badchunk
	jmp short loadsaveinduincargodata

saveinduincargodata:
	mov eax,8*NUMINDUSTRIES
	call savechunkheader

loadsaveinduincargodata:
	xchg ecx,eax
	mov esi,industryincargos
	call ebp

	or byte [extrachunksloaded2],LOADED_X2_INDUINCARGO	// meaningless when saving
	ret

canhavenewcargotypes:
	testflags newcargos
	ret

copybackcargodata:
//Copy the beginning of the new arrays to the old place in case this will be loaded
//with this switch being off
	push esi
	mov esi, newcargotypenames
	mov edi, cargotypenames
	mov ecx, 12
	rep movsw

	mov esi, newcargounitnames
	mov edi, cargounitnames
	mov cl, 12
	rep movsw

	mov esi, newcargoamount1names
	mov edi, cargoamount1names
	mov cl, 12
	rep movsw

	mov esi, newcargoamountnnames
	mov edi, cargoamountnnames
	mov cl, 12
	rep movsw

	mov esi, newcargoshortnames
	mov edi, cargoshortnames
	mov cl, 12
	rep movsw

	mov esi, newcargoicons
	mov edi, cargoicons
	mov cl, 12
	rep movsw

	mov esi, newcargounitweights
	mov edi, cargounitweights
	mov cl, 12
	rep movsb

	mov esi, newcargodelaypenaltythresholds1
	mov edi, cargodelaypenaltythresholds1
	mov cl, 12
	rep movsb

	mov esi, newcargodelaypenaltythresholds2
	mov edi, cargodelaypenaltythresholds2
	mov cl, 12
	rep movsb

//price of passengers is important, it shouldn't ever be overwritten!
	mov esi, newcargopricefactors+8
	mov edi, cargopricefactors+8
	mov cl,2*11
	rep movsd

	pop esi
	ret

loadnewcargotypes:
	cmp eax, newcargodatasize
	jne badchunk
	jmp short loadsavenewcargotypes

savenewcargotypes:
	mov eax, newcargodatasize
	call savechunkheader

loadsavenewcargotypes:
	mov esi,newcargotypenames
	mov ecx, 2*32
	call ebp

	mov esi, newcargounitnames
	mov ecx, 2*32
	call ebp

	mov esi, newcargoamount1names
	mov ecx, 2*32
	call ebp

	mov esi, newcargoamountnnames
	mov ecx, 2*32
	call ebp

	mov esi, newcargoshortnames
	mov ecx, 2*32
	call ebp

	mov esi, newcargoicons
	mov ecx, 2*32
	call ebp

	mov esi, newcargounitweights
	mov ecx, 32
	call ebp

	mov esi, newcargodelaypenaltythresholds1
	mov ecx, 32
	call ebp

	mov esi, newcargodelaypenaltythresholds2
	mov ecx, 32
	call ebp

	mov esi, newcargopricefactors
	mov ecx, 8*32
	call ebp

	mov esi, newcargocolors
	mov ecx, 32
	call ebp

	mov esi, newcargographcolors
	mov ecx, 32
	call ebp

	or byte [extrachunksloaded2],LOADED_X2_NEWCARGOTYPES	// meaningless when saving
	ret

// Query, load and save functions for the company statistics
canhavecompanystats:
	mov eax,[companystatsptr]
	neg eax				// set CF if EAX is nonzero
	ret

loadcompanystats:
	cmp eax,8*4*32
	jne badchunk
	jmp short loadsavecompanystats

savecompanystats:
	mov eax,8*4*32
	call savechunkheader

loadsavecompanystats:
	xchg ecx,eax
	mov esi,[companystatsptr]
	call ebp
	ret

// Player 2 array function
canhaveplayer2array:
	mov eax,[player2array]
	neg eax				// set CF if EAX is nonzero
	ret

loadplayer2array:
	call player2clear
	push eax
	mov esi,esp
	mov ecx,4
	push eax
	call ebp			// load saved array size into [esp]
	pop eax
	imul ecx,[esp],8
	sub eax,4
	cmp ecx,eax
	jne .bad

	xor eax,eax

.loadnextplayer:
	push eax
	imul esi,eax,0+player2_size
	add esi,[player2array]
	mov ecx,[esp+4]		// now ecx=saved array size
	cmp ecx,0+player2_size
	jbe .ok
	mov ecx,player2_size	// load only as much as fits
	call ebp
	mov esi,cargoids	// use as temporary storage; it'll be reset anyway
	mov ecx,[esp+4]
	sub ecx,0+player2_size	// and skip the rest
.ok:
	call ebp
	pop eax
	inc eax
	cmp eax,8
	jb .loadnextplayer
	pop ecx
	or byte [extrachunksloaded2],LOADED_X2_PLAYER2
	ret

.bad:
	pop ecx
	jmp badchunk

saveplayer2array:
	mov ecx,player2_size
	push ecx
	lea eax,[4+ecx*8]
	call savechunkheader

	mov ecx,4
	mov esi,esp
	call ebp			// save array entry size

	mov esi,[player2array]
	pop ecx
	shl ecx,3			// gives array size
	call ebp			// save actual array
	ret


//
// End of extra chunk load/save/query functions
//


// find engines of each vehicle in all consists
global findengines
findengines:
	pusha

	// first clear engine for all vehicles

	mov esi,[veharrayptr]
	mov edi,[veharrayendptr]
	push esi

.vehicleloop:
	mov word [esi+veh.engineidx],-1

.nextvehicle:
	sub esi,byte -vehiclesize
	cmp esi,edi
	jb short .vehicleloop

	// now find all engines and record them in their consists
	pop esi		// pop+push = mov esi,[veharrayptr]
	push esi

.vehicleloop2:
	mov al,[esi+veh.class]
	cmp al,0x10
	jb .nextvehicle2
	ja .nottrain

	cmp byte [esi+veh.subclass],4
	je .isfirst

.nottrain:
	cmp word [esi+veh.engineidx],byte -1
	jne .nextvehicle2

.isfirst:
	// follow the chain of vehicles
	// (whether the current one is an engine or not)
	push esi
	mov ax,[esi+veh.idx]
	mov ebx,eax

.recordnext:
	mov [esi+veh.engineidx],ax
	cmp byte [esi+veh.artictype],0xfd
	jb .notartic
	mov [esi+veh.articheadidx],bx
.notartic:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .nextvehicle2a
	shl esi,vehicleshift
	add esi,[veharrayptr]
	jmp short .recordnext

.nextvehicle2a:
	pop esi

.nextvehicle2:
	sub esi,byte -vehiclesize
	cmp esi,edi
	jb short .vehicleloop2

	// and finally set engineidx=idx for all vehicles which we
	// haven't touched yet (just to be safe)

	pop esi

.vehicleloop3:
	cmp word [esi+veh.engineidx],byte -1
	jne .nextvehicle3

	mov ax,[esi+veh.idx]
	mov [esi+veh.engineidx],ax

.nextvehicle3:
	sub esi,byte -vehiclesize
	cmp esi,edi
	jb short .vehicleloop3


	popa
	ret

// set veh.veh2ptr and veh2.vehptr variables
global initveh2
initveh2:
	pusha
	mov esi,[veharrayptr]
	mov edi,[veh2ptr]

.next:
	mov [esi+veh.veh2ptr],edi
	mov [edi+veh2.vehptr],esi
	sub esi,byte -vehiclesize
	add edi,byte veh2_size
	cmp esi,[veharrayendptr]
	jb .next
	popa
	ret

// updates various cached vehicle vars after loading a game
//
// we need the correct weight and MOD_POWERED flag for all train
// vehicles with realistic acceleration
// recalculate it here, in case real.accel. was just turned on
// also recalculates the cached 40+x variables and consist callbacks for
// all vehicle types
global updatevehvars
updatevehvars:
	pusha
	mov esi,[veharrayptr]

.next:
	mov al,[esi+veh.class]
	cmp al,0x10
	jb .nextveh
	je .trains
	cmp al,0x11
	je .rvs
	cmp al,0x13
	ja .nextveh

.planeships:
	cmp dword [esi+veh.scheduleptr],byte -1
	je .nextveh

	push esi
	call consistcallbacks
	pop esi
	jmp short .nextveh

.rvs:
	call setrvweightandpower
	jmp short .nextveh

.trains:
	cmp dword [esi+veh.scheduleptr],byte -1
	je .nextveh

	push esi
	call consistcallbacks
	pop esi
	call calcpowerandspeed	// to set MOD_POWERED
	call calcconsistweight
	call calcaccel

.nextveh:
	sub esi,byte -veh_size
	cmp esi,[veharrayendptr]
	jb .next

	popa
	ret


// set the default save game file name
// if saved veh.mult is 0 or 1, it's "TRT00.SV1", otherwise "TRP00.SV1"
// safe:ebx,esi,edi,al,cl
// out:	edi=ptr to where filename is stored (only for the patch)
global savedefaultname
proc savedefaultname
	arg fn

	_enter

	mov edi,[%$fn]
	mov dword [edi],"TRT0"

	testflags uselargerarray
	jnc short .keepfirstpart

	cmp byte [vehicledatafactor],1
	jbe short .keepfirstpart

	mov byte [edi+2],'P'	// save as TRP??.SV1

.keepfirstpart:
	mov dword [edi+4],"0.SV"
	mov word [edi+8],'1'

	cmp byte [numplayers],2
	jne .goodname

	mov byte [edi+8],'2'
#if WINTTDX
	testflags enhancemultiplayer
	jnc .goodname

	mov al,[realplayernum]
	add al,'0'
	mov [edi+8],al

#endif
.goodname:
	_ret
endproc ; savedefaultname



global checkloadsuccess
checkloadsuccess:
	pushf

	cmp byte [gamemode],2
	je .notowncheck

	pusha
	mov edi,townarray
	mov ecx,numtowns

.checknexttown:
	cmp word [edi+town.XY], 0
	jne .hastown
	add edi, town_size
	loop .checknexttown

	mov bx, ourtext(warning_notowns)
	or edx,-1
	jmp short .showerror

.hastown:
	popa

.notowncheck:
	movzx eax,byte [loadreduced]
	test al,al
	jnz .reduced

	test byte [loadproblem],LOADPROBLEM_RCHUNKNOTLOADED
	jnz .rchunksnotloaded

	cmp dword [spriteerror],0
	je .done

	call grferror

.done:
	popf
	jnz short .dofarjmpnotret
	ret

.dofarjmpnotret:
	add esp,byte 4		// remove return address from stack
	jmp near $+0x200	// far jmp instead
ovar endofloadtarget,-4

.rchunksnotloaded:
	pusha
	mov bx,ourtext(rchunknotloaded)
	or edx,byte -1
	jmp short .showerror

.reduced:
	pusha

	// show error popup
	mov esi,textrefstack
	mov [esi],eax			// store the original vehicle array multiplier
	mov eax,[loadremovedvehs]
	mov [esi+2],eax
	mov eax,[loadremovedsfxs]
	mov [esi+6],eax			// upper word irrelevant

	mov bx,ourtext(vehmulttoolow)
	or edx,byte -1

.showerror:
	xor eax,eax
	xor ecx,ecx
	call dword [errorpopup]

	// pause the game
	mov bl,1
	mov esi,0x38
	call dword [actionhandler]

	popa
	jmp .done
; endp checkloadsuccess

// same as above but for loading title.dat
global checktitleloadsuccess
checktitleloadsuccess:
	cmp dword [spriteerror],0
	je .done

	call grferror

.done:
	mov ebx,6
	call [ebp+4]
	ret

global grferror
grferror:	// error while loading graphics
	pusha
	xor esi,esi
	xchg esi,[spriteerror]	// reset error after showing message

	test byte [spriteerrortype],2
				// was it a message generated by the grf file?
	jnz near dogrferrormsg	// if so process it differently (see grfload.asm)

	test byte [spriteerrortype],1
				// or a message not by the grf system but just
	jz .isgrfmsg		// handled similarly?

	mov bx,statictext(grfnotice)
	mov dx,-1
	test byte [spriteerrortype],4
	jnz .showmsg
	mov esi,[esi]
	jmp short .showmsg

.isgrfmsg:
	mov ax,[esi+spriteblock.cursprite]
	inc ax		// first sprite is sprite #1
	mov esi,[esi+spriteblock.filenameptr]

	mov [textrefstack+2],ax
	mov eax,[spriteerrorparam]
	mov [textrefstack+4],eax

	mov bx,ourtext(grfloaderror)
	mov dx,[operrormsg2]

.showmsg:
	mov [specialerrtext1],esi
	mov word [textrefstack],statictext(specialerr1)
	xor ax,ax
	xor cx,cx
	call dword [errorpopup]
	popa
	ret



#if WINTTDX
// Fix schedule pointers if loading a savegame from TTDPatchW 1.7 and older
// in: ESI -> vehicle array, ECX = newvehicles, EDX = offset to add
global bcfixcommandaddr
bcfixcommandaddr:
.fixcommandloop:
	cmp	byte [esi],0
	jz	short .nextveh
	cmp	dword [esi+veh.scheduleptr],byte -1
	jz	short .nextveh
	cmp	dword [esi+veh.scheduleptr],edx
	jnc	short .nextveh

	// when called before saving, edx = -dsbase (negative)
	// so unsigned (commandindex >= edx) cannot happen;
	// when called after loading or saving, edx = dsbase
	// so (commandindex >= edx) indicates bug in the game just loaded
	// in which case commandindex is best left alone

	add	dword [esi+veh.scheduleptr],edx
.nextveh:
	sub	esi,byte -vehiclesize	//add	esi,vehiclesize
	loop	.fixcommandloop
	ret
; endp bcfixcommandaddr

// Before we reduce the vehicle array, we have to adjust schedule pointers;
// after that, we have to set them back so that TTD's adjustment code works
// (we cannot use TTD's code because the loaded array is larger)
// in:	EAX -> vehicle array, EBP -> vehicle array's end, EDX = 1 (adjust) or -1 (set back)
// safe:everything
adjustscheduleptrs:
	pusha
	imul edx,datastart
	add dword [scheduleheapfree],edx
	mov esi,eax
	mov ecx,ebp
	sub ecx,eax
	shr ecx,vehicleshift
	call bcfixcommandaddr		// note: the fix will work whether adjustscheduleptrs is called or not
	popa
	ret

#endif /* WINTTDX */


// Fix AI's vehicle pointers on load or save
// in:	EDX -> correction subfunction (adjaivehicleptrsload or adjaivehicleptrssave)
// preserves:ESI,EBP
adjaivehicleptrs:
	movzx ebx,byte [vehicledatafactor]
	imul ebx,oldveharraysize
	mov edi,[playerarrayptr]
	xor ecx,ecx
	mov cl,8

.companyloop:
	cmp word [edi],0
	je .next
	mov al,[edi+0x2bb]
	cmp al,2
	je .needadj
	cmp al,3
	je .needadj
	cmp al,4
	je .needadj
	cmp al,0x14
	jne .next

.needadj:
	mov eax,[edi+0x2c2]
	call edx
	mov [edi+0x2c2],eax

.next:
	add edi,player_size
	loop .companyloop
	ret

// Adjust after load or save:
adjaivehicleptrsload:
	cmp eax,byte -1
	je .done

	sub eax,oldveharray_abs
	cmp eax,ebx
	jae .bad
	test al,vehiclesize-1
	jnz .bad

	add eax,[veharrayptr]
	jmp short .done

.bad:
	or eax,byte -1
	cmp byte [edi+0x2bb],2
	je .done
	mov byte [edi+0x2bb],1

.done:
#if WINTTDX
	sub eax,datastart		// later adjusted back by WinTTDX
#endif
	ret

// Adjust before save:
adjaivehicleptrssave:
#if WINTTDX
	add eax,datastart
#endif
	cmp eax,byte -1
	je .done

	sub eax,[veharrayptr]
	add eax,oldveharray_abs

.done:
	ret

