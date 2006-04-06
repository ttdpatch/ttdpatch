@echo off
net time /set /yes > nul
rem Run this to make a non-debug version
set DEBTGT=
if not "%1"=="R" goto debug 
set DEBUG=0
set DEBTGT= nodebug
echo Don't forget to do make remake and delete memsize.h !
shift
:debug
shift
make -fMakefile -fMakefile.tst checkver -e%DEBTGT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
