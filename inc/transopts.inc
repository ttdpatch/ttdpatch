
#define TROPT_TREES	0
#define TROPT_TOWN_BLDG	1
#define TROPT_INDUSTRY	2
#define TROPT_STATION	3
#define TROPT_RAILDEPOT	4
#define TROPT_ROADDEPOT	5
#define TROPT_SHIPDEPOT	6
#define TROPT_BRIDGE	7
#define TROPT_OBJECT	8
#define TROPT_HQ	9
#define TROPT_STATUE	9
#define TROPT_ONEWAY	10

#define TROPT__LAST	10
#define TROPT__COUNT	11

struc transopts
	.opts:		resw 1
	.locked:	resw 1
	.invis:		resw 1
endstruc
