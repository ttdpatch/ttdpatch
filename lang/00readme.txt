Various language text files, as C header files
They are used by the makelang program which turns them into a
special compressed format to be appended to the TTDPatch exe
files.

PLEASE NOTE.
	The files in this directory must be edited with a DOS editor,
	and the codepage set to the value stated at the beginning of the
	the language file.

	To edit the language strings using a Windows editor (e.g. Notepad), 
	please edit the files in the Windows subdirectory.  These are 
	identical except for the code page, which is that country's default 
	Windows code page.

	If you need the files in any other code page than the ones specified,
	please contact me and I can provide it in the page, or convert it
	yourself.  Make sure that the EDITORCODEPAGE is set properly.

After changing files either here or in the Windows/ subdirectory, run

perl update.pl

to propagate the changes into the corresponding other version.  This allows
people to use whichever editor they're more familiar with (DOS or Windows).


How to translate:

- Get english.h and rename it to yourlanguage.h if your language file doesn't
  exist yet

- Change only text between quotation marks ("").  Leave everything else the way
  it is, so that if I need to change something, I can find my way around the
  file.

- Don't change the "info about this language" section, except perhaps for the
  EDITORCODEPAGE if you've used a different one and converted it yourself.
  I'll normally make these changes myself when integrating the language.

- Don't touch the special codes like "&#x2500;", those are Unicode characters 
  that can't be displayed properly in a Windows editor.  Just leave them the 
  way they are, and your file will work fine.

- The SWITCHTEXT(...) entries consist of two strings.  The first one is always
  shown, the second one only if the switch is enabled.  For example,
	SWITCHTEXT(uselargerarray, "Extend total vehicles", " to %d*850")
  can show either
	"Extend total vehicles" (if it's disabled)
  or
	"Extend total vehicles to 4*850" (if it's enabled and has value 4)
  You should only use the second part for switches that take a parameter.

- No lines may be longer than 80 characters (exception: the configuration
  file lines may have any length). Some lines have even shorter length limits:
	* The entries in TEXTARRAY(halflines, ...) may be at most 38 chars long
	  However, you can, if you need, use multiple lines for each entry.
	* The entries in SWITCHTEXT(...) may be at most 74 chars long, 
	  including the second part with a substituted number.  Note that you
	  cannot use multiple lines, so you have to be very brief.

  To start a new line (only where it's allowed), use this type of syntax:
  SETTEXT(LANG_SOMETHING, "This is the first line.\n"
	"This is the second line.\n"
	"This is the last line.\n")

