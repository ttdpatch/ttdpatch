// New mountain and curve handling

#include <std.inc>
#include <veh.inc>
#include <proc.inc>
#include <newvehdata.inc>

extern isengine,newvehdata


uvard mountaintypes	// same as mountaintype but broken down by vehicle type
uvard curvetypes

// this is to calculate the new speed when going up or downhill
global mountain
mountain:
	push eax

	movzx eax,byte [esi+veh.class]
	lea eax,[eax*3]
	add al,[esi+veh.tracktype]
	mov al,[mountaintypes+eax-0x30]
	cmp al,3
	je .realistic

	// dl has z pos of the previous square
	cmp dl,byte [esi+veh.zpos]
	je short .mountainexit
	ja short .mountainaccel

	cmp al,1
	jb .normal		// 0 = normal
	// je .fast		// 1 = faster (default case)
	ja .fullspeed		// 2 = full speed


.fast:		// faster speed: decelerate 6%
	mov dx,word [esi+veh.speed]
	shr dx,4
	sub word [esi+veh.speed],dx
	pop eax
	ret

.normal:	// normal speed: decelerate 25%
	mov dx,word [esi+veh.speed]
	shr dx,2
	sub word [esi+veh.speed],dx

.fullspeed:	// full speed
	pop eax
	ret


.mountainaccel:		// Accelerate downwards: 2 mph per time unit
	mov dx,word [esi+veh.speed]
	add dx,byte 2
	cmp dx,word [esi+veh.maxspeed]
	ja short .mountainexit
	mov word [esi+veh.speed],dx
.mountainexit:
	pop eax
	ret

// called when the engine of a consist moves in z direction
// with realistic acceleration
//
// in:	esi=vehicle
//	dl=zpos of previous square
// out:	zero flag according to replaced instructions
// safe:ax cx ebp
//
// this sets [esi+acceleration] to record the vertical motion
// the two upper bits (6&7) define the vertical motion:
//	+1 = uphill	(01xxxxxx)
//	 0 = flat	(00xxxxxx)
//	-1 = downhill	(11xxxxxx)
// the six lower bits are those of the sum of the x and y coordinates
// for motion detection
//
// for road vehicles, the sense of bits 6&7 is reversed
//
// This is achieved through keeping track of the last position of the vehicle
// and its vertical motion in [esi+veh.acceleration] which is encoded as
// follows:
//
// Bits
// 6,7	last vertical motion, either -1<<6 (0xC0) for downhill, 0 for flat
//	or +1<<6 (0x40) for uphill
// 4,5	amount of motion since vertical motion was recorded last
//	vertical motion is reset to 0 if no further vertical motion occurs
//	within two advances of the vehicle
// 2,3	least significant bits of last x position + bits 2,3 of last y position
// 0,1	least significant bits of last y position
//
// The vehicle movement can be detected by any change in bits 0 to 3.
//

.realistic:
	mov ah,[esi+veh.xpos]
	shl ah,2
	add ah,[esi+veh.ypos]
	and ah,0x0f

	cmp dl,[esi+veh.zpos]
	je .nochange

	// either up or downhill
	sbb al,al	// uphill=0, downhill=-1
	and al,1<<7	// uphill=0, downhill=-128
	add al,1<<6	// uphill=64, downhill=-64

	// now al = 1<<6 (0x40) for uphill, -1<<6 (0xC0) for downhill
	or al,ah
	jmp short .done

.nochange:
	// No change in z position. If there was a change in x or y,
	// that means the vehicle is not on a hill
	mov al,[esi+veh.acceleration]
	and al,(1<<4)-1
	cmp al,ah
	jz .nomotion	// no motion in x or y -> keep z direction

	mov al,[esi+veh.acceleration]
	and al,0xf0	// mask out amount of motion bits 4,5 and z dir bits 6,7
	or al,ah	// set bits 0 to 3
	add al,0x10
	test al,0x20
	jz .done	// not a lot of motion (z only changes every two x, y changes)

	// either x or y changed, so set z direction to zero (no hill)
	mov al,ah

.done:
	mov [esi+veh.acceleration],al

.nomotion:
	pop eax
	ret


// this determines the maximum speed in a curve for trains
global curve
curve:
	push eax
	movzx eax,byte [esi+veh.tracktype]
	cmp byte [curvetypes+eax],3
	je .realistic

	movzx eax,byte [esi+veh.vehtype]
	test byte [trainmiscflags+eax],1
	jz .nottilting

	// see if all wagons are tilting
	push ebx
	mov ebx,esi
.checknexttilt:
	movzx ebx,word [ebx+veh.nextunitidx]
	cmp bx,byte -1
	je .istilting
	shl ebx,7
	add ebx,[veharrayptr]
	movzx eax,byte [esi+veh.vehtype]
	test byte [trainmiscflags+eax],1
	jz .nottiltingpop
	jmp .checknexttilt

.istilting:
	pop ebx
	movzx eax,byte [esi+veh.tracktype]
	mov al,[curvetypes+eax]
	inc al
	cmp al,3
	adc al,-1	// change 3 -> 2, so that 0->1, 1->2, 2->2
	jmp short .gotcurvesetting

.nottiltingpop:
	pop ebx

.nottilting:
	movzx eax,byte [esi+veh.tracktype]
	mov al,[curvetypes+eax]
	cmp al,3
	je .realistic

.gotcurvesetting:
	and dh,7
	cmp dh,1
	je short .iswide
	cmp dh,7
	je short .iswide

.istight:		// a tight curve = 90 degree angle, always 1/2 speed
	shr word [esi+veh.speed],1

.realistic:
	pop eax
	ret

.iswide:		// a wide curve = 45 degree angle, use speed setting
	cmp al,1
	jb .normal		// 0 = normal
	ja .fullspeed		// 2 = full speed
				// 1 = faster

.faster:		// 7/8 speed
	mov ax,word [esi+veh.speed]
	shr ax,3	// subtract 1/8
	sub word [esi+veh.speed],ax
	pop eax
	ret

.normal:		// 3/4 speed
	mov ax,word [esi+veh.speed]
	shr ax,2	// subtract 1/4
	sub word [esi+veh.speed],ax

.fullspeed:		// full speed
	pop eax
	ret

; endp curve

// same as above but for road vehicles
// in:	esi=vehicle
// out:	(set speed)
// safe:ebp
global rvcurve
rvcurve:
	push eax
	cmp byte [curvetypes+3],2

	je .fullspeed		// 2 = full speed
	ja .realistic		// 3 = realistic
	jp .fast		// 1 = faster
				// 0 = normal

.normal:		// 3/4 speed
	mov ax,word [esi+veh.speed]
	shr ax,2	// subtract 1/4
	sub word [esi+veh.speed],ax

.fullspeed:		// full speed
	pop eax
	ret

.fast:			// 7/8 speed
	mov ax,word [esi+veh.speed]
	shr ax,3	// subtract 1/8
	sub word [esi+veh.speed],ax
	pop eax
	ret

.realistic:
	// limit to 3/4 of top speed
	movzx eax,word [esi+veh.maxspeed]
	lea eax,[eax+eax*2]
	shr eax,2

	// if the vehicle is entering a station, limit to 20 mph
	cmp byte [esi+veh.movementstat],0x20
	jb .limit
	cmp byte [esi+veh.movementstat],0x30
	jae .limit
	mov ax,64

.limit:
	cmp [esi+veh.speed],ax
	jbe .done
	mov [esi+veh.speed],ax

.done:
	pop eax
	ret


// called when a road vehicle is accelerating
// in:	ax=current speed
//	esi=vehicle
// out:	eax=new speed (will be limited to maxspeed upon return)
// safe:ebx
global rvaccelerate
rvaccelerate:
	push edx

	cwde	// clear high word of ax

	// calculate acceleration
	push eax
	shr eax,1		// convert to mph*1.6 from mph*3.2
	call calc_te_a
	lea ebx,[eax*2]		// convert to more useful numbers
//	xchg eax,ebx

#if 0
	// acceleration = force / mass = (power/speed) / mass = power / (speed * mass)
	// (assuming perfect gear ratios at each speed, which is
	//  something of an oversimplification but close enough)
	// below 20 mph, acceleration is constant and maximal

	shl eax,16		// for more accuracy

	mov edx,[esp]		// [esp] = current speed
	test edx,edx
	jz .tooslow

	imul ebx,edx
	xor edx,edx

.tooslow:
	idiv ebx

	// now eax=acceleration
	mov ebx,eax
	shr ebx,1

	// add a little friction
	// kinetic friction (constant 2), rolling friction (speed/64)
	// and air resistance (speed^2/16000)
	mov eax,[esp]
	mov edx,eax
	imul edx,eax

	shr eax,6
	shr edx,14

	// could put variable coefficients of friction here to
	// support *really* fast trucks

	lea eax,[eax+edx+2]
	sub ebx,eax

	mov eax,345	// maximum tractive acceleration = 0.9 g or so
	cmp ebx,eax
	jbe short .notslipping

	mov ebx,eax

.notslipping:

	// adjust for gravity up/downhill if necessary
	movsx edx,byte [esi+veh.acceleration]
	and edx,0-(1<<6)

	// 96 is an arbitrary value for the tangential component of
	// the acceleration of gravity

	add ebx,edx
	sar edx,1
	add ebx,edx
#endif

	pop eax


	cmp byte [esi+0x66],0
	je .nottwice

	add ebx,ebx	// double acceleration sometimes?  That's what TTD does.

.nottwice:
	mov dl,bl
	sar ebx,8

	add [esi+veh.speedfract],dl
	adc eax,ebx

	cmp [esi+veh.speed],ax
	jl .nottoosmall

	cmp eax,2
	jge .nottoosmall

	mov eax,2	// don't let speed drop below 1.25 mph

.nottoosmall:
	pop edx
	ret

; endp rvaccelerate

	uvard lasttractiveeffort
	uvard lastaccel
	uvarb lastheavyduty

// calculate tractive effort and acceleration
// in:	esi=vehicle
//	eax=speed to calculate these for
// out:	eax=acceleration [m/s^2/256]
//	ebx=power
//
// also sets lasttractiveeffort, lastaccel and lastheavyduty
//
// !!! Shouldn't change vehicle data directly because it's called from a window handler by showspeed !!!
//
global calc_te_a
proc calc_te_a
	local totweight,inclforces,maxte,notallpower,power,speed

	_enter

	push ecx
	push edx

	xor ebx,ebx
	mov [%$maxte],ebx
	mov [%$totweight],ebx
	mov [%$inclforces],ebx
	mov [%$power],ebx
	mov [%$notallpower],ebx

	test eax,eax
	jnz .havespeed
	inc eax
.havespeed:
	mov [%$speed],eax

	mov edx,[esi+veh.veh2ptr]

	movzx eax,word [esi+veh.idx]
	test byte [edx+veh2.flags],1<<VEH2_MIXEDPOWERTRAIN
	jz .notmixed

	or dword [%$notallpower],1<<MOD_NOTELECTRICHERE

.notmixed:
	mov cl,[esi+veh.zpos]

	push esi

		// count weight and incline forces of all engines+waggons
.next:
	mov ch,[%$notallpower]
	mov edx, [esi+veh.veh2ptr] // should be here because of the jump and use of it afterwards
	test [esi+veh.modflags],ch
	jnz .nopowerontile

	movzx eax,word [edx+veh2.te]
	add [%$maxte],eax	// tractive effort provided in kN

	movzx eax,word [edx+veh2.power]
	add [%$power],eax

.nopowerontile:
	movzx ebx,word [edx+veh2.fullweight]
	add [%$totweight],ebx

	mov ch,[esi+veh.zpos]
	cmp cl,ch
	je .noslope
	ja .uphill

	neg ebx

.uphill:
	shl ebx,6
	sub  [%$inclforces],ebx

	mov cl,ch
	
.noslope:
	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .haveall
	shl esi,vehicleshift
	add esi,[veharrayptr]
	
// We need to make note of artic units (code basically the same as multihead for the same behaviour)
	cmp byte [esi+veh.artictype], 0xfd // articulated (can be all but first vehicle)
	jb .next
	je .reversed
	jmp .noslope

.reversed:
	movzx edx,word [esi+veh.nextunitidx]
	cmp dx, byte -1
	je .next // was the last articulated piece = the real engine
	shl edx, 7
	add edx, [veharrayptr]
	cmp byte [edx+veh.artictype], 0xfd
	jb .next
	mov esi, edx
	jmp .reversed

.haveall:
	pop esi

	// add incline force for the engine
	mov edx,[esi+veh.veh2ptr]
	movsx eax,byte [esi+veh.acceleration]
	movzx ebx,word [edx+veh2.fullweight]

	and eax,byte -64
	imul eax,ebx

	add [%$inclforces],eax

	mov eax,[%$power]

		// do conversion from hp/(mph/1.6) to N
		// hp/(mph/1.6) = 2.669 kN

	mov ebx,683		// 2.669*256
	mul ebx

	mov ebx,[%$speed]
	div ebx

	// now eax=force of engine [kN/256]

	mov edx,[%$maxte]
	shl edx,8
	mov [%$maxte],edx	// for later

	cmp eax,edx
	jbe .belowmax

	mov eax,edx

.belowmax:
	// now eax=tractive effort [kN/256]

	mov [lasttractiveeffort],eax

	movzx ecx,byte [esi+veh.vehtype]
	movzx ecx,byte [trainc2coeff+ecx]
	dec ecx
#if 0
	shr cl,1
	adc ch,0
	add cl,ch
	add cl,ch
#endif

	cmp byte [esi+veh.movementstat],0x40
	jne .nottunnel

//	dec cl		// cl was at least 1
	add ecx,ecx

.nottunnel:

#if 0
	// now ch, cl give the following divisors (using bit shifts):
	// top speed: <32  32  48  64   96 128  192  256  384  512   768 1024 ...
	// c2coeff:	1   2   3   4    5   6    7    8    9   10    11   12
	// c2:        3/4 1/2 3/8 1/4 3/16 1/8 3/32 1/16 3/64 1/32 3/128 1/64
	// (half as much in tunnels = twice the air resistance)
#endif

	mov edx,ebx

	imul edx,edx

#if 0
	test ch,ch
	jz .notadded
	lea edx,[edx+edx*2]

.notadded:
	shr edx,cl		// edx: air resistance = c2*v^2
#else
	xchg eax,ecx
	imul edx
	shrd eax,edx,8
	mov edx,eax		// edx: air resistance = c2*v^2
	mov eax,ecx
#endif

	add ebx,50
	shr ebx,4		// ebx: c0+c1*v = friction/m (=frictional accel.)

	sub eax,edx

	mov edx,[%$inclforces]	// edx = mass*9.8*sin(theta)/2 [kN/256] (theta=5%)
	add edx,edx
	add eax,edx		// eax = TE + inclforce

	imul edx,byte -6	// edx = -inclforce*6
	lea edx,[edx+eax*4]	// edx = (TE - inclforce/2)*4

// show smoke if TE + inclforce/2 > maxTE/4
	cmp edx,[%$maxte]
	setg byte [lastheavyduty]

	// now eax=net force (except for static/rolling friction
	// which is in ebx as an acceleration)

	mov ecx,[%$totweight]

	cdq		// sign extend edx
	jecxz .nodiv
	idiv ecx
.nodiv:
	sub eax,ebx		// subtract friction (avoid multiplying and dividing by weight)

	// now eax=acceleration [m/s^2/256]

	mov [lastaccel],eax
	mov ebx,[%$power]

	pop edx
	pop ecx
	_ret

endproc train_te_a


	// called to calculate the new speed after acceleration
	//
	// in:	esi=vehicle
	// out:	(set esi.speed and esi.subspeed), ax=speed
	// safe:eax,ebx
global calcspeed
calcspeed:
	push ecx
	push edx

	movzx ecx,byte [esi+veh.tracktype]
	cmp byte [mountaintypes+ecx],3
	jne near .notrealisticaccel

	push ecx
	mov ecx,[esi+veh.veh2ptr]

	push esi

	// VEH2_MUSTCHECKTILE is set if this is a mixed power train that just
	// entered a new tile (note this is only set, and only works for tiles
	// that store the track type in the lower byte, i.e. not crossings etc.)
	test byte [ecx+veh2.flags],1<<VEH2_MIXEDPOWERTRAIN
	jz .knowpower

	btr dword [ecx+veh2.flags],VEH2_MUSTCHECKTILE
	jnc .knowpower

	movzx eax,word [esi+veh.XY]
	mov al,[landscape3+eax*2]
	and al,0xF

	// check to see if landscape3 track type is right for this vehicle
.checknextveh:
	movzx edx,word [esi+veh.vehtype]
	bt [isengine],edx
	mov dl,[esi+veh.tracktype]
	jc .isengine

	// for wagons, power type is same as the engine
	movzx edx,word [esi+veh.engineidx]
	shl edx,7
	add edx,[veharrayptr]
	mov dl,[edx+veh.tracktype]

.isengine:
	// now dl=tracktype of vehicle, or of engine for wagons
	// and al=landscape3 tracktype
	cmp dl,al
	seta dl
	shl dl,MOD_NOTELECTRICHERE
	and byte [esi+veh.modflags],~(1<<MOD_NOTELECTRICHERE)
	or [esi+veh.modflags],dl

	movzx esi,word [esi+veh.nextunitidx]
	cmp si,byte -1
	je .knowpower
	shl esi,7
	add esi,[veharrayptr]
	jmp .checknextveh

.knowpower:
	pop esi

	movzx eax,word [esi+veh.speed]
	call calc_te_a
	add eax,eax		// convert to more useful numbers

	mov [ecx+veh2.realpower],ebx

#if 0
	// this doesn't work yet; need to reset bit 4 when stopped
	bt dword [esi+veh.vehstatus],4		// but not if stopping
	cmc
	sbb ebx,ebx
	and eax,ebx
#endif

	movzx ebx,word [esi+veh.speed]

	pop ecx

	// calculate new speed

	mov dl,al
	sar eax,8

	add [esi+veh.speedfract],dl
	adc eax,ebx

	cmp ebx,eax
	jl .nottoosmall

	cmp eax,2
	jge .nottoosmall

	mov eax,2	// don't let speed drop below 1.25 mph

.nottoosmall:
	cmp byte [lastheavyduty],0
	je .limittomaxspeed
	// vehicle is under heavy duty
	or byte [esi+veh.modflags],1 << MOD_SHOWSMOKE
	jmp short .limittomaxspeed

.notrealisticaccel:
	mov eax,[esi+veh.veh2ptr]
	movzx eax,word [eax+veh2.fullaccel]
	shl eax,2
	jnz short .havefullaccel
	movzx eax,byte [esi+veh.acceleration]
	shl eax,2
.havefullaccel:
	mov bl,al
	shr eax,8
	add byte [esi+veh.speedfract],bl
	movzx ebx,word [esi+veh.speed]
	adc eax,ebx

.limittomaxspeed:
	cmp byte [curvetypes+ecx],3	// ecx is still tracktype
	movzx ebx,word [esi+veh.maxspeed]
	jne .gotspeed

	push esi

	xor ecx,ecx
	mov cl,1

.next:
	movzx edx,byte [esi+veh.vehtype]
	and cl,[trainmiscflags+edx]

	mov ch,[esi+veh.direction]

	movzx esi,word [esi+veh.nextunitidx]
	cmp si,-1
	je .done
	shl esi,vehicleshift
	add esi,[veharrayptr]

	sub ch,[esi+veh.direction]
	je .next

	add ecx,0x10000

	and ch,7
	cmp ch,1
	je .next	// wide curve
	cmp ch,7
	je .next

	add ecx,0x20000	// narrow curve -> counts as 3
	jmp .next

.done:
	pop esi

	test cl,1
	jz .gotcurves
	sub ecx,0x20000	// tilting trains get two free curves
	jnb .gotcurves
	xor ecx,ecx
.gotcurves:
	shr ecx,16
	// now ecx=total number of turns the entire train is making

	// for each turn, subtract 1/16, up to 8/16

	cmp ecx,8
	jbe .ok

	mov ecx,8

.ok:
	imul ecx,ebx
	shr ecx,4
	sub ebx,ecx

.gotspeed:
	cmp eax,ebx
	jbe short .nottoofast
	mov eax,ebx

.nottoofast:
	mov [esi+veh.speed],ax
	pop edx
	pop ecx
	ret
; endp calcspeed
