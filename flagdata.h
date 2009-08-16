// This file is part of TTDPatch
//
// flagdata.h: Define switch variables
//

// This will be included both in C and assembly code, therefore we use
// special one-line macros which are defined appropriately for each
// language:
//
//  simple variables:
//    defbyte(name), defword(name), deflong(name)
//  arrays:
//    defbytes(name, size), defwords(name, size), deflongs(name, size)
//
// where 'name' is the name of the variable.  In C, it's a field in the
// paramset.data struct; in assembly, it's a global variable.
//
// Longs and words should be aligned at 4 and 2 byte boundaries, respectively.

// long variables:
deflong(miscmodsflags)		// flags for the miscmods switch
deflong(miscmods2flags)		// flags for the miscmods2 switch
deflong(animarraysize)		// new size of the animated tiles array
deflong(autoslopevalue)		// setting for autoslope cost
deflong(forcegameoptionssettings)	// game options settings in ttdpatch bit format
deflong(mapsize)			// map size, for special var 13.
deflong(rvovertakeparamsvalue)	//flag bits for road vehicle overtaking behaviour modificaton
deflong(cfgtransbits)		// bits for initial transparency options
deflong(cargodestroutecmpfactor)	// factor to multiply minimum route by then shift right 16 to produce route threshold

#define flags_long_end newservint

// word variables:
defword(newservint)		// new def. service interval
defword(expswitches)		// bit mask of enabled experimental features
defword(coloryear)		// the year when TTD news becomes colored
defword(trainlosttime)		// time in days until trains...
defword(rvlosttime)		// ...road vehicles...
defword(shiplosttime)		// ...ships....
defword(aircraftlosttime)	// ...and aircraft are considered to be lost
defword(cargoforgettime)	// a cargo type is removed from a station after this many days if it isn't picked up
defword(windowsize)		// x size of the TTD/Win windowed mode
defword(aibuildrailchance)	// chance of building a rail-route *65535
defword(aibuildrvchance)	// chance of building a rv-route *65535
defword(aibuildairchance)	// chance of building a air-route *65535

defword(reswidth)		// Resolution width
defword(resheight)		// Resolution height

// custom town growth rate variables:
defword(townmaxgrowthrate)	// max. growth rate in houses per 100 years
defword(tgrpassinmax)		// maximum number of passengers accepted that will influence growth

defword(branchprobab)		// probability of a road branch
defword(semaphoreyear)		// year before which semaphores are built
defword(cdstrtcostexprthrshld)	// time after which an unused single hop route expires

#define flags_word_end townmingrowthrate

defbyte(townmingrowthrate)	// min. growth rate in houses per 100 years
defbyte(tgractstationexist)	// influence of having any active stations / 10 (signed, default 5)
defbyte(tgractstations)		// influence of each active station / 10 (default 10)
defbyte(tgractstationsweight)	// weight of the active stations into the rate calculation
defbyte(tgrpassoutweight)	// weight of the fraction of passengers transported
defbyte(tgrmailoutweight)	// weight of the fraction of mail transported
defbyte(tgrpassinweight)	// weight of the influence of the number of passengers accepted
defbyte(tgrmailinoptim)		// population per 2 bags of mail that stimulates growth optimally
defbyte(tgrmailinweight)	// weight of the influence of the mail accepted
defbyte(tgrgoodsinoptim)	// population per 2 crates of goods that stimulates growth optimally
defbyte(tgrgoodsinweight)	// weight of the influence of the goods accepted
defbyte(tgrfoodinmin)		// minimum population per 2 tonnes of food for a town to grow
defbyte(tgrfoodinoptim)		// optimal population per 2 tonnes of food for a town to grow
defbyte(tgrfoodinweight) 	// how much food affects growth rate
defbyte(tgrwaterinmin)		// minimum population per 2 tonnes of water for a town to grow
defbyte(tgrwaterinoptim)	// optimal population per 2 tonnes of water for a town to grow
defbyte(tgrwaterinweight)	// how much water affects growth rate
defbyte(tgrsweetsinoptim)	// population per 2 crates of sweets that stimulates growth optimally
defbyte(tgrsweetsinweight)	// weight of the influence of the sweets accepted
defbyte(tgrfizzydrinksinoptim)	// population per 2 fizzy drinks that stimulates growth optimally
defbyte(tgrfizzydrinksinweight)	// weight of the influence of the fizzy drinks accepted
defbyte(tgrtownsizebase)	// town size (number of houses) that yields base growth rate
defbyte(tgrtownsizefactor)	// how much town size affects growth rate
defbyte(townminpopulationsnow)	// minimum 'guaranteed' population of towns on snow
defbyte(townminpopulationdesert)// minimum 'guaranteed' population of towns on desert

// unsigned byte variables:
// defbyte(aiboostfactor)		// AI boost factor
defbyte(newstationspread)	// new maximum station spread in tiles
defbyte(vehicledatafactor)	// size multiplier of vehicle array
defbytes(mctype, 2)		// [0]:curves [1]:mountains
defbytes(newvehcount, 4)	// trains,rv,plane,ship
defbyte(planecrashctrl)		// plane crash control byte
defbyte(multihdspeedup)		// max. speed up for multiple heads in percent
defbyte(disastermask)		// mask of allowed disasters
defbytes(signalwaittimes, 2) 	// days to wait on red signals, 1- and 2-way
defbyte(unimaglevmode)		// mode of monorail-maglev unification
defbyte(newbridgespeedpc)	// max. new bridge speed in percent of highest engine speed
defbyte(languageid)		// current TTD language ID
defbyte(startyear)		// default start year, 1920-based
defbyte(redpopuptime)		// time after which red popup windows close, 0=very long
defbyte(bigtownfreq)		// frequency of towns that can grow larger
defbyte(townsizelimit)		// distance limit for the random town growth procedure
defbyte(treeplantmode)		// flags for the plantmanytrees switch
defbyte(morecurropts)		// options for the morecurrencies patch
defbyte(rvcrashtype)		// new type of train/rv crashes
defbyte(towngrowthratemode)	// mode of town growth rate calculation
defbyte(morebuildoptionsflags)	// flags for morebuildoptions
defbyte(moresteamsetting)	// setting for moresteam
defbyte(sortfrequency)		// time between two orderings
defbyte(maprefreshfrequency)	// time between two full map redraws
defbyte(networktimeout)		// network response timeout in seconds
defbyte(toylandfeatures)	// random map features enabled in toyland
defbyte(freightweightfactor)	// what cargo carried by freight trains is multiplied by
defbyte(mousewheelsettings)	// flags for mouse wheel support
defbyte(newwindowcount)		// new maximum count of visible windows on-screen
defbyte(abanroadmode)		// decides what abandonedroads should do with roads in towns
defbyte(windowsnapradius)	// from what distance windows should snap together
defbyte(wagonspeedlimitempty)	// speed limit increase for empty wagons
defbyte(locomotionguibits)	// bits for the locomotion switch
defbyte(planespeedfactor)	// factor for planespeed switch
defbyte(pbssettings)		// bit settings for PBS
defbyte(newsoundsettings)	// bit settings for newsounds
defbyte(replaceminreliab)	// minimum reliability for autoreplace
defbyte(stationsizevalue)	// maximum size of a railway station complex (as well as station spread)
defbyte(numindustries)		// industry count limit
defbyte(cdstcargopacketinitttl)	// the ttl for newly created cargo packets

#define flags_ubyte_end replaceage

// signed byte variables:
defbyte(replaceage)		// months relative to age for autorenew
defbyte(initgamespeed)		// initial game speed setting

defbytes(flags_byte_end,1)	// end marker wasting a byte b/o OpenWatcom
