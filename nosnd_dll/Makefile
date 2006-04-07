
CC = i686-pc-mingw32-gcc
DLLTOOL = i686-pc-mingw32-dlltool

CFLAGS = -g -Os -mno-cygwin
LDOPTS = -Wl,--subsystem,windows,-s
#LDOPTS = -Wl,--subsystem,console
DLLOPTS = $(LDOPTS) -Wl,--enable-auto-image-base,-e,_DllMain@12

all:    nosnd.dll nomus.dll

%.o : %.c
	$(CC) -c -o $@ $(CFLAGS) $<

%.def: %.o
	$(DLLTOOL) -z $@ $^

%.dll: %.def %.o
	$(CC) -o $@ -shared $^ $(DLLOPTS) 

distclean:
	rm -f *.o *.map *.s *.dmp 

clean:	distclean
	rm -f *.exe *.dll *.def
