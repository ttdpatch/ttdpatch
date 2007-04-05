/*
* Adam Kadlubek 2006
* Terrain Generator for TTD
* under GPL license
* version written in C, not protable
* to C++
*
* This is actually a refactor of a C++ class
* that is why all ex-methods have the explicit
* 'this_' pointer
*/
#include <stdint.h>
#include <ttdvar.h>
#include "themes.h"
#include "gridArray.h"
extern char climate;

extern void memcompact() asm("dmemcompact");
extern uint32_t (*randomfn)(void) asm("randomfn");

typedef struct {
	char  deltamin;
	char  deltarange;
	char  truncmin;
	char  truncrange;
} terrain_parm_t;

terrain_parm_t terrain_parms[3][4] = {
	// low water
	{
		{  5, 0, 20, 2},	// very flat
		{  9, 0, 22, 2},	// flat
		{ 14, 0, 24, 2},	// hilly
		{ 19, 0, 28, 2},	// mountaineous
	},

	// medium water
	{
		{  5, 0, 30,  2},
		{  9, 0, 32,  2},
		{ 14, 0, 34,  2},
		{ 19, 0, 38,  2},
	},

	// high water
	{
		{  5, 0, 40,  2},
		{  9, 0, 42,  2},
		{ 14, 0, 44,  2},
		{ 19, 0, 48,  2},
	},
};


/*
* creates freeform terrain
* par1 - amount of hills
* par2 - amount of water
*/

void freeForm (int hills, int water, gridArray** desert_,  gridArray** this_)
{
    terrain_parm_t parm = terrain_parms[water][hills];

    float tmpD = 0.0;
    float tmpH = 0.0;
	int delta = parm.deltamin + (randomfn()%(parm.deltarange+1));
	int trunc = parm.truncmin + (randomfn()%(parm.truncrange+1));
	ulong i_x = 0;
	ulong i_y = 0;

    if (climate == 2) {
    makeArray(64,64,NULL,desert_);
    mulScalar(0.0,*desert_);
    memcompact();
    ttDesert(desert_);
    delta = delta * 0.66f + 4;
    ttMap(delta,28,*this_);
  
    for (i_y = 0;i_y < size_x(*this_);++i_y)
      {
        for (i_x = 0;i_x < size_y(*this_); ++i_x)
        {
          tmpD = val(i_x,i_y, *desert_);
          tmpH = val(i_x,i_y, *this_);
          tmpD++;
          if (tmpD == 0.0 && tmpH/(4.0f - tmpD) < 1.0)
            insert(1.25f,i_x,i_y,*this_);
          else
            insert(tmpH/(3.0f - tmpD),i_x,i_y,*this_);
        }
      }
 
    for (i_x = 0;i_x < size_x(*this_);++i_x)
      {
      for (i_y = 0;i_y < size_y(*this_);++i_y)
        {
          tmpD = val(i_x,i_y,*desert_);
          if (tmpD <= -0.75f)
            insert(1.0,i_x,i_y,*desert_);
          else if (tmpD >= 0.75f)
            insert(2.0,i_x,i_y,*desert_);
          else
            insert(0.0,i_x,i_y,*desert_);
        }
      }
 
    for (i_x = 0;i_x < size_x(*this_);++i_x)
      {
      for (i_y = 0;i_y < size_y(*this_);++i_y)
        {
          shoreStomp(i_x,i_y,*this_,*desert_);
        }
      }
    ttMap(delta,0.0f,*this_);
    
  } else {
    ttMap(delta,trunc,*this_);
  }
}

/*
* creates a classic arctic/tropic terrain (half one thing, half another)
*/

void classic (gridArray** desert_, gridArray** this_)
{
 }

/*
* creates a valley themed terrain
* par1 - width of the river inside
*/

void valley (int width, gridArray** desert_, gridArray** this_)
{
     
     float min = 1.0;
     float max = 2.0;
     int i_x = 0;
     int i_y = 0;
     float val = 0.0;
     
     
     
     makeArray(size_x(*this_),size_y(*this_),NULL,desert_);
     mulScalar(0.0,*desert_);
     
     for (i_x = 0;i_x < size_x(*this_);++i_x)
     {
         for (i_y = 0;i_y <= size_y(*this_)/2;++i_y)
         {
             val = (1.0*((size_y(*this_)/2)-i_y))/(size_y(*this_)/2);
             insert(val,i_x,i_y,*desert_);
             insert(val,i_x,size_y(*this_)-i_y,*desert_);
         }
     }
     
//     normalize(max,*desert_);
//     addScalar(min,*desert_);
//     mulArray(*desert_,*desert_);
     normalize(0.45,*desert_);
     addScalar(0.55,*desert_);
     mulArray(*desert_,*this_);
     ttMap(16,17 + width*4,*this_);
     destroyArray(desert_);
     memcompact();
     
     if (climate == 2)
     {
       ttDesertBelow(6,*this_,desert_);
     }
     
 }

/*
* creates a mountain range through the terrain
* par 1 - width of the shores
*/

void mountains (int width, gridArray** desert_, gridArray** this_)
{
     int i_x = 0;
     int i_y = 0;
     float val = 0.0;
     
     makeArray(size_x(*this_),size_y(*this_),NULL,desert_);
     mulScalar(0.0,*desert_);
     
     if (randomfn()%100 > 50)
     {
         for (i_x = 0;i_x < size_x(*this_);++i_x)
         {
             for (i_y = size_y(*this_)/2;i_y >= 0;--i_y)
             {
                 val = (1.0*(i_y))/(size_y(*this_)/2);
                 insert(val,i_x,i_y,*desert_);
                 insert(val,i_x,size_y(*this_)-i_y,*desert_);
             }
         }
     } else {
         for (i_y = 0;i_y < size_y(*this_);++i_y)
         {
             for (i_x = size_x(*this_)/2;i_x >= 0;--i_x)
             {
                 val = (1.0*(i_x))/(size_x(*this_)/2);
                 insert(val,i_x,i_y,*desert_);
                 insert(val,size_x(*this_)-i_x,i_y,*desert_);
             }
         }       
     }
     
     normalize(1.0, *desert_);
     
     mulArray(*desert_,*this_);

     normalize(3.2,*this_);
     addScalar(1.2,*this_);
     mulArray(*this_,*this_);
     mulArray(*this_,*this_);
     normalize(16,*this_);
     ttMap(18,width*3,*this_);
     destroyArray(desert_);

     *desert_ = NULL;
     memcompact();
     
     if (climate == 2)
     {
       ttDesertBelow(6,*this_,desert_);
     }
 }

/*
* creates a shoreline - ie mountains at one edge and sea on the other
* par1 - max height
* par2 - angle
*/

void shoreline (int height, int angle, gridArray** desert_, gridArray** this_)
{
 }

/*
* creates an atol - ie an island circular in shape
* note - no desert will be created!
*/

void atolTheme (gridArray** this_)
{
 }

/*
* creates a longmap - ie a twisty S shaped map
* par1 - amout of hilliness
*/

void longmap (int hills, gridArray** desert_, gridArray** this_)
{
 }
