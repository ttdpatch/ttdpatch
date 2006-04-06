;
; Relocations for the Windows version as auxfile
;

db "rELOCdAT"
dd relocend-relocstart

relocstart:
%include "INCFILE"
relocend:
