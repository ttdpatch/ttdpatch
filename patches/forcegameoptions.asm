#include <std.inc>
#include <bitvars.inc>

exported setnewroadtrafficside
	test dword [forcegameoptionssettings], forcegameoptions_trafficleft
	jz .noforceleft
	mov al, 0x80
 .noforceleft:
 	test dword [forcegameoptionssettings], forcegameoptions_trafficright
	jz .noforceright
	mov al, 0x90
.noforceright:
	mov [newroadtrafficside], al
	ret

exported setnewtownnamestyle
	// we test each bit independent so it doesn't depend on the order and placement of the bits
	test dword [forcegameoptionssettings], forcegameoptions_townsenglish
	jz .no_townsenglish
	mov al, 0
 .no_townsenglish:
	test dword [forcegameoptionssettings], forcegameoptions_townsfrench
	jz .no_townsfrench
	mov al, 1
 .no_townsfrench:
	test dword [forcegameoptionssettings], forcegameoptions_townsgerman
	jz .no_townsgerman
	mov al, 2
 .no_townsgerman:
	test dword [forcegameoptionssettings], forcegameoptions_townsamerican
	jz .no_townsamerican
	mov al, 3
 .no_townsamerican:
	test dword [forcegameoptionssettings], forcegameoptions_townslatin
	jz .no_townslatin
	mov al, 4
 .no_townslatin:
	test dword [forcegameoptionssettings], forcegameoptions_townssilly
	jz .no_townssilly
	mov al, 5
 .no_townssilly:
	mov [newtownnamestyle], al
	ret
