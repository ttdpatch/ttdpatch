// Created By Lakie September 2006

/*
	-= Basic Idea =-

	Convert based of the value given in dl.
	* From Engine to Extra Head if dl is 0
	* From Extra Head to Engine if dl is 1

	Converting from Engine to Multi Head
	* Remove vehicle's order schedule
	* Reset the know vraiables to their wagon values (normally 0)
	* Change the vehicle subclass
	* Return to subroutine to move the vehicle as a wagon

	Converting from Multi Head to Engine
	* Unknown
*/

#include <human.inc>
#include <misc.inc>
#include <std.inc>
#include <textdef.inc>
#include <veh.inc>

extern delvehschedule, actionhandler, ConvertEngineType_actionnum, ctrlkeystate
extern FindWindow, DestroyWindow, CloneTrainLastIdx, lookforsamewagontype

/*
	-= Hook for the conversion =-
*/

// Output, CF = 0 for attach, CF = 1 for engine (bad)
global ConvertEngineHook
ConvertEngineHook:
//	int3 // Was used for debugging the whole process
	cmp byte [edi+veh.subclass], 0 // Is it an engine being moved?
	je .engine
	clc
	ret

.engine:
	push byte CTRL_ANY + CTRL_MP // Was control held when moving the engine
	call ctrlkeystate
	jz .engineconvert
.notgood:
	stc
	ret

.engineconvert:
	// Reset the control key status incase anything later breaks like moving the new extra head
#if WINTTDX
	mov byte [keypresstable+KEY_Ctrl], 1
#else
	mov byte [keypresstable+KEY_RCtrl], 1
	mov byte [keypresstable+KEY_LCtrl], 1
#endif

	cmp edi, edx // If it's the same train, we cannot convert
	je .notgood

	pusha
	mov word [CloneTrainLastIdx], dx // Store the train to attach to for later
	mov dx, [edi+veh.idx] // Find and close the train window if it's open
	mov cl, 13
	call [FindWindow]
	cmp esi, 0
	je .notfound
	call [DestroyWindow]

.notfound:
	sub edi, [veharrayptr] // make the pointer an index for the vehicle array
	shr edi, 7
	mov bl, 1 // Set the veraibles and do the actual converting of the vehicle
	mov dh, 0
	dopatchaction ConvertEngineType
	popa
	clc
	ret

/*
	-= Main Conversion function =-
*/

// Input would be the edi (engine) as a index
exported ConvertEngineType
	mov byte [currentexpensetype], expenses_trainruncosts // All costs should be of this type

	shl edi, 7 // Only an index was given, move to the actual array entry
	add edi, [veharrayptr]

	test bl, 1 // Are we actually doing the convert?
	jz near .onlycalculations

	test dh, 1 // Yes, so is it an engine or and extra head being convertted?
	jnz near .revertvehicle

	push edi // It's an engine being converted
	movzx edi, word [edi+veh.nextunitidx] // Does our engine having anything attached?
	cmp di, byte -1
	je .nothingattached

.nextattached:
	shl edi, 7 // Yes so lets deattach it
	add edi, [veharrayptr]

	movzx eax, word [edi+veh.nextunitidx] // This is so that edi can be used for deattaching
	push eax

	mov ax, [edi+veh.xpos] // Set the actionhandler values which will be needed
	mov cx, [edi+veh.ypos]
	movzx edi, word [edi+veh.idx]

	mov dx, -1 // Deattach the rail vehicle
	mov bl, 1
	mov esi, 0x90080
	call [actionhandler]

	pop edi // Get our next idx out, and check if there is anything there
	cmp di, byte -1 
	jne .nextattached

.nothingattached:
	pop edi
	mov edx, edi // Remove the vehicles schedule ready for removing / converting
	mov ax, [edi+veh.XY]
	push edi
	call [delvehschedule]
	pop edi

	mov dword [edi+veh.scheduleptr], -1 // Although the schedule was destroyed
	mov word [edi+veh.currorder], 0 // These variables need to be altered manually
	mov byte [edi+veh.totalorders], 0
	mov byte [edi+veh.currorderidx], 0
	mov word [edi+veh.target], 0
	mov word [edi+veh.lastmaintenance], 0 // The next lot of values are always 0 for wagons
	mov word [edi+veh.serviceinterval], 0 // including extra heads
	mov byte [edi+veh.acceleration], 0
	mov word [edi+veh.age], 0
	mov word [edi+veh.maxage], 0
	mov byte [edi+veh.consistnum], 0
	mov word [edi+veh.reliability], 0
	mov word [edi+veh.reliabilityspeed], 0
	mov word [edi+veh.name], 6 // Wagons always have this value, unknown why
	btr word [edi+veh.vehstatus], 1 // Wagons cannot be stopped
	mov dl, 4 // By default it is lightly to be on it's own line

	push edi // Push now or it will crash, also clear ecx for later
	xor ecx, ecx
	cmp word [CloneTrainLastIdx], 0 // Any train to attach to?
	jne .endattach

	mov bp, [edi+veh.XY] // No, so lets setup the values used in the loop
	mov ecx, [veharrayptr]
	movzx ebx, word [edi+veh.vehtype] // Used for checing if the same type of vehicle
	xchg bh, bl

.findloopcheck:
	cmp byte [ecx+veh.class], 0x10 // Is the vehicle the same class and in the depot
	jne .findmovenext
	cmp word [ecx+veh.XY], bp
	jne .findmovenext
	cmp byte [ecx+veh.subclass], 4 // Is it a wagon row head engine
	jne .findmovenext
	mov edi, ecx
	call lookforsamewagontype // Is it of the same vehicle type
	jne .findmovenext

.foundchainnext:
	cmp word [ecx+veh.nextunitidx], byte -1 // Is if the end of this vehicle consist
	je .endattach
	movzx ecx, word [ecx+veh.nextunitidx] // no so lets move to the next unit and try again
	shl ecx, 7
	add ecx, [veharrayptr]
	jmp .foundchainnext

.findmovenext:
	add ecx, 0x80 // move to the next vehicle array entry to check
	cmp ecx, [veharrayendptr]
	jb .findloopcheck
	xor ecx, ecx // no vehicle entry found so blank ecx

.endattach:
	pop edi
	or ecx, ecx // Did we find a consist
	jz .realdone

	mov dl, 2 // Found consist so it's an extra wagon subclass 2
	mov ax, word [edi+veh.idx] // Attach the wagon to the end of the consist
	mov word [ecx+veh.nextunitidx], ax
	mov ax, word [ecx+veh.engineidx] // Correct the consist variables
	mov word [edi+veh.engineidx], ax

.realdone:
	mov byte [edi+veh.subclass], dl // Store the vehicle class so that it looks right in the depot
	mov word [CloneTrainLastIdx], 0 // Reset this so that CloneTrain won't fail
	ret

.revertvehicle: // No code for this yet, might be in future versions
	ret

.onlycalculations: // Costs nothing to the player (since it's just recoupling in real life anyway)
	mov ebx, 0
	ret

