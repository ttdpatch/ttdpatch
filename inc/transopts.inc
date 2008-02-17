
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
#define TROPT_INVISIBLETREES 10

%assign defaulttrans 07FFh & ~(1<<TROPT_INVISIBLETREES) & ~(1<<TROPT_BRIDGE) & ~(1<<TROPT_ROADDEPOT)
%assign alltrans 07FFh & ~(1<<TROPT_INVISIBLETREES)	// Bits that are *really* transparency bits.
