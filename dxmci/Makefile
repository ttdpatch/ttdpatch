#
# Compile the MCI-to-DirectMusic wrapper by Norman Rasmussen
#
# You must have the DirectX SDK header files in the include directories
# or specify them at the -I option.
# You must also patch the DirectX dmdls.h file using dmdls.h.diff
# which you can find here.
#
# Then just say "make".
#

# use WINCC setting from toplevel Makefile
WINCC=$(shell grep WINCC.*= ../Makefile|sed 's/.*= *//')
TARGETPREF=
ifeq ($(WINCC),LINUX)
	TARGETPREF=i686-pc-mingw32-
endif

# path to the DirectX include files (patched using dmdls.h.diff)
DXINCLUDE = dxinc

# path to the MingW libraries
MINGWLIB = /usr/lib/mingw

# The rest should be fine as it is, but change CFLAGS for gcc 3.x
DLLNAME = dxmci
DEF_FILE = $(DLLNAME).def
DLL_OFILES = $(DLLNAME).o
DLL_ENTRY = _DllMain@12
DLL_IMPORTS = -lcrtdll -luser32 -lole32 -ldxguid -lkernel32 -lwinmm

CC = $(TARGETPREF)gcc
CXX = $(TARGETPREF)g++
DLLTOOL = $(TARGETPREF)dlltool
AS = $(TARGETPREF)as


# if you're using gcc 2.x, add the -fvtable-thunks option
#CFLAGS = -c -Os -fvtable-thunks -mno-cygwin -I $(DXINCLUDE) -march=i386 -mcpu=pentium
CFLAGS = -c -Os -mno-cygwin -I $(DXINCLUDE) -march=i386 -mtune=pentium
CXXFLAGS = $(CFLAGS)

LDPATH = -L$(MINGWLIB)
LDOPTS =  -Wl,--enable-auto-image-base,--subsystem,windows,-s
LDOPTS += -Wl,-e,$(DLL_ENTRY)
LDOPTS += -Wl,-Map,$(@:%.dll=%.map)		# uncomment to make map files


all:    $(DLLNAME).dll

# compile the C++ files
%.o : %.c
	$(CC) -o $@ $(CFLAGS) $<

%.o : %.cpp
	$(CXX) -o $@ $(CXXFLAGS) $<

%.o : %.c
	$(CC) -o $@ $(CFLAGS) $<

# make assembly file for testing the compile output
%.s : %.cpp
	$(CXX) -S -o $@ $(CXXFLAGS) $<

%.lst : %.s
	$(AS) -a -o /dev/null $< > $@

# generate the export definition file
$(DLLNAME).def: $(DLL_OFILES)
	$(DLLTOOL) -z $@ $^

# compile the DLL
$(DLLNAME).dll: $(DEF_FILE) $(DLL_OFILES)
	$(CXX) -o $@ -nostdlib -shared $^ \
		$(LDOPTS) \
		$(LDPATH) $(DLL_IMPORTS)

distclean:
	rm -f *.o *.map *.s *.dmp 

clean:	distclean
	rm -f *.dll *.def
