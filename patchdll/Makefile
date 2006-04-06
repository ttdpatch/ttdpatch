
# default target
all:    ttdpatch.dll

OBJECTFILES = patchsnd.o noregist.o

# use WINCC setting from toplevel Makefile
MAKEFILELOCAL=../Makefile.local
include ../Makefile.setup

TARGETPREF = $(subst gcc,,${CC})
#CC = $(TARGETPREF)gcc
CXX = $(TARGETPREF)g++
AS = $(TARGETPREF)as

CFLAGS = -g -Os -mno-cygwin -Wall
LDOPTS = -Wl,--subsystem,windows,-s -ldsound -mno-cygwin
#LDOPTS = -Wl,--subsystem,console
LDOPTS += -lshlwapi
DLLOPTS = $(LDOPTS) -Wl,--enable-auto-image-base,-e,_DllMain@12
DLLOPTS += -Wl,-Map,$(@:%.dll=%.map)		# uncomment to make map files
ifdef LOGPLAY
	CFLAGS += -DLOGPLAY=${LOGPLAY}
endif


ttdpatch.dll: ${OBJECTFILES} ttdpatch.def
ttdpatch.def: ${OBJECTFILES}

%.o : %.c
	$(CC) -c -o $@ $(CFLAGS) $<

%.o : %.cpp
	$(CXX) -c -o $@ $(CFLAGS) $<

%.def:
	$(DLLTOOL) -z $@ $^

%.dll:
	$(CC) -o $@ -shared $^ $(DLLOPTS) 
ifndef NOUPX
	upx -qq --best $@
endif

# make assembly file for testing the compile output
%.s : %.cpp
	$(CXX) -S -o $@ $(CFLAGS) $<

%.lst : %.s
	$(AS) -a -o /dev/null $< > $@

distclean:
	rm -f *.o *.map *.s *.dmp 

clean:	distclean
	rm -f *.exe *.dll *.def
