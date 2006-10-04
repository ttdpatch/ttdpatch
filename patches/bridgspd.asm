//
// Increase speed limit on monorail and maglev bridges without affecting other bridge types
// 

#include <std.inc>
#include <flags.inc>
#include <vehtype.inc>
#include <ptrvar.inc>
#include <veh.inc>

extern curtooltracktypeptr,isengine,newbridgespeedpc,newmaglevbridgespeeds
extern patchflags
extern vehtypedataptr





// get speed limit on a bridge
// in:	ESI = bridge type
//	ECX = railway type (0 if road)
//	EDX = original speed limit
// out: EDX = speed limit
// uses:ECX
getbridgespeedlimit:
	shl ecx,2
	jz short .done

	cmp esi,byte 9
	je short .good
	cmp esi,byte 10
	jne short .done

.good:
	movzx ecx,word [newmaglevbridgespeeds+(ecx-4)+(esi-9)*2]
	cmp edx,ecx
	jae short .done
	mov edx,ecx

.done:
	ret
; endp getbridgespeedlimit


// called to get the speed limit for the window display
// in:	AX = speed limit
//	EBX = bridge type
// out: AX = speed limit in mph
// safe:EBX
global displrailbridgespeed
displrailbridgespeed:
	push ecx
	mov ecx,[curtooltracktypeptr]
	movzx ecx,byte [ecx]
	xchg esi,ebx
	xchg eax,edx
	movzx edx,dx
	call getbridgespeedlimit
	xchg eax,edx
	xchg ebx,esi
	pop ecx

	shr ax,4	// overwritten by...
	imul ax,byte 10	// ... the runindex call
	ret
; endp displrailbridgespeed


// called to actually limit the speed of a vehicle
// in:	BX = coord of the square
//	ESI = bridge type
//	EDI -> vehicle
//	DH = L5[BX]
// out: DX = speed limit
// safe:EAX,ECX,ESI
global bridgespeedlimit
bridgespeedlimit:
	xor ecx,ecx
	test dh,6
	jnz short .road

	// get railway type of the bridge
	movzx ecx,bx
	mov cl,byte [landscape3+ecx*2]
	test dh,0x40
	jz short .endpart
	shr cl,4

.endpart:
	and ecx,byte 0xF

.road:
	movzx edx,word [dword -1+esi*2]	// overwritten by runindex call
ovar .limittable,-4,$,bridgespeedlimit
	call getbridgespeedlimit
	ret
; endp bridgespeedlimit


// Initialization-time procedure:
// set bridge speed limits for monorail and maglev
// uses:EAX,EBX,ECX,ESI,EDI
global setbridgespeedlimits
setbridgespeedlimits:
	xor ebx,ebx
	mov bl,1
	call calcnewbridgespeedlimits
	mov bl,2
	call calcnewbridgespeedlimits

	// if unified maglev is on, use the same speed limit for both monorail and maglev
	testflags unifiedmaglev
	jnc short .done

	// electrified trains on, leave type=1 (former monorail) bridges alone
	xor eax,eax		// this will work because the actual speed limit is never lower than original
	testflags electrifiedrail
	jc short .notype1

	// EDI still points to newmaglevbridgespeeds (see calcnewbridgespeedlimits)
	mov eax,[edi]
	cmp eax,[edi+4]		// the second speed is always 0.9 of the first one
	jae short .higher
	mov eax,[edi+4]
.higher:
	mov [edi+4],eax
.notype1:
	mov [edi],eax
.done:
	ret


// Calculate and store bridge speed limits for a given class of railway
// in:	EBX = track type
// out: EDI -> newmaglevbridgespeeds
// uses:EAX,ECX,ESI
calcnewbridgespeedlimits:
	// find the highest max. speed of a vehicle in this class
//	mov esi,[enginepowerstable]
//	add esi,speedfrompower
	mov esi,trainspeeds
	mov edi,[vehtypedataptr]
	xor eax,eax
	xor ecx,ecx

.loop:
	bt [isengine],ecx
	jnc .next

	cmp [edi+vehtypeinfo.traintype],bl
	jne short .next
	cmp ax,[esi]
	jae short .next
	mov ax,[esi]

.next:
	inc esi
	inc esi
	add edi,byte vehtypeinfo_size
	inc ecx
	cmp ecx,NTRAINTYPES
	jb .loop

	// calculate and store the bridge speed limits
	mov edi,newmaglevbridgespeeds
	push edx
	movzx edx,byte [newbridgespeedpc]
	mul edx
	mov esi,100
	div esi
	pop edx
	mov si,0xFFF0
	cmp eax,esi
	jbe short .nooverflow
	xchg eax,esi

.nooverflow:
	// round to a multiple of 10 mph
	shr eax,4
	adc eax,byte 0
	shl eax,4
	mov [edi+(ebx-1)*4+2],ax

	// for the high-speed girder bridges, it's a fixed 0.9 of the value for tubular bridges
	imul eax,(9*65536)/10
	shr eax,20
	adc eax,byte 0
	shl eax,4
	mov [edi+(ebx-1)*4],ax
	ret
; endp calcnewbridgespeedlimits

// called when vehicle moves on bridge (just before limiting speed)
//
// in:	bx=XY
//	esi=L2 value
//	edi->vehicle
// out:	esi=bridge type
// safe:dx,?
exported vehonbridge
	and esi,0xf0
	shr esi,4

	extern genericids
	cmp dword [genericids+6*4],0
	jg .havecallback
	ret

.havecallback:
	extern grfvarfeature_set_add,grfvarfeature_set_and,grffeature
	extern getnewsprite,miscgrfvar,callback_extrainfo,curcallback
	xchg esi,edi
	push eax
	mov al,[esi+veh.class]
	sub al,0x10
	mov [grfvarfeature_set_add],al
	inc dword [grfvarfeature_set_and]
	mov byte [miscgrfvar],2
	mov [callback_extrainfo],edi

	mov eax,0x106	// generic callback for feature 6 (bridges)
	mov [grffeature],al
	mov byte [curcallback],0x33
	call getnewsprite
	jc .nosound

	extern generatesoundeffect
	call [generatesoundeffect]

.nosound:
	mov byte [grfvarfeature_set_add],0
	dec dword [grfvarfeature_set_and]
	and dword [miscgrfvar],0
	mov byte [curcallback],0

	pop eax
	xchg esi,edi
	ret

