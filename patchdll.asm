;
; Include the ttdpatch.dll file as auxiliary data
;

db "pATCHdLL"
dd dllend-dllstart

dllstart:
incbin "patchdll/ttdpatch.dll"
dllend:
