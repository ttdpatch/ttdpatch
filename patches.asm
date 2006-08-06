//
// patches.asm - list the procs that do the actual patching
//

// procs that do not depend on the order in which they're called and
// work when called can also simply be defined in their procs/*.asm file,
// that will work just fine; see patch.ld and ttdprot*.map for details

#include <defs.inc>
#include <frag_mac.inc>
#include <window.inc>

#define __extern_procs__ 1
#include <patchproc.inc>

	// list of patchprocs that require special ordering

	patchproc anyflagset, dogeneralpatching

	patchproc anyflagset, patchloadunload

#if WINTTDX
	patchproc resolutionwidth,resolutionheight, patchresolution
#endif
	patchproc enhancegui,locomotiongui, patchdynamicmemory	// only used currently by enhancegui

	patchproc uselargerarray,enhancemultiplayer, newsavename
	patchproc uselargerarray, patchuselargerarray
	patchproc bribe,newtowngrowthfactor,newtowngrowthrate,displmoretownstats,newhouses, patchmoretowndata
		// same as the previous one plus generalfixes:
	patchproc bribe,newtowngrowthfactor,newtowngrowthrate,displmoretownstats,newhouses,generalfixes, patchtowninit
	patchproc usenewmountain, patchusenewmountain	// must be before patchtrainaccel
	patchproc rvpower, patchrvpower			// must be after patchusenewmountain
	patchproc rvpower,newrvs, patchrvinfowindow
	patchproc usenewcurves,usenewmountain,multihead,newtrains,wagonspeedlimits, patchtrainaccel
	patchproc usenewcurves, patchusenewcurves
	patchproc usenewnonstop,newstations, patchusenewnonstop
	patchproc increasetraincount, patchincreasetraincount
	patchproc increaservcount, patchincreaservcount
	patchproc increaseplanecount, patchincreaseplanecount
	patchproc increaseshipcount, patchincreaseshipcount
	patchproc setnewservinterval, patchsetnewservinterval
	patchproc setnewservinterval,autorenew,gotodepot, patchmaintcheck
	patchproc sharedorders,gotodepot, patchschedulefuncs
	patchproc gotodepot, patchgotodepot
	patchproc gotodepot,buildonslopes, patchnewdepottypeandcost
	patchproc largerstations, patchstationspread
	patchproc morestationtracks,irrstations, patchmorestationtracks
	patchproc morestationtracks,pathbasedsignalling,irrstations, patchstationtarget
	patchproc generalfixes,feederservice, patchenroutetime
	patchproc gradualloading,newcargos, patchloadtimedone
	patchproc higherbridges,enhancetunnels, patchhigherbridges	// must be before buildonslopes, destroys oldcanstartendbridgehere
	patchproc buildonslopes, autoslope, patchbuildonslopes	// must be before manuconv (which destroys a search string)
	patchproc buildonslopes,newplanes, patchaircraftdispatch
	patchproc manualconvert, patchmanuconv		// must be before patchbridgeheads
	patchproc custombridgeheads, patchbridgeheads	// must be before patchpathbasedsignalling

	patchproc newstations,trams, patchbusstopmovement	// must be before patchpathbasedsignalling

	patchproc pathbasedsignalling, patchpathbasedsignalling	// must be before signal changing code
	patchproc presignals,extpresignals,locomotiongui, patchsignals
	patchproc extpresignals,semaphoresignals,pathbasedsignalling, patchmodifysignals
	patchproc noinflation, patchnoinflation

#if WINTTDX
	// must be before subsidiaries
	patchproc enhancemultiplayer, patchenhmulti
#endif
		// subsidiaries must be patched before maxloanwithctrl
	patchproc subsidiaries, patchsubsidiaries
	patchproc subsidiaries,morestats, patchcompanywindow
	patchproc anyflagset, patchmaxloanwithctrl
	patchproc fullloadany, patchfullloadany
	patchproc selectstationgoods, patchselectstationgoods
	patchproc keepsmallairports, patchkeepsmallairports
	patchproc longerbridges, patchlongerbridges
	patchproc morethingsremovable, patchmorethingsremovable
	patchproc morethingsremovable,generalfixes, patchremovebridgeortunnel

//!	patchproc aibooster, patchaibooster
	patchproc multihead, patchmultihead
	patchproc multihead,unifiedmaglev,newtrains,saveoptdata, patchwaggoncheck	// must include all switches from patchrailvehiclelist
	patchproc newlineup, patchnewlineup
	patchproc generalfixes, patchgeneralfixes
	patchproc generalfixes,sharedorders, patchsaveschedule

#if WINTTDX
	patchproc win2k, patchwin2k
	patchproc generalfixes,win2k,enhancedkbdhandler, patchscreenshots
	patchproc generalfixes,win2k, patchpanning
	patchproc generalfixes,win2k,disconnectontimeout,enhancemultiplayer, patchnetplay
	patchproc enhancemultiplayer,NOTBIT(MISCMODS_NOTIMEGIVEAWAY), patchenhmultiortime
#else
	patchproc generalfixes,enhancedkbdhandler, patchscreenshots
	patchproc generalfixes,disconnectontimeout, patchnetplay
#endif
	patchproc enhancedkbdhandler, patchkbdhandler

	patchproc morebuildoptions, patchmorebuildoptions
	patchproc morethingsremovable,morebuildoptions, patchremovespecobjects
	patchproc bribe, patchbribe			// must be after patchgeneralfixes (destroys a search string)
	patchproc noplanecrashes, patchnoplanecrashes
	patchproc showspeed, patchshowspeed
	patchproc officefood, patchofficefood
	patchproc usesigncheat, patchusesigncheat
	patchproc moreairports, patchmoreairports
	patchproc allowtrainrefit,newtrains, patchallowtrainrefit
	patchproc newships,newrvs,newtrains,newplanes, patchrefitting
	patchproc newships,newrvs,newtrains,newplanes, patchnewvehs
	patchproc newships,newrvs,newtrains,newplanes,generalfixes, patchstartstop
	patchproc newships, patchnewships
	patchproc newrvs, patchnewrvs
	patchproc newplanes, patchnewplanes
//	patchproc moresignals, patchmoresignals
//	patchproc hugeairport, patchhugeairport
	patchproc moveerrorpopup, patcherrorpopups
	patchproc setsignal1waittime,setsignal2waittime, patchsignalwaittime
	patchproc maskdisasters, patchdisastersmask	// must be before patcheternalgame (which destroys a search string)
	patchproc morenews, patchmorenews
	patchproc morenews,pathbasedsignalling, patchclearcrashedtrain
	patchproc unifiedmaglev,newtrains,saveoptdata, patchrailvehiclelist	// all switches here must also be present for patchwaggoncheck, patchaibuyvehicle and the testmultiflags in patchaibuyvehicle
	patchproc unifiedmaglev,newtrains,newrvs,newplanes,newships,saveoptdata, patchaibuyvehicle
	patchproc unifiedmaglev,newtrains,newrvs,newships,newplanes,saveoptdata,newstartyear, patchairandomroutes
	patchproc generalfixes,unifiedmaglev, patchrailconsmenu
	patchproc unifiedmaglev, patchunifiedmaglev
	patchproc newtrains, patchnewtrains
	patchproc newtrains,pathbasedsignalling, patchtrainreverse
//	patchproc rvpower, patchrvpower
	patchproc persistentengines,newtrains,newrvs,newships,newplanes, patchpersistentengines	// must be after patchrailvehiclelist (destroys search string)
	patchproc eternalgame,generalfixes, patch2070servint
	patchproc eternalgame, patcheternalgame
	patchproc showfulldate,gamespeed, patchshowfulldate
	patchproc signalsontrafficside, patchsignalsontrafficside
	patchproc newstartyear, patchstartyear
	patchproc newerrorpopuptime, patcherrorpopuptime
	patchproc newtowngrowthfactor, patchtowngrowthfactor
//	patchproc largertowns,newtowngrowthrate, patchtowngrowthrate
	patchproc newtowngrowthfactor,newtowngrowthrate,generalfixes, patchtowngrowthmisc
	patchproc displmoretownstats, patchmoretownstats
	patchproc diskmenu, patchdiskmenu		// must be after patchunifiedmaglev (destroys a search string)
	patchproc diskmenu,generalfixes, patchdefaultsavetitle
	patchproc newhouses, patchnewhousedata

		// must be processed after any patch that adds new graphics
	patchproc diskmenu,enhancegui,canmodifygraphics, patchdropdownmenu
	patchproc feederservice,gradualloading,canmodifygraphics,fifoloading, patchenterstation
	patchproc autorenew,canmodifygraphics,pathbasedsignalling,newtrains, patchtrainenterdepot
	patchproc autorenew,canmodifygraphics, patchautorenew

		// enhancetunnels requires access to sprite 4898
	patchproc canmodifygraphics,enhancetunnels, patchmovespriteinfo

	patchproc electrifiedrail, patchelectrifiedrail		// must be after patchunifiedmaglev
	patchproc locomotiongui, patchlocomotiongui		// must be before patchstationgraphics
	patchproc electrifiedrail,newstations, patchstationgraphics	// must be before patchsetnewgraphics
	patchproc newstations,trams, patchbusstop		// need stuff set via patchstationgraphics!

		// all patch bits that use overrideembeddedsprite must be listed below
	patchproc generalfixes,canmodifygraphics,morecurrencies,enhancegui,enhancetunnels, patchsetspritecache	// must be after patchmovespriteinfo
	patchproc canmodifygraphics, patchtranslation		// must be before patchsetnewgraphics
	patchproc canmodifygraphics, patchsetnewgraphics	// must be after patchsetspritecache
	patchprocandor canmodifygraphics,NOTBIT(MISCMODS_SMALLSPRITELIMIT),, patchextendedspritelimit
	patchproc enhancegui, patchwindowsizer
	patchprocandor newshistory,enhancegui,, patchnewshistory	// must be before patchmorewindows


	// NOTE:
	// If you were going to put your patchproc here, just put it in
	// the procs/ asm file instead, include <patchproc.inc> and it 
	// will work just fine (this makes diffs work better)
	// The patchprocs listed in procs/* files will be run after all
	// of the above, in alphabetical order (see patch.ld and
	// ttdprot*.map for details).



// for the linker (it can't read .h files, so we need to define a symbol instead)
global __recordversiondata
__recordversiondata equ recordversiondata

// general purpose fragments to find accesses to some variables etc.

begincodefragments

global variabletofind
glob_frag findvariableaccess
codefragment findvariableaccess
	variabletofind: dd 0

global variabletowrite
glob_frag newvariable
codefragment newvariable
	variabletowrite: dd 0

global findwindowstructuse.ptr
glob_frag findwindowstructuse
codefragment findwindowstructuse
	mov dword [esi+window.elemlistptr],0
findwindowstructuse.ptr equ $-4

endcodefragments

