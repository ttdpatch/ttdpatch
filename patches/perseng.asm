
// Persistent engines

#include <std.inc>
#include <proc.inc>
#include <flags.inc>
#include <textdef.inc>
#include <veh.inc>
#include <vehtype.inc>
#include <newvehdata.inc>
#include <ptrvar.inc>

extern checkrefittable,isengine,patchflags
extern vehtypedataptr,newvehdata
extern TrainSpeedNewVehicleHandler.lnews

// Find what vehicles are currently in use
// With persistentengines on:
//	- all vehicles in the game are in use
//	- all vehicles whose model lifetime (prop. 04) is FF are in use
// Without persistenengines on:
//	- all vehicles whose model lifetime (prop. 04) is FF are in use
//
// By default, all wagons and the last model(s) of each class have prop 04
// set to FF, so that they remain available eternally
//
// in:	ebp-100h=pointer to a memory chunk that's totalengines bytes large
//	(will be initialized automatically)
// out:	each of these bytes is 1 if that engine is in use, 0 otherwise
// destroys eax, ebx, ecx, esi
global findusedengines
findusedengines:
	%define .engineuse ebp-totalvehtypes/8

		// clear @@engineuse array (can't use edi...)
	xor eax,eax
	lea ecx,[eax+totalvehtypes/4/8]	// mov ecx,... in 3 bytes
.clearnextengine:
	mov [.engineuse+ecx*4-4],eax
	loop .clearnextengine

	testmultiflags persistentengines
	jz .dontcheckexisting
		// now ecx=0, good for later.

		// determine engines that are in use
	mov esi,[veharrayptr]
.nextvehicle:
	mov eax,dword [esi+veh.class]
	cmp al,0x10
	jb short .vehicleloop
	cmp al,0x13
	ja short .vehicleloop
	jb short .notaplane

	// ignore airplane mail compartment and heli rotor
	cmp ah,4
	jae short .vehicleloop

.notaplane:
	mov cl,byte [esi+veh.vehtype]
	bts [.engineuse],ecx	// cool, bts automatically calculates the dword offset!

.vehicleloop:
	sub esi,byte -vehiclesize	//add esi,vehiclesize
	cmp esi,[veharrayendptr]
	jb .nextvehicle

.dontcheckexisting:
	// set all vehicles with lifetime = FF to in use if they have been
	// introduced already

	mov cl,0
	movzx eax,byte [climate]
	mov esi,dword [vehtypedataptr]
	mov ebx,vehtypearray

.nextvehtype:
	// introduced yet?
	test byte [ebx+vehtype.flags],1
	jz .skip

	// available in this climate?
	bt dword [esi+vehtypeinfo.climates],eax
	jnc short .skip

	// has lifetime FF?
	cmp byte [esi+vehtypeinfo.basedurphase2],255
	jne .skip

	// should be available forever
	bts [.engineuse],ecx

.skip:
	add esi,byte vehtypeinfo_size
	add ebx,byte vehtype_size
	inc cl
	jnz .nextvehtype

	ret
; endp findusedengines

	// called every month to determine new/outdated engines and
	// reliabilies
	//
	// safe to use: esi, eax, ebx, ecx
	// must set at exit: esi=enginestruct, cx=0
global monthlyengineloop
proc monthlyengineloop
	slocal engineuse,dword,totalvehtypes/4/8

	_enter

	call findusedengines

		// Engines that are used cannot get to within 2 years of the
		// end of their second phase.  If they are, set them back
	mov esi,vehtypearray
	push esi
	xor ecx,ecx
	push ecx
.nextengine:
	bt [%$engineuse],ecx
	jnc short .engineloop

		// right climate?
	imul eax,ecx,0+vehtypeinfo_size
	add eax,[vehtypedataptr]
	movzx ebx,byte [climate]
	bt [eax+vehtypeinfo.climates],ebx
	jnc .engineloop

		// this engine is in use
	and byte [esi+vehtype.availinfo],~3	// make it available if it wasn't
	or byte [esi+vehtype.availinfo],1
	mov word [esi+vehtype.playeravail],-1

		// check that's it's not about to expire
	mov ax,word [esi+vehtype.engineage]
	movzx ebx,byte [vehphase2dec+ecx]
	imul ebx,byte -12
	add bx,word [esi+vehtype.durphase1]
	add bx,word [esi+vehtype.durphase2]
	sub bx,byte 24		// 2 years before end of phase 2, or early ret.
	cmp ax,bx
	jb short .engineloop	// not old enough yet
	mov word [esi+vehtype.engineage],bx	// set age back

.engineloop:
	add esi,byte vehtype_size
	add cl,1
	jnc .nextengine			// 0x100 vehtypes

	pop ecx
	pop esi
	_ret
endproc // monthlyengineloop


// called when a new vehicle is available for exclusive testing
// skip the testing if it's a train waggon
//
// in:	cx=vehicle index
//	esi=index into vehtypearray
// out:	carry set if it's an engine
global newvehavailable
newvehavailable:
	or byte [esi+vehtype.flags],2
	mov byte [esi+vehtype.availinfo],1
	bt [isengine],cx
	ret

// called after a new vehicle announcement window has been set up
//
// in:	ebx=vehtype
// out:	 bx=text index (885B for engines, ourtext for wagons)
// safe:eax, ebx
global shownewrailveh
shownewrailveh:
	push edi

	bt [isengine],ebx
	jnc .prepwagon

	mov bx,0x885b

.iswagon:
	pop edi
	jmp near $+5
ovar doshownewrailveh, -4

.prepwagon:
	mov edi,textrefstack
	mov eax,[edi+14]
	mov [edi+6],eax

	// show "refittable" if appropriate
	mov ax,[edi+8]
	call checkrefittable
	mov [edi+10],ax

	// fix cost to use waggon base cost
//	mov eax,ebx
//	add eax,[enginepowerstable]
	movzx eax,byte [traincost+ebx]
;	movzx ebx,word [trainspeeds+ebx*2]
	call TrainSpeedNewVehicleHandler.lnews
	imul eax,[waggonbasevalue]
	shr eax,8
	mov [edi],eax

	lea eax,[ebx+1]

	mov bx,ourtext(newwagoninfo)

	testmultiflags wagonspeedlimits
	jz .iswagon

	cmp eax,2
	jb .iswagon

	mov ebx,[edi+8]
	mov [edi+10],ebx
	mov ebx,[edi+4]
	mov [edi+6],ebx
	mov ebx,[edi]
	mov [edi+2],ebx
	mov word [edi],ourtext(newwagoninfo)

	dec eax
	imul eax,10
	shr eax,4
	mov [edi+18],ax
	mov word [edi+14],ourtext(wagonspeedlimit)
	mov word [edi+16],statictext(empty)
	mov bx,statictext(ident2)

	jmp .iswagon


// called when setting the introduction date of an engine
//
// in:  eax=random number
//	 bx=base introduction date
// out:	 bx=adjusted introduction date
// safe:eax ebx
global setintrodate
setintrodate:
	cmp bx,730	// before 1922?
	jb .gotit	// if so, don't adjust the date
	and ax,511
	add bx,ax
.gotit:
	ret
