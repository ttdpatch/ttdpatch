#include <defs.inc>
#include <frag_mac.inc>
#include <patchproc.inc>

patchproc newspapercolour, patchnewspapercolour


extern makenewsblackandwhite.fillrectangle


patchnewspapercolour:
	// Makes News Colorfull
	stringaddress oldmakenewsblackandwhite,1,7
	copyrelative makenewsblackandwhite.fillrectangle,5
	multipatchcode oldmakenewsblackandwhite,newmakenewsblackandwhite,7
	multipatchcode oldsetnewsbackground,newsetnewsbackground,4
	ret



begincodefragments

codefragment oldmakenewsblackandwhite
	mov bp,0x4323

codefragment newmakenewsblackandwhite
	call runindex(makenewsblackandwhite)
	setfragmentsize 9

codefragment oldsetnewsbackground
	sub dx,2
	mov bp,0xa

codefragment newsetnewsbackground
	call runindex(setnewsbackground)
	setfragmentsize 8


endcodefragments
