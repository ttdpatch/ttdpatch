@echo off
call setall
call d:\watcom\setvars.bat
set DEBUG=1
SET MAKE_MODE=UNIX
SET GNUTARGET=pe-i386
SET PATH=d:\cygwin\bin;%PATH%
SET HOME=d:\cygwin\home\Josef
e:
cd \spiele\ttdtemp
%TTDPATCHSRCDRIVE%
if "%2"=="" cd %TTDPATCHSRC%
if not "%2"=="" cd %2
if "%1"=="" d:\windows\far\far
if not "%1"=="" %1
