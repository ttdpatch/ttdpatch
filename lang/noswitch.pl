#!/usr/bin/perl -pl -i.bak2

s/(SETTEXT\((CFG_|LANG_SWITCHOBSOLETE).*?)\(.*?\)/$1(%s)/