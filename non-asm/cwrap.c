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
void terrain(  int   maxHeight, // the desired difference between lowest and highest
                                  // point of the map - roughly the 'amount of hills'
                                  // settings

               float truncHeight, // the desired sink of the map, this value will be
                                  // subtracted the created map array.

               int   desertMin,   // the minimum height the desert will appear

               int   desertMax,   // the maximum height the desert will appear

               int   rainforestMin,   // minimum height of rainforest

               int   sourcePatchSize, // source patch size
                                      // this setting creates how "busy" the terrain
                                      // is, the smaller value, the smoother and less
                                      // defined is the terrain

              uint32_t   (*TTD_random)(void)) // pointer to the random number generator function
{

gridArray* source = NULL;
gridArray* desert = NULL;
//gridArray* stenci = NULL;

ulong sourceSize = 96;
ulong resize = 64;
int i_x = 0;
int i_y = 0;
//int i_z = 0;

if (sourcePatchSize <= 20) {
     sourceSize = (sourcePatchSize + 5) * 8;
     resize = 1 << ((sourcePatchSize + 5) / 8 + 5);
}

makeArray(sourceSize+TTD_random()%64-32, sourceSize+TTD_random()%64-32, TTD_random, &source);

//stencil(valley_data, &stenci);

go(5,&source);

normalize(1.0,source);

while (resize < 256) {
    resize *= 2;
    scale(resize,resize,&source);
    filter(4,&source);
}



/*makeArray(256,256,TTD_random, &desert);
go(5,&desert);
normalize (0.25,desert);
addArray(desert,source);
destroyArray(&desert);*/

/*normalize(1.0,source);
mulArray(stenci,source);
destroyArray(&stenci);*/

normalize(1.7,source);
addScalar(1.4,source);
mulArray(source,source);
normalize(1.0,source);

makeArray(256,256,TTD_random, &desert);
normalize (0.1*(1.0/maxHeight), desert);
addArray(desert,source);
destroyArray(&desert);

/*for (i_y = 0;i_y < resize;++i_y)
{
    for (i_x = 0;i_x < 128;++i_x)
    {
        shift_y(1,i_y,source);
    }
}*/


ttMap(maxHeight,truncHeight,source);

for (i_y = 0;i_y < resize-1;++i_y)	// don't touch southern-most tiles
{
    for (i_x = 0;i_x < resize-1;++i_x)	// because they contain guard tiles
    {
	char v = val(i_y,i_x,source);

	// set height, but make sure we're not overwriting guard tiles
#if WINTTDX
#if DEBUG
        if ((&landscape4base)[i_y*256+i_x])
          asm("ud2");
#endif
        (&landscape4base)[i_y*256+i_x] = v;
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

snipArray(source,size_x(source),size_y(source),&desert);
ttDesert(desert,desertMin,desertMax,rainforestMin,5,source);

for (i_y = 0;i_y < resize;++i_y)
{
    for (i_x = 0;i_x < resize/4;++i_x)
    {
        unsigned char a, b, c, d;
        a = (char)val(i_y,i_x*4  ,desert);
        b = (char)val(i_y,i_x*4+1,desert);
        c = (char)val(i_y,i_x*4+2,desert);
        d = (char)val(i_y,i_x*4+3,desert);

        (&desertmap)[i_y*64+i_x] = a + (b << 2) + (c << 4) + (d << 6);
    }
}

destroyArray(&source);
destroyArray(&desert);

}

extern uint8_t terraintype; // We need these variables
extern uint8_t quantityofwater;
extern char climate;

typedef struct {
	char  deltamin;
	char  deltarange;
	char  truncmin;
	char  truncrange;
	char  patchmin;
	char  patchrange;
} terrain_parm_t;

terrain_parm_t terrain_parms[3][4] = {
	// low water
	{
		{  5, 0, 20, 2, 7, 4 },	// very flat
		{  9, 0, 22, 2, 6, 4 },	// flat
		{ 14, 0, 24, 2, 5, 4 },	// hilly
		{ 19, 0, 28, 2, 4, 4 },	// mountaineous
	},

	// medium water
	{
		{  5, 0, 30,  2, 7, 4 },
		{  9, 0, 32,  2, 6, 4 },
		{ 14, 0, 34,  2, 5, 4 },
		{ 19, 0, 38,  2, 4, 4 },
	},

	// high water
	{
		{  5, 0, 40,  2, 7, 4 },
		{  9, 0, 42,  2, 6, 4 },
		{ 14, 0, 44,  2, 5, 4 },
		{ 19, 0, 48,  2, 4, 4 },
	},
};

void makerandomterrain() {
	terrain_parm_t parm = terrain_parms[quantityofwater][terraintype];

	int delta = parm.deltamin + (randomfn()%(parm.deltarange+1));
	int trunc = parm.truncmin + (randomfn()%(parm.truncrange+1));
	int patch = parm.patchmin + (randomfn()%(parm.patchrange+1));

	terrain(delta, trunc, 1, 6, 9, patch, randomfn);
}
