#ifndef __GRIDARRAY_H__
#define __GRIDARRAY_H__

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

typedef unsigned long ulong;
typedef unsigned int uint;



#define NOBMP /* undefining this requires
compliation as C++ as BMP is a class */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

typedef struct {

	float** data; /* data array */
    ulong size_x; /* size of the array */
    ulong size_y; /* size of the array */
} gridArray;

//void snipArray (gridArray* source_,ulong  size_x_,ulong  size_y_,gridArray** this_);
/* copy constructor for creating the array from another
   array with its sub-cutted elements */

void makeArray (ulong size_x_, ulong size_y_,uint32_t (*randomizer)(void), gridArray** this_);
/* construct an array of a given size */

void destroyArray(gridArray** this_);
/* destructor of the array */

void mulArray(gridArray* source_,gridArray* this_);
/* multiply elements of one array with elements of this_ array*/

void mulScalar (float scalar, gridArray* this_);
/* scalar multiply operator */

void addArray(gridArray* source_, gridArray* this_);
/* addition of two arrays */

void addScalar(float scalar, gridArray* this_);
/* addition of a value to all array elements */

void scale(ulong newSize_x, ulong newSize_y, gridArray** this_);
/* scale the given array to a new size */

void filter(ulong iterations, gridArray** this_);
/* smooth the given array by x times using bilinear filtering */

void go(ulong iterations, gridArray** this_);
/* do the generation using the iterations set by the user */

void normalize(float hi, gridArray* this_);
/* normalize the array to the low-hi range */

#ifndef NOBMP
static void image(const char* filename, gridArray* this_);
/* inputs the map as a bmp image */
#endif

void ttMap(ulong cutDown, ulong cutUp, gridArray* this_);
/* change the map to fulfill the Transport
   Tycoon requirements for the vertex data */

void ttDesert(gridArray** this_);
/* make TT desert */

#if 0	// never used

void print (gridArray* this_);
/* print the contents of the array */

void shift_x (int dir, ulong row, gridArray* this_);
/* move values by 1 on thr x axis */

void shift_y (int dir, ulong row, gridArray* this_);
/* move values by q on the y axis */

/* in both cases - if dir is negative, shift low->hi
else shift hi->lo */

#endif

/*stomp a circle of normal terrain to make a shoreline green
for desert creation */
void shoreStomp(ulong i_x, ulong i_y,gridArray* geometry, gridArray* this_);

/*
*
* return size of the array
*
*/

static inline ulong size_x(gridArray* this_)
{
  return this_->size_x;
}

/*
*
* likewise
*
*/

static inline ulong size_y(gridArray* this_)
{
  return this_->size_y;
}

/*
*
* return value under indices
*
*/

static inline float val (ulong i_x, ulong i_y, gridArray* this_)
{

  if (size_x(this_) <= i_x || size_y(this_) <= i_y)
    return 0.0;

  return this_->data[i_x][i_y];
}

/*
*
* insert value under indices
*
*/

static inline void insert (float val,ulong i_x, ulong i_y, gridArray* this_)
{
  if (size_x(this_) > i_x && size_y(this_) > i_y)
    this_->data[i_x][i_y] = val;
}

/*
*
* make sure value differs no more than 1 from neighbour
*
*/

static inline void adjust (ulong i_x, ulong i_y, ulong j_x, ulong j_y, int raise, gridArray* this_)
{
  long current = (long)(val(i_x,i_y,this_));
  long prev    = (long)(val(j_x,j_y,this_));

  if (raise) {
    if (current > prev + 1)
      insert (current - 1, j_x, j_y, this_);
    if (current + 1 < prev)
      insert (prev - 1, i_x, i_y, this_);
  } else {
    if (current > prev + 1)
      insert (prev + 1, i_x, i_y, this_);
    else if (current + 1 < prev)
      insert (current + 1, j_x, j_y, this_);
  }
}

/*
*
* check if two verices are close/far away.
* needed for scaling
*
*/

static inline int dist(ulong otherSize, ulong other, ulong mySize, ulong indice, gridArray* this_) {

  float len = 0.0;
  float my = indice *1.0 /mySize;
  float ot = other  *1.0 /otherSize;

  len = (ot-my)*mySize*1.0;
  return (len < 1.0);
}


//void cellularAutomata(ulong pop1, ulong pop2, ulong iters, gridArray** this_);
//void infest(gridArray* source, ulong i_x, ulong i_y, gridArray* this_);

inline static void normalizePoint(ulong i_x, ulong i_y, double low, double hi, double range, gridArray* this_) 
{
    insert((val(i_x,i_y,this_)-low)*(range/hi),i_x,i_y,this_);
}

inline static void ttDesertBelow(int level, gridArray* source, gridArray** this_)
{
    ulong i_x = 0;
    ulong i_y = 0;
    ulong limit_x = size_x(source);
    ulong limit_y = size_y(source);
    
    makeArray(limit_x, limit_y, NULL, this_);
    mulScalar(0.0,*this_);
       
    for (i_x = 0;i_x < limit_x;++i_x)
    {
        for (i_y = 0;i_y < limit_y;++i_y)
        {
            if (val(i_x,i_y,source) > level)
            {
              insert(2.0,i_x,i_y,*this_);
            } else if (val(i_x,i_y,source) > 0 && val(i_x,i_y,source) < level-2)
            {
              insert(1.0,i_x,i_y,*this_);
            }
        }
    }
    
    for (i_x = 0;i_x < limit_x;++i_x)
      {
      for (i_y = 0;i_y < limit_y;++i_y)
        {
          shoreStomp(i_x,i_y,source,*this_);
        }
      }
}

#endif
