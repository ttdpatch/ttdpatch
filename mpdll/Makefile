
# default target
all:    ttdpatchmp.dll

OBJECTFILES = asyncmpclient.o

# use WINCC setting from toplevel Makefile
MAKEFILELOCAL=../Makefile.local
include ../Makefile.setup

TARGETPREF = $(subst gcc,,${CC})
#CC = $(TARGETPREF)gcc
CXX = $(TARGETPREF)g++
AS = $(TARGETPREF)as

CFLAGS = -g -Os -mno-cygwin -Wall ${CFLAGS-DLL}
LDOPTS = -Wl,--subsystem,windows,-s -lwsock32 -mno-cygwin ${LDOPTS-DLL}
#LDOPTS = -Wl,--subsystem,console
LDOPTS += -lshlwapi
DLLOPTS = $(LDOPTS) -Wl,--enable-auto-image-base,-e,_DllMain@12
DLLOPTS += -Wl,-Map,$(@:%.dll=%.map)		# uncomment to make map files

ttdpatchmp.dll: ${OBJECTFILES} ttdpatchmp.def
ttdpatchmp.def: ${OBJECTFILES}

%.o : %.c
	${_E} [CC] $@
	${_C}$(CC) -c -o $@ $(CFLAGS) $<

%.o : %.cpp
	${_E} [CXX] $@
	${_C}$(CXX) -c -o $@ $(CFLAGS) $<

%.def:
	${_E} [DLLTOOL] $@
	${_C}$(DLLTOOL) -z $@ $^

%.dll:
	${_E} [BUILD] $@
	${_C}$(CC) -o $@ -shared $^ $(DLLOPTS) 
ifndef NOUPX
	${_C} ${UPX} -qqq --best $@
endif

# make assembly file for testing the compile output
%.s : %.cpp
	${_E} [CXX] $@
	${_C}$(CXX) -S -o $@ $(CFLAGS) $<

%.lst : %.s
	${_E} [AS] $@
	${_C}$(AS) -a -o /dev/null $< > $@

distclean:
	rm -f *.o *.map *.s *.dmp 

clean:	distclean
	rm -f *.exe *.dll *.def
