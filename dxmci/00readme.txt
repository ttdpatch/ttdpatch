
MCI to DirectMusic wrapper by Norman Rasmussen

This DLL can be used by the Windows version of TTD (using TTDPatch's win2k
patches) to use DirectMusic instead of MCI.

Before you'll able to compile it, you must install the DirectX SDK, and
then patch dmdls.h in the SDK using the supplied diff file.

You'll also have to adjust the paths in the Makefile, and the CFLAGS
if you're using GCC 3.
