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

#define INLINE_DEF
#include "gridArray.h"
#undef INLINE_DEF
#include "cwrap.h"
#include <ttdvar.h>

#ifndef NOBMP
  #include "bmp.h"
#endif

// #define DEBUG

#define TRAP

/*
*
* Snippet constructor - creates an array as a sub-array of another array
*
*/

void snipArray (gridArray* source_,ulong size_x_,ulong size_y_,gridArray** this_) {

    ulong limit_x = 0;
    ulong limit_y = 0;
    ulong i_x = 0;
    ulong i_y = 0;

    /* check if the requested sizes are fitting to the
       size of the array used */

    if (size_x_ > size_x(source_))
    {
	    limit_x = size_x(source_);
    } else {
	    limit_x = size_x_;
    }

    if (size_y_ > size_y(source_))
    {
      limit_y = size_y(source_);
    } else {
      limit_y = size_y_;
    }

    makeArray(limit_x,limit_y,NULL,this_);  

    for (i_x = 0; i_x < limit_x; ++i_x)
    {
        for (i_y = 0; i_y < limit_y; ++i_y)
        {
            (*this_)->data[i_x][i_y] = val(i_x,i_y,source_);
        }
    }
    (*this_)->size_x = limit_x;
    (*this_)->size_y = limit_y;
}

/*
*
* new constructor - creates an array of a given size
* and fill it with random data
*
*/

void makeArray (ulong size_x_,ulong size_y_,uint32_t (*randomizer)(void),gridArray** this_) {

/* first checkif the pointer we get is NULL or not */

    ulong i_x;
    ulong i_y;

    if ((*this_) != NULL)
    {
        /* freeing memory */
        for (i_x = 0;i_x < size_x(*this_);++i_x)
            {
                free((*this_)->data[i_x]);
            }
        free ((*this_)->data);
        free (*this_);
    }

    /* getting memory */

    (*this_) = (gridArray*)malloc(sizeof(gridArray));

    (*this_)->data = (float**)malloc(sizeof(float*)*size_x_);

    for (i_x = 0;i_x < size_x_;++i_x)
        {
           (*this_)->data[i_x] = (float*)malloc(sizeof(float)*size_y_);
        }

    /* done */

    for (i_x = 0;i_x < size_x_; ++i_x)
    {
        for (i_y = 0;i_y < size_y_; ++i_y)
        {
            if (randomizer != NULL)
            (*this_)->data[i_x][i_y] = (randomizer()*1.0/0xffffffff);
            else
            (*this_)->data[i_x][i_y] = 0.0;
        }
    }
    (*this_)->size_x = size_x_;
    (*this_)->size_y = size_y_;
}


/*
*
* add elements of array b to 'this' array
*
*/

void addArray(gridArray* source_,gridArray* this_) {

    ulong limit_x = 0;
    ulong limit_y = 0;
    ulong i_x = 0;
    ulong i_y = 0;

    // check if the array sizes match
    if (size_x(this_) != size_x(source_) && size_y(this_) != size_y(source_))
    {
        return;
    }

    // do the addition

    limit_x = size_x(this_);
    limit_y = size_y(this_);
 
    for (i_x = 0;i_x < limit_x;++i_x)
    {
        for (i_y = 0;i_y < limit_y;++i_y)
        {
            this_->data[i_x][i_y] += val(i_x,i_y,source_);
        }
    }
}

/*
*
* add an value of b to all array elements
*
*/

void addScalar (float scalar, gridArray* this_) {

    ulong limit_x = size_x(this_);
    ulong limit_y = size_y(this_);
    ulong i_x = 0;
    ulong i_y = 0;

    for (i_x = 0;i_x < limit_x;++i_x)
    {
        for (i_y = 0;i_y < limit_y;++i_y)
        {
            this_->data[i_x][i_y] += scalar;
            //insert(1.0,i_x,i_y,this_);
        }
    }
}

/*
*
* multiply the array with a scalar
*
*/

void mulScalar(float scalar, gridArray* this_) {

    ulong limit_x = size_x(this_);
    ulong limit_y = size_y(this_);
    ulong i_x = 0;
    ulong i_y = 0;

    for (i_x = 0;i_x < limit_x;++i_x)
    {
        for (i_y = 0;i_y < limit_y;++i_y)
        {
            this_->data[i_x][i_y] *= scalar;
        }
    }
}

/*
*
* scaling(enlarging) of the image to the x-y
* it is just a pixel resize, to get filtering use filter
* method
*
*/

void scale(ulong newSize_x,ulong newSize_y, gridArray** this_) {

    ulong indiceBuf_x = 0;
    ulong indiceBuf_y = 0;
    ulong i_x = 0;
    ulong i_y = 0;
    gridArray* buffer = NULL;
    gridArray* tmp;
    float tmp2;

    if (newSize_x < size_x(*this_) || newSize_y < size_y(*this_))
        return;

    makeArray(newSize_x,newSize_y,NULL,&buffer); // new, resized array

    while (indiceBuf_x < newSize_x)
    {
          
        if(!dist(newSize_x,indiceBuf_x,size_x(*this_),i_x,*this_))
        {
            ++i_x;
        }
        while (indiceBuf_y < newSize_y)
        {
            if(!dist(newSize_y,indiceBuf_y,size_y(*this_),i_y,*this_))
            {
                ++i_y;
            }
            tmp2 = val(i_x,i_y,(*this_));
            insert(tmp2,indiceBuf_x,indiceBuf_y,buffer);
            indiceBuf_y++;
        }
        indiceBuf_y = 0;
	      i_y = 0;
        ++indiceBuf_x;
    }

    /* the painful part */
    tmp = *this_;
    *this_ = buffer;
    buffer = tmp;
    destroyArray(&buffer);
}

/*
*
* Bilinear filtering of the image
* Ironically - this is the longest stage
*
*/

void filter(ulong iterations, gridArray** this_) {

    gridArray* buffer = NULL;
    gridArray* tmp = NULL;
    float value;

    ulong limit_x = size_x(*this_) - 1;
    ulong limit_y = size_y(*this_) - 1;
    ulong i_x;
    ulong i_y;
    ulong iter;

    makeArray(size_x(*this_),size_y(*this_),NULL,&buffer);

    for (iter = 0;iter < iterations;++iter) {

        // first stage - body of the heightmap

        for (i_x = 1;i_x < limit_x;++i_x)
        {
            for (i_y = 1;i_y < limit_y;++i_y)
            {              
                value = val(i_x  ,i_y  ,*this_) * 0.5   +
                        val(i_x+1,i_y  ,*this_) * 0.125 +
                        val(i_x-1,i_y  ,*this_) * 0.125 +
                        val(i_x  ,i_y+1,*this_) * 0.125 +
                        val(i_x  ,i_y-1,*this_) * 0.125;

                insert(value,i_x,i_y,buffer);
            }
        }

/* edges */

        for (i_x = 1;i_x < limit_x;++i_x) {

                value = val(i_x  ,0,*this_) * 0.5   +
                        val(i_x+1,0,*this_) * 0.125 +
                        val(i_x-1,0,*this_) * 0.125 +
                        val(i_x  ,1,*this_) * 0.125;

                insert(value,i_x,0,buffer);

                value = val(i_x  ,limit_y  ,*this_)   * 0.5   +
                        val(i_x+1,limit_y  ,*this_)   * 0.125 + 
                        val(i_x-1,limit_y  ,*this_)   * 0.125 +
                        val(i_x  ,limit_y-1,*this_) * 0.125;

                insert(value,i_x,limit_y,buffer);
           }

        /* now edges along y */
       

        for(i_y = 1;i_y < limit_y;++i_y) {

                value = val(0,i_y  ,*this_) * 0.5   +
                        val(0,i_y+1,*this_) * 0.125 +
                        val(0,i_y-1,*this_) * 0.125 +
                        val(1,i_y  ,*this_) * 0.125;

                insert(value,0,i_y,buffer);

                value = val(limit_x  ,i_y  ,*this_) * 0.5   +
                        val(limit_x  ,i_y+1,*this_) * 0.125 +
                        val(limit_x  ,i_y-1,*this_) * 0.125 +
                        val(limit_x-1,i_y  ,*this_) * 0.125;

                insert(value,limit_x,i_y,buffer);
        }

        /* lastly - corners */

        value = val(0,0,*this_) * 0.5   +
                val(1,0,*this_) * 0.125 +
                val(0,1,*this_) * 0.125;

        insert(value,0,0,buffer);

        value = val(limit_x  ,0,*this_) * 0.5   +
                val(limit_x-1,0,*this_) * 0.125 +
                val(limit_x  ,1,*this_) * 0.125;

        insert(value,limit_x,0,buffer);

        value = val(0,limit_y  ,*this_) * 0.5   +
                val(1,limit_y-1,*this_) * 0.125 +
                val(0,limit_y  ,*this_) * 0.125;

        insert(value,0,limit_y,buffer);

        value = val(limit_x  ,limit_y  ,*this_) * 0.5   +
                val(limit_x-1,limit_y  ,*this_) * 0.125 + 
                val(limit_x  ,limit_y-1,*this_) * 0.125;

        insert(value,limit_x,limit_y,buffer);


/* end of edges */

        tmp = *this_;
     *this_ = buffer;
     buffer = tmp;
     
    }

    destroyArray(&buffer);
}

/*
*
* run the algorithm with predefined values
*
*/


void go(ulong iterations,gridArray** this_) {

    ulong iter = 0;
    gridArray* buffer = NULL;
    float snipVal = 2.0;

    for (iter = 0;iter < iterations;++iter) {

	      snipArray(*this_,
                  (ulong)(size_x(*this_)/snipVal),
                  (ulong)(size_y(*this_)/snipVal),
                  &buffer);

        snipVal *= 2.0;

        scale(size_x(*this_),size_y(*this_),&buffer);

        mulScalar(2.0,buffer);
        
        addArray(*this_,buffer);
        
        filter(3,this_);
        
        destroyArray(&buffer);
    }
}

/*
*
* Normalisation to a range of 0..hi
*
*/

void normalize(float hi,gridArray* this_) {

//    1. find largest value
    float largest = -1.0;
    float inValue = 0.0;
    ulong limit_x = size_x(this_);
    ulong limit_y = size_y(this_);
    ulong i_x = 0;
    ulong i_y = 0;

for (i_x = 0;i_x < limit_x;++i_x)
{
    for (i_y = 0;i_y < limit_y;++i_y)
    {
        if (val(i_x,i_y,this_) > largest)
        {
            largest = val(i_x,i_y,this_);
        }
    }
}



for (i_x = 0;i_x < limit_x;++i_x)
{
    for (i_y = 0;i_y < limit_y;++i_y)
    {
        inValue = val(i_x,i_y,this_)/largest * hi;
        if (inValue < 0.0)
        {
            insert(0.0,i_x,i_y,this_);
        }
        else
        {
            insert(inValue,i_x,i_y,this_);
        }
    }
}

}

/*
*
* Write a bitmap (bmp image) of the heightmap
*
*/

#ifndef NOBMP

void image(const char* filename,gridArray* this_) {

    ulong i_x = 0;
    ulong i_y = 0;
    ulong limit_x = size_x(this_);
    ulong limit_y = size_y(this_);
    float color = val(i_x,i_y,this_);

    bmp image(limit_x,limit_y,filename);

    for (i_x = 0;i_x < limit_x;++i_x) {
        
        for (i_y = 0;i_y < limit_y;++i_y) {
            
            color = val(i_x,i_y,this_);
            if (color > 255.0) color = 255.0;
            if (color < 0.0) color = 0.0;
            image.putPixel(char(color),char(color),char(color),i_x,i_y);

        }
    }
    image.writeToFile();
}

#endif

/*
*
* Constrain adjacent vertices to differ no more than +1/-1 in height
* (inline to allow compiler to optimize the comparison type)
*
*/

INLINE void constrain(int raise, gridArray* this_) {
  ulong limit_x = size_x(this_);
  ulong limit_y = size_y(this_);

  ulong i_x;
  ulong i_y;
  
  ulong l_ind = 1;
  ulong l_lim = 2;

/* pass the map in four directions to set it so the
   map is in the TTD format (no more then 1 height difference
   in each direction */

  for (i_x = 0; i_x < limit_x; ++i_x)
      for (i_y = l_ind; i_y < limit_y-l_lim; ++i_y)
          adjust(i_x, i_y, i_x, i_y-1, raise, this_);
  
  for (i_y = limit_y-1; i_y > 0; --i_y)
      for (i_x =  l_ind ;i_x < limit_x-l_lim; ++i_x)
          adjust(i_x, i_y, i_x-1, i_y, raise, this_);

  for (i_x = limit_x-1;i_x > 0;--i_x)
      for (i_y = limit_y-l_lim;i_y > l_ind;--i_y)
          adjust(i_x, i_y, i_x, i_y+1, raise, this_);

  for (i_y = 0;i_y < limit_y;++i_y)
      for (i_x = limit_x-l_lim;i_x > l_ind;--i_x)
          adjust(i_x, i_y, i_x+1, i_y, raise, this_);
}

/*
*
* Transform into TTD format
*
*/

void ttMap(ulong cutDown, ulong cutUp, gridArray* this_) {

/* set the limits to avoid calling size_x() and size_y()
   methods on each loop */

    ulong limit_x = size_x(this_);
    ulong limit_y = size_y(this_);
    ulong i_x = 0;
    ulong i_y = 0;

/* check for sensibility of the arguments */

    if (cutUp < cutDown) return;

/* normalize to the proper range and subtract the cutDown */

    normalize(cutUp+13+cutDown/4,this_);
    addScalar((cutUp* -1.0),this_);
    normalize(cutDown,this_);

/* first pass to adjust adjacent heights by raising neighbors as needed */

    constrain(1, this_);

/* zero two outmost vertices to 0.0 */

    for (i_x = 0;i_x < limit_x;++i_x) {
        insert(0.0,i_x,        0,this_);
        insert(0.0,i_x,        1,this_);
        insert(0.0,i_x,limit_y-2,this_);
        insert(0.0,i_x,limit_y-1,this_);
    }

    for (i_y = 0;i_y < limit_y;++i_y) {
        insert(0.0,        0,i_y,this_);
        insert(0.0,        1,i_y,this_);
        insert(0.0,limit_x-2,i_y,this_);
        insert(0.0,limit_x-1,i_y,this_);
    }

/* constrain neighbours again, this time lowering as needed so as not
   to raise map edges */

    constrain(0, this_);
    
    for (i_x = 0; i_x < limit_x;++i_x)
    {
        for (i_y = 0; i_y < limit_y;++i_y)
        {
            if (val(i_x,i_y,this_) > 15.0) insert (15.0, i_x, i_y, this_);
            if (val(i_x,i_y,this_) <  0.0)  insert (0.0, i_x, i_y, this_);
        }
    }

}

/*
*
* Create a desert where applicable
*
*/

void ttDesert(gridArray* target, ulong min, ulong max, ulong rfmin, ulong range, gridArray* this_) {

    ulong limit_x = size_x(this_) - range;
    ulong limit_y = size_y(this_) - range;
    ulong i_x = 0;
    ulong i_y = 0;

    ulong rBonus = 2;

    mulScalar(0.0,target); // zero the array

    scale(limit_x,limit_y,&this_);

    for (i_x = range+rBonus;i_x < limit_x-rBonus;++i_x)
    {
        for (i_y = range+rBonus;i_y < limit_y-rBonus;++i_y)
        {
            if (val(i_x,i_y,this_) > rfmin)
                insert(2.0,i_x,i_y,target);
            else if ( val(i_x,i_y,this_) < max && val(i_x,i_y,this_) > min)
            {
                if ( recursiveTest(range,i_x,i_y,this_) )
                  insert(1.0,i_x,i_y,target);
            }
        }
    }
}

/*
*
* test recursively if a tile is sensibly located
*
*/

int recursiveTest(ulong range, ulong x, ulong y, gridArray* this_)
{
  if (range == 0)
  {
      return val(x,y,this_) > 0.0;
  }
      return val (x+range, y+range, this_) > 0.0 &&
             val (x-range, y-range, this_) > 0.0 &&
             val (x+range, y-range, this_) > 0.0 &&
             val (x-range, y+range, this_) > 0.0 &&
             val (x      , y+range, this_) > 0.0 &&
             val (x      , y-range, this_) > 0.0 &&
             val (x+range, y      , this_) > 0.0 &&
             val (x-range, y      , this_) > 0.0 &&
             recursiveTest(range - 1, x, y, this_);
}

/*
*
* destroy array
*
*/

void Array(gridArray* source_,gridArray* this_) {

    ulong limit_x = 0;
    ulong limit_y = 0;
    ulong i_x = 0;
    ulong i_y = 0;

    // check if the array sizes match
    if (size_x(this_) != size_x(source_) && size_y(this_) != size_y(source_))
    {
        return;
    }

    // do the addition

    limit_x = size_x(this_);
    limit_y = size_y(this_);
 
    for (i_x = 0;i_x < limit_x;++i_x)
    {
        for (i_y = 0;i_y < limit_y;++i_y)
        {
            this_->data[i_x][i_y] += val(i_x,i_y,source_);
        }
    }
}

void destroyArray(gridArray** this_) {

  ulong i_x;

  for (i_x = 0;i_x < size_x(*this_);++i_x)
    free((*this_)->data[i_x]);

  free((*this_)->data);

  free(*this_);
  *this_ = NULL;
}

/* multiply elements of one array with elements of another array */

void mulArray(gridArray* source_,gridArray* this_) {

    ulong limit_x = 0;
    ulong limit_y = 0;
    ulong i_x = 0;
    ulong i_y = 0;

    // check if the array sizes match
    if (size_x(this_) != size_x(source_) && size_y(this_) != size_y(source_))
    {
        return;
    }

    // do the addition

    limit_x = size_x(this_);
    limit_y = size_y(this_);
 
    for (i_x = 0;i_x < limit_x;++i_x)
    {
        for (i_y = 0;i_y < limit_y;++i_y)
        {
            this_->data[i_x][i_y] *= val(i_x,i_y,source_);
        }
    }
}

/*
*
* Stencils
*
*/

float valley_data[16][16] = {
    {  0.4, 0.55, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.45, 0.55, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.45, 0.6, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.45, 0.6, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    
    {  0.55, 0.6, 0.65,  0.6,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.6,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.7,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.7,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    
    {  0.55, 0.6, 0.65,  0.7,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.7,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.6,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.6,    0.65, 0.75, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    
    {  0.55, 0.6, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},
    {  0.55, 0.6, 0.65,  0.7,    0.75, 0.8, 0.85, 1.0,     1.0,  0.85, 0.8,  0.75,  0.7, 0.65, 0.6, 0.55},   
};

void stencil (float stencil_data[16][16], gridArray** this_)
{
     ulong i_x = 0;
     ulong i_y = 0;
     ulong scaleFactor = 16;

     makeArray(16,16,NULL,this_);
     
     for (i_x = 0;i_x < 16;++i_x)
     {
        for (i_y = 0;i_y < 16; ++i_y)
        {
            insert(stencil_data[i_x][i_y],i_x,i_y,(*this_));
        }
     }

     while (scaleFactor < 256) {
       scaleFactor *= 2;
       scale(scaleFactor,scaleFactor,this_);
       filter(2,this_);
    }
}


void shift_x (int dir, ulong row, gridArray* this_) {
     
     int i_x = 0;
     float tmp = 0;
     
     if (this_->size_x <= row) return;
     
     if (dir > 0)
     {
       tmp = this_->data[0][row];
       for (i_x = 1;i_x < this_->size_x;++i_x)
       {
          this_->data[i_x-1][row] = this_->data[i_x][row];
       }
       this_->data[this_->size_x-1][row] = tmp;
     }
     
     if (dir < 0)
     {
       tmp = this_->data[this_->size_x-1][row];
       for (i_x = this_->size_x-2;i_x > -1;--i_x)
       {
          this_->data[i_x+1][row] = this_->data[i_x][row];
       }
       this_->data[0][row] = tmp;
     }
     
}

void shift_y (int dir, ulong row, gridArray* this_) {
     
     int i_y = 0;
     float tmp = 0;
     
     if (this_->size_y <= row) return;
     
     if (dir > 0)
     {
       tmp = this_->data[row][0];
       for (i_y = 1;i_y < this_->size_y;++i_y)
       {
          this_->data[row][i_y-1] = this_->data[row][i_y];
       }
       this_->data[row][this_->size_y-1] = tmp;
     }
     
     if (dir < 0)
     {
       tmp = this_->data[row][this_->size_y-1];
       for (i_y = this_->size_y-2;i_y > -1;--i_y)
       {
          this_->data[row][i_y+1] = this_->data[row][i_y];
       }
       this_->data[row][0] = tmp;
     }
     
}
