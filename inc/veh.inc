
// *THE* Vehicle structure
struc veh
	.class: 	resb 1	// 00h:10h=train, 11h=road, 12h=ship, 13h=aircraft, 14h=special effects, 15h=disaster-related
	.subclass: 	resb 1	// 01h:for trains: 00h=engine, 02h=waggon/secd.engine, 04h=first waggon in a train w/o engine
				//     for road vehicles and ships always 0 (?)
				//     for aircraft: 00h=helicopter, 02h=plane, 04h=shadow (and mail compartment), 06h=rotor
			resw 1	// 02h:index of next vehicle in some list (used to detect collisions?)
	.idx:	 	resw 1	// 04h:vehicle number
	.scheduleptr: 	resd 1	// 06h:pointer to command list
	.currorder: 	resw 1	// 0ah:next station or depot & special commands (see below)
	.totalorders: 	resb 1	// 0ch:total number of commands
	.currorderidx:		// 0dh:	current command index (for engine of consist)
	.artictype:	resb 1	//	articulated piece type (for following vehicles)
				//	FD=articulated piece (not for head), forward
				//	FE=articulated piece, reversed
				//	FF=articulated head, reversed
				//	i.e. you have 00 FF FF or FD FE FE for a three-piece artic
	.target: 		// 0eh:	current target coordinates (not used for aircraft?)
	.articheadidx:	resw 1	//	for articulated piece (FD..FF): veh index of head
	.loadtime: 	resw 1	// 10h:time to load/unload remaining
	.lastmaintenance:resw 1	// 12h:date of last maintenance
	.serviceinterval:resw 1	// 14h:service interval
	.laststation: 	resb 1	// 16h:last station visited
	.cycle:		resb 1	// 17h:cycle; increased every engine tick
	.maxspeed: 	resw 1	// 18h:maximum speed of the vehicle, in mph/1.6 (trains), mph/3.2 (rv/ships) or mph*8 (aircraft)
	.xpos: 		resw 1	// 1ah:X Position
	.ypos: 		resw 1	// 1ch:Y Position
	.zpos: 		resb 1	// 1eh:Z Position
	.direction: 	resb 1	// 1fh:Direction; 0=up, 1=up/right, 2=right etc.
	.delx: 		resb 1	// 20h:X offset of sprite box
	.dely: 		resb 1	// 21h:Y offset of sprite box
	.xsize:		resb 1	// 22h:X-size of vehicle (for object display sorting)
	.ysize:		resb 1	// 23h:Y-size of vehicle
	.zsize:		resb 1	// 24h:Z-size of vehicle
	.owner: 	resb 1	// 25h:vehicle owner
	.XY: 		resw 1	// 26h:index into landscape array
	.cursprite: 	resw 1	// 28h:current sprite ID (incl. direction and veh. type)
	.box_coord:	resw 4	// 2ah,2ch,2eh,30h:x1,y1,x2,y2 coordinates of sprite box on screen
	.vehstatus: 	resw 1	// 32h:bit 0=vehicle invisible (in tunnel/depot), bit 1=stopped, bit 7=crashed, ??
	.speed: 	resw 1	// 34h:current speed in mph/1.6 (trains), mph/3.2 (rv/ships), see also trnspd.asm
	.speedfract: 	resb 1	// 36h:current speed, fractional part
	.acceleration: 	resb 1	// 37h:acceleration
	.movementfract:	resb 1	// 38h:fraction of movement (when it overflows, vehicle moves one unit)
	.cargotype: 	resb 1	// 39h:cargo type// 0=pass,1=coal,2=mail etc.
	.capacity: 	resw 1	// 3ah:cargo capacity
	.currentload: 	resw 1	// 3ch:current cargo load
	.cargosource: 	resb 1	// 3eh:source station of cargo
	.cargotransittime:resb 1// 3fh:number of days in transit from source
	.age: 		resw 1	// 40h:age in days
	.maxage: 	resw 1	// 42h:max age in days
	.yearbuilt: 	resb 1	// 44h:year built, -1920
	.consistnum: 	resb 1	// 45h:train/rv/plane/ship number
	.vehtype: 	resw 1	// 46h:engine type, or waggontype or plane type etc.
	.spritetype: 	resb 1	// 48h:vehicle sprite number (Trains: FD, forward; FF, reversed)
	.daycounter: 	resb 1	// 49h:day counter; mod 8=0 then dec. value 0.4%
	.breakdowns: 	resb 1	// 4ah:breakdowns since last service
	.breakdowncountdown:	resb 1	// 4bh:1=broken down, >1=countdown to breakdown
	.breakdowntime:		resb 1	// 4ch: time until the end of the breakdown
	.breakdownthreshold:
			resb 1	// 4dh:breakdown threshold (if sometable[reliability>>somenum]<this, train breaks down)

	.reliability: 	resw 1	// 4eh:reliability (65535=100%)
	.reliabilityspeed:
			resw 1	// 50h:how fast it decreases
	.profit: 	resd 1	// 52h:profit this year
	.previousprofit:resd 1	// 56h:profit last year
	.nextunitidx: 	resw 1	// 5ah:index to next waggon or aircraft part
	.value: 	resd 1	// 5ch:value in pounds
	.name: 		resw 1	// 60h:type of title; text index
	.movementstat:	resb 1	// 62h:00h..07h=sub image? 40h=in tunnel
				//     actually some kind of status
				//     aircraft: >=13 when in flight
				//     train, ship: 80h=in depot
	.RVCurTilePos:		//     rv: 0feh=in depot
	.ignoresignals:		// 63h:train: ticks remaining for "ignore signal" order
	.targetairport: resb 1	//     aircraft: arget airport
			resw 1	// 64h:?? travelpos on runway??
				//     rv:if blocked by another one: counts for how long, overrides when >5c8h (?)
	.tracktype:		// 66h:train:0=normal, 1=monorail, 2=maglev
	.aircraftop: 	resb 1	//     aircraft:0=in depot, 1..3=at terminal 1..3, 4..6=going from hangar to terminal,
				//              7..9=landing and going to terminal, 0ah..0ch=going from terminal to hangar,
				//		0dh..0fh=taking off from terminal, 10h=taking off from hangar,
				//		11h=landing and going to hangar, 12h=in flight
				//     rv:10h=overtaking
			resb 1	// 67h:rv:overtaking counter (0..23h); ??
			resw 1	// 68h:rv:??
			resb 1	// 6ah:rv:turn-around counter
				// So far it's the last entry identified as used by TTD.
			resb 0x6D-$
	.parentmvstat2:	resb 1	// 6Dh:stores the extra parent stat information (mainly needed for uturns)
	.slfifoidx:	resb 1	// 6Eh:the index of this vehicle in the fifo queue (save/load only)
	.prevmovementstat:	// 6Fh:the previous movementstat (used for RV trailers and Plane accel/decel)
	.parentmvstat	resb 1	//     the next turn for Articulated RVs (so that they follow the leader)
	.traveltime:	resw 1	// 70h:number of days travelling since last load/unload
	.refitcycle:	resb 1	// 72h:how often refitted to same cargo
	.shortened:		// 73h:how much shorter is the wagon (+0x80)
	.aircraftnode:	resb 1	//     current node when on newairports
	.speedlimit:	resw 1	// 74h:current top speed (b/o bridge, curve etc.), 0 if unlimited
	.veh2ptr:	resd 1	// 76h:pointer to veh2 entry of this vehicle
	.random:	resb 1	// 7ah:random bits, changed according to sprite data
	.newrandom:	resb 1	// 7bh:what random triggers occured so far
	.engineidx:	resw 1	// 7ch:engine index of this consist; same as .idx if none

#define MOD_DIDUNLOAD 0		//	bit 0=did unload at this station
#define MOD_MORETOUNLOAD 1	//	bit 1=unloading not done yet
#define MOD_NOTDONEYET 2	//	bit 2=not yet done (loading or unloading)
#define MOD_DIDCASHIN 3		//	bit 3=did cash in
#define MOD_SHOWSMOKE 4		//	bit 4=acceleration large enough for diesel smoke
#define MOD_POWERED 5		//	bit 5=vehicle is powered
#define MOD_NOTELECTRICHERE 6	// 	bit 6=mixed power train is on non-electric tile
#define MOD_ISFULL 7		//	bit 7=train is done loading even with full load set
#define MOD_REVERSE 8		//	bit 8=toggled whenever train reverses
#define MOD_HASRESERVED 9	//	bit 9=this vehicle has reserved its cargo type and is loading (FIFO)
#define MOD_PROTOTYPE 10	//	bit 10=the vehicle was built during the testing phase

	.modflags: 	resw 1	// 7eh:above flags, bitcoded.
endstruc

// Hint:  When adding or subtracting vehiclesize to a variable,
//	  do the opposite operation with -vehiclesize, e.g. instead of
//	  add esi,vehiclesize
//	  do this:
//	  sub esi,byte -vehiclesize
//	  The reason is that -80h can be encoded in a single imm8, so nasm
//	  uses the equivalent sign-extend operation, whereas +80h needs
//	  four bytes.

%assign vehicleshift 7
%assign vehiclesize 1 << vehicleshift
%ifndef PREPROCESSONLY
	%if veh_size <> vehiclesize
		%error "Vehicle struc has wrong size!"
	%endif
%endif

// .currorder:
// high byte = station/depot number
//
// special commands ORed in low byte:
// 00h=no orders
// 01h=is a station
// 02h=is a depot
// 03h=loading/unloading
// 04h=??
// 05h=TTDP special
//
// bits for stations: 20h=unload, 40h=full load, 80h=non-stop
// bits for depots: 40h=manually sent, a0h="go to depot" order,
//	e0h="go to depot after service int. expired" order

//for TTDP special, high byte=command num
// 00h=find & goto closest (forward) depot
// 01h=find & goto closest (forward) depot if service needed
// 02h=skip next n orders if overall load percentage ==,!=,<,>,<=,>= P%		One extra word: MSB->LSB, op: 3 bits, n: 5 bits, gap: 1 bit, P: 7 bits
//high 3 bits means number of words in schedule heap after command which are associated


// Format of data in veh2 array (for temporary, unsaved vehicle data)
%define numvehvar40x 4			// highest 40+x variable that's cacheable
%define cachevehvar40x_def 01111b	// bitmask of actually cacheable 40+x 
					// variables (any 40+x variables that do
					// not change while train is in motion)
struc veh2
	.te:		resw 1	// current tractive effort provided by vehicle (in kN/256)
	.power:		resw 1	// power of just this vehicle
	.flags:		resb 1	// flags, bitcoded, see VEH2_* below
	.lastspeed:	resb 1	// last speed shown in window status bar
	.fullweight:	resw 1	// weight of vehicle plus cargo
	.realpower:	resd 1	// total power of train
	.vehptr:	resd 1	// pointer back to veh structure
	.sortvar:	resd 1	// value for sorting train list
	.fullaccel:	resw 1	// full uncapped acceleration
	.viseffect:	resb 1	// cache of visual effect from callback 10
	.loadamount:	resb 1	// cache of load amount from callback 12
	.var40x:	resd numvehvar40x	// cache of vehicle variables 40+x for action 2
	.motion:	resd 1	// motion counter (256 increase = 1 unit of motion)
	.colormap:	resd 1	// color translation sprite
	.curraircraftact: resb 6	// raw movement data needed by AircraftMovement
	.userbits:	resb 1	// user bits (train prop 25)
	.pad:		resb 1
	.prevptr:	resd 1	// linked list of vehicles queued-for-reserving
	.nextptr:	resd 1	// pointers point to veh2 struct
		align 4,resb 1
endstruc

#define VEH2_MIXEDPOWERTRAIN 0	// set if train has mix of electric/nonelectric engines
#define VEH2_MUSTCHECKTILE 1	// if set, mixed power train just moved onto a new tile

#define AIRCRAFTACT_UNKNOWN 0x80008000	// signals that .curraircraftact isn't valid and needs
					// to be recalculated
 
// cvivp: convert vehicle index to vehicle pointer
//
// params: dest (r32), source (r/m16)
// params: source (r/m16) or dest (r32)
//	If source is an m16, dest is esi. Otherwise, the non-specified
//	argument is the specified register's 32 or 16 bit companion.
//	If dest is specified and source is not, dest's high 16 bits are assumed to be clear.
//
// Do not specify "word [address]" for m16s, simply specify "[address]"
//

%macro cvivp 0-1 esi
	%tostr %%1 %1
	%strlen %%len %%1
	%substr %%mem %%1 1
	%ifidn %%mem, '['
		movzx	esi, word %1
		shl	esi, vehicleshift
		add	esi, [veharrayptr]
	%elif %%len == 2
		%substr %%x %%1 2
		%ifidn %%x,'x'	 //[abcd]x
		%elifidn %%x,'i' //[sd]i
		%elifidn %%x,'p' //[sb]p
		%else
			%error "cvivp requires a word register or memory location, or a dword register."
		%endif
		movzx	e%1, %1
		shl	e%1, vehicleshift
		add	e%1, [veharrayptr]
	%else
		shl	%1, vehicleshift
		add	%1, [veharrayptr]
	%endif
%endmacro

%macro cvivp 2 //params: destination register, source word
	movzx %1, word %2
	cvivp %1
%endmacro

// cvivpj[n]v: cvivp and jump if [not] vehicle.
//
// Do not use cvivpjv if it is immediately followed by an unconditional jmp
// In this case, use the jnv form instead.
//
// params: dest (r32), source (r/m16), jump destination
// params: source (r/m16) or dest (r32), jump destination
//	If source is an m16, dest is esi. Otherwise, the non-specified
//	argument is the specified register's 32 or 16 bit companion.
//	If dest is specified, its high 16 bits are assumed to be clear.
//
// Do not specify "word [address]" for m16s, simply specify "[address]"
// Jumps will be short unless specified as "near target"
//
// In all cases, dest is undefined in the nv case.
//

%macro cvivpjnv 3
	movzx	%1, word %2
	db	0x66		// cmp %1's word register
	cmp	%1, byte -1
	je	%3
	cvivp	%1
%endmacro

%macro cvivpjnv 2
	%tostr %%1 %1
	%strlen %%len %%1
	%substr %%mem %%1 1
	%ifidn %%mem, '['
		cvivpjnv esi, %1, %2
	%elif %%len == 2
		%substr %%x %%1 2
		%ifidn %%x,'x'	 //[abcd]x
		%elifidn %%x,'i' //[sd]i
		%elifidn %%x,'p' //[sb]p
		%else
			%error "cvivpj[n]v requires a word register or memory location, or a dword register."
		%endif
		cvivpjnv e%1, %1, %2
	%else
		db	0x66		// cmp %1's word register
		cmp	%1, byte -1
		je	%2
		cvivp	%1
	%endif
%endmacro

%macro cvivpjv 3
	cvivpjnv %1, %2, %%done
	jmp short %3
%%done:
%endmacro

%macro cvivpjv 2
	cvivpjnv %1, %%done
	jmp short %2
%%done:
%endmacro
