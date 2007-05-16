
#include "gridArray.h"


/*
* Adam Kadlubek 2006
* Terrain Generator for TTD
* under GPL license
* version written in C, not protable
* to C++
*
* This is actuall a refactor of a C++ class
* that is why this then "extern "C" " func
* was provided. Now all it does is launch
* the generation and pit the results into
* the appropiate arrays
*/

#include <stdint.h>
#include <ttdvar.h>

#include "themes.h"

extern char landscape4[0x100][0x100];
extern char desertmap[0x100][64];

extern uint8_t terraintype;     // hills setting (par 1)
extern uint8_t quantityofwater; // water setting (par 2)
extern char climate;            // 0 - temprate, 1 - snow, 2 - desert, 3 - toyland)
static uint8_t theme = 0;
                                // 0 - freeform
                                // 1 - valley
                                // 2 - mountains
                                // 3 - shoreline
                                // 4 - atol
                                // 5 - longmap
                                
static uint8_t forced = 0;

extern void memcompact() asm("dmemcompact");
extern uint32_t (*randomfn)(void) asm("randomfn");
extern int32_t landgen_forceparam asm("landgen_forceparam");

#define OUTPUT_FILE // undef this to disable outputing the heightmap and
                    // desert map as bmps

static const char deserttype[4] = { 1, 0, 2, 2 };

void makerandomterrain()
{

// landgen cheat solution goes here

int sourcePatchSize = 5 + randomfn()%5;

int par1 = terraintype;
int par2 = quantityofwater;


gridArray* source = NULL;
gridArray* desert = NULL;

ulong sourceSize = 96;
ulong resize = 64;
int i_x = 0;
int i_y = 0;


if (sourcePatchSize <= 20) {
     sourceSize = (sourcePatchSize + 5) * 8;
     resize = 1 << ((sourcePatchSize + 5) / 8 + 5);
}


if (theme == 3 || theme == 2)
{
makeArray(192, 192, randomfn, &source);
} else {
makeArray(sourceSize+randomfn()%64-48, sourceSize+randomfn()%64-48, randomfn, &source);
}

if (landgen_forceparam != -1) {
  	                par1 =  landgen_forceparam & 0xff;
 	                par2 = (landgen_forceparam >> 8) & 0xff;
 	                sourceSize = (landgen_forceparam >> 16) & 0xff; 	                
 	                theme = (landgen_forceparam >> 24) & 0x3f;
 	                destroyArray(&source);
 	                makeArray(sourceSize, sourceSize, randomfn, &source);
 	                forced = 1;
 	                if (par1 >= par2) par2 = par1+1;
}

go(5,&source);

normalize(1.0,source);

while (resize < 256) {
    resize *= 2;
    scale(resize,resize,&source);
    filter(4,&source);
}

normalize(1.7,source);
addScalar(1.4,source);
mulArray(source,source);
normalize(1.0,source);

makeArray(256,256,randomfn, &desert);
memcompact();
normalize (0.035*(1.0/(terraintype*4+1)), desert);
addArray(desert,source);
destroyArray(&desert);
memcompact();

switch (theme)
{
case 0: freeForm(par1, par2, forced, &desert, &source); break; // use default theme
case 1: valley(par2, forced, &desert, &source); break;
case 2: mountains(par2, forced, &desert, &source); break;
default: freeForm(par1,par2, forced, &desert, &source); break;
}

for (i_y = 0;i_y < resize-1;++i_y)	// don't touch southern-most tiles
{
    for (i_x = 0;i_x < resize-1;++i_x)	// because they contain guard tiles
    {
	char v = val(i_y,i_x,source);

	// set height, but make sure we're not overwriting guard tiles
#if WINTTDX
#if DEBUG
        if (landscape4[i_y][i_x])
          asm("ud2");
#endif
        landscape4[i_y][i_x] = v;
#else
#if DEBUG
        char old;
        asm("movb %%fs:(%[ofs]),%[old]" : [old] "=q" (old) : [ofs] "r" (i_y*256+i_x));
        if (old)
          asm("ud2");
#endif
	asm("movb %[v],%%fs:(%[ofs])" : : [v] "q" (v), [ofs] "r" (i_y*256+i_x));
#endif
    }
}

if (climate == 2)
  for (i_y = 0;i_y < resize;++i_y)
    {
      for (i_x = 0;i_x < resize/4;++i_x)
      {
        unsigned char a, b, c, d;
        a = (char)val(i_y,i_x*4  ,desert);
        b = (char)val(i_y,i_x*4+1,desert);
        c = (char)val(i_y,i_x*4+2,desert);
        d = (char)val(i_y,i_x*4+3,desert);

        desertmap[i_y][i_x] = a + (b << 2) + (c << 4) + (d << 6);
      }
    }
destroyArray(&source);
if (climate == 2)
destroyArray(&desert);
memcompact();
}
