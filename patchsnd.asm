;
; Include the patchsnd.dll file as auxiliary data
;

db "pATCHsND"
dd sndend-sndstart

sndstart:
incbin "patchsnd/patchsnd.dll"
sndend:
