
%assign NINDUSTRIES	37

// starts at offset given in [7790c] (normally 51766)
struc industry
	.XY: 		resw 1	// 00h:coordinates
	.townptr: 	resd 1	// 02h:offset to industry's city struct
	.dimensions: 	resw 1	// 06h:size
	.producedcargos:resb 2	// 08h:two cargo types produced here
	.amountswaiting:resw 2	// 0ah:amount waiting for delivery to a station
	.prodrates:	resb 2	// 0eh:production rate
	.accepts:	resb 3	// 10h:three cargo types accepted (not for station acceptance, only for cargo actually delivered!)
	.prodmultiplier:resb 1	// 13h:production multiplier;
				// 10h=default production, minimum is 4 (quarter of default production), maximum is 80h
				// if zero, industry will be removed next month
	.totalproduced:	resw 2	// 14h:total amount produced this month
	.totaltransp:	resw 2	// 18h:total transported this month
	.transpfract:	resb 2	// 1ch:how much cargo was transported last month (0-none..255-all)
	.lastmonthprod:	resw 2	// 1eh:total amount produced last month
	.lastmonthtransp:resw 2	// 22h:total transported last month
	.type:		resb 1	// 26h:type of industry
	.owner:		resb 1	// 27h:owner
	.buildingcolor:	resb 1	// 28h:color of some buildings
	.lastyearprod:	resb 1	// 29h:last year something was produced
	.prodcounter: 	resw 1	// 2ah:production counter
	.didprocess:	resb 1	// 2ch:set to 1 when the industry produces something; used for toy factory animation
	.unused1:	resb 1	// 2dh:unused by TTD
// the following fields are added by TTDPatch
	.random:	resw 1	// 2eh:random bits
	.consdate:	resw 1	// 30h:construction date
	.badtreecuts:	resb 1	// 32h:number of unsuccessful treecuts; used only by TTDPatch,
				// and only for industries that cut trees
	.unused3:	resb 3	// 33h:unused by TTD, initialized to 0
endstruc_32

ptrvardec industrydatablock

struc industrydatastruc

// production flags:
// bit	meaning
// 0	extractive
// 1	organic
// 2	processing
ptrvarofs industryproductionflags,industrydatablock,$
resb NINDUSTRIES

// closure messages
ptrvarofs industryclosuremsgs,industrydatablock,$
resw NINDUSTRIES

// production increase messages
ptrvarofs industryprodincmsgs,industrydatablock,$
resw NINDUSTRIES

// production decrease messages
ptrvarofs industryproddecmsgs,industrydatablock,$
resw NINDUSTRIES

// fund cost multipliers
ptrvarofs industryfundcostmultis,industrydatablock,$
resb NINDUSTRIES

// produced cargo types
ptrvarofs industryproducedcargos,industrydatablock,$
resw NINDUSTRIES

// accepted cargo types
ptrvarofs industryacceptedcargos,industrydatablock,$
resd NINDUSTRIES

// production rates
ptrvarofs industryprod1rates,industrydatablock,$
resb NINDUSTRIES
ptrvarofs industryprod2rates,industrydatablock,$
resb NINDUSTRIES

// minimum amounts of cargo distributed from the industry
ptrvarofs industrymindistramounts,industrydatablock,$
resb NINDUSTRIES

// placement check procedures
ptrvarofs industryplacecheckprocs,industrydatablock,$
resd NINDUSTRIES

// pointers to random sound effect lists
ptrvarofs industryrandomsoundptrs,industrydatablock,$
resd NINDUSTRIES

endstruc_32
