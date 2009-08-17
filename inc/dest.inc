struc cargopacket
	.prevptr:	resd 1	//relative to start of cargo packet store. These two form a doubly linked list.
	.nextptr:	resd 1	//same
	.location:	resd 1
	.lasttransprofit:	resd 1
	.flags:		resw 1	//1=destroy packet immediately without payment
	.dateleft:	resw 1
	.datearrcurloc:	resw 1	//date arrived at current station or boarded current vehicle
	.amount:	resw 1
	.lastboardedst:	resb 1	//station id at which the packet last boarded a vehicle
	.ttl:		resb 1
	.cargo:		resb 1
	.destst:	resb 1
	.sourcest:	resb 1
	resb 32-$
endstruc

struc routingtableentry
	.dest:		resd 1
	.destrttable:	resd 1	//always of the next hop
	.nexthop:	resd 1	//for far destination entries, the hop to use (location)
	.next:		resd 1	//next entry 
	.cargo:		resb 1
	.flags:		resb 1
	.mindays:	resw 1	//when updated: calculate the difference in costs, divide by 4 and add to this. Initially, set to the the first cost.
	.lastupdated:	resw 1
	.oldestwaiting:	resw 1	//for next hop entries only
	resb 32-$
endstruc

struc routingtable
	.location:	resd 1
	.nexthoprtptr:	resd 1	//routingtableentry linked list pointed to, relative to cargodestgamedata
	.destrtptr:	resd 1	//same but for destinations past the first hop		
	.cargopacketsfront:	resd 1	//pointer to doubly-linked list of cargo packets: front
	.cargopacketsrear:	resd 1	//pointer to doubly-linked list of cargo packets: rear
	.flags:		resw 1
	.packetprodtempval:	resw 1	//ATM this is the indice of the last routingtable indice used to produce a cargo packet
	resb 32-$
endstruc

struc cargodestgamedata
	.version:	resd 1	//put "1" here
	.headerlength:	resd 1
	.cddfirstfree:	resd 1
	.cddfreeleft:	resd 1
	.cddusedend:	resd 1
	.reserved:		//for future use
	resb 4096-$
	.vehcplist:	resd 0x10000	//this should be reasonably sparse, and so not take up too much space when saved
	.vehrttimelist:	resw 0x10000	//ditto
	.datastart:
endstruc

//%assign cargopacketstore_reservesize 0x1000000
%assign cargodestdata_reservesize 0x4000000
%assign cargodestdata_initialsize (cargodestgamedata.datastart+0xFFFF)&(~0xFFFF)

//location types
//upper word:	type, lower word: number
//types:	0,	packet not linked, or no specific location/position
//		1,	station id
//		2,	vehicle id
