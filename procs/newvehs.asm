#include <defs.inc>
#include <frag_mac.inc>


extern newgraphicssetsenabled


global patchnewvehs
patchnewvehs:
	multipatchcode startstopveh,4
	or byte [newgraphicssetsenabled+1],1 << (10-8)
	ret

#if WINTTDX
var newspritehandlers
	dd addr(newgetplanesprite_start)
	dd addr(newgetrvsprite_start)
	dd addr(newgettrainsprite_start)
	dd addr(newgetshipsprite_start)

var newspritehandlersize
	db newgetplanesprite_end-newgetplanesprite_start
	db newgetrvsprite_end-newgetrvsprite_start
	db newgettrainsprite_end-newgettrainsprite_start
	db newgetshipsprite_end-newgetshipsprite_start

var newdisplayhandlers
	dd addr(newdisplayplane_start)
	dd addr(newdisplayrv_start)
	dd addr(newdisplay2ndeng_start)
	dd addr(newdisplayship_start)

var newdisplayhandlersize
	db newdisplayplane_end-newdisplayplane_start
	db newdisplayrv_end-newdisplayrv_start
	db newdisplay2ndeng_end-newdisplay2ndeng_start
	db newdisplayship_end-newdisplayship_start

var newdisplayhandlers_np
	dd addr(newdisplayplane_noplayer_start)
	dd addr(newdisplayrv_noplayer_start)
	dd addr(newdisplay2ndeng_noplayer_start)
	dd addr(newdisplayship_noplayer_start)

var newdisplayhandlersize_np
	db newdisplayplane_noplayer_end-newdisplayplane_noplayer_start
	db newdisplayrv_noplayer_end-newdisplayrv_noplayer_start
	db newdisplay2ndeng_noplayer_end-newdisplay2ndeng_noplayer_start
	db newdisplayship_noplayer_end-newdisplayship_noplayer_start
#else
var newspritehandlers
	dd addr(newgettrainsprite_start)
	dd addr(newgetrvsprite_start)
	dd addr(newgetshipsprite_start)
	dd addr(newgetplanesprite_start)

var newspritehandlersize
	db newgettrainsprite_end-newgettrainsprite_start
	db newgetrvsprite_end-newgetrvsprite_start
	db newgetshipsprite_end-newgetshipsprite_start
	db newgetplanesprite_end-newgetplanesprite_start

var newdisplayhandlers
	dd addr(newdisplay2ndeng_start)
	dd addr(newdisplayrv_start)
	dd addr(newdisplayship_start)
	dd addr(newdisplayplane_start)

var newdisplayhandlersize
	db newdisplay2ndeng_end-newdisplay2ndeng_start
	db newdisplayrv_end-newdisplayrv_start
	db newdisplayship_end-newdisplayship_start
	db newdisplayplane_end-newdisplayplane_start

var newdisplayhandlers_np
	dd addr(newdisplay2ndeng_noplayer_start)
	dd addr(newdisplayrv_noplayer_start)
	dd addr(newdisplayship_noplayer_start)
	dd addr(newdisplayplane_noplayer_start)

var newdisplayhandlersize_np
	db newdisplay2ndeng_noplayer_end-newdisplay2ndeng_noplayer_start
	db newdisplayrv_noplayer_end-newdisplayrv_noplayer_start
	db newdisplayship_noplayer_end-newdisplayship_noplayer_start
	db newdisplayplane_noplayer_end-newdisplayplane_noplayer_start
#endif


begincodefragments

codefragment oldstartstopveh,-5
	xor word [edx+veh.vehstatus],2

codefragment newstartstopveh
	icall startstopveh
	jc newstartstopveh_start+53
	jz newstartstopveh_start+38
	setfragmentsize 10


codefragment newgettrainsprite
	call runindex(gettrainsprite)
	jnc $+35
	setfragmentsize 14

codefragment newgetrvsprite
	call runindex(getrvsprite)
	setfragmentsize 18

codefragment newgetshipsprite
	call runindex(getshipsprite)
	nop

codefragment newgetplanesprite
	call runindex(getplanesprite)
	nop

codefragment newdisplay2ndeng
	call runindex(display2ndengine)
	setfragmentsize 21

codefragment newdisplay2ndeng_noplayer
	call runindex(display2ndengine_noplayer)
	setfragmentsize 24

codefragment newdisplayrv
	call runindex(displayrv)
	nop

codefragment newdisplayrv_noplayer
	call runindex(displayrv_noplayer)
	setfragmentsize 10

codefragment newdisplayship
	call runindex(displayship)
	nop

codefragment newdisplayship_noplayer
	call runindex(displayship_noplayer)
	setfragmentsize 10

codefragment newdisplayplane
	call runindex(displayplane)
	nop

codefragment newdisplayplane_noplayer
	call runindex(displayplane_noplayer)
	setfragmentsize 10

endcodefragments
