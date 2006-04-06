//
// "Unified maglev": monorail and maglev engines available for both types of railways
// (after all, monorail *is* maglev)
//

#include <std.inc>
#include <vehtype.inc>
#include <flags.inc>
#include <veh.inc>
#include <ptrvar.inc>

extern getaiselectioncallback,isengine,patchflags
extern railenginetypenames,tracktypes
extern vehsorttable


// Variable to hold how much position of Maglev class is moved up
// in rail construction menu
// is 1 if unimaglev=2 and not electrifiedrailway, 0 by default otherwise
uvarb maglevclassadjust


// Check if any engines of given railway type are available
// in the New Railway Vehicles window
// in:	ESI -> New Rail Vehicles window struct
//	 word [ESI+2Ah] = railway type
// out:	CF set if available, clear otherwise
// uses:DL
haverailenginesinwindow:
	mov dl,[esi+2ah]

// same as above, except:
// in:	DL = queried railway type
// uses:-
global haverailengines
haverailengines:
	pusha
	mov eax,vehtypearray
	xor ebx,ebx
	movzx ecx,byte [human1]

.checkloop:
	bt [isengine],ebx
	jnc .next
	bt [eax],ecx
	jnc .next

	push edx
	call isrightrailclass
	pop edx
	jc .done

.next:
	add eax,byte vehtype_size
	inc ebx
	cmp bl,NTRAINTYPES
	jb .checkloop

.done:
	popa
	ret


isrightrailclassinwindow:
	mov dl,[esi+2ah]

// Check if an engine/waggon is available for the current type of railway
// in:	EAX -> vehtype struct
//	EBX = vehtype ID
//	DL = current railway type
// out:	CF set if available, clear otherwise
// uses:EDX
isrightrailclass:
	mov dh,[eax+vehtype.enginetraintype]
	cmp dl,dh
	je short .isthere

	// OK, so it's not the right type, but perhaps should appear in the list anyway
	testflags unifiedmaglev
	jnc short .done

	testflags electrifiedrail
	jc short .electrified

	// eliminate conventional railroad vehicles and windows
	or dl,dl		// CF=0
	jz short .done
	or dh,dh
	jz short .done

	// all engines appear in both railway type lists
	bt [isengine],ebx

.done:
	ret

.electrified:
	// show all type=0 vehicles in type=1 depots
	xor dl,1		// CF=0
	jne short .done
	or dh,dh		// CF=0
	jne short .done

// i.e. type=1 are the electric engines, type=2 are the unified monorail and maglev
// (so the electric railways feature must force unifiedmaglev). There are no waggons of type=1.

.isthere:
	stc
	ret
; endp isrightrailclass


// Find a vehicle type in a list of available ones (common part of 3 almost identical loops)
// in:	ESI -> window struct
//	EBX = currently checked engine/waggon number (unsorted, so it's not the vehtype ID)
//	EAX -> vehtypearray entry corresponding to EBX
//	CL = number of engines/waggons to skip
//	BP = human player 1
// out:	CF=SF=1 = end of skipping; then EBX = vehtype ID
//	CL -= 1 if the vehicle is in the list
global skiprailvehsinwindow
skiprailvehsinwindow:
	// check if anything is displayed
	cmp eax,vehtypearray
	jne .continue
	push edx
	call haverailenginesinwindow
	pop edx
	jc .continue
	add eax,0x100*vehtype_size	// cause loop termination
	jmp short .return		// CF=0 or something's *really* wrong...

.continue:
	push eax
	push ebx

	// translate vehtype according to the sort table
	movzx ebx,byte [vehsorttable+ebx]
	imul eax,ebx,byte vehtype_size
	add eax,vehtypearray

	bt [eax],bp		// overwritten by runindex call
	jnc short .done

	// check if it's the right type
	push edx
	call isrightrailclassinwindow
	pop edx
	jnc short .done
	dec cl			// overwritten; leaves CF alone
	jns short .done
	mov [esp],ebx		// end of skipping - return the real vehtype ID (doesn't touch flags either)

.done:
	pop ebx
	pop eax

.return:
	ret
; endp skiprailvehsinwindow


// Called in a loop to count available railway vehicle types
// in:	ESI -> window struct
//	EBX -> currently checked engine/waggon (in vehtypearray)
//	CX = human player 1
//	DH = number of engines/waggons left to check
// i/o:	DL = number of engines/waggons found so far
global countrailvehtypes
countrailvehtypes:
	// check if anything is displayed
	cmp dh,NTRAINTYPES
	jne .continue
	push edx
	call haverailenginesinwindow
	pop edx
	jc .continue
	mov dh,1		// cause loop termination
	jmp short .done

.continue:
	bt [ebx],cx		// overwritten by runindex call
	jnc short .done

	// check if it's the right type
	pusha
	xchg eax,ebx
	xor ebx,ebx
	mov bl,NTRAINTYPES
	sub bl,dh		// relies on DH==NTRAINTYPES at the start of the loop!! (see patches.ah)
	call isrightrailclassinwindow
	popa

	adc dl,0		// overwritten by runindex call

.done:
	ret
; endp countrailvehtypes


// Called when assembling the railway vehicle list
// in:	ESI -> window struct
//	EBP = current engine/waggon number (unsorted)
//	EAX -> vehtypearray entry corresponding to EBP
// out:	CX = human player 1
//	CF clear if engine/waggon not available (see fragment.ah)
global israilvehonlist
israilvehonlist:
	cmp byte [esi+1],0	// total number of items
	jz .return

	push eax
	push ebx

	// translate vehtype according to the sort table
	movzx ebx,byte [vehsorttable+ebp]
	imul eax,ebx,byte vehtype_size
	add eax,vehtypearray

	movzx cx,[human1]	// overwritten by runindex call
	bt [eax],cx
	jnc .done

	push edx
	call isrightrailclassinwindow
	pop edx

.done:
	pop ebx
	pop eax

.return:
	ret
; endp israilvehonlist

// OK, the vehicle type is on list.  Translate the vehtype ID in EBP
// safe:EAX,EDI
global israilvehonlist2
israilvehonlist2:
	// have to PUSH a few things on the stack, so stuff the return address in a temp register
	pop edi

	push ebx
	push ebp				// save it for the loop (see patches.ah)
	movzx ebp,byte [vehsorttable+ebp]
	push cx
	push dx
	jmp edi
; endp israilvehonlist2


// Called when AI decides which train engine to buy
// in:	EDX -> current engine/waggon struct
//	BX = current engine/waggon ID
//	ESI = cash available
//	CL = cargo type for this service (see codefragments newisaipassengerservice and newcanaiusedualhead)
//	CH = bit 0 set: don't use passenger-optimized engines (checked later by TTD)
//	     bit 1 set: can use dual-headed engines
// out: CF set if it's an engine of the right type, clear otherwise
//	BP = current player (not needed if CF clear)
// safe:EAX
global canaibuyloco
canaibuyloco:
	// first, check if it's an engine
	movzx ebx,bx
	bt [isengine],ebx
	jnc near .done

	// check if it's the right type
	mov al,[dword -1]
ovar .gettraintype,-4,$,canaibuyloco

	xor al,[edx+vehtype.enginetraintype]	// CF=0
	je .righttype

	// didn't match, with elrails on can build train type 0 on rail type 1
	testmultiflags electrifiedrail
	jz .done	// CF=0

	// check whether maglev/not-maglev didn't match
	test al,2
	jnz .done

	// railtype	traintype	al now	ok
	//	0		1	1	no
	//	1		0	1	yes

	test byte [edx+vehtype.enginetraintype],1
	jnz .done

.righttype:
	// with newtrains, try the AI selection callback
	testmultiflags newtrains
	jz .defaultchecks

	pusha
	movzx eax,byte [edx+vehtype.enginetraintype]
	mov bh,bl
	mov bl,[tracktypes+eax]
	mov al,0
	movzx edx,cl
	call getaiselectioncallback
	jc .nocallback
	test bh,bh
.nocallback:
	popa
	ja .passed		// CF=0, ZF=0 -> passed
	jnc .done		// CF=0, ZF=1 -> failed
				// CF=1 -> no callback, resume checks

.defaultchecks:
	// check if it's dual-headed
//	mov eax,[enginepowerstable]
	test byte [numheads+ebx],1
	jz short .checkcargo

	// it is dual-headed; can we use those?
	test ch,2				// CF=0
	jnz short .done

.checkcargo:
	// check if it has the right cargo type, if any
	cmp byte [traincargosize+ebx],0
	je short .passed
	mov al,[traincargotype+ebx]
	cmp al,cl
	je short .passed
	test cl,~2				// CF=0
	jnz short .done
	test al,~2				// CF=0
	jnz short .done
	// one is passengers and the other is mail -- OK

.passed:
	// all tests passed
	movzx ebp,byte [curplayer]
	stc

.done:
	ret
; endp canaibuyloco


// Called when buying a new locomotive or waggon to determine the track type
// i/o:	ESI -> vehicle struct (landscapeindex already initialized)
// out:	AL = type
global settraintype
settraintype:
	mov al,[vehtypearray+ebx+vehtype.enginetraintype]	// overwritten by runindex call
	testflags electrifiedrail
	jc short .done

	movzx eax,word [esi+veh.XY]
	mov al,[landscape3+eax*2]
	and al,0xF

.done:
	ret
; endp settraintype


// Called when AI decides to replace a train engine
// (two occurences, one just for checking and the other for the actual replace)
// in:	ESI = player's cash
//	EDI -> first vehicle in the train
//	EDX -> last vehicle in the train
//	BL = number of vehicles in the train
//	BH = 0
// out:	BL = cargo type
//	BH = 0=can use passenger-optimized engines, 1=nope
//	     +2 to consider dual-headed engines too
// safe:EAX,ECX,EDX
global canaiusedualhead
canaiusedualhead:
	mov eax,edi
	cmp eax,edx				// just to be sure
	je short .checkcargo
	movzx eax,word [edi+veh.nextunitidx]
	shl eax,vehicleshift
	add eax,[veharrayptr]

.checkcargo:
	test bl,1
	mov bl,[eax+veh.cargotype]
	jnz short .done				// odd number of vehicles, so an extra engine won't hurt
	movzx ecx,word [edx+veh.vehtype]
	bt [isengine],ecx
	jc short .done				// last vehicle is an engine, can buy a dual-head again
	mov bh,2

.done:
	cmp word [eax+veh.capacity],byte 0
	jne .hascargo
	mov bl,-1				// cannot determine cargo type

.hascargo:
	test bl,~2				// check for passengers (0) or mail (2)
	je .fast
	or bh,1

.fast:
	ret
; endp canaiusedualhead

// Find text index for railway vehicle type
//
// in:	eax=vehtype
// out:	 bx=text index
// safe:eax,ebx
global getrailvehclassname
getrailvehclassname:
	imul ebx,eax,byte vehtype_size
	bt [isengine],eax
	movzx eax,byte [vehtypearray+ebx+vehtype.enginetraintype]
	jc .engine
	add eax,3
.engine:
	mov bx,[railenginetypenames+eax*2]
	ret


// Check if this loco has a higher AI rank than the one selected previously
//
// in:	al=new ai rank
//	ebx=vehtype num
//	edx->vehtype struct
// out:	CF set if not better
// safe:ebp
global airankcheck
airankcheck:
	cmp al,1
	jb .done
	cmp al,[dword 0]
ovar .bestrankofs, -4,$,airankcheck
.done:
	ret
