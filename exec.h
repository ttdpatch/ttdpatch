/*
	--- Version 3.3.3 2002-12-22 18:41 ---

   EXEC.H: EXEC function with memory swap - Main function header file.

   Public domain software by

        Thomas Wagner
        Ferrari electronic GmbH
        Beusselstrasse 27
        D-1000 Berlin 21
        Germany

   Support of keeping of additional data (function set_keeprel)
   by Josef Drexler, enhanced by Marcin Grzegorczyk.
*/


extern int do_exec (char *xfn, char *pars, int spawn, unsigned needed,
						  char **envp);

#ifdef __cplusplus
extern "C" {
#endif
extern void far * __cdecl set_keeprel (void far *begin, void far *end, unsigned alignment);
#ifdef __cplusplus
}
#endif


/*
   The EXEC function.

      Parameters:

         xfn      is a string containing the name of the file
		  to be executed. If the string is empty,
                  the COMSPEC environment variable is used to
                  load a copy of COMMAND.COM or its equivalent.
                  If the filename does not include a path, the
                  current PATH is searched after the default.
                  If the filename does not include an extension,
                  the path is scanned for a COM, EXE, or BAT file 
                  in that order.

         pars     The program parameters.

         spawn    If 0, the function will terminate after the 
                  EXECed program returns, the function will not return.

                  NOTE: If the program file is not found, the function 
                        will always return with the appropriate error 
                        code, even if 'spawn' is 0.

                  If non-0, the function will return after executing the
                  program. If necessary (see the "needed" parameter),
                  memory will be swapped out before executing the program.
                  For swapping, spawn must contain a combination of the 
                  following flags:

                     USE_EMS  (0x01)  - allow EMS swap
		     USE_XMS  (0x02)  - allow XMS swap
                     USE_FILE (0x04)  - allow File swap

                  The order of trying the different swap methods can be
                  controlled with one of the flags

		     EMS_FIRST (0x00) - EMS, XMS, File (default)
		     XMS_FIRST (0x10) - XMS, EMS, File

		  If swapping is to File, the attribute of the swap file
                  can be set to "hidden", so users are not irritated by
		  strange files appearing out of nowhere with the flag

                     HIDE_FILE (0x40)    - create swap file as hidden

                  and the behaviour on Network drives can be changed with

		     NO_PREALLOC (0x100) - don't preallocate
                     CHECK_NET (0x200)   - don't preallocate if file on net.

                  This checking for Network is mainly to compensate for
                  a strange slowdown on Novell networks when preallocating
                  a file. You can either set NO_PREALLOC to avoid allocation
                  in any case, or let the prep_swap routine decide whether
                  to do preallocation or not depending on the file being
                  on a network drive (this will only work with DOS 3.1 or 
                  later).

         needed   The memory needed for the program in paragraphs (16 Bytes).
                  If not enough memory is free, the program will 
                  be swapped out. 
                  Use 0 to never swap, 0xffff to always swap. 
                  If 'spawn' is 0, this parameter is irrelevant.

	 envp     The environment to be passed to the spawned
                  program. If this parameter is NULL, a copy
                  of the parent's environment is used (i.e.
                  'putenv' calls have no effect). If non-NULL,
                  envp must point to an array of pointers to
                  strings, terminated by a NULL pointer (the
		  standard variable 'environ' may be used).

      Return value:

         0x0000..00FF: The EXECed Program's return code

         0x0101:       Error preparing for swap: no space for swapping
	 0x0102:       Error preparing for swap: program too low in memory
	 0x0103:       Error preparing for swap: no space for environment

         0x0200:       Program file not found
	 0x0201:       Program file: Invalid drive
         0x0202:       Program file: Invalid path
         0x0203:       Program file: Invalid name
         0x0204:       Program file: Invalid drive letter
         0x0205:       Program file: Path too long
         0x0206:       Program file: Drive not ready
         0x0207:       Batchfile/COMMAND: COMMAND.COM not found
         0x0208:       Error allocating temporary buffer

         0x03xx:       DOS-error-code xx calling EXEC

         0x0400:       Error allocating environment buffer

         0x0500:       Swapping requested, but prep_swap has not 
                       been called or returned an error.
         0x0501:       MCBs don't match expected setup
         0x0502:       Error while swapping out

	 0x0600:       Redirection syntax error
	 0x06xx:       DOS error xx on redirection




   The set_keeprel function

      Parameters:

	begin		Pointer to the first byte of the area to relocate/keep.
	end		Pointer to the first byte *not* to be kept.
	alignment	Requested alignment; data will be moved to a location
			aligned at a (1 << alignment) boundary.
			If 0, data will not be relocated.

      If the area is to be relocated ('alignment' is nonzero) and it contains code,
      it must be written in such way that it will work regardless of its actual
      location in the address space.

      Return value:

	On success, returns a pointer to the location the data will be
	relocated to (the destination area). The offset portion of the pointer
	is the number of bytes available for a copy of the environment
	(see the 'envp' parameter of the 'do_exec' function).

	On error, returns -1 in the segment part and one of the following values
	in the offset part:
	-1:	'end' is too far from the PSP (if not relocated), or the block
		to relocate/keep is too large (if relocated). The end of the block
		(after possible relocation) must be less than 64KB from the PSP.
	-2:	'begin' is too low in the memory
	-3:	Invalid input; 'begin' points to a higher location than 'end',
		or either of the pointers overflows the 1MB limit.

      If 'begin' is NULL, no data will be relocated or kept. In this case,
      the function returns NULL.

      Relocation is performed by swapping the area between 'begin' and 'end',
      aligned to paragraph boundaries, with a suitably aligned destination area
      near the PSP. After the EXECed program returns, the areas will be swapped
      back, restoring the original contents of the destination area (but only
      if the 'spawn' parameter to 'do_exec()' is nonzero). For this code to
      work, 'begin' must not be below the destination area; if this condition
      is not met, 'set_keeprel()' will return an error (code -2). This may be
      particularly important if a large alignment is requested.

      Warning: If you request a relocation, make sure the area between 'begin'
      and 'end', extended to paragraph boundaries, does not include any of the
      code or data areas used by the swapper (the SPAWNK module) itself,
      otherwise the relocation will corrupt those areas!

*/


/* Return codes (only upper byte significant) */

#define RC_PREPERR   0x0100
#define RC_NOFILE    0x0200
#define RC_EXECERR   0x0300
#define RC_ENVERR    0x0400
#define RC_SWAPERR   0x0500
#define RC_REDIRERR  0x0600

/* Swap method and option flags */

#define USE_EMS      0x01
#define USE_XMS      0x02
#define USE_FILE     0x04
#define EMS_FIRST    0x00
#define XMS_FIRST    0x10
#define HIDE_FILE    0x40
#define NO_PREALLOC  0x100
#define CHECK_NET    0x200

#define USE_ALL      (USE_EMS | USE_XMS | USE_FILE)


/*
   The function pointed to by "spawn_check" will be called immediately 
   before doing the actual swap/exec, provided that

      - the preparation code did not detect an error, and
      - "spawn_check" is not NULL.

   The function definition is
      int name (int cmdbat, int swapping, char *execfn, char *progpars)

   The parameters passed to this function are

      cmdbat      1: Normal EXE/COM file
                  2: Executing BAT file via COMMAND.COM
                  3: Executing COMMAND.COM (or equivalent)

      swapping    < 0: Exec, don't swap
                    0: Spawn, don't swap
                  > 0: Spawn, swap

      execfn      the file name to execute (complete with path)

      progpars    the program parameter string

   If the routine returns anything other than 0, the swap/exec will
   not be executed, and do_exec will return with this code.

   You can use this function to output messages (for example, the
   usual "enter EXIT to return" message when loading COMMAND.COM)
   and to do clean-up and additional checking.

   CAUTION: If swapping is > 0, the routine may not modify the 
   memory layout, i.e. it may not call any memory allocation or
   deallocation routines.

   "spawn_check" is initialized to NULL.
*/

typedef int (spawn_check_proc)(int cmdbat, int swapping, char *execfn, char *progpars);
extern spawn_check_proc *spawn_check;

/*
   The 'swap_prep' variable can be accessed from the spawn_check
   call-back routine for additional information on the nature and
   parameters of the swap. This variable will ONLY hold useful
   information if the 'swapping' parameter to spawn_check is > 0.
   The contents of this variable may not be changed.

   The 'swapmethod' field will contain one of the flags USE_FILE, 
   USE_XMS, or USE_EMS.

   Caution: The module using this data structure must be compiled
   with structure packing on byte boundaries on, i.e. with /Zp1 for
   MSC, or -a- for Turbo/Borland.
*/

typedef struct {
               long xmm;            /* XMM entry address */
               int first_mcb;       /* Segment of first MCB */
               int psp_mcb;         /* Segment of MCB of our PSP */
               int env_mcb;         /* MCB of Environment segment */
               int noswap_mcb;      /* MCB that may not be swapped */
               int ems_pageframe;   /* EMS page frame address */
               int handle;          /* EMS/XMS/File handle */
               int total_mcbs;      /* Total number of MCBs */
               char swapmethod;     /* Method for swapping */
               char swapfilename[81]; /* Swap file name if swapping to file */
               } prep_block;

extern prep_block swap_prep;

