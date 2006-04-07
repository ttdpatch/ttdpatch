@echo off
REM
REM Don't edit or run this file here, copy it to the main source directory
REM and use it from there (svn will ignore changes there, but not here)
REM

REM -- Use this if the Cygwin /bin directory is not in the PATH --
rem PATH D:\Cygwin\bin;%PATH%

REM -- Set to 1 for debug, 0 for non-debug builds --
SET DEBUG=1

REM -- Set to your TTD test directory if you're going to use 'make test' --
SET GAMEDIR=E:\TTD\TEST

bash --rcfile ./bashinit
