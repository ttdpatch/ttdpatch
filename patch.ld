OUTPUT_FORMAT(pei-i386)
SECTIONS
{
	/* loader header and code */
  .phead 0xec636 : SUBALIGN(1)
  {
	/* pROTcODE marker */
	LONG(0x544F5270);
	LONG(0x45444F63);

	/* Size of the loader */
	LONG(__loader_end - __loader_start)

	__loader_start = .;
	loader.*po(.text)
	loader.*po(.data)
	__loader_end = .;
  }

	/* main patch code and data */
  .ptext __image_base__ -8 :
  {
	/* The code size, with and without bss */
	LONG(__psbss_end - __ptext_start)
	LONG(__ptext_end - __ptext_start)

	__ptext_start = .;

	/* Link all main patch .text sections */
	header.*po(.text)
	*.*po(.text)

	/* the indirect call list */
	*(.indrct)

	/* the patch proc list */
	patchlist = .;
	patches.*po(.pproc)
	SORT(*)(.pproc)		/* sorted so that the version info remains valid */
	/* add the recordversiondata/dorecordversiondata entry */
	BYTE(1); BYTE(__recordversiondata); LONG(dorecordversiondata);
	/* and the list terminator */
	BYTE(0); BYTE(0);

	/* and the .text and .data of the remaining files */
	*/*.*po(.text)
	*.*po(.data)
	*/*.*po(.data)
	__ptext_end = .;
  }

	/* "un"initialized variables */
  .pbss :
  {
	/* The bss sections, these will not be included in the binary	*/
	/* Use byte-alignment since each chunk will have the correct	*/
	/* sizes already (i.e. each .bss chunk is a multiple of 4 large	*/
	__pbss_start = .;
	*.*po(.bss)
	*/*.*po(.bss)
	*.*po(.bss2)
	*/*.*po(.bss2)
	*.*po(.bss1)
	*/*.*po(.bss1)
	. = ALIGN(4);
	__pbss_end = .;

	/* The sbss sections, these will not be included in the binary either */
	__psbss_start = .;
	*.*po(.sbss)
	*/*.*po(.sbss)
	*.*po(.sbss2)
	*/*.*po(.sbss2)
	*.*po(.sbss1)
	*/*.*po(.sbss1)
	. = ALIGN(4);
	__psbss_end = .;
	*.*po(.aux)
  }
  __pbss_size_dwords = ((__pbss_end - __pbss_start + 3) >> 2);
  __psbss_size_dwords = ((__psbss_end - __psbss_start + 3) >> 2);
  __ttdpatchvercode__ = __ttdpatchvercode;
  .relocv 0 : { *(.relocv) }
  /DISCARD/ :
  {
	/* Discard all the junk from the CRT initialization and whatnot */
	*(.*data*)
	*(.text)
	*(.*bss*)
	*(.stab*)
  }
}
