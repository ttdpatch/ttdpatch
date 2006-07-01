#define NUMNEWAIRPORTS 15
#define NUMOLDAIRPORTS 4

#define NUMAIRPORTS (NUMNEWAIRPORTS+NUMOLDAIRPORTS)

struc airportmovementnode
	.xpos:		resw 1
	.ypos:		resw 1		// fine coordinates relative to north corner
	.flags:		resb 1
endstruc

#define AIRNODE_TERMINAL 1
#define AIRNODE_HANGAR 2
#define AIRNODE_FORCEDIR 4
//bits 3..5 contain the new direction if forcedir is set

struc airportmovementedge
	.start:		resb 1
	.end:		resb 1		// indexes in the node list
	.specaction:	resb 1
	.flags:		resb 1
	.and_mask:	resd 2		// all of these edges must be clear to use this edge
	.or_mask:	resd 2		// at least one of these edges must be clear...
endstruc

#define AIRSPECAC_NOTHING 0
#define AIRSPECAC_HELITAKEOFF 1
#define AIRSPECAC_HELILAND 2
#define AIRSPECAC_PLANELAND 3
#define AIRSPECAC_PLANESLOWDOWN 4
#define AIRSPECAC_PLANESPEEDUP 5
#define AIRSPECAC_PLANETAKEOFF 6

#define AIREDGE_INTERRUPTIBLE 1
#define AIREDGE_NOTAXI 2
#define AIREDGE_NOSHARPTURN 4
#define AIREDGE_NOHELIS 8
#define AIREDGE_NOPLANES 0x10
#define AIREDGE_NOTTOTERMINAL 0x20
#define AIREDGE_NOTTOHANGAR 0x40
#define AIREDGE_NOTTOOTHERAIRPORT 0x80
