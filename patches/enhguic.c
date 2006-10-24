#include <stdint.h>
#include <ttdvar.h>

// to define a keyword without leading underscore in the .o file
// for keywords defined in the asm source; not for ttdvars!
#define ASM(x) x asm(#x)

// same for global functions defined in this file
#define ASMFUNC(x) x() asm(#x)

extern uint16_t dragtoolstartx;
extern uint16_t dragtoolstarty;
extern uint16_t dragtoolendx;
extern uint16_t dragtoolendy;
extern uint16_t landscapemarkerorigx;
extern uint8_t ASM(diagonalflags);
extern uint8_t ASM(curdiagstartpiece);
extern uint8_t ASM(curdiagtool);
extern uint16_t operrormsg1;
extern uint8_t * ASM(curtooltracktypeptr);
extern uint32_t ASM(railbuttons);
extern uint16_t mouseflags;

// assumes X,Y is already in AX,CX, returns converted X,Y in X and Y
// this can't be an inline function, since we want the results to be directly placed in two variables.
#define ScreenToLandscapeCoords(X, Y) 							\
	asm ("pushl\t%%ebp\n\tcall\t*ScreenToLandscapeCoords\n\tpopl\t%%ebp" 		\
			: "=a" (X), 							\
			  "=c" (Y) 							\
			: 								\
			: "ebx","edx","edi","esi" 					\
	    );

static inline void RefreshLandscapeHighlights() __attribute__ ((always_inline));
static inline void RefreshLandscapeHighlights() {
	asm volatile ("pushl\t%%ebp\n\tcall\t*RefreshLandscapeHighlights\n\tpopl\t%%ebp"	
			:								
			:								
			: "eax","ecx","edx","ebx","edi","esi"				
	    );
}

static inline void SetMouseTool(int16_t ToolWinType, int16_t WinID, int32_t CursorSprite, int32_t CursorAnim) __attribute__ ((always_inline));
static inline void SetMouseTool(int16_t ToolWinType, int16_t WinID, int32_t CursorSprite, int32_t CursorAnim) {
	asm volatile ("pushl\t%%ebp\n\tcall\t*setmousetool\n\tpopl\t%%ebp"
			:
			: "a" (ToolWinType),
			  "d" (WinID),
			  "b" (CursorSprite),
			  "S" (CursorAnim)
			: "ecx", "edi"
	    );
}

static inline int32_t CallAction(int32_t action, int16_t x, int16_t y, int32_t ebx, int32_t edx, int32_t edi) __attribute__ ((always_inline));
static inline int32_t CallAction(int32_t action, int16_t x, int16_t y, int32_t ebx, int32_t edx, int32_t edi) {
	int32_t cost;
	asm volatile("pushl\t%%ebp\n\tcall\t*actionhandler\n\tpopl\t%%ebp"
			: "=b"(cost)
			: "a"(x),
			  "c"(y),
			  "b"(ebx),
			  "d"(edx),
			  "D"(edi),
			  "S"(action)
	    );
	return cost;
}

static inline void GenerateSoundEffect(int32_t soundnr, int16_t x, int16_t y) __attribute__ ((always_inline));
static inline void GenerateSoundEffect(int32_t soundnr, int16_t x, int16_t y) {
	asm volatile("movl\t$-1,%%esi\n\tcall\t*generatesoundeffect"
			:
			: "a"(soundnr),
			  "b"(x),
			  "c"(y)
			: "esi"
		    );
}

#define CallPatchAction(name, x, y, ebx, edx, edi, cost) 							\
	asm volatile("pushl\t%%ebp\n\tmovl\t$" #name "_actionnum, %%esi\n\tcall\t*actionhandler\n\tpopl\t%%ebp"	\
			: "=b"(cost)										\
			: "a"(x),										\
			  "c"(y),										\
			  "b"(ebx),										\
			  "d"(edx),										\
			  "D"(edi)										\
			: "esi"											\
		    );

typedef struct window {
	int8_t  type;
	int8_t  itemstotal;
	int8_t  itemsvisible;
	int8_t  itemsoffset;
	int16_t flags;
	int16_t id;
	int16_t x;
	int16_t y;
	int16_t width;
	int16_t height;
	int16_t opclassoff;
	int32_t function;
	int32_t viewptr;
	int32_t activebuttons;
	int32_t disabledbuttons;
	int16_t selecteditem;
	int32_t elemlistptr;
	int8_t  company;
	int8_t  unknown_0;
	int8_t  data[10];
} __attribute__ ((packed)) window;

void ASMFUNC(DragNSRailUITick);
void DragNSRailUITick() {
	int16_t X, Y, diff, dx, dy;
	ScreenToLandscapeCoords(X, Y);
	if (X == -1) return;	// call failed
	landscapemarkerorigx = 1; // Make sure the tiles get redrawn.
	RefreshLandscapeHighlights();
	dx = X - dragtoolstartx;
	dy = Y - dragtoolstarty;
	diagonalflags &= 3;
	curdiagstartpiece = 4;	// west
	if (dx < dy) {
		diagonalflags |= 4;
		curdiagstartpiece = 5;	// east
	}
	diff = ((dx + dy)>>1);
	dx = (X & 0xFFF0) - dragtoolstartx;
	dy = (Y & 0xFFF0) - dragtoolstarty;
	if ( ( (dx - dy) == 16) ||
	     ( (dy - dx) == 16) || 
	       (dx == dy) ) {
		dragtoolendx = dragtoolstartx + dx;
		dragtoolendy = dragtoolstarty + dy;
	} else {
		dragtoolendx = (diff & 0xFFF0) + dragtoolstartx;
		dragtoolendy = (diff & 0xFFF0) + dragtoolstarty;
		if (diff < 0) {
			if ( (diff & 0xF) < 8 ) {
				if ( (diagonalflags & 4) == 0) {
					dragtoolendy -= 16;
				} else {
					dragtoolendx -= 16;
				}
			}
		} else {
			if ( (diff & 0xF) > 7 ) {
				if ( (diagonalflags & 4) == 0) {
					dragtoolendx += 16;
				} else {
					dragtoolendy += 16;
				}
			}
		}
	}
	RefreshLandscapeHighlights();
}

void ASMFUNC(DragEWRailUITick);
void DragEWRailUITick() {
	int16_t X, Y, diff, dx, dy;
	ScreenToLandscapeCoords(X, Y);
	if (X == -1) return;	// call failed
	landscapemarkerorigx = 1; // Make sure the tiles get redrawn.
	RefreshLandscapeHighlights();
	dx = X - dragtoolstartx;
	dy = 16-(Y - dragtoolstarty);
	diagonalflags &= 3;
	curdiagstartpiece = 3; // south
	if (dx < dy) {
		diagonalflags |= 4;
		curdiagstartpiece = 2; // north
	}
	diff = ((dx + dy)>>1);
	dx = (X & 0xFFF0) - dragtoolstartx;
	dy = -((Y & 0xFFF0) - dragtoolstarty);
	if ( ( (dx - dy) == 16) ||
	     ( (dy - dx) == 16) || 
	       (dx == dy) ) {
		dragtoolendx = dragtoolstartx + dx;
		dragtoolendy = dragtoolstarty - dy;
	} else {
		dragtoolendx = (diff & 0xFFF0) + dragtoolstartx;
		dragtoolendy = -(diff & 0xFFF0) + dragtoolstarty;
		if (diff < 0) {
			if ( (diff & 0xF) < 8 ) {
				if ( (diagonalflags & 4) == 0) {
					dragtoolendy += 16;
				} else {
					dragtoolendx -= 16;
				}
			}
		} else {
			if ( (diff & 0xF) > 7 ) {
				if ( (diagonalflags & 4) == 0) {
					dragtoolendx += 16;
				} else {
					dragtoolendy -= 16;
				}
			}
		}
	}
	RefreshLandscapeHighlights();
}

void ASMFUNC(ReleaseNSorEWRail);
void ReleaseNSorEWRail() {
	window *win;
	asm("" : "=S" (win):  );
	
	if (dragtoolendx != (uint16_t)-1) {
		int32_t cost;
		operrormsg1 = 0x1011 + (railbuttons & (1 << 14) ? 1 : 0);
		CallPatchAction(builddiagtrackspan, dragtoolstartx, dragtoolstarty, 11 + ((railbuttons & (1 << 14) ? 1 : 0) << 8), dragtoolendx | (dragtoolendy << 16), curdiagstartpiece | (*curtooltracktypeptr << 16), cost);
		if (cost != 0x80000000) {
			GenerateSoundEffect(0x1E, dragtoolstartx, dragtoolstarty);
		}
	}
	
	SetMouseTool(1 + (3 << 8), 0, 1263 + (curdiagtool == 1 ? 0 : 2) + 4 * *curtooltracktypeptr, 0);
	win->activebuttons = railbuttons;
	if (railbuttons & (1 << 14)) {
		mouseflags |= (1 << 4);
	}
	RefreshLandscapeHighlights();
}

