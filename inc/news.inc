%define NEWS_HISTORY_SIZE	32
struc newsitem
	.item		resw 1	// text ID for types 0, 1, 2; parameter for type 3
	.textrefstack	resb 32	//
	.countdown	resw 1	// decremented every tick, when reaches 0 the news window closes
	.date		resw 1	//
	.flags		resb 1	// +01h: has view area; landscape X,Y in par3,par4
				// +02h: has view area; vehicle idx in par3
				// +04h: clicking brings location(s) in par1,par2
				// +08h: clicking brings vehicle, idx in par1
				// +10h: always display full window
				// +20h: display (if not set then skip)
	.type		resb 1	// type of news report or message:
				// 0 - small message window with a view area
				// 1 - tall news window (430x170)
				// 2 - short news window (430x130)
				// 3 - tall news window, redraw handled via a class function
	.category	resw 1
	.par1		resw 1	// XY of first click location, or click vehicle idx
	.par2		resw 1	// XY of second location (0 if not present)
	.par3		resw 1	// type3: handler class offset
				// other: view area's X location or vehicle idx
	.par4		resw 1	// type3: handler function number
				// other: view area's Y location
endstruc

// .type
%define cNews_small 0		// small message window with a view area
%define cNews_tall 1		// tall news window (430x170)
%define cNews_short 2		// short news window (430x130)
%define cNews_tall_class 3	// tall news window, redraw handled via a class function
				//     (class offset in par3, function number in par4)
// .flags
%define cNews_view_XY 0x01	// has view area; landscape X,Y in par3,par4
%define cNews_view_veidx 0x02	// has view area; vehicle idx in par3
%define cNews_click_XY 0x04	// clicking brings location(s) in par1,par2
%define cNews_click_veidx 0x08	// clicking brings vehicle, idx in par1
%define cNews_always_full 0x10	// always display full window
%define cNews_display 0x20	// display (if not set then skip)

// .category
%define cNews_cat_1stplveh 0	// first vehicle at player's station
%define cNews_cat_1stcompveh 1	// first vehicle at competitor's station
%define cNews_cat_disaster 2	// accident/disaster
%define cNews_cat_company 3	// company information
%define cNews_cat_economy 4	// economy changes
%define cNews_cat_vehicle 5	// advice/information on player's vehicles
%define cNews_cat_newveh 6	// new vehicles
%define cNews_cat_cargo 7	// changes of cargo acceptance
%define cNews_cat_subsidies 8	// subsidies
%define cNews_cat_general 9	// general information

