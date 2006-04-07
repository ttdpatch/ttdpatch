# Generated automatically from Makefile.in by configure.
#
#	Makefile.in
#
#	This file is part of a free library for the Win32 API.
# 
#	This library is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


# start config section

SHELL = /bin/sh

srcdir = .

host_alias = i686-pc-cygwin
build_alias = i686-pc-cygwin
target_alias = i686-pc-cygwin
prefix = /usr/local
includedir:=${prefix}/include

program_transform_name = s,x,x,
exec_prefix = ${prefix}
libdir:=${exec_prefix}/lib
bindir = ${exec_prefix}/bin
ifeq ($(target_alias),$(host_alias))
ifeq ($(build_alias),$(host_alias))
tooldir:=$(exec_prefix)
else
tooldir:=$(exec_prefix)/$(target_alias)
endif
else
tooldir:=$(exec_prefix)/$(target_alias)
endif
datadir = ${prefix}/share
infodir = ${prefix}/info
ifneq (,$(findstring cygwin,$(target_alias)))
inst_includedir:=$(tooldir)/include/w32api
inst_libdir:=$(tooldir)/lib/w32api
else
inst_includedir:=$(includedir)
inst_libdir:=$(libdir)
endif

INSTALL = /usr/bin/install -c
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_PROGRAM = ${INSTALL}
mkinstalldirs = mkdir -p

CC = gcc
CC_FOR_TARGET = $(CC)

DLLTOOL = dlltool
DLLTOOL_FLAGS = --as=$(AS) -k
AS = as
AS_FOR_TARGET = $(AS_FOR_TARGET)
WINDRES = windres

# Depending on if we build as part of winsup or mingw we need to
# add additional include paths in order to get the correct headers
# from the C library.
BUILDENV = cygwin

ifeq ($(BUILDENV), cygwin)
# winsup/include
# winsup/../newlib/libc/include
# winsup/../newlib/libc/sys/cygwin
EXTRA_INCLUDES = -I$(srcdir)/../../include -I$(srcdir)/../../../newlib/libc/include -I$(srcdir)/../../../newlib/libc/sys/cygwin
endif
ifeq ($(BUILDENV), mingw)
EXTRA_INCLUDES = -I$(srcdir)/../../mingw/include
endif

#INCLUDES = -I$(srcdir)/../include $(EXTRA_INCLUDES)

CFLAGS =
ALL_CFLAGS = $(CFLAGS) $(INCLUDES)

RANLIB = ranlib
AR = ar
LD = ld

# end config section

# headers

HEADERS = $(notdir $(wildcard $(srcdir)/../include/*.h))
GL_HEADERS = $(notdir $(wildcard $(srcdir)/../include/GL/*.h))

# libraries

DEF_FILES = $(notdir $(wildcard $(srcdir)/*.def))
IMPLIBS = $(addprefix lib,$(subst .def,.a,$(DEF_FILES)))
EXTRA_LIBS=libuuid.a libscrnsave.a libscrnsavw.a libdxguid.a liblargeint.a
LIBS = $(IMPLIBS) $(EXTRA_LIBS)
EXTRA_OBJS=uuid.o shell32.o dxguid.o scrnsave.o scrnsavw.o largeint.o \
	$(UUID_OBJS) dinput.o kernel32.o
SOURCES = scrnsave.c shell32.c uuid.c largeint.c dinput.c dxguid.c \
res.rc test.c kernel32.c

DISTFILES = Makefile.in $(DEF_FILES) $(SOURCES)

.NOTPARALLEL:

# targets
all: $(LIBS) $(EXTRA_OBJS)

TEST_OPTIONS = $(ALL_CFLAGS) -Wall -pedantic -Wsystem-headers -c $(srcdir)/test.c -o test.o
.PHONY: test
test:
	@echo "Testing w32api..."
	@for lang in c c++ objective-c ; do \
		echo "$$lang..."; \
		$(CC) -x$$lang $(TEST_OPTIONS) ; \
		echo "$$lang UNICODE..."; \
		$(CC) -x$$lang -DUNICODE $(TEST_OPTIONS) ; \
	done
	@echo "windres..."
	@$(WINDRES) --include-dir $(INCDIR) -i $(srcdir)/res.rc -o test.o
	@echo "windres UNICODE..."
	@$(WINDRES) --define UNICODE --include-dir $(INCDIR) -i $(srcdir)/res.rc -o test.o
	@rm -f test.o

scrnsavw.o: scrnsave.c
	$(CC) -c $(ALL_CFLAGS) -DUNICODE -o $@ $<

# make rules

.SUFFIXES: .c .o .def .a

.c.o:
	$(CC) -c $(ALL_CFLAGS) -o $@ $<

DXGUIDC = $(wildcard dxguid/*.c)
DXGUIDO = $(DXGUIDC:%.c=%.o)

libdxguid.a: $(DXGUIDO)
	echo $(DXGUIDO)
	$(AR) rc $@ $<
	$(RANLIB) $@

# clean

mostlyclean:
	rm -f *~ *.o *.s

clean:
	rm -f *.o *.a *.s *~

distclean: clean
	rm -f config.cache config.status config.log Makefile

maintainer-clean: distclean
