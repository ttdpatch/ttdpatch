//
// Localization strings for TTDPatch.
//
// Czech translation by Miroslav Duda.
//

//-------------------------------------------
//  INFO ABOUT THIS LANGUAGE
//-------------------------------------------
SETNAME("Czech")
SETCODE("cz")
COUNTRYARRAY(countries) = { 421, 42, 0, 0x05, 0 };
SETARRAY(countries);
	// 421 is the Czech Republic (42 is Czechoslovakia in old DOS versions),
	// and 0x05 is Czech in Windows

DOSCODEPAGE(852)	// The default DOS code page for this language
WINCODEPAGE(1250)	// The default Windows code page for this language
EDITORCODEPAGE(852)	// The code page of all strings in this file.

DOSENCODING(IBM852)	// Encoding type for XML output from DOS and Windows;
WINENCODING(ISO-8859-2)	// DOS MUST be from IANA-CHARSETS and same as DOSCODEPAGE
			// Windows can be any ISO-8859-x encoding, doesn't have
			// to be related to WINCODEPAGE

//-------------------------------------------
//  PROGRAM BLURBS
//-------------------------------------------

// First line of output is something like "TTDPatch V1.5.1 starting.\n"
// The program name and version are autogenerated, only put the " starting\n"
// here
SETTEXT(LANG_STARTING, " byl spu�t�n.\n")


//-------------------------------------------
//  VERSION CHECKING
//-------------------------------------------

// In the version identifier, this is for the file size
SETTEXT(LANG_SIZE, "velikost")

// Shown if the version is recognized
SETTEXT(LANG_KNOWNVERSION, "Verze programu je spr�vn�\n")

// Warning if the version isn't recognized.  Be sure *not* to use tabs
// in the text.  All but the last lines should end in ...\n"
SETTEXT(LANG_WRONGVERSION, "\n"
	"POZOR!   Nezn�m� verze programu. M��eme se pokusit\n"
	"         jej i p�esto spustit a zjistit pot�ebn� informace, pokud\n"
	"         se to nepovede, TTD nahl�s� chybu ochrany a bude ukon�en.\n"
	"\n"
	"         V z�vislosti na schopnostech opera�n�ho syst�mu nakl�dat s GPF, se m��e\n"
/***/	"         po��ta� zablokovat a vy p�ij�t o data. 	Please read\n"
/***/	"         the \"Version Trouble\" section in the TTDPatch manual for more\n"
/***/	"         information.\n"
	"\n"
	"Odpov�zte 'a' jen pokud opravdu v�te, co d�l�te. BYL JSTE VAROV�N!\n"
	"Chcete i p�esto TTD spustit? ")

// Keys which continue loading after the above warning. *MUST* be lower case.
// can be several different keys, e.g. one for your language "yjo"
SETTEXT(LANG_YESKEYS, "ay")

// Answering anything but the above keys gives this message.
SETTEXT(LANG_ABORTLOAD, "Nahr�v�n� programu bylo zastaveno.\n")

// otherwise continue loading
SETTEXT(LANG_CONTINUELOAD, "Pokus�m se...\n")

// Warning if '-y' was used and the version is unknown
SETTEXT(LANG_WARNVERSION, "POZOR: Nezn�m� verze!\n")


// -------------------------------------------
//    CREATING AND PATCHING TTDLOAD
// -------------------------------------------

// TTDLOAD.OVL doesn't exist
SETTEXT(LANG_OVLNOTFOUND, " nenalezen, hled�m origin�ln� soubory:\n")

// (DOS) neither do tycoon.exe or ttdx.exe.  %s is TTDX.EXE
SETTEXT(LANG_NOFILESFOUND, "Nemohu nal�zt ani %s ani %s.\n")

// (Windows) neither does GameGFX.exe.  %s is GameGFX.EXE
SETTEXT(LANG_NOFILEFOUND, "Nemohu nal�zt %s.\n")

// Shown when copying tycoon.exe or ttdx.exe (first %s) to ttdload.ovl (2nd %s)
SETTEXT(LANG_SHOWCOPYING, "Kop�ruji %s do %s")

// Error if running the copy command fails.  %s is the command.
SETTEXT(LANG_COPYERROR_RUN, "Nelze spustit %s\n")

// Error if command returned successfully, but nothing was copied.
// %s=TTDLOAD.OVL
SETTEXT(LANG_COPYERROR_NOEXIST, "Chyba kop�rov�n� - soubor %s neexistuje.\n")

// Invalid .EXE format
SETTEXT(LANG_INVALIDEXE, "Nezjistiteln� .EXE form�t.\n")

// Version could not be determined
SETTEXT(LANG_VERSIONUNCONFIRMED, "Nelze zjistit verzi programu.\n")

// Shows program name (1st %s) and version (2nd %s)
SETTEXT(LANG_PROGANDVER, "N�zev programu:\n  %s\nVerze programu: %s\n")

// More than three numbers in the version string (not #.#.#)
SETTEXT(LANG_TOOMANYNUMBERS, "Verze obsahuje p��li� mnoho ��sel!\n")

// .EXE is not TTD
SETTEXT(LANG_WRONGPROGRAM, "Toto nen� Transport Tycoon Deluxe.\n")

// Displays the parsed version number
SETTEXT(LANG_PARSEDVERSION, "Parsed verze je %s\n")

// The exe has been determined to be the DOS extended executable
SETTEXT(LANG_ISDOSEXTEXE, "Spustiteln� v DOSu.\n")

// The exe has been determined to be the Windows executable
SETTEXT(LANG_ISWINDOWSEXE, "Spustiteln� ve Windows.\n")

// The exe is of an unknown type
SETTEXT(LANG_ISUNKNOWNEXE, "Nezn�m� spou�t�c� form�t.\n")

// The exe is the wrong one for this TTDPatch, i.e. DOS/Windows mixed up. %s=DOS or Windows
SETTEXT(LANG_NOTSUPPORTED, "Promi�te, tato verze TTDPatch spolupracuje jen s %s verz�.\n")

// If the original .exe segment length (%lx) is too large or too small
SETTEXT(LANG_INVALIDSEGMENTLEN, "�patn� p�vodn� d�lka segment� %lx")

// When increasing the segment length
SETTEXT(LANG_INCREASECODELENGTH, "Nastavuji velikost programu na %s MB.\n")

// Can't write to TTDLOAD.OVL (%s) [or TTDLOADW.OVL for the Windows version]
SETTEXT(LANG_WRITEERROR, "Nelze zapisovat do %s, je nastaven jen ke �ten�\n")

// Installing the code loeader
SETTEXT(LANG_INSTALLLOADER, "Instaluji code loader.\n")

// TTDLOAD.OVL (%s) is invalid, needs to be deleted.
SETTEXT(LANG_TTDLOADINVALID, "Nemohu instalovat code loader")
SETTEXT(LANG_DELETEOVL, " - Zkuste vymazat %s.\n")

// TTDLOAD.OVL was verified to be correct
SETTEXT(LANG_TTDLOADOK, "%s je v po��dku.\n")

// Waiting for key before terminating TTDPatch after an error occured
SETTEXT(LANG_PRESSANYKEY, "Pro p�eru�en� stiskn�te kl�vesu.")

// Displayed on various warning conditions: Esc to exit, any other key to continue
SETTEXT(LANG_PRESSESCTOEXIT, "Stiskni kl�vesu pro pokra�ov�n� nebo Escape pro p�eru�en�.")

// Loading custom in-game texts
SETTEXT(LANG_LOADCUSTOMTEXTS, "Nahr�v�m obvykl� hern� texty.\n")

// ttdpttxt.dat is not in a valid format
SETTEXT(LANG_CUSTOMTXTINVALID, "�ten� %s: Chybn� form�t souboru.\n")

SETTEXT(LANG_CUSTOMTXTWRONGVER,
	"%s mus� b�t znovu vytvo�en pro tuto verzi TTDPatch.\n"
	"Spus�te nejnov�j� verzi mkpttxt.exe\n")


//-----------------------------------------------
//   COMMAND LINE HELP (-h)
//-----------------------------------------------

// Introduction, prefixed with "TTDPATCH V<version> - "
SETTEXT(LANG_COMMANDLINEHELP, "Uprav� TTD a spust� patchovac� program %s\n"
	  "\n"
	  "Pou�it�: TTDPATCH [-C cfg-soubor] [volby] [cesta k CD] [-W cfg-soubor]\n"
	  "\n")

// Lines of help for all on/off switches(volby), each at most 38 chars long.
// If you need more chars just insert another line.
TEXTARRAY(halflines,) =
	{ "-a: V�echny volby krom� -x",
	  "-d: V�dy uk��e cel� datum",
	  "-f: Refitov�n� vlak�",
	  "-g: Oprava glob�ln�ch chyb",
	  "-k: Mal� leti�t� v�dy",
	  "-l: Vlakov� n�dra�� a� 7x7",
	  "-n: Nov� non-stop",
	  "-q: Vylep�en� nakl�d�n�/vykl�d�n�",
	  "-s: Povolen� cheat�",
	  "-v: Zobrazit aktivn� volby",
	  "-w: Super-semafory automaticky",
	  "-y: P�esko�it hl��en� nezn�m� verze",
	  "-z: Dlouh� vlaky (126 voz�)",

	  "-B: Dlouh� mosty",
	  "-D: Super-dynamit",
	  "-E: P�esunuto �erven� hl��en�",
	  "-F: Full load alespo� jednoho typu",
	  "-G: V�b�r n�kladu ve stanici",
	  "-I: Vypnuta inflace",
	  "-J: V�ce leti� ve m�st�",
	  "-L: P�j�it/splatit max. s 'Ctrl'",
	  "-N: Roz��en� News",
	  "-O: Office Tower akceptuj� food",
	  "-P: Aktivace star�ch vozidel",
	  "-R: Auta �ekaj�c� ve front�",
	  "-S: Nov� modely lod�",
	  "-T: Nov� modely vlak�",
	  "-Z: Verze s malou pam�t� (3.5MB)",

	  "-2: N�kter� opravy pro Windows 2000",

	  "-Xb: �platky v menu Local Autority",
	  "-Xd: P�id�n� dep do p��kazu GOTO",
	  "-Xe: Nekone�n� hra po roce 2070",
	  "-Xf: Zefektivn� pomocn� vozidla",
	  "-Xg: Postupn� nakl�d�n�/vykl�d�n�",
	  "-Xi: Zabr�n� krachov�n� pr�myslu",
	  "-Xm: Volba Load v menu",
	  "-Xo: Cheaty za pen�ze",
	  "-Xr: V�dy vytvo�it TTDLOAD.OVL",
	  "-Xs: Zobrazen� rychlosti",
	  "-Xw: Nastaven� super-semafor�",
	  "-Xx: Ukl�d� a nahr�v� dal� data",

	  "-XA: Nucen� obnova vozidel s -Xa",
	  "-XE: Electrifikovan� trat�",
	  "-XF: Nastav� experimentaln� volby",
	  "-XG: V�dy nahraje novou grafiku",
	  "-XP: Nov� modely letadel",
	  "-XR: Nov� modely aut",
	  "-XS: Ovl�d�n� PC soupe�e",

	  "-Ya: Ratingy tolerant. ke v�ku vozidel",
	  "-Yb: Stav�n� v�ce v�c� na svahu",
	  "-Yc: R�zn� ceny za r�zn� typy trat�",
	  "-Ym: Umo�n� manu�ln� zm�nu trat�",
	  "-Ys: Semafor na stran�, kde jezd� auta",
	  "-Yt: Uk��e v�ce v�c� v okn� m�st",
	  "-Yw: Rychl� prodej vagon�",

	  "-YC: Stav�n� na b�ehu",
	  "-YH: V�ce/nov� hotkeys",
	  "-YP: Letadla se skute�nou rychlost�",
	  "-YS: Star� semafory p�ed rokem 1975",

	  NULL
	};
SETARRAY(halflines);

// Text describing the switches with values.  The lines have to be shorter
// than 79 chars, excluding the "\n".  Start new lines if necessary.
SETTEXT(LANG_FULLSWITCHES, "\n"
	  "-e #:    Umo�n� rozlehlej� zast�vky\n"
	  "-i #:    Nastaven� servisn�ho intervalu ve dnech\n"
	  "-x #:    Roz��� vehicle array na 850*#. Dal� informace v manu�lu!\n"
	  "-mc #:   Zv�� rychlost vlak� v kopc�ch a zat��k�ch\n"
	  "-trpb #: Zv�� po�et vlak�, aut, letadel a lod�\n"
	  "-A #:    Zv�� inteligenci soupe��. Pou��vejte pouze mal� hodnoty.\n"
	  "-M #:    Umo�n� v�cema�inov�m vlak�m nastavit zv��en� rychlosti v %%.\n"
	  "-Xa #:   Automatick� obnova vozidel # m�s�ce p�ed ukon�en�m jejich �ivotnosti\n"
	  "-Xc #:   Sn��� pravd�podobnost hav�rie letadla\n"
	  "-Yr #:   Zm�n� auto-vlakov� kolize na dan� typ (1/2)\n"
	  "-Xt #:   Nastav� maxim�ln� velikost m�st\n"
	  "-XC #:   Umo�n� v�ce m�n a nastav� jejich volby\n"
	  "-XD #:   Vybere, kter� katastrofy se mohou p�ihodit\n"
	  "-XM #:   Umo�n� kombinovat monorail a maglev\n"
	  "-XT #:   Nastav� kolik m�st bude r�st rychleji a v�ce\n"
	  "-XX #:   Rychlost na mostech u monorail a maglev v procentech z max.rychlosti\n"
	  "-XY #:   Nastav� startovn� rok pro novou hru\n"
	  "-X1 #, -X2 #: Max. �as �ek�n� vlaku p�ed jednosm�rn�mi resp. obousm�rn�mi semafory\n"
	  "-Yo #:   Ovl�d�n� dal�ch voleb (viz. dokumentace)\n"
	  "-Yp #:   Umo�n� s�zen� v�ce strom� najednou\n"
	  "-YB #:   V�ce stav�c�ch voleb, ovl�d�n� s parametrem\n"
	  "-YE #:   Nastav� �as v sec. jak dlouho bude zobrazeno �erven� hl��en�\n"
	  "-YG #:   Roz��� u�ivatelsk� interface, v�b�r volby s parametrem\n"
	  "-YT #:   Nastav� algoritmus r�stu m�st\n"
	  "\n"
	  "-C cfg-file:  Spust� TTDPatch s t�mto cfg souborem m�sto ttdpatch.cfg\n"
	  "-W cfg-file:  Vytvo�� cfg soubor se sou�asnou konfigurac�\n"
	  "\n"
	  "Pozor na psan� velk�ch a mal�ch p�smen!\n"
	  "\n"
	  "P��klad:  ttdpatch -fnqz -m 00 -c 13 -trpb 240 -FG -A 2 -v\n"
	  "\n"
	  "(Hint:  Jestli�e v�echno scrolovalo velmi rychle, vlo�te \"ttdpatch -h|more\")\n"
	  "\n")

// Referral to the docs, prefixed by "Copyright (C) 1999 by Josef Drexler.  "
SETTEXT(LANG_HELPTRAILER, "V�ce informac� naleznete v TTDPATCH.TXT.\n")


//-----------------------------------------------
//  COMMAND LINE AND CONFIG FILE PARSING
//-----------------------------------------------

// if an on/off switch has a value other than the above (%s = wrong value)
SETTEXT(LANG_UNKNOWNSTATE, "Pozor: Nezn�m� parametr %s, nastaveno na off.\n")

// switch is unknown.  %c is '-' or '/' etc, %s is the switch char
SETTEXT(LANG_UNKNOWNSWITCH, "Nezn�m� parametr '%c%s'. Pou�ijte -h pro pomoc.\n")

// cfg command %s is unknown
SETTEXT(LANG_UNKNOWNCFGLINE, "Pozor: Chybn� p��kaz v cfg souboru '%s'.\n")

// Names of the switches for the '-v' options
// First string is shown always, second only if set and with the given
// value of the switch in %d.
// These lines (both parts) are limited to 36 chars, also consider how large
// the expansion of the %d can be for that switch.
SWITCHTEXT(uselargerarray, "Roz��en� po�tu vozidel", " na %d*850")
SWITCHTEXT(usenewcurves, "Rychlosti v zat��k�ch", " k�d %04x")
SWITCHTEXT(usenewmountain, "Rychlosti na svahu", " k�d %04x")
SWITCHTEXT(usenewnonstop, "Odli�n� NON-STOP", "")
SWITCHTEXT(increasetraincount, "Max. po�et vlak�", ": %d")
SWITCHTEXT(increaservcount, "Max. po�et aut", ": %d")
SWITCHTEXT(setnewservinterval, "Servisn� interval", ": %d dn�")
SWITCHTEXT(usesigncheat, "Pou�it� cheat�", "")
SWITCHTEXT(allowtrainrefit, "Povoleno refitov�n� vlak�", "")
SWITCHTEXT(increaseplanecount, "Max. po�et letadel", ": %d")
SWITCHTEXT(increaseshipcount, "Max. po�et lod�", ": %d")
SWITCHTEXT(keepsmallairports, "V�dy stav�t mal� leti�t�", "")
SWITCHTEXT(largerstations, "Kombinovan� stanice", " do %d �tverc�")
SWITCHTEXT(morestationtracks, "Vlakov� n�dra�� a� 7x7", "")
SWITCHTEXT(longerbridges, "Dlouh� mosty", "")
SWITCHTEXT(improvedloadtimes, "Vylep�en� nakl�d�n�/vykl�d.", "")
SWITCHTEXT(mammothtrains, "Mamut� vlaky (max.d�lka 126)", "")
SWITCHTEXT(presignals, "Super-semafory automaticky", "")
SWITCHTEXT(officefood, "Office Tower akceptuj� j�dlo", "")
SWITCHTEXT(noinflation, "Vypnut� inflace", "")
SWITCHTEXT(maxloanwithctrl, "P�j�it/splatit max. s 'Ctrl'", "")
SWITCHTEXT(persistentengines, "Aktivace star�ch vozidel", "")
SWITCHTEXT(fullloadany, "Full load alespo� jednoho typu", "")
SWITCHTEXT(selectstationgoods, "V�b�r n�kladu ve stanici", "")
SWITCHTEXT(morethingsremovable, "V�ce v�c� lze obnovit", "")
SWITCHTEXT(multihead, "V�cema�inov� vlaky", "rychlost: %d%%")
SWITCHTEXT(newlineup, "Auta �ekaj�c� ve front�", "")
SWITCHTEXT(lowmemory, "N�zkopam؜ov� verze (3.5MB)", "")
SWITCHTEXT(generalfixes, "Obecn� opravy (viz. manu�l)", "")
SWITCHTEXT(moreairports, "V�ce leti� v jednom m�st�", "")
SWITCHTEXT(bribe, "�platky v menu Local Autority", "")
SWITCHTEXT(noplanecrashes, "Hav�rie letadel", " k�d %d")
SWITCHTEXT(showspeed, "Zobrazen� rychlost vozidel", "")
SWITCHTEXT(autorenew, "Auto-obnova vozidel", " od %d m�s�c�")
SWITCHTEXT(cheatscost, "Cheaty za pen�ze", "")
SWITCHTEXT(extpresignals, "Nastaven� super-semafor�", "")
SWITCHTEXT(diskmenu, "Volba Load v menu", "")
SWITCHTEXT(win2k, "N�kter� opravy pro Windows 2000/XP", "")
SWITCHTEXT(feederservice, "Pomocn� vozidla maj� zisk", "")
SWITCHTEXT(gotodepot, "P�id�n� dep do p��kazu GOTO", "")
SWITCHTEXT(newships, "Nov� modely lod�", "")
SWITCHTEXT(subsidiaries, "Ovl�d�n� soupe��", "")
SWITCHTEXT(gradualloading, "Postupn� nakl�d�n�/vykl�d.", "")
SWITCHTEXT(moveerrorpopup, "P�esunuto �erven� hl��en�", "")
SWITCHTEXT(setsignal1waittime, "Nov� �ekac� �as p�ed semafory", ":")
SWITCHTEXT(setsignal2waittime, "", "")				// dummy entry
SWITCHTEXT(maskdisasters, "Katastrofy", " k�d %d")
SWITCHTEXT(forceautorenew, "Nucen� obnova vozidel", "")
SWITCHTEXT(morenews, "Roz��en� News", "")
SWITCHTEXT(unifiedmaglev, "Sjednocen� maglev", " k�d %d")
SWITCHTEXT(newbridgespeeds, "Max rychlost na mostech", " k�d %d%%")
SWITCHTEXT(eternalgame, "Nekone�n� hra po roce 2070", "")
SWITCHTEXT(showfulldate, "V�dy zobrazeno cel� datum", "")
SWITCHTEXT(newtrains, "Nov� modely vlak�", "")
SWITCHTEXT(newrvs, "Nov� modely aut", "")
SWITCHTEXT(newplanes, "Nov� modely letadel", "")
SWITCHTEXT(signalsontrafficside, "Semafory vlevo-vpravo podle aut", "")
SWITCHTEXT(electrifiedrail, "Elektrifikovan� trat�", "")
SWITCHTEXT(newstartyear, "Startovn� rok", ": %d")
SWITCHTEXT(newerrorpopuptime, "Trv�n� �erven�ho hl��en�", ": %d s")
SWITCHTEXT(newtowngrowthfactor, "Faktor r�stu m�st", " k�d %d")
SWITCHTEXT(largertowns, "V�t� m�sta", ", ka�d� 1 z %d")
SWITCHTEXT(miscmods, "Mnohostrann� m�dy", " k�d %d")
SWITCHTEXT(loadallgraphics, "Nahr�n� ka�d�ho souboru nov� grafiky", "")
SWITCHTEXT(saveoptdata, "Ulo�en� a nahr�t� roz��en�ch dat", "")
SWITCHTEXT(morebuildoptions, "Roz��en� stav�n�", " k�d %d")
SWITCHTEXT(semaphoresignals, "Star� semafory p�ed rokem 1975", "")
SWITCHTEXT(morehotkeys, "V�ce voleb ovl�dan�ch kl�vesami", "")
SWITCHTEXT(plantmanytrees, "S�zen� v�ce strom� najednou", ", k�d %d")
SWITCHTEXT(morecurrencies, "V�ce m�n", ", k�d %d")
SWITCHTEXT(manualconvert, "Manu�ln� zm�na trat�", "")
SWITCHTEXT(newtowngrowthrate, "Algoritmus r�stu m�st", " k�d %d")
SWITCHTEXT(displmoretownstats, "V�ce statistik v okn� m�st", "")
SWITCHTEXT(enhancegui, "Roz��en� hern� interface", " k�d %d")
SWITCHTEXT(newagerating, "Rating tolerantn�j� ke v�ku vozidel", "")
SWITCHTEXT(buildonslopes, "Stav�n� na svahu", "")
SWITCHTEXT(buildoncoasts, "Stav�n� na pob�e�� bez dynamitu", "")
SWITCHTEXT(experimentalfeatures, "Posledn� experiment�ln� mo�nosti", ": %d")
SWITCHTEXT(tracktypecostdiff, "R�zn� ceny za r�zn� typy trat�", "")
SWITCHTEXT(planespeed, "Re�ln� rychlost letadel", "")
SWITCHTEXT(fastwagonsell, "Rychlej� prodej vagon�", "")
SWITCHTEXT(newrvcrash, "Auto-vlakov� kolize"," k�d %d")
SWITCHTEXT(stableindustry, "Pr�mysl nekrachuje p�i stabl. ekonom","")

// A cfg file (%s) could not be found and is ignored.
SETTEXT(LANG_CFGFILENOTFOUND, "Nemohu nal�zt cfg soubor %s.  Ignoruji jej.\n")

// Couldn't write the config file
SETTEXT(LANG_CFGFILENOTWRITABLE, "Nemohu otev��t %s pro z�pis.\n")

// A non-comment line is longer than 32 chars, rest ignored.
SETTEXT(LANG_CFGLINETOOLONG, "POZOR!  Konfigura�n� ��dek je del� ne� 32 znak�, zbytek ignorov�n.\n")

// Shown if an obsolete switch is used. First option is %s which is the
// config name, second one is %s which is the command line char
SETTEXT(LANG_SWITCHOBSOLETE, "Volba `%s' (%s) je nefunk�n�. Pros�m, nepou��vejte ji v p���t�\n"
		"verzi bude odstran�na.\n")

//---------------------------------------------------
//   CONFIG FILE COMMENTS (for '-W')
//---------------------------------------------------

// This is the intro at the start of the config file.  No constraints on line lengths.
SETTEXT(CFG_INTRO,
	CFG_COMMENT "\n"
	CFG_COMMENT "Konfigura�n� soubor TTDPatch.cfg byl automaticky vytvo�en pomoc� TTDPatch -W N�zevSouboru.\n"
	CFG_COMMENT "(TTDPatch %s)\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Form�t volby je:\n"
	CFG_COMMENT "   N�zev = Hodnota k�d\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Znak \"=\" m��e b�t opominut a nahrazen mezerou.\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Hodnota yes/no [y/n] ano/ne, m��e b�t zad�na t�mito znaky:\n"
	CFG_COMMENT "yes, y, on, 1, a, no, n, off, 0,\n"
	CFG_COMMENT "Jestli�e je hodnota vynech�na je volba nastavena na ano/yes.\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Pro volby s k�dem je rozsah d�n v pozn�mce\n"
	CFG_COMMENT "V p��pad�, �e k�d je opominut je volba nastavena na Default.\n"
	CFG_COMMENT "N�kter� volby mohou b�t vypnuty zad�n�m k�du, kter� je vypne.\n"
	CFG_COMMENT "\n"
	CFG_COMMENT "Koment��e jsou v�echny ��dky za��naj�c� dv�ma lom�tky.\n"
	CFG_COMMENT "\n")

// Line before previously unset switches
SETTEXT(CFG_NEWSWITCHINTRO, "**** Seznam voleb ****")

// For switches which have no command line equivalent
SETTEXT(CFG_NOCMDLINE, "��dn� switch")

// Definitions of the cfg file comments.
// All can have a place holder %s to stand for the actual setting name,
// and all but CFG_CDPATH can have a %s *after* the %s for the command
// line switch.
// They will have the "comment" char and a space prefixed.
//
SETTEXT(CFG_SHIPS, "`%s' (%s) Maxim�ln� po�et lod�.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_CURVES, "`%s' (%s) Rychlost v zat��k�ch 0 - normal, 1 - rychlej�, 2 - nejrychlej�, 3 - re�ln�.  Jedno ��slo pro ka�d� typ trat� a silnici.  Default 0120.")
SETTEXT(CFG_MOUNTAINS, "`%s' (%s) Rychlost na svahu 0 - normal, 1 - rychlej�, 2 - nejrychlej�, 3 - re�ln�. Jedno ��slo pro ka�d� typ trat� a silnici.  Default 0120.")
SETTEXT(CFG_SPREAD, "`%s' (%s) Rozlehlost spole�n�ch zast�vek.  Rozsah %ld - %ld �tverc�.  Default %ld.")
SETTEXT(CFG_TRAINREFIT, "`%s' (%s) Zp��stupn� refitov�n� ma�in.")
SETTEXT(CFG_SERVINT, "`%s' (%s) Po��te�n� servisn� interval pro nov� vozidla.  Rozsah %ld - %ld dn�.  Default %ld.")
SETTEXT(CFG_NOINFLATION, "`%s' (%s) Vypne v�echny inflace, pro n�kupy i pro n�vratnost.")
SETTEXT(CFG_LARGESTATIONS, "`%s' (%s) Umo�n� p�idat v�ce n�stupi� a del� stanice, do 15x15.")
SETTEXT(CFG_NONSTOP, "`%s' (%s) Odli�n� \"Non-stop\" volba.")
SETTEXT(CFG_PLANES, "`%s' (%s) Maxim�ln� po�et letadel.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_LOADTIME, "`%s' (%s) Nov� kalkulace �asu p�i nakl�d�n� a vykl�d�n�.")
SETTEXT(CFG_ROADVEHS, "`%s' (%s) Maxim�ln� po�et aut.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_SIGNCHEATS, "`%s' (%s) Zapne cheaty.")
SETTEXT(CFG_TRAINS, "`%s' (%s) Maxim�ln� po�et vlak�.  Rozsah %ld - %ld.  Default %ld.")
//*#define CFG_PLAYERS "`%s' (-%s) Nastav�, kte�� hr��i mohou po��vat cheaty.  Seznam hr��� od 0 - 7"
SETTEXT(CFG_VERBOSE, "`%s' (%s) Uk��e seznam voleb a jejich hodnot p�ed spu�t�n�m TTD.")
SETTEXT(CFG_PRESIGNALS, "`%s' (%s) Automaticky nastavuje super-semafory.")
SETTEXT(CFG_MOREVEHICLES, "`%s' (%s) Celkov� po�et vozidel na hodnota*850.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_MAMMOTHTRAINS, "`%s' (%s) Dlouh� vlaky s a� 126 vagony.")
SETTEXT(CFG_FULLLOADANY, "`%s' (%s) Umo�n� aby vlak opustil stanici jestli�e jeden z typ� n�kladu je nalo�en.")
SETTEXT(CFG_SELECTGOODS, "With `%s' (%s) Zbo�� se objev� ve stanici a� ho n�kter� vozidlo vy�aduje.")
SETTEXT(CFG_DEBTMAX, "`%s' (%s) Zapne p�j�ov�n�/spl�cen� cel� maxim�ln� ��stky s 'Ctrl'.")
SETTEXT(CFG_OFFICEFOOD, "`%s' (%s) Office towers akceptuj� j�dlo (tropic/arctic scenaria).")
SETTEXT(CFG_ENGINESPERSIST, "`%s' (%s) Zobraz� ke koupi star� vozidla.")
SETTEXT(CFG_CDPATH, "`%s' (%s) Nastav� cestu k CD.")
// Note- CFG_CDPATH has no command line switch, so don't give the second %s!
SETTEXT(CFG_KEEPSMALLAP, "`%s' (%s) Umo�n� v�dy stav�t mal� leti�t�.")
SETTEXT(CFG_AIBOOST, "`%s' (%s) Inteligence soupe��.")
SETTEXT(CFG_LONGBRIDGES, "`%s' (%s) Umo�n� stav�t mosty dlouh� a� 127 �tverc�.")
SETTEXT(CFG_DYNAMITE, "`%s' (%s) Umo�n� v�ce mo�nost� pro bour�n� dynamitem.")
SETTEXT(CFG_MULTIHEAD, "`%s' (%s) Umo�n� v�ce ma�inov� vlaky s 'Ctrl'.  Parametr je max. sou�et rychlost� ma�in, v procentech %ld %ld, default %ld%%.")
SETTEXT(CFG_RVQUEUEING, "`%s' (%s) Nastav� aby auta �ekala ve front� p�ed stanic� a neot��ela se.")
SETTEXT(CFG_LOWMEMORY, "`%s' (%s) Umo�n� aby TTDPatch bاel i s pam�t� do 3.5MB, ale sn��� maxim�ln� po�et vozidel na 2x850.")
SETTEXT(CFG_GENERALFIXES, "`%s' (%s) Odstran� n�kter� mal� chyby viz. maul�l.")
SETTEXT(CFG_MOREAIRPORTS, "`%s' (%s) Umo�n� stavbu v�ce ne� dvou leti� ve m�st�.")
SETTEXT(CFG_BRIBE, "`%s' (%s) P�id� mo�nost upl�cen� `bribe' v local authority menu.")
SETTEXT(CFG_PLANECRCTRL, "`%s' (%s) Umo�n� ovl�d�n� hav�ri� letadel. Dvoucifern� hodnota, default 1.")
SETTEXT(CFG_SHOWSPEED, "`%s' (%s) Uk��e sou�asnou rychlost vozidla v jeho okn�.")
SETTEXT(CFG_AUTORENEW, "`%s' (%s) Zapne autoobnovu vozidel kdy� dos�hnou pl�novan�ho ukon�en� jejich �ivotnosti. Parametr je po�et m�s�c� od tohoto term�nu.  Rozsah %ld a� +%ld.  Default %ld.")
SETTEXT(CFG_CHEATSCOST, "`%s' (%s) Umo�n� aby cheaty st�ly pen�ze kdy� se pou�ij�.")
SETTEXT(CFG_EXTPRESIGNALS, "`%s' (%s) Umo�n� m�nit mezi norm�ln�mi semafory a super-semafory pomoc� 'Ctrl'.")
SETTEXT(CFG_FORCEREBUILDOVL, "`%s' (%s) Umo�n� aby TTDPatch zm�nil p�i ka�d�m startu TTDLOAD.OVL nebo TTDLOADW.OVL.")
SETTEXT(CFG_DISKMENU, "`%s' (%s) P�id� do hern�ho menu funkci LOAD GAME a do scenario menu, funkci LOAD GAME a SAVE GAME (s 'Ctrl').")
SETTEXT(CFG_WIN2K, "`%s' (%s) Ud�l� Windows verzi TTD compatibiln� s Windows 2000/XP.")
SETTEXT(CFG_FEEDERSERVICE, "`%s' (%s) Zm�n� unload a profit ve stanic�ch akceptuj�c�ch n�klad od pomocn�ch vozidel viz. manul�l.")
SETTEXT(CFG_GOTODEPOT, "`%s' (%s) Umo�n� p�id�n� depa jako c�l vozidla.")
SETTEXT(CFG_NEWSHIPS, "`%s' (%s) Aktivuje nov� typy lod� v�etn� nov� grafiky.")
SETTEXT(CFG_SUBSIDIARIES, "`%s' (%s) Umo�n� ovl�dat soupe�e p�i vlastn�n� 75%%.")
SETTEXT(CFG_GRADUALLOADING, "`%s' (%s) Zm�n� nakl�d�n� a vykl�d�n� n�klad� na v�ce realistick� (tak� aktivuje `loadtime').")
SETTEXT(CFG_MOVEERRORPOPUP, "`%s' (%s) P�em�st� �erven� hl��en� do horn�ho lev�ho rohu obrazovky.")
SETTEXT(CFG_SIGNAL1WAITTIME, "`%s' (%s) Po�et dn�, po kter�ch se vlak oto�� p�ed jednosm�rn�m semaforem.  Rozsah 0 - 254, nebo 255 pro neot��en�. Default 70.")
SETTEXT(CFG_SIGNAL2WAITTIME, "`%s' (%s) Po�et dn�, po kter�ch se vlak oto�� p�ed obousm�rn�m semaforem. Hodnota 0 - 254, nebo 255 pro neot��en�. Default 20.")
SETTEXT(CFG_DISASTERS, "`%s' (%s) Nastav� katastrofy, kter� mohou nastat. Dvoucifern� hodnota, Default 255 (v�echny katastrofy).")
SETTEXT(CFG_FORCEAUTORENEW, "`%s' (%s) P�inut� vozidla zajet do depa, kdy� je �as na autoobnovu (viz. `autorenew').")
SETTEXT(CFG_MORENEWS, "`%s' (%s) Hra informuje o dal�ch ud�lostech (nap�. vyk�cen� v�ech strom� u Lumber millu v tropick�m sc�n�riu).")
SETTEXT(CFG_UNIFIEDMAGLEV, "`%s' (%s) Umo�n� kupovat monorail ma�iny v maglev depu a naopak. K�d: 1 - zm�n� v�echny maglev na monorail; 2 - zm�n� v�echny monorail na maglev; 3 - udr�uje monorail a maglev odd�len�.")
SETTEXT(CFG_BRIDGESPEEDS, "`%s' (%s) Zm�n� rychlostn� limit na tubusov�ch mostech pro monorail a maglev na procento z maxim�ln� rychlosti nejrychlej� ma�iny, kterou je mo�no koupit.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_ETERNALGAME, "`%s' (%s) Umo�n� hru i po roce 2070. Letopo�et se nezastav�.")
SETTEXT(CFG_SHOWFULLDATE, "`%s' (%s) V�dy uk��e cel� datum (i kdy� hra nen� zapauzovan�).")
SETTEXT(CFG_NEWTRAINS, "`%s' (%s) Aktivuje nov� modely vlak� v�etn� nov� grafiky.")
SETTEXT(CFG_NEWRVS, "`%s' (%s) Aktivuje nov� modely aut v�etn� nov� grafiky.")
SETTEXT(CFG_NEWPLANES, "`%s' (%s) Aktivuje nov� modely letadel v�etn� nov� grafiky.")
SETTEXT(CFG_SIGNALSONTRAFFICSIDE, "`%s' (%s) Zobraz� semafory na t� stran�, po kter� jezd� auta.")
SETTEXT(CFG_ELECTRIFIEDRAIL, "`%s' (%s) Odstran� monorail nebo maglev a m�sto toho p�id� elektrifikovan� trat�.")
SETTEXT(CFG_STARTYEAR, "`%s' (%s) Nastav� startovn� rok pro n�hodnou hru a umo�n� rozs�hlej� v�b�r startovn�ho roku v editoru. Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_ERRORPOPUPTIME, "`%s' (%s) �as, po kter�m automaticky zmiz� �erven� hl��en� v sekund�ch.  Rozsah 1 - 255, ( 0 pro velmi dlouh� �as.  Default 10.")
SETTEXT(CFG_TOWNGROWTHLIMIT, "`%s' (%s) Maxim�ln� mo�n� rozsah m�st. Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_LARGERTOWNS, "`%s' (%s) Po�et m�st, ze kter�ch jedno roste rychleji a v�ce (tak� aplikuje `towngrowthlimit' selektivn�).  Rozsah %ld - %ld.  Default %ld (jedno m�sto ze �ty�).")
SETTEXT(CFG_MISCMODS, "`%s' (%s) Zm�n� funkci n�kter�ch voleb nebo je modifikuje viz. manu�l.  Rozsah dvoucifern� hodnota Default 0 (��dn� modifikace).")
SETTEXT(CFG_LOADALLGRAPHICS, "`%s' (%s) P�inut� TTDPatch v�dy nahr�t v�echny *.grf soubory v newgrf(w).cfg, bez ohledu na to, zda byly pou�ity v p�edch�zej�c�m spu�t�n� hry nebo ne.")
SETTEXT(CFG_SAVEOPTDATA, "`%s' (%s) TTDPatch ulo�� p�idan� data na konec souboru (funguje i pro nahr�v�n� save s p�idan�mi daty).")
SETTEXT(CFG_MOREBUILDOPTIONS, "`%s' (%s) V�ce mo�nost� p�i stav�n�. Rozsah %ld - %ld. Default %ld.")
SETTEXT(CFG_SEMAPHORES, "`%s' (%s) P�ed rokem 1975 jdou postavit pouze star� mechanick� semafory.")
SETTEXT(CFG_MOREHOTKEYS, "`%s' (%s) Zapnuty nov� kl�vesy pro ovl�d�n� n�kter�ch funkc� ve h�e.")
SETTEXT(CFG_MANYTREES, "`%s' (%s) Umo�n� zasadit  v�ce ne� jeden strom najednou, ozna�en�m dvou protilehl�ch vrchol� obdl�ln�ku s Ctrl.")
SETTEXT(CFG_MORECURRENCIES,"`%s' (%s) Zapne v�ce m�n v�etn� Euro po roce 2002.  0 - jednotka je na p�vodn�m m�st�; 1 - jednotka je p�ed ��sly; 2 - jednotka je za ��sly. 4 - zak��e Euro.")
SETTEXT(CFG_MANCONVERT,"`%s' (%s) Umo�n� ru�n� zm�nu trat� um�st�n�m nov�ho typu trat� na ji� existuj�c� tra� (bez dynamitu).")
SETTEXT(CFG_NEWAGERATING, "`%s' (%s) Rating zast�vek je v�ce tolerantn� k v�ku vozidel.  Vag�ny mohou b�t a� 21 let star� m�sto 3 let.")
SETTEXT(CFG_ENHANCEGUI,"`%s' (%s) Zm�n� grafick� vzhled n�kter�ch oken.")
SETTEXT(CFG_TOWNGROWTHRATEMODE, "`%s' (%s) Umo�n� definovat pravidla pro kalkulaci r�stu m�st. 0 - TTD original, 1 - TTD vylep�en�, 2 - u�ivatelsk�.  Viz dokumentace.")
SETTEXT(CFG_TOWNGROWTHRATEMIN, "`%s' (%s) Definuje minim�ln� r�st m�st. Jedn� se o po�et nov�ch dom� za sto let.  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TOWNGROWTHRATEMAX, "`%s' (%s) Definuje maxim�ln� r�st m�st. Jedn� se o po�et nov�ch dom� za sto let.  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRACTSTATIONEXIST, "`%s' (%s) Definuje kolik z existuj�c�ch aktivn�ch zast�vek zvy�uje r�st m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld +%ld.  Default %ld.")
SETTEXT(CFG_TGRACTSTATIONS, "`%s' (%s) Definuje kolik zast�vek zvy�uje r�st m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRACTSTATIONSWEIGHT, "`%s' (%s) Definuje jak aktivn� zast�vky p�isp�vaj� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRPASSOUTWEIGHT, "`%s' (%s) Definuje jak efektivn� odj��d�j�c� lid� p�isp�vaj� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRMAILOUTWEIGHT, "`%s' (%s) Definuje jak efektivn� odj��d�j�c� po�ta p�isp�v� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRPASSINMAX, "`%s' (%s) Definuje maxim�ln� po�et p�ij��d�j�c�ch lid�, kter� m��e m�t efekt na r�st m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRPASSINWEIGHT, "`%s' (%s) Definuje jak efektivn� p�ij��d�j�c� lid� p�isp�vaj� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRMAILINOPTIM, "`%s' (%s) Definuje optim�ln� populaci na ka�d� 2 bal�ky p��j��d�j�c� po�ty (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRMAILINWEIGHT, "`%s' (%s) Definuje jak efektivn� p�ij��d�j�c� po�ta p�isp�v� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRGOODSINOPTIM, "`%s' (%s) Definuje optim�ln� populaci na ka�d� 2 ks zbo�� (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRGOODSINWEIGHT, "`%s' (%s) Definuje jak efektivn� p�ij��d�j�c� zbo�� p�isp�v� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRFOODINMIN, "`%s' (%s) Definuje minim�ln� pot�ebu j�dla ve m�stech ve sn�hem pokryt�ch m�stech a v pou�t�ch. Kolik populace na 2 tuny p�ij��d�j�c�ho j�dla (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRFOODINOPTIM, "`%s' (%s) Definuje optimum populace na ka�d� 2 tuny p�ij��d�j�c�ho j�dla (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRFOODINWEIGHT, "`%s' (%s) Definuje jak efektivn� p�ij��d�j�c� j�dlo p�isp�v� k r�stu m�st (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRWATERINMIN, "`%s' (%s) Definuje minim�ln� pot�ebu vody ve m�stech v pou�t�ch. Kolik populace na 2 tuny (2000 litr�) p�ij��d�j�c� vody (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRWATERINOPTIM, "`%s' (%s) Definuje optimum populace na ka�d� 2 tuny (2000 litr�) p�ij��d�j�c� vody v tropick�m klimatu (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRWATERINWEIGHT, "`%s' (%s) Definuje jak efektivn� p�ij��d�j�c� vody p�isp�v� k r�stu m�st v tropick�m klimatu (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRSWEETSINOPTIM, "`%s' (%s) Definuje optim�ln� populaci na ka�d� 2 ks p�ij��d�j�c�ch sladkost� v d�tsk�m klimatu (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRSWEETSINWEIGHT, "`%s' (%s) Definuje jak efektivn� p�iji�d�j�c� sladkosti p�isp�vaj� k r�stu m�st v d�tsk�m klimatu (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRFIZZYDRINKSINOPTIM, "`%s' (%s) Definuje optim�ln� populaci na ka�d� 2 ks p�ij��d�j�c�ch limon�d v d�tsk�m klimatu (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRFIZZYDRINKSINWEIGHT, "`%s' (%s) Definuje jak efektivn� limon�dy p�isp�vaj� k r�stu m�st v d�tsk�m klimatu (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TGRTOWNSIZEBASE, "`%s' (%s) Definuje z�kladn� po�et m�stsk�ch budov pro v�po�et volby `tgrtownsizefactor' (viz. dokumentace).  Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld..%ld.  Default %ld.")
SETTEXT(CFG_TGRTOWNSIZEFACTOR, "`%s' (%s) Definuje, jak velik� vliv m� velikost m�st na r�st m�st (viz. dokumentace). Aktivn� pouze kdy� volba `towngrowthratemode' = 2.  Rozsah %ld - %ld.  Default %ld (tzn. 25 procentn� vliv).")
SETTEXT(CFG_TOWNMINPOPULATIONSNOW, "`%s' (%s) Definuje minimum populace v sn�hem pokryt�ch m�stech, od kter�ho mohou r�st bez podpory j�dla. Aktivn� pouze kdy� jsou volby `towngrowthratemode', `towngrowthlimit' a `generalfixes' zapnuty.  Rozsah %ld - %ld.  Default %ld.")
SETTEXT(CFG_TOWNMINPOPULATIONDESERT, "`%s' (%s) Definuje minimum populace ve m�stech na pou�ti, od kter�ho mohou r�st bez podpory vodou a j�dlem. Aktivn� pouze kdy� jsou volby `towngrowthratemode', `towngrowthlimit' a `generalfixes' zapnuty.  Rozsah %ld - %ld. Default %ld.")
SETTEXT(CFG_MORETOWNSTATS, "`%s' (%s) Zobraz� v�ce informac� v okn� m�sta.")
SETTEXT(CFG_BUILDONSLOPES, "`%s' (%s) Umo�n� stav�n� trat�, silnic a zast�vek na svahu se stejn�m z�kladem jako u dom�.")
SETTEXT(CFG_BUILDONCOASTS, "`%s' (%s) Umo�n� stav�n� na b�ehu bez p�edchoz�ho pou�it� dynamitu.")
SETTEXT(CFG_TRACKTYPECOSTDIFF, "`%s' (%s) R�zn� typy trat� maj� r�znou cenu.")
SETTEXT(CFG_CUSMULTIPLIER, "`%s' (%s) P�epo��t�vac� koeficient pro vlastn� m�nu - custom currency CUS * 1000.  Default is 1000 (1 CUS = 1 pound).  Aktivn� pouze p�i zapnut� `morecurrencies'.")
SETTEXT(CFG_EXPERIMENTALFEATURES, "`%s' (%s) Zapne nov� experiment�ln� volby.")
SETTEXT(CFG_PLANESPEED, "`%s' (%s) Zrychl� letadla na jejich skute�nou indikovanou rychlost (p�vodn� rychlost je �tvrtinov� oproti indikovan�) a p�i stavu Brake Down zredukuje rychlost na 5/8.")
SETTEXT(CFG_FASTWAGONSELL, "`%s' (%s) Rychlej� prodej vag�n� s Ctrl")
SETTEXT(CFG_NEWRVCRASH,"`%s' (%s) M�n� auto-vlakov� kolize. Hodnota 1 znamen�, �e vlak po kolizi s autem bude chv�li ve stavu Brake Down. Hodnota 2 vypne auto-vlakov� kolize. Default 1.");
SETTEXT(CFG_STABLEINDUSTRY,"`%s' (%s) ��dn� pr�mysl nezkrachuje p�i stabiln� ekonomice (v menu Difficulty settings je polo�ka Economy nastavena na Steady).");


//----------------------------------------------------
//   SWITCH DISPLAY ('-v')
//----------------------------------------------------

// Wait for a key before displaying the switches
SETTEXT(LANG_SWWAITFORKEY, "\nStiskem Enter se spust� TTD, stiskem Escape se program p�eru�, stiskem jin� kl�vesy se uk��ou volby a jejich hodnoty.")

// Introduction
SETTEXT(LANG_SHOWSWITCHINTRO, "    Nastaven� voleb:   (%c zapnuto, %c vypnuto)\n")

// Five characters: vertical line for the table; enabled switch; disabled switch;
// table heading; table heading column separator.
SETTEXT(LANG_SWTABLEVERCHAR, "�+-��")

// 1-way and 2-way captions after "New train wait time on red signals"
SETTEXT(LANG_SWONEWAY, "Jednosm�rn�: ")
SETTEXT(LANG_SWTWOWAY, "Obousm�rn�: ")

// Train wait time is either in days or infinite
SETTEXT(LANG_TIMEDAYS, "%d dn�")
SETTEXT(LANG_INFINITETIME, "nekone�n�")

// Shows the load options for ttdload.  %s is the given parameters to be passed to ttdload
SETTEXT(LANG_SWSHOWLOAD, "Stiskni kl�vesu pro start \"TTDLOAD %s\" (Escape pro odchod).")

SETTEXT(LANG_SWABORTLOAD, "\nProgram je p�eru�en u�ivatelem.\n")


//---------------------------------------
//  STARTUP AND REPORTING
//---------------------------------------

// Internal error in TTDPatch (%d is error number)
SETTEXT(LANG_INTERNALERROR, "*** Vnit�n� chyba TTDPatch #%d ***\n")

// Error fixing the Windows version HDPath registry entry
SETTEXT(LANG_REGISTRYERROR, "TTD nen� spr�vn� nainstalov�n (chyba registru %d)\n")

// DOS reports no memory available
SETTEXT(LANG_NOTENOUGHMEM, "Nen� dost pam�ti pro start programu. Nyn� je %s, a je pot�eba %d KB.\n")

// ...for starting TTD
SETTEXT(LANG_TOSTARTTTD, "pro start TTD")

// Protected mode code exceeds 32kb
SETTEXT(LANG_PROTECTEDTOOLARGE, "Ochrann� m�d je p��li� rozlehl�!\n")

// Swapping TTDPatch out
SETTEXT(LANG_SWAPPING, "Swapov�n� ukon�eno.\n")

// Just before running ttdload, show this.
// 1st %s is ttdload.ovl, then %s is a space if there are options,
// and the 3rd %s contains the options
SETTEXT(LANG_RUNTTDLOAD, "Startuje %s%s%s\n")

// Error executing ttdload.  1st %s is ttdload.ovl, 2nd %s is the error message from the OS
SETTEXT(LANG_RUNERROR, "Nemohu naj�t %s: %s\n")

// Show the result after after running, %s is one of the following strings
SETTEXT(LANG_RUNRESULT, "V�sledek: [%s]\n")
SETTEXT(LANG_RUNRESULTOK, "OK")
SETTEXT(LANG_RUNRESULTERROR, "Chyba!")

// Messages about the graphics file ttdpatch.grf
SETTEXT(LANG_NOTTDPATCHGRF, "Nemohu naj�t cestu k souboru %s, vytv���m pr�zdn� soubor.\n")
SETTEXT(LANG_ERRORCREATING, "Chyba p�i vytv��en� %s: %s\n")
