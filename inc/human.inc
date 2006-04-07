
// for Ctrl key and player checks

#define CTRL_DEFAULT 0	// only human player, and only in single player
#define CTRL_ANY 1	// any player can be active (use only if current player is undefined)
#define CTRL_MP 2	// multiplayer games too

// also all of the following are valid for ctrlkeystate:

#define PL_DEFAULT 0	// only real human player
#define PL_PLAYER 4	// assume current player, stored in high byte of low word on stack
#define PL_NOTTEMP 8	// but not ai companies temporarily managed by human
#define PL_ORG 16	// also original human companies temporarily unmanaged
#define PL_RETURNCURRENT 32	// return current player in ecx

