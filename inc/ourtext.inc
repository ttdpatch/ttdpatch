
; definitions of ourtext text IDs

; hack to ignore file contents when included by C preprocessor, and to ignore
; this hack when parsed by nasm
%if 0
#ifndef MAKEDEP_HACK
%endif

%macro defourtext 1.nolist
	%assign ourtext_%1 ourtext_base+ourtext_num
	%assign ourtext_num ourtext_num+1
%endmacro

; NOTICE: DO NOT REORDER OR REMOVE ENTRIES. ALWAYS ADD NEW ONES AT THE END.
; If an defourtext becomes unused, just leave it there. The order of existing entries
; important here, and their IDs must remain fixed for all times. If the format
; of an defourtext changes (e.g. different place holders), change the old one to
; foo_unused and readd foo at the end.
;
; After defining a new ID, document it on the wiki please.

%assign ourtext_num	0
%assign ourtext_base	0xF800

defourtext bribetext
defourtext bribedesc
defourtext bribefailed
defourtext headingfor
defourtext headingfordepot1
defourtext headingfordepot2
defourtext headingfordepot3
defourtext headingfordepot4
defourtext withsignals
defourtext wplainsignals
defourtext wpresignals
defourtext wpresigexits
defourtext wprecombined
defourtext presigautomatic
defourtext presigmanual
defourtext pathbasedauto
defourtext pathbasedmanual
defourtext vehmulttoolow
defourtext rchunknotloaded
defourtext loadgame
defourtext gotodepot
defourtext gotodepotonly
defourtext gototraindepot
defourtext gotoroaddepot
defourtext gotoshipdepot
defourtext gotoairdepot
defourtext routethrough
defourtext routenonstopthrough
defourtext vehobsolete
defourtext cannotcheat
defourtext cheatinvalidparm
defourtext cheatunknown
defourtext cheatobsolete1
defourtext cheatobsolete2
defourtext nostationhere
defourtext managedby1
defourtext managedby2
defourtext manage
defourtext engineinfo1
defourtext wagonpower
defourtext engineinfo2
defourtext wagoninfo
defourtext newwagoninfo
defourtext wagonspeedlimit
defourtext refittableto
defourtext refittabletoallbut
defourtext refittabletoall
defourtext railwaywagon
defourtext monorailwagon
defourtext maglevwagon
defourtext ufodestroyed
defourtext rvweightinfo
defourtext rvweightpurchasewindow
defourtext grfloaderror
defourtext toomanysprites
defourtext outofmemory
defourtext wronggrfversion
defourtext toomanyspritestotal
defourtext filenotfound
defourtext invalidsprite
defourtext notttdpatchgrf
defourtext grferror
defourtext grfwarning
defourtext grfneedspatchversion
defourtext grfneedsdoswin
defourtext grfwantsswitch
defourtext grfinvalidparam
defourtext grfconflict
defourtext grfstatcaption
defourtext grfstatapply
defourtext grfstatreset
defourtext grfinfotext
defourtext grflisthint
defourtext grfapplyhint
defourtext grfresethint
defourtext grfstatusmenu
defourtext initialgrfsettings
defourtext initialgrfsettingshint
defourtext grfstatgeninfo1
defourtext grfstatgeninfo2
defourtext grfstatgeninfo3
defourtext grfstatgeninfo4
defourtext grfstatmax
defourtext elecrailconstitle
defourtext elecrailconsmenu
defourtext lmilloutoftrees
defourtext eurointroduced
defourtext curr_HUF
defourtext curr_PLN
defourtext curr_ATS
defourtext curr_BEF
defourtext curr_DKK
defourtext curr_FIM
defourtext curr_GRD
defourtext curr_CHF
defourtext curr_NLG
defourtext curr_ITL
defourtext curr_SEK
defourtext curr_RUB
defourtext curr_EUR
defourtext townlastmonthaccepted
defourtext aircraftcleared
defourtext zeppelincleared
defourtext traincleared
defourtext endofsharedorders
defourtext resetorders
defourtext toggleservice
defourtext resethint
defourtext servicehint
defourtext nosort
defourtext sortconsistnum
defourtext sortprofit
defourtext sortlastprofit
defourtext sortage
defourtext sortmaxspeed
defourtext sortreliability
defourtext sortcargo
defourtext sortdestination
defourtext sorthint
defourtext performance
defourtext vehiclelost
defourtext wrongrailtype
defourtext neterror1
defourtext neterror2
defourtext desynch1
defourtext desynch2
defourtext refitvehicle
defourtext refitcargohint
defourtext refitbuttonhint
defourtext cantbuildcanalhere
defourtext fundprospecting
defourtext buildindustry
defourtext fundingfailed
defourtext cannotfundprospecting
defourtext newtrainindepot
defourtext newrvindepot
defourtext newshipindepot
defourtext newaircraftinhangar
defourtext newvehold
defourtext newvehveryold
defourtext newvehveryveryold
defourtext newvehiclelost
defourtext newcantreverse
defourtext txtetoolboxmenu
defourtext txtetoolbox
defourtext txtetoolbox_tsigns
defourtext txtetoolbox_tsignstrans
defourtext txtetoolbox_tsignsold
defourtext txtetoolbox_dsize
defourtext txtetoolbox_d8
defourtext txtetoolbox_d10
defourtext txtetoolbox_d12
defourtext txtetoolbox_d14
defourtext txtetoolbox_d16
defourtext txtetoolbox_d18
defourtext txtetoolbox_d20
defourtext txtetoolbox_depotalltrash
defourtext txtetoolbox_on
defourtext txtetoolbox_off
defourtext txtetoolbox_saveinsavegame
defourtext txtetoolbox_usedefaultinsave
defourtext txtetoolbox_saveasdefault
defourtext txtetoolbox_resetdefaultsizes
defourtext none
defourtext low
defourtext normal
defourtext high
defourtext defaultstation
defourtext stationnumdefault
defourtext stationclassdefault
defourtext unnamedtownnamestyle
defourtext newshistory
defourtext messagesettings
defourtext messages
defourtext cantreverse
defourtext grflanguage
defourtext sizertooltip
defourtext stickytooltip
defourtext rcw_railway
defourtext rcw_signaltype
defourtext rcw_semaphores
defourtext rcw_lights
defourtext rcw_automatic
defourtext rcw_normal
defourtext rcw_entry
defourtext rcw_exit
defourtext rcw_combo
defourtext rcw_nopbs
defourtext rcw_pbs
defourtext rcw_tracks
defourtext rcw_length
defourtext rcw_drag
defourtext rcw_class
defourtext rcw_type
defourtext rcw_accepts
defourtext outofdynmem
defourtext cantresize
defourtext grftextnotfound
defourtext newindubuildindustry
defourtext newindufundprospecting
defourtext newinduproduces
defourtext toomanyindustries
defourtext newindulist_tooltip
defourtext newinduinfo_tooltip
defourtext newindubuild_tooltip
defourtext newinduprospect_tooltip
defourtext newindu_cargowaiting
defourtext warning_notowns
defourtext localplayer
defourtext remoteplayer
defourtext multiplayer
defourtext multiplayer_tooltip
defourtext ttdpatch_dll_notfound
defourtext statistics
defourtext statistics_white
defourtext totalcargo
defourtext landareainfoheight
defourtext txteroadmenu
defourtext txtetramwindowheader
defourtext hotkeylistdos
defourtext hotkeylistwin
defourtext curr_pound
defourtext curr_dollar
defourtext curr_franc
defourtext curr_deutschmark
defourtext curr_yen
defourtext curr_peseta
defourtext shortdateformat
defourtext longdateformat

defourtext txtltwocc ; Main Name
defourtext txtltwoccglb ; Global colours
defourtext txtltwoccstm ; Special classes
defourtext txtltwoccdsl
defourtext txtltwoccelc
defourtext txtltwoccmor
defourtext txtltwoccmgv
defourtext txtltwoccdmu
defourtext txtltwoccemu
defourtext txtltwoccpaw
defourtext txtltwoccfrw
defourtext txtltwoccbus
defourtext txtltwocctrm
defourtext txtltwocctrk
defourtext txtltwoccpsh
defourtext txtltwoccfsh
defourtext txtltwoccsap
defourtext txtltwocclap
defourtext txtltwoccfrp
defourtext txtltwocchel
defourtext txtltwocclr1 ; Colours
defourtext txtltwocclr2
defourtext steepslopes
defourtext landhigherbridgehead
defourtext grfhelpercaption
defourtext grfhelper_displxrelyrel
defourtext textsprite

defourtext txtetramstationheader
defourtext txtetramdepotheader

defourtext statistics_tooltip

defourtext conflict_itself
defourtext conflict_preexist

defourtext grfstatdebug
defourtext grfdebughint
defourtext grfdebugmsg

defourtext firstpasstramarrives
defourtext firstfreighttramarrives

defourtext airporttype
defourtext unnamedairporttype

defourtext txtclonedepotbutton
defourtext txtclonetooltip
defourtext txtcloneerrortop
defourtext txtclonebadcash
defourtext txtcloneerror_company
defourtext txtcloneerror_unavail
defourtext txtcloneerror_nothead
defourtext txtcloneerror_notrail
defourtext txtcloneerror_unknown

defourtext grfbefore
defourtext grfafter

defourtext tr_trainlen
defourtext tr_maxspeed_kph
defourtext tr_curorder
defourtext tr_curdeporder
defourtext tr_totalpower
defourtext tr_totalweight
defourtext tr_restricttitle
defourtext tr_valuebtn
defourtext tr_andbtn
defourtext tr_orbtn
defourtext tr_xorbtn
defourtext tr_error1
defourtext tr_siggui_text
defourtext tr_enternumber

defourtext tr_copy
defourtext tr_share
defourtext tr_end
defourtext tr_endshare
defourtext tr_landinfotext
defourtext tr_sigval_sw
defourtext tr_sigval_se
defourtext tr_sigval_nw
defourtext tr_sigval_ne
defourtext tr_sigval_is_green
defourtext tr_sigval_is_red
defourtext tr_sigval_is_g
defourtext tr_sigval_is_r

defourtext tr_maxspeed_mph
defourtext tr_nextorder
defourtext tr_lastvisitstation
defourtext tr_carriescargo
defourtext tr_distancefromsig

defourtext tr_vartxt
defourtext tr_optxt

defourtext directoryoverflow

defourtext trdlg_eq
defourtext trdlg_neq
defourtext tr_nextdeporder

defourtext adjsttitle
defourtext adjstnumstsinrange
defourtext adjstnormstmergealgtxt
defourtext adjstnewsttxt

; CRC f0f2aac5 (check to make sure that the order above is unchanged)

defourtext adjstnewstbuoy
defourtext adjstnewenhbuoy

defourtext newgame
defourtext newgamewindow

defourtext aquaducttext

defourtext headingfordepot1v2
defourtext headingfordepot2v2
defourtext headingfordepot3v2

defourtext canaltexttip
defourtext rivertexttip
defourtext aquaducttexttip
defourtext waterconstrwin
defourtext waterconstrtbtip

defourtext sortname

defourtext tr_days_since_last_service
defourtext tr_searching_for_depot

defourtext tr_ps_wintitle
defourtext tr_ps_gui_text

defourtext tr_ps_sigcount_g
defourtext tr_ps_sigcount_go
defourtext tr_ps_sigcount_gt
defourtext tr_ps_sigcount_r
defourtext tr_ps_sigcount_ro
defourtext tr_ps_sigcount_rt
defourtext tr_ps_end
defourtext tr_ps_landinfotext

defourtext ne
defourtext se
defourtext sw
defourtext nw

defourtext tr_entertileside
defourtext tr_pbssigblentertl

defourtext newstartyear
defourtext newstartyearprint
defourtext newstartyearhintyear
defourtext newstartyearhintinc
defourtext newstartyearhintdec

defourtext nohouseremove

defourtext tsignal_linfotxt
defourtext isignal_linfotxt

defourtext advorder_findnearestdepottxt

defourtext advorder_gotonearestdepotddltxt
defourtext advorder_servicenearestdepotddltxt
defourtext advorder_loadcondskipddltxt
defourtext advorder_loadcondskiporderwintxt

defourtext advorder_orderskipcountguibtntxt
defourtext advorder_orderloadpercentguibtntxt
defourtext advorder_ordercondskiploadparamddltxt

defourtext advorder_orderparamtooltip

defourtext advorder_selrefitveh
defourtext advorder_orderrefitveh
defourtext advorder_ordergotoloadonlytxt
defourtext advorder_ordergotounloadonlytxt
defourtext advorder_ordergotoloadonlyddltxt
defourtext advorder_ordergotounloadonlyddltxt

defourtext transopts_option
defourtext transopts_caption
defourtext transopts_tttrees
defourtext transopts_ttbuildings
defourtext transopts_ttindustries
defourtext transopts_ttstations
defourtext transopts_ttraildepots
defourtext transopts_ttroaddepots
defourtext transopts_ttshipdepots
defourtext transopts_ttbridges
defourtext transopts_ttobjects
defourtext transopts_ttcompany
defourtext transopts_ttinvistrees

defourtext tr_findbtn

defourtext transopts_cttrees
defourtext transopts_ctbuildings
defourtext transopts_ctindustries
defourtext transopts_ctstations
defourtext transopts_ctraildepots
defourtext transopts_ctroaddepots
defourtext transopts_ctshipdepots
defourtext transopts_ctbridges
defourtext transopts_ctobjects
defourtext transopts_ctcompany
defourtext transopts_ttoneway

defourtext industrydirmenu
defourtext industrydir
defourtext industrydiritem0
defourtext industrydiritem1
defourtext industrydiritem2
defourtext sortorder_tooltip
defourtext sortorder_production
defourtext sortorder_type
defourtext sortorder_transported
defourtext sortorder_name

defourtext objectbuild
defourtext objecterr
defourtext objecterr_wrongclimate
defourtext objecterr_wronggamemode
defourtext objecterr_noaction3
defourtext objecterr_tooearly
defourtext objecterr_toolate
defourtext objecterr_invalidsize
defourtext objecterr_poolfull
defourtext objectgui_title
defourtext objectgui_cost
defourtext objectgui_size

defourtext winshadetooltip
defourtext minimapautocentertip

defourtext cargopacketwintitle
defourtext moredetailstooltip
defourtext cpgui_dest
defourtext cpgui_full
defourtext cpgui_nexthop
defourtext cpgui_tree
defourtext cpgui_packetdump
defourtext cpgui_routing

defourtext cpgui_pd_amount
defourtext cpgui_pd_cargo
defourtext cpgui_pd_source
defourtext cpgui_pd_dest
defourtext cpgui_pd_lastst
defourtext cpgui_pd_startdate
defourtext cpgui_pd_laststopdate
defourtext cpgui_pd_ttl
defourtext cpgui_pd_flags

defourtext cpgui_cargosum
defourtext cpgui_destline
defourtext cpgui_cargosum_extra
defourtext cpgui_destunroutable
defourtext cpgui_nexthopline

defourtext cpgui_rd_via
defourtext cpgui_rd_days
defourtext cpgui_rd_lastupdate
defourtext cpgui_rd_oldestwaiting

defourtext cpgui_sourceline

defourtext news_newbridge
defourtext news_newbridge_details

defourtext cpgui_treeline

defourtext advorder_branchskipddltxt
defourtext advorder_uncondskipddltxt
defourtext advorder_orderbranchyesguibtntxt
defourtext advorder_orderbranchnoguibtntxt
defourtext advorder_branchskiporderwintxt
defourtext advorder_uncondskiporderwintxt

defourtext objectquery
defourtext objecterr_cantbuildonland
defourtext objectgui_tooltips_menu

; ADD NEW ENTRIES DIRECTLY ABOVE THIS LINE ONLY

defourtext last

%if 0
#endif
%endif

