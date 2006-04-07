#include <defs.inc>
#include <frag_mac.inc>

ext_frag oldautoreplace12

global patchtrainenterdepot

begincodefragments

codefragment newtrainenterdepot
	icall trainenterdepot


endcodefragments

patchtrainenterdepot:
	patchcode oldautoreplace12,newtrainenterdepot,1+WINTTDX,2
	ret
