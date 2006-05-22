//
// This file is part of TTDPatch
// Copyright (C) 1999-2001 by Josef Drexler
//
// C++ to C conversion by Marcin Grzegorczyk
//
// switches.c: defines functions dealing with the switches
//

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <ctype.h>

#if defined(WIN32) || !WINTTDX
#	include <conio.h>
#else
#	define getch() getc(stdin)
#	define kbhit() 0
#	define stricmp strcasecmp
#	define strnicmp strncasecmp
#endif

#include "codepage.h"
#include "error.h"

#define IS_SWITCHES_CPP
#include "switches.h"
#include "language.h"
#include "loadlng.h"

#if WINTTDX
#	include "versionw.h"
#else
#	include "versiond.h"
#endif


int showswitches = 0;
//int writeverfile = 0;
u16 startyear = 1950;
char ttdoptions[128+1024*WINTTDX];
int cfgfilespecified = 0;
int forcerebuildovl = 0;
int mcparam[2] = {0, 0};

extern char *patchedfilename;
extern langinfo *linfo;
#if WINTTDX
extern int acp;
#endif


#define DEFAULTCFGFILE "ttdpatch.cfg"

#if WINTTDX
#	define DEFAULTNEWGRFCFG "newgrfw.cfg"
#else
#	define DEFAULTNEWGRFCFG "newgrf.cfg"
#endif


#ifndef HAVE_SNPRINTF
#ifdef __BORLANDC__
#pragma argsused
#endif
static int snprintf(char *buf, size_t count, const char *format, ... ) {
  va_list args;
  int n;

  va_start(args, format);
  n = vsprintf(buf, format, args);
  va_end(args);
  return n;
}
#endif

const char snprintf_error[] =
#if DEBUG
			      "[snprintf() error]";
#else
			      "";
#endif

struct lineprintbuf {
	char *buf;
	size_t maxlen;
};



void givehelp(void)
{
  int i, total;

  printf("TTDPatch - ");
  printf(langtext[LANG_COMMANDLINEHELP], patchedfilename);

  // count halflines
  for (total=0; halflines[total]; total++);

  // show them in two-column format
  for (i=0; i<total/2; i++)
	printf("%-38s %c %-38s\n", halflines[i], langtext[LANG_SWTABLEVERCHAR][0], halflines[i + (total + 1)/2]);
  if (total % 2)
	printf("%-38s %c\n", halflines[(total + 1)/2 - 1], langtext[LANG_SWTABLEVERCHAR][0]);

  printf("%s%s%s",
	langtext[LANG_FULLSWITCHES],
	"Copyright (C) 1999-2002 by Josef Drexler.  ",
	langtext[LANG_HELPTRAILER]);
  exit(0);
}


void copyflagdata(void)
{
  // copy switch variables we handle specially to the flag data
  int i, p;

  flags->data.startyear = (u8)(startyear - 1920);

  for (p=0; p<2; p++) {
	flags->data.mctype[p] = 0;
	if (getf(usenewcurves+p))
	  for (i=0; i<4; i++) {
		flags->data.mctype[p] |= ((mcparam[p] >> ((3-i)*4)) & 3) << (i*2);
	  }
  }
}


#include "bitnames.h"

#if BITSWITCHNUM != BITSWITCHNUM_DEF
#error "BITSWITCHNUM is incorrect in language.h"
#endif

#define OBSOLETE ((void*)-1L)

int radix[4] = { 0, 8, 10, 16 };

#define YESNO(ch, txt, comment, sw) \
	{ ch, txt, comment, sw,  0, 0, {-1, -1, -1}, 0, NULL, -1 }

#define SPCL(ch, txt, comment, var) \
	{ ch, txt, comment, -1,  0, 2, {-1, -1, -1}, 0, var, -1 }

#define RANGE(ch, txt, comment, sw, radix, varsize, var, low, high, default) \
	{ ch, txt, comment, sw, radix, varsize, {low, high, default}, 0, var, -1 }

#define BITS(ch, txt, comment, sw, varsize, var, default) \
	{ ch, txt, comment, sw, 0, varsize, {0, 0x7fffffff, default}, 0, var, BITSWITCH_ ## sw }


#define noswitch -2
#define FLAGDATA(var) ( (void _fptr*) ( (s32) ( offsetof(paramset, data.var) - offsetof(paramset, data)) ) )
#include "sw_lists.h"
#undef noswitch

int overridesconfigfile = 0;

int readcfgfile(const char *filename);
int writecfgfile(const char *filename);


// Parameters for the on/off switches, case is ignored.  *MUST* be unique.
// Number of entries not limited.  End each list with a NULL entry.
// The first value is what is printed by the -W switch.
// e.g. "presignals yes" or "presignals off" etc.

const char *const switchonofftext[] =
	{ "on", "yes", "y", NULL,
	  "off", "no", "n", NULL };

const char *switchofftext = "off";

void _fptr *getswitchvarptr(int switchid)
{
  void _fptr *ptr = switches[switchid].var;

  if ( (u32) ptr < sizeof *flags )
	ptr = (void _fptr*) ( (char _fptr*) &(flags->data) + (s32) ptr);

  return (void _fptr*) ptr;
}

void setswitchvar(int switchid, s32 value)
{
  void _fptr *ptr = getswitchvarptr(switchid);

  if (switches[switchid].radix & 4)
	value = ~value;

  switch (switches[switchid].varsize) {
	case 0:
		*( (u8 _fptr *) ptr) = value;
		break;
	case 1:
		*( (u16 _fptr *) ptr) = value;
		break;
	case 2:
		*( (s16 _fptr *) ptr) = value;
		break;
	case 3:
		*( (s32 _fptr *) ptr) = value;
		break;
	case 4:
		*( (s8 _fptr *) ptr) = value;
		break;
  }
}

s32 getswitchvar(int switchid)
{
  s32 value, mask;
  void _fptr *ptr = getswitchvarptr(switchid);

  switch (switches[switchid].varsize) {
	case 0:
		value = *( (u8 _fptr *) ptr);
		mask = 0xff;
		break;
	case 1:
		value = *( (u16 _fptr *) ptr);
		mask = 0xffff;
		break;
	case 2:
		value = *( (s16 _fptr *) ptr);
		mask = 0xffff;
		break;
	default:				// case 3 really
		value = *( (s32 _fptr *) ptr);
		mask = 0xffffffff;
		break;
	case 4:
		value = *( (s8 _fptr *) ptr);
		mask = 0xff;
		break;
  }

  if (switches[switchid].radix & 4)
	value = (~value & mask);

  return value;
}

void setswitchbit(int switchid, const char *bitname, int swon)
{
  int i;
  const char **names;
  s32 var;

  names = bitnames[switches[switchid].bitswitchid];

  for (i=0; names[i]; i++) {
	if (!names[i]) continue;
	if (!stricmp(bitname, names[i])) {
		var = getswitchvar(switchid);
		var &= ~(((s32)1)<<i);
		var |= (((s32)swon)<<i);
		setswitchvar(switchid, var);
		return;
	}
  }

  warning(langtext[LANG_UNKNOWNSWITCHBIT], bitname, switches[switchid].cfgcmd);
}


void initvalues(int preferred)
{
  int i;

  // first set default values for all switches as if they were "on"

  for (i=0; switches[i].cmdline; i++) {
	if ( (switches[i].range[0] != -1) || (switches[i].range[1] != -1) )
		setswitchvar(i, switches[i].range[2]);
  }

  // if electrifiedrailway is on (which it is now), the default
  // value for unimaglevmode isn't valid
  flags->data.unimaglevmode = 1;

  if (!preferred) {	// now set default values for "off" switches,
			// i.e. as if the switch wasn't on
			// where it should be different from the "on" default
	flags->data.newvehcount[0] = 80;
	flags->data.newvehcount[1] = 80;
	flags->data.newvehcount[2] = 50;
	flags->data.newvehcount[3] = 40;
	mcparam[0] = 0;
	mcparam[1] = 0;
	flags->data.vehicledatafactor = 1;
	flags->data.newstationspread = 12;
	flags->data.newservint = 180;
	flags->data.planecrashctrl = 0;
	flags->data.multihdspeedup = 0;
	flags->data.signalwaittimes[0] = 41;
	flags->data.signalwaittimes[1] = 15;
	flags->data.unimaglevmode = 0;
	flags->data.newbridgespeedpc = 50;
	startyear = 1950;
	flags->data.redpopuptime = 4;
	flags->data.bigtownfreq = 0;
	flags->data.townsizelimit = 20;
	flags->data.treeplantmode = 0;
	flags->data.towngrowthratemode = 0;
	flags->data.townminpopulationsnow = 0;		// important!
	flags->data.townminpopulationdesert = 0;	// important!
	flags->data.moresteamsetting = 0x22;
	flags->data.windowsize = 640;
  }
}

void allswitches(int reallyall, int swon)
{
  int i;

  for (i=0; i<=lastbitcommandline; i++) {

	// only set bits from 0..lastbitdefaulton and
	// firstbitdefaultoff..lastbitdefaultoff if DEBUG or reallyall

	if (swon) {
	    if (i > lastbitdefaultoff)
		continue;
	    if ( (i > lastbitdefaulton) && (i < firstbitdefaultoff) )
		continue;
	    if ( (i >= firstbitdefaultoff) &&
	    	 (!reallyall
#if DEBUG
			 && 0	// for debug versions, -a turns on all switches
#endif
			      ) )
		continue;

	}
	setf(i, swon);
  }

  initvalues(swon);
  copyflagdata();

}


int setreallyspecial(int switchid, int swon, const char *cfgpar, int onlycheck)
{
  int parused = 0;

  switch (switches[switchid].cmdline) {
	case 'a':
		if (!onlycheck) allswitches(0, swon);
		break;
	case 'h':
	case '?':
		if (!onlycheck) givehelp();
		break;
	case 'C':
		if (!onlycheck)
			readcfgfile(cfgpar);
		else
			overridesconfigfile = 1;
		parused = 1;
		break;
	case 'W':
		if (!onlycheck)
			writecfgfile(cfgpar);
		parused = 1;
		break;
	case 155:	// CD Path
		if (!onlycheck) {
			if (cfgpar && (strlen(cfgpar) > 0))
				strcpy(ttdoptions, cfgpar);
			else
				strcpy(ttdoptions, "");
		}
		parused = 1;
		break;
	case maketwochars('X','n'):	// newgrf.cfg name
		if (!onlycheck) {
			free(othertext[0]);
			if (cfgpar && (strlen(cfgpar) > 0))
				othertext[0] = strdup(cfgpar);
			else
				othertext[0] = strdup(DEFAULTNEWGRFCFG);
		}
		parused = 1;
		break;

  }
  return parused;
}

int lastswitchorder = 0;
int numswitchorder = sizeof(switchorder)/sizeof(switchorder[0]);

int setswitch(int switchid, const char *cfgpar, const char *cfgsub, int swon, int onlycheck)
{
  int parused = 0;
  char *endptr;
  s32 parvalue;

  if (!onlycheck && !debug_flags.switchorder)
	switches[switchid].order = ++lastswitchorder;

  if (swon < 0) {	// not yet determined
	swon = 1;	// switch given, implies default "on"
	if (cfgpar &&
	    (switches[switchid].cmdline != 155) &&	// ignore CDPath
	    (switches[switchid].cmdline != 'W') &&	// and -W / writecfg
	    (switches[switchid].cmdline != maketwochars('X','n')) &&	// and -Xn / newgrfcfg
	    (switches[switchid].range[0] == -1) &&
	    (switches[switchid].range[1] == -1) ) {
		// check if a non-ranged switch has a value
		parvalue = strtol(cfgpar, &endptr, 0);
		if (*endptr == 0)
			swon = (parvalue != 0);	// if it's zero turn the switch off
		else {
			warning(langtext[LANG_UNKNOWNSTATE], cfgpar);
			swon = 0;
		}
	}
  }

  if (switches[switchid].bit == -1) {	// Special switches
	if (switches[switchid].var == NULL) {	// really special
		parused = setreallyspecial(switchid, swon, cfgpar, onlycheck);
	} else if (switches[switchid].var == OBSOLETE) {
		int ch;
			// obsolete
		ch = switches[switchid].cmdline;
		if ( ((ch & 0xff) < 32) || ((ch & 0xff) > 128) )
			ch = 0;

		if (!onlycheck) warning(langtext[LANG_SWITCHOBSOLETE],
			switches[switchid].cfgcmd, cmdswitchstr(ch, NULL));
	} else {	// with a variable to set
		if (!onlycheck)
			setswitchvar(switchid, swon);
	}
  } else if (!onlycheck) {	// not special
	if ( (switches[switchid].range[0] != -1) ||
	     (switches[switchid].range[1] != -1) ) {	// with a range (value)
		if (cfgpar == NULL || *cfgpar == 0)
			parvalue = switches[switchid].range[2];	//default
		else {
			if (*cfgpar == '#') { // We have bin format
			cfgpar++;
			parvalue = strtol(cfgpar, &endptr, 2);

			} else {
			parvalue = strtol(cfgpar, &endptr,
					radix[switches[switchid].radix & 3]);

			}
			if (*endptr == 0) {
				int offrange = -1;
				parused = 1;

				if ( (parvalue < switches[switchid].range[0]) )
					offrange = 0;
				else if ( (parvalue > switches[switchid].range[1]) )
					offrange = 1;

				if (offrange >= 0) switch (parvalue) {
					default:
						// bring the value into bounds
						parvalue = switches[switchid].range[offrange];
						break;
					case 1:
						// value is 1 and not in range, assume it means "on"
						parvalue = switches[switchid].range[2];
						break;
					case 0:
						swon = 0;	// value is 0 and not in range, turn off the switch
				}
			}
			else
				parvalue = switches[switchid].range[2];
		}

		if (switches[switchid].bitswitchid >= 0 && cfgsub && swon >= 0) {
			setswitchbit(switchid, cfgsub, swon);
			swon |= getf(switches[switchid].bit);
		} else
			setswitchvar(switchid, parvalue);
	}

	if (switches[switchid].bit >= 0)
		setf(switches[switchid].bit, swon);
  }
  return parused;
}

// command line is parsed twice, first to only check if there is a '-C' switch
// second pass is for real
int processswitch(int switchchar, const char *cfgswline, int swon, int onlycheck)
{

  int i, k, l, switchid = -1;
  const char *cfgcmd, *cfgpar;
  char *cfgsub;

  cfgsub = NULL;

  if ( (switchchar == 0) && (cfgswline != NULL) ) {	// cfg entry
	char *cfgline = (char *)cfgswline;		// modifiable (in a buffer)

	// syntax is "name *[:=]? *value", value may be omitted.

	i = strcspn(cfgline, " :=");
	if (cfgline[i])
		cfgline[i++] = 0;
	cfgcmd = cfgline;

	i += strspn(&(cfgline[i]), " :=");
	cfgpar = &(cfgline[i]);

	if (*cfgpar == 0)	// no parameter
		swon = 1;	// -> "yes" default
	else {
		swon = -1;	// not yet determined
		l = 1;		// first list is "on" list

				// cut off whitespace at the end
		k = strcspn(cfgline + i, " \t\r\n");
		if (k)
			cfgline[i+k] = 0;

		for (k=0; l >= 0; k++)
			if (switchonofftext[k]) {
				if (stricmp(cfgpar, switchonofftext[k]) == 0) {
					swon = l;
					break;
				}
			} else {
				if (l--) switchofftext = switchonofftext[k + 1];
			}
	}

	if (strchr(cfgcmd, '.') && ( (swon >= 0) || cfgpar) ) {
		cfgsub = (char*) strchr(cfgcmd, '.');
		cfgsub[0] = 0;
		cfgsub++;
	}
  } else {
	cfgpar = cfgswline;	// parameter
	cfgswline = NULL;
	cfgcmd = NULL;
  }

  for (i=0; switches[i].cmdline; i++) {
	if (cfgswline == NULL) {
		if (switches[i].cmdline == switchchar) {
			switchid = i;
			break;
		}
	} else {
		if (switches[i].cfgcmd)
			if (stricmp(cfgcmd, switches[i].cfgcmd) == 0) {
				switchid = i;
				break;
			}
	}
  }

  if (switchid == -1)
	return 0;

  return 1 + setswitch(switchid, cfgpar, cfgsub, swon, onlycheck);
}

int readcfgfile(const char *filename)
{
#define CFGLINEMAXLEN 256
  char cfgline[CFGLINEMAXLEN + 2], cfglineorg[CFGLINEMAXLEN + 2];
  int linetoolong, linepos;

  FILE *cfgfile;

  if (filename == NULL) filename = "";

  if (strlen(filename) < 1) {
	printf(langtext[LANG_CFGFILENOTFOUND], filename);
	return 0;
  }

  cfgfile = fopen(filename, "rt");
  if (!cfgfile) {
	if (strcmp(filename, DEFAULTCFGFILE))
		printf(langtext[LANG_CFGFILENOTFOUND], filename);
	return 0;
  }

  while (!feof(cfgfile)) {
	memset(cfgline, 0, CFGLINEMAXLEN + 1);
	fgets(cfgline, CFGLINEMAXLEN, cfgfile);

	linetoolong = (strchr(cfgline, '\n') == NULL) && (!feof(cfgfile));

	if (linetoolong)
		fscanf(cfgfile, "%*[^\n]");	// skip to end of line

	for (linepos = 0; isspace(cfgline[linepos]); linepos++);

	if (cfgline[linepos] == 0)
		continue;	// skip empty lines

	if (isalpha(cfgline[linepos])) {	// all lines starting with a-z are options
		if (linetoolong)
			warning(langtext[LANG_CFGLINETOOLONG]);

		{
		  char *eol = strchr(cfgline, '\n');
		  if (eol) *eol = 0;
		}
		strcpy(cfglineorg, cfgline);

		if (!processswitch(0, &(cfgline[linepos]), 0, 0))
			warning(langtext[LANG_UNKNOWNCFGLINE], cfglineorg);
	}
  }

  fclose(cfgfile);

  return 1;
}

int writereallyspecial(int switchid, const char **const formatstring, s32 *parvalue)
{
  switch (switches[switchid].cmdline) {
	case 155:	// CD Path
		if (strlen(ttdoptions) > 0)
			*parvalue = (s32) ttdoptions;
		else
			*parvalue = (s32) "";
		*formatstring = "%s %s";
		break;
	case maketwochars('X','n'):	// newgrf.cfg name
		*parvalue = (s32) othertext[0];
		*formatstring = "%s %s";
		if (!strcmp(othertext[0], DEFAULTNEWGRFCFG))
			return 0;
		break;
  }
  return 1;
}

void writebitswitch(int switchid, FILE *cfg)
{
	  int i, bitswid;
  const char *cfgcmd;
  const char **names;
  s32 val;

  bitswid = switches[switchid].bitswitchid;
  cfgcmd = switches[switchid].cfgcmd;
  names = bitnames[bitswid];
  val = getswitchvar(switchid);

  for (i=0; names[i]; i++) {
	if (!strcmp(names[i], "(reserved)")) continue;
	if (i) fputs("\n", cfg);
	fprintf(cfg, "%s.%s %s   // %s",
		cfgcmd, names[i],
		val & (((s32)1) << i) ? switchonofftext[0] : switchofftext,
		langstr(bitswitchdesc[bitswid][i]));
  }
}

void writerangedswitch(int switchid, const char **const formatstring, s32 *parvalue)
{
  if ((switches[switchid].bit >= 0) && !getf(switches[switchid].bit)) {
	*formatstring = "%s %s";
	*parvalue = (s32) switchofftext;
  } else {
	tempstr[0] = 0;
	*formatstring = tempstr;
	switch (switches[switchid].radix & 3) {
		case 1:
			strcat(tempstr, "%s %lo");
			break;
		case 3:
			strcat(tempstr, "%s %lx");
			break;
		default:
			strcat(tempstr, "%s %ld");
			break;
	}
	*parvalue = getswitchvar(switchid);
  }
}

void writeswitch(FILE *cfgfile, int switchid)
{
  s32 parvalue;
  const char *formatstring = "%s %ld";

  if (switches[switchid].bit == -1) {		// special
	if (switches[switchid].var == NULL) {		// really special
		if (!writereallyspecial(switchid, &formatstring, &parvalue))
			fputs("// ", cfgfile);
	} else if (switches[switchid].var == OBSOLETE) {	// obsolete
		return;
	} else {	// has a var
		parvalue = *( (int*) switches[switchid].var);
		if ( (parvalue >= 0) && (parvalue <= 1) ) {
			formatstring = "%s %s";
			if (parvalue)
				parvalue = (s32) switchonofftext[0];
			else
				parvalue = (s32) switchofftext;
		}
	}
  } else {	// not special
	if ( (switches[switchid].range[0] != -1) ||
	     (switches[switchid].range[1] != -1) ) {	// ranged (value)
		if (switches[switchid].bitswitchid >= 0 && getf(switches[switchid].bit)) {
			writebitswitch(switchid, cfgfile);
			return;
		} else
			writerangedswitch(switchid, &formatstring, &parvalue);
	} else {	// just on/off
		formatstring = "%s %s";
		#if DEBUG
		if (switches[switchid].bit < 0)
			error("** %s: on/off switch with no flag\n", switches[switchid].cfgcmd);
		#endif
		if (getf(switches[switchid].bit))
			parvalue = (s32) switchonofftext[0];
		else
			parvalue = (s32) switchofftext;
	}
  }

  fprintf(cfgfile, formatstring, switches[switchid].cfgcmd, parvalue);
}

char *dchartostr(int ch)
{
  static char dcharstr[6];

  if (firstchar(ch) < 128) {
  dcharstr[0] = firstchar(ch);
  dcharstr[1] = secondchar(ch);
  } else {
	snprintf(dcharstr, sizeof(dcharstr)-1, "\\%d", firstchar(ch));
  }

  return dcharstr;
}

char *cfg_nocmdline = NULL;

const char *cmdswitchstr(int ch, const char *defstr)
{
  static char dcharstr[4] = "-";

  dcharstr[1] = firstchar(ch);
  dcharstr[2] = secondchar(ch);

  if ( ((ch & 0xff) > 32) && ((ch & 0xff) < 128) )
	return dcharstr;
  else if (defstr)
	return defstr;
  else
	return cfg_nocmdline;
}

static void writeswitchcomment(FILE *cfgfile, int switchid)
{
  fprintf(cfgfile, langcfg(switches[switchid].comment),
		switches[switchid].cfgcmd,
		cmdswitchstr(switches[switchid].cmdline, NULL),
		switches[switchid].range[0],
		switches[switchid].range[1],
		switches[switchid].range[2]);
}

int writecfgfile(const char *filename)
{
  FILE *cfgfile;
  int switchid;
  int i, newsep;
  int *list;

  if (filename == NULL) filename = "";

  if (strlen(filename) < 1) {
	printf(langtext[LANG_CFGFILENOTFOUND], filename);
	return 0;
  }

  cfgfile = fopen(filename, "wt");
  if (!cfgfile) {
	printf(langtext[LANG_CFGFILENOTWRITABLE], filename);
	return 0;
  }

  cfg_nocmdline = strdup(langcfg(CFG_NOCMDLINE));

  fprintf(cfgfile, langcfg(CFG_INTRO), TTDPATCHVERSION);

  // build list of switches in the right order
  i = lastswitchorder;
  list = calloc(i + sizeof(switches)/sizeof(switches[0]) + 2, sizeof(int));
  if (list) {
	for (switchid=0; switches[switchid].cmdline; switchid++)
		if (switches[switchid].order)
			list[switches[switchid].order-1] = switchid+1;

	list[i++] = -1;		// end of old; beginning of new switches

	for (switchid=0; switches[switchid].cmdline; switchid++)
		if (!switches[switchid].order)
			list[i++] = switchid+1;

	list[i++] = -2;		// end of list
  }

  newsep = 0;
  for (i=0; ; i++) {
	if (list) {
		switchid = list[i]-1;

		if (switchid == -2)
			newsep = 1;
		else if (switchid == -3)
			break;

		if (switchid < 0)
			continue;
	} else {
		switchid = i;
		if (!switches[switchid].cmdline)
			break;
	}

	if (switches[switchid].comment) {
		if (newsep) {
			if (!debug_flags.switchorder)
				fprintf(cfgfile, "\n\n\n" CFG_COMMENT "%s\n",
					langcfg(CFG_NEWSWITCHINTRO));
			newsep = 0;
		}

		fprintf(cfgfile, "\n\n" CFG_COMMENT);
		// Note -- CFG_COMMENT uses ASCII, so no conversion is needed
		writeswitchcomment(cfgfile, switchid);
		fprintf(cfgfile, "\n");

		writeswitch(cfgfile, switchid);
	}
  }

  free(cfg_nocmdline);
  cfg_nocmdline = NULL;

  fprintf(cfgfile, "\n");
  fclose(cfgfile);

  if (list) free(list);

  return 1;
}

const char *defaultcmdline[] = { NULL, "-a", "-W", DEFAULTCFGFILE };

void commandline(int argc, const char *const *argv)
{
  int i, par, swon, p, parused;
  const char *s, *switchpar;
  int switchchar;
  int onlycheck;

  memset(&flags->data, 0, sizeof(flags->data));
  flags->datasize = (s32) ( offsetof(paramset, data.flags_byte_end) + sizeof(flags->data.flags_byte_end) - offsetof(paramset, data));
 // sizeof(flags->data);
  initvalues(0);

  for (i=0; i<nflagssw; i++)
	flags->flags[i] = 0;

  alwaysrun = 0;

  othertext[0] = strdup(DEFAULTNEWGRFCFG);

  for (onlycheck = 1; onlycheck >= 0; onlycheck--) {

	// "real" run, and there is no '-C' switch -> source default .cfg file
     if ( (!onlycheck) && (!overridesconfigfile) && (debug_flags.readcfg >= 0) )
	if (!readcfgfile(DEFAULTCFGFILE)) {
		// ttdpatch.cfg doesn't exist either; make a default
		// if we have *no* cmd.line options at all
		if (argc < 2 && !debug_flags.runcmdline) {
			argc = sizeof(defaultcmdline) / sizeof(defaultcmdline[0]);
			argv = defaultcmdline;
		}
	}

     for (par=1; par < argc; par++) {
	s = argv[par];

	if ( ((s[0] != '-') && (s[0] != '/')) || (debug_flags.runcmdline > 0) ) {
		if (!onlycheck) {	// handle non-option strings, but only in the "real" run
			size_t len = strlen(ttdoptions);
			if (len < sizeof(ttdoptions) - 2) {
				if (len > 0)
					strcat(ttdoptions, " ");
				strncat(ttdoptions, s, sizeof(ttdoptions) - len - 2);
			}
		}
		continue;
	}

	switchpar = argv[par + 1];	// NULL if par==argc-1
	parused = 0;

	if ((s[0] == '-') && (s[1] == '-')) {	// long switch
		char longswitch[CFGLINEMAXLEN+1];
		size_t longswitchlen = strlen(s + 2);

		if (strlen(s + 2) >= CFGLINEMAXLEN)
			error(langtext[LANG_UNKNOWNSWITCH], s[0], s + 1);

		strcpy(longswitch, s + 2);
		if (!longswitch[strcspn(longswitch, " :=")] && switchpar) {
			strcat(longswitch, "=");
			strncat(longswitch, switchpar, CFGLINEMAXLEN - longswitchlen - 1);
			parused = 1;
		}

		if (!processswitch(0, longswitch, 0, onlycheck))
			error(langtext[LANG_UNKNOWNSWITCH], s[0], s + 1);

	} else for (p=1; s[p]; p++) {
		switchchar = s[p];
		if ( (switchchar == 'X') || (switchchar == 'Y') ) {
			p++;
			if (!s[p])
				error(langtext[LANG_UNKNOWNSWITCH], s[0], dchartostr(switchchar));
			switchchar = maketwochars(switchchar, s[p]);
		}

		if (onlycheck && (switchchar != 'C') )
			continue;

		swon = 1;
		if (s[p + 1] == '-') {
			swon = 0;
			p++;
		}

		i = processswitch(switchchar, switchpar, swon, onlycheck);
		if (!i)
			error(langtext[LANG_UNKNOWNSWITCH], s[0], dchartostr(switchchar));

		if (i == 2)
			parused = 1;
	}

	if (parused)
		par++;
     }
  }

  if (debug_flags.useversioninfo > 0)
	setf1(recordversiondata);

  if (debug_flags.terminatettd)
	setf1(onlygetversiondata);

  if (debug_flags.noshowleds < 0)
	setf1(dontshowkbdleds);

  if (flags->data.vehicledatafactor <= 1)
	clearf(uselargerarray);

  // check dependencies between switches
  if (debug_flags.chkswitchdep >= 0) {
    if (!getf(uselargerarray)) {
	flags->data.vehicledatafactor = 1;
    }

    #if WINTTDX
	clearf(lowmemory);    
    #endif

    if (getf(gradualloading))
	setf1(improvedloadtimes);

    if (!getf(autorenew))
	clearf(forceautorenew);

    if (getf(electrifiedrail)) {
	setf1(unifiedmaglev);
	if (flags->data.unimaglevmode != 2)
		flags->data.unimaglevmode = 1;
    }

    if (getf(largertowns) && !getf(newtowngrowthfactor)) {
	setf1(newtowngrowthfactor);
	flags->data.townsizelimit = 80;
    }

    if (getf(recordversiondata)) {
	setf1(canmodifygraphics);
	setf1(enhancedkbdhandler);
    }

    if (!getf(newtowngrowthrate)) {
	flags->data.towngrowthratemode = 0;
    }

    if (getf(newstartyear) && (startyear < 1930)) {
	setf1(generalfixes);
    }

    if (!getf(moresteam)) {
	flags->data.moresteamsetting = 0x22;
    }

    if (getf(higherbridges) || getf(custombridgeheads)) {
	setf1(buildonslopes);
    }

    if (getf(newstations)) {
	setf1(enhancegui);
    }

    if (getf(resolutionwidth)) {
	setf1(resolutionheight);
    }
    else if (getf(resolutionheight)) {
	setf1(resolutionwidth);
    }
    else {
	// if none of the resolution patches are enabled, set the defaults,
	// so later code doesn't have to check the corresponding switches
	flags->data.reswidth=640;
	flags->data.resheight=480;
    }

    if (!getf(multihead)) {
	flags->data.multihdspeedup = 0;
    }

#if 0
    if (getf(newcargos) || getf(newindustries)) {
	clearf(moreindustriesperclimate);
    }
#endif

//    if (!getf(electrifiedrail)) {
//	clearf(enhancetunnels);
//    }
  }

  copyflagdata();

}


// Switches display

// switchorder[] array now in sw_lists.h


char switchnotshown(int bit) {
  switch (bit) {
	case setsignal1waittime:
	case setsignal2waittime:
  #if WINTTDX
	case lowmemory:
  #else
	case win2k:
	case disconnectontimeout:
	case stretchwindow:
  #endif
		return 1;
  }
  return 0;
}

int findswitch(int bit) {
  int i;

  for (i=0; i<sizeof(switches)/sizeof(switches[0]); i++) {
	if (!switches[i].cmdline)
		return -1;
	if (switches[i].bit == bit)
		return i;
  }
  return -1;
}

const char *getswitchline(int bit, int state, char *line, size_t maxlen, int *more)
{
  char *lineend = line;
  int i, switchid;
  s32 value = -1;		// initialized to make gcc happy
  const char *midtext = NULL;

  line[0] = 0;
  *more = 0;

  // find the switch in switches[]
  switchid = findswitch(bit);
  if (switchid < 0) {
  #if DEBUG
	snprintf(line, maxlen, "[Bit %d: no switch]", bit);
  #endif
	return line;
  }

  if ( (switches[switchid].range[0] != -1) || (switches[switchid].range[1] != -1) ) {
	value = getswitchvar(switchid);
	midtext = switchnames[bit*2+1];
	if ( (value && switches[switchid].bitswitchid >= 0) ||
	     (bit == setsignal1waittime) || (bit == setsignal2waittime) )
		*more = getf(bit);
  }

  i = snprintf(line, maxlen, " %c ",
			state?langtext[LANG_SWTABLEVERCHAR][1]
			     :langtext[LANG_SWTABLEVERCHAR][2]);
  // if (i < 0) return snprintf_error;
  if (i > maxlen) i = maxlen;
  lineend += i;
  maxlen -= i;

  i = snprintf(lineend, maxlen, switchnames[bit*2]);
  // if (i < 0) return snprintf_error;
  if (i > maxlen) i = maxlen;
  lineend += i;
  maxlen -= i;

  if (state && midtext)
	snprintf(lineend, maxlen, midtext, value);

  return line;
}

int addbitname(char *line, const char *bit, size_t maxlen) {
  size_t llen, blen;

  llen = strlen(line);
  blen = strlen(bit);

  if (llen + blen + 2 >= maxlen) {
	strcat(line, ",");
	return 0;
  }

  if (llen > 6)
	strcat(line, ", ");
  strcat(line, bit);

  return 1;
}

// return next set of bit names
const char *getswitchextra(int bit, int state, char *line, size_t maxlen, int bitline, int *more) {
  const char **names;
  s32 value;
  int i, thisline;
  int switchid = findswitch(bit);

  names = bitnames[switches[switchid].bitswitchid];
  value = getswitchvar(switchid);

  thisline = 1;
  strcpy(line, "   -> ");
  for (i=0; (thisline < bitline) && names[i]; i++) {
	if (value & (((s32)1) << i) && !addbitname(line, names[i], maxlen)) {
		thisline ++;
		strcpy(line, "      ");
		addbitname(line, names[i], maxlen);
	}
  }

  for (; names[i]; i++) {
	if (value & (((s32)1) << i) && !addbitname(line, names[i], maxlen)) {
		*more = 1;
		return line;
	}
  }
  *more = 0;
  return line;
}

// print train signal wait time message into a buffer
// return error message or NULL on success
const char *printwaittime(char **const lineend, size_t *const charsleft, int which) {
  int value = flags->data.signalwaittimes[which];
  int i = snprintf(*lineend, *charsleft, "  %s", langtext[which ? LANG_SWTWOWAY : LANG_SWONEWAY]);
  if (i < 0) return snprintf_error;
  if (i > *charsleft) i = *charsleft;
  *lineend += i;
  *charsleft -= i;

  i = snprintf(*lineend, *charsleft,
	(value == 255) ? langtext[LANG_INFINITETIME] : langtext[LANG_TIMEDAYS],
	value);
  if (i < 0) return snprintf_error;
  if (i > *charsleft) i = *charsleft;
  *lineend += i;
  *charsleft -= i;
  return NULL;
}


static enum {
	VERDISP_RESET,
	VERDISP_DEBUG,
	VERDISP_SWITCHES,
	VERDISP_WAITTIMES,
	VERDISP_DONE
} verbose_display_stage;
static int verbose_display_index;

// return next switch line to display, or NULL if nothing more
// the line to display is put in lineprintbuffer
const char *getnextverdispline(const struct lineprintbuf *const pb, int *subline) {
  trynextline:
  switch (verbose_display_stage) {
    case VERDISP_DEBUG:
      #if DEBUG
      {
	int i, k = verbose_display_index;
	int count = 0;

	if (k > lastbitcommandline) goto nextstage;
	verbose_display_index++;

	for (i=0; i<sizeof(switchorder)/sizeof(switchorder[0]); i++)
		if (switchorder[i] == k)
			count++;
	if (
	     !switchnotshown(k) &&
	     (count != 1) &&
	     ( (k <= lastbitdefaulton) || (k >= firstbitdefaultoff) ) &&
	     (k <= lastbitdefaultoff)
	   ) {
		snprintf(pb->buf, pb->maxlen,
			"[Bit %d is displayed %d times]", k, count);
		return pb->buf;
	}
	goto trynextline;
      }
      #endif
      // if DEBUG==0 then VERDISP_DEBUG falls through to nextstage
    case VERDISP_RESET:
	nextstage:
	verbose_display_stage++;
	verbose_display_index = 0;
	goto trynextline;
    case VERDISP_SWITCHES: {
	int line, more;
	const char *result;
	int i = verbose_display_index;
	if (i >= sizeof(switchorder)/sizeof(switchorder[0])) goto nextstage;
	i = switchorder[i];

	line = *subline;

	if (line == 0)
		result = getswitchline(i, getf(i), pb->buf, pb->maxlen, &more);
	else
		result = getswitchextra(i, getf(i), pb->buf, pb->maxlen, line, &more);

	if (more)
        	(*subline)++;
	else {
		verbose_display_index++;
		*subline=0;
	}
	return result;
    }
    case VERDISP_WAITTIMES:
	switch (verbose_display_index++) {
	    int more;
	    case 0: return getswitchline(setsignal1waittime,
					 getf(setsignal1waittime) || getf(setsignal2waittime),
					 pb->buf, pb->maxlen, &more);
	    case 1: {
		char f1 = getf(setsignal1waittime);
		char f2 = getf(setsignal2waittime);
		const char *errmsg;
		char *lineend;
		size_t charsleft = pb->maxlen;
		int i = snprintf(pb->buf, pb->maxlen, "   ");

		if (!f1 && !f2) goto trynextline;

		if (i < 0) return snprintf_error;
		if (i > charsleft) i = charsleft;
		charsleft -= i;
		lineend = pb->buf + i;
		if (f1)
			if ((errmsg = printwaittime(&lineend, &charsleft, 0)) != NULL) return errmsg;
		if (f2)
			if ((errmsg = printwaittime(&lineend, &charsleft, 1)) != NULL) return errmsg;

		return pb->buf;
	    }
	    default: goto nextstage;
	}
    default:
	return NULL;
  }
}

#define specialheadlines 2
#define specialtaillines 4
#define speciallines (specialheadlines+specialtaillines)

static struct lineprintbuf lineprintbuffer;

static void clradvline(int *y, const struct consoleinfo *const pcon) {
  if (*y >= 0) {
    pcon->clrconsole(*y, *y, pcon->width, pcon->attrib);
    pcon->setcursorxy(0, *y);
    (*y)++;
  }
}

static void showswitchtable(int fullredraw, int offset, const struct consoleinfo *const pcon) {
  int i, y = -1;
  int subline;

  // Head lines

  if (offset != -(int)0x8000) {
	if (fullredraw) pcon->clrconsole(0, pcon->height - 1, pcon->width, pcon->attrib);
	pcon->setcursorxy(0, 0);
	y = 2;
  }

  pcon->cprintf(langtext[LANG_SHOWSWITCHINTRO],
	langtext[LANG_SWTABLEVERCHAR][1], langtext[LANG_SWTABLEVERCHAR][2]);
  if (y >= 0) pcon->setcursorxy(0, 1);
  pcon->cprintf(" ");
  for (i = 0; i < pcon->width - 3; i++) pcon->cprintf("%c", langtext[LANG_SWTABLEVERCHAR][3]);
  pcon->cprintf(" \n");

  // Table

  verbose_display_stage = VERDISP_RESET;
  subline = 0;
  while (offset-- > 0 && getnextverdispline(&lineprintbuffer, &subline));	// skip the initial 'offset' items

  for (i = 0; i < pcon->height - speciallines; i++) {
	const char *line = getnextverdispline(&lineprintbuffer, &subline);
	if (y < 0 && !line) break;
	clradvline(&y, pcon);
	pcon->cprintf("%.*s\n", pcon->width - 1, line ? line : "");
  }

  // Tail lines

  if (y >= 0)
	pcon->setcursorxy(0, y);

  pcon->cprintf(" ");
  for (i = 0; i < pcon->width - 3; i++) pcon->cprintf("%c", langtext[LANG_SWTABLEVERCHAR][3]);
  if (y >= 0) {
	pcon->setcursorxy(3, y);
	pcon->cprintf(langtext[LANG_SCROLLKEYS]);
	pcon->setcursorxy(pcon->width - 5 - strlen(langtext[LANG_SCROLLABORTKEY]), y);
	pcon->cprintf(langtext[LANG_SCROLLABORTKEY]);
	pcon->setcursorxy(pcon->width - 3, y);
  }
  else pcon->cprintf(" \n %s", langtext[LANG_SCROLLABORTKEY]);
  pcon->cprintf(" \n ");

  pcon->cprintf(langtext[LANG_SWSHOWLOAD], ttdoptions);

  fflush(stdout);
}

void showtheswitches(const struct consoleinfo *const pcon)
{
  int nlines, subline, offset = 0;
  int key;
  char exitflag, redrawflag, fullredraw, noscroller = 0;

  #ifdef HAVE_SNPRINTF
    char lbuf[81];
    lineprintbuffer.buf = lbuf;
    lineprintbuffer.maxlen = 80;
  #else
    static char lbuf[161];		// for safety
    lineprintbuffer.buf = lbuf;
    lineprintbuffer.maxlen = 80;
  #endif

  printf(langtext[LANG_SWWAITFORKEY]);
  fflush(stdout);
  key = getch();
  if (key == 27) errornowait(langtext[LANG_SWABORTLOAD]);
  while (kbhit()) (void)getch();	// flush input buffer (necessary because some keys generate 2 characters)
  printf("\n");
  if (key == 13) return;
  printf("\n\n");

  // get number of scrollable lines
  verbose_display_stage = VERDISP_RESET;
  subline = 0;
  for (nlines = 0; getnextverdispline(&lineprintbuffer, &subline); nlines++);

  if ((nlines + speciallines) < pcon->height) {
	offset = -(int)0x8000;	// special mode, no scrolling necessary
	noscroller = 1;
  }

  exitflag = 0;
  redrawflag = 1;
  fullredraw = 1;
  do {
	if (redrawflag) {
		showswitchtable(fullredraw, offset, pcon);
		redrawflag = 0;
		fullredraw = 0;
	}

	// FIXME: better key handling
	key = getch();
	if (key == 0
	  #ifdef __GNUC__
	    || key == 224	// a quirk of msvcrt.dll
	  #endif
	  ) key = getch() << 8;

	switch (key) {
	    case 72 << 8:	// up
		if (noscroller) break;
		if (offset > 0)
			offset--, redrawflag = 1;
		break;
	    case 80 << 8:	// down
		if (noscroller) break;
		if (offset < nlines - (pcon->height - speciallines - 1))
			offset++, redrawflag = 1;
		break;
	    case 73 << 8: {	// page up
		int shift = pcon->height - speciallines - 1;
		if (noscroller) break;
		if (shift > offset) shift = offset;
		if (shift) offset -= shift, redrawflag = 1;
		break;
	    }
	    case 81 << 8: {	// page down
		int shift = pcon->height - speciallines - 1;
		int last = nlines - (pcon->height - speciallines - 1);
		if (noscroller) break;
		if (offset + shift > last) shift = (offset > last) ? 0 : last - offset;
		if (shift) offset += shift, redrawflag = 1;
		break;
	    }
	    case 71 << 8:	// home
		if (noscroller) break;
		offset = 0, redrawflag = 1;
		break;
	    case 79 << 8:	// end
		if (noscroller) break;
		offset = nlines - (pcon->height - speciallines - 1);
		redrawflag = 1;
		break;
	    case 27:		// Esc
		errornowait(langtext[LANG_SWABORTLOAD]);
	    case 13:		// Enter
	    case 32:		// Space
		exitflag = 1;
	}
  } while (!exitflag);

  printf("\n");
}

/*
Write switches in XML format

Format:
<switches version="TTDPatch 2.0.1 alpha 17" ID="020A00AA">
	<bool name="debtmax" desc="(from cfg") value="1" />
	<range name="multihead" min="0" max="100" default="35" value="35" />
	<bitswitch name="experimentalfeatures" desc="(from cfg file)">
		<bit num="0" name="slowcrossing" desc="slow before crossing">
	</bitswitch>
</switches>

*/

void putxmlstr(FILE *f, const char *str)
{
  int i;

  for (i=0; str[i]; i++) {
	switch (str[i]) {
		case '"': fputs("&quot;", f); break;
		case '<': fputs("&lt;", f); break;
		case '>': fputs("&gt;", f); break;
		case '&': fputs("&amp;", f); break;
		case 9:
		case 10:
		case 13: break;
		default: fputc(str[i], f); break;
	}
  }
}

void printbits(FILE *f, switchinfo* s)
{
  int i;
  const char **names;

  names = bitnames[s->bitswitchid];

  for (i=0; names[i]; i++) {
	if (!names[i]) continue;
	fprintf(f, "\t\t<bit num=\"%d\" name=\"%s\" desc=\"", i, names[i]);
	putxmlstr(f, langstr(bitswitchdesc[s->bitswitchid][i]));
	fputs("\"/>\n", f);
  }
}

int dumpxmlswitches(void)
{
  FILE *f;
  int i, isbitswitch;
#if WINTTDX
  int isonum, oldacp;
#endif

  f = fopen("switches.xml", "wt");
  if (!f)
	return 1;

#if WINTTDX
  oldacp = acp;
  if (strnicmp(linfo->winencoding, "ISO-8859-", 9) == 0)
	isonum = strtol(linfo->winencoding+9, NULL, 10);
  else
	isonum = 1;
  acp = 28590 + isonum;	// ACP for ISO-8859-x is 28590+x
  fprintf(f, "<?xml version=\"1.0\" encoding=\"ISO-8859-%d\"?>\n", isonum);
#else
  fprintf(f, "<?xml version=\"1.0\" encoding=\"%s\"?>\n", linfo->dosencoding);
#endif

  fprintf(f, "<switches version=\"%s\" ID=\"%08lX\">\n", TTDPATCHVERSION,
	((long)TTDPATCHVERSIONMAJOR<<24)+
	((long)TTDPATCHVERSIONMINOR<<20)+
	((long)TTDPATCHVERSIONREVISION<<16)+
	 (long)TTDPATCHVERSIONBUILD);

  for (i=0; switches[i].cmdline; i++) {
	if (!switches[i].comment) continue;

	isbitswitch = 0;

	if ( (switches[i].bit == -1) && (switches[i].var == NULL) )
		fprintf(f, "\t<special name=\"%s\"", switches[i].cfgcmd);
	else if ( (switches[i].range[0] != -1) ||
	     (switches[i].range[1] != -1) ) { 	// ranged (value)
	   if (switches[i].bitswitchid >= 0) {
		isbitswitch = 1;
		fprintf(f, "\t<bitswitch name=\"%s\" default=\"%ld\"",
			switches[i].cfgcmd, switches[i].range[2]);
	   } else if (switches[i].radix == 3)
		fprintf(f, "\t<range name=\"%s\" min=\"%lx\" max=\"%lx\" default=\"%lx\"",
			switches[i].cfgcmd,
			switches[i].range[0], switches[i].range[1], switches[i].range[2]);
	   else
		fprintf(f, "\t<range name=\"%s\" min=\"%ld\" max=\"%ld\" default=\"%ld\"",
			switches[i].cfgcmd,
			switches[i].range[0], switches[i].range[1], switches[i].range[2]);
	} else
		fprintf(f, "\t<bool name=\"%s\"", switches[i].cfgcmd);

	fprintf(f, " cmdline=\"%s\"", cmdswitchstr(switches[i].cmdline, ""));
	fprintf(f, " defstate=\"%s\"",
		(switches[i].bit >= 0) &&
		(switches[i].bit <= lastbitdefaulton) ? "on" : "off" );
	fputs(" desc=\"", f);
	putxmlstr(f, langcfg(switches[i].comment));
	if (isbitswitch) {
		fputs("\">\n", f);
		printbits(f, &switches[i]);
		fputs("\t</bitswitch>\n", f);
	} else
		fputs("\"/>\n", f);
  }
  fputs("</switches>\n", f);
  fclose(f);
#if WINTTDX
  acp = oldacp;
#endif
  return 0;
}

// Dump all switches to swtchlst.txt for parsing by configuration tools
// (in current language too)
int dumpswitches(int type)
{
  FILE *f;
  int i;

  if (type < 0) {
	return dumpxmlswitches();
  }

  f = fopen("swtchlst.txt", "wt");
  if (!f)
	return 1;

  fprintf(f, "%s\n", TTDPATCHVERSION);

  for (i=0; switches[i].cmdline; i++) {
	if (!switches[i].comment) continue;

	// Write "-[<cmdsw>] <cfgline> <rangemin rangemax|- -> <comment>"
	fprintf(f, "%s ", cmdswitchstr(switches[i].cmdline, "-"));
	fputs(switches[i].cfgcmd, f);
	if ( (switches[i].range[0] != -1) ||
	     (switches[i].range[1] != -1) ) 	// ranged (value)
		fprintf(f, " %ld %ld %ld ",
			switches[i].range[0], switches[i].range[1], switches[i].range[2]);
	else
		fputs(" - - - ", f);
	writeswitchcomment(f, i);
	fputs("\n", f);
  }
  fclose(f);
  return 0;
}


// Special debug switches.
// To access, have the first command line argument begin with a "-!";
// the rest of this argument is to have the form
// [<letter>[+|-]]...
// where + sets the feature to always on, - to always off; default is +
// example: ttdpatch -!v-s+ -v
// means ignore version info, always swap, verbose display (-v is processed as usual)
// another example: ttdpatch -!s-c c:/command.com /e:2048
// means run c:/command.com (with 2048 bytes for environment) instead of ttdload.ovl

static const struct debug_switch_struct {
	char c;
	signed char *flag;
} debug_switches[] = {
	{ 'v', &debug_flags.useversioninfo },	// v- ignore version info, v+ collect version info
	{ 's', &debug_flags.swap },		// s+ always swap, s- never swap (DOS only)
	{ 'c', &debug_flags.runcmdline },	// treat the rest of the command line as name+args of program to run
	{ 't', &debug_flags.checkttd },		// t- don't process TTDLOAD[W].OVL
	{ 'm', &debug_flags.checkmem },		// m- run even if memory is too low (DOS only)
	{ 'f', &debug_flags.readcfg },		// f- don't read or create the default ttdpatch.cfg
	{ 'a', &debug_flags.chkswitchdep },	// a- don't check dependencies between switches
	{ 'w', &debug_flags.warnwait },		// w- never wait for key, don't abort; w+ never wait for key, do abort
	{ 'o', &debug_flags.switchorder },	// o+ reorder switches when writing cfg file
	{ 'T', &debug_flags.terminatettd },	// T+ terminate TTD after finding new version info; T- terminate TTDPatch after processing cmd line and cfg
	{ 'L', &debug_flags.langdatafile },	// L+ load language data from language.dat file
	{ 'I', &debug_flags.noshowleds },	// I- don't update keyboard LED indicators (DOS only)
	{ 'S', &debug_flags.dumpswitches },	// S+ dump all switches to swtchlst.txt and abort, S- same but to switches.xml
	{ 'C', &debug_flags.protcodefile },	// C+ load protected mode code from ttdprot?.bin file
	{ 'R', &debug_flags.relocofsfile },	// R+ load reloc ofs from reloc.bin file
	{ 'P', &debug_flags.patchdllfile },	// P+ do not touch ttdpatch.dll
	{ 'n', &debug_flags.noregistry },	// n+ always use registry.ini, n- never use registry.ini
	{ 0, NULL }
};

void check_debug_switches(int *const argc, const char *const **const argv)
{
  if ((*argc >= 2) && (*argv)[1][0] == '-' && (*argv)[1][1] == '!') {
	const char *sw = (*argv)[1] + 2;
	(*argc)--;
	(*argv)++;

	while (*sw) {
		const struct debug_switch_struct *swdesc;
		for (swdesc = debug_switches; swdesc->c; swdesc++) if (swdesc->c == *sw) {
			signed char val = 1;
			switch (sw[1]) {
				case '-': val = -1;
					// FALLTHROUGH
				case '+': sw++;
			}
			*swdesc->flag = val;
			break;
		}
		sw++;
	}

	if (debug_flags.runcmdline > 0) {
		(*argc)--;
		(*argv)++;
	}
  }
}
