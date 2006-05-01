
numtowns equ 70

// starts at 264h
struc town
	.XY: 		resw 1	// 00h:coordinates of city center
	.population: 	resw 1	// 02h:population
	.citynametype: 	resw 1	// 04h:text index for city name
	.citynameparts: resd 1	// 06h:IDs of the parts making up the name
	.expcountdown:	resb 1	// 0ah:countdown to expansion
	.displayidx:	resb 1	// 0bh:for alphabetic ordering
	.nameposx:	resw 1	// 0ch: absolute pixel coordinate
	.nameposy:	resw 1	// 0eh: absolute pixel coordinate
	.namewidth:	resb 1	// 10h: in pixels, normal font
	.namewidthsmall:resb 1	//11h: in pixels, small font
	.flags:		resw 1	// 12h:flags, bitcoded: 1=can expand, 2=has church, 4=has stadium
	.zones:		resw 5	// 14h:radii of town zones
	.ratings:	resw 8	// 1eh:company ratings for 8 companies
	.companiesrated:resd 1	// 2eh:bitmask of the companies with ratings
	.havestatue:	resd 1	// 32h:bitmask of the companies that have a statue in this town
	.buildingcount:	resw 1	// 36h:number of buildings in the town
			resb 1	// 38h:??
	.expansionrate:	resb 1	// 39h:used to reset .expcountdown
	.maxpassacc:	resw 1	// 3ah:max. passengers transported so far ('accumulated') this month
	.maxmailacc:	resw 1	// 3ch:     mail
	.actpassacc:	resw 1	// 3eh:actual passengers transported so far this month
	.actmailacc:	resw 1	// 40h:       mail
	.maxpasstrans: 	resw 1	// 42h:max. passengers transported last month
	.maxmailtrans: 	resw 1	// 44h:     mail
	.actpasstrans: 	resw 1	// 46h:actual passengers transported
	.actmailtrans: 	resw 1	// 48h:       mail
	.passtranspfr:	resb 1	// 4ah:fraction of passengers transported last month (255~100%)
	.mailtranspfr:	resb 1	// 4bh:            mail
	.foodthismonth:	resw 1	// 4ch:food (or fizzy drinks) received so far this month
	.waterthismonth:resw 1	// 4eh:water received so far this month (bogus if not in sub-tropical climate)
	.foodlastmonth:	resw 1	// 50h:food (or fizzy drinks) received last month
	.waterlastmonth:resw 1	// 52h:water received last month (bogus if not in sub-tropical climate)
	.roadworks:	resb 1	// 54h:for how many months the road works are yet to be active
	.buildingfund:	resb 1	// 55h:for how many months building funding is yet to be active
			resb 0x5e-$
endstruc

// TTDPatch extension
// has the same size to make pointer arithmetic easier
struc town2
	.population:	resd 1	// 00h:population, full (protects town.population from overflows)
	.companiesunwanted:resb 8 // 04h:if nonzero a company will be unwanted for this many months
	.passthismonth:	resw 1	// 0ch:passengers received so far this month
	.mailthismonth:	resw 1	// 0eh:mail received so far this month
	.goodsthismonth:resw 1	// 10h:goods (or sweets) received so far this month
			resw 1	// 12h:reserved
	.passlastmonth:	resw 1	// 14h:passengers received last month
	.maillastmonth:	resw 1	// 16h:mail received last month
	.goodslastmonth:resw 1	// 18h:goods (or sweets) received last month
			resw 1	// 1ah:reserved
	.boundrectminx:	resb 1	// 1ch:coordinates of bounding rectangle of town, used to speed up house counting for newhouses
	.boundrectminy: resb 1
	.boundrectmaxx:	resb 1
	.boundrectmaxy:	resb 1
			resb 0x5e-$
endstruc

