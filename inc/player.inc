// starts at offset given in [77914] (normally 52a62)
struc player
	.name: 		resw 1	// 00h:name text ID; 0 for non-existing players
	.nameparts:	resd 1	// 02h:text ref stack argument for name text ID
			resw 1	// 06h:?
			resd 1	// 08h:?
			resd 1	// 0ah:?
	.cash: 		resd 1	// 10h:	cash of player	(use [addexpenses] to modify for overflow protection)
			resb 0x19-$
	.cashfract:	resb 1	// 19h: fraction of cash, for subtracting sub-dollar amounts
			resb 0x26-$
	.thisyearexpenses:resd 12//26h: several types of expenses in this year
			resb 0xc2-$
	.thisquarterincome:resd 1//c2h: income in this quarter
			resb 0xd6-$
	.lastquarterincome:
			resd 1	// d6h:	income in last quarter
			resb 0x2b6-$
	.inaugurated:	resw 1	// 2b6h:year the company was launched (full, not 1920-based)
			resb 0x2bb-$
	.aiaction:	resb 1	// 2bbh:current AI action
			resb 0x3a3-$
	.tracktypes:	resb 1	// 3a3h:number of track types available for building
	.hqlocation: 	resw 1	// 3a4h:location of headquarters
	.shareowners:	resb 4	// 3a6h:owners of the four shares
			resb 0x3b2-$
endstruc_32


