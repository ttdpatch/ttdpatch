
numstations equ 250			// Number of stations in the station array

struc stationcargo
	.amount: 	resw 1	// +00h/+1Ch:amount waiting in lower 12 bits. Bits 12-15: cargo acceptance in 1/8th, up to 0fh
	.timesincevisit:resb 1	// +02h/+1Eh:days since this cargo was picked up last
	.rating: 	resb 1	// +03h/+1Fh:station rating for this type of cargo
	.enroutefrom: 	resb 1	// +04h/+20h:en-route from this station (if not zero); ff=unrated if amount=0
	.enroutetime: 	resb 1	// +05h/+21h:how many days already in transit
	.lastspeed: 	resb 1	// +06h/+22h:speed of last train picking this up (for rating)
	.lastage: 	resb 1	// +07h/+23h:age of last waggon picking this up  (for rating)
endstruc_32

// stations start at 48cba
struc station
	.XY: 		resw 1	// 00h:position of the main square (whatever that is...)  you go here with the "location" button
	.townptr: 	resd 1	// 02h:city this station belongs to (pointer to city data)
	.busXY: 	resw 1	// 06h:position of the bus station
	.lorryXY: 	resw 1	// 08h:position of the lorry loading bay
	.railXY: 	resw 1	// 0ah:position of the railway station (north corner)
	.airportXY: 	resw 1	// 0ch:position of the airport (north corner)
	.dockXY: 	resw 1	// 0eh:position of the dock
	.platforms: 	resb 1	// 10h:bits 0..2,7: number of tracks; bits 3..6: length of railway station
	.displayidx:	resb 1	// 11h:for alphabetic ordering
	.namewidth:	resb 1	// 12h:width of name in normal font
	.namewidthsmall:resb 1	// 13h:width of name in small font
	.name: 		resw 1	// 14h:text index for station name
	.nameposx:	resw 1	// 16h:absolute X pixel coord of name position
	.nameposy:	resw 1	// 18h:absolute Y pixel coord of name position
	.flags:		resw 1	// 1ah:bit 0: no facilities left, will be removed
				//     bits 1..5: train/bus/truck/aircraft/ship has visited station
				//     bit 6: station will not receive cargo (e.g. for buoys)
				//     bits 7..15: not used
	.cargos:	resb stationcargo_size * 12	// 1ch:cargo structs for 12 cargo types
				// 1ch:passengers
				// 24h:coal
				// 2ch:mail
				// 34h
				// 3ch
				// 44h
				// 4ch
				// 54h
				// 5ch
				// 64h
				// 6ch
				// 74h
	.timesinceload:	resb 1	// 7ch:time since last cargo load
	.timesinceunload:resb 1	// 7dh:time since last cargo unload
	.updatecounter:	resb 1	// 7eh:countdown to next update
	.owner: 	resb 1	// 7fh:Owner of the station
	.facilities:	resb 1	// 80h:Facilities of the station, bitcoded: 1=railway, 2=lorry, 4=bus, 8=airport, 10h=dock
	.airporttype: 	resb 1	// 81h:airport type. 0=small, 1=large, 2=heliport, 3=oil rig
	.truckstop: 	resb 1	// 82h: Bits 0,1 clear: that slot is occupied;
	.busstop: 	resb 1	// 83h:  Bit 7 set: the station is busy
	.exclusive:	resb 1	// 84h:months left in exclusive service
	.unused1:	resb 1	// 85h:unused
	.airportstat:	resw 1	// 86h:Bits 0..2: set if terminal 1..3 occupied (bit 2 is always set for small airports)
				//	bit 6 set for heliports
				//	bit 7 set: busy
				//	bit 8 set for large airports
				//	bit 9 set: out way busy (large airports only)
				//	bit 10 set: in way busy (large airports only)
				//	bit 11 set: runway busy
	.lastvehicle: 	resw 1	// 88h:number of last vehicle visiting
	.datebuilt:	resw 1	// 8ah:TTDPatch:date station was built
	.random:	resb 1	// 8ch:TTDPatch:random bits
	.newrandom:	resb 1	// 8dh:TTDPatch:what random triggers occured so far
endstruc_32

// additional cargo information, stored in secondary station array, same size as original one, for easier pointer arithmetic
struc stationcargo2
	.amount:	resd 1	// +00h/+1Ch:total amount waiting (full 32 bits), not yet implemented
	.curveh:	resw 1	// +04h/+20h:vehicle currently loading this cargo type
	.type:		resb 1
			resb 8 - $
endstruc_32

// additional station data, same size as normal struct for easier pointer arithmetics
struc station2
	.cargos:		resb stationcargo2_size*12	// 00h:
	.catchmenttop:		resw 1				// 60h: northest tile of catchment area
	.catchmentbottom:	resw 1				// 62h: southest "-"
	.acceptedcargos:	resd 1				// 64h: bitmask of accepted cargos
	.railxysouth:	resw 1				// 68h: for a rail station the south corner if 
				resb station_size - $
endstruc_32

%assign stationlengthshift 3		// stationsize shr this gives length
%assign stationtracksand 7		// stationsize and this gives tracks
%assign stationlengthmax 1 << (8-stationlengthshift)-1
%assign stationtracksmax stationtracksand

