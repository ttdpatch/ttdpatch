#!/usr/bin/perl -pl

# rename lots of identifiers to better names
# needs all structs to have local identifiers
# (i.e. run strucmemlocal first)

use strict;
use warnings;

our %members;
our %things;
BEGIN {
%members = (
	veh => {
		vehicletype	=> "class",		# TTD's 'abstraction class ID'
		subtype		=> "subclass",
		vehiclenum	=> "idx",		# use 'idx' for index into array, 'offst' for offset into array, 'num' for arbitrary numbers
		commandindex	=> "scheduleptr",
		nextstation	=> "currorder",		# holds both station/depot idx and order flags
		totalcommands	=> "totalorders",
		currentcommand	=> "currorderidx",
		targetcoord	=> "target",		# not necessarily coord (e.g. for class 15 vehicles)
		landscapeindex	=> "XY",		# shorter and clearer :-)
		subspeed	=> "speedfract",
		unitnumber	=> "consistnum",
		enginetype	=> "vehtype",		# This is what TTD calls "vehicle type", after all
		spritenum	=> "spritetype",	# Not a sprite *number* (as in TRG1.GRF), but actually an offset into several word arrays
		nextwaggon	=> "nextunitidx",
		traintitle	=> "name",		# the name of a vehicle (text ID), either generic (e.g. "Train 23") or custom
		vehmovementstat	=> "movementstat",	# shorter :-)
		traintype	=> "tracktype",
	},
	engine => {
		introduced	=> "introdate",		# to go with engineinfo.baseintrodate
		engineage	=> "age",
		reliab		=> "reliability",	# to go with vehicle.reliability
		enginelife	=> "lifespan",		# to go with engineinfo.lifespan
		inclimate	=> "flags",		# there's more in this field...
		enginetraintype	=> "tracktype",
	},
	stationcargo => {				# always used with station.cargos, the shorter the better
		amountwaiting	=> "amount",
	},
	station => {
		stationpos	=> "XY",
		stationcity	=> "townptr",
		busfacilitypos	=> "busXY",
		lorryfacilitypos => "lorryXY",
		railwayfacilitypos => "railXY",
		airportfacilitypos => "airportXY",
		dockfacilitypos	=> "dockXY",
		stationplatforms => "platforms",
		stationname	=> "name",
		cargo		=> "cargos",		# there's more than one cargo there, after all...
		stationowner	=> "owner",
		stationfacilities => "facilities",
	},
	city => {
		citylocation	=> "XY",
		citynametype	=> "name",
		citynameparts	=> "nameparts",
		maxpasstrans	=> "maxpasslast",	# these fields are for the last month, there are also fields for this month
		maxmailtrans	=> "maxmaillast",
		actpasstrans	=> "actpasslast",
		actmailtrans	=> "actmaillast",
	},
	depot => {
		depotloc	=> "XY",
		depotcity	=> "townptr",
	},
	industry => {
		industryloc	=> "XY",
		icity		=> "townptr",
		industrysize	=> "dimensions",	# these are XY dimensions
		producedtype	=> "producedcargos",	# for clarity
		iamountwaiting	=> "amountswaiting",
		prodrate	=> "prodrates",		# more than 1...
		iaccepts	=> "accepts",
	},
	player => {
		playername	=> "name",
		playermoney	=> "cash",
		yearlyexpenses	=> "thisyearexpenses",	# there are ones for the last 2 years too...
		playerlastquarterincome => "lastquarterincome",
	},
	subsidy => {
		subscargo	=> "cargo",
		subsage		=> "age",
		subsfrom	=> "from",
		substo		=> "to",
	},
);

%things = (
	vehicle		=> "veh",
	vehicle_size	=> "veh_size",
	engine		=> "vehtype",
	engine_size	=> "vehtype_size",
	engineinfo	=> "vehtypeinfo",
	engineinfo_size	=> "vehtypeinfo_size",
	city		=> "town",
	city_size	=> "town_size",
	index		=> "veharrayptr",		# 'ptr' or 'table' suffix for pointers to things, 'array' for direct addresses
	oldindex	=> "oldveharray",
	oldindex_abs	=> "oldveharray_abs",		# used explicitly in patches/loadsave.asm
	newindex	=> "newveharray",
	cityofs		=> "townarray",
	stationofs	=> "stationarray",
	depotofs	=> "depotarray",
	olddatasize	=> "oldveharraysize",
	enginestruct	=> "vehtypearray",
	traindataend	=> "veharrayendptr",
	scenariotype	=> "climate",
	totalengines	=> "totalvehtypes",
	playerdata	=> "playerarrayptr",
	stationdata	=> "stationarrayptr",
	signalerrormsg	=> "operrormsg",
	mainhandlerarray	=> "mainhandlertable",
	brakespeedarray		=> "brakespeedtable",
	normaltrainwindow	=> "normaltrainwindowptr",
	stationarray		=> "DONTUSE",		# this variable is redundant!
	enginedata		=> "vehtypedataptr",
	enginepowers		=> "enginepowerstable",
	isbigplane		=> "isbigplanetable",
	gametypeofs		=> "numplayersptr",
	scenedactiveofs		=> "scenedactiveptr",
	curtooltracktype	=> "curtooltracktypeptr",
);
}

# Main loop
	
# cut off everything after a comment or C preprocessor directive
my $comment = s~(\s*(#|;|//).*)$~~ ? $1 : '';

# process full identifiers
# strings and NASM preprocessor directives are also matched to prevent them
# from being mangled accidentally
s/
	(?<![\w.@\$\#~?%"'])		# neg.lookbehind (is faster)
	(	\%?[\w.@\$\#~?]+|
		"[^"]*"|
		'[^']*'
	)
/$things{$1} || $1/xge;
	
if (/^\s*struc\s+(\w+)/ && (our $instruc = $1) .. /^\s*endstruc/) {
	# replace member names in the struct definition
	s/\.(\w+)/".".($members{$instruc}{$1} || $1)/e;
} else {
	# and in the member accesses
	s/\b(\w+)\.(\w+)\b/
		my $struc = $things{$1} || $1;
		my $member = $members{$struc}{$2} || $2;
		"$struc.$member"
	/ge;
}
	
# append the comment (etc.) again
$_ .= $comment;

print STDERR "$0: $ARGV done" if eof;
