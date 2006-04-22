#!/usr/bin/perl -w
use strict;

# This script automatically updates outdated lang files by adding all
# required additional lines

my $debug = 0;

# remove these entries
my @remove = qw(
	LANG_SWWAITFORKEY LANG_SHOWSWITCHINTRO LANG_SWTABLEVERCHAR LANG_TOSTARTTTD
	LANG_SWONEWAY LANG_SWTWOWAY LANG_TIMEDAYS LANG_INFINITETIME
	LANG_SCROLLKEYS LANG_SCROLLABORTKEY LANG_SWSHOWLOAD LANG_SWABORTLOAD
	CFG_AIBOOST CFG_MOREINDUSTRIESPERCLIMATE
	aibooster
	);

# rename these entries
my %rename = (
	LANG_NOTENOUGHMEM => 'LANG_NOTENOUGHMEMTTD',
	);

# change comment only
my %changecomm = (
	LANG_NOFILESFOUND =>
		q~neither do the original files (two %s are two filenames)~,
	CFG_CDPATH => "",
	);

# add entries after other entries
my %append = (
	LANG_UNKNOWNSWITCH => [
		q~~,
		q~// switch bit name is unknown.  First %s is bit name, 2nd is switch name~,
		q~SETTEXT(LANG_UNKNOWNSWITCHBIT, "Unknown bit '%s' for switch '%s'.\n")~,
		],
	LANG_INFINITETIME => [
		q~~,
		q~// Shows the keys to scroll the verbose switch table~,
		q~SETTEXT(LANG_SCROLLKEYS, " Keys: Up Down PgUp PgDown Home End ")~,
		q~~,
		q~// ... and to abort TTDPatch~,
		q~SETTEXT(LANG_SCROLLABORTKEY, " Escape = abort ")~,
		],
	LANG_REGISTRYERROR => [
		q~~,
		q~// Trying no-registry file~,
		q~SETTEXT(LANG_TRYINGNOREGIST, "Trying no-registry information from %s\n")~,
		q~~,
		q~// no-registry file failed~,
		q~SETTEXT(LANG_NOREGISTFAILED, "No-registry information not available.\n")~,
		],
	LANG_NOTENOUGHMEMTTD => [
		q~~,
		q~// Other out-of-memory messages~,
		q~// %s is a function or variable name to identify where the memory allocation failed~,
		q~SETTEXT(LANG_NOTENOUGHMEM, "%s: Not enough memory available, need %d KB more.\n")~,
		],
	LANG_RUNERROR => [
		q~~,
		q~// Failed to create the new process for ttdloadw.ovl~,
		q~SETTEXT(LANG_CRPROCESSFAIL, "Create process failed")~,
		q~~,
		q~// Interprocess communication error: TTDPatchW seems to be already running~,
		q~SETTEXT(LANG_IPCEXISTS, "Another instance of TTDPatch is already running!\n")~,
		q~~,
		q~// Failed to convert language strings to Unicode~,
		q~SETTEXT(LANG_STRINGCONVFAIL, "Error while preparing TTDPatch data!\n")~,
		],
	LANG_ERRORCREATING => [
		q~~,
		q~~,
		q~//---------------------------------------~,
		q~//  MESSAGES DISPLAYED BY TTDLOAD~,
		q~//---------------------------------------~,
		q~~,
		q~// Messages in this category will have "TTDPatch: " prefixed and "\r\n" suffixed~,
		q~// when displayed by the DOS version.~,
		q~~,
		q~// Out of memory (in protected mode)~,
		q~SETTEXT(LANG_PMOUTOFMEMORY, "Not enough free memory!")~,
		q~~,
		q~// Interprocess communication failed (WinTTDX only)~,
		q~SETTEXT(LANG_PMIPCERROR, "Interprocess communication error")~,
		],
	stableindustry => [
		q~SWITCHTEXT(newperformance, "New performance rating", "")~,
		q~SWITCHTEXT(sortvehlist, "Sort vehicle lists", ", delay: %d")~,
		q~SWITCHTEXT(showprofitinlist, "Show profit in vehicle list", "")~,
		q~SWITCHTEXT(newspapercolour, "Newpapers are in colour", " after %d")~,
		q~SWITCHTEXT(sharedorders, "Enable shared/copied orders", "")~,
		q~SWITCHTEXT(moresteam, "Show more steam plumes", ": %x")~,
		q~SWITCHTEXT(abandonedroads, "Abandoned roads lose their owners", ", mode %d")~,
		q~SWITCHTEXT(newstations, "Enable new station graphics", "")~,
		q~SWITCHTEXT(buildwhilepaused, "Enable construction while paused", "")~,
		q~SWITCHTEXT(losttrains, "Warning about lost trains", " after %d days")~,
		q~SWITCHTEXT(lostrvs, "Warning about lost road vehicles", " after %d days")~,
		q~SWITCHTEXT(lostships, "Warning about lost ships", " after %d days")~,
		q~SWITCHTEXT(lostaircraft, "Warning about lost aircraft", " after %d days")~,
		q~SWITCHTEXT(maprefresh, "New map refresh frequency", ": %d ticks")~,
		q~SWITCHTEXT(disconnectontimeout, "Disconnect a network game if there is no response", " for %d sec.")~,
		q~SWITCHTEXT(moretoylandfeatures, "Enable some random game features in toyland", ": %d")~,
		q~SWITCHTEXT(stretchwindow, "Stretch TTD's window", " to %d pixels")~,
		q~SWITCHTEXT(canals, "Build canals and locks", "")~,
		q~SWITCHTEXT(higherbridges, "Allow higher bridges", "")~,
		q~SWITCHTEXT(gamespeed, "Changeable gamespeed", ", initially %d")~,
		q~SWITCHTEXT(freighttrains, "Make freight trains more massive", " (x%d)")~,
		q~SWITCHTEXT(mousewheel, "Enable mouse wheel",", setting: %d")~,
		q~SWITCHTEXT(morewindows, "Increase maximum window count", " to %d")~,
		q~SWITCHTEXT(enhanceddiffsettings, "Enhanced difficulty settings", "")~,
		q~SWITCHTEXT(newbridges, "New bridges", "")~,
		q~SWITCHTEXT(newhouses, "New town buildings", "")~,
		q~SWITCHTEXT(newtownnames,"New town name styles","")~,
		q~SWITCHTEXT(moreanimation,"Allow more animated tiles",", up to %d")~,
		q~SWITCHTEXT(newshistory, "News history", "")~,
		q~SWITCHTEXT(wagonspeedlimits, "Speed limits for train wagons", "")~,
		q~SWITCHTEXT(pathbasedsignalling, "Enable path based signalling", "")~,
		q~SWITCHTEXT(aichoosechances, "Specify which chances to use when the ai decides what to build", "")~,
		q~SWITCHTEXT(custombridgeheads, "Custom bridge heads", "")~,
		q~SWITCHTEXT(townbuildnoroads, "Towns build no roads", "")~,
		q~SWITCHTEXT(newcargodistribution, "Enhanced cargo distribution", "")~,
		q~SWITCHTEXT(windowsnap, "Windows snap together", " when closer than %d pixels")~,
		q~SWITCHTEXT(resolutionwidth, "Resolution width", " %d pixels")~,
		q~SWITCHTEXT(resolutionheight, "Resolution height", " %d pixels")~,
		q~SWITCHTEXT(newindustries, "New industries", "")~,
		q~SWITCHTEXT(locomotiongui, "Enable locomotion style gui", "")~,
		q~SWITCHTEXT(fifoloading, "Enable FIFO loading", "");~,
		q~SWITCHTEXT(tempsnowline, "Enable snow line on temperate", "")~,
		q~SWITCHTEXT(townroadbranchprob, "Change town road branch prob.", " to %d")~,
		q~SWITCHTEXT(newcargos, "Allow new cargo types", "")~,
		q~SWITCHTEXT(enhancemultiplayer, "Enhance multiplayer games (allow more players)", "")~,
		q~SWITCHTEXT(newsounds, "Allow adding new sounds to the game", "")~,
		q~SWITCHTEXT(morestats, "Enable collection of more statistics", "")~,
		q~SWITCHTEXT(onewayroads, "Allow changing roads to one-way with 'Ctrl'", "")~,
		q~SWITCHTEXT(irrstations, "Enable irregular station construction", "")~,
		q~SWITCHTEXT(autoreplace, "Upgrade vehicles when they get old", "; %d%% min. reliability for new model")~,
		q~SWITCHTEXT(autoslope, "Allows terraforming without removing structures", "")~,
		q~SWITCHTEXT(followvehicle, "Follow vehicle motion in main map", "")~,
		q~SWITCHTEXT(trams, "Enable trams on Roads", "")~,
		q~SWITCHTEXT(enhancetunnels, "Allows building track on top of tunnel entrances", "")~,
		q~~,
		q~//---------------------------------------~,
		q~//  BIT SWITCH DESCRIPTIONS~,
		q~//---------------------------------------~,
		q~~,
		q~// Description for noplanecrashes bits~,
		q~BITSWITCH(noplanecrashes)~,
		q~BIT(normdis,      "normal plane crashes off if disasters off")~,
		q~BIT(jetsdis,      "crashes of jets on small airports off if disasters off")~,
		q~BIT(normbrdown,   "normal plane crashes only for broken down planes, rate * 4")~,
		q~BIT(jetssamerate, "same rate for jets on small airports and normal crashes")~,
		q~BIT(normoff,      "normal plane crashes off")~,
		q~BIT(jetsoff,      "jets on small airport crashes off")~,
		q~~,
		q~// Description for miscmods bits~,
		q~BITSWITCH(miscmods)~,
		q~BIT(nobuildonbanks,        "towns don't build on waterbanks")~,
		q~BIT(servintonlyhuman,      "servint setting doesn't apply to AI players")~,
		q~BIT(noroadtakeover,        "towns don't claim all roads in the scenario editor")~,
		q~BIT(gradualloadbywagon,    "gradual loading loads wagon by wagon first")~,
		q~BIT(dontfixlitres,         "don't change litres so that 1000 l is a ton instead of 100 l")~,
		q~BIT(dontfixtropicbanks,    "don't fix bank types in the sub-tropical climate")~,
		q~BIT(dontfixhousesprites,   "don't fix offices being displayed as churches")~,
		q~BIT(oldtownterrmodlimit,   "don't change the upper cost of terrain modification for towns")~,
		q~BIT(nozeppelinonlargeap,   "prevent Zeppelins from crashing at large airports")~,
		q~BIT(nodefaultoldtracktype, "don't use previous track type as new default")~,
		q~BIT(usevehnnumbernotname,  "don't change news messages to use vehicle names")~,
		q~BIT(norescalecompanygraph, "don't rescale company graph when companies are deselected")~,
		q~BIT(noyearlyfinances,      "don't display yearly finances on Jan 1st")~,
		q~BIT(notimegiveaway,        "don't try to give time slices away to conserve power")~,
		q~BIT(nodesynchwarning,      "don't warn about multiplayer games being desynched")~,
		q~BIT(noworldedgeflooding,   "don't let the edge of the map flood")~,
		q~BIT(doshowintro,           "show the game intro (don't skip it)")~,
		q~BIT(nonewspritesorter,     "don't use new sprite sorting algorithm")~,
		q~BIT(noenhancedcomp,        "don't enhance savegame compression algorithm")~,
		q~BIT(breakdownatsignal,     "don't fix trains breaking down while waiting on red signals")~,
		q~BIT(smallspritelimit,      "don't increase the sprite limit")~,
		q~BIT(displaytownsize,       "display town size in the name")~,
		q~BIT(noextendstationrange,  "don't increase the maximum allowed distance between station sign and industry for cargo to be delivered")~,
		q~BIT(nooldvehiclenews,      "don't generate news messages when vehicles get old")~,
		q~BIT(dontfixpaymentgraph,   "don't fix the X axis of the cargo payment rate window")~,
		q~BIT(loaduntilgreen,        "keep loading at station until exit signal is green")~,
		q~BIT(dontshowaltitude,      "Don't show altitude in tile info window")~,
		q~BIT(nogrfidsinscreenshots, "Don't show active grfids in screenshots")~,
		q~BIT(dontchangesnow,        "Don't change how height is calculated for snowiness")~,
		q~~,
		q~// Description for morebuildoptions bits~,
		q~BITSWITCH(morebuildoptions)~,
		q~BIT(ctunnel,         "allow crossing tunnels")~,
		q~BIT(oilrefinery,     "allow oil refinery everywhere")~,
		q~BIT(moreindustries,  "allow more than one industry of the same type")~,
		q~BIT(removeobjects,   "allow removing statues, lighthouses and transmitters")~,
		q~BIT(removeindustry,  "allow removing industries")~,
		q~BIT(closeindustries, "allow same industries to be very close to each other")~,
		q~BIT(enhancedbuoys,   "allow buoys that work like normal stations")~,
		q~BIT(bulldozesignals, "automatically bulldoze signals on track")~,
		q~~,
		q~// Description for experimentalfeatures bits~,
		q~BITSWITCH(experimentalfeatures)~,
		q~BIT(slowcrossing, "trains slow down before crossings")~,
		q~BIT(cooperative,  "cooperative play, very limited")~,
		q~BIT(mandatorygrm, "make GRF Resource Management mandatory for .grf files")~,
		q~~,
		q~// Description for maskdisasters bits~,
		q~BITSWITCH(maskdisasters)~,
		q~BIT(zeppelincrash,      "Allow zeppelin crash")~,
		q~BIT(smallufo,           "Allow small UFO")~,
		q~BIT(refineryexplosion,  "Allow refinery explosion")~,
		q~BIT(factoryexplosion,   "Allow factory explosion")~,
		q~BIT(largeufo,           "Allow large UFO")~,
		q~BIT(smallsubmarine,     "Allow small submarine")~,
		q~BIT(largesubmarine,     "Allow large submarine")~,
		q~BIT(coalminesubsidence, "Allow coal mine subsidence")~,
		q~~,
		q~// Description for mousewheel bits~,
		q~BITSWITCH(mousewheel)~,
		q~BIT(cursorzoom, "Zoom at cursor location instead of screen center")~,
		q~BIT(safezoom,   "Zoom only after rolling wheel two notches")~,
		q~BIT(legacy,     "Enable support for older (legacy) operating systems and drivers (not normally needed)")~,
		q~~,
		q~// Description for plantmanytrees bits~,
		q~BITSWITCH(plantmanytrees)~,
		q~BIT(morethanonepersquare,   "Allow planting more than one tree per square")~,
		q~BIT(rectangular,            "Enable planting over a rectangular area with 'Ctrl'")~,
		q~BIT(morethanonerectangular, "More than one tree on a square in the rectangular planting mode")~,
		q~~,
		q~// Description for moretoylandfeatures bits~,
		q~BITSWITCH(moretoylandfeatures)~,
		q~BIT(lighthouses, "Enable lighthouses on sea shores in Toyland")~,
		q~BIT(woodlands,   "Enable woodlands (clusters of trees) in Toyland")~,
		q~~,
		q~// Description for locomotiongui bits~,
		q~BITSWITCH(locomotiongui)~,
		q~BIT(usenewgui,      "Enable the new gui")~,
		q~BIT(defaultnewgui,  "Use the new gui by default (with this disabled the new gui can be reached with ctrl, when enabled with ctrl the old gui will be used)")~,
		q~BIT(defaultstation, "Make the station build button open the locomotion gui station tab.")~,
		q~~,
		q~// Description for pathbasedsignalling bits~,
		q~BITSWITCH(pathbasedsignalling)~,
		q~BIT(autoconvertpresig,    "Convert pre, exit and combo signals into PBS signals")~,
		q~BIT(manualpbssig,         "Allow manually setting PBS signals")~,
		q~BIT(preservemanualpresig, "Don't convert junctions with manually set signals into PBS")~,
		q~BIT(showreservedpath,     "Show reserved track pieces darker")~,
		q~BIT(shownonjunctionpath,  "Show reserved track pieces on non-junction tiles too")~,
		q~BIT(allowunsafejunction,  "Don't hold trains at unsafe PBS signal")~,
		q~BIT(allowunsafereverse,   "Don't stop trains that can't reverse safely")~,
		q~~,
		q~// Description for newsounds bits~,
		q~BITSWITCH(newsounds)~,
		q~BIT(highfrequency, "(DOS only) Mix sounds at 22KHz instead of the default 11KHz. Allows correct playpack of 22KHz samples.")~,
		q~~,
		q~// Description for morecurrencies bits~,
		q~BITSWITCH(morecurrencies)~,
		q~BIT(symbefore, "Currency symbol displayed always before number")~,
		q~BIT(symafter,  "Currency symbol displayed always after number")~,
		q~BIT(noeuro,    "Do not introduce the Euro")~,
		q~BIT(comma,     "Always use comma to separate thousands")~,
		q~BIT(period,    "Always use period to separate thousands")~,
		q~~,
		],
	CFG_NEWSWITCHINTRO => [
		q~~,
		q~// For switches which have no command line equivalent~,
		q~SETTEXT(CFG_NOCMDLINE, "no command line switch")~,
		],
	CFG_STABLEINDUSTRY => [
		q~SETTEXT(CFG_NEWPERF, "`%s' (%s) applies a more reasonable performance calculation regarding vehicle profits.")~,
		q~SETTEXT(CFG_SORTVEHLIST, "`%s' (%s) sorts vehicles in vehicle list windows. The parameter sets how much time elapses between two updates. Lower settings requre more CPU time, but keep the list more up-to date. The setting of 10 means approximately a TTD day. Range %ld..%ld. Default %ld.")~,
		q~SETTEXT(CFG_NEWSPAPERCOLOUR, "`%s' (%s) changes newspapers to colour in the given year.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_SHAREDORDERS, "`%s' (%s) allows shared or copied orders.")~,
		q~SETTEXT(CFG_SHOWPROFITINLIST, "`%s' (%s) shows colour-coded profit in the list of vehicles.")~,
		q~SETTEXT(CFG_MORESTEAM, "`%s' (%s) shows more (or fewer) steam plumes. Parameter has two digits, first for length of steam plume, second for frequency, with 2 being TTD's default.  Adding/subtracting one doubles/halves the length or frequency.  Range %02lx..%02lx.  Default %02lx.")~,
		q~SETTEXT(CFG_ABANDONEDROADS, "`%s' (%s) makes roads lose their owner if they aren't used for a period of time, so you can remove unused roads if they're in the way. You also get the ownership of unowned roads if your vehicles use them. In mode 0, all roads lose their owners, in mode 1, roads near towns are taken over by the towns if their aren't used for a while, in mode 2 they're taken over instantly.")~,
		q~SETTEXT(CFG_MOREINDUSTRIESPERCLIMATE, "`%s' (%s) enables more industries in climates, currently only paperindustries for temperate.")~,
		q~SETTEXT(CFG_NEWSTATIONS, "`%s' (%s) enables new station graphics.")~,
		q~SETTEXT(CFG_BUILDWHILEPAUSED, "`%s' (%s) enables all construction options even when the game is paused.")~,
		q~SETTEXT(CFG_TRAINLOSTTIME, "`%s' (%s) gives a warning about lost trains after the given number of days.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_RVLOSTTIME, "`%s' (%s) gives a warning about lost road vehicles after the given number of days.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_SHIPLOSTTIME, "`%s' (%s) gives a warning about lost ships after the given number of days.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_AIRCRAFTLOSTTIME, "`%s' (%s) gives a warning about lost aircraft after the given number of days.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_MAPREFRESH, "`%s' (%s) overrides the frequency TTD updates the map window.  Lower numbers mean faster refresh and more CPU usage.  TTD's default is 64.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_NETWORKTIMEOUT, "`%s' (%s) disconnects a network game if there is no response for the given number of seconds.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_TOYLANDFEATURES, "`%s' (%s) enables landscape features that are normally disabled in random games in the toyland climate, such as lighthouses.  Bitcoded value.")~,
		q~SETTEXT(CFG_STRETCHWINDOW, "`%s' (%s) stretches the TTD window to this horizontal size in pixels (only for the Windows version of TTD in windowed mode).  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_CANALS, "`%s' (%s) allows building canals and locks using the `buy land' tool from the dock construction menu.")~,
		q~SETTEXT(CFG_FREIGHTTRAINS, "`%s' (%s) multiplies the cargo carried by cargo trains with the given factor, to simulate very long freight trains.  This only affects train acceleration, the trains do not actually transport more.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_GAMESPEED, "`%s' (%s) Makes the gamespeed changeable. This requires the hotkeys patch. Press 'q' to speed up the game by a factor 2 (to a max of 8x speed) and 'w' to slow it down.  Parameter is the initial setting.  Range %ld..%ld.  Default %ld.")~,
		q~SETTEXT(CFG_HIGHERBRIDGES, "`%s' (%s) allows building of higher bridges.")~,
		q~SETTEXT(CFG_NEWGRFCFG, "`%s' (%s) chooses the configuration file for new graphics sets.")~,
		q~SETTEXT(CFG_MOUSEWHEEL, "`%s' (%s) enables using the mouse wheel in the Windows version. 0 means original zooming with wheel (center stays), 1 means OpenTTD-style zooming (point under mouse cursor stays if possible). Add 2 to enable 'safe' zooming (two rollings trigger zoom). Add 4 for legacy wheel support (needed for some drivers and Win95). Range %ld..%ld. Default %ld.")~,
		q~SETTEXT(CFG_MOREWINDOWS, "`%s' (%s) allows more windows to be open on the screen. TTD's default is 10, but 3 slots are always occupied (main toolbar, main view, status bar), so the actual maximum count is 7. Drop-down menus and news messages count as windows as well. Range %ld..%ld. Default %ld.")~,
		q~SETTEXT(CFG_ENHANCEDDIFFICULTYSETTINGS, "'%s' (%s) makes it possible to select 'none' for the number of industries in the difficulty settings.")~,
		q~SETTEXT(CFG_NEWBRIDGES, "`%s' (%s) enables new graphics for bridges.")~,
		q~SETTEXT(CFG_NEWHOUSES, "`%s' (%s) activates new town building types with new graphics.")~,
		q~SETTEXT(CFG_NEWTOWNNAMES, "`%s' (%s) allows adding new town name styles for random games via new grf files.")~,
		q~SETTEXT(CFG_MOREANIMATION, "`%s' (%s) allows increasing the number of tiles that can be animated. TTD's default is 256. Range %ld..%ld. Default %ld.")~,
		q~SETTEXT(CFG_NEWSHISTORY, "`%s' (%s) enables collecting and displaying of news history.")~,
		q~SETTEXT(CFG_WAGONSPEEDLIMITS, "`%s' (%s) enables speed limits for train wagons.")~,
		q~SETTEXT(CFG_PATHBASEDSIGNALLING, "`%s' (%s) enables path based signalling. Before enabling it PLEASE read the manual, this feature is somewhat difficult to use correctly.")~,
		q~SETTEXT(CFG_CUSTOMBRIDGEHEADS, "`%s' (%s) custom bridge heads.")~,
		q~SETTEXT(CFG_TOWNBUILDNOROADS, "`%s' (%s) towns build no roads.")~,
		q~SETTEXT(CFG_NEWCARGODISTRIBUTION, "`%s' (%s) enhanced cargo distribution.")~,
		q~SETTEXT(CFG_WINDOWSNAP, "`%s' (%s) let windows snap together. Range %ld..%ld. Default %ld.")~,
		q~SETTEXT(CFG_RESOLUTIONWIDTH, "`%s' (%s) enables and sets the width of the resolution patch.")~,
		q~SETTEXT(CFG_RESOLUTIONHEIGHT, "`%s' (%s) enables and sets the height of the resolution patch.")~,
		q~SETTEXT(CFG_AICHOOSECHANCES, "`%s' (%s) specify which chances to use when the ai decides what to build next (chance of building a ship route is 1-railchance-rvchance-airchance).")~,
		q~SETTEXT(CFG_AIBUILDRAILCHANCE, "`%s' (%s) the chance that the ai will build a rail-route when it wants to build a new route. Range %ld..%ld, 0=0%%, 65535=100%%. Default %ld.")~,
		q~SETTEXT(CFG_AIBUILDRVCHANCE, "`%s' (%s) the chance that the ai will build a rv-route when it wants to build a new route. Range %ld..%ld, 0=0%%, 65535=100%%. Default %ld.")~,
		q~SETTEXT(CFG_AIBUILDAIRCHANCE, "`%s' (%s) the chance that the ai will build a air-route when it wants to build a new route. Range %ld..%ld, 0=0%%, 65535=100%%. Default %ld.")~,
		q~SETTEXT(CFG_NEWINDUSTRIES, "`%s' (%s) enables support for new industry types.")~,
		q~SETTEXT(CFG_LOCOMOTIONGUI, "`%s' (%s) enable the new locomotion style gui.")~,
		q~SETTEXT(CFG_FIFOLOADING, "`%s' (%s) enable FIFO loading.")~,
		q~SETTEXT(CFG_TEMPSNOWLINE, "`%s' (%s) enables snow line on temperate (needs an appropriate GRF file to actually show snow)")~,
		q~SETTEXT(CFG_TOWNROADBRANCHPROB, "`%s' (%s) changes the probability of a town building a road branch. 0 means almost no branches, 65535 means branch everywhere possible. TTD's default is 26214. Range %ld..%ld. Default %ld.")~,
		q~SETTEXT(CFG_NEWCARGOS, "`%s' (%s) enables support for new cargo types.")~,
		q~SETTEXT(CFG_ENHMULTI, "`%s' (%s) enhances multiplayer games by allowing more human players.")~,
		q~SETTEXT(CFG_ONEWAYROADS, "`%s' (%s) enables one-way roads")~,
		q~SETTEXT(CFG_NEWSOUNDS, "`%s' (%s) allows adding new sounds to the game via custom GRF files.")~,
		q~SETTEXT(CFG_IRRSTATIONS, "`%s' (%s) allows to build station in irregular forms.")~,
		q~SETTEXT(CFG_MORESTATS, "`%s' (%s) enables collection of more statistics (only works if enhancegui is also enabled).")~,
		q~SETTEXT(CFG_AUTOREPLACE, "`%s' (%s) upgrades vehicles to the best available new type, with the given minimum reliability in percent.  Range 1..100, default 80.")~,
		q~SETTEXT(CFG_AUTOSLOPE, "`%s' (%s) allows to terraform without removeing structure.")~,
		q~SETTEXT(CFG_FOLLOWVEHICLE, "`%s' (%s) allows the main view to follow a vehicle with a right mouse click on the Center View button in the vehicles window.")~,
		q~SETTEXT(CFG_TRAMS, "`%s' (%s) allows trams to be built.")~,
		q~SETTEXT(CFG_ENHANCETUNNELS, "`%s' (%s) allows to build track on top of tunnel entrances")~,
		],
	);

# remove command line text
my @cmdremove = qw( );

# change command line text
my %cmdchange = (
	2 => 'Windows 2000/XP compatibility',
	);

# add command line texts
my %cmdafter = (
	s => [ u => 'Enhance multiplayer games' ],
	G => [ H => 'Custom bridge heads' ],
	Xg => [ Xh => 'New town buildings' ],
	Xi => [ Xl => 'Build canals and locks' ],
	Xo => [ Xp => 'New performance calculation' ],
	XA => [ XB => 'Enable construction while paused' ],
	XG => [ XH => 'Save+display news history',
		XI => 'Enable path based signalling',
		XL => 'Show profit in vehicle list',
		XO => 'Enabled shared/copied orders' ],
	Yc => [ Yd => 'New bridges',
		Yg => 'Changeable gamespeed',
		Yh => 'Allow higher bridges' ],

	Ym => [ Yn => 'Enable new station graphics' ],
	YC => [ YD => 'Enhanced difficulty settings',
		YF => 'FIFO loading' ],
	YH => [	YL => 'Speed limits for train wagons',
		YN => 'Enable new town name schemes' ],

#	z => [ undef, '' ],		???
#	Xw => [ Xx => 'Save and load additional data',
#		undef, '' ],		???
	);

# remove full-length switches
my @fullremove = qw( A );

# add full-length switches
my %fullafter = (
	M => [ U => 'Enable the new locomotion-like gui. 1 for new gui without ctrl.' ],
	Xt => [ Xv => 'Sort vehicle lists and set the time between two updates.',
		Xz => 'Snap windows together.' ],
	XD => [ XN => 'TTD newspaper in color after the given year' ],
	XY => [ XW => 'Stretch TTD\'s window to this size in pixels (Windows version only)' ],
	X1 => [ Yf => 'Make freight trains more massive by the given factor',
		Yl => 'Enable mouse wheel support and set options (Windows version only)' ],
	Yp => [ YA => 'Abandoned roads lose their owners, choose mode with parameter' ],
	YE => [ YM => 'Show more (or fewer) steam plumes, value sets amount' ],
	YG => [ YO => 'Enable the snow line in the temperate climate and set its height',
		YR => 'Override map refresh frequency to # ticks' ],
	YT => [ YW => 'Set maximum allowed window count' ],
	W => [ Xn => 'cfg-file: Uses this file as configuration file for new graphics sets' ],
	);

# make substitutions in text of entry
my %subs = (
	LANG_NOTENOUGHMEMTTD => [ qr/\%s/, 'to start TTD' ],
	selectstationgoods => [ qr/""/, '" for %d days"' ],
	CFG_SELECTGOODS => [ qr/(?<!\%ld)\.?"\)/, 
		', and disappear after the given number of days if the service stops.  '.
		'Specifying 2 means goods never disappear.  '.
		'Range: %ld..%ld.  Default: %ld' ],
	CFG_MORECURRENCIES => [ qr/\.[^.]*0.*"/, '".  Bitcoded value.  Default 0."' ],
	CFG_ENHANCEGUI => [ qr/,.*\%ld/, "Change the settings from the entry in TTD's toolbox menu." ],
	CFG_PLANESPEED => [ qr/(?<!\%ld)\."/, '.  Range %ld..%ld.  Default %ld."' ],
	LANG_SWSHOWLOAD => [ qr/".*"/, '"Enter/Space = run \"TTDLOAD %s\""' ],
	);

# same as above, but don't flag the changes (no translatable text involved)
my %subsnomod = (
	LANG_SWITCHOBSOLETE => [ qr/-\%s/, '%s' ],
	LANG_SHOWSWITCHINTRO => [ qr/"\\n"\n/, "" ],
	miscmods => [ qr/\%d/, '%ld' ],
	enhancegui => [ qr/"[^"]*\%d[^"]*"/, '""' ],
	experimentalfeatures => [ qr/\%d/, '%u' ],
	planespeed => [ qr/""/, '": %d/4"' ],
	CFG_LARGESTATIONS => [ qr/7(.)7/, "15${1}15" ],
	CFG_CDPATH => [ qr/\([^)]+\)/, '%s' ],
	CFG_MOREBUILDOPTIONS => [ qr/,.*\%ld/, "" ],
	CFG_TOWNGROWTHRATEMIN => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TOWNGROWTHRATEMAX => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRACTSTATIONEXIST => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRACTSTATIONS => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRACTSTATIONSWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRPASSOUTWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRMAILOUTWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRPASSINMAX => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRPASSINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRMAILINOPTIM => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRMAILINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRGOODSINOPTIM => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRGOODSINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRFOODINMIN => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRFOODINOPTIM => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRFOODINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRWATERINMIN => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRWATERINOPTIM => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRWATERINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRSWEETSINOPTIM => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRSWEETSINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRFIZZYDRINKSINOPTIM => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRFIZZYDRINKSINWEIGHT => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRTOWNSIZEBASE => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TGRTOWNSIZEFACTOR => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TOWNMINPOPULATIONSNOW => [ qr/\([^()]+\)/, '(%s)' ],
	CFG_TOWNMINPOPULATIONDESERT => [ qr/\([^()]+\)/, '(%s)' ],
	);
my @allsubs = map { [ $_, 1 ] } keys %subs;
push @allsubs, map { [ $_, 0 ] } keys %subsnomod;


our $w;
sub hasit() { return 1+index $_||'', $w||'' };

sub addafter(\@@) {
	my $this = shift;
	my $align = shift;
	my $cmdformat = shift;
	my $format = shift;
	my $par = shift;
	while (@$par) {
		my $c = shift @$par; my $arg = shift @$par;
		push @$this, [ $arg, 0 ] and next unless defined $c;
		my $form = eval $cmdformat;
		$form.= " " x ($align - length $form) if length $form < $align;
		push @$this, [ eval $format, 1 ];
	}
}



for my $f (@ARGV) {
print "Processing $f\n";
open my $file, "<", $f or die "Can't read $f: $!";
local $/;
my @data = split /(?<!\n)\n(?=\n)/, <$file>;
close $file;

my @paragraphs = map {
	  /TEXTARRAY\(halflines/ .. /}/ ?
		split(/\n(?=\s+)/, $_)
	: /SETTEXT\(LANG_FULLSWITCHES/ .. /\)/ ?
		split(/\n(?=[^\n]*")/, $_)
	: /SWITCHTEXT/ ? 
		split(/\n(?=\s*SWITCHTEXT)/, $_)
	: /SETTEXT\(CFG_/ ?
		split(/\n(?=\s*SETTEXT\(CFG_)/, $_)
	: $_
	} @data;

my @out;
LOOP: for my $i (0..$#paragraphs) {
	$_ = $paragraphs[$i];

	my $l = $_;
	$l =~ s/\n/\n\t/g;
	print "$i (BEFORE)\n\t$l\n" if $debug;

	my @this;
	my $mod;
	for $w (@remove) { next LOOP if hasit; };
	for $w (keys %rename) {
		next unless hasit;
		s/\Q$w/$rename{$w}/;
	}
	for $w (keys %changecomm) {
		next unless hasit;
		s#//[^\n]*#// $changecomm{$w}#;
	}
	for $w (keys %append) {
		next unless hasit;
		push @this, map [ $_, 1 ], @{$append{$w}};
	}
	my $c;
	for $c (@cmdremove) {
		$w = qq("-$c:); 
		next LOOP if hasit;
	}
	for $c (keys %cmdchange) {
		$w = qq("-$c:); next unless hasit;
		s/($c:\s*).*?"/$1$cmdchange{$c}"/; $mod=1;
	}
	for $c (keys %cmdafter) {
		$w = qq("-$c:); next unless hasit;
		addafter @this, 5, 'qq(-$c:)', 'qq(	  "$form$arg",)', $cmdafter{$c};
	}
	for $c (@fullremove) {
		$w = qq("-$c #:); 
		next LOOP if hasit;
	}
	for $c (keys %fullafter) {
		$w = qq("-$c #); next unless hasit;
		addafter @this, 9, 'qq(-$c #:)', 'qq(	  "$form$arg).q(\n")', $fullafter{$c};
	}
	for $c (@allsubs) {
		my $domod;
		($w,$domod) = @$c;
		next unless hasit;
		my @s = $domod ? @{$subs{$w}} : @{$subsnomod{$w}};
		my @lines = map [ $_, 0 ], split /\n/, $_; $_ = undef;
		my $found = 0;
		while (@s) {
			my $re = shift @s; my $repl = shift @s;
			for my $l (0..$#lines) {
				$lines[$l][0] =~ $re or next;
				my $match = $1; $repl =~ s/\$1/$match/;
				if ($lines[$l][0] =~ s/$re/$repl/) {
					$lines[$l][1] += $domod;
				}
			}
		}
		unshift @this, @lines;
	}

	unshift @this, [$_, $mod] if defined;

	if ($debug) {
		print "(AFTER)\n\t";
		for (@this) {
			my $l = $_->[0];
			$l =~ s/\n/\n\t/g;
			print "/***/" if $_->[1];
			print "$l\n";
		}
	}
	push @out, map { $_->[1] ? "/***/" : "", "$_->[0]\n" } @this;
}

open $file, ">", "$f.new" or die "Can't write $f.new: $!";
print $file @out;
close $file;

}
