#include <defs.inc>
#include <frag_mac.inc>

global patchnewdepottypeandcost
patchnewdepottypeandcost:
#if WINTTDX
	patchcode oldcanplacedepot,newcanplacedepot,3,3			// ship
	dec byte [newcanplacedepotarg]
	patchcode oldcanplacedepot,newcanplacedepot,1,2			// road
	dec byte [newcanplacedepotarg]
	patchcode oldcanplacedepot,newcanplacedepot,1,1			// rail
#else
	patchcode oldcanplacedepot,newcanplacedepot,1,3			// ship
	dec byte [newcanplacedepotarg]
	patchcode oldcanplacedepot,newcanplacedepot,2,2			// road
	dec byte [newcanplacedepotarg]
	patchcode oldcanplacedepot,newcanplacedepot,1,1			// rail
#endif
	ret



begincodefragments

codefragment oldcanplacedepot,-2
	cmp ebp,0x80000000
	db 0xf,0x84		// jz near somewhere

codefragment newcanplacedepot
	push byte 0x12			// Note: this is vehicle type
newcanplacedepotarg equ $-1
	call runindex(marknewdepottype)


endcodefragments
