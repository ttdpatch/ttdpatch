#ifndef __GRF_INC__
#define __GRF_INC__

	// first sprite number to be used for TTDPatch sprites
baseoursprites equ 4900
totalsprites equ 0x131a+6*WINTTDX	// Windows TTD has six more (for Fish UK logo etc.?)

	// GRF version we currently support
#define THISGRFVERSION 2

	// maximum GRF version compatible with this patch version
#define MAXGRFVERSION 6

	// number of GRF features supported for actions 0, 1, 2, 3 etc.
%define NUMFEATURES 13

%assign NBRIDGES	11

%define NUMCARGOS 32		// if newcargos is on


#define MAXLABELS 32

maxstationclasses equ 32

foundationtypes equ 14+8

#define TRAINACTION 0
#define ROADACTION 1
#define SHIPACTION 2
#define AIRCRAFTACTION 3


	// invalid sprite error codes
#define INVSP_ISREAL 1		// using real sprite where pseudo sprite expected
#define INVSP_BADACTION 2	// unknown action
#define INVSP_BADFEATURE 3	// unknown feature (action 0/1/2/3/5)
#define INVSP_BADID 4		// bad action 0 veh(etc.) ID, text ID (action 4) or part ID (action F)
#define INVSP_OUTOFDATA 5	// unexpected end of pseudo sprite data
#define INVSP_BADPROP 6		// unknown property number
#define INVSP_BLOCKTOOLARGE 7	// action 1/5/A sprite block goes beyond end of file
#define INVSP_WRONGFEATURE 8	// action 1/2/3 feature types don't agree
#define INVSP_BADBLOCK 9	// undefined action 1 sprite block
#define INVSP_INVCID 10		// reference to unknown action 2 cid
#define INVSP_INVVAR 11		// invalid variable in action 7/9/D
#define INVSP_MULTACT8 12	// multiple action 8 in one file
#define INVSP_SPNUM 13		// invalid TTD sprite number in action A
#define INVSP_INVSEVERITY 14	// invalid severity in action B
#define INVSP_INVERRMSG 15	// invalid message type in action B
#define INVSP_INVOP 16		// invalid operation type in action D
#define INVSP_ALREADYACT 17	// trying to deactivate already-active grf
#define INVSP_INVPARTS 18	// invalid number of parts in action F
#define INVSP_INVBIT 19		// invalid bit number in action F
#define INVSP_INVLABEL 20	// invalid label number in action 10
#define INVSP_INVRESOURCE 21	// invalid resource definition
#define INVSP_MULTIACT11 22	// multiple action 11 in file
#define INVSP_NOTBININC 23	// not a binary include sprite after action 11
#define INVSP_UNRESID 24	// attempt to modify unreserved ID

#endif	// ndef __GRF_INC__

