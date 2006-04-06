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
; 	- add one here, before the "last" entry
;		entry <entryname>
;	- add the text for each language, prefixed with a
;	  letter for the language name and an underscore.
;	  These texts must be within their respective language
;	  block.  Example:
;		a_<entryname> db "Hello!"
;		g_<entryname> db "Hallo!"
;		f_<entryname> db "Bonjour!"
;	- all text must use the iso-8859-1 codepage
;	- then use it in the assembly code with ourtext(<entryname>)
;
;
; Note: adding, removing or changing the order of entries here will invalidate
;	all ttdpttxt.dat files, so only make changes if they're really
;	necessary

	entry bribetext
	entry bribedesc
	entry bribefailed
	entry headingfor
	entry headingfordepot1
	entry headingfordepot2
	entry headingfordepot3
	entry headingfordepot4
	entry withsignals
	entry wplainsignals
	entry wpresignals
	entry wpresigexits
	entry wprecombined
	entry presigautomatic
	entry presigmanual
	entry pathbasedauto
	entry pathbasedmanual

	entry vehmulttoolow
	entry rchunknotloaded
	entry loadgame
	entry gotodepot
	entry gotodepotonly

	; must be order train, road, ship, air
	entry gototraindepot
	entry gotoroaddepot
	entry gotoshipdepot
	entry gotoairdepot

	entry routethrough
	entry routenonstopthrough

	entry vehobsolete

	entry cannotcheat
	entry cheatinvalidparm
	entry cheatunknown
	entry cheatobsolete1
	entry cheatobsolete2
	entry nostationhere

	entry managedby1
	entry managedby2

	entry manage

	entry engineinfo1
	entry wagonpower
	entry engineinfo2
	entry wagoninfo
	entry newwagoninfo
	entry wagonspeedlimit
	entry refittableto
	entry refittabletoallbut
	entry refittabletoall

	entry railwaywagon
	entry monorailwagon
	entry maglevwagon

	entry ufodestroyed

	entry rvweightinfo
	entry rvweightpurchasewindow

	entry grfloaderror
	entry toomanysprites
	entry outofmemory
	entry wronggrfversion
	entry toomanyspritestotal
	entry filenotfound
	entry invalidsprite
	entry notttdpatchgrf
	entry grferror
	entry grfwarning
	entry grfneedspatchversion
	entry grfneedsdoswin
	entry grfwantsswitch
	entry grfinvalidparam
	entry grfconflict

	entry grfstatcaption
	entry grfstatapply
	entry grfstatreset
	entry grfinfotext
	entry grflisthint
	entry grfapplyhint
	entry grfresethint
	entry grfstatusmenu
	entry initialgrfsettings
	entry initialgrfsettingshint

	entry grfstatgeninfo1
	entry grfstatgeninfo2
	entry grfstatgeninfo3
	entry grfstatgeninfo4
	entry grfstatmax

	entry elecrailconstitle
	entry elecrailconsmenu

	entry lmilloutoftrees

	entry eurointroduced

	entry curr_HUF
	entry curr_PLN
	entry curr_ATS
	entry curr_BEF
	entry curr_DKK
	entry curr_FIM
	entry curr_GRD
	entry curr_CHF
	entry curr_NLG
	entry curr_ITL
	entry curr_SEK
	entry curr_RUB
	entry curr_EUR

	entry townlastmonthaccepted

	entry aircraftcleared
	entry zeppelincleared
	entry traincleared

	entry endofsharedorders

	entry resetorders
	entry toggleservice
	entry resethint
	entry servicehint

	entry nosort
	entry sortconsistnum
	entry sortprofit
	entry sortlastprofit
	entry sortage
	entry sortmaxspeed
	entry sortreliability
	entry sortcargo
	entry sorthint

	entry performance

	entry vehiclelost

	entry wrongrailtype

	entry neterror1
	entry neterror2
	entry desynch1
	entry desynch2

	entry refitvehicle
	entry refitcargohint
	entry refitbuttonhint

	entry cantbuildcanalhere

	entry fundprospecting
	entry buildindustry
	entry fundingfailed
	entry cannotfundprospecting

	entry newtrainindepot
	entry newrvindepot
	entry newshipindepot
	entry newaircraftinhangar
	entry newvehold
	entry newvehveryold
	entry newvehveryveryold
	entry newvehiclelost
	entry newcantreverse

	entry txtetoolboxmenu
	entry txtetoolbox
	entry txtetoolbox_tsigns
	entry txtetoolbox_tsignstrans
	entry txtetoolbox_tsignsold

	entry txtetoolbox_dsize
	entry txtetoolbox_d8
	entry txtetoolbox_d10
	entry txtetoolbox_d12
	entry txtetoolbox_d14
	entry txtetoolbox_d16
	entry txtetoolbox_d18
	entry txtetoolbox_d20

	entry txtetoolbox_depotalltrash
	entry txtetoolbox_on
	entry txtetoolbox_off
	entry txtetoolbox_saveinsavegame
	entry txtetoolbox_usedefaultinsave
	entry txtetoolbox_saveasdefault
	entry txtetoolbox_resetdefaultsizes

	entry none
	entry low
	entry normal
	entry high

	entry defaultstation
	entry stationnumdefault
	entry stationclassdefault

	entry unnamedtownnamestyle

	entry newshistory
	entry messagesettings
	entry messages

	entry cantreverse

	entry grflanguage

	entry sizertooltip
	entry stickytooltip

	entry rcw_railway
	entry rcw_signaltype
	entry rcw_semaphores
	entry rcw_lights
	entry rcw_automatic
	entry rcw_normal
	entry rcw_entry
	entry rcw_exit
	entry rcw_combo
	entry rcw_nopbs
	entry rcw_pbs
	entry rcw_tracks
	entry rcw_length
	entry rcw_drag
	entry rcw_class
	entry rcw_type
	entry rcw_accepts

	entry outofdynmem
	entry cantresize

	entry grftextnotfound

	entry newindubuildindustry
	entry newindufundprospecting
	entry newinduproduces
	entry toomanyindustries

	entry newindulist_tooltip
	entry newinduinfo_tooltip
	entry newindubuild_tooltip
	entry newinduprospect_tooltip

	entry newindu_cargowaiting

	entry warning_notowns

	entry localplayer
	entry remoteplayer

	entry multiplayer
	entry multiplayer_tooltip

	entry patchsnd_dll_notfound

	entry statistics
	entry statistics_white
	entry totalcargo

	entry landareainfoheight

	; the following two should probably remain the last entries
	; because they aren't really text, but rather a list of key codes

	entry hotkeylistdos
	entry hotkeylistwin	; must immediately follow hotkeylistdos

; "last" always must be the last entry, as a guard entry

	entry last


; -----------------------------------
;	Language data
; -----------------------------------


; **************
;    American
; **************

newlanguage american,a,2,496543,1695744

a_bribetext db "Bribe the local authority",0

a_bribedesc db 94h,80h,13,90h,"  "
	db "Bribe the local authority to increase your rating, "
	db "at the risk of a severe penalty if caught."
	db 13,"  Cost: ",7fh,0

a_bribefailed db 94h,"Your attempted bribery has been discovered by a regional investigator.",0

a_headingfor db 95h,80h,", ",84h,0
a_headingfordepot1 db 95h,80h," Train Depot, ", 84h,0
a_headingfordepot2 db 95h,80h," Road Depot, ", 84h,0
a_headingfordepot3 db 95h,80h," Ship Depot, ", 84h,0
a_headingfordepot4 db 95h,80h," Hangar, ", 84h,0

a_withsignals db "Railroad track with ",80h," (",80h,")",0
a_wplainsignals db "plain signals",0
a_wpresignals db "pre-signals",0
a_wpresigexits db "pre-signal exits",0
a_wprecombined db "combined signals",0
a_presigautomatic db "automatic",0
a_presigmanual db "manual",0
a_pathbasedauto db "automatic, path-based",0
a_pathbasedmanual db "manual, path-based",0

a_vehmulttoolow db 94h,"Warning: Game saved with vehicle multiplier ",7eh,". "
		db " Removed ",7eh," vehicles in ",7eh," consists and ",7eh," special objects.",0

a_rchunknotloaded db 94h,"Warning: Game uses some features of TTDPatch "
		db "that are disabled or not present in this version. Data may be lost.",0

a_loadgame db "Load game",0

a_gotodepot db "Go to ",80h,0
a_gotodepotonly db "Service at ",80h,0
a_gototraindepot db 80h," Train Depot",0
a_gotoroaddepot db 80h," Road Depot",0
a_gotoshipdepot db 80h," Ship Depot",0
a_gotoairdepot db 80h," Hangar",0
a_routethrough db "Route through ",0x80,0
a_routenonstopthrough db "Route non-stop through ",0x80,0

a_vehobsolete db 94h,"Model is obsolete and ",80h,0

a_cannotcheat db 94h,"Cannot carry out sign cheat action",0
a_cheatinvalidparm db 94h,"Invalid parameter",0
a_cheatunknown db 94h,"Unknown sign cheat",0
a_cheatobsolete1 db 94h,"Note: Cht: ",80h," is obsolete.",0
a_cheatobsolete2 db 94h,"Use Cht: ",80h," instead.",0
a_nostationhere db 94h,"No station here",0

a_managedby1 db " (temp. Player 1)",0
a_managedby2 db " (temp. Player 2)",0

a_manage db 98h,"Manage",0

a_engineinfo1	db 98h,"Cost: ",8ah,7fh
		db 98h,"   Weight: ",8ah,7ch,"t",13
		db 98h,"Max. Tractive Effort: ",8ah,7ch,"kN",13
		db 98h,"Speed: ",8ah,84h
		db 98h,"   Power: ",8ah,7ch,"hp",0
a_wagonpower	db 98h,"Powered Wagons: ",8ah,"+",7ch,"hp"
		db 98h,"   Weight: ",8ah,"+",7dh,"t",0
a_engineinfo2	db 98h,"Running Cost: ",8ah,7fh,"/yr",13
		db 98h,"Capacity: ",8ah,80h," ",80h,13
		db 98h,"Designed: ",8ah,7eh
		db 98h,"   Life: ",8ah,7ch," years",13
		db 98h,"Max. Reliability: ",8ah,7dh,"%",0
a_wagoninfo	db 98h,"Cost: ",8ah,7fh,13
		db 98h,"Weight: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacity: ",8ah,80h," ",80h,0
a_newwagoninfo db 98h,"Cost: ",7fh,
	db "    Weight: ",7ch,"t",13
	db "Capacity: ",80h," ",80h,0
a_wagonspeedlimit db 98h,13,"Max. Speed: ",80h,84h,0
a_refittableto db 98h,"Refittable to: ",8ah,80h,0
a_refittabletoallbut db 98h,"Refittable to: ",8ah,"All but ",80h,0
a_refittabletoall db 98h,"Refittable to: ",8ah,"All cargo types",0

a_railwaywagon db "railroad wagon",0
a_monorailwagon db "monorail wagon",0
a_maglevwagon db "maglev wagon",0

a_ufodestroyed db 98h,0fh,"'UFO' destroyed in huge explosion near ",80h,"!",0

a_rvweightinfo db 98h,"Weight: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Power: ", 95h,7ch,"hp   "
	db 80h,0

a_rvweightpurchasewindow db 98h,"Cost: ", 8ah, 7fh
	db 98h,"   Speed: ", 8ah, 84h, 13
	db 98h,"Running Cost: ", 8ah, 7fh, "/yr", 13
	db 98h,"Power: ", 8ah, 7ch,"hp"
	db 98h,"   Weight: ", 8ah, 7dh,".",7dh,"t", 13
	db 98h,"Capacity: ", 8ah, 80h, 13
	db 98h,"Designed: ", 8ah, 7eh
	db 98h,"   Life: ", 8ah, 7ch, " years",13
	db 98h,"Max. Reliability: ", 8ah, 7dh, "%", 0

a_grfloaderror db 94h,"Error loading new graphics:",0
a_toomanysprites db 94h,"More sprites than specified (file ",80h,").",0
a_outofmemory db 94h,"Out of memory (file ",80h,").",0
a_wronggrfversion db 94h,"Wrong .grf version (file ",80h,").",0
a_toomanyspritestotal db 94h,"Cannot load more sprites (from file ",80h,").",0
a_filenotfound db 94h,"File ",22h,80h,22h," not found.",0
a_invalidsprite db 94h, "File ", 22h,80h,22h," has invalid sprite #",7ch," (code ",7ch,"/",7ch,").",0
a_notttdpatchgrf db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
a_grferror db 94h, "Error: ", 80h,0
a_grfwarning db 94h, "Warning: ", 80h,0
a_grfneedspatchversion db 80h, " requires at least TTDPatch version ", 80h, 0
a_grfneedsdoswin db 80h, " is for the ", 80h, " version of TTD.", 0
a_grfwantsswitch db 80h, " is designed to be used with ", 80h, 0
a_grfinvalidparam db "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
a_grfconflict db 94h,"GRF conflict with ", 80h, 0

a_grfstatcaption db 0x94,"GRF Status", 0
a_grfstatapply db 0x98,"Apply", 0
a_grfstatreset db 0x98,"Default", 0
a_grfinfotext db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

a_grflisthint db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
a_grfapplyhint db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
a_grfresethint db 0x98,"Reset all graphics settings to the default and apply",0

a_grfstatusmenu db "New graphics status", 0
a_initialgrfsettings db 0x98, "Initial graphics settings", 0
a_initialgrfsettingshint db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

a_grfstatgeninfo1 db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
a_grfstatgeninfo2	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
a_grfstatgeninfo3	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
a_grfstatgeninfo4	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
a_grfstatmax db " (",0x7b," max)",0

a_elecrailconstitle db 94h,"Electrified Railroad Construction",0
a_elecrailconsmenu db "Electr. railroad construction",0

a_lmilloutoftrees db 98h,0fh,80h," ",80h," ran out of nearby trees!",0

a_eurointroduced db 98h,0fh,"Monetary union!",0dh,0dh,"European countries switch from national currencies to Euro!",0

a_curr_HUF db "Hungarian Forint (Ft)",0,0,0,0,0,0
a_curr_PLN db "Polish Zloty (zl)",0,0,0,0,0,0
a_curr_ATS db "Austrian Shilling (ATS)",0,0,0,0,0,0
a_curr_BEF db "Belgian Franc (BEF)",0,0,0,0,0,0
a_curr_DKK db "Danish Krone (DKK)",0,0,0,0,0,0
a_curr_FIM db "Finnish Markka (FIM)",0,0,0,0,0,0
a_curr_GRD db "Greek Drachma (GRD)",0,0,0,0,0,0
a_curr_CHF db "Swiss Franc (CHF)",0,0,0,0,0,0
a_curr_NLG db "Dutch Guilder (NLG)",0,0,0,0,0,0
a_curr_ITL db "Italian Lira (ITL)",0,0,0,0,0,0
a_curr_SEK db "Swedish Krona (SEK)",0,0,0,0,0,0
a_curr_RUB db "Russian Rubel (RUB)",0,0,0,0,0,0
a_curr_EUR db "Euro (",0x9E,")",0,0,0,0,0,0

a_townlastmonthaccepted db 98h,"Cargo accepted last month at all stations:",0

a_aircraftcleared db 98h,0fh,"Remnants of the recent plane crash have been cleared from ",80h,"!",0
a_zeppelincleared db 98h,0fh,"Remnants of the recent Zeppelin crash have been cleared from ",80h,"!",0
a_traincleared db 98h,0fh,"Remnants of the recent train crash have been cleared near ",80h,"!",0

a_endofsharedorders db 1,0xa,"- - End of shared orders (",85h,7ch,") - -",0

a_resetorders db 0x98,"Reset",0
a_toggleservice db 0x98,"Service",0
a_resethint db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
a_servicehint db 0x98,"Makes the vehicle skip this order unless it's time for service",0

a_nosort db "Unsorted",0
a_sortconsistnum db "Number",0
a_sortprofit db "Profit",0
a_sortlastprofit db "Last year profit",0
a_sortage db "Age",0
a_sortmaxspeed db "Max. Speed",0
a_sortreliability db "Reliability",0
a_sortcargo db "Cargo",0
a_sorthint db "Select sorting method of vehicles in this list",0

a_performance db " (Perf. score: ",0x7e,")",0

a_vehiclelost db 0x94,0x80," ",0x7c," seems to be lost",0

a_wrongrailtype db 94h,"...incompatible rail types",0

a_neterror1 db 0x94,"Network error!",0
a_neterror2 db 0x94,"Games disconnected!",0

a_desynch1 db 0x94,"Games out of sync!",0
a_desynch2 db 0x94,"Use sv2flip or reload the last save!",0

a_refitvehicle db 0x98,"Refit vehicle",0
a_refitcargohint db 0x98,"Select type of cargo for vehicle to carry",0
a_refitbuttonhint db 0x98,"Refit vehicle to carry highlighted cargo type",0

a_cantbuildcanalhere db 0x94, "Can't build canals/locks here", 0

a_fundprospecting db 0x94, "Fund prospecting", 0
a_buildindustry db 0x94, "Build industry", 0
a_fundingfailed db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
a_cannotfundprospecting db 0x94, "Cannot fund prospecting", 0

a_newtrainindepot db 0
a_newrvindepot db 0
a_newshipindepot db 0
a_newaircraftinhangar db 0
a_newvehold db 0
a_newvehveryold db 0
a_newvehveryveryold db 0
a_newvehiclelost db 0
a_newcantreverse db 0

a_txtetoolboxmenu db "Enhanced GUI settings", 0
a_txtetoolbox db 0x94, "Enhanced GUI Settings", 0
a_txtetoolbox_tsigns db 0x98, "Station signs", 0
a_txtetoolbox_tsignstrans db "Transparent",0
a_txtetoolbox_tsignsold db "TTD Style",0

a_txtetoolbox_dsize db 0x98, "Depot Size",0
a_txtetoolbox_d8 db "Depot  8  (4)",0
a_txtetoolbox_d10 db "Depot 10  (5)",0
a_txtetoolbox_d12 db "Depot 12  (6)",0
a_txtetoolbox_d14 db "Depot 14  (7)",0
a_txtetoolbox_d16 db "Depot 16  (8)",0
a_txtetoolbox_d18 db "Depot 18  (9)",0
a_txtetoolbox_d20 db "Depot 20  (10)",0

a_txtetoolbox_depotalltrash db 0x98, "Depot allTrash",0
a_txtetoolbox_on db "On",0
a_txtetoolbox_off db "Off",0
a_txtetoolbox_saveinsavegame db 0x98, "Stick Settings",0
a_txtetoolbox_usedefaultinsave db 0x98, "Unstick",0
a_txtetoolbox_saveasdefault db 0x98, "Save as Default",0
a_txtetoolbox_resetdefaultsizes db 0x98, "Reset default sizes",0

a_none db "None", 0
a_low  db "Low", 0
a_normal db "Normal", 0
a_high db "High", 0

a_defaultstation db "(default)",0
a_stationnumdefault db "Station ",0x81,0xff,0xC7,0
a_stationclassdefault db "Station class ",0x81,0xff,0xC7,0


a_unnamedtownnamestyle db "(Unnamed style)",0

a_newshistory db "Message history",0
a_messagesettings db "Message settings",0
a_messages db 0x94, "Messages",0

a_cantreverse db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

a_grflanguage db "0",0

a_sizertooltip db 0x98, "Drag to resize the window",0
a_stickytooltip db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0
	
a_rcw_railway db 0x94, "Railway", 0
a_rcw_signaltype db 0x98, "Signal type", 0
a_rcw_semaphores db "Semaphores", 0
a_rcw_lights db "Lights", 0
a_rcw_automatic db "Automatic", 0
a_rcw_normal db "Normal", 0
a_rcw_entry db "Entry", 0
a_rcw_exit db "Exit", 0
a_rcw_combo db "Combo", 0
a_rcw_nopbs db "Not path based", 0
a_rcw_pbs db "Path based", 0
a_rcw_tracks db 0x98, "Tracks: ", 0x8E, 0x80, 0
a_rcw_length db 0x98, "Length: ", 0x8E, 0x80, 0
a_rcw_drag db "Drag", 0
a_rcw_class db 0x98, "Class:", 0
a_rcw_type db 0x98, "Type:", 0
a_rcw_accepts db 0x98, "Accepts:          ", 0x8A, 0

a_outofdynmem db 0x94, "Out of dynamic memory", 0
a_cantresize db 0x94, "Can't resize window...", 0

a_grftextnotfound db "-- GRF text not found! --",0

a_newindubuildindustry db "Build industry",0
a_newindufundprospecting db "Fund prospecting for industry",0
a_newinduproduces db 0x98, "Produces: ", 0x90, 0x80, 0
a_toomanyindustries db 94h,"Too many industries on map.", 0

a_newindulist_tooltip db 0x98,"List of available industry types - click on the one you want to build",0
a_newinduinfo_tooltip db 0x98,"Information about the currently selected industry type",0
a_newindubuild_tooltip db 0x98,"Build the industry",0
a_newinduprospect_tooltip db 0x98,"Fund prospecting to find resources for this industry",0

a_newindu_cargowaiting db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

a_warning_notowns db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

a_localplayer db " (local player)",0
a_remoteplayer db " (remote player)",0

a_multiplayer db 0x98,"Multiplayer",0
a_multiplayer_tooltip db 0x98,"Select multiplayer game",0

a_patchsnd_dll_notfound db 94h,"Cannot load patchsnd.dll, new sounds disabled.", 0

a_statistics db 0x98, "Statistics",0
a_statistics_white db 0x94, "Statistics",0
a_totalcargo db 0x8E, "Total amount of cargo transported",0

a_landareainfoheight db 0x98,"Altitude: ",0x95,0x7B,0

a_hotkeylistdos db "xqwe!@#$t%1234567890-=",1eh,5ch,0
a_hotkeylistwin db "xqwe!@#$t%1234567890-=`",5ch,0

a_last equ $

secondlanguage

; **************
;    English
; **************

newlanguage english,e,2,496601,1696256
; for the most part same as american...

e_bribetext db "Bribe the local authority",0

e_bribedesc db 94h,80h,13,90h,"  "
	db "Bribe the local authority to increase your rating, "
	db "at the risk of a severe penalty if caught."
	db 13,"  Cost: ",7fh,0

e_bribefailed db 94h,"Your attempted bribery has been discovered by a regional investigator.",0

e_headingfor db 95h,80h,", ",84h,0
e_headingfordepot1 db 95h,80h," Train Depot, ", 84h,0
e_headingfordepot2 db 95h,80h," Road Depot, ", 84h,0
e_headingfordepot3 db 95h,80h," Ship Depot, ", 84h,0
e_headingfordepot4 db 95h,80h," Hangar, ", 84h,0

e_withsignals db "Railway track with ",80h," (",80h,")",0
e_wplainsignals db "plain signals",0
e_wpresignals db "pre-signals",0
e_wpresigexits db "pre-signal exits",0
e_wprecombined db "combined signals",0
e_presigautomatic db "automatic",0
e_presigmanual db "manual",0
e_pathbasedauto db "automatic, path-based",0
e_pathbasedmanual db "manual, path-based",0

e_vehmulttoolow db 94h,"Warning: Game saved with vehicle multiplier ",7eh,". "
		db " Removed ",7eh," vehicles in ",7eh," consists and ",7eh," special objects.",0

e_rchunknotloaded db 94h,"Warning: Game uses some features of TTDPatch "
		db "that are disabled or not present in this version. Data may be lost.",0

e_loadgame db "Load game",0

e_gotodepot db "Go to ",80h,0
e_gotodepotonly db "Service at ",80h,0
e_gototraindepot db 80h," Train Depot",0
e_gotoroaddepot db 80h," Road Depot",0
e_gotoshipdepot db 80h," Ship Depot",0
e_gotoairdepot db 80h," Hangar",0
e_routethrough db "Route through ",0x80,0
e_routenonstopthrough db "Route non-stop through ",0x80,0

e_vehobsolete db 94h,"Model is obsolete and ",80h,0

e_cannotcheat db 94h,"Cannot carry out sign cheat action",0
e_cheatinvalidparm db 94h,"Invalid parameter",0
e_cheatunknown db 94h,"Unknown sign cheat",0
e_cheatobsolete1 db 94h,"Note: Cht: ",80h," is obsolete.",0
e_cheatobsolete2 db 94h,"Use Cht: ",80h," instead.",0
e_nostationhere db 94h,"No station here",0

e_managedby1 db " (temp. Player 1)",0
e_managedby2 db " (temp. Player 2)",0

e_manage db 98h,"Manage",0

e_engineinfo1	db 98h,"Cost: ",8ah,7fh
		db 98h,"   Weight: ",8ah,7ch,"t",13
		db 98h,"Max. Tractive Effort: ",8ah,7ch,"kN",13
		db 98h,"Speed: ",8ah,84h
		db 98h,"   Power: ",8ah,7ch,"hp",0
e_wagonpower	db 98h,"Powered Wagons: ",8ah,"+",7ch,"hp"
		db 98h,"   Weight: ",8ah,"+",7dh,"t",0
e_engineinfo2	db 98h,"Running Cost: ",8ah,7fh,"/yr",13
		db 98h,"Capacity: ",8ah,80h," ",80h,13
		db 98h,"Designed: ",8ah,7eh
		db 98h,"   Life: ",8ah,7ch," years",13
		db 98h,"Max. Reliability: ",8ah,7dh,"%",0
e_wagoninfo	db 98h,"Cost: ",8ah,7fh,13
		db 98h,"Weight: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacity: ",8ah,80h," ",80h,0
e_newwagoninfo db 98h,"Cost: ",7fh,
	db "    Weight: ",7ch,"t",13
	db "Capacity: ",80h," ",80h,0
e_wagonspeedlimit db 98h,13,"Max. Speed: ",80h,84h,0
e_refittableto db 98h,"Refittable to: ",8ah,80h,0
e_refittabletoallbut db 98h,"Refittable to: ",8ah,"All but ",80h,0
e_refittabletoall db 98h,"Refittable to: ",8ah,"All cargo types",0

e_railwaywagon db "railway wagon",0
e_monorailwagon db "monorail wagon",0
e_maglevwagon db "maglev wagon",0

e_ufodestroyed db 98h,0fh,"'UFO' destroyed in huge explosion near ",80h,"!",0

e_rvweightinfo db 98h,"Weight: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Power: ", 95h,7ch,"hp   "
	db 80h,0

e_rvweightpurchasewindow db 98h,"Cost: ", 8ah, 7fh
	db 98h,"   Speed: ", 8ah, 84h, 13
	db 98h,"Running Cost: ", 8ah, 7fh, "/yr", 13
	db 98h,"Power: ", 8ah, 7ch,"hp"
	db 98h,"   Weight: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Capacity: ", 8ah, 80h, 13
	db 98h,"Designed: ", 8ah, 7eh
	db 98h,"   Life: ", 8ah, 7ch, " years",13
	db 98h,"Max. Reliability: ", 8ah, 7dh, "%", 0

e_grfloaderror db 94h,"Error loading new graphics:",0
e_toomanysprites db 94h,"More sprites than specified (file ",80h,").",0
e_outofmemory db 94h,"Out of memory (file ",80h,").",0
e_wronggrfversion db 94h,"Wrong .grf version (file ",80h,").",0
e_toomanyspritestotal db 94h,"Cannot load more sprites (from file ",80h,").",0
e_filenotfound db 94h,"File ",22h,80h,22h," not found.",0
e_invalidsprite db 94h, "File ", 22h,80h,22h," has invalid sprite #",7ch," (code ",7ch,"/",7ch,").",0
e_notttdpatchgrf db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
e_grferror db 94h, "Error: ", 80h,0
e_grfwarning db 94h, "Warning: ", 80h,0
e_grfneedspatchversion db 94h, 80h, " requires at least TTDPatch version ", 80h, 0
e_grfneedsdoswin db 94h, 80h, " is for the ", 80h, " version of TTD.", 0
e_grfwantsswitch db 94h, 80h, " is designed to be used with ", 80h, 0
e_grfinvalidparam db 94h, "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
e_grfconflict db 94h,"GRF conflict with ", 80h, 0

e_grfstatcaption db 0x94,"GRF Status", 0
e_grfstatapply db 0x98,"Apply", 0
e_grfstatreset db 0x98,"Default", 0
e_grfinfotext db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

e_grflisthint db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
e_grfapplyhint db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
e_grfresethint db 0x98,"Reset all graphics settings to the default and apply",0

e_grfstatusmenu db "New graphics status", 0
e_initialgrfsettings db 0x98, "Initial graphics settings", 0
e_initialgrfsettingshint db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

e_grfstatgeninfo1 db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
e_grfstatgeninfo2	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
e_grfstatgeninfo3	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
e_grfstatgeninfo4	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
e_grfstatmax db " (",0x7b," max)",0

e_elecrailconstitle db 94h,"Electrified Railway Construction",0
e_elecrailconsmenu db "Electr. railway construction",0

e_lmilloutoftrees db 98h,0fh,80h," ",80h," ran out of nearby trees!",0

e_eurointroduced db 98h,0fh,"Monetary union!",0dh,0dh,"European countries switch from national currencies to Euro!",0

e_curr_HUF db "Hungarian Forint (Ft)",0,0,0,0,0,0
e_curr_PLN db "Polish Zloty (zl)",0,0,0,0,0,0
e_curr_ATS db "Austrian Shilling (ATS)",0,0,0,0,0,0
e_curr_BEF db "Belgian Franc (BEF)",0,0,0,0,0,0
e_curr_DKK db "Danish Krone (DKK)",0,0,0,0,0,0
e_curr_FIM db "Finnish Markka (FIM)",0,0,0,0,0,0
e_curr_GRD db "Greek Drachma (GRD)",0,0,0,0,0,0
e_curr_CHF db "Swiss Franc (CHF)",0,0,0,0,0,0
e_curr_NLG db "Dutch Guilder (NLG)",0,0,0,0,0,0
e_curr_ITL db "Italian Lira (ITL)",0,0,0,0,0,0
e_curr_SEK db "Swedish Krona (SEK)",0,0,0,0,0,0
e_curr_RUB db "Russian Rubel (RUB)",0,0,0,0,0,0
e_curr_EUR db "Euro (",0x9E,")",0,0,0,0,0,0

e_townlastmonthaccepted db 98h,"Cargo accepted last month at all stations:",0

e_aircraftcleared db 98h,0fh,"Remnants of the recent plane crash have been cleared from ",80h,"!",0
e_zeppelincleared db 98h,0fh,"Remnants of the recent Zeppelin crash have been cleared from ",80h,"!",0
e_traincleared db 98h,0fh,"Remnants of the recent train crash have been cleared near ",80h,"!",0

e_endofsharedorders db 1,0xa,"- - End of shared orders (",85h,7ch,") - -",0

e_resetorders db 0x98,"Reset",0
e_toggleservice db 0x98,"Service",0
e_resethint db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
e_servicehint db 0x98,"Makes the vehicle skip this order unless it's time for service",0

e_nosort db "Unsorted",0
e_sortconsistnum db "Number",0
e_sortprofit db "Profit",0
e_sortlastprofit db "Last year profit",0
e_sortage db "Age",0
e_sortmaxspeed db "Max. Speed",0
e_sortreliability db "Reliability",0
e_sortcargo db "Cargo",0
e_sorthint db 0x98,"Select sorting method of vehicles in this list",0

e_performance db " (Perf. score: ",0x7e,")",0

e_vehiclelost db 0x94,0x80," ",0x7c," seems to be lost",0

e_wrongrailtype db 94h,"...incompatible rail types",0

e_neterror1 db 0x94,"Network error!",0
e_neterror2 db 0x94,"Games disconnected!",0

e_desynch1 db 0x94,"Games out of sync!",0
e_desynch2 db 0x94,"Use sv2flip or reload the last save!",0

e_refitvehicle db 0x98,"Refit vehicle",0
e_refitcargohint db 0x98,"Select type of cargo for vehicle to carry",0
e_refitbuttonhint db 0x98,"Refit vehicle to carry highlighted cargo type",0

e_cantbuildcanalhere db 0x94, "Can't build canals/locks here", 0

e_fundprospecting db 0x94, "Fund prospecting", 0
e_buildindustry db 0x94, "Build industry", 0
e_fundingfailed db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
e_cannotfundprospecting db 0x94, "Cannot fund prospecting", 0

e_newtrainindepot db 0
e_newrvindepot db 0
e_newshipindepot db 0
e_newaircraftinhangar db 0
e_newvehold db 0
e_newvehveryold db 0
e_newvehveryveryold db 0
e_newvehiclelost db 0
e_newcantreverse db 0

e_txtetoolboxmenu db "Enhanced GUI settings", 0
e_txtetoolbox db 0x94, "Enhanced GUI Settings", 0
e_txtetoolbox_tsigns db 0x98, "Station signs", 0
e_txtetoolbox_tsignstrans db "Transparent",0
e_txtetoolbox_tsignsold db "TTD Style",0

e_txtetoolbox_dsize db 0x98, "Depot Size",0
e_txtetoolbox_d8 db "Depot  8  (4)",0
e_txtetoolbox_d10 db "Depot 10  (5)",0
e_txtetoolbox_d12 db "Depot 12  (6)",0
e_txtetoolbox_d14 db "Depot 14  (7)",0
e_txtetoolbox_d16 db "Depot 16  (8)",0
e_txtetoolbox_d18 db "Depot 18  (9)",0
e_txtetoolbox_d20 db "Depot 20  (10)",0

e_txtetoolbox_depotalltrash db 0x98, "Depot allTrash",0
e_txtetoolbox_on db "On",0
e_txtetoolbox_off db "Off",0
e_txtetoolbox_saveinsavegame db 0x98, "Stick Settings",0
e_txtetoolbox_usedefaultinsave db 0x98, "Unstick",0
e_txtetoolbox_saveasdefault db 0x98, "Save as Default",0
e_txtetoolbox_resetdefaultsizes db 0x98, "Reset default sizes",0

e_none db "None", 0
e_low  db "Low", 0
e_normal db "Normal", 0
e_high db "High", 0

e_defaultstation db "(default)",0
e_stationnumdefault db "Station ",0x81,0xff,0xC7,0
e_stationclassdefault db "Station class ",0x81,0xff,0xC7,0

e_unnamedtownnamestyle db "(Unnamed style)",0

e_newshistory db "Message history",0
e_messagesettings db "Message settings",0
e_messages db 0x94, "Messages",0
	
e_cantreverse db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

e_grflanguage db "0",0

e_sizertooltip db 0x98, "Drag to resize the window",0
e_stickytooltip db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0

e_rcw_railway db 0x94, "Railway", 0
e_rcw_signaltype db 0x98, "Signal type", 0
e_rcw_semaphores db "Semaphores", 0
e_rcw_lights db "Lights", 0
e_rcw_automatic db "Automatic", 0
e_rcw_normal db "Normal", 0
e_rcw_entry db "Entry", 0
e_rcw_exit db "Exit", 0
e_rcw_combo db "Combo", 0
e_rcw_nopbs db "Not path based", 0
e_rcw_pbs db "Path based", 0
e_rcw_tracks db 0x98, "Tracks: ", 0x8E, 0x80, 0
e_rcw_length db 0x98, "Length: ", 0x8E, 0x80, 0
e_rcw_drag db "Drag", 0
e_rcw_class db 0x98, "Class:", 0
e_rcw_type db 0x98, "Type:", 0
e_rcw_accepts db 0x98, "Accepts:                    ", 0x8A, 0

e_outofdynmem db 0x94, "Out of dynamic memory", 0
e_cantresize db 0x94, "Can't resize window...", 0

e_grftextnotfound db "-- GRF text not found! --",0

e_newindubuildindustry db "Build industry",0
e_newindufundprospecting db "Fund prospecting for industry",0
e_newinduproduces db 0x98, "Produces: ", 0x90, 0x80, 0
e_toomanyindustries db 94h,"Too many industries on map.", 0

e_newindulist_tooltip db 0x98,"List of available industry types - click on the one you want to build",0
e_newinduinfo_tooltip db 0x98,"Information about the currently selected industry type",0
e_newindubuild_tooltip db 0x98,"Build the industry",0
e_newinduprospect_tooltip db 0x98,"Fund prospecting to find resources for this industry",0

e_newindu_cargowaiting db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

e_warning_notowns db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

e_localplayer db " (local player)",0
e_remoteplayer db " (remote player)",0

e_multiplayer db 0x98,"Multiplayer",0
e_multiplayer_tooltip db 0x98,"Select multiplayer game",0

e_patchsnd_dll_notfound db 94h,"Cannot load patchsnd.dll, new sounds disabled.", 0

e_statistics db 0x98, "Statistics",0
e_statistics_white db 0x94, "Statistics",0
e_totalcargo db 0x8E, "Total amount of cargo transported",0

e_landareainfoheight db 0x98,"Altitude: ",0x95,0x7B,0

e_hotkeylistdos db "xqwe!",22h,0xa3,"$t%1234567890-=",1eh,5ch,0
e_hotkeylistwin db "xqwe!",22h,0xa3,"$t%1234567890-=~",5ch,0

e_last equ $


; **************
;     German
; **************

newlanguage german,g,2,499583,1699328

g_bribetext db "Stadtverwaltung bestechen",0

g_bribedesc db 94h,80h,13,90h
	db "Bestechen Sie die Stadtverwaltung für eine bessere "
	db "Bewertung, mit dem Risiko einer schweren Strafe falls "
	db "Sie erwischt werden."
	db 13,"  Kosten: ",7fh,0

g_bribefailed db 94h,"Ihr Bestechungsversuch wurde aufgedeckt durch eine staatliche Untersuchung.",0

g_headingfor db 95h,80h,", ",84h,0
g_headingfordepot1 db 95h,80h,"-Zugdepot, ", 84h,0
g_headingfordepot2 db 95h,80h," Fahrzeugdepot, ", 84h,0
g_headingfordepot3 db 95h,80h," Schiffswerft, ", 84h,0
g_headingfordepot4 db 95h,80h," Halle, ", 84h,0

g_withsignals db "Gleise mit ",80h," (",80h,")",0
g_wplainsignals db "normalen Signalen",0
g_wpresignals db "Vorsignalen",0
g_wpresigexits db "Vorsignalausfahrten",0
g_wprecombined db "kombinierten Signalen",0
g_presigautomatic db "automatisch",0
g_presigmanual db "manuell",0
g_pathbasedauto db "automatic, path-based",0
g_pathbasedmanual db "manual, path-based",0

g_vehmulttoolow db 94h,"Warnung: Spielstand wurde mit Fahrzeuganzahl-Faktor ",7eh," gespeichert. "
		db " ",7eh," Fahrzeuge in ",7eh," Einheiten und ",7eh," spezielle Objekte wurden entfernt.",0

g_rchunknotloaded db 94h,"Warning: Game uses some features of TTDPatch "
		db "that are disabled or not present in this version. Data may be lost.",0

g_loadgame db "Spiel laden",0

g_gotodepot db "Nach ",80h,0
g_gotodepotonly db "Wartung in ",80h,0
g_gototraindepot db 80h," Zugdepot",0
g_gotoroaddepot db 80h," Strassendepot",0
g_gotoshipdepot db 80h," Schiffswerft",0
g_gotoairdepot db 80h," Flugzeughalle",0
g_routethrough db "Route through ",0x80,0
g_routenonstopthrough db "Route non-stop through ",0x80,0

g_vehobsolete db 94h,"Model is obsolete and ",80h,0

g_cannotcheat db 94h,"Kann Schilder-Cheat nicht ausführen",0
g_cheatinvalidparm db 94h,"Ungültiger Parameter",0
g_cheatunknown db 94h,"Unbekannter Schilder-Cheat",0
g_cheatobsolete1 db 94h,"Achtung: Cht: ",80h," ist veraltet.",0
g_cheatobsolete2 db 94h,"Benutzen Sie stattdessen Cht: ",80h,".",0
g_nostationhere db 94h,"No station here",0

g_managedby1 db " (Spieler 1 temp.)",0
g_managedby2 db " (Spieler 2 temp.)",0

g_manage db 98h,"Verwalten",0

g_engineinfo1	db 98h,"Kosten: ",8ah,7fh
		db 98h,"   Gewicht: ",8ah,7ch,"t",13
		db 98h,"Max. Zugkraft: ",8ah,7ch,"kN",13
		db 98h,"Geschwindigkeit: ",8ah,84h
		db 98h,"   Leistung: ",8ah,7ch,"PS",0
g_wagonpower	db 98h,"Waggons mit Antrieb: ",8ah,"+",7ch,"PS"
		db 98h,"   Gewicht: ",8ah,"+",7dh,"t",0
g_engineinfo2	db 98h,"Betriebskosten: ",8ah,7fh,"/Jahr",13
		db 98h,"Kapazität: ",8ah,80h," ",80h,13
		db 98h,"Entwurf: ",8ah,7eh
		db 98h,"   Zeit: ",8ah,7ch," Jahre",13
		db 98h,"Max. Zuverlässigkeit: ",8ah,7dh,"%",0
g_wagoninfo	db 98h,"Kosten: ",8ah,7fh,13
		db 98h,"Gewicht: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Kapazität: ",8ah,80h," ",80h,0
g_newwagoninfo db 98h,"Kosten: ",7fh,
	db "    Gewicht: ",7ch,"t",13
	db "Kapazität: ",80h," ",80h,0
g_wagonspeedlimit db 98h,13,"Max. Speed: ",80h,84h,0
g_refittableto db 98h,"Refittable to: ",8ah,80h,0
g_refittabletoallbut db 98h,"Refittable to: ",8ah,"All but ",80h,0
g_refittabletoall db 98h,"Refittable to: ",8ah,"All cargo types",0

g_railwaywagon db "Waggon",0
g_monorailwagon db "Einschienenbahnwaggon",0
g_maglevwagon db "Schwebebahnwaggon",0

g_ufodestroyed db 98h,0fh,"'UFO' zerstört in großer Explosion bei ",80h,"!",0

g_rvweightinfo db 98h,"Gewicht: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Leistung: ", 95h,7ch,"PS   "
	db 80h,0

g_rvweightpurchasewindow db 98h,"Kosten: ", 8ah, 7fh
	db 98h,"   Geschwindigkeit: ", 8ah, 84h, 13
	db 98h,"Betriebskosten: ", 8ah, 7fh, "/Jahr", 13
	db 98h,"Leistung: ", 8ah, 7ch,"PS"
	db 98h,"   Gewicht: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Kapazität: ", 8ah, 80h, 13
	db 98h,"Entwurf: ", 8ah, 7eh
	db 98h,"   Zeit: ", 8ah, 7ch, " Jahre",13
	db 98h,"Max. Zuverlässigkeit: ", 8ah, 7dh, "%", 0

g_grfloaderror db 94h,"Fehler beim Laden der Grafiken:",0
g_toomanysprites db 94h,"Mehr Einträge als angegeben (Datei ",80h,").",0
g_outofmemory db 94h,"Zu wenig Speicher (Datei ",80h,").",0
g_wronggrfversion db 94h,"Falsche .grf Version (Datei ",80h,").",0
g_toomanyspritestotal db 94h,"Kann nicht mehr Sprites laden (ab Datei ",80h,").",0
g_filenotfound db 94h,"Datei ",80h," nicht gefunden.",0
g_invalidsprite db 94h, "Datei ", 22h,80h,22h," hat ungültiges Sprite #",7ch," (code ",7ch,"/",7ch,").",0
g_notttdpatchgrf db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
g_grferror db 94h, "Error: ", 80h,0
g_grfwarning db 94h, "Warning: ", 80h,0
g_grfneedspatchversion db 94h, 80h, " requires at least TTDPatch version ", 80h, 0
g_grfneedsdoswin db 94h, 80h, " is for the ", 80h, " version of TTD.", 0
g_grfwantsswitch db 94h, 80h, " is designed to be used with ", 80h, 0
g_grfinvalidparam db 94h, "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
g_grfconflict db 94h,"GRF conflict with ", 80h, 0

g_grfstatcaption db 0x94,"GRF Status", 0
g_grfstatapply db 0x98,"Apply", 0
g_grfstatreset db 0x98,"Default", 0
g_grfinfotext db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

g_grflisthint db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
g_grfapplyhint db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
g_grfresethint db 0x98,"Reset all graphics settings to the default and apply",0

g_grfstatusmenu db "New graphics status", 0
g_initialgrfsettings db 0x98, "Initial graphics settings", 0
g_initialgrfsettingshint db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

g_grfstatgeninfo1 db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
g_grfstatgeninfo2	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
g_grfstatgeninfo3	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
g_grfstatgeninfo4	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
g_grfstatmax db " (",0x7b," max)",0


g_elecrailconstitle db 94h,"Gleisbau mit Oberleitung",0
g_elecrailconsmenu db "Eisenbahnbau mit Oberleitung",0

g_lmilloutoftrees db 98h,0fh,80h," ",80h," stellt Produktion ein mangels Bäumen!",0

g_eurointroduced db 98h,0fh,"Währungsunion!",0dh,0dh,"Landeswährungen durch Euro ersetzt!",0

g_curr_HUF db "Ungarische Forint (Ft)",0,0,0,0,0,0
g_curr_PLN db "Polnische Zloty (zl)",0,0,0,0,0,0
g_curr_ATS db "Österreichische Schilling (ATS)",0,0,0,0,0,0
g_curr_BEF db "Belgische Franken (BEF)",0,0,0,0,0,0
g_curr_DKK db "Dänische Kronen (DKK)",0,0,0,0,0,0
g_curr_FIM db "Finnische Mark (FIM)",0,0,0,0,0,0
g_curr_GRD db "Griechische Drachmen (GRD)",0,0,0,0,0,0
g_curr_CHF db "Schweizer Franken (CHF)",0,0,0,0,0,0
g_curr_NLG db "Niederländische Gulden (NLG)",0,0,0,0,0,0
g_curr_ITL db "Italienische Lira (ITL)",0,0,0,0,0,0
g_curr_SEK db "Schwedische Kronen (SEK)",0,0,0,0,0,0
g_curr_RUB db "Russische Rubel (RUB)",0,0,0,0,0,0
g_curr_EUR db "Euro (",0x9E,")",0,0,0,0,0,0

g_townlastmonthaccepted db 98h,"Angelieferte Fracht im letzten Monat:",0

g_aircraftcleared db 98h,0fh,"Die Trümmer des Flugzeugabsturzes bei ",80h," sind nun geräumt worden.",0
g_zeppelincleared db 98h,0fh,"Die Trümmer des Zeppelinabsturzes bei ",80h," sind nun geräumt worden.",0
g_traincleared db 98h,0fh,"Die Trümmer des Zugzusammensstosses bei ",80h," sind nun geräumt worden.",0

g_endofsharedorders db 1,0xa,"- - End of shared orders (",85h,7ch,") - -",0

g_resetorders db 0x98,"Reset",0
g_toggleservice db 0x98,"Service",0
g_resethint db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
g_servicehint db 0x98,"Makes the vehicle skip this order unless it's time for service",0

g_nosort db "Unsorted",0
g_sortconsistnum db "Number",0
g_sortprofit db "Profit",0
g_sortlastprofit db "Last year profit",0
g_sortage db "Age",0
g_sortmaxspeed db "Max. Speed",0
g_sortreliability db "Reliability",0
g_sortcargo db "Cargo",0
g_sorthint db 0x98,"Select sorting method of vehicles in this list",0

g_performance db " (Perf. score: ",0x7e,")",0

g_vehiclelost db 0x94,0x80," ",0x7c," seems to be lost",0

g_wrongrailtype db 94h,"...incompatible rail types",0

g_neterror1 db 0x94,"Network error!",0
g_neterror2 db 0x94,"Games disconnected!",0

g_desynch1 db 0x94,"Games out of sync!",0
g_desynch2 db 0x94,"Use sv2flip or reload the last save!",0

g_refitvehicle db 0x98,"Refit vehicle",0
g_refitcargohint db 0x98,"Select type of cargo for vehicle to carry",0
g_refitbuttonhint db 0x98,"Refit vehicle to carry highlighted cargo type",0

g_cantbuildcanalhere db 0x94, "Can't build canals/locks here", 0

g_fundprospecting db 0x94, "Fund prospecting", 0
g_buildindustry db 0x94, "Build industry", 0
g_fundingfailed db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
g_cannotfundprospecting db 0x94, "Cannot fund prospecting", 0

g_newtrainindepot db 0
g_newrvindepot db 0
g_newshipindepot db 0
g_newaircraftinhangar db 0
g_newvehold db 0
g_newvehveryold db 0
g_newvehveryveryold db 0
g_newvehiclelost db 0
g_newcantreverse db 0

g_txtetoolboxmenu db "Enhanced GUI settings", 0
g_txtetoolbox db 0x94, "Enhanced GUI Settings", 0
g_txtetoolbox_tsigns db 0x98, "Station signs", 0
g_txtetoolbox_tsignstrans db "Transparent",0
g_txtetoolbox_tsignsold db "TTD Style",0

g_txtetoolbox_dsize db 0x98, "Depot Size",0
g_txtetoolbox_d8 db "Depot  8  (4)",0
g_txtetoolbox_d10 db "Depot 10  (5)",0
g_txtetoolbox_d12 db "Depot 12  (6)",0
g_txtetoolbox_d14 db "Depot 14  (7)",0
g_txtetoolbox_d16 db "Depot 16  (8)",0
g_txtetoolbox_d18 db "Depot 18  (9)",0
g_txtetoolbox_d20 db "Depot 20  (10)",0

g_txtetoolbox_depotalltrash db 0x98, "Depot allTrash",0
g_txtetoolbox_on db "On",0
g_txtetoolbox_off db "Off",0
g_txtetoolbox_saveinsavegame db 0x98, "Stick Settings",0
g_txtetoolbox_usedefaultinsave db 0x98, "Unstick",0
g_txtetoolbox_saveasdefault db 0x98, "Save as Default",0
g_txtetoolbox_resetdefaultsizes db 0x98, "Reset default sizes",0

g_none db "None", 0
g_low  db "Low", 0
g_normal db "Normal", 0
g_high db "High", 0

g_defaultstation db "(default)",0
g_stationnumdefault db "Station ",0x81,0xff,0xC7,0
g_stationclassdefault db "Station class ",0x81,0xff,0xC7,0

g_unnamedtownnamestyle db "(Unnamed style)",0

g_newshistory db "Message history",0
g_messagesettings db "Message settings",0
g_messages db 0x94, "Messages",0
	
g_cantreverse db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

g_grflanguage db "0",0

g_sizertooltip db 0x98, "Drag to resize the window",0
g_stickytooltip db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0

g_rcw_railway db 0x94, "Railway", 0
g_rcw_signaltype db 0x98, "Signal type", 0
g_rcw_semaphores db "Semaphores", 0
g_rcw_lights db "Lights", 0
g_rcw_automatic db "Automatic", 0
g_rcw_normal db "Normal", 0
g_rcw_entry db "Entry", 0
g_rcw_exit db "Exit", 0
g_rcw_combo db "Combo", 0
g_rcw_nopbs db "Not path based", 0
g_rcw_pbs db "Path based", 0
g_rcw_tracks db 0x98, "Tracks: ", 0x8E, 0x80, 0
g_rcw_length db 0x98, "Length: ", 0x8E, 0x80, 0
g_rcw_drag db "Drag", 0
g_rcw_class db 0x98, "Class:", 0
g_rcw_type db 0x98, "Type:", 0
g_rcw_accepts db 0x98, "Accepts:                    ", 0x8A, 0

g_outofdynmem db 0x94, "Out of dynamic memory", 0
g_cantresize db 0x94, "Can't resize window...", 0

g_grftextnotfound db "-- GRF text not found! --",0

g_newindubuildindustry db "Build industry",0
g_newindufundprospecting db "Fund prospecting for industry",0
g_newinduproduces db 0x98, "Produces: ", 0x90, 0x80, 0
g_toomanyindustries db 94h,"Too many industries on map.", 0

g_newindulist_tooltip db 0x98,"List of available industry types - click on the one you want to build",0
g_newinduinfo_tooltip db 0x98,"Information about the currently selected industry type",0
g_newindubuild_tooltip db 0x98,"Build the industry",0
g_newinduprospect_tooltip db 0x98,"Fund prospecting to find resources for this industry",0

g_newindu_cargowaiting db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

g_warning_notowns db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

g_localplayer db " (local player)",0
g_remoteplayer db " (remote player)",0

g_multiplayer db 0x98,"Multiplayer",0
g_multiplayer_tooltip db 0x98,"Select multiplayer game",0

g_patchsnd_dll_notfound db 94h,"Cannot load patchsnd.dll, new sounds disabled.", 0

g_statistics db 0x98, "Statistics",0
g_statistics_white db 0x94, "Statistics",0
g_totalcargo db 0x8E, "Total amount of cargo transported",0

g_landareainfoheight db 0x98,"Altitude: ",0x95,0x7B,0

g_hotkeylistdos db "xqwe!",0x22,"-$t%1234567890",0xdf,1eh,5ch,0
g_hotkeylistwin db "xqwe!",0x22,"§$t%1234567890-=~]",0

g_last equ $


; **************
;     French
; **************

newlanguage french,f,2,505759,1707008

f_bribetext db "Corrompre les autorités locales",0

f_bribedesc db 94h,80h,13,90h,"  "
	db "Paye les autorités locales pour augmenter votre cote, "
	db "au risque de vous faire coincer."
	db 13,"  Co",0fbh,"t: ",7fh,0

f_bribefailed db 94h,"Votre tentative de corruption a été découverte par un investigateur régional.",0

f_headingfor db 95h,80h,", ",84h,0
f_headingfordepot1 db 95h,"Dépot de train ",0e0h," ",80h,", ", 84h,0
f_headingfordepot2 db 95h,"Dépot routier ",0e0h," ",80h,", ", 84h,0
f_headingfordepot3 db 95h,"Dépot maritime ",0e0h," ",80h,", ", 84h,0
f_headingfordepot4 db 95h,80h," Hangar, ", 84h,0

f_withsignals db "Voie ferrées avec ",80h," (",80h,")",0
f_wplainsignals db "signaux réguliers",0
f_wpresignals db "pré-signaux",0
f_wpresigexits db "sortie-signaux",0
f_wprecombined db "signaux hybrides",0
f_presigautomatic db "automatiques",0
f_presigmanual db "manuels",0
f_pathbasedauto db "automatic, path-based",0
f_pathbasedmanual db "manual, path-based",0

f_vehmulttoolow db 94h,"Attention : partie sauvée avec un nombre total de véhicules multiplié par ",7eh,". "
		db " ",7eh," composants de ",7eh," véhicules et ",7eh," objets spéciaux ont été retirés.",0

f_rchunknotloaded db 94h,"Attention : la partie utilise des options de TTDPatch "
		db "qui sont désactivées ou non présentes dans cette version, des informations peuvent etre perdues.",0

f_loadgame db "Charger le jeu",0

f_gotodepot db "Aller à ",80h,0
f_gotodepotonly db "Service au ",80h,0
f_gototraindepot db "Dépot de train ",0e0h," ",80h,0
f_gotoroaddepot db "Dépot routier ",0e0h," ",80h,0
f_gotoshipdepot db "Dépot maritime ",0e0h," ",80h,0
f_gotoairdepot db "Hangar ",80h,0
f_routethrough db "Route through ",0x80,0
f_routenonstopthrough db "Route non-stop through ",0x80,0

f_vehobsolete db 94h,"Model is obsolete and ",80h,0

f_cannotcheat db 94h,"Ne peut exécuter la triche",0
f_cheatinvalidparm db 94h,"Paramètre invalide",0
f_cheatunknown db 94h,"Triche inconnue",0
f_cheatobsolete1 db 94h,"Remarque: Cht: ",80h," est désuet.",0
f_cheatobsolete2 db 94h,"Utilisez plutôt Cht: ",80h,".",0
f_nostationhere db 94h,"No station here",0

f_managedby1 db " (Joueur 1 prov.)",0
f_managedby2 db " (Joueur 2 prov.)",0

f_manage db 98h,"Contrôler",0

f_engineinfo1	db 98h,"Cost: ",8ah,7fh
		db 98h,"   Poids: ",8ah,7ch,"t",13
		db 98h,"Effort Traction Max.: ",8ah,7ch,"kN",13
		db 98h,"Vitesse: ",8ah,84h
		db 98h,"   Puissance: ",8ah,7ch,"CV",0
f_wagonpower	db 98h,"Wagons Motorisés: ",8ah,"+",7ch,"CV"
		db 98h,"   Poids: ",8ah,"+",7dh,"t",0
f_engineinfo2	db 98h,"Coût: ",8ah,7fh,"/yr",13
		db 98h,"Capacité: ",8ah,80h," ",80h,13
		db 98h,"Modèle: ",8ah,7eh
		db 98h,"   Vie: ",8ah,7ch," années",13
		db 98h,"Fiabilité max: ",8ah,7dh,"%",0
f_wagoninfo	db 98h,"Cost: ",8ah,7fh,13
		db 98h,"Poids: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacité: ",8ah,80h," ",80h,0
f_newwagoninfo db 98h,"Cost: ",7fh,
	db "    Poids: ",7ch,"t",13
	db "Capacité: ",80h," ",80h,0
f_wagonspeedlimit db 98h,13,"Max. Speed: ",80h,84h,0
f_refittableto db 98h,"Refittable to: ",8ah,80h,0
f_refittabletoallbut db 98h,"Refittable to: ",8ah,"All but ",80h,0
f_refittabletoall db 98h,"Refittable to: ",8ah,"All cargo types",0

f_railwaywagon db "wagon",0
f_monorailwagon db "wagon monorail",0
f_maglevwagon db "wagon maglev",0

f_ufodestroyed db 98h,0fh,"'OVNI' detruit dans une grande explosion pres de ",80h,"!",0

f_rvweightinfo db 98h,"Poids: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Puissance: ", 95h,7ch,"CV   "
	db 80h,0

f_rvweightpurchasewindow db 98h,"Cost: ", 8ah, 7fh
	db 98h,"   vitesse: ", 8ah, 84h, 13
	db 98h,"Coût: ", 8ah, 7fh, "/année", 13
	db 98h,"Puissance: ", 8ah, 7ch,"CV"
	db 98h,"   poids: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Capacité: ", 8ah, 80h, 13
	db 98h,"Modèle: ", 8ah, 7eh
	db 98h,"   Vie: ", 8ah, 7ch, " années",13
	db 98h,"Fiabilité max: ", 8ah, 7dh, "%", 0

f_grfloaderror db 94h,"Erreur en chargeant les nouveaux graphiques:",0
f_toomanysprites db 94h,"Il y a plus de sprites que ce qui est spécifié (fichier ",80h,").",0
f_outofmemory db 94h,"Pas assez de mémoire (fichier ",80h,").",0
f_wronggrfversion db 94h,"Mauvaise version de .grf (fichier ",80h,").",0
f_toomanyspritestotal db 94h,"Ne peut pas charger plus de sprites (du fichier ",80h,").",0
f_filenotfound db 94h,"Fichier ",22h,80h,22h," non trouvé.",0
f_invalidsprite db 94h, "Fichier ", 22h,80h,22h," a le sprite #",7ch," invalide (code ",7ch,"/",7ch,").",0
f_notttdpatchgrf db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
f_grferror db 94h, "Error: ", 80h,0
f_grfwarning db 94h, "Warning: ", 80h,0
f_grfneedspatchversion db 94h, 80h, " requires at least TTDPatch version ", 80h, 0
f_grfneedsdoswin db 94h, 80h, " is for the ", 80h, " version of TTD.", 0
f_grfwantsswitch db 94h, 80h, " is designed to be used with ", 80h, 0
f_grfinvalidparam db 94h, "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
f_grfconflict db 94h,"GRF conflict with ", 80h, 0

f_grfstatcaption db 0x94,"GRF Status", 0
f_grfstatapply db 0x98,"Apply", 0
f_grfstatreset db 0x98,"Default", 0
f_grfinfotext db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

f_grflisthint db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
f_grfapplyhint db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
f_grfresethint db 0x98,"Reset all graphics settings to the default and apply",0

f_grfstatusmenu db "New graphics status", 0
f_initialgrfsettings db 0x98, "Initial graphics settings", 0
f_initialgrfsettingshint db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

f_grfstatgeninfo1 db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
f_grfstatgeninfo2	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
f_grfstatgeninfo3	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
f_grfstatgeninfo4	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
f_grfstatmax db " (",0x7b," max)",0


f_elecrailconstitle db 94h,"Construction de voie ferrée électrique",0
f_elecrailconsmenu db "construction voie électrique",0

f_lmilloutoftrees db 98h,0fh,80h," ",80h," manque d'arbre proches!",0

f_eurointroduced db 98h,0fh,"Union monétaire!",0dh,0dh,"Les pays européens passe à l'Euro!",0

f_curr_HUF db "Florin hongrois (Ft)",0,0,0,0,0,0
f_curr_PLN db "Zloty Polonais(Zl)",0,0,0,0,0,0
f_curr_ATS db "AShilling Australien (ATS)",0,0,0,0,0,0
f_curr_BEF db "Franc Belge (BEF)",0,0,0,0,0,0
f_curr_DKK db "Couronne danoise (DKK)",0,0,0,0,0,0
f_curr_FIM db "Mark finlandais (FIM)",0,0,0,0,0,0
f_curr_GRD db "Drachme grec (GRD)",0,0,0,0,0,0
f_curr_CHF db "Franc Suisse(CHF)",0,0,0,0,0,0
f_curr_NLG db "Florin hollandais (NLG)",0,0,0,0,0,0
f_curr_ITL db "Lire italienne (ITL)",0,0,0,0,0,0
f_curr_SEK db "Couronne suisse (SEK)",0,0,0,0,0,0
f_curr_RUB db "Rouble russe (RUB)",0,0,0,0,0,0
f_curr_EUR db "Euro (",0x9E,")",0,0,0,0,0,0

f_townlastmonthaccepted db 98h,"Marchandises acceptées par toutes les stations le mois dernier :",0

f_aircraftcleared db 98h,0fh,"Les débris du récent crash d'avion de ",80h," ont été retirés!",0
f_zeppelincleared db 98h,0fh,"Les débris du récent crash de Zepplin de ",80h," ont Ã©té retirés!",0
f_traincleared db 98h,0fh,"Les débris du récent accident de train près de ",80h," ont été déblayés!",0

f_endofsharedorders db 1,0xa,"- - Fin de commande partagée (",85h,7ch,") - -",0

f_resetorders db 0x98,"Reset",0
f_toggleservice db 0x98,"Service",0
f_resethint db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
f_servicehint db 0x98,"Makes the vehicle skip this order unless it's time for service",0

f_nosort db "Unsorted",0
f_sortconsistnum db "Number",0
f_sortprofit db "Profit",0
f_sortlastprofit db "Last year profit",0
f_sortage db "Age",0
f_sortmaxspeed db "Max. Speed",0
f_sortreliability db "Reliability",0
f_sortcargo db "Cargo",0
f_sorthint db 0x98,"Select sorting method of vehicles in this list",0

f_performance db " (Perf. score: ",0x7e,")",0

f_vehiclelost db 0x94,0x80," ",0x7c," seems to be lost",0

f_wrongrailtype db 94h,"...incompatible rail types",0

f_neterror1 db 0x94,"Network error!",0
f_neterror2 db 0x94,"Games disconnected!",0

f_desynch1 db 0x94,"Games out of sync!",0
f_desynch2 db 0x94,"Use sv2flip or reload the last save!",0

f_refitvehicle db 0x98,"Refit vehicle",0
f_refitcargohint db 0x98,"Select type of cargo for vehicle to carry",0
f_refitbuttonhint db 0x98,"Refit vehicle to carry highlighted cargo type",0

f_cantbuildcanalhere db 0x94, "Can't build canals/locks here", 0

f_fundprospecting db 0x94, "Fund prospecting", 0
f_buildindustry db 0x94, "Build industry", 0
f_fundingfailed db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
f_cannotfundprospecting db 0x94, "Cannot fund prospecting", 0

f_newtrainindepot db 0
f_newrvindepot db 0
f_newshipindepot db 0
f_newaircraftinhangar db 0
f_newvehold db 0
f_newvehveryold db 0
f_newvehveryveryold db 0
f_newvehiclelost db 0
f_newcantreverse db 0

f_txtetoolboxmenu db "Enhanced GUI settings", 0
f_txtetoolbox db 0x94, "Enhanced GUI Settings", 0
f_txtetoolbox_tsigns db 0x98, "Station signs", 0
f_txtetoolbox_tsignstrans db "Transparent",0
f_txtetoolbox_tsignsold db "TTD Style",0

f_txtetoolbox_dsize db 0x98, "Depot Size",0
f_txtetoolbox_d8 db "Depot  8  (4)",0
f_txtetoolbox_d10 db "Depot 10  (5)",0
f_txtetoolbox_d12 db "Depot 12  (6)",0
f_txtetoolbox_d14 db "Depot 14  (7)",0
f_txtetoolbox_d16 db "Depot 16  (8)",0
f_txtetoolbox_d18 db "Depot 18  (9)",0
f_txtetoolbox_d20 db "Depot 20  (10)",0

f_txtetoolbox_depotalltrash db 0x98, "Depot allTrash",0
f_txtetoolbox_on db "On",0
f_txtetoolbox_off db "Off",0
f_txtetoolbox_saveinsavegame db 0x98, "Stick Settings",0
f_txtetoolbox_usedefaultinsave db 0x98, "Unstick",0
f_txtetoolbox_saveasdefault db 0x98, "Save as Default",0
f_txtetoolbox_resetdefaultsizes db 0x98, "Reset default sizes",0

f_none db "None", 0
f_low  db "Low", 0
f_normal db "Normal", 0
f_high db "High", 0

f_defaultstation db "(default)",0
f_stationnumdefault db "Station ",0x81,0xff,0xC7,0
f_stationclassdefault db "Station class ",0x81,0xff,0xC7,0

f_unnamedtownnamestyle db "(Unnamed style)",0

f_newshistory db "Message history",0
f_messagesettings db "Message settings",0
f_messages db 0x94, "Messages",0
	
f_cantreverse db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

f_grflanguage db "0",0

f_sizertooltip db 0x98, "Drag to resize the window",0
f_stickytooltip db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0

f_rcw_railway db 0x94, "Railway", 0
f_rcw_signaltype db 0x98, "Signal type", 0
f_rcw_semaphores db "Semaphores", 0
f_rcw_lights db "Lights", 0
f_rcw_automatic db "Automatic", 0
f_rcw_normal db "Normal", 0
f_rcw_entry db "Entry", 0
f_rcw_exit db "Exit", 0
f_rcw_combo db "Combo", 0
f_rcw_nopbs db "Not path based", 0
f_rcw_pbs db "Path based", 0
f_rcw_tracks db 0x98, "Tracks: ", 0x8E, 0x80, 0
f_rcw_length db 0x98, "Length: ", 0x8E, 0x80, 0
f_rcw_drag db "Drag", 0
f_rcw_class db 0x98, "Class:", 0
f_rcw_type db 0x98, "Type:", 0
f_rcw_accepts db 0x98, "Accepts:                    ", 0x8A, 0
	
f_outofdynmem db 0x94, "Out of dynamic memory", 0
f_cantresize db 0x94, "Can't resize window...", 0

f_grftextnotfound db "-- GRF text not found! --",0

f_newindubuildindustry db "Build industry",0
f_newindufundprospecting db "Fund prospecting for industry",0
f_newinduproduces db 0x98, "Produces: ", 0x90, 0x80, 0
f_toomanyindustries db 94h,"Too many industries on map.", 0

f_newindulist_tooltip db 0x98,"List of available industry types - click on the one you want to build",0
f_newinduinfo_tooltip db 0x98,"Information about the currently selected industry type",0
f_newindubuild_tooltip db 0x98,"Build the industry",0
f_newinduprospect_tooltip db 0x98,"Fund prospecting to find resources for this industry",0

f_newindu_cargowaiting db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

f_warning_notowns db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

f_localplayer db " (local player)",0
f_remoteplayer db " (remote player)",0

f_multiplayer db 0x98,"Multiplayer",0
f_multiplayer_tooltip db 0x98,"Select multiplayer game",0

f_patchsnd_dll_notfound db 94h,"Cannot load patchsnd.dll, new sounds disabled.", 0

f_statistics db 0x98, "Statistics",0
f_statistics_white db 0x94, "Statistics",0
f_totalcargo db 0x8E, "Total amount of cargo transported",0

f_landareainfoheight db 0x98,"Altitude: ",0x95,0x7B,0

f_hotkeylistdos db "xqwe!",0x22,0x9C,"$t%1234567890-=",1eh,5ch,0
f_hotkeylistwin db "xqwe1234t5&",0xE9,0x22,"'(-",0xE8,"_",0xE7,")=$",0xB2,"*",0

f_last equ $


; **************
;    Spanish
; **************

newlanguage spanish,s,2,506237,1707520

s_bribetext db "Sobornar la autoridad local",0

s_bribedesc db 94h,80h,13,90h," "
	db "Sobornar la autoridad local para aumentar su ranking, "
	db "con el riesgo de una severa penalización si es descubierto."
	db 13," Coste: ",7fh,0

s_bribefailed db 94h,"Su intento de soborno ha sido descubierto por un investigador regional.",0

s_headingfor db 95h,80h,", ",84h,0
s_headingfordepot1 db 95h,80h," Cocheras de Ferrocarril, ", 84h,0
s_headingfordepot2 db 95h,80h," Garaje de Carretera, ", 84h,0
s_headingfordepot3 db 95h,80h," Estación Marítima, ", 84h,0
s_headingfordepot4 db 95h,80h," Hangar, ", 84h,0

s_withsignals db "Vías de ferrocarril con ",80h," ",80h,0
s_wplainsignals db "señales planas",0
s_wpresignals db "pre-señales",0
s_wpresigexits db "salidas pre-señal",0
s_wprecombined db "señales combinadas",0
s_presigautomatic db "automáticas",0
s_presigmanual db "manuales",0
s_pathbasedauto db "automatic, path-based",0
s_pathbasedmanual db "manual, path-based",0

s_vehmulttoolow db 94h,"Advertencia: juego guardado con multiplicador de veh. de ",7eh,". "
		db " Removidos ",7eh," vehículos en ",7eh," grupos  y ",7eh," objetos especiales.",0

s_rchunknotloaded db 94h,"Advertencia: el juego utiliza algunas características de TTDPatch "
		db "que no estan activadas o disponibles en esta versión. Podría perder datos.",0

s_loadgame db "Cargar Juego",0

s_gotodepot db "Ir a ",80h,0
s_gotodepotonly db "Mantenimiento en ",80h,0
s_gototraindepot db 80h," Cocheras de Ferrocarril",0
s_gotoroaddepot db 80h," Garaje de Carretera",0
s_gotoshipdepot db 80h," Estación Marítima",0
s_gotoairdepot db 80h," Hangar",0
s_routethrough db "Route through ",0x80,0
s_routenonstopthrough db "Route non-stop through ",0x80,0

s_vehobsolete db 94h,"Model is obsolete and ",80h,0

s_cannotcheat db 94h,"No se puede ejecutar el código trampa",0
s_cheatinvalidparm db 94h,"Parámetro invalido",0
s_cheatunknown db 94h,"Código trampa desconocido",0
s_cheatobsolete1 db 94h,"Nota: Cht: ",80h," es obsoleto.",0
s_cheatobsolete2 db 94h,"Use en cambio Cht: ",80h,0
s_nostationhere db 94h,"No station here",0

s_managedby1 db " (Jugador 1 temp.)",0
s_managedby2 db " (Jugador 2 temp.)",0

s_manage db 98h,"Manejar",0

s_engineinfo1	db 98h,"Coste: ",8ah,7fh
		db 98h,"   Peso: ",8ah,7ch,"t",13
		db 98h,"Esfuerzo de Tracción Max.: ",8ah,7ch,"kN",13
		db 98h,"Velocidad: ",8ah,84h
		db 98h,"   Potencia: ",8ah,7ch,"cv",0
s_wagonpower	db 98h,"Vagones Motrises: ",8ah,"+",7ch,"cv"
		db 98h,"   Peso: ",8ah,"+",7dh,"t",0
s_engineinfo2	db 98h,"Coste de operación: ",8ah,7fh,"/año",13
		db 98h,"Capacidad: ",8ah,80h," ",80h,13
		db 98h,"Diseño: ",8ah,7eh
		db 98h,"   Vida: ",8ah,7ch," años",13
		db 98h,"Fiabilidad Max.: ",8ah,7dh,"%",0
s_wagoninfo	db 98h,"Coste: ",8ah,7fh,13
		db 98h,"Peso: ",8ah,7ch,"t (",7ch,"t)",13
		db 98h,"Capacidad: ",8ah,80h," ",80h,0
s_newwagoninfo db 98h,"Coste: ",7fh,
	db "    Peso: ",7ch,"t",13
	db "Capacidad: ",80h," ",80h,0
s_wagonspeedlimit db 98h,13,"Max. Speed: ",80h,84h,0
s_refittableto db 98h,"Refittable to: ",8ah,80h,0
s_refittabletoallbut db 98h,"Refittable to: ",8ah,"All but ",80h,0
s_refittabletoall db 98h,"Refittable to: ",8ah,"All cargo types",0

s_railwaywagon db "vagón ferroviario",0
s_monorailwagon db "vagón de monorriel",0
s_maglevwagon db "vagón maglev",0

s_ufodestroyed db 98h,0fh,"'OVNI' destruido en enorme explosión cerca de  ",80h,"!",0

s_rvweightinfo db 98h,"Peso: ", 95h,7ch,".",7dh,"t   "
	db 98h,"Potencia: ", 95h,7ch,"cv   "
	db 80h,0

s_rvweightpurchasewindow db 98h,"Coste: ", 8ah, 7fh
	db 98h,"   Velocidad: ", 8ah, 84h, 13
	db 98h,"Coste de operación: ", 8ah, 7fh, "/año", 13
	db 98h,"Potencia: ", 8ah, 7ch,"cv"
	db 98h,"   Peso: ", 8ah, 7dh,".",7dh, "t", 13
	db 98h,"Capacidad: ", 8ah, 80h, 13
	db 98h,"Diseño: ", 8ah, 7eh
	db 98h,"   Vida: ", 8ah, 7ch, " años",13
	db 98h,"Fiabilidad Max.: ", 8ah, 7dh, "%", 0

s_grfloaderror db 94h,"Error cargando nuevos gráficos:",0
s_toomanysprites db 94h,"Error cargando nuevos gráficos: (archivo ",80h,").",0
s_outofmemory db 94h,"Sin memoria (archivo ",80h,").",0
s_wronggrfversion db 94h,"Versión .grf incorrecta (archivo ",80h,").",0
s_toomanyspritestotal db 94h,"No se pueden cargar más dibujos (desde archivo ",80h,").",0
s_filenotfound db 94h,"Archivo ",22h,80h,22h," no encontrado.",0
s_invalidsprite db 94h, "El archivo ", 22h,80h,22h," contiene un dibujo inválido #",7ch," (code ",7ch,"/",7ch,").",0
s_notttdpatchgrf db 94h, "File ",22h,80h,22h," is not a TTDPatch graphics file.",0
s_grferror db 94h, "Error: ", 80h,0
s_grfwarning db 94h, "Warning: ", 80h,0
s_grfneedspatchversion db 94h, 80h, " requires at least TTDPatch version ", 80h, 0
s_grfneedsdoswin db 94h, 80h, " is for the ", 80h, " version of TTD.", 0
s_grfwantsswitch db 94h, 80h, " is designed to be used with ", 80h, 0
s_grfinvalidparam db 94h, "Invalid parameter for ", 80h, ": parameter ", 80h, " (", 7Bh, ")", 0
s_grfconflict db 94h,"GRF conflict with ", 80h, 0

s_grfstatcaption db 0x94,"GRF Status", 0
s_grfstatapply db 0x98,"Apply", 0
s_grfstatreset db 0x98,"Default", 0
s_grfinfotext db 0x95,0x80,13,0x94,"File: ",0x95,0x80,13,0x80,0x94,0x80,0

s_grflisthint db 0x98,"Click on text to display additional info about "
	db "this file.  Click on red/green flags to toggle activation.",0
s_grfapplyhint db 0x98,"Apply changes in active/inactive graphics to "
	db "current game.",0
s_grfresethint db 0x98,"Reset all graphics settings to the default and apply",0

s_grfstatusmenu db "New graphics status", 0
s_initialgrfsettings db 0x98, "Initial graphics settings", 0
s_initialgrfsettingshint db 0x98, "Open the GRF Status window to select initially ",
	db "active graphics sets", 0

s_grfstatgeninfo1 db 0x98,"Number of files: ",0x94,0x7b,13
	db 0x98,"Memory usage: ",0x94,0x7b,0x98, " kB",13
	db 0x98,"Total number of sprites: ",0x94,0x7b,13
	db 0x98,"Active sprites: ",0x94,0x7b,0x98,0x80,0
s_grfstatgeninfo2	db 0x98,"    Trains: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Road vehicles: ",0x94,0x7b,0x98,0x80,0
s_grfstatgeninfo3	db 0x98,"    Ships: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Planes: ",0x94,0x7b,0x98,0x80,0
s_grfstatgeninfo4	db 0x98,"    Houses: ",0x94,0x7b,0x98,0x80,13
			db 0x98,"    Other: ",0x94,0x7b,0x98,0x80,0
s_grfstatmax db " (",0x7b," max)",0


s_elecrailconstitle db 94h,"Construcción de vía electrificada",0
s_elecrailconsmenu db "Construcción de vía Electr.",0

s_lmilloutoftrees db 98h,0fh,80h," ",80h," se quedó sin árboles aledaños!",0

s_eurointroduced db 98h,0fh,"Unión monetaria!",0dh,0dh,"Los paises europeos cambian sus monedas nacionales por el Euro!",0

s_curr_HUF db "Forint Húngaro (Ft)",0,0,0,0,0,0
s_curr_PLN db "Zloty Polaco (zl)",0,0,0,0,0,0
s_curr_ATS db "Schilling Austriaco (ATS)",0,0,0,0,0,0
s_curr_BEF db "Franco Belga (BEF)",0,0,0,0,0,0
s_curr_DKK db "Corona Danesa (DKK)",0,0,0,0,0,0
s_curr_FIM db "Marco Finlandes (FIM)",0,0,0,0,0,0
s_curr_GRD db "Dracma Griego (GRD)",0,0,0,0,0,0
s_curr_CHF db "Franco Suizo (CHF)",0,0,0,0,0,0
s_curr_NLG db "Florín Holandés (NLG)",0,0,0,0,0,0
s_curr_ITL db "Lira Italiana (ITL)",0,0,0,0,0,0
s_curr_SEK db "Corona Sueca (SEK)",0,0,0,0,0,0
s_curr_RUB db "Rublo Ruso (RUB)",0,0,0,0,0,0
s_curr_EUR db "Euro (",0x9E,")",0,0,0,0,0,0

s_townlastmonthaccepted db 98h,"Carga aceptada el mes anterior en todas las estaciones:",0

s_aircraftcleared db 98h,0fh,"Los restos de un reciente accidente aéreo han sido retirados de",80h,"!",0
s_zeppelincleared db 98h,0fh,"Los restos de un reciente accidente de Zeppelin han sido retirados de ",80h,"!",0
s_traincleared db 98h,0fh,"Los restos del reciente accidente de tren han sido retirados de ",80h,"!",0

s_endofsharedorders db 1,0xa,"- - End of shared orders (",85h,7ch,") - -",0

s_resetorders db 0x98,"Reset",0
s_toggleservice db 0x98,"Service",0
s_resethint db 0x98,"Removes all orders from the schedule (doesn't affect other vehicles sharing this order)",0
s_servicehint db 0x98,"Makes the vehicle skip this order unless it's time for service",0

s_nosort db "Unsorted",0
s_sortconsistnum db "Number",0
s_sortprofit db "Profit",0
s_sortlastprofit db "Last year profit",0
s_sortage db "Age",0
s_sortmaxspeed db "Max. Speed",0
s_sortreliability db "Reliability",0
s_sortcargo db "Cargo",0
s_sorthint db 0x98,"Select sorting method of vehicles in this list",0

s_performance db " (Perf. score: ",0x7e,")",0

s_vehiclelost db 0x94,0x80," ",0x7c," seems to be lost",0

s_wrongrailtype db 94h,"...incompatible rail types",0

s_neterror1 db 0x94,"Network error!",0
s_neterror2 db 0x94,"Games disconnected!",0

s_desynch1 db 0x94,"Games out of sync!",0
s_desynch2 db 0x94,"Use sv2flip or reload the last save!",0

s_refitvehicle db 0x98,"Refit vehicle",0
s_refitcargohint db 0x98,"Select type of cargo for vehicle to carry",0
s_refitbuttonhint db 0x98,"Refit vehicle to carry highlighted cargo type",0

s_cantbuildcanalhere db 0x94, "Can't build canals/locks here", 0

s_fundprospecting db 0x94, "Fund prospecting", 0
s_buildindustry db 0x94, "Build industry", 0
s_fundingfailed db 0x94, "Your funding didn't pay off. The prospecters came back empty-handed.", 0
s_cannotfundprospecting db 0x94, "Cannot fund prospecting", 0

s_newtrainindepot db 0
s_newrvindepot db 0
s_newshipindepot db 0
s_newaircraftinhangar db 0
s_newvehold db 0
s_newvehveryold db 0
s_newvehveryveryold db 0
s_newvehiclelost db 0
s_newcantreverse db 0

s_txtetoolboxmenu db "Enhanced GUI settings", 0
s_txtetoolbox db 0x94, "Enhanced GUI Settings", 0
s_txtetoolbox_tsigns db 0x98, "Station signs", 0
s_txtetoolbox_tsignstrans db "Transparent",0
s_txtetoolbox_tsignsold db "TTD Style",0

s_txtetoolbox_dsize db 0x98, "Depot Size",0
s_txtetoolbox_d8 db "Depot  8  (4)",0
s_txtetoolbox_d10 db "Depot 10  (5)",0
s_txtetoolbox_d12 db "Depot 12  (6)",0
s_txtetoolbox_d14 db "Depot 14  (7)",0
s_txtetoolbox_d16 db "Depot 16  (8)",0
s_txtetoolbox_d18 db "Depot 18  (9)",0
s_txtetoolbox_d20 db "Depot 20  (10)",0

s_txtetoolbox_depotalltrash db 0x98, "Depot allTrash",0
s_txtetoolbox_on db "On",0
s_txtetoolbox_off db "Off",0
s_txtetoolbox_saveinsavegame db 0x98, "Stick Settings",0
s_txtetoolbox_usedefaultinsave db 0x98, "Unstick",0
s_txtetoolbox_saveasdefault db 0x98, "Save as Default",0
s_txtetoolbox_resetdefaultsizes db 0x98, "Reset default sizes",0

s_none db "None", 0
s_low  db "Low", 0
s_normal db "Normal", 0
s_high db "High", 0

s_defaultstation db "(default)",0
s_stationnumdefault db "Station ",0x81,0xff,0xc7,0
s_stationclassdefault db "Station class ",0x81,0xff,0xc7,0

s_unnamedtownnamestyle db "(Unnamed style)",0

s_newshistory db "Message history",0
s_messagesettings db "Message settings",0
s_messages db 0x94, "Messages",0

s_cantreverse db 0x94,0x80," ",0x7c," needs to reverse but cannot do so safely.",0

s_grflanguage db "0",0

s_sizertooltip db 0x98, "Drag to resize the window",0
s_stickytooltip db 0x98, "Make this window sticky, this window won't be closed when pressing <del>",0

s_rcw_railway db 0x94, "Railway", 0
s_rcw_signaltype db 0x98, "Signal type", 0
s_rcw_semaphores db "Semaphores", 0
s_rcw_lights db "Lights", 0
s_rcw_automatic db "Automatic", 0
s_rcw_normal db "Normal", 0
s_rcw_entry db "Entry", 0
s_rcw_exit db "Exit", 0
s_rcw_combo db "Combo", 0
s_rcw_nopbs db "Not path based", 0
s_rcw_pbs db "Path based", 0
s_rcw_tracks db 0x98, "Tracks: ", 0x8E, 0x80, 0
s_rcw_length db 0x98, "Length: ", 0x8E, 0x80, 0
s_rcw_drag db "Drag", 0
s_rcw_class db 0x98, "Class:", 0
s_rcw_type db 0x98, "Type:", 0
s_rcw_accepts db 0x98, "Accepts:                    ", 0x8A, 0

s_outofdynmem db 0x94, "Out of dynamic memory", 0
s_cantresize db 0x94, "Can't resize window...", 0

s_grftextnotfound db "-- GRF text not found! --",0

s_newindubuildindustry db "Build industry",0
s_newindufundprospecting db "Fund prospecting for industry",0
s_newinduproduces db 0x98, "Produces: ", 0x90, 0x80, 0
s_toomanyindustries db 94h,"Too many industries on map.", 0

s_newindulist_tooltip db 0x98,"List of available industry types - click on the one you want to build",0
s_newinduinfo_tooltip db 0x98,"Information about the currently selected industry type",0
s_newindubuild_tooltip db 0x98,"Build the industry",0
s_newinduprospect_tooltip db 0x98,"Fund prospecting to find resources for this industry",0

s_newindu_cargowaiting db 0x98,"Cargo waiting to be processed:",0x90,0x0d,0x80,0x0d,0x80,0x0d,0x80,0

s_warning_notowns db 94h,"Warning: This game doesn't have any towns. If you try to play it, TTD may crash!",0

s_localplayer db " (local player)",0
s_remoteplayer db " (remote player)",0

s_multiplayer db 0x98,"Multiplayer",0
s_multiplayer_tooltip db 0x98,"Select multiplayer game",0

s_patchsnd_dll_notfound db 94h,"Cannot load patchsnd.dll, new sounds disabled.", 0

s_statistics db 0x98, "Statistics",0
s_statistics_white db 0x94, "Statistics",0
s_totalcargo db 0x8E, "Total amount of cargo transported",0

s_landareainfoheight db 0x98,"Altitude: ",0x95,0x7B,0

s_hotkeylistdos db "xqwe!",0x22,"$%t&1234567890'",0xa1,1eh,5ch,0
s_hotkeylistwin db "xqwe!",0x22,0xb7,"$t%1234567890'",0xa1,0xba,0xe7,0

s_last equ $
