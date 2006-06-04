//
// This file is part of TTDPatch
// Copyright (C) 1999-2003 by Josef Drexler
//
// sw_list.h: list of command line and config file switches
//
// will be processed by perl/sw_sort.pl to sort the switches
// and generate sw_lists.h
//


//
// Usage of the options:
//
// YESNO(cmdline, cfgfile, cfgtext, category, bitname)
//
// RANGE(cmdline, cfgfile, cfgtext, category, bitname, radix, varsize,
//		  FLAGDATA(var), low, high, default)
//
// BITS (cmdline, cfgfile, cfgtext, category, bitname, varsize, FLAGDATA(var), default)
//
// SPCL (cmdline, cfgfile, cfgtext, category, &var)
//
// cmdline is the char that is the command line option
// cfgfile is the string that is the config file option name
//		if zero, this switch won't be written with -W
// cfgtext is the CFG_xxx constant that corresponds to this switch
// category is the category from the manual, see below
// bitname is the name of the switch in common.h
// radix is 0 for autodetect, 1 for octal, 2 for decimal,
//		3 for hexadecimal, add 4 to invert bitwise
// varsize is 0 for unsigned char, 1 for unsigned short
//		2 for signed short(2), 3 for signed long(4)
//		4 for signed char
// var is the flags->data element for RANGE, or a pointer to
//		an int for SPCL (or NULL which needs a handler)
// low,high,default give the range and default for RANGE
//
// BITS needs bit definitions in bitnames.ah
//
//
// Available categories:



		// single-char options, lowercase

	##ch##

	SPCL ('a', "all", 0, BASIC, NULL),
	RANGE('b', "ships", CFG_SHIPS, VEH, increaseshipcount, 0, 0, FLAGDATA(newvehcount[3]), 1, 240, 240),
	RANGE('c', "curves", CFG_CURVES, VEH, usenewcurves, 3, 1, &mcparam[0], 0, 0x3333, 0x0120),
	YESNO('d', "showfulldate", CFG_SHOWFULLDATE, INTERFACE, showfulldate),
	RANGE('e', "spread", CFG_SPREAD, INFST_STATION, largerstations, 0, 0, FLAGDATA(newstationspread), 1, 255, 20),
	YESNO('f', "trainrefit", CFG_TRAINREFIT, VEH_RAIL, allowtrainrefit),
	YESNO('g', "generalfixes", CFG_GENERALFIXES, BASIC, generalfixes),
	SPCL ('h', NULL, 0, NONE, NULL),
	RANGE('i', "servint", CFG_SERVINT, VEH, setnewservinterval, 0, 1, FLAGDATA(newservint), 1, 32767, 16000),
	     //j
	YESNO('k', "keepsmallairport", CFG_KEEPSMALLAP, INFST_STATION, keepsmallairports),
	YESNO('l', "largestations", CFG_LARGESTATIONS, INFST_STATION, morestationtracks),
	RANGE('m', "mountains", CFG_MOUNTAINS, VEH, usenewmountain, 3, 1, &mcparam[1], 0, 0x3333, 0x0120),
	YESNO('n', "nonstop", CFG_NONSTOP, VEH_ORDERS, usenewnonstop),
	SPCL ('o', "reducedsave", 0, NONE, OBSOLETE),
	RANGE('p', "planes", CFG_PLANES, VEH, increaseplanecount, 0, 0, FLAGDATA(newvehcount[2]), 1, 240, 240),
	YESNO('q', "loadtime", CFG_LOADTIME, INFST_STATION, improvedloadtimes),
	RANGE('r', "roadvehs", CFG_ROADVEHS, VEH, increaservcount, 0, 0, FLAGDATA(newvehcount[1]), 1, 240, 240),
	YESNO('s', "signcheats", CFG_SIGNCHEATS, DIFFICULTY, usesigncheat),
	RANGE('t', "trains", CFG_TRAINS, VEH, increasetraincount, 0, 0, FLAGDATA(newvehcount[0]), 1, 240, 240),
	YESNO('u', "enhancemultiplayer", CFG_ENHMULTI, BASIC, enhancemultiplayer),
	SPCL ('v', "verbose", CFG_VERBOSE, BASIC, &showswitches),
	YESNO('w', "presignals", CFG_PRESIGNALS, INFST_RAIL_SIGNAL, presignals),
	RANGE('x', "morevehicles", CFG_MOREVEHICLES, VEH, uselargerarray, 0, 0, FLAGDATA(vehicledatafactor), 1, 40, 1),
	SPCL ('y', NULL, 0, BASIC, &alwaysrun),
	YESNO('z', "mammothtrains", CFG_MAMMOTHTRAINS, VEH_RAIL, mammothtrains),
	SPCL ('?', NULL, 0, NONE, NULL),


		// uppercase

	//RANGE('A', "aiboost", CFG_AIBOOST, aibooster, 0, 0, FLAGDATA(aiboostfactor), 0, 255, 0),
	//RANGE('A', "aiboost", CFG_AIBOOST, aibooster, 0, 0, FLAGDATA(aiboostfactor), 0, 4, 0),
	SPCL ('A', "aiboost", 0, NONE, OBSOLETE),
	YESNO('B', "longbridges", CFG_LONGBRIDGES, INFST_BRIDGE, longerbridges),
	SPCL ('C', "include", 0, NONE, NULL),
	YESNO('D', "extradynamite", CFG_DYNAMITE, HOUSESTOWNS, morethingsremovable),
	YESNO('E', "moveerrorpopup", CFG_MOVEERRORPOPUP, INTERFACE, moveerrorpopup),
	YESNO('F', "fullloadany", CFG_FULLLOADANY, VEH_ORDERS, fullloadany),
	RANGE('G', "selectgoods", CFG_SELECTGOODS, VEH_ORDERS, selectstationgoods, 0, 1, FLAGDATA(cargoforgettime), 2, 600, 365),
	YESNO('H', "custombridgeheads", CFG_CUSTOMBRIDGEHEADS, INFST_BRIDGE, custombridgeheads),	// i doubt hugeairports will be made :P
	YESNO('I', "noinflation", CFG_NOINFLATION, FINANCEECONOMY, noinflation),
	YESNO('J', "moreairports", CFG_MOREAIRPORTS, INFST_STATION, moreairports),
	     //K
	YESNO('L', "debtmax", CFG_DEBTMAX, INTERFACE, maxloanwithctrl),
	RANGE('M', "multihead", CFG_MULTIHEAD, VEH_RAIL, multihead, 0, 0, FLAGDATA(multihdspeedup), 0, 100, 35),
	YESNO('N', "morenews", CFG_MORENEWS, INTERFACE_NEWS, morenews),
	YESNO('O', "officefood", CFG_OFFICEFOOD, HOUSESTOWNS, officefood),
	YESNO('P', "enginespersist", CFG_ENGINESPERSIST, VEH, persistentengines),
	     //Q
	YESNO('R', "rvqueueing", CFG_RVQUEUEING, VEH_ROAD, newlineup),
	YESNO('S', "newships", CFG_NEWSHIPS, VEH, newships),
	YESNO('T', "newtrains", CFG_NEWTRAINS, VEH, newtrains),
	BITS ('U', "locomotiongui", CFG_LOCOMOTIONGUI, INTERFACE, locomotiongui, 0, FLAGDATA(locomotionguibits), 1),
	SPCL ('V', "writeverfile", 0, NONE, OBSOLETE),
	SPCL ('W', "writecfg", 0, NONE, NULL),
	     //X reserved for extended switches, see below
	     //Y reserved for extended switches, see below
	SPCL ('Z', "lowmemory", 0, NONE, OBSOLETE),

	YESNO('2', "win2k", CFG_WIN2K, BASIC, win2k),


		// X-extended, lowercase

	##maketwochars('X',ch)##

	RANGE('1',"signal1waittime", CFG_SIGNAL1WAITTIME, INFST_RAIL_SIGNAL, setsignal1waittime, 0, 0, FLAGDATA(signalwaittimes[0]), 0, 255, 70),
	RANGE('2',"signal2waittime", CFG_SIGNAL2WAITTIME, INFST_RAIL_SIGNAL, setsignal2waittime, 0, 0, FLAGDATA(signalwaittimes[1]), 0, 255, 20),
	RANGE('a',"autorenew", CFG_AUTORENEW, VEH, autorenew, 0, 4, FLAGDATA(replaceage), -128, 127, -6),
	YESNO('b',"bribe", CFG_BRIBE, HOUSESTOWNS, bribe),
	BITS ('c',"planecrashcontrol", CFG_PLANECRCTRL, VEH_AIR, noplanecrashes, 0, FLAGDATA(planecrashctrl), 1),
	YESNO('d',"gotodepot", CFG_GOTODEPOT, VEH_ORDERS, gotodepot),
	YESNO('e',"eternalgame", CFG_ETERNALGAME, DIFFICULTY, eternalgame),
	YESNO('f',"feederservice", CFG_FEEDERSERVICE, VEH_ORDERS, feederservice),
	YESNO('g',"gradualloading", CFG_GRADUALLOADING, INFST_STATION, gradualloading),
	YESNO('h',"newhouses", CFG_NEWHOUSES, HOUSESTOWNS, newhouses),
	YESNO('i',"stableindustry", CFG_STABLEINDUSTRY, INDUSTRIESCARGO, stableindustry),
	     //j
	     //k
	YESNO('l',"canals", CFG_CANALS, INFST, canals),
	YESNO('m',"diskmenu", CFG_DISKMENU, INTERFACE, diskmenu),
	SPCL( 'n',"newgrfcfg", CFG_NEWGRFCFG, BASIC, NULL),
	YESNO('o',"cheatscost", CFG_CHEATSCOST, DIFFICULTY, cheatscost),
	YESNO('p',"newperformance", CFG_NEWPERF, DIFFICULTY, newperformance),
	     //q
	SPCL ('r',"forcerebuildovl", CFG_FORCEREBUILDOVL, BASIC, &forcerebuildovl),
	YESNO('s',"showspeed", CFG_SHOWSPEED, INTERFACE_VEH, showspeed),
	RANGE('t',"towngrowthlimit", CFG_TOWNGROWTHLIMIT, HOUSESTOWNS, newtowngrowthfactor, 0, 0, FLAGDATA(townsizelimit), 12, 128, 80),
	     //u
	RANGE('v',"sortvehlist", CFG_SORTVEHLIST, INTERFACE_VEH, sortvehlist, 0, 0, FLAGDATA(sortfrequency), 0, 255, 10),
	YESNO('w',"extpresignals", CFG_EXTPRESIGNALS, INFST_RAIL_SIGNAL, extpresignals),
	YESNO('x',"saveoptionaldata", CFG_SAVEOPTDATA, BASIC, saveoptdata),
	     //y
	RANGE('z',"windowsnap", CFG_WINDOWSNAP, INTERFACE_WINDOW, windowsnap, 0, 0, FLAGDATA(windowsnapradius), 0, 255, 10),


		// X-extended, uppercase

	YESNO('A',"forceautorenew", CFG_FORCEAUTORENEW, VEH, forceautorenew),
	YESNO('B',"buildwhilepaused", CFG_BUILDWHILEPAUSED, DIFFICULTY, buildwhilepaused),
	BITS ('C',"morecurrencies", CFG_MORECURRENCIES, FINANCEECONOMY, morecurrencies, 0, FLAGDATA(morecurropts), 0),
	BITS ('D',"disasters", CFG_DISASTERS, DIFFICULTY, maskdisasters, 0, FLAGDATA(disastermask), 255),
	YESNO('E',"electrifiedrailway", CFG_ELECTRIFIEDRAIL, INFST_RAIL, electrifiedrail),
	BITS ('F',"experimentalfeatures", CFG_EXPERIMENTALFEATURES, BASIC, experimentalfeatures, 1, FLAGDATA(expswitches), 0xFFFF & ~4),
	SPCL ('G',"loadallgraphics", 0, NONE, OBSOLETE),
	YESNO('H',"newshistory", CFG_NEWSHISTORY, INTERFACE_NEWS, newshistory),
	BITS ('I',"pathbasedsignalling", CFG_PATHBASEDSIGNALLING, INFST_RAIL_SIGNAL, pathbasedsignalling, 0, FLAGDATA(pbssettings), 11),
	     //J
	     //K
	YESNO('L',"showprofitinlist", CFG_SHOWPROFITINLIST, INTERFACE_VEH, showprofitinlist),
	RANGE('M',"unifiedmaglev", CFG_UNIFIEDMAGLEV, INFST_RAIL, unifiedmaglev, 0, 0, FLAGDATA(unimaglevmode), 1, 3, 3),
	RANGE('N',"newspapercolour", CFG_NEWSPAPERCOLOUR, INTERFACE_NEWS, newspapercolour, 0, 1, FLAGDATA(coloryear), 1920, 2070, 2000),
	YESNO('O',"sharedorders", CFG_SHAREDORDERS, VEH_ORDERS, sharedorders),
	YESNO('P',"newplanes", CFG_NEWPLANES, VEH, newplanes),
	     //Q
	YESNO('R',"newrvs", CFG_NEWRVS, VEH, newrvs),
	YESNO('S',"subsidiaries", CFG_SUBSIDIARIES, FINANCEECONOMY, subsidiaries),
	RANGE('T',"largertowns", CFG_LARGERTOWNS, HOUSESTOWNS, largertowns, 0, 0, FLAGDATA(bigtownfreq), 1, 70, 4),
	     //U
	     //V
	RANGE('W',"stretchwindow", CFG_STRETCHWINDOW, INTERFACE_WINDOW, stretchwindow, 0, 1, FLAGDATA(windowsize), 40, 20480, 1280),
	RANGE('X',"bridgespeedlimits", CFG_BRIDGESPEEDS, INFST_BRIDGE, newbridgespeeds, 0, 0, FLAGDATA(newbridgespeedpc), 25, 250, 90),
	RANGE('Y',"startyear", CFG_STARTYEAR, DIFFICULTY, newstartyear, 2, 1, &startyear, 1921, 2030, 1930),
	YESNO('Z', "lowmemory", CFG_LOWMEMORY, BASIC, lowmemory),


		// Y-extended, lowercase

	##maketwochars('Y',ch)##

	YESNO('a',"newagerating", CFG_NEWAGERATING, VEH_RAIL, newagerating),
	YESNO('b',"buildonslopes", CFG_BUILDONSLOPES, TERRAIN, buildonslopes),
	YESNO('c',"tracktypecostdiff", CFG_TRACKTYPECOSTDIFF, INFST_RAIL, tracktypecostdiff),
	YESNO('d',"newbridges", CFG_NEWBRIDGES, INFST_BRIDGE, newbridges),
	     //e
	RANGE('f',"freighttrains", CFG_FREIGHTTRAINS, VEH_RAIL, freighttrains, 0, 0, FLAGDATA(freightweightfactor), 1, 100, 5),
	RANGE('g',"gamespeed", CFG_GAMESPEED, INTERFACE, gamespeed, 0, 0, FLAGDATA(initgamespeed), -3, 3, 0),
	YESNO('h',"higherbridges", CFG_HIGHERBRIDGES, INFST_BRIDGE, higherbridges),
	     //i
	     //j
	     //k
	BITS ('l',"mousewheel", CFG_MOUSEWHEEL, INTERFACE, mousewheel, 0, FLAGDATA(mousewheelsettings), 5),
	YESNO('m',"manualconvert", CFG_MANCONVERT, INFST_RAIL, manualconvert),
	YESNO('n',"newstations", CFG_NEWSTATIONS, INFST_STATION, newstations),
	BITS ('o',"miscmods", CFG_MISCMODS, BASIC, miscmods, 3, FLAGDATA(miscmodsflags), 0),
	BITS ('p',"plantmanytrees", CFG_MANYTREES, TERRAIN, plantmanytrees, 0, FLAGDATA(treeplantmode), 3),
	     //q
	RANGE('r',"newrvcrash", CFG_NEWRVCRASH, VEH_ROAD, newrvcrash,0,0,FLAGDATA(rvcrashtype),1,2,1),
	YESNO('s',"signalsontrafficside", CFG_SIGNALSONTRAFFICSIDE, INFST_RAIL_SIGNAL, signalsontrafficside),
	YESNO('t',"moretownstats", CFG_MORETOWNSTATS, HOUSESTOWNS, displmoretownstats),
	     //u
	     //v
	YESNO('w',"fastwagonsell",CFG_FASTWAGONSELL,INTERFACE_VEH, fastwagonsell),
	     //x
	     //y
	     //z


		// Y-extended, uppercase

	RANGE('A',"abandonedroads", CFG_ABANDONEDROADS, INFST_ROADS, abandonedroads, 0, 0, FLAGDATA(abanroadmode), 0, 2, 0),
	BITS ('B',"morebuildoptions", CFG_MOREBUILDOPTIONS, INFST, morebuildoptions, 0, FLAGDATA(morebuildoptionsflags), 0xcf),	// REMOVE_INDUSTRY=16, CLOSEINDUSTRIES=32 disabled by default
	YESNO('C',"buildoncoasts", CFG_BUILDONCOASTS, TERRAIN, buildoncoasts),
	YESNO('D',"enhanceddifficultysettings", CFG_ENHANCEDDIFFICULTYSETTINGS, DIFFICULTY, enhanceddiffsettings),
	RANGE('E',"errorpopuptime", CFG_ERRORPOPUPTIME, INTERFACE, newerrorpopuptime, 0, 0, FLAGDATA(redpopuptime), 0, 255, 10),
	YESNO('F',"fifoloading", CFG_FIFOLOADING, INFST_STATION, fifoloading),
	YESNO('G',"enhancegui", CFG_ENHANCEGUI, INTERFACE, enhancegui),
	YESNO('H',"morehotkeys", CFG_MOREHOTKEYS, INTERFACE, morehotkeys),
	// YESNO('I',"moreindustriesperclimate", CFG_MOREINDUSTRIESPERCLIMATE, moreindustriesperclimate),
	SPCL ('I',"moreindustriesperclimate", 0, NONE, OBSOLETE),
	     //J
	     //K
	RANGE('L',"wagonspeedlimits", CFG_WAGONSPEEDLIMITS, VEH_RAIL, wagonspeedlimits, 0, 0, FLAGDATA(wagonspeedlimitempty), 0, 255, 20),
	RANGE('M',"moresteam", CFG_MORESTEAM, VEH_RAIL, moresteam, 3, 0, FLAGDATA(moresteamsetting), 0, 0x55, 0x23),
	YESNO('N',"newtownnames",CFG_NEWTOWNNAMES,HOUSESTOWNS, newtownnames),
	YESNO('O',"tempsnowline", CFG_TEMPSNOWLINE, TERRAIN, tempsnowline),
	RANGE('P',"planespeed", CFG_PLANESPEED, VEH_AIR, planespeed, 0, 0, FLAGDATA(planespeedfactor), 1, 4, 4),
	     //Q
	RANGE('R',"maprefresh", CFG_MAPREFRESH, INTERFACE, maprefresh, 0, 0, FLAGDATA(maprefreshfrequency), 1, 255, 1),
	YESNO('S',"semaphores", CFG_SEMAPHORES, INFST_RAIL_SIGNAL, semaphoresignals),
	RANGE('T',"towngrowthratemode", CFG_TOWNGROWTHRATEMODE, HOUSESTOWNS, newtowngrowthrate, 0, 0, FLAGDATA(towngrowthratemode), 0, 2, 2),
	     //U
	     //V
	RANGE('W',"morewindows", CFG_MOREWINDOWS, INTERFACE_WINDOW, morewindows, 0, 0, FLAGDATA(newwindowcount), 11, 255, 20),
	     //X
	     //Y
	     //Z


		// cfg-only (no command line switch)
	##ch##
	SPCL (155,"cdpath", CFG_CDPATH, BASIC, NULL),
	RANGE(128,"towngrowthratemin", CFG_TOWNGROWTHRATEMIN, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(townmingrowthrate), 0, 255, 20),
	RANGE(129,"towngrowthratemax", CFG_TOWNGROWTHRATEMAX, HOUSESTOWNS, noswitch, 0, 1, FLAGDATA(townmaxgrowthrate), 10, 4800, 600),
	RANGE(130,"tgractstationexist", CFG_TGRACTSTATIONEXIST, HOUSESTOWNS, noswitch, 0, 4, FLAGDATA(tgractstationexist), -128, 127, 5),
	RANGE(131,"tgractstations", CFG_TGRACTSTATIONS, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgractstations), 0, 255, 10),
	RANGE(132,"tgractstationsweight", CFG_TGRACTSTATIONSWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgractstationsweight), 0, 255, 55),
	RANGE(133,"tgrpassoutweight", CFG_TGRPASSOUTWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrpassoutweight), 0, 255, 40),
	RANGE(134,"tgrmailoutweight", CFG_TGRMAILOUTWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrmailoutweight), 0, 255, 10),
	RANGE(135,"tgrpassinmax", CFG_TGRPASSINMAX, HOUSESTOWNS, noswitch, 0, 1, FLAGDATA(tgrpassinmax), 0, 65535, 5000),
	RANGE(136,"tgrpassinweight", CFG_TGRPASSINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrpassinweight), 0, 255, 40),
	RANGE(137,"tgrmailinoptim", CFG_TGRMAILINOPTIM, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrmailinoptim), 1, 255, 25),
	RANGE(138,"tgrmailinweight", CFG_TGRMAILINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrmailinweight), 0, 255, 10),
	RANGE(139,"tgrgoodsinoptim", CFG_TGRGOODSINOPTIM, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrgoodsinoptim), 1, 255, 20),
	RANGE(140,"tgrgoodsinweight", CFG_TGRGOODSINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrgoodsinweight), 0, 255, 20),
	RANGE(141,"tgrfoodinmin", CFG_TGRFOODINMIN, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrfoodinmin), 1, 255, 80),
	RANGE(142,"tgrfoodinoptim", CFG_TGRFOODINOPTIM, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrfoodinoptim), 1, 255, 20),
	RANGE(143,"tgrfoodinweight", CFG_TGRFOODINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrfoodinweight), 0, 255, 30),
	RANGE(144,"tgrwaterinmin", CFG_TGRWATERINMIN, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrwaterinmin), 1, 255, 80),
	RANGE(145,"tgrwaterinoptim", CFG_TGRWATERINOPTIM, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrwaterinoptim), 1, 255, 20),
	RANGE(146,"tgrwaterinweight", CFG_TGRWATERINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrwaterinweight), 0, 255, 30),
	RANGE(147,"tgrsweetsinoptim", CFG_TGRSWEETSINOPTIM, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrsweetsinoptim), 1, 255, 20),
	RANGE(148,"tgrsweetsinweight", CFG_TGRSWEETSINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrsweetsinweight), 0, 255, 20),
	RANGE(149,"tgrfizzydrinksinoptim", CFG_TGRFIZZYDRINKSINOPTIM, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrfizzydrinksinoptim), 1, 255, 30),
	RANGE(150,"tgrfizzydrinksinweight", CFG_TGRFIZZYDRINKSINWEIGHT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrfizzydrinksinweight), 0, 255, 30),
	RANGE(151,"tgrtownsizebase", CFG_TGRTOWNSIZEBASE, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrtownsizebase), 1, 255, 60),
	RANGE(152,"tgrtownsizefactor", CFG_TGRTOWNSIZEFACTOR, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(tgrtownsizefactor), 0, 255, 63),
	RANGE(153,"townminpopulationsnow", CFG_TOWNMINPOPULATIONSNOW, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(townminpopulationsnow), 0, 255, 90),
	RANGE(156,"townminpopulationdesert", CFG_TOWNMINPOPULATIONDESERT, HOUSESTOWNS, noswitch, 0, 0, FLAGDATA(townminpopulationdesert), 0, 255, 60),
	SPCL (157,"cusmultiplier", 0, NONE, OBSOLETE),
	RANGE(158,"losttrains", CFG_TRAINLOSTTIME, VEH_ORDERS, losttrains, 0, 1, FLAGDATA(trainlosttime), 5, 1000, 150),
	RANGE(159,"lostrvs", CFG_RVLOSTTIME, VEH_ORDERS, lostrvs, 0, 1, FLAGDATA(rvlosttime), 5, 1000, 150),
	RANGE(160,"lostships", CFG_SHIPLOSTTIME, VEH_ORDERS, lostships, 0, 1, FLAGDATA(shiplosttime), 5, 1000, 400),
	RANGE(161,"lostaircraft", CFG_AIRCRAFTLOSTTIME, VEH_ORDERS, lostaircraft, 0, 1, FLAGDATA(aircraftlosttime), 5, 1000, 90),
	RANGE(162,"networktimeout", CFG_NETWORKTIMEOUT, BASIC, disconnectontimeout, 0, 0, FLAGDATA(networktimeout), 2, 240, 10),
	BITS (163,"toylandfeatures", CFG_TOYLANDFEATURES, TERRAIN, moretoylandfeatures, 0, FLAGDATA(toylandfeatures), 1),
	RANGE(164,"moreanimation", CFG_MOREANIMATION, INTERFACE, moreanimation, 0, 3, FLAGDATA(animarraysize), 256, 65535, 4096),
	YESNO(165,"townbuildnoroads", CFG_TOWNBUILDNOROADS, HOUSESTOWNS, townbuildnoroads),
	YESNO(166,"aichoosechances", CFG_AICHOOSECHANCES, DIFFICULTY, aichoosechances),
	RANGE(167,"aibuildrailchance", CFG_AIBUILDRAILCHANCE, DIFFICULTY, noswitch, 0, 1, FLAGDATA(aibuildrailchance), 0, 65535, 30246),
	RANGE(168,"aibuildrvchance", CFG_AIBUILDRVCHANCE, DIFFICULTY, noswitch, 0, 1, FLAGDATA(aibuildrvchance), 0, 65535, 20164),
	RANGE(169,"aibuildairchance", CFG_AIBUILDAIRCHANCE, DIFFICULTY, noswitch, 0, 1, FLAGDATA(aibuildairchance), 0, 65535, 5041),
	YESNO(170,"newcargodistribution", CFG_NEWCARGODISTRIBUTION, INDUSTRIESCARGO, newcargodistribution),
	RANGE(171,"resolutionwidth", CFG_RESOLUTIONWIDTH, BASIC, resolutionwidth, 0, 1, FLAGDATA(reswidth), 640, 2048, 800),
	RANGE(172,"resolutionheight", CFG_RESOLUTIONHEIGHT, BASIC, resolutionheight, 0, 1, FLAGDATA(resheight), 480, 2048, 600),
	YESNO(173,"newindustries", CFG_NEWINDUSTRIES, INDUSTRIESCARGO, newindustries),
	RANGE(175,"townroadbranchprob",CFG_TOWNROADBRANCHPROB,HOUSESTOWNS, townroadbranchprob, 0, 1, FLAGDATA(branchprobab), 0, 0xffff, 0x5555),
	YESNO(176,"newcargos", CFG_NEWCARGOS, INDUSTRIESCARGO, newcargos),
	YESNO(177,"onewayroads", CFG_ONEWAYROADS, INFST_ROADS, onewayroads),
	BITS (178,"newsounds", CFG_NEWSOUNDS, BASIC, newsounds, 0, FLAGDATA(newsoundsettings), 1),
	YESNO(179,"irregularstations", CFG_IRRSTATIONS, INFST_STATION, irrstations),
	YESNO(180,"morestatistics", CFG_MORESTATS, INTERFACE, morestats),
	RANGE(181,"autoreplace", CFG_AUTOREPLACE, VEH, autoreplace, 0, 0, FLAGDATA(replaceminreliab), 1, 100, 80),
	RANGE(182,"autoslope", CFG_AUTOSLOPE, TERRAIN, autoslope, 0, 1, FLAGDATA(autoslopevalue), 1, 3, 1),
	YESNO(183,"followvehicle", CFG_FOLLOWVEHICLE, INTERFACE_VEH, followvehicle),
	YESNO(184,"trams", CFG_TRAMS, INFST_ROADS, trams),
	YESNO(185,"enhancetunnels", CFG_ENHANCETUNNELS, INFST, enhancetunnels),
	SPCL (186,"saveextradata", 0, NONE, OBSOLETE),
	BITS (187,"forcegameoptions", CFG_FORCEGAMEOPTIONS, INTERFACE, forcegameoptions, 3, FLAGDATA(forcegameoptionssettings), 0),
//
// Here follows the switch order list
// This list defines the order of switches in the switch table
// (displayed if verbose=on).  This is simply a list of bit names
// (from common.h) separated by commas.
//

SWITCHORDER:			// not actually a label, see perl/sw_sort.pl
	usenewcurves,
	usenewmountain,
	usenewnonstop,
	setnewservinterval,
	autorenew,
	forceautorenew,
	gotodepot,
	largerstations,
	morestationtracks,
	uselargerarray,
	saveoptdata,
	improvedloadtimes,
	gradualloading,
	presignals,
	extpresignals,
	increasetraincount,
	increaservcount,
	increaseplanecount,
	increaseshipcount,
	noinflation,
	maxloanwithctrl,
	persistentengines,
	fullloadany,
	selectstationgoods,
	keepsmallairports,
	longerbridges,
	morethingsremovable,
//	aibooster,
	multihead,
	newlineup,
	generalfixes,
	moreairports,
	bribe,
	noplanecrashes,
	showspeed,
	officefood,
	usesigncheat,
	cheatscost,
	diskmenu,
#if WINTTDX
	win2k,
#else
	lowmemory,
#endif
	feederservice,
	allowtrainrefit,
	showfulldate,
	subsidiaries,
	mammothtrains,
	moveerrorpopup,
	newerrorpopuptime,
	maskdisasters,
	morenews,
	unifiedmaglev,
	newbridgespeeds,
	newstartyear,
	eternalgame,
	newtrains,
	newrvs,
	newships,
	newplanes,
	newstations,
	newbridges,
	newhouses,
	electrifiedrail,
	largertowns,
	newtowngrowthfactor,
	miscmods,
	loadallgraphics,
	morebuildoptions,
	semaphoresignals,
	morehotkeys,
	plantmanytrees,
	tracktypecostdiff,
	morecurrencies,
	manualconvert,
	newtowngrowthrate,
	displmoretownstats,
	enhancegui,
	enhanceddiffsettings,
	newagerating,
	buildonslopes,
	buildoncoasts,
	planespeed,
	fastwagonsell,
	newrvcrash,
	stableindustry,
	newperformance,
	sortvehlist,
	newspapercolour,
	sharedorders,
	showprofitinlist,
	moresteam,
	abandonedroads,
//	moreindustriesperclimate,
	signalsontrafficside,
	buildwhilepaused,
	losttrains,
	lostrvs,
	lostships,
	lostaircraft,
	maprefresh,
#if WINTTDX
	disconnectontimeout,
	stretchwindow,
#endif
	moretoylandfeatures,
	canals,
	gamespeed,
	higherbridges,
	freighttrains,
	experimentalfeatures,
	newtownnames,
	moreanimation,
	newshistory,
	wagonspeedlimits,
	townbuildnoroads,
	custombridgeheads,
	aichoosechances,
	newcargodistribution,
	windowsnap,
	resolutionwidth,
	resolutionheight,
	newindustries,
	locomotiongui,
	mousewheel,
	morewindows,
	pathbasedsignalling,
	fifoloading,
	tempsnowline,
	townroadbranchprob,
	newcargos,
#if WINTTDX
	enhancemultiplayer,
#endif
 	onewayroads,
	newsounds,
	irrstations,
	morestats,
	autoreplace,
	autoslope,
	followvehicle,
	trams,
	enhancetunnels,
	forcegameoptions,

