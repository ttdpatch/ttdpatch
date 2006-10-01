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

extern char landscape4base;
extern char desertmap;

extern uint32_t (*randomfn)(void) asm("randomfn");

#define OUTPUT_FILE // undef this to disable outputing the heightmap and
                    // desert map as bmps

static const char deserttype[4] = { 1, 0, 2, 2 };

static
void terrain(  int   deltaHeight, // the desired difference between lowest and highest
                                  // point of the map - roughly the 'amount of hills'
                                  // settings

               float truncHeight, // the desired sink of the map, this value will be
                                  // subtracted the created map array.

               int   desertMin,   // the minimum height the desert will appear

               int   desertMax,   // the maximum height the desert will appear

               int   sourcePatchSize, // source patch size
                                      // this setting creates how "busy" the terrain
                                      // is, the smaller value, the smoother and less
                                      // defined is the terrain
                                      // minimum is 0
                                      // maximum is 5

              uint32_t   (*TTD_random)(void)) // pointer to the random number generator function
{

gridArray* source = NULL;
gridArray* desert =NULL;

ulong sourceSize = 64;
ulong resize = 0;
ulong i_x = 0;
ulong i_y = 0;

if (sourcePatchSize < 6)
  sourceSize = 1 << (sourcePatchSize + 3);

makeArray(sourceSize, sourceSize, TTD_random, &source);

resize = sourceSize;

go(5,&source);
normalize(0.0,1.0,source);

while (resize < 256) {
    resize *= 2;
    scale(resize,resize,&source);
    filter(4,&source);
}

ttMap(truncHeight,deltaHeight,source);

for (i_y = 0;i_y < resize;++i_y)
{
    for (i_x = 0;i_x < resize;++i_x)
    {
	char v = val(i_y,i_x,source);
	
	/*if (v < 0) v = 0;
	else if (v > 15) v = 15;*/
	
	/* this range checking is not necessary, ttmap produces 0..15 range */
	
#if WINTTDX
        (&landscape4base)[i_y*256+i_x] = v;
#else
	asm("movb %[v],%%fs:(%[ofs])" : : [v] "q" (v), [ofs] "r" (i_y*256+i_x));
#endif
    }
}

snipArray(source,size_x(source),size_y(source),&desert);
ttDesert(desert,desertMin,desertMax,3,source);

for (i_y = 0;i_y < resize;++i_y)
{
    for (i_x = 0;i_x < resize/4;++i_x)
    {
        char a, b, c, d;
        a = (char)val(i_x*4  ,i_y,desert);
        b = (char)val(i_x*4+1,i_y,desert);
        c = (char)val(i_x*4+2,i_y,desert);
        d = (char)val(i_x*4+3,i_y,desert);
        (&desertmap)[i_y*64+i_x] = a + (b<<2) + (c<<4) + (d<<6);
    }
}

#ifndef NOBMP
   addScalar (-2.0        ,desert);
   mulScalar (-256.0      ,desert);
   image     ("desert.bmp",desert);
#endif

#ifndef NOBMP
mulScalar (16.0         ,source);
image     ("terrain.bmp",source);
#endif

destroyArray(&source);
destroyArray(&desert);

}

extern uint8_t terraintype; // We need these variables
extern uint8_t quantityofwater;

typedef struct {
	char  deltamin;
	char  deltarange;
	float truncmin;
	float truncrange;
	char  patchmin;
	char  patchrange;
} terrain_parm_t;

terrain_parm_t terrain_parms[3][4] = {
	// low water
	{
		{  4, 4,  0.75, 3.0,  2, 1 },	// very flat
		{ 10, 4,  6.0,  2.0,  2, 2 },	// flat
		{ 14, 4,  8.0,  2.0,  3, 1 },	// hilly
		{ 28, 4, 15.0,  4.0,  3, 2 },	// mountaineous
	},

	// medium water
	{
		{  5, 4,  2.5,  3.5,  3, 1 },
		{ 10, 6,  5.25, 5.0,  3, 2 },
		{ 20, 8, 13.0,  6.0,  3, 1 },
		{ 30,10, 20.0,  6.0,  3, 2 },
	},

	// high water
	{
		{  4, 4,  3.0,  2.0,  2, 1 },
		{ 10, 6,  6.5,  5.0,  2, 2 },
		{ 20,10, 15.0,  7.0,  3, 1 },
		{ 35,16, 26.0, 12.0,  3, 2 },
	},
};

void makerandomterrain() {
	terrain_parm_t parm = terrain_parms[quantityofwater][terraintype];

	uint32_t range1 = randomfn() >> 16;
	uint32_t range2 = randomfn() >> 16;

	int delta = parm.deltamin + (       range1 * parm.deltarange >> 16);
	int trunc = parm.truncmin + ((float)range1 * parm.truncrange / (1 << 16));
	int patch = parm.patchmin + (       range2 * parm.patchrange >> 16);

	if (trunc > delta-2)
		trunc = delta-2;

	terrain(delta, trunc, trunc+2, trunc+5, patch, randomfn);
}
