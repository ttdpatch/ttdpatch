
Versions files.

These contain the offsets of the various patches in the various versions.

1119*.VER files are for the DOS version 2.01.119, the last four bytes in
the name are the file size minus 470000 in hex.

2011*.VER files are for the Windows version, the last four bytes are the
file size minus 1690000 divided by 256, in hex.

Each file is a C include file of an array containing:
 - the version number
 - the file size
 - the list of offsets in the order in which they appear in init.ah,
   filled with zeroes to some array size

To create empty files (from empty.dat) simply delete the .ver files
and run make, it'll recreate them.

