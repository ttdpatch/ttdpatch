;
; This file contains the new in-game texts in all five language versions
; Note: Edit all the texts in iso-8859-1
;
; -------------------------------------
;     Text definitions
; -------------------------------------
;
;
; How to make a new entry:
; 	- add one TO THE END of inc/ourtext.inc before defourtext lasts:
;		defourtext <entryname>
;	- add the text for each language, these texts must be within 
;	  their respective language block.  Example:
;		def <entryname> db "Hello!"
;		def <entryname> db "Hallo!"
;		def <entryname> db "Bonjour!"
;	- all text must use the iso-8859-1 codepage or the UTF-8 extension
;	- then use it in the assembly code with ourtext(<entryname>)
;

; -----------------------------------
;	Language data
; -----------------------------------


; **************
;    American
; **************

newlanguage american,a,2,496543,1695744

def bribetext, db "Bribe the local authority",0

def bribedesc, db 94h,80h,13,90h,"  "
	db "Bribe the local authority to increase your rating, "
	db "at the risk of a severe penalty if caught."
	db 13,"  Cost: ",7fh,0

def bribefailed, db 94h,"Your attempted bribery has been discovered by a regional investigator.",0

def headingfor, db 95h,80h,", ",84h,0
def headingfordepot1, db 95h,80h," Train Depot, ", 84h,0
def headingfordepot2, db 95h,80h," Road Depot, ", 84h,0
def headingfordepot3, db 95h,80h," Ship Depot, ", 84h,0
def headingfordepot4, db 95h,80h," Hangar, ", 84h,0

def withsignals, db "Railroad track with ",80h," (",80h,")",0
def wplainsignals, db "plain signals",0
def wpresignals, db "pre-signals",0
def wpresigexits, db "pre-signal exits",0
def wprecombined, db "combined signals",0
def presigautomatic, db "automatic",0
def presigmanual, db "manual",0
def pathbasedauto, db "automatic, path-based",0
def pathbasedmanual, db "manual, path-based",0

def vehmulttoolow, db 94h,"Warning: Game saved with vehicle multiplier ",7eh,". "
		db " Removed ",7eh," vehicles in ",7eh," consists and ",7eh," special objects.",0

def rchunknotloaded, db 94h,"Warning: Game uses some features of TTDPatch "
		db "that are disabled or not present in this version. Data may be lost.",0

def loadgame, db "Load game",0

def gotodepot, db "Go to ",80h,0
def gotodepotonly, db "Service at ",80h,0
def gototraindepot, db 80h," Train Depot",0
def gotoroaddepot, db 80h," Road Depot",0
def gotoshipdepot, db 80h," Ship Depot",0
def gotoairdepot, db 80h," Hangar",0
def routethrough, db "Route through ",0x80,0
def routenonstopthrough, db "Route non-stop through ",0x80,0

def vehobsolete, db 94h,"Model is obsolete and ",80h,0

def cannotcheat, db 94h,"Cannot carry out sign cheat action",0
def cheatinvalidparm, db 94h,"Invalid parameter",0
def cheatunknown, db 94h,"Unknown sign cheat",0
def cheatobsolete1, db 94h,"Note: Cht: ",80h," is obsolete.",0
def cheatobsolete2, db 94h,"Use Cht: ",80h," instead.",0
def nostationhere, db 94h,"No station here",0

def managedby1, db " (temp. Player 1)",0
def managedby2, db " (temp. Player 2)",0

def manage, db 98h,"Manage",0

def engineinfo1,	db 98h,"Cost: ",8ah,7fh
		db 98h,"   Weight: ",8ah,7ch,"t",13
		db 98h,"Max. Tractive Effort: ",8ah,7ch,"kN",13
		db 98h,"Speed: ",8ah,84h
		db 98h,"   Power: ",8ah,7ch,"hp",0
def wagonpower,	db 98h,"Powered Wagons: ",8ah,"+",7ch,"hp"
		db 98h,"   Weight: ",8ah,"+",7dh,"t",0
def engineinfo2,	db 98h,"Running Cost: ",8ah,7fh,"/yr",13
		db 98h,"Capacity: ",8ah,80h," ",80h,13
		db 98h,"Designed: ",8ah,7eh
		db 98h,"   Life: ",8ah,7ch," years",13
		db 98h,"Max. Reliability: ",8ah,7dh,"%",0
def wagoninfo,	db 98h,"Cost: ",8ah,7fh,13
		db 98h,"Weight: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacity: ",8ah,80h," ",80h,0
def newwagoninfo, db 98h,"Cost: ",7fh,
	db "    Weight: ",7ch,"t",13
	db "Capacity: ",80h," ",80h,0
def wagonspeedlimit, db 98h,13,"Max. Speed: ",80h,84h,0
def refittableto, db 98h,"Refittable to: ",8ah,80h,0
def refittabletoallbut, db 98h,"Refittable to: ",8ah,"All but ",80h,0
def refittabletoall, db 98h,"Refittable to: ",8ah,"All cargo types",0

def railwaywagon, db "railroad wagon",0
def monorailwagon, db "monorail wagon",0
def maglevwagon, db "maglev wagon",0

def ufodestroyed, db 98h,0fh,"'UFO' destroyed in huge explosion near ",80h,"!",0

def rvweightinfo, db 98h,"Weight: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Power: ", 95h,7ch,"hp   "
	db 80h,0

def rvweightpurchasewindow, db 98h,"Cost: ", 8ah, 7fh
	db 98h,"   Speed: ", 8ah, 84h, 13
	db 98h,"Running Cost: ", 8ah, 7fh, "/yr", 13
	db 98h,"Power: ", 8ah, 7ch,"hp"
	db 98h,"   Weight: ", 8ah, 7dh,".",7dh,"t", 13
	db 98h,"Capacity: ", 8ah, 80h, 13
	db 98h,"Designed: ", 8ah, 7eh
	db 98h,"   Life: ", 8ah, 7ch, " years",13
	db 98h,"Max. Reliability: ", 8ah, 7dh, "%", 0

def grfloaderror, db 94h,"Error loading new graphics:",0
def toomanysprites, db 94h,"More sprites than specified (file ",80h,").",0
def outofmemory, db 94h,"Out of memory (file ",80h,").",0
def wronggrfversion, db 94h,"Wrong .grf version (file ",80h,").",0
def toomanyspritestotal, db 94h,"Cannot load more sprites (from file ",80h,").",0
def filenotfound, db 94h,"File ",22h,80h,22h," not found.",0
def invalidsprite, db 94h, "File ", 22h,80h,22h," has invalid sprite #",7ch," (code ",7ch,"/",7ch,").",0
def notttdpatchgrf, db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
def grferror, db 94h, "Error: ", 80h,0
def grfwarning, db 94h, "Warning: ", 80h,0
def grfneedspatchversion, db 94h, 80h, " requires at least TTDPatch version ", 80h, 0
def grfneedsdoswin, db 94h, 80h, " is for the ", 80h, " version of TTD.", 0
def grfwantsswitch, db 94h, 80h, " is designed to be used with ", 80h, 0
def grfinvalidparam, db 94h, "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
def grfconflict, db 94h,"GRF conflict with ", 80h,0x94, " (resource ", 0x7c, " at sprite ", 0x7c, ")", 0
def conflict_itself, db "itself", 0
def conflict_preexist, db "existing definitions", 0

def grfstatcaption, db 0x94,"GRF Status", 0
def grfstatapply, db 0x98,"Apply", 0
def grfstatreset, db 0x98,"Default", 0
def grfstatdebug, db 0x98,"Debug", 0
def grfinfotext, db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

def grflisthint, db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
def grfapplyhint, db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
def grfresethint, db 0x98,"Reset all graphics settings to the default and apply",0
def grfdebughint, db 0x98,"Creates a debug output of the current active grf status",0
def grfdebugmsg, db 0x94, "Graphics status information written to ",80h,": ",80h,0

def grfstatusmenu, db "New graphics status", 0
def initialgrfsettings, db 0x98, "Initial graphics settings", 0
def initialgrfsettingshint, db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

def grfstatgeninfo1, db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo2,	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo3,	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo4,	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
def grfstatmax, db " (",0x7b," max)",0

def elecrailconstitle, db 94h,"Electrified Railroad Construction",0
def elecrailconsmenu, db "Electr. railroad construction",0

def lmilloutoftrees, db 98h,0fh,80h," ",80h," ran out of nearby trees!",0

def eurointroduced, db 98h,0fh,"Monetary union!",0dh,0dh,"European countries switch from national currencies to Euro!",0

def curr_pound, db 0,0,0,0,0,0
def curr_dollar, db 0,0,0,0,0,0
def curr_franc, db 0,0,0,0,0,0
def curr_deutschmark, db 0,0,0,0,0,0
def curr_yen, db 0,0,0,0,0,0
def curr_peseta, db 0,0,0,0,0,0
def curr_HUF, db "Hungarian Forint (Ft)",0,0,0,0,0,0
def curr_PLN, db "Polish Zloty (zl)",0,0,0,0,0,0
def curr_ATS, db "Austrian Shilling (ATS)",0,0,0,0,0,0
def curr_BEF, db "Belgian Franc (BEF)",0,0,0,0,0,0
def curr_DKK, db "Danish Krone (DKK)",0,0,0,0,0,0
def curr_FIM, db "Finnish Markka (FIM)",0,0,0,0,0,0
def curr_GRD, db "Greek Drachma (GRD)",0,0,0,0,0,0
def curr_CHF, db "Swiss Franc (CHF)",0,0,0,0,0,0
def curr_NLG, db "Dutch Guilder (NLG)",0,0,0,0,0,0
def curr_ITL, db "Italian Lira (ITL)",0,0,0,0,0,0
def curr_SEK, db "Swedish Krona (SEK)",0,0,0,0,0,0
def curr_RUB, db "Russian Rubel (RUB)",0,0,0,0,0,0
def curr_EUR, db "Euro (",0x9E,")",0,0,0,0,0,0

def townlastmonthaccepted, db 98h,"Cargo accepted last month at all stations:",0

def aircraftcleared, db 98h,0fh,"Remnants of the recent plane crash have been cleared from ",80h,"!",0
def zeppelincleared, db 98h,0fh,"Remnants of the recent Zeppelin crash have been cleared from ",80h,"!",0
def traincleared, db 98h,0fh,"Remnants of the recent train crash have been cleared near ",80h,"!",0

def endofsharedorders, db 1,0xa,"- - End of shared orders (",85h,7ch,") - -",0

def resetorders, db 0x98,"Reset",0
def toggleservice, db 0x98,"Service",0
def resethint, db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
def servicehint, db 0x98,"Makes the vehicle skip this order unless it's time for service",0

def nosort, db "Unsorted",0
def sortconsistnum, db "Number",0
def sortprofit, db "Profit",0
def sortlastprofit, db "Last year profit",0
def sortage, db "Age",0
def sortmaxspeed, db "Max. Speed",0
def sortreliability, db "Reliability",0
def sortcargo, db "Cargo",0
def sortdestination, db "First destination",0
def sorthint, db "Select sorting method of vehicles in this list",0

def performance, db " (Perf. score: ",0x7e,")",0

def vehiclelost, db 0x94,0x80," ",0x7c," seems to be lost",0

def wrongrailtype, db 94h,"...incompatible rail types",0

def neterror1, db 0x94,"Network error!",0
def neterror2, db 0x94,"Games disconnected!",0

def desynch1, db 0x94,"Games out of sync!",0
def desynch2, db 0x94,"Use sv2flip or reload the last save!",0

def refitvehicle, db 0x98,"Refit vehicle",0
def refitcargohint, db 0x98,"Select type of cargo for vehicle to carry",0
def refitbuttonhint, db 0x98,"Refit vehicle to carry highlighted cargo type",0

def cantbuildcanalhere, db 0x94, "Can't build canals/locks here", 0

def fundprospecting, db 0x94, "Fund prospecting", 0
def buildindustry, db 0x94, "Build industry", 0
def fundingfailed, db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
def cannotfundprospecting, db 0x94, "Cannot fund prospecting", 0

def newtrainindepot, db 0
def newrvindepot, db 0
def newshipindepot, db 0
def newaircraftinhangar, db 0
def newvehold, db 0
def newvehveryold, db 0
def newvehveryveryold, db 0
def newvehiclelost, db 0
def newcantreverse, db 0

def txtetoolboxmenu, db "Enhanced GUI settings", 0
def txtetoolbox, db 0x94, "Enhanced GUI Settings", 0
def txtetoolbox_tsigns, db 0x98, "Station signs", 0
def txtetoolbox_tsignstrans, db "Transparent",0
def txtetoolbox_tsignsold, db "TTD Style",0

def txtetoolbox_dsize, db 0x98, "Depot Size",0
def txtetoolbox_d8, db "Depot  8  (4)",0
def txtetoolbox_d10, db "Depot 10  (5)",0
def txtetoolbox_d12, db "Depot 12  (6)",0
def txtetoolbox_d14, db "Depot 14  (7)",0
def txtetoolbox_d16, db "Depot 16  (8)",0
def txtetoolbox_d18, db "Depot 18  (9)",0
def txtetoolbox_d20, db "Depot 20  (10)",0

def txtetoolbox_depotalltrash, db 0x98, "Depot allTrash",0
def txtetoolbox_on, db "On",0
def txtetoolbox_off, db "Off",0
def txtetoolbox_saveinsavegame, db 0x98, "Stick Settings",0
def txtetoolbox_usedefaultinsave, db 0x98, "Unstick",0
def txtetoolbox_saveasdefault, db 0x98, "Save as Default",0
def txtetoolbox_resetdefaultsizes, db 0x98, "Reset default sizes",0

def none, db "None", 0
def low,  db "Low", 0
def normal, db "Normal", 0
def high, db "High", 0

def defaultstation, db "(default)",0
def stationnumdefault, db "Station ",0x81,0xff,0xC7,0
def stationclassdefault, db "Station class ",0x81,0xff,0xC7,0


def unnamedtownnamestyle, db "(Unnamed style)",0

def newshistory, db "Message history",0
def messagesettings, db "Message settings",0
def messages, db 0x94, "Messages",0

def cantreverse, db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

def grflanguage, db "0",0

def sizertooltip, db 0x98, "Drag to resize the window",0
def stickytooltip, db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0
	
def rcw_railway, db 0x94, "Railway", 0
def rcw_signaltype, db 0x98, "Signal type", 0
def rcw_semaphores, db "Semaphores", 0
def rcw_lights, db "Lights", 0
def rcw_automatic, db "Automatic", 0
def rcw_normal, db "Normal", 0
def rcw_entry, db "Entry", 0
def rcw_exit, db "Exit", 0
def rcw_combo, db "Combo", 0
def rcw_nopbs, db "Not path based", 0
def rcw_pbs, db "Path based", 0
def rcw_tracks, db 0x98, "Tracks: ", 0x8E, 0x80, 0
def rcw_length, db 0x98, "Length: ", 0x8E, 0x80, 0
def rcw_drag, db "Drag", 0
def rcw_class, db 0x98, "Class:", 0
def rcw_type, db 0x98, "Type:", 0
def rcw_accepts, db 0x98, "Accepts:          ", 0x8A, 0

def outofdynmem, db 0x94, "Out of dynamic memory", 0
def cantresize, db 0x94, "Can't resize window...", 0

def grftextnotfound, db "-- GRF text not found! --",0

def newindubuildindustry, db "Build industry",0
def newindufundprospecting, db "Fund prospecting for industry",0
def newinduproduces, db 0x98, "Produces: ", 0x90, 0x80, 0
def toomanyindustries, db 94h,"Too many industries on map.", 0

def newindulist_tooltip, db 0x98,"List of available industry types - click on the one you want to build",0
def newinduinfo_tooltip, db 0x98,"Information about the currently selected industry type",0
def newindubuild_tooltip, db 0x98,"Build the industry",0
def newinduprospect_tooltip, db 0x98,"Fund prospecting to find resources for this industry",0

def newindu_cargowaiting, db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

def warning_notowns, db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

def localplayer, db " (local player)",0
def remoteplayer, db " (remote player)",0

def multiplayer, db 0x98,"Multiplayer",0
def multiplayer_tooltip, db 0x98,"Select multiplayer game",0

def ttdpatch_dll_notfound, db 94h,"Cannot load ttdpatch.dll, new sounds disabled.", 0

def statistics, db 0x98, "Statistics",0
def statistics_white, db 0x94, "Statistics",0
def totalcargo, db 0x8E, "Total amount of cargo transported",0
def statistics_tooltip, db 0x98, "Open company statistics",0

def landareainfoheight, db 0x98,"Altitude: ",0x95,0x7B,0

def txteroadmenu, db "Tramway construction",0
def txtetramwindowheader, db 0x94,"Tramway Construction",0
def txtetramstationheader, db 0x94,"Tram Stop Orientation",0
def txtetramdepotheader, db 0x94,"Tram Depot Orientation",0
  
def shortdateformat, db 4, " ", 1, 0
def longdateformat, db 2, " ", 3, " ", 1, 0

def txtltwocc, db 0x94, "Company Color Scheme Window", 0
def txtltwoccglb, db 0x98, "Global Color Scheme", 0
def txtltwoccstm, db 0x98, "Steam Engine", 0
def txtltwoccdsl, db 0x98, "Diesel Engine", 0
def txtltwoccelc, db 0x98, "Electric Engine", 0
def txtltwoccmor, db 0x98, "Monorail Engine", 0
def txtltwoccmgv, db 0x98, "Maglev Engine", 0
def txtltwoccdmu, db 0x98, "Diesel Multiple Unit", 0
def txtltwoccemu, db 0x98, "Electric Multiple Unit", 0
def txtltwoccpaw, db 0x98, "Passenger Wagons", 0
def txtltwoccfrw, db 0x98, "Freight Wagons", 0
def txtltwoccbus, db 0x98, "Bus", 0
def txtltwocctrm, db 0x98, "Tram", 0
def txtltwocctrk, db 0x98, "Truck", 0
def txtltwoccpsh, db 0x98, "Passenger Ship", 0
def txtltwoccfsh, db 0x98, "Freight Ship", 0
def txtltwoccsap, db 0x98, "Regional Aircraft", 0
def txtltwocclap, db 0x98, "Express Aircraft", 0
def txtltwoccfrp, db 0x98, "Freight Aircraft", 0
def txtltwocchel, db 0x98, "Helicopter", 0
def txtltwocclr1, db 0x94, "Primary", 0
def txtltwocclr2, db 0x94, "Secondary", 0

def steepslopes, db "steep slopes aren't suited", 0
def landhigherbridgehead, db "land under bridge higher than bridgehead", 0

def grfhelpercaption, db 0x94,"GRF Author Helper",0
def grfhelper_displxrelyrel, db 0x94,"Sprite: ",0x7E," xrel: ",0x7C," yrel: ",0x7C,0
def textsprite, db 0x98,"Sprite",0

def airporttype, db 0x98, "Airport Type",0
def unnamedairporttype, db "(Unnamed type)",0

def hotkeylistdos, db "xqwe!@#$t%1234567890-=",1eh,5ch,0
def hotkeylistwin, db "xqwe!@#$t%1234567890-=`",5ch,0

def txtclonedepotbutton, db 0x98, "Clone Train", 0
def txtclonetooltip, db 0x98, "Allows you to clone a train", 0
def txtcloneerrortop, db 0x94, "Cannot clone train consist", 0
def txtcloneerror1, db 0x94, "Not a company train", 0
def txtcloneerror2, db 0x94, "Vehicle in consist is not available anymore", 0
def txtcloneerror3, db 0x94, "No engine head at the start of the consist", 0
def txtcloneerror4, db 0x94, "Not a rail vehicle", 0
def txtcloneerror5, db 0x94, "Unknown reason", 0


def last

secondlanguage

; **************
;    English
; **************

newlanguage english,e,2,496601,1696256
; for the most part same as american...

def bribetext, db "Bribe the local authority",0

def bribedesc, db 94h,80h,13,90h,"  "
	db "Bribe the local authority to increase your rating, "
	db "at the risk of a severe penalty if caught."
	db 13,"  Cost: ",7fh,0

def bribefailed, db 94h,"Your attempted bribery has been discovered by a regional investigator.",0

def headingfor, db 95h,80h,", ",84h,0
def headingfordepot1, db 95h,80h," Train Depot, ", 84h,0
def headingfordepot2, db 95h,80h," Road Depot, ", 84h,0
def headingfordepot3, db 95h,80h," Ship Depot, ", 84h,0
def headingfordepot4, db 95h,80h," Hangar, ", 84h,0

def withsignals, db "Railway track with ",80h," (",80h,")",0
def wplainsignals, db "plain signals",0
def wpresignals, db "pre-signals",0
def wpresigexits, db "pre-signal exits",0
def wprecombined, db "combined signals",0
def presigautomatic, db "automatic",0
def presigmanual, db "manual",0
def pathbasedauto, db "automatic, path-based",0
def pathbasedmanual, db "manual, path-based",0

def vehmulttoolow, db 94h,"Warning: Game saved with vehicle multiplier ",7eh,". "
		db " Removed ",7eh," vehicles in ",7eh," consists and ",7eh," special objects.",0

def rchunknotloaded, db 94h,"Warning: Game uses some features of TTDPatch "
		db "that are disabled or not present in this version. Data may be lost.",0

def loadgame, db "Load game",0

def gotodepot, db "Go to ",80h,0
def gotodepotonly, db "Service at ",80h,0
def gototraindepot, db 80h," Train Depot",0
def gotoroaddepot, db 80h," Road Depot",0
def gotoshipdepot, db 80h," Ship Depot",0
def gotoairdepot, db 80h," Hangar",0
def routethrough, db "Route through ",0x80,0
def routenonstopthrough, db "Route non-stop through ",0x80,0

def vehobsolete, db 94h,"Model is obsolete and ",80h,0

def cannotcheat, db 94h,"Cannot carry out sign cheat action",0
def cheatinvalidparm, db 94h,"Invalid parameter",0
def cheatunknown, db 94h,"Unknown sign cheat",0
def cheatobsolete1, db 94h,"Note: Cht: ",80h," is obsolete.",0
def cheatobsolete2, db 94h,"Use Cht: ",80h," instead.",0
def nostationhere, db 94h,"No station here",0

def managedby1, db " (temp. Player 1)",0
def managedby2, db " (temp. Player 2)",0

def manage, db 98h,"Manage",0

def engineinfo1,	db 98h,"Cost: ",8ah,7fh
		db 98h,"   Weight: ",8ah,7ch,"t",13
		db 98h,"Max. Tractive Effort: ",8ah,7ch,"kN",13
		db 98h,"Speed: ",8ah,84h
		db 98h,"   Power: ",8ah,7ch,"hp",0
def wagonpower,	db 98h,"Powered Wagons: ",8ah,"+",7ch,"hp"
		db 98h,"   Weight: ",8ah,"+",7dh,"t",0
def engineinfo2,	db 98h,"Running Cost: ",8ah,7fh,"/yr",13
		db 98h,"Capacity: ",8ah,80h," ",80h,13
		db 98h,"Designed: ",8ah,7eh
		db 98h,"   Life: ",8ah,7ch," years",13
		db 98h,"Max. Reliability: ",8ah,7dh,"%",0
def wagoninfo,	db 98h,"Cost: ",8ah,7fh,13
		db 98h,"Weight: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacity: ",8ah,80h," ",80h,0
def newwagoninfo, db 98h,"Cost: ",7fh,
	db "    Weight: ",7ch,"t",13
	db "Capacity: ",80h," ",80h,0
def wagonspeedlimit, db 98h,13,"Max. Speed: ",80h,84h,0
def refittableto, db 98h,"Refittable to: ",8ah,80h,0
def refittabletoallbut, db 98h,"Refittable to: ",8ah,"All but ",80h,0
def refittabletoall, db 98h,"Refittable to: ",8ah,"All cargo types",0

def railwaywagon, db "railway wagon",0
def monorailwagon, db "monorail wagon",0
def maglevwagon, db "maglev wagon",0

def ufodestroyed, db 98h,0fh,"'UFO' destroyed in huge explosion near ",80h,"!",0

def rvweightinfo, db 98h,"Weight: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Power: ", 95h,7ch,"hp   "
	db 80h,0

def rvweightpurchasewindow, db 98h,"Cost: ", 8ah, 7fh
	db 98h,"   Speed: ", 8ah, 84h, 13
	db 98h,"Running Cost: ", 8ah, 7fh, "/yr", 13
	db 98h,"Power: ", 8ah, 7ch,"hp"
	db 98h,"   Weight: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Capacity: ", 8ah, 80h, 13
	db 98h,"Designed: ", 8ah, 7eh
	db 98h,"   Life: ", 8ah, 7ch, " years",13
	db 98h,"Max. Reliability: ", 8ah, 7dh, "%", 0

def grfloaderror, db 94h,"Error loading new graphics:",0
def toomanysprites, db 94h,"More sprites than specified (file ",80h,").",0
def outofmemory, db 94h,"Out of memory (file ",80h,").",0
def wronggrfversion, db 94h,"Wrong .grf version (file ",80h,").",0
def toomanyspritestotal, db 94h,"Cannot load more sprites (from file ",80h,").",0
def filenotfound, db 94h,"File ",22h,80h,22h," not found.",0
def invalidsprite, db 94h, "File ", 22h,80h,22h," has invalid sprite #",7ch," (code ",7ch,"/",7ch,").",0
def notttdpatchgrf, db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
def grferror, db 94h, "Error: ", 80h,0
def grfwarning, db 94h, "Warning: ", 80h,0
def grfneedspatchversion, db 94h, 80h, " requires at least TTDPatch version ", 80h, 0
def grfneedsdoswin, db 94h, 80h, " is for the ", 80h, " version of TTD.", 0
def grfwantsswitch, db 94h, 80h, " is designed to be used with ", 80h, 0
def grfinvalidparam, db 94h, "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
def grfconflict, db 94h,"GRF conflict with ", 80h,0x94, " (resource ", 0x7c, " at sprite ", 0x7c, ")", 0
def conflict_itself, db "itself", 0
def conflict_preexist, db "existing definitions", 0

def grfstatcaption, db 0x94,"GRF Status", 0
def grfstatapply, db 0x98,"Apply", 0
def grfstatreset, db 0x98,"Default", 0
def grfstatdebug, db 0x98,"Debug", 0
def grfinfotext, db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

def grflisthint, db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
def grfapplyhint, db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
def grfresethint, db 0x98,"Reset all graphics settings to the default and apply",0
def grfdebughint, db 0x98,"Creates a debug output of the current active grf status",0
def grfdebugmsg, db 0x94, "Graphics status information written to ",80h,": ",80h,0

def grfstatusmenu, db "New graphics status", 0
def initialgrfsettings, db 0x98, "Initial graphics settings", 0
def initialgrfsettingshint, db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

def grfstatgeninfo1, db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo2,	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo3,	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo4,	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
def grfstatmax, db " (",0x7b," max)",0

def elecrailconstitle, db 94h,"Electrified Railway Construction",0
def elecrailconsmenu, db "Electr. railway construction",0

def lmilloutoftrees, db 98h,0fh,80h," ",80h," ran out of nearby trees!",0

def eurointroduced, db 98h,0fh,"Monetary union!",0dh,0dh,"European countries switch from national currencies to Euro!",0

def curr_pound, db 0,0,0,0,0,0
def curr_dollar, db 0,0,0,0,0,0
def curr_franc, db 0,0,0,0,0,0
def curr_deutschmark, db 0,0,0,0,0,0
def curr_yen, db 0,0,0,0,0,0
def curr_peseta, db 0,0,0,0,0,0
def curr_HUF, db "Hungarian Forint (Ft)",0,0,0,0,0,0
def curr_PLN, db "Polish Zloty (zl)",0,0,0,0,0,0
def curr_ATS, db "Austrian Shilling (ATS)",0,0,0,0,0,0
def curr_BEF, db "Belgian Franc (BEF)",0,0,0,0,0,0
def curr_DKK, db "Danish Krone (DKK)",0,0,0,0,0,0
def curr_FIM, db "Finnish Markka (FIM)",0,0,0,0,0,0
def curr_GRD, db "Greek Drachma (GRD)",0,0,0,0,0,0
def curr_CHF, db "Swiss Franc (CHF)",0,0,0,0,0,0
def curr_NLG, db "Dutch Guilder (NLG)",0,0,0,0,0,0
def curr_ITL, db "Italian Lira (ITL)",0,0,0,0,0,0
def curr_SEK, db "Swedish Krona (SEK)",0,0,0,0,0,0
def curr_RUB, db "Russian Rubel (RUB)",0,0,0,0,0,0
def curr_EUR, db "Euro (",0x9E,")",0,0,0,0,0,0

def townlastmonthaccepted, db 98h,"Cargo accepted last month at all stations:",0

def aircraftcleared, db 98h,0fh,"Remnants of the recent plane crash have been cleared from ",80h,"!",0
def zeppelincleared, db 98h,0fh,"Remnants of the recent Zeppelin crash have been cleared from ",80h,"!",0
def traincleared, db 98h,0fh,"Remnants of the recent train crash have been cleared near ",80h,"!",0

def endofsharedorders, db 1,0xa,"- - End of shared orders (",85h,7ch,") - -",0

def resetorders, db 0x98,"Reset",0
def toggleservice, db 0x98,"Service",0
def resethint, db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
def servicehint, db 0x98,"Makes the vehicle skip this order unless it's time for service",0

def nosort, db "Unsorted",0
def sortconsistnum, db "Number",0
def sortprofit, db "Profit",0
def sortlastprofit, db "Last year profit",0
def sortage, db "Age",0
def sortmaxspeed, db "Max. Speed",0
def sortreliability, db "Reliability",0
def sortcargo, db "Cargo",0
def sortdestination, db "First destination",0
def sorthint, db 0x98,"Select sorting method of vehicles in this list",0

def performance, db " (Perf. score: ",0x7e,")",0

def vehiclelost, db 0x94,0x80," ",0x7c," seems to be lost",0

def wrongrailtype, db 94h,"...incompatible rail types",0

def neterror1, db 0x94,"Network error!",0
def neterror2, db 0x94,"Games disconnected!",0

def desynch1, db 0x94,"Games out of sync!",0
def desynch2, db 0x94,"Use sv2flip or reload the last save!",0

def refitvehicle, db 0x98,"Refit vehicle",0
def refitcargohint, db 0x98,"Select type of cargo for vehicle to carry",0
def refitbuttonhint, db 0x98,"Refit vehicle to carry highlighted cargo type",0

def cantbuildcanalhere, db 0x94, "Can't build canals/locks here", 0

def fundprospecting, db 0x94, "Fund prospecting", 0
def buildindustry, db 0x94, "Build industry", 0
def fundingfailed, db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
def cannotfundprospecting, db 0x94, "Cannot fund prospecting", 0

def newtrainindepot, db 0
def newrvindepot, db 0
def newshipindepot, db 0
def newaircraftinhangar, db 0
def newvehold, db 0
def newvehveryold, db 0
def newvehveryveryold, db 0
def newvehiclelost, db 0
def newcantreverse, db 0

def txtetoolboxmenu, db "Enhanced GUI settings", 0
def txtetoolbox, db 0x94, "Enhanced GUI Settings", 0
def txtetoolbox_tsigns, db 0x98, "Station signs", 0
def txtetoolbox_tsignstrans, db "Transparent",0
def txtetoolbox_tsignsold, db "TTD Style",0

def txtetoolbox_dsize, db 0x98, "Depot Size",0
def txtetoolbox_d8, db "Depot  8  (4)",0
def txtetoolbox_d10, db "Depot 10  (5)",0
def txtetoolbox_d12, db "Depot 12  (6)",0
def txtetoolbox_d14, db "Depot 14  (7)",0
def txtetoolbox_d16, db "Depot 16  (8)",0
def txtetoolbox_d18, db "Depot 18  (9)",0
def txtetoolbox_d20, db "Depot 20  (10)",0

def txtetoolbox_depotalltrash, db 0x98, "Depot allTrash",0
def txtetoolbox_on, db "On",0
def txtetoolbox_off, db "Off",0
def txtetoolbox_saveinsavegame, db 0x98, "Stick Settings",0
def txtetoolbox_usedefaultinsave, db 0x98, "Unstick",0
def txtetoolbox_saveasdefault, db 0x98, "Save as Default",0
def txtetoolbox_resetdefaultsizes, db 0x98, "Reset default sizes",0

def none, db "None", 0
def low,  db "Low", 0
def normal, db "Normal", 0
def high, db "High", 0

def defaultstation, db "(default)",0
def stationnumdefault, db "Station ",0x81,0xff,0xC7,0
def stationclassdefault, db "Station class ",0x81,0xff,0xC7,0

def unnamedtownnamestyle, db "(Unnamed style)",0

def newshistory, db "Message history",0
def messagesettings, db "Message settings",0
def messages, db 0x94, "Messages",0
	
def cantreverse, db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

def grflanguage, db "0",0

def sizertooltip, db 0x98, "Drag to resize the window",0
def stickytooltip, db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0

def rcw_railway, db 0x94, "Railway", 0
def rcw_signaltype, db 0x98, "Signal type", 0
def rcw_semaphores, db "Semaphores", 0
def rcw_lights, db "Lights", 0
def rcw_automatic, db "Automatic", 0
def rcw_normal, db "Normal", 0
def rcw_entry, db "Entry", 0
def rcw_exit, db "Exit", 0
def rcw_combo, db "Combo", 0
def rcw_nopbs, db "Not path based", 0
def rcw_pbs, db "Path based", 0
def rcw_tracks, db 0x98, "Tracks: ", 0x8E, 0x80, 0
def rcw_length, db 0x98, "Length: ", 0x8E, 0x80, 0
def rcw_drag, db "Drag", 0
def rcw_class, db 0x98, "Class:", 0
def rcw_type, db 0x98, "Type:", 0
def rcw_accepts, db 0x98, "Accepts:                    ", 0x8A, 0

def outofdynmem, db 0x94, "Out of dynamic memory", 0
def cantresize, db 0x94, "Can't resize window...", 0

def grftextnotfound, db "-- GRF text not found! --",0

def newindubuildindustry, db "Build industry",0
def newindufundprospecting, db "Fund prospecting for industry",0
def newinduproduces, db 0x98, "Produces: ", 0x90, 0x80, 0
def toomanyindustries, db 94h,"Too many industries on map.", 0

def newindulist_tooltip, db 0x98,"List of available industry types - click on the one you want to build",0
def newinduinfo_tooltip, db 0x98,"Information about the currently selected industry type",0
def newindubuild_tooltip, db 0x98,"Build the industry",0
def newinduprospect_tooltip, db 0x98,"Fund prospecting to find resources for this industry",0

def newindu_cargowaiting, db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

def warning_notowns, db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

def localplayer, db " (local player)",0
def remoteplayer, db " (remote player)",0

def multiplayer, db 0x98,"Multiplayer",0
def multiplayer_tooltip, db 0x98,"Select multiplayer game",0

def ttdpatch_dll_notfound, db 94h,"Cannot load ttdpatch.dll, new sounds disabled.", 0

def statistics, db 0x98, "Statistics",0
def statistics_white, db 0x94, "Statistics",0
def totalcargo, db 0x8E, "Total amount of cargo transported",0
def statistics_tooltip, db 0x98, "Open company statistics",0

def landareainfoheight, db 0x98,"Altitude: ",0x95,0x7B,0

def txteroadmenu, db "Tramway construction",0
def txtetramwindowheader, db 0x94,"Tramway Construction",0
def txtetramstationheader, db 0x94,"Tram Stop Orientation",0
def txtetramdepotheader, db 0x94,"Tram Depot Orientation",0
  
def shortdateformat, db 4, " ", 1, 0
def longdateformat, db 2, " ", 3, " ", 1, 0

def txtltwocc, db 0x94, "Company Color Scheme Window", 0
def txtltwoccglb, db 0x98, "Global Color Scheme", 0
def txtltwoccstm, db 0x98, "Steam Engine", 0
def txtltwoccdsl, db 0x98, "Diesel Engine", 0
def txtltwoccelc, db 0x98, "Electric Engine", 0
def txtltwoccmor, db 0x98, "Monorail Engine", 0
def txtltwoccmgv, db 0x98, "Maglev Engine", 0
def txtltwoccdmu, db 0x98, "Diesel Multiple Unit", 0
def txtltwoccemu, db 0x98, "Electric Multiple Unit", 0
def txtltwoccpaw, db 0x98, "Passenger Wagons", 0
def txtltwoccfrw, db 0x98, "Freight Wagons", 0
def txtltwoccbus, db 0x98, "Bus", 0
def txtltwocctrm, db 0x98, "Tram", 0
def txtltwocctrk, db 0x98, "Truck", 0
def txtltwoccpsh, db 0x98, "Passenger Ship", 0
def txtltwoccfsh, db 0x98, "Freight Ship", 0
def txtltwoccsap, db 0x98, "Regional Aircraft", 0
def txtltwocclap, db 0x98, "Express Aircraft", 0
def txtltwoccfrp, db 0x98, "Freight Aircraft", 0
def txtltwocchel, db 0x98, "Helicopter", 0
def txtltwocclr1, db 0x94, "Primary", 0
def txtltwocclr2, db 0x94, "Secondary", 0

def steepslopes, db "steep slopes aren't suited", 0
def landhigherbridgehead, db "land under bridge higher than bridgehead", 0

def grfhelpercaption, db 0x94,"GRF Author Helper",0
def grfhelper_displxrelyrel, db 0x94,"Sprite: ",0x7E," xrel: ",0x7C," yrel: ",0x7C,0
def textsprite, db 0x98,"Sprite",0

def airporttype, db 0x98, "Airport Type",0
def unnamedairporttype, db "(Unnamed type)",0

def hotkeylistdos, db "xqwe!",22h,0xa3,"$t%1234567890-=",1eh,5ch,0
def hotkeylistwin, db "xqwe!",22h,0xa3,"$t%1234567890-=~",5ch,0

def txtclonedepotbutton, db 0x98, "Clone Train", 0
def txtclonetooltip, db 0x98, "Allows you to clone a train", 0
def txtcloneerrortop, db 0x94, "Cannot clone train consist", 0
def txtcloneerror1, db 0x94, "Not a company train", 0
def txtcloneerror2, db 0x94, "Vehicle in consist is not available anymore", 0
def txtcloneerror3, db 0x94, "No engine head at the start of the consist", 0
def txtcloneerror4, db 0x94, "Not a rail vehicle", 0
def txtcloneerror5, db 0x94, "Unknown reason", 0

def last


; **************
;     German
; **************

newlanguage german,g,2,499583,1699328

def bribetext, db "Stadtverwaltung bestechen",0

def bribedesc, db 94h,80h,13,90h
	db "Bestechen Sie die Stadtverwaltung für eine bessere "
	db "Bewertung, mit dem Risiko einer schweren Strafe falls "
	db "Sie erwischt werden."
	db 13,"  Kosten: ",7fh,0

def bribefailed, db 94h,"Ihr Bestechungsversuch wurde durch eine staatliche Untersuchung aufgedeckt.",0

def headingfor, db 95h,80h,", ",84h,0
def headingfordepot1, db 95h,80h,"-Zugdepot, ", 84h,0
def headingfordepot2, db 95h,80h," Fahrzeugdepot, ", 84h,0
def headingfordepot3, db 95h,80h," Schiffswerft, ", 84h,0
def headingfordepot4, db 95h,80h," Halle, ", 84h,0

def withsignals, db "Gleise mit ",80h," (",80h,")",0
def wplainsignals, db "normalen Signalen",0
def wpresignals, db "Vorsignalen",0
def wpresigexits, db "Vorsignalausfahrten",0
def wprecombined, db "kombinierten Signalen",0
def presigautomatic, db "automatisch",0
def presigmanual, db "manuell",0
def pathbasedauto, db "automatisch, weg-basiert",0
def pathbasedmanual, db "manuell, weg-basiert",0

def vehmulttoolow, db 94h,"Warnung: Spielstand wurde mit Fahrzeuganzahl-Faktor ",7eh," gespeichert. "
		db " ",7eh," Fahrzeuge in ",7eh," Einheiten und ",7eh," spezielle Objekte wurden entfernt.",0

def rchunknotloaded, db 94h,"Warnung: Spielstand benötigt TTDPatch Features, die momentan "
		db "deaktiviert oder nicht verfügbar sind. Dies kann zu Datenverlust führen.",0

def loadgame, db "Spiel laden",0

def gotodepot, db "Nach ",80h,0
def gotodepotonly, db "Wartung in ",80h,0
def gototraindepot, db 80h," Zugdepot",0
def gotoroaddepot, db 80h," Strassendepot",0
def gotoshipdepot, db 80h," Schiffswerft",0
def gotoairdepot, db 80h," Flugzeughalle",0
def routethrough, db "Passiere ",0x80,0
def routenonstopthrough, db "Passiere ohne Zwischenhalt ",0x80,0

def vehobsolete, db 94h,"Baureihe ist veraltet und ",80h,0

def cannotcheat, db 94h,"Kann Schilder-Cheat nicht ausführen",0
def cheatinvalidparm, db 94h,"Ungültiger Parameter",0
def cheatunknown, db 94h,"Unbekannter Schilder-Cheat",0
def cheatobsolete1, db 94h,"Achtung: Cht: ",80h," ist veraltet.",0
def cheatobsolete2, db 94h,"Benutzen Sie stattdessen Cht: ",80h,".",0
def nostationhere, db 94h,"Kein Bahnhof hier",0

def managedby1, db " (Spieler 1 temp.)",0
def managedby2, db " (Spieler 2 temp.)",0

def manage, db 98h,"Verwalten",0

def engineinfo1,	db 98h,"Kosten: ",8ah,7fh
		db 98h,"   Gewicht: ",8ah,7ch,"t",13
		db 98h,"Max. Zugkraft: ",8ah,7ch,"kN",13
		db 98h,"Geschwindigkeit: ",8ah,84h
		db 98h,"   Leistung: ",8ah,7ch,"PS",0
def wagonpower,	db 98h,"Waggons mit Antrieb: ",8ah,"+",7ch,"PS"
		db 98h,"   Gewicht: ",8ah,"+",7dh,"t",0
def engineinfo2,	db 98h,"Betriebskosten: ",8ah,7fh,"/Jahr",13
		db 98h,"Kapazität: ",8ah,80h," ",80h,13
		db 98h,"Entwurf: ",8ah,7eh
		db 98h,"   Zeit: ",8ah,7ch," Jahre",13
		db 98h,"Max. Zuverlässigkeit: ",8ah,7dh,"%",0
def wagoninfo,	db 98h,"Kosten: ",8ah,7fh,13
		db 98h,"Gewicht: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Kapazität: ",8ah,80h," ",80h,0
def newwagoninfo, db 98h,"Kosten: ",7fh,
	db "    Gewicht: ",7ch,"t",13
	db "Kapazität: ",80h," ",80h,0
def wagonspeedlimit, db 98h,13,"Max. Geschwindigkeit: ",80h,84h,0
def refittableto, db 98h,"Umrüstbar auf: ",8ah,80h,0
def refittabletoallbut, db 98h,"Umrüstbar auf: ",8ah,"Alle außer ",80h,0
def refittabletoall, db 98h,"Umrüstbar auf: ",8ah,"Alle Frachtarten",0

def railwaywagon, db "Waggon",0
def monorailwagon, db "Einschienenbahnwaggon",0
def maglevwagon, db "Schwebebahnwaggon",0

def ufodestroyed, db 98h,0fh,"'UFO' zerstört in großer Explosion bei ",80h,"!",0

def rvweightinfo, db 98h,"Gewicht: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Leistung: ", 95h,7ch,"PS   "
	db 80h,0

def rvweightpurchasewindow, db 98h,"Kosten: ", 8ah, 7fh
	db 98h,"   Geschwindigkeit: ", 8ah, 84h, 13
	db 98h,"Betriebskosten: ", 8ah, 7fh, "/Jahr", 13
	db 98h,"Leistung: ", 8ah, 7ch,"PS"
	db 98h,"   Gewicht: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Kapazität: ", 8ah, 80h, 13
	db 98h,"Entwurf: ", 8ah, 7eh
	db 98h,"   Zeit: ", 8ah, 7ch, " Jahre",13
	db 98h,"Max. Zuverlässigkeit: ", 8ah, 7dh, "%", 0

def grfloaderror, db 94h,"Fehler beim Laden der Grafiken:",0
def toomanysprites, db 94h,"Mehr Einträge als angegeben (Datei ",80h,").",0
def outofmemory, db 94h,"Zu wenig Speicher (Datei ",80h,").",0
def wronggrfversion, db 94h,"Falsche .grf Version (Datei ",80h,").",0
def toomanyspritestotal, db 94h,"Kann nicht mehr Sprites laden (ab Datei ",80h,").",0
def filenotfound, db 94h,"Datei ",80h," nicht gefunden.",0
def invalidsprite, db 94h, "Datei ", 22h,80h,22h," hat ungültiges Sprite #",7ch," (code ",7ch,"/",7ch,").",0
def notttdpatchgrf, db 94h, "Datei ",22h,80h,22h," ist keine TTDPatch Grafikdatei.",0
def grferror, db 94h, "Fehler: ", 80h,0
def grfwarning, db 94h, "Warnung: ", 80h,0
def grfneedspatchversion, db 94h, 80h, " benötigt mindestens TTDPatch Version ", 80h, 0
def grfneedsdoswin, db 94h, 80h, " ist für die ", 80h, " Version von TTD.", 0
def grfwantsswitch, db 94h, 80h, " wurde entwickelt für die Einstellung ", 80h, 0
def grfinvalidparam, db 94h, "Ungültiger Parameter für ", 80h, ": Parameter ", 80h, " (", 7Bh, ")", 0
def grfconflict, db 94h,"GRF-Konflikt mit ", 80h,0x94, " (Ressource ", 0x7c, " in Sprite ", 0x7c, ")", 0
def conflict_itself, db "sich selbst", 0
def conflict_preexist, db "gespeicherten Einstellungen", 0

def grfstatcaption, db 0x94,"GRF Status", 0
def grfstatapply, db 0x98,"Anwenden", 0
def grfstatreset, db 0x98,"Standard", 0
def grfstatdebug, db 0x98,"Debug", 0
def grfinfotext, db 0x95,0x80,13,0x94,"Datei: ",0x95,0x80,13,0x80,0x94,0x80,0

def grflisthint, db 0x98,"Klicken Sie auf den Namen, um weitere Informationen "
	db "für diese Datei anzuzeigen.  Klicken Sie auf die rote/grüne Fahne "
	db "um die Datei zu (de)aktivieren.",0
def grfapplyhint, db 0x98,"Neue Einstellungen in aktuellem Spielstand aktivieren",0
def grfresethint, db 0x98,"Alle Einstellungen zum Standard zurücksetzen und aktivieren",0
def grfdebughint, db 0x98,"Erzeugt eine Debug-Datei des gesamten GRF Status",0 
def grfdebugmsg, db 0x94, "Grafik-Statusinformationen geschrieben nach ",80h,": ",80h,0

def grfstatusmenu, db "Status neuer Grafiken", 0
def initialgrfsettings, db 0x98, "Anfängliche Grafikeinstellungen", 0
def initialgrfsettingshint, db 0x98, "Öffnet das GRF Status Fenster zur Wahl der ",
	db "anfangs aktiven Grafiksätze",0

def grfstatgeninfo1, db 0x98,"Anzahl der Dateien: ",0x94,0x7b,13
	db 0x98,"Verwendeter Speicher: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Gesamtzahl der Sprites: ",0x94,0x7b,13
	db 0x98,"Aktive Sprites: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo2,	db 0x98,"    Züge: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Straßenfahrzeuge: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo3,	db 0x98,"    Schiffe: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Flugzeuge: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo4,	db 0x98,"    Häuser: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Andere: ",0x94,0x7b,0x98,0x80,0
def grfstatmax, db " (",0x7b," max)",0


def elecrailconstitle, db 94h,"Gleisbau mit Oberleitung",0
def elecrailconsmenu, db "Eisenbahnbau mit Oberleitung",0

def lmilloutoftrees, db 98h,0fh,80h," ",80h," stellt Produktion ein mangels Bäumen!",0

def eurointroduced, db 98h,0fh,"Währungsunion!",0dh,0dh,"Landeswährungen durch Euro ersetzt!",0

def curr_pound, db 0,0,0,0,0,0
def curr_dollar, db 0,0,0,0,0,0
def curr_franc, db 0,0,0,0,0,0
def curr_deutschmark, db 0,0,0,0,0,0
def curr_yen, db 0,0,0,0,0,0
def curr_peseta, db 0,0,0,0,0,0
def curr_HUF, db "Ungarische Forint (Ft)",0,0,0,0,0,0
def curr_PLN, db "Polnische Zloty (zl)",0,0,0,0,0,0
def curr_ATS, db "Österreichische Schilling (ATS)",0,0,0,0,0,0
def curr_BEF, db "Belgische Franken (BEF)",0,0,0,0,0,0
def curr_DKK, db "Dänische Kronen (DKK)",0,0,0,0,0,0
def curr_FIM, db "Finnische Mark (FIM)",0,0,0,0,0,0
def curr_GRD, db "Griechische Drachmen (GRD)",0,0,0,0,0,0
def curr_CHF, db "Schweizer Franken (CHF)",0,0,0,0,0,0
def curr_NLG, db "Niederländische Gulden (NLG)",0,0,0,0,0,0
def curr_ITL, db "Italienische Lira (ITL)",0,0,0,0,0,0
def curr_SEK, db "Schwedische Kronen (SEK)",0,0,0,0,0,0
def curr_RUB, db "Russische Rubel (RUB)",0,0,0,0,0,0
def curr_EUR, db "Euro (",0x9E,")",0,0,0,0,0,0

def townlastmonthaccepted, db 98h,"Angelieferte Fracht im letzten Monat:",0

def aircraftcleared, db 98h,0fh,"Die Trümmer des Flugzeugabsturzes bei ",80h," sind nun geräumt worden.",0
def zeppelincleared, db 98h,0fh,"Die Trümmer des Zeppelinabsturzes bei ",80h," sind nun geräumt worden.",0
def traincleared, db 98h,0fh,"Die Trümmer des Zugzusammensstosses bei ",80h," sind nun geräumt worden.",0

def endofsharedorders, db 1,0xa,"- - Ende der gemeinsamen Aufträge (",85h,7ch,") - -",0

def resetorders, db 0x98,"Zurücksetzen",0
def toggleservice, db 0x98,"Wartung",0
def resethint, db 0x98,"Entfernt alle Aufträge von der Liste (nur aktuelles Fahrzeug bei gemeinsamen Aufträgen)",0
def servicehint, db 0x98,"Dieser Auftrag wird übersprungen wenn noch keine Wartung fällig ist",0

def nosort, db "Unsortiert",0
def sortconsistnum, db "Nummer",0
def sortprofit, db "Profit",0
def sortlastprofit, db "Profit letztes Jahr",0
def sortage, db "Alter",0
def sortmaxspeed, db "Geschwindigkeit",0
def sortreliability, db "Zuverlässigkeit",0
def sortcargo, db "Fracht",0
def sortdestination, db "Erster Auftrag",0
def sorthint, db 0x98,"Wahl des Sortier-Kriteriums für diese Liste",0

def performance, db " (Leistungsindex: ",0x7e,")",0

def vehiclelost, db 0x94,0x80," ",0x7c," scheint sich verfahren zu haben",0

def wrongrailtype, db 94h,"...inkompatible Schienenart",0

def neterror1, db 0x94,"Netzwerkfehler!",0
def neterror2, db 0x94,"Spieleverbindung getrennt!",0

def desynch1, db 0x94,"Spieleynchronisation verloren!",0
def desynch2, db 0x94,"Verwenden Sie sv2flip oder laden Sie einen älteren Spielstand!",0

def refitvehicle, db 0x98,"Fahrzeug umrüsten",0
def refitcargohint, db 0x98,"Wählen Sie die Fracht, die das Fahrzeug transportieren soll",0
def refitbuttonhint, db 0x98,"Fahrzeug auf gewählte Frachtart umrüsten",0

def cantbuildcanalhere, db 0x94, "Kann hier keinen Kanal/Schleusen bauen", 0

def fundprospecting, db 0x94, "Rohstofferkundung finanzieren", 0
def buildindustry, db 0x94, "Industry bauen", 0
def fundingfailed, db 0x94, "Die Erkundung ist fehlgeschlagen, keine neuen Rohstoffe konnten entdeckt werden.", 0
def cannotfundprospecting, db 0x94, "Kann Erkundung nicht finanzieren", 0

def newtrainindepot, db 0
def newrvindepot, db 0
def newshipindepot, db 0
def newaircraftinhangar, db 0
def newvehold, db 0
def newvehveryold, db 0
def newvehveryveryold, db 0
def newvehiclelost, db 0
def newcantreverse, db 0

def txtetoolboxmenu, db "GUI Einstellungen", 0
def txtetoolbox, db 0x94, "GUI Einstellungen", 0
def txtetoolbox_tsigns, db 0x98, "Bahnhofsschilder", 0
def txtetoolbox_tsignstrans, db "Transparent",0
def txtetoolbox_tsignsold, db "Normal",0

def txtetoolbox_dsize, db 0x98, "Depotgröße",0
def txtetoolbox_d8, db "Depot  8  (4)",0
def txtetoolbox_d10, db "Depot 10  (5)",0
def txtetoolbox_d12, db "Depot 12  (6)",0
def txtetoolbox_d14, db "Depot 14  (7)",0
def txtetoolbox_d16, db "Depot 16  (8)",0
def txtetoolbox_d18, db "Depot 18  (9)",0
def txtetoolbox_d20, db "Depot 20  (10)",0

def txtetoolbox_depotalltrash, db 0x98, "Depot allTrash",0
def txtetoolbox_on, db "An",0
def txtetoolbox_off, db "Aus",0
def txtetoolbox_saveinsavegame, db 0x98, "Mit Spielstand speichern",0
def txtetoolbox_usedefaultinsave, db 0x98, "Vom Spielstand entfernen",0
def txtetoolbox_saveasdefault, db 0x98, "Als Standard speichern",0
def txtetoolbox_resetdefaultsizes, db 0x98, "Standard wiederherstellen",0

def none, db "Keine", 0
def low,  db "Niedrig", 0
def normal, db "Normal", 0
def high, db "Hoch", 0

def defaultstation, db "(Standard)",0
def stationnumdefault, db "Bahnhof ",0x81,0xff,0xC7,0
def stationclassdefault, db "Bahnhofsklasse ",0x81,0xff,0xC7,0

def unnamedtownnamestyle, db "(Unbenannte Art)",0

def newshistory, db "Nachrichtenlog",0
def messagesettings, db "Nachrichten Einstellungen",0
def messages, db 0x94, "Nachrichten",0
	
def cantreverse, db 0x94,0x80," ",0x7c," will umkehren, kann dies aber nicht ohne Gefahr.",0

def grflanguage, db "0",0

def sizertooltip, db 0x98, "Ziehen um die Fenstergröße zu verändern",0
def stickytooltip, db 0x98, "Fenster dauerhaft machen, dadurch wird es per <Entf> nicht geschlossen",0

def rcw_railway, db 0x94, "Eisenbahn", 0
def rcw_signaltype, db 0x98, "Signalart", 0
def rcw_semaphores, db "Armsignal", 0
def rcw_lights, db "Lichtsignal", 0
def rcw_automatic, db "Automatisch", 0
def rcw_normal, db "Normal", 0
def rcw_entry, db "Einfahrt", 0
def rcw_exit, db "Ausfahrt", 0
def rcw_combo, db "Kombi", 0
def rcw_nopbs, db "Nicht wegbasiert", 0
def rcw_pbs, db "Wegbasiert", 0
def rcw_tracks, db 0x98, "Bahnsteige: ", 0x8E, 0x80, 0
def rcw_length, db 0x98, "Länge: ", 0x8E, 0x80, 0
def rcw_drag, db "Variabel", 0
def rcw_class, db 0x98, "Klasse:", 0
def rcw_type, db 0x98, "Art:", 0
def rcw_accepts, db 0x98, "Akzeptiert:                    ", 0x8A, 0

def outofdynmem, db 0x94, "Nicht genug dynamischer Speicher", 0
def cantresize, db 0x94, "Kann Fenstergröße nicht verändern...", 0

def grftextnotfound, db "-- GRF Text nicht gefunden! --",0

def newindubuildindustry, db "Industrie bauen",0
def newindufundprospecting, db "Erkundung finanzieren",0
def newinduproduces, db 0x98, "Produziert: ", 0x90, 0x80, 0
def toomanyindustries, db 94h,"Zu viele Industrien im Spiel.", 0

def newindulist_tooltip, db 0x98,"Liste der verfügbaren Industriearten - wählen Sie die gewünschte Art",0
def newinduinfo_tooltip, db 0x98,"Information über die aktuell ausgewählte Industrie",0
def newindubuild_tooltip, db 0x98,"Industrie bauen",0
def newinduprospect_tooltip, db 0x98,"Rohstofferkundung für die Industrie finanzieren",0

def newindu_cargowaiting, db 0x98,"Zu verarbeitende Rohstoffe:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

def warning_notowns, db 94h,"Warnung: Diese Spiel hat keine Städte. TTD wird vermutlich abstürzen wenn es geladen wird!",0

def localplayer, db " (lokaler Spieler)",0
def remoteplayer, db " (entfernter Spieler)",0

def multiplayer, db 0x98,"Mehrspielermodus",0
def multiplayer_tooltip, db 0x98,"Mehrspielermodus wählen",0

def ttdpatch_dll_notfound, db 94h,"Konnte ttdpatch.dll nicht laden, keine neuen Soundeffekte verfügbar.", 0

def statistics, db 0x98, "Statistiken",0
def statistics_white, db 0x94, "Statistiken",0
def totalcargo, db 0x8E, "Transportierte Fracht insgesamt",0
def statistics_tooltip, db 0x98, "Firmenstatistik öffnen",0

def landareainfoheight, db 0x98,"Höhe: ",0x95,0x7B,0

def txteroadmenu, db "Straßenbahnbau",0
def txtetramwindowheader, db 0x94,"Straßenbahnbau",0
def txtetramstationheader, db 0x94,"Haltestellenausrichtung",0
def txtetramdepotheader, db 0x94,"S.-Depotausrichtung",0
  
def shortdateformat, db 4, " ", 1, 0
def longdateformat, db 2, " ", 3, " ", 1, 0

def txtltwocc, db 0x94, "Farbauswahl", 0
def txtltwoccglb, db 0x98, "Globale Farben", 0
def txtltwoccstm, db 0x98, "Dampflok", 0
def txtltwoccdsl, db 0x98, "Diesellok", 0
def txtltwoccelc, db 0x98, "Elektr. Lok", 0
def txtltwoccmor, db 0x98, "Einschienenbahn", 0
def txtltwoccmgv, db 0x98, "Schwebebahn", 0
def txtltwoccdmu, db 0x98, "Diesel-Einheit", 0
def txtltwoccemu, db 0x98, "Elektr. Einheit", 0
def txtltwoccpaw, db 0x98, "Passagierwaggon", 0
def txtltwoccfrw, db 0x98, "Frachtwaggon", 0
def txtltwoccbus, db 0x98, "Bus", 0
def txtltwocctrm, db 0x98, "Straßenbahn", 0
def txtltwocctrk, db 0x98, "LKW", 0
def txtltwoccpsh, db 0x98, "Passagierschiff", 0
def txtltwoccfsh, db 0x98, "Frachtschiff", 0
def txtltwoccsap, db 0x98, "Regionalflugzeug", 0
def txtltwocclap, db 0x98, "Langstreckenflugzeug", 0
def txtltwoccfrp, db 0x98, "Frachtflugzeug", 0
def txtltwocchel, db 0x98, "Hubschrauber", 0
def txtltwocclr1, db 0x94, "Primär", 0
def txtltwocclr2, db 0x94, "Sekundär", 0

def steepslopes, db "Steilhang nicht möglich", 0
def landhigherbridgehead, db "Land unter Brücke zu hoch", 0

def grfhelpercaption, db 0x94,"GRF Author Helper",0
def grfhelper_displxrelyrel, db 0x94,"Sprite: ",0x7E," xrel: ",0x7C," yrel: ",0x7C,0
def textsprite, db 0x98,"Sprite",0

def airporttype, db 0x98, "Airport Type",0
def unnamedairporttype, db "(Unnamed type)",0

def hotkeylistdos, db "xqwe!",0x22,"-$t%1234567890",0xdf,27h,09h,5ch,0
def hotkeylistwin, db "xqwe!",0x22,"§$t%1234567890-=~]",0

def txtclonedepotbutton, db 0x98, "Clone Train", 0
def txtclonetooltip, db 0x98, "Allows you to clone a train", 0
def txtcloneerrortop, db 0x94, "Cannot clone train consist", 0
def txtcloneerror1, db 0x94, "Not a company train", 0
def txtcloneerror2, db 0x94, "Vehicle in consist is not available anymore", 0
def txtcloneerror3, db 0x94, "No engine head at the start of the consist", 0
def txtcloneerror4, db 0x94, "Not a rail vehicle", 0
def txtcloneerror5, db 0x94, "Unknown reason", 0

def last


; **************
;     French
; **************

newlanguage french,f,2,505759,1707008

def bribetext, db "Corrompre les autorités locales",0

def bribedesc, db 94h,80h,13,90h,"  "
	db "Paye les autorités locales pour augmenter votre cote, "
	db "au risque de vous faire coincer."
	db 13,"  Co",0fbh,"t: ",7fh,0

def bribefailed, db 94h,"Votre tentative de corruption a été découverte par un investigateur régional.",0

def headingfor, db 95h,80h,", ",84h,0
def headingfordepot1, db 95h,"Dépot de train ",0e0h," ",80h,", ", 84h,0
def headingfordepot2, db 95h,"Dépot routier ",0e0h," ",80h,", ", 84h,0
def headingfordepot3, db 95h,"Dépot maritime ",0e0h," ",80h,", ", 84h,0
def headingfordepot4, db 95h,80h," Hangar, ", 84h,0

def withsignals, db "Voie ferrées avec ",80h," (",80h,")",0
def wplainsignals, db "signaux réguliers",0
def wpresignals, db "pré-signaux",0
def wpresigexits, db "sortie-signaux",0
def wprecombined, db "signaux hybrides",0
def presigautomatic, db "automatiques",0
def presigmanual, db "manuels",0
def pathbasedauto, db "automatique, basé sur le trajet",0
def pathbasedmanual, db "manuel, basé sur le trajet",0

def vehmulttoolow, db 94h,"Attention : partie sauvée avec un nombre total de véhicules multiplié par ",7eh,". "
		db " ",7eh," composants de ",7eh," véhicules et ",7eh," objets spéciaux ont été retirés.",0

def rchunknotloaded, db 94h,"Attention : la partie utilise des options de TTDPatch "
		db "qui sont désactivées ou non présentes dans cette version, des informations peuvent etre perdues.",0

def loadgame, db "Charger le jeu",0

def gotodepot, db "Aller à ",80h,0
def gotodepotonly, db "Service au ",80h,0
def gototraindepot, db "Dépot de train ",0e0h," ",80h,0
def gotoroaddepot, db "Dépot routier ",0e0h," ",80h,0
def gotoshipdepot, db "Dépot maritime ",0e0h," ",80h,0
def gotoairdepot, db "Hangar ",80h,0
def routethrough, db "Trajet via ",0x80,0
def routenonstopthrough, db "Trajet non-stop via ",0x80,0

def vehobsolete, db 94h,"Le modèle est obsolete et ",80h,0

def cannotcheat, db 94h,"Ne peut exécuter la triche",0
def cheatinvalidparm, db 94h,"Paramètre invalide",0
def cheatunknown, db 94h,"Triche inconnue",0
def cheatobsolete1, db 94h,"Remarque: Cht: ",80h," est désuet.",0
def cheatobsolete2, db 94h,"Utilisez plutôt Cht: ",80h,".",0
def nostationhere, db 94h,"Aucune gare ici",0

def managedby1, db " (Joueur 1 prov.)",0
def managedby2, db " (Joueur 2 prov.)",0

def manage, db 98h,"Contrôler",0

def engineinfo1,	db 98h,"Cost: ",8ah,7fh
		db 98h,"   Poids: ",8ah,7ch,"t",13
		db 98h,"Effort Traction Max.: ",8ah,7ch,"kN",13
		db 98h,"Vitesse: ",8ah,84h
		db 98h,"   Puissance: ",8ah,7ch,"CV",0
def wagonpower,	db 98h,"Wagons Motorisés: ",8ah,"+",7ch,"CV"
		db 98h,"   Poids: ",8ah,"+",7dh,"t",0
def engineinfo2,	db 98h,"Coût: ",8ah,7fh,"/yr",13
		db 98h,"Capacité: ",8ah,80h," ",80h,13
		db 98h,"Modèle: ",8ah,7eh
		db 98h,"   Vie: ",8ah,7ch," années",13
		db 98h,"Fiabilité max: ",8ah,7dh,"%",0
def wagoninfo,	db 98h,"Cost: ",8ah,7fh,13
		db 98h,"Poids: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacité: ",8ah,80h," ",80h,0
def newwagoninfo, db 98h,"Cost: ",7fh,
	db "    Poids: ",7ch,"t",13
	db "Capacité: ",80h," ",80h,0
def wagonspeedlimit, db 98h,13,"Vitesse Max: ",80h,84h,0
def refittableto, db 98h,"Transformable en: ",8ah,80h,0
def refittabletoallbut, db 98h,"Transformable en: ",8ah,"Tout sauf ",80h,0
def refittabletoall, db 98h,"Transformable en: ",8ah,"Tout types de marchandises",0

def railwaywagon, db "wagon",0
def monorailwagon, db "wagon monorail",0
def maglevwagon, db "wagon maglev",0

def ufodestroyed, db 98h,0fh,"'OVNI' detruit dans une grande explosion pres de ",80h,"!",0

def rvweightinfo, db 98h,"Poids: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Puissance: ", 95h,7ch,"CV   "
	db 80h,0

def rvweightpurchasewindow, db 98h,"Cost: ", 8ah, 7fh
	db 98h,"   vitesse: ", 8ah, 84h, 13
	db 98h,"Coût: ", 8ah, 7fh, "/année", 13
	db 98h,"Puissance: ", 8ah, 7ch,"CV"
	db 98h,"   poids: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Capacité: ", 8ah, 80h, 13
	db 98h,"Modèle: ", 8ah, 7eh
	db 98h,"   Vie: ", 8ah, 7ch, " années",13
	db 98h,"Fiabilité max: ", 8ah, 7dh, "%", 0

def grfloaderror, db 94h,"Erreur en chargeant les nouveaux graphiques:",0
def toomanysprites, db 94h,"Il y a plus de sprites que ce qui est spécifié (fichier ",80h,").",0
def outofmemory, db 94h,"Pas assez de mémoire (fichier ",80h,").",0
def wronggrfversion, db 94h,"Mauvaise version de .grf (fichier ",80h,").",0
def toomanyspritestotal, db 94h,"Ne peut pas charger plus de sprites (du fichier ",80h,").",0
def filenotfound, db 94h,"Fichier ",22h,80h,22h," non trouvé.",0
def invalidsprite, db 94h, "Fichier ", 22h,80h,22h," a le sprite #",7ch," invalide (code ",7ch,"/",7ch,").",0
def notttdpatchgrf, db 94h, "File ",22h,80h,22h," n'est pas un fichier graphique pour TTDPatch.",0
def grferror, db 94h, "Erreur: ", 80h,0
def grfwarning, db 94h, "Attention: ", 80h,0
def grfneedspatchversion, db 94h, 80h, " necessite au moins TTDPatch version ", 80h, 0
def grfneedsdoswin, db 94h, 80h, " est pour la version ", 80h, " de TTD.", 0
def grfwantsswitch, db 94h, 80h, " est conçue pour fonctionner avec ", 80h, 0
def grfinvalidparam, db 94h, "Parametres invalides pour ", 80h, ": parametre ", 80h, " (", 7Bh, ")", 0
def grfconflict, db 94h,"Conflit de GRF avec ", 80h,0x94, " (ressource ", 0x7c, " au sprite ", 0x7c, ")", 0
def conflict_itself, db "lui même", 0
def conflict_preexist, db "definitions existantes", 0

def grfstatcaption, db 0x94,"Status GRF", 0
def grfstatapply, db 0x98,"Appliquer", 0
def grfstatreset, db 0x98,"Defaut", 0
def grfstatdebug, db 0x98,"Debug", 0
def grfinfotext, db 0x95,0x80,13,0x94,"Fichier: ",0x95,0x80,13,0x80,0x94,0x80,0

def grflisthint, db 0x98,"Cliquez sur le texte pour avoir plus d'information sur "
	db "ce fichier.  Cliquez sur le drapeau vert/rouge pour activer/désactiver.",0
def grfapplyhint, db 0x98,"Appliquer les changement d'activation des graphiques à "
	db "cette partie.",0
def grfresethint, db 0x98,"Réinitialiser tous les réglages graphiques et appliquer",0
def grfdebughint, db 0x98,"Créer des informations de debug des status des grf actifs",0
def grfdebugmsg, db 0x94, "Informations sur les status graphiques enregistrés sous ",80h,": ",80h,0

def grfstatusmenu, db "Nouveaux status graphiques", 0
def initialgrfsettings, db 0x98, "Reglages graphiques initiaux", 0
def initialgrfsettingshint, db 0x98, "Ouvrir la fenêtre des status graphiques pour activer les graphiques ",
	db "activés par defaut", 0

def grfstatgeninfo1, db 0x98,"Nombre de fichiers: ",0x94,0x7b,13
	db 0x98,"Memoire utiliséee: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Nombre total de sprites: ",0x94,0x7b,13
	db 0x98,"Sprites actifs: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo2,	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Camions/Bus: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo3,	db 0x98,"    Bateaux: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Avions: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo4,	db 0x98,"    Maisons: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Autres: ",0x94,0x7b,0x98,0x80,0
def grfstatmax, db " (",0x7b," max)",0


def elecrailconstitle, db 94h,"Construction de voie ferrée électrique",0
def elecrailconsmenu, db "construction voie électrique",0

def lmilloutoftrees, db 98h,0fh,80h," ",80h," manque d'arbre proches!",0

def eurointroduced, db 98h,0fh,"Union monétaire!",0dh,0dh,"Les pays européens passe à l'Euro!",0

def curr_pound, db 0,0,0,0,0,0
def curr_dollar, db 0,0,0,0,0,0
def curr_franc, db 0,0,0,0,0,0
def curr_deutschmark, db 0,0,0,0,0,0
def curr_yen, db 0,0,0,0,0,0
def curr_peseta, db 0,0,0,0,0,0
def curr_HUF, db "Florin hongrois (Ft)",0,0,0,0,0,0
def curr_PLN, db "Zloty Polonais(Zl)",0,0,0,0,0,0
def curr_ATS, db "AShilling Australien (ATS)",0,0,0,0,0,0
def curr_BEF, db "Franc Belge (BEF)",0,0,0,0,0,0
def curr_DKK, db "Couronne danoise (DKK)",0,0,0,0,0,0
def curr_FIM, db "Mark finlandais (FIM)",0,0,0,0,0,0
def curr_GRD, db "Drachme grec (GRD)",0,0,0,0,0,0
def curr_CHF, db "Franc Suisse(CHF)",0,0,0,0,0,0
def curr_NLG, db "Florin hollandais (NLG)",0,0,0,0,0,0
def curr_ITL, db "Lire italienne (ITL)",0,0,0,0,0,0
def curr_SEK, db "Couronne suisse (SEK)",0,0,0,0,0,0
def curr_RUB, db "Rouble russe (RUB)",0,0,0,0,0,0
def curr_EUR, db "Euro (",0x9E,")",0,0,0,0,0,0

def townlastmonthaccepted, db 98h,"Marchandises acceptées par toutes les stations le mois dernier :",0

def aircraftcleared, db 98h,0fh,"Les débris du récent crash d'avion de ",80h," ont été retirés!",0
def zeppelincleared, db 98h,0fh,"Les débris du récent crash de Zepplin de ",80h," ont été retirés!",0
def traincleared, db 98h,0fh,"Les débris du récent accident de train près de ",80h," ont été déblayés!",0

def endofsharedorders, db 1,0xa,"- - Fin de commande partagée (",85h,7ch,") - -",0

def resetorders, db 0x98,"Réinitialiser",0
def toggleservice, db 0x98,"Révision",0
def resethint, db 0x98,"Retirer tous les ordres (n'affecte pas les autres véhicules partageant ces ordres)",0
def servicehint, db 0x98,"Le véhicule ignore cet ordre à moins qu'il soit temps de faire une révision",0

def nosort, db "Non trié",0
def sortconsistnum, db "Nombre",0
def sortprofit, db "Profit",0
def sortlastprofit, db "Profit de l'année précédente",0
def sortage, db "Age",0
def sortmaxspeed, db "Vitesse max",0
def sortreliability, db "Fiabilité",0
def sortcargo, db "Marchandise",0
def sortdestination, db "Première destination",0
def sorthint, db 0x98,"Choisissez le critère de tri dans cette liste",0

def performance, db " (Performance: ",0x7e,")",0

def vehiclelost, db 0x94,0x80," ",0x7c," semble perdu",0

def wrongrailtype, db 94h,"...type de rail incompatible",0

def neterror1, db 0x94,"Erreur réseau!",0
def neterror2, db 0x94,"Partie déconnéctée!",0

def desynch1, db 0x94,"Synchronisation perdue!",0
def desynch2, db 0x94,"Utilisez sv2flip ou recharger un partie sauvée!",0

def refitvehicle, db 0x98,"Transformer le véhicule",0
def refitcargohint, db 0x98,"Choisissez le nouveau type de marchandise",0
def refitbuttonhint, db 0x98,"Transforme le véhicule pour transporter le type sélectionné",0

def cantbuildcanalhere, db 0x94, "Ne peut construire de canal/écluse ici", 0

def fundprospecting, db 0x94, "Recherche de nouvelles mines/forêts", 0
def buildindustry, db 0x94, "Construire une industrie", 0
def fundingfailed, db 0x94, "Recherche infructueuse. Les prospecteurs sont revenus les mains vides.", 0
def cannotfundprospecting, db 0x94, "Impossible d'effectuer des recherches", 0

def newtrainindepot, db 0
def newrvindepot, db 0
def newshipindepot, db 0
def newaircraftinhangar, db 0
def newvehold, db 0
def newvehveryold, db 0
def newvehveryveryold, db 0
def newvehiclelost, db 0
def newcantreverse, db 0

def txtetoolboxmenu, db "Réglage des IHM améliorées", 0
def txtetoolbox, db 0x94, "Réglage des IHM améliorées", 0
def txtetoolbox_tsigns, db 0x98, "Panneaux de gare", 0
def txtetoolbox_tsignstrans, db "Transparent",0
def txtetoolbox_tsignsold, db "Style TTD",0

def txtetoolbox_dsize, db 0x98, "Taille des dépots",0
def txtetoolbox_d8, db "Dépot  8  (4)",0
def txtetoolbox_d10, db "Dépot 10  (5)",0
def txtetoolbox_d12, db "Dépot 12  (6)",0
def txtetoolbox_d14, db "Dépot 14  (7)",0
def txtetoolbox_d16, db "Dépot 16  (8)",0
def txtetoolbox_d18, db "Dépot 18  (9)",0
def txtetoolbox_d20, db "Dépot 20  (10)",0

def txtetoolbox_depotalltrash, db 0x98, "Depot jeter tout",0
def txtetoolbox_on, db "On",0
def txtetoolbox_off, db "Off",0
def txtetoolbox_saveinsavegame, db 0x98, "Sauve opt. ds partie",0
def txtetoolbox_usedefaultinsave, db 0x98, "Ne sauve pas opt.",0
def txtetoolbox_saveasdefault, db 0x98, "Définir par défaut",0
def txtetoolbox_resetdefaultsizes, db 0x98, "Réinitialiser les tailles",0

def none, db "Aucun", 0
def low,  db "Fible", 0
def normal, db "Normale", 0
def high, db "Elevé", 0

def defaultstation, db "(defaut)",0
def stationnumdefault, db "Gare ",0x81,0xff,0xC7,0
def stationclassdefault, db "Catégorie de gare ",0x81,0xff,0xC7,0

def unnamedtownnamestyle, db "(style sans nom)",0

def newshistory, db "Historique des messages",0
def messagesettings, db "Réglages des messages",0
def messages, db 0x94, "Messages",0
	
def cantreverse, db 0x94,0x80," ",0x7c," doit faire demi tour mais ne peut y arriver.",0

def grflanguage, db "0",0

def sizertooltip, db 0x98, "Tirez pour redimentionner la fenêtre",0
def stickytooltip, db 0x98, "Rend la fenêtre attachée, elle ne sera pas fermée en appuyant sur <Suppr>",0

def rcw_railway, db 0x94, "Voie ferrée", 0
def rcw_signaltype, db 0x98, "Type de signal", 0
def rcw_semaphores, db "Sémaphores", 0
def rcw_lights, db "Lampadaires", 0
def rcw_automatic, db "Automatique", 0
def rcw_normal, db "Normale", 0
def rcw_entry, db "Entrée", 0
def rcw_exit, db "Sortie", 0
def rcw_combo, db "Combiné", 0
def rcw_nopbs, db "Non basé s/ trajet", 0
def rcw_pbs, db "Basé s/ trajet", 0
def rcw_tracks, db 0x98, "Voies: ", 0x8E, 0x80, 0
def rcw_length, db 0x98, "Longueur: ", 0x8E, 0x80, 0
def rcw_drag, db "Tirer", 0
def rcw_class, db 0x98, "Catégorie:", 0
def rcw_type, db 0x98, "Type:", 0
def rcw_accepts, db 0x98, "Accepte:                    ", 0x8A, 0
	
def outofdynmem, db 0x94, "Pas assez de mémoire dynamique", 0
def cantresize, db 0x94, "Ne peut redimentionner la fenêtre...", 0

def grftextnotfound, db "-- texte GRF non trouvé! --",0

def newindubuildindustry, db "Construire une industrie",0
def newindufundprospecting, db "Recherche de mine/forêt pour industrie",0
def newinduproduces, db 0x98, "Produit: ", 0x90, 0x80, 0
def toomanyindustries, db 94h,"Trop d'industries dans ce monde.", 0

def newindulist_tooltip, db 0x98,"Liste des industries disponibles, cliquez sur celle que vous voulez construire",0
def newinduinfo_tooltip, db 0x98,"Informations sur le type d'industrie sélectionné",0
def newindubuild_tooltip, db 0x98,"Constuire l'industrie",0
def newinduprospect_tooltip, db 0x98,"Financer une recherche de matières premières pour cette industrie",0

def newindu_cargowaiting, db 0x98,"Marchadise attendant d'^tre transformée:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

def warning_notowns, db 94h,"Attention, cette partie n'a aucune ville. Si vous y jouer, TTD risque de planter!",0

def localplayer, db " (joueurs local)",0
def remoteplayer, db " (joueur distant)",0

def multiplayer, db 0x98,"Multijoueurs",0
def multiplayer_tooltip, db 0x98,"Choisissez la partie multijoueurs",0

def ttdpatch_dll_notfound, db 94h,"Ne peut charger ttdpatch.dll, nouveaux sons désactivés.", 0

def statistics, db 0x98, "Statistiques",0
def statistics_white, db 0x94, "Statistiques",0
def totalcargo, db 0x8E, "Total des marchandises transportées",0
def statistics_tooltip, db 0x98, "Ouvrir les statistiques de la compagnie",0

def landareainfoheight, db 0x98,"Altitude: ",0x95,0x7B,0

def txteroadmenu, db "Construction de tramway",0
def txtetramwindowheader, db 0x94,"Construction de tramway",0
def txtetramstationheader, db 0x94,"Orientation de l'arrêt de tram",0
def txtetramdepotheader, db 0x94,"Orientation du dépot de tram",0
  
def shortdateformat, db 4, " ", 1, 0
def longdateformat, db 2, " ", 3, " ", 1, 0

def txtltwocc, db 0x94, "Fenêtre des couleurs de la compagnie", 0
def txtltwoccglb, db 0x98, "Couleurs principales", 0
def txtltwoccstm, db 0x98, "Locomotive à vapeur", 0
def txtltwoccdsl, db 0x98, "Locomotive diesel", 0
def txtltwoccelc, db 0x98, "Locomotive éléctrique", 0
def txtltwoccmor, db 0x98, "Locomotive monorail", 0
def txtltwoccmgv, db 0x98, "Locomotive maglev", 0
def txtltwoccdmu, db 0x98, "Multi-locos diesel", 0
def txtltwoccemu, db 0x98, "Multi-locos éléctriques", 0
def txtltwoccpaw, db 0x98, "Wagons de passager", 0
def txtltwoccfrw, db 0x98, "Wagons de fret", 0
def txtltwoccbus, db 0x98, "Bus", 0
def txtltwocctrm, db 0x98, "Tram", 0
def txtltwocctrk, db 0x98, "Camion", 0
def txtltwoccpsh, db 0x98, "Bateau de passagers", 0
def txtltwoccfsh, db 0x98, "Bateau de fret", 0
def txtltwoccsap, db 0x98, "Avion régional", 0
def txtltwocclap, db 0x98, "Avion grandes lignes", 0
def txtltwoccfrp, db 0x98, "Avion de fret", 0
def txtltwocchel, db 0x98, "Helicopter", 0
def txtltwocclr1, db 0x94, "Principal", 0
def txtltwocclr2, db 0x94, "Secondaire", 0

def steepslopes, db "les pentes raides ne sont pas adaptées", 0
def landhigherbridgehead, db "terrain sous le pont plus haut que la tête de pont", 0

def grfhelpercaption, db 0x94,"Aide auteur GRF",0
def grfhelper_displxrelyrel, db 0x94,"Sprite: ",0x7E," xrel: ",0x7C," yrel: ",0x7C,0
def textsprite, db 0x98,"Sprite",0

def airporttype, db 0x98, "Airport Type",0
def unnamedairporttype, db "(Unnamed type)",0

def hotkeylistdos, db "xqwe!",0x22,0x9C,"$t%1234567890-=",1eh,5ch,0
def hotkeylistwin, db "xqwe1234t5&",0xE9,0x22,"'(-",0xE8,"_",0xE7,")=$",0xB2,"*",0

def txtclonedepotbutton, db 0x98, "Clone Train", 0
def txtclonetooltip, db 0x98, "Allows you to clone a train", 0
def txtcloneerrortop, db 0x94, "Cannot clone train consist", 0
def txtcloneerror1, db 0x94, "Not a company train", 0
def txtcloneerror2, db 0x94, "Vehicle in consist is not available anymore", 0
def txtcloneerror3, db 0x94, "No engine head at the start of the consist", 0
def txtcloneerror4, db 0x94, "Not a rail vehicle", 0
def txtcloneerror5, db 0x94, "Unknown reason", 0

def last


; **************
;    Spanish
; **************

newlanguage spanish,s,2,506237,1707520

def bribetext, db "Sobornar la autoridad local",0

def bribedesc, db 94h,80h,13,90h," "
	db "Sobornar la autoridad local para aumentar su ranking, "
	db "con el riesgo de una severa penalización si es descubierto."
	db 13," Coste: ",7fh,0

def bribefailed, db 94h,"Su intento de soborno ha sido descubierto por un investigador regional.",0

def headingfor, db 95h,80h,", ",84h,0
def headingfordepot1, db 95h,80h," Cocheras de Ferrocarril, ", 84h,0
def headingfordepot2, db 95h,80h," Garaje de Carretera, ", 84h,0
def headingfordepot3, db 95h,80h," Estación Marítima, ", 84h,0
def headingfordepot4, db 95h,80h," Hangar, ", 84h,0

def withsignals, db "Vías de ferrocarril con ",80h," ",80h,0
def wplainsignals, db "señales planas",0
def wpresignals, db "pre-señales",0
def wpresigexits, db "salidas pre-señal",0
def wprecombined, db "señales combinadas",0
def presigautomatic, db "automáticas",0
def presigmanual, db "manuales",0
def pathbasedauto, db "automático, basado en trayectoria",0
def pathbasedmanual, db "manual, basado en trayectoria",0

def vehmulttoolow, db 94h,"Advertencia: juego guardado con multiplicador de veh. de ",7eh,". "
		db " Removidos ",7eh," vehículos en ",7eh," grupos  y ",7eh," objetos especiales.",0

def rchunknotloaded, db 94h,"Advertencia: el juego utiliza algunas características de TTDPatch "
		db "que no estan activadas o disponibles en esta versión. Podría perder datos.",0

def loadgame, db "Cargar Juego",0

def gotodepot, db "Ir a ",80h,0
def gotodepotonly, db "Mantenimiento en ",80h,0
def gototraindepot, db 80h," Cocheras de Ferrocarril",0
def gotoroaddepot, db 80h," Garaje de Carretera",0
def gotoshipdepot, db 80h," Estación Marítima",0
def gotoairdepot, db 80h," Hangar",0
def routethrough, db "Ruta a través ",0x80,0
def routenonstopthrough, db "Ruta sin paradas a través ",0x80,0

def vehobsolete, db 94h,"El modelo está obsoleto y ",80h,0

def cannotcheat, db 94h,"No se puede ejecutar el código trampa",0
def cheatinvalidparm, db 94h,"Parámetro invalido",0
def cheatunknown, db 94h,"Código trampa desconocido",0
def cheatobsolete1, db 94h,"Nota: Cht: ",80h," es obsoleto.",0
def cheatobsolete2, db 94h,"Use en cambio Cht: ",80h,0
def nostationhere, db 94h,"No hay estación aquí",0

def managedby1, db " (Jugador 1 temp.)",0
def managedby2, db " (Jugador 2 temp.)",0

def manage, db 98h,"Manejar",0

def engineinfo1,	db 98h,"Coste: ",8ah,7fh
		db 98h,"   Peso: ",8ah,7ch,"t",13
		db 98h,"Esfuerzo de Tracción Max.: ",8ah,7ch,"kN",13
		db 98h,"Velocidad: ",8ah,84h
		db 98h,"   Potencia: ",8ah,7ch,"cv",0
def wagonpower,	db 98h,"Vagones Motrices: ",8ah,"+",7ch,"cv"
		db 98h,"   Peso: ",8ah,"+",7dh,"t",0
def engineinfo2,	db 98h,"Coste de operación: ",8ah,7fh,"/año",13
		db 98h,"Capacidad: ",8ah,80h," ",80h,13
		db 98h,"Diseño: ",8ah,7eh
		db 98h,"   Vida: ",8ah,7ch," años",13
		db 98h,"Fiabilidad Max.: ",8ah,7dh,"%",0
def wagoninfo,	db 98h,"Coste: ",8ah,7fh,13
		db 98h,"Peso: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacidad: ",8ah,80h," ",80h,0
def newwagoninfo, db 98h,"Coste: ",7fh,
	db "    Peso: ",7ch,"t",13
	db "Capacidad: ",80h," ",80h,0
def wagonspeedlimit, db 98h,13,"Velocidad máx.: ",80h,84h,0
def refittableto, db 98h,"Modificable a: ",8ah,80h,0
def refittabletoallbut, db 98h,"Modificable a: ",8ah,"Todos menos ",80h,0
def refittabletoall, db 98h,"iModificable a: ",8ah,"Todos los tipos de mercancias",0

def railwaywagon, db "vagón ferroviario",0
def monorailwagon, db "vagón de monorrail",0
def maglevwagon, db "vagón maglev",0

def ufodestroyed, db 98h,0fh,"'OVNI' destruido en una enorme explosión cerca de ",80h,"!",0

def rvweightinfo, db 98h,"Peso: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Potencia: ", 95h,7ch,"cv   "
	db 80h,0

def rvweightpurchasewindow, db 98h,"Coste: ", 8ah, 7fh
	db 98h,"   Velocidad: ", 8ah, 84h, 13
	db 98h,"Coste de operación: ", 8ah, 7fh, "/año", 13
	db 98h,"Potencia: ", 8ah, 7ch,"cv"
	db 98h,"   Peso: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Capacidad: ", 8ah, 80h, 13
	db 98h,"Diseño: ", 8ah, 7eh
	db 98h,"   Vida: ", 8ah, 7ch, " años",13
	db 98h,"Fiabilidad Max.: ", 8ah, 7dh, "%", 0

def grfloaderror, db 94h,"Error cargando nuevos gráficos:",0
def toomanysprites, db 94h,"Error cargando nuevos gráficos: (archivo ",80h,").",0
def outofmemory, db 94h,"Sin memoria (archivo ",80h,").",0
def wronggrfversion, db 94h,"Versión .grf incorrecta (archivo ",80h,").",0
def toomanyspritestotal, db 94h,"No se pueden cargar más dibujos (desde archivo ",80h,").",0
def filenotfound, db 94h,"Archivo ",22h,80h,22h," no encontrado.",0
def invalidsprite, db 94h, "El archivo ", 22h,80h,22h," contiene un dibujo inválido #",7ch," (code ",7ch,"/",7ch,").",0
def notttdpatchgrf, db 94h, "El archivo ",22h,80h,22h," no es un archivo de gráficos para TTDPatch.",0
def grferror, db 94h, "Error: ", 80h,0
def grfwarning, db 94h, "Aviso: ", 80h,0
def grfneedspatchversion, db 94h, 80h, " requiere la última versión de TTDPatch ", 80h, 0
def grfneedsdoswin, db 94h, 80h, " es para la versión ", 80h, " de TTD.", 0
def grfwantsswitch, db 94h, 80h, " está diseñado para ser usado con ", 80h, 0
def grfinvalidparam, db 94h, "Parámetro inválido para ", 80h, ": parámetro ", 80h, " (", 7Bh, ")", 0
def grfconflict, db 94h,"conflicto GRF con ", 80h,0x94, " (recurso ", 0x7c, " al puntero ", 0x7c, ")", 0
def conflict_itself, db "consigo mismo", 0
def conflict_preexist, db "definiciones existentes", 0

def grfstatcaption, db 0x94,"Estado GRF", 0
def grfstatapply, db 0x98,"Aplica", 0
def grfstatreset, db 0x98,"Defecto", 0
def grfstatdebug, db 0x98,"Depura", 0
def grfinfotext, db 0x95,0x80,13,0x94,"Archivo: ",0x95,0x80,13,0x80,0x94,0x80,0

def grflisthint, db 0x98,"Pulse en el texto para ver información adicional "
	db "sobre este archivo. Pulse en el marcador rojo/verde para activarlo.",0
def grfapplyhint, db 0x98,"Aplicar cambios de gráficos activos/inactivos a la "
	db "partida actual.",0
def grfresethint, db 0x98,"Restaurar todos los valores de gráficos a los valores por defecto y aplicar",0
def grfdebughint, db 0x98,"Crear una salida depurada del estado de los actuales gráficos activos",0
def grfdebugmsg, db 0x94, "Información del estado de los gráficos escrito en ",80h,": ",80h,0

def grfstatusmenu, db "Nuevo estado de gráficos", 0
def initialgrfsettings, db 0x98, "Configuración inicial de los gráficos", 0
def initialgrfsettingshint, db 0x98, "Abrir la ventana del estado de GRF para seleccionar inicialmente ",
	db "los juegos de gráficos activos", 0

def grfstatgeninfo1, db 0x98,"Número de archivos: ",0x94,0x7b,13
	db 0x98,"Uso de memoria: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Punteros activos: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo2,	db 0x98,"    Trenes: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Automóviles: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo3,	db 0x98,"    Barcos: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Aviones: ",0x94,0x7b,0x98,0x80,0
def grfstatgeninfo4,	db 0x98,"    Casas: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Otros: ",0x94,0x7b,0x98,0x80,0
def grfstatmax, db " (",0x7b," máx)",0


def elecrailconstitle, db 94h,"Construcción de vía electrificada",0
def elecrailconsmenu, db "Construcción de vía Electr.",0

def lmilloutoftrees, db 98h,0fh,80h," ",80h," se quedó sin árboles aledaños!",0

def eurointroduced, db 98h,0fh,"Unión monetaria!",0dh,0dh,"Los paises europeos cambian sus monedas nacionales por el Euro!",0

def curr_pound, db 0,0,0,0,0,0
def curr_dollar, db 0,0,0,0,0,0
def curr_franc, db 0,0,0,0,0,0
def curr_deutschmark, db 0,0,0,0,0,0
def curr_yen, db 0,0,0,0,0,0
def curr_peseta, db 0,0,0,0,0,0
def curr_HUF, db "Forint Húngaro (Ft)",0,0,0,0,0,0
def curr_PLN, db "Zloty Polaco (zl)",0,0,0,0,0,0
def curr_ATS, db "Schilling Austriaco (ATS)",0,0,0,0,0,0
def curr_BEF, db "Franco Belga (BEF)",0,0,0,0,0,0
def curr_DKK, db "Corona Danesa (DKK)",0,0,0,0,0,0
def curr_FIM, db "Marco Finlandes (FIM)",0,0,0,0,0,0
def curr_GRD, db "Dracma Griego (GRD)",0,0,0,0,0,0
def curr_CHF, db "Franco Suizo (CHF)",0,0,0,0,0,0
def curr_NLG, db "Florín Holandés (NLG)",0,0,0,0,0,0
def curr_ITL, db "Lira Italiana (ITL)",0,0,0,0,0,0
def curr_SEK, db "Corona Sueca (SEK)",0,0,0,0,0,0
def curr_RUB, db "Rublo Ruso (RUB)",0,0,0,0,0,0
def curr_EUR, db "Euro (",0x9D,")",0,0,0,0,0,0

def townlastmonthaccepted, db 98h,"Carga aceptada el mes anterior en todas las estaciones:",0

def aircraftcleared, db 98h,0fh,"Los restos de un reciente accidente aéreo han sido retirados de",80h,"!",0
def zeppelincleared, db 98h,0fh,"Los restos de un reciente accidente de Zeppelin han sido retirados de ",80h,"!",0
def traincleared, db 98h,0fh,"Los restos del reciente accidente de tren han sido retirados de ",80h,"!",0

def endofsharedorders, db 1,0xa,"- - Fin de órdenes compartidas (",85h,7ch,") - -",0

def resetorders, db 0x98,"Borra",0
def toggleservice, db 0x98,"Servicio",0
def resethint, db 0x98,"Borrar todas las órdenes de la hoja de ruta (no afecta a los otros vehículos que comparten esta hoja de ruta)",0
def servicehint, db 0x98,"Hace que el vehículo salte esta órden hasta que llegue el tiempo de servicio",0

def nosort, db "Sin órden",0
def sortconsistnum, db "Número",0
def sortprofit, db "Provecho",0
def sortlastprofit, db "Provecho del último año",0
def sortage, db "Edad",0
def sortmaxspeed, db "Velocidad Máxima",0
def sortreliability, db "Fiabilidad",0
def sortcargo, db "Mercancia",0
def sortdestination, db "Primera destinación",0
def sorthint, db 0x98,"Seleccione el método de ordenación de la lista de vehículos",0

def performance, db " (Puntuación funcionamiento: ",0x7e,")",0

def vehiclelost, db 0x94,0x80," ",0x7c," parece haberse perdido",0

def wrongrailtype, db 94h,"...tipos de rail incompatibles",0

def neterror1, db 0x94,"Error de red!",0
def neterror2, db 0x94,"Juego desconectado!",0

def desynch1, db 0x94,"Juego desincronizado!",0
def desynch2, db 0x94,"Use sv2flip o recargue el último guardado!",0

def refitvehicle, db 0x98,"Modificar vehículo",0
def refitcargohint, db 0x98,"Seleccione el tipo de mercancia que el vehículo debe llevar",0
def refitbuttonhint, db 0x98,"Modificar vehículo para cargar el tipo de mercancias seleccionado",0

def cantbuildcanalhere, db 0x94, "No puede construir canales/esclusas aquí", 0

def fundprospecting, db 0x94, "Financiar una prospección", 0
def buildindustry, db 0x94, "Construir industria", 0
def fundingfailed, db 0x94, "Tu financiamiento no ha sido suficiente. Los prospectores han vuelto con las manos vacías.", 0
def cannotfundprospecting, db 0x94, "No se puede financiar una prospección", 0

def newtrainindepot, db 0
def newrvindepot, db 0
def newshipindepot, db 0
def newaircraftinhangar, db 0
def newvehold, db 0
def newvehveryold, db 0
def newvehveryveryold, db 0
def newvehiclelost, db 0
def newcantreverse, db 0

def txtetoolboxmenu, db "Configuración de GUI mejorada", 0
def txtetoolbox, db 0x94, "Configuración de GUI mejorada", 0
def txtetoolbox_tsigns, db 0x98, "Señales de estación", 0
def txtetoolbox_tsignstrans, db "Transparente",0
def txtetoolbox_tsignsold, db "Estilo TTD",0

def txtetoolbox_dsize, db 0x98, "Tamaño del hangar",0
def txtetoolbox_d8, db "Hangar  8  (4)",0
def txtetoolbox_d10, db "Hangar 10  (5)",0
def txtetoolbox_d12, db "Hangar 12  (6)",0
def txtetoolbox_d14, db "Hangar 14  (7)",0
def txtetoolbox_d16, db "Hangar 16  (8)",0
def txtetoolbox_d18, db "Hangar 18  (9)",0
def txtetoolbox_d20, db "Hangar 20  (10)",0

def txtetoolbox_depotalltrash, db 0x98, "Hangar todo basura",0
def txtetoolbox_on, db "Encendido",0
def txtetoolbox_off, db "Apagado",0
def txtetoolbox_saveinsavegame, db 0x98, "Configuración fijada",0
def txtetoolbox_usedefaultinsave, db 0x98, "Desfijar",0
def txtetoolbox_saveasdefault, db 0x98, "Guardar como defecto",0
def txtetoolbox_resetdefaultsizes, db 0x98, "Volver a los valores por defecto",0

def none, db "No", 0
def low,  db "Bajo", 0
def normal, db "Normal", 0
def high, db "Alto", 0

def defaultstation, db "(defecto)",0
def stationnumdefault, db "Estación ",0x81,0xff,0xc7,0
def stationclassdefault, db "Clase de estación ",0x81,0xff,0xc7,0

def unnamedtownnamestyle, db "(Estilo sin nombre)",0

def newshistory, db "Histórico de mensajes",0
def messagesettings, db "Configuración de mensajes",0
def messages, db 0x94, "Mensajes",0

def cantreverse, db 0x94,0x80," ",0x7c," necesita dar la vuelta pero no lo puede hacer de forma segura.",0

def grflanguage, db "0",0

def sizertooltip, db 0x98, "Arrastre para cambiar el tamaño de ventana",0
def stickytooltip, db 0x98, "Hacer esta ventana fija, no se cerrará cuando pulse <supr>",0

def rcw_railway, db 0x94, "Via de tren", 0
def rcw_signaltype, db 0x98, "Tipo de señal", 0
def rcw_semaphores, db "Semáforos", 0
def rcw_lights, db "Luces", 0
def rcw_automatic, db "Automático", 0
def rcw_normal, db "Normal", 0
def rcw_entry, db "Entrada", 0
def rcw_exit, db "Salida", 0
def rcw_combo, db "Combinada", 0
def rcw_nopbs, db "No basado en trayectoria", 0
def rcw_pbs, db "basado en trayectoria", 0
def rcw_tracks, db 0x98, "Pistas: ", 0x8E, 0x80, 0
def rcw_length, db 0x98, "Longitud: ", 0x8E, 0x80, 0
def rcw_drag, db "Arrastrar", 0
def rcw_class, db 0x98, "Clase:", 0
def rcw_type, db 0x98, "Tipo:", 0
def rcw_accepts, db 0x98, "Acepta:                    ", 0x8A, 0

def outofdynmem, db 0x94, "Fuera de memoria dinámica", 0
def cantresize, db 0x94, "No puedo cambiar de tamaño la ventana...", 0

def grftextnotfound, db "-- texto GRF no encontrado! --",0

def newindubuildindustry, db "Construir industria",0
def newindufundprospecting, db "Hacer prospecciones para una industria",0
def newinduproduces, db 0x98, "Produce: ", 0x90, 0x80, 0
def toomanyindustries, db 94h,"Demasiadas industrias en el mapa.", 0

def newindulist_tooltip, db 0x98,"Lista de tipos de industrias disponibles - pulse la que usted quiera para construirla",0
def newinduinfo_tooltip, db 0x98,"Información sobre el tipo de industria actualmente seleccionado",0
def newindubuild_tooltip, db 0x98,"Construye la industria",0
def newinduprospect_tooltip, db 0x98,"Financiar la prospección para encontrar los recursos para esta industria",0

def newindu_cargowaiting, db 0x98,"Mercancia esperando ser procesada:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

def warning_notowns, db 94h,"Aviso: Este juego no tiene ninguna ciudad. Si usted intenta jugar, TTD puede cascar!",0

def localplayer, db " (jugador local)",0
def remoteplayer, db " (jugador remoto)",0

def multiplayer, db 0x98,"Multijugador",0
def multiplayer_tooltip, db 0x98,"Seleccione juego multijugador",0

def ttdpatch_dll_notfound, db 94h,"No se puede cargar ttdpatch.dll, nuevos sonidos desactivados.", 0

def statistics, db 0x98, "Estadísticas",0
def statistics_white, db 0x94, "Estadísticas",0
def totalcargo, db 0x8E, "Cantidad total de mercancias transportadas",0
def statistics_tooltip, db 0x98, "Abrir estadísticas de compañias",0

def landareainfoheight, db 0x98,"Altitud: ",0x95,0x7B,0

def txteroadmenu, db "Construcción de tramvía",0
def txtetramwindowheader, db 0x94,"Construcción de tramvía",0
def txtetramstationheader, db 0x94,"Orientación de la parada de tramvía",0
def txtetramdepotheader, db 0x94,"Orientación del hangar de tramvía",0
  
def shortdateformat, db 4, " ", 1, 0
def longdateformat, db 2, " ", 3, " ", 1, 0

def txtltwocc, db 0x94, "Esquema de color de la compañía", 0
def txtltwoccglb, db 0x98, "Esquema de color global", 0
def txtltwoccstm, db 0x98, "Locomotora de Vapor", 0
def txtltwoccdsl, db 0x98, "Locomotora Diésel", 0
def txtltwoccelc, db 0x98, "Locomotora Eléctrica", 0
def txtltwoccmor, db 0x98, "Locomotora Monorail", 0
def txtltwoccmgv, db 0x98, "Locomotora Maglev", 0
def txtltwoccdmu, db 0x98, "Unidad Múltiple Diésel", 0
def txtltwoccemu, db 0x98, "Unidad Múltiple Eléctrica", 0
def txtltwoccpaw, db 0x98, "Vagones de pasajeros", 0
def txtltwoccfrw, db 0x98, "Vagones de mercancias", 0
def txtltwoccbus, db 0x98, "Autobús", 0
def txtltwocctrm, db 0x98, "Tramvía", 0
def txtltwocctrk, db 0x98, "Camión", 0
def txtltwoccpsh, db 0x98, "Barco de pasajeros", 0
def txtltwoccfsh, db 0x98, "Barco mercante", 0
def txtltwoccsap, db 0x98, "Avión regional", 0
def txtltwocclap, db 0x98, "Avión expreso", 0
def txtltwoccfrp, db 0x98, "Avión de carga", 0
def txtltwocchel, db 0x98, "Helicóptero", 0
def txtltwocclr1, db 0x94, "Primario", 0
def txtltwocclr2, db 0x94, "Secundario", 0

def steepslopes, db "las cuestas escarpadas no satisfacen", 0
def landhigherbridgehead, db "el terreno bajo el puente es más alto que las cabeceras del puente", 0

def grfhelpercaption, db 0x94,"Ayudante para los autores de GRF",0
def grfhelper_displxrelyrel, db 0x94,"Puntero: ",0x7E," xrel: ",0x7C," yrel: ",0x7C,0
def textsprite, db 0x98,"Puntero",0

def airporttype, db 0x98, "Airport Type",0
def unnamedairporttype, db "(Unnamed type)",0

def hotkeylistdos, db "xqwe!",0x22,"$%t&1234567890'",0xa1,1eh,5ch,0
def hotkeylistwin, db "xqwe!",0x22,0xb7,"$t%1234567890'",0xa1,0xba,0xe7,0

def txtclonedepotbutton, db 0x98, "Clone Train", 0
def txtclonetooltip, db 0x98, "Allows you to clone a train", 0
def txtcloneerrortop, db 0x94, "Cannot clone train consist", 0
def txtcloneerror1, db 0x94, "Not a company train", 0
def txtcloneerror2, db 0x94, "Vehicle in consist is not available anymore", 0
def txtcloneerror3, db 0x94, "No engine head at the start of the consist", 0
def txtcloneerror4, db 0x94, "Not a rail vehicle", 0
def txtcloneerror5, db 0x94, "Unknown reason", 0

def last
