;
; This file contains the new in-game texts in all five language versions
; Note: Edit all the texts in iso-8859-1
;
; -------------------------------------
;     Text definitions
; -------------------------------------
;
;
; How to make a new entry:
; 	- add one TO THE END of inc/ourtext.inc before defourtext lasts:
;		defourtext <entryname>
;	- add the text to lang/american.txt and lang/english.txt.  Example:
;		<entryname>="Hello!"
;		<entryname>="Hallo!"
;	- add the text to the other lang/<language>.txt files if you know
;		that language.  Example:
;		<entryname>="Bonjour!"
;	- all text must use the iso-8859-1 codepage or the UTF-8 extension
;	- then use it in the assembly code with ourtext(<entryname>)
;

; -----------------------------------
;	Language data
; -----------------------------------

newlanguage american,a,2,496543,1695744
%include "lang/american.inc"
def last

secondlanguage

newlanguage english,e,2,496601,1696256
%include "lang/english.inc"
def last

newlanguage german,g,2,499583,1699328
%include "lang/german.inc"
def last

newlanguage french,f,2,505759,1707008
%include "lang/french.inc"
def last

newlanguage spanish,s,2,506237,1707520
%include "lang/spanish.inc"
def last
