Various Perl scripts that are needed for the compilation

langerr.pl:	Computer langerr.h, which makelang uses to emit error messages
cvtstruc.pl:	Helper macro to add memory size operators to structure member
		accesses
lineinfo.pl:	Convert the C preprocessor "#line" instructions to NASM's
		"%line" format
reloc.pl:	Find relocations in ttdprotw.lst and write reloc.inc
texts.pl:	Generates texts.h from texts.lst
