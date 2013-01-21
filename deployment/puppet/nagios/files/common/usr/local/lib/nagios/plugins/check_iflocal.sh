#!/bin/bash
#
# check_iflocal v 1.0
# Written by Alan McKay at Nortel 
# alan.mckay@nortel.com, alan.mckay@gmail.com
# http://www.nortel.com/
# Donated back to the Nagios project with permission of Nortel
#
# check_iflocal is a Nagios plugin to report on the health of a 
# Linux ethernet interface
# Copyright (C) 2008 Nortel
# check_iflocal is free software; you can redistribute it 
# and/or modify it under the terms of the GNU General Public 
# License as published by the Free Software Foundation, either 
# version 2 of the License, or (at your option) any later version.
#
# check_iflocal is distributed WITHOUT ANY WARRANTY; without even 
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
# PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This script checks the 4 values found in the output of ifconfig
# RX Errors, TX Errors, RX dropped, TX dropped
# It assumes that if the interface is functioning properly, 
# these values will be 0.  Rather than flag absolute values
# the script flags delta values from one invocation to the next
#
# for this to run you need to :
# mkdir -p /var/run/nagios
# chown -R nagios:nagios /var/run/nagios
# or whatever values you have for
# RUNDIR and NAGUSER and NAGGROUP

# change these to whatever delta you want
# to flag from one invocation to the next
WARNDELTA=1
CRITDELTA=10

# The script also gives the option of running either ethtool or mii-tool
# to get additional information on the link status, and flag a warning
# if there is no link on the interface

# These 4 are standard return codes for Nagios 
# DO NOT CHANGE!
# They have to be here at top since other variables
# that you can change rely on them.
STATOK=0
STATWARN=1
STATCRIT=2
STATYIKES=3

# Text which cooresponds to the values above
# Changing probably won't break anything
STROK="OK"
STRWARN="WARNING"
STRCRIT="CRITICAL"
STRYIKES="UNKNOWN"

# change this according to your environment
RUNDIR=/var/run/nagios
NAGUSER=nagios
NAGGROUP=nagios

# these should be good for most Linux distros
# but set them to whatever makes sense for you
# this script does however rely on the Linux
# output of ifconfig.  Alternate outputs may
# require change to the script
# Contact me and if I have access to a box
# running your OS I'll try my best to accomodate
IFCONFIG=/sbin/ifconfig
TOUCH=/bin/touch
GREP=/bin/grep
AWK=/usr/bin/awk
CAT=/bin/cat
RM=/bin/rm
MV=/bin/mv
CHOWN=/bin/chown
CHMOD=/bin/chmod
SUDO=/usr/bin/sudo
ETHTOOL=/sbin/ethtool
MIITOOL=/sbin/mii-tool

# do we want to do the ethtool or mii-tool check for link?
# ONLY 1 OF THESE 2 CAN BE ENABLED! OTHERWISE ERROR
# if so, then you have to put an entry in the sudoers 
# file for nagios and ethtool.  The below is for recent
# versions of sudo.
# e.g.
# nagios  hostname = NOPASSWD: /sbin/ethtool
# you will also have to make sure that requiretty is
# not enabled in the sudoers file
# e.g.
# # Defaults    requiretty
# only enable one of these two or the script will fail
RUNETHTOOL=1
RUNMIITOOL=0

# How do you want "no link" to be reported?
# NOLINK=$STATOK	# OK
# NOLINK=$STATWARN	# Warning
NOLINK=$STATCRIT	# Critical

# if your ifconfig output is different, these may have to change
# DO NOT CHANGE OTHERWISE!!!
ETHTOOLGREP="Link detected:"
RXSTR="RX packets:"
TXSTR="TX packets:"

################################################################
# you probably do not need / want to change anything below here
################################################################

# do not change these
ETHTOOLOK="yes"
ETHTOOLNOTOK="no"

show_usage()
{
	echo	"Usage : `basename $0` ethX [VAR=VAL] [VAR=VAL] [...]"
	echo	""
	echo	"This script checks the 4 values found in the output of ifconfig "
	echo	"RX Errors, TX Errors, RX dropped, TX dropped"
	echo	"It assumes that if the interface is functioning properly,"
	echo	"these values will be 0.  Rather than flag absolute values"
	echo	"the script flags delta values from one invocation to the next"
	echo	"It is also smart enough to reset itself e.g. on reboot"
	echo	""
	echo	"Please read comments at top of script for installation details"
	echo	""
	echo	"Variable names can be mixed-cased.  Valid variables : "
	echo	"	WARNDELTA=number (default 1)"
	echo	"	CRITDELTA=number (default 10)"
	echo	"		How big of a delta to flag as warning or critical?"
	echo	"		Applies to all of RX Errors, TX Errors, RX Dropped, TX Dropped"
	echo	"		So if any one of those 4 exceeds the delta from one invocation"
	echo	"		to the next, the appropriate action is taken"
	echo 	"	NOLINK=[0|1|2|3] (default 1)"
	echo	"		How to report when there is no link on this interface?"
	echo	"		Nagios return codes - 0=OK,1=WARNING,2=CRITICAL,3=SCRIPT ERROR"
	echo 	"		but note that you use the numbers, not the strings"
	echo	"		This is only used if either ethtool or mii-tool is enabled"
	echo	"	RUNETHTOOL=[0|1]"
	echo	"	RUNMIITOOL=[0|1]"
	echo	"		Only 1 of the above 2 can be enabled otherwise it's an error"
	echo	"		These give more info on each interface, but require sudo"
	echo	"		See script comments for details"
	echo	"	STROK=STRING (see script comments)"
	echo	"	STRWARN=STRING (see script comments)"
	echo	"	STRCRIT=STRING (see script comments)"
	echo	"	STRYIKES=STRING (see script comments)"
	echo	""
}

# rudimentary check for proper usage
if [ $# -lt 1 ]
then
	show_usage
	exit $STATYIKES
fi
IFACE=$1
shift

if [ "$IFACE" == "-h" -o "$IFACE" == "--help" ]
then
	show_usage
	exit $STATOK
fi

# process command line

while [ $# -gt 0 ]
do
	case $1 in
		*=*)
			MYVAR=`echo $1 | $AWK -F= '{print $1}'`
			MYVAL=`echo $1 | $AWK -F= '{print $2}'`
			case $MYVAR in
				[Ww][Aa][Rr][Nn][Dd][Ee][Ll][Tt][Aa])
					WARNDELTA=$MYVAL
					;;
				[Cc][Rr][Ii][Tt][Dd][Ee][Ll][Tt][Aa])
					CRITDELTA=$MYVAL
					;;
				[Nn][Oo][Ll][Ii][Nn][Kk])
					NOLINK=$MYVAL
					;;
				[Rr][Uu][Nn][Ee][Tt][Hh][Tt][Oo][Oo][Ll])
					RUNETHTOOL=$MYVAL
					;;
				[Rr][Uu][Nn][Mm][Ii][Ii][Tt][Oo][Oo][Ll])
					RUNMIITOOL=$MYVAL
					;;
				[Ss][Tt][Rr][Oo][Kk])
					STROK=$MYVAL
					;;
				[Ss][Tt][Rr][Ww][Aa][Rr][Nn])
					STRWARN=$MYVAL
					;;
				[Ss][Tt][Rr][Cc][Rr][Ii][Tt])
					STRCRIT=$MYVAL
					;;
				[Ss][Tt][Rr][Yy][Ii][Kk][Ee][Ss])
					STRYIKES=$MYVAL
					;;
			esac
			;;
		*)
			echo "Invalid command argument $1"
			exit $STATYIKES
			;;
	esac
	shift
done

if [ $RUNETHTOOL -eq 1 -a $RUNMIITOOL -eq 1 ]
then
	echo	"$STRYIKES : must disable either ethtool or mii-tool"
	exit $STATYIKES
fi

RXERR=0
TXERR=0

gt()
# simply returns the greater of the two values handed in
{
	local	V1=$1
	local	V2=$2

	if [ $V1 -gt $V2 ]
	then 
		return	$V1
	else
		return	$V2
	fi
}

check_vals()
# compares the new and old values
# if there is a delta, compares it against VWARN and VCRIT
# Note we pass the old return code in and back out again
# this is important due to the way it is called
{
	if [ $# -ne 6 ]
	then
		echo "Usage : $0 VARNAME newval oldval warndelta critdelta RCODE"
		return
	fi
	local	VNAME=$1
	local	VNEW=$2
	local	VOLD=$3
	local	VWARN=$4
	local	VCRIT=$5
	local	RCODE=$6
	local	RETSTR=
	
	if [ $VNEW -lt $VOLD ]
	then
		# errors have decreased - probably upon reboot
		# so reset ourselves by removing the $RUNFILE
		RETSTR="$VNAME ${VOLD}->${VNEW}"
		$RM -f $RUNFILE
	elif [ $VNEW -gt $VOLD ]
	then
		# have increased 

		RETSTR="$VNAME ${VOLD}->${VNEW}"
		((VDELTA=VNEW-VOLD))

		if [ $VDELTA -lt $VWARN ]
		then
			# below the warning threshold 
			# so just hand back the same return
			# code that was handed into us
			RCODE=$RCODE

		elif [ $VDELTA -lt $VCRIT ]
		then
			# above warning threshold but below
			# critical threshold, so return warning
			# return the greater of $STATWARN or 
			# whatever RCODE was handed in to us
			gt $STATWARN $RCODE
			RCODE=$?

		else
			# above critical threshold
			RCODE=$STATCRIT
		fi
	else
		# no change
		RETSTR="$VNAME $VOLD"
	fi

	echo $RETSTR
	return $RCODE
}

# see if we have permissions on the run directory

$TOUCH $RUNDIR/tmpfile
if [ $? -ne 0 ]
then
	echo	"FAILED : no permissions on $RUNDIR"
	exit	$STATYIKES
fi
$RM -f $RUNDIR/tmpfile

# determine if we've ever been run before

RUNFILE=$RUNDIR/`basename $0`.$IFACE
TFILE=$RUNFILE.tmp
FIRSTRUN=0
if [ ! -f $RUNFILE ]
then
	FIRSTRUN=1
fi

# get all the current info from the interface

$IFCONFIG $IFACE	> $TFILE	2>&1
RCODE=$?
if [ $RCODE -ne 0 ]
then
	echo	"FAILED : invalid interface $IFACE"
	exit	$STATYIKES
fi

RXLINE=`$GREP "$RXSTR" $TFILE`
TXLINE=`$GREP "$TXSTR" $TFILE`
RXERR=`echo $RXLINE | $AWK '{print $3}' | $AWK -F: '{print $2}'`
TXERR=`echo $TXLINE | $AWK '{print $3}' | $AWK -F: '{print $2}'`
RXDROP=`echo $RXLINE | $AWK '{print $4}' | $AWK -F: '{print $2}'`
TXDROP=`echo $TXLINE | $AWK '{print $4}' | $AWK -F: '{print $2}'`

# get the info from the last run

if [ $FIRSTRUN -eq 1 ]
then
	RXERROLD=$RXERR
	TXERROLD=$TXERR
	RXDROPOLD=$RXDROP
	TXDROPOLD=$TXDROP
else
	RXLINEOLD=`$GREP "$RXSTR" $RUNFILE`
	TXLINEOLD=`$GREP "$TXSTR" $RUNFILE`

	RXERROLD=`echo $RXLINEOLD | $AWK '{print $3}' | $AWK -F: '{print $2}'`
	TXERROLD=`echo $TXLINEOLD | $AWK '{print $3}' | $AWK -F: '{print $2}'`
	RXDROPOLD=`echo $RXLINEOLD | $AWK '{print $4}' | $AWK -F: '{print $2}'`
	TXDROPOLD=`echo $TXLINEOLD | $AWK '{print $4}' | $AWK -F: '{print $2}'`
fi

# put current data into place as "last time" for next time around
$MV -f $TFILE $RUNFILE
if [ $? -ne 0 ]
then
	RCODE=$STATYIKES
	echo "YIKES : unable to \"$MV -f $TFILE $RUNFILE\""
	exit $RCODE
fi
$CHOWN ${NAGUSER}:${NAGGROUP} $RUNFILE
$CHMOD 0660 $RUNFILE

# now check our 4 current data points against their previous values

RCODE=$STATOK
RXERRSTR=`check_vals "RX err" $RXERR $RXERROLD $WARNDELTA $CRITDELTA $RCODE`
RCODE=$?
TXERRSTR=`check_vals "TX err" $TXERR $TXERROLD $WARNDELTA $CRITDELTA $RCODE`
RCODE=$?
RXDROPSTR=`check_vals "RX drop" $RXDROP $RXDROPOLD $WARNDELTA $CRITDELTA $RCODE`
RCODE=$?
TXDROPSTR=`check_vals "TX drop" $TXDROP $TXDROPOLD $WARNDELTA $CRITDELTA $RCODE`
RCODE=$?

RSTR="$RXERRSTR, $TXERRSTR, $RXDROPSTR, $TXDROPSTR"

if [ $RUNETHTOOL -eq 1 ]
then
	# ethtool can only detect link status for the physical interface
	# so for any interface named ethX.nnn (VLANed virtual interface)
	# we convert it to the physical interface name first
	PHYSIF=`echo $IFACE | $AWK -F. '{print $1}'`
	ETFILE=$RUNDIR/`basename $ETHTOOL`.$PHSIF
	$SUDO $ETHTOOL $PHYSIF	> $ETFILE	2>&1
	if [ $? -eq 0 ]
	then
		IFACESTATUS=`$GREP "${ETHTOOLGREP}" $ETFILE | $AWK '{print $3}'`
		case $IFACESTATUS in
			${ETHTOOLOK})
				RCODE=$RCODE
				;;
			${ETHTOOLNOTOK})
				gt $RCODE $NOLINK
				RCODE=$?
				;;
			*)
				RCODE=$STATYIKES
				;;
		esac

		RSTR="${RSTR}, Link: $IFACESTATUS"

		if [ "$IFACESTATUS" == "yes" ]
		then
			SPEED=`$GREP Speed: $ETFILE | $AWK '{print $2}' | $AWK -F/ '{print $1}'`
			DUPLEX=`$GREP Duplex: $ETFILE | $AWK '{print $2}'`
			AUTONEG=`$GREP Auto-negotiation: $ETFILE | $AWK '{print $2}'`
			RSTR="${RSTR} - $SPEED $DUPLEX, Autoneg $AUTONEG" 
		fi
	else
		RSTR="${RSTR} - `$CAT $ETFILE`"
		RCODE=$STATYIKES
	fi

fi

if [ $RUNMIITOOL -eq 1 ]
then
	# mii-tool is a bit smarter than ethtool and will work on virtual interfaces
	MIIFILE=$RUNDIR/`basename $MIITOOL`.$IFACE
	$SUDO $MIITOOL $IFACE	> $MIIFILE	2>&1
	if [ $? -eq 0 ]
	then
		$GREP -q "link ok" $MIIFILE
		if [ $? -eq 0 ]
		then
			RCODE=$RCODE
		else
			gt $RCODE $NOLINK
			RCODE=$?
		fi

		IFACESTATUS=`$CAT $MIIFILE | $AWK -F: '{print $2}'`
		RSTR="${RSTR}, $IFACESTATUS"
	else
		RSTR="${RSTR} - `$CAT $MIIFILE`"
		RCODE=$STATYIKES
	fi
	
fi

case $RCODE in
	$STATOK)
		CSTR=$STROK
		;;
	$STATWARN)
		CSTR=$STRWARN
		;;
	$STATCRIT)
		CSTR=$STRCRIT
		;;
	*)
		CSTR=$STRYIKES
		;;
esac

echo "$CSTR : $RSTR"
exit $RCODE
