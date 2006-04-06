@echo off
rem This is the file I use to get the compiler environment started
rem Basically t2.bat sets all environment variables and directories,
rem and then it runs Norton Commander.  I run this because otherwise
rem I won't have enough environment space.
command /e:2048 /c t2.bat %1 %2 %3 %4
