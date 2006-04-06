
# Makefile for sv1fix

# Gnu compiler settings
SHELL = /bin/sh
CC = gcc
CXX = g++
# use 386 instructions but optimize for pentium II/III
CFLAGS = -Wall -mno-cygwin -Os -march=i386 -mcpu=pentium -I.
CXXFLAGS = $(CFLAGS)
LDOPT = -Wl,--subsystem,console,-s

# default targets
all: sv1fix.o sv1fix sv2flip.o sv2flip

%:	%.o

%.o : %.c
	$(CC) -c -o $@ $(CFLAGS) $<

% : %.o
	$(CC) -o $@ $(CFLAGS) $^ $(LDOPT)
