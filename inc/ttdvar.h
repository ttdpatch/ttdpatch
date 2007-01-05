// import the ttdvar declarations in the assembler
#if WINTTDX
#define ttdvar(a,b) asm (".global _" #a "\n.set _" #a ", _ttdvar_base+0x80000000+" #b);
#else
#define ttdvar(a,b) asm (".set _" #a "," #b);
#endif
#define __C_SOURCE__

#define landscape4 landscape4base // In C code, use of extern char landscape4[256][256]; is preferred.
#define landscape5 landscape5base

#include <ttdvar.inc>

// to define their size and access them in C code, you still need something like
// extern uint16_t operrormsg1;
