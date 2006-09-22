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

#include <ttdvar.h>
extern char landscape4base;
extern char desertmap;

extern void *randomfn asm("randomfn");

#define OUTPUT_FILE // undef this to disable outputing the heightmap and
                    // desert map as bmps

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

              uint   (*TTD_random)(void)) // pointer to the random number generator function
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

for (i_x = 0;i_x < resize;++i_x)
{
    for (i_y = 0;i_y < resize;++i_y)
    {
#if WINTTDX
        (&landscape4base)[i_y*256+i_x] = (char)(val(i_x,i_y,source));
#else
	char v = (char)(val(i_x,i_y,source));
	int ofs = i_y*256+i_x;
	asm("movb %%al,%%fs:(%[ofs])" : : "a" (v), [ofs] "r" (ofs));
#endif
    }
}

snipArray(source,size_x(source),size_y(source),&desert);
ttDesert(desert,desertMin,desertMax,3,source);

for (i_x = 0;i_x < resize;++i_x)
{
    for (i_y = 0;i_y < resize/4;++i_y)
    {
        char a, b, c, d;
        a = (char)(val(i_x,(i_y*4)  ,desert));
        b = (char)(val(i_x,(i_y*4)+1,desert));
        c = (char)(val(i_x,(i_y*4)+2,desert));
        d = (char)(val(i_x,(i_y*4)+3,desert));
        (&desertmap)[(i_y*256+i_x)>>2] = a + (b<<2) + (c<<4) + (d<<6);
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

void makerandomterrain() {
  // use TTD terrain settings here
  terrain(24, 8, 8, 16, 3, randomfn);
}
