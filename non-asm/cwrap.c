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

               int   truncHeight, // the desired sink of the map, this value will be
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

ttMap(truncHeight,/*truncHeight+*/deltaHeight,source);

for (i_x = 0;i_x < resize;++i_x)
{
    for (i_y = 0;i_y < resize;++i_y)
    {
	char v = val(i_x,i_y,source);
	if (v < 0) v = 0;
	else if (v > 15) v = 15;
	
	/* this range checking is not necessary, ttmap produces 0..15 range */
	
#if WINTTDX
        (&landscape4base)[i_x*256+i_y] = v;
#else
	int ofs = i_x*256+i_y;
	asm("movb %[v],%%fs:(%[ofs])" : : [v] "q" (v), [ofs] "r" (ofs));
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
	int deltamin;
	int deltarange;
	int truncmin;
	int truncrange;
} terrain_parm_t;

terrain_parm_t terrain_parms[3][4] = {
	// low water
	{
		{ 2, 4, 2, 4 },		// very flat
		{ 6, 2, 8, 4 },		// flat
		{ 8, 4, 8, 4 },		// hilly
		{ 14, 4, 8, 4 }		// mountaineous
	}, 
	// medium water
	{
		{ 2, 4, 8, 2 },
		{ 6, 2, 12, 4 },
		{ 8, 4, 16, 4 },
		{ 16, 4, 32, 8 },
	},
	// high water
	{
		{ 2, 2, 12, 4 },
		{ 6, 2, 16, 4 },
		{ 8, 4, 24, 6 },
		{ 16, 4, 50, 10 },
	},
};

void makerandomterrain() {
//  terrain(24, 8, 0, 8, 3, randomfn); // Orginal function call.
// Note: Lakie's first attempt at making nice randomly generated maps.

	int tmpwater; // Local vars used for calculating some values
	int tmpland;


	if (terraintype != 0) {
		tmpwater = 8+(quantityofwater*(terraintype)); // Right, water should scale against the 'hieght'
	} else {
		tmpwater = 8+quantityofwater; // Water is also scaled at lower heights
	};

	tmpland = 12+(terraintype*3); // Land should increase faster than the water

	DO NOT COMPILE THIS IT DOESN'T WORK

/*
	terrain_parm_t parm = terrain_parms[quantityofwater][terraintype];
	float range = (float)randomfn()/0xffffffff;
	tmpland = parm.deltamin + (int) (range * parm.deltarange);
	tmpwater = parm.truncmin + (int) (range * parm.truncrange);
*/

	if (tmpwater > tmpland-3) { // Make sure our land doesn't diappear
		tmpwater = tmpland-2;
	};

	terrain(tmpland, tmpwater, tmpwater+2, tmpwater+4, ((randomfn()%2)+(terraintype+1)), randomfn); // Actually generate the landscape
}
