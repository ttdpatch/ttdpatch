@echo off

REM -- Use this if the Cygwin /bin directory is not in the PATH --
rem PATH D:\Cygwin\bin;%PATH%

REM -- Set to 1 for debug, 0 for non-debug builds --
SET DEBUG=1

REM -- Set to your TTD test directory if you're going to use 'make test' --
SET GAMEDIR=E:\TTD\TEST

bash --rcfile ./bashinit
