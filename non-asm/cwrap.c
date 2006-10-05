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

               int   sourcePatchSize, // source patch size
                                      // this setting creates how "busy" the terrain
                                      // is, the smaller value, the smoother and less
                                      // defined is the terrain

              uint32_t   (*TTD_random)(void)) // pointer to the random number generator function
{

gridArray* source = NULL;
gridArray* desert = NULL;
//gridArray* stenci = NULL;

ulong sourceSize = 64;
ulong resize = 0;
int i_x = 0;
int i_y = 0;
//int i_z = 0;

switch (sourcePatchSize) {

     case 0:  sourceSize = 40;  resize = 32;  break;
     case 1:  sourceSize = 48;  resize = 32;  break;
     case 2:  sourceSize = 56;  resize = 32;  break;
     case 3:  sourceSize = 64;  resize = 64;  break;
     case 4:  sourceSize = 72;  resize = 64;  break;
     case 5:  sourceSize = 80;  resize = 64;  break;
     case 6:  sourceSize = 88;  resize = 64;  break;
     case 7:  sourceSize = 96;  resize = 64;  break;
     case 8:  sourceSize = 104; resize = 64;  break;
     case 9:  sourceSize = 112; resize = 64;  break;
     case 10: sourceSize = 120; resize = 64;  break;
     case 11: sourceSize = 128; resize = 128; break;
     case 12: sourceSize = 132; resize = 128; break;
     case 13: sourceSize = 140; resize = 128; break;
     case 14: sourceSize = 148; resize = 128; break;
     case 15: sourceSize = 152; resize = 128; break;
     case 16: sourceSize = 160; resize = 128; break;
     case 17: sourceSize = 168; resize = 128; break;
     case 18: sourceSize = 176; resize = 128; break;
     case 19: sourceSize = 184; resize = 128; break;
     case 20: sourceSize = 192; resize = 128; break;
     default: sourceSize = 96;  resize = 64;  break;
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

for (i_y = 0;i_y < resize;++i_y)
{
    for (i_x = 0;i_x < resize;++i_x)
    {
	char v = val(i_y,i_x,source);
	
#if WINTTDX
        (&landscape4base)[i_y*256+i_x] = v;
#else
	asm("movb %[v],%%fs:(%[ofs])" : : [v] "q" (v), [ofs] "r" (i_y*256+i_x));
#endif
    }
}

snipArray(source,size_x(source),size_y(source),&desert);
ttDesert(desert,desertMin,desertMax,5,source);

/* for some odd reason genearting a map in tropics causes
the start year to go to 6404. Dunno why (even if I do
nothing to actual values of the desertmap the error persists).
anyhoo - the loop below "fixes" the problem,
but no info i have if this is a proper procedure */

for (i_y = 0;i_y < resize*resize/4;++i_y) {
    (&desertmap)[i_y] = 85;
}

for (i_y = 1;i_y < resize-1;++i_y)
{
    for (i_x = 1;i_x < resize/4-1;++i_x)
    {
        char a, b, c, d;
        a = (char)val(i_y,i_x*4  ,desert);
        b = (char)val(i_y,i_x*4+1,desert);
        c = (char)val(i_y,i_x*4+2,desert);
        d = (char)val(i_y,i_x*4+3,desert);
        if (a!=0)
        {
         if(a == 1)
           a = 1;
         else
           a = 2;
        }
        
        if (b!=0)
        {
          if (b == 1)
            b = 4;
          else
            b = 8;
        }
        
        if (c!=0)
        {
          if (c == 1)
            c = 16;
          else
            c = 32;
        }
        
        if (d!=0)
        {
          if (d == 1)
            d = 64;
          else
            d = 128;
        }
        (&desertmap)[i_y*64+i_x] = a + b + c + d;
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

	terrain(delta, trunc, 1, 6, patch, randomfn);
}
