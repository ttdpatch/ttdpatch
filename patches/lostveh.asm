// Find lost vehicles

#include <std.inc>
#include <textdef.inc>
#include <veh.inc>

extern newsmessagefn,trainlosttime

// Called when preparing a new veharray entry
// Reset traveltime
global createvehicle
createvehicle:
	or word [esi+2],-1
	and word [esi+veh.traveltime],0
	ret

// Helper functions to tell if a tile is a depot of the given type
// in:	ah: landscape5 entry
//	al: landscape4 entry
// out:	zf set if depot

var vehtypetextids, dw 0x19f,0x19c,0x19e,0x19d

var isindepot
	dd addr(isintraindepot)
	dd addr(isinrvdepot)
	dd addr(isinshipdepot)
	dd addr(isinhangar)

isintraindepot:
	and ax,0xfcf0
	cmp ax,0xc010
	ret

isinrvdepot:
	and ax,0xf0f0
	cmp ax,0x2020
	ret

isinshipdepot:
	and ax,0xfcf0
	cmp ax,0x8060
	ret

isinhangar:
	and al,0xf0
	cmp ax,0x2050
	je .exit
	cmp ax,0x4150
.exit:
	ret

// called daily for every vehicle
// detect lost vehicles here
// in:	esi: vehicle
// out:	overflow flag if no "vehicle old message" should be shown
// safe: eax,ebx,edx
global agevehicle
agevehicle:
	movzx edx,byte [esi+veh.class]
	test byte [esi+veh.vehstatus],2		// always increase traveltime if moving
	jz .travelling

	movzx ebx,word [esi+veh.XY]		// if it's stopped in a depot, don't increase traveltime
	mov ah,[landscape5(bx)]
	mov al,[landscape4(bx)]
	call dword [isindepot+(edx-0x10)*4]
	jz .notlost

.travelling:
	cmp dword [esi+veh.scheduleptr],byte -1
	je .notlost				// only warn about engines
	inc word [esi+veh.traveltime]		// increase traveltime and make message if necessary

	test byte [esi+veh.vehstatus],2
	jz .notstopped

	mov al,0x7f
	add al,10	// set overflow flag
	ret

.notstopped:
	mov ax,[trainlosttime+(edx-0x10)*2]
	or ax,ax				// 0 means disabled
	jz .notlost
	cmp ax,[esi+veh.traveltime]
	ja .notlost
	mov al,[esi+veh.owner]			// only for the current player's vehicles
	cmp al,[human1]
	jne .notlost

	pusha					// generate message
	mov dx,newstext(vehiclelost)
	movzx ecx,byte [esi+veh.class]
	mov ax,[vehtypetextids+(ecx-0x10)*2]
	mov [textrefstack],ax
	movzx ax,byte [esi+veh.consistnum]

	global agevehicle.lostvehmessage
.lostvehmessage:
	mov [textrefstack+2],ax
	mov ebx,0x50a00
	mov ax,[esi+veh.idx]
	mov [newsitemparam],ax
	call dword [newsmessagefn]
	popa
	and word [esi+veh.traveltime],0		// and reset traveltime

.notlost:
	mov ax,[esi+veh.age]		// overwritten
	sub ax,[esi+veh.maxage]		// ditto

	// can't have overflow flag set here unless the age was > 32000 days
	// then it won't matter that no more messages are shown anyway :)
	ret
