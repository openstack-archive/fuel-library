#!/usr/bin/perl -Tw

# $Id: nagios-check-apt-updates 352 2008-05-20 21:36:54Z weasel $

# nagios check for debian (security) updates,
# based on net-snmp glue to security updates via apt-get.
#  Copyright (C) 2004 SILVER SERVER Gmbh
#  Copyright (C) 2004, 2005, 2006, 2007, 2008 Peter Palfrader
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

use strict;
use English;
use Getopt::Long;
use IO::Handle;
use IPC::Open2;

$ENV{'PATH'} = '/bin:/sbin:/usr/bin:/usr/sbin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

my $APT = '/usr/bin/apt-get';
my $VERBOSE;

sub do_check($$$$$$) {
	my ($pre_command, $timeout, $noupdate, $name, $updates_security, $updates_other) = @_;
	my $fh;
	my $pid;
	my @command;

	unless ($noupdate) {
		print STDERR "Running $APT update in $name\n" if $VERBOSE;
		@command = ($APT, 'update');
		unshift @command, @$pre_command;
		$fh = new IO::Handle;
		$pid = open2($fh, \*STDIN, @command) or die ("Cannot run $APT update in $name: $!\n");
		local $SIG{ALRM} = sub { die "Timeout for apt-get update.\n" };
		alarm $timeout;
		my @ignore=<$fh>;
		alarm 0;
		close $fh;
		waitpid $pid, 0;
		if ($CHILD_ERROR) { # program failed
			die("$APT update returned with non-zero exit code in $name: ".($CHILD_ERROR / 256)."\n");
		};
	};

	print STDERR "Running $APT --simulate upgrade in $name\n" if $VERBOSE;
	@command = ($APT, qw{--simulate upgrade});
	unshift @command, @$pre_command;
	$fh = new IO::Handle;
	$pid = open2($fh, \*STDIN, @command) or die ("Cannot run $APT --simulate upgrade | sort -u in $name: $!\n");
	local $SIG{ALRM} = sub { die "Timeout for apt-get --simulate upgrade.\n" };
	alarm $timeout;
	my @lines=<$fh>;
	close $fh;
	alarm 0;
	waitpid $pid, 0;
	if ($CHILD_ERROR) { # program failed
		die("$APT --simulate upgrade | sort -u returned with non-zero exit code in $name: ".($CHILD_ERROR / 256)."\n");
	};

	@lines = sort {$a cmp $b} @lines;
	my %uniq;
	@lines = grep {!$uniq{$_}++} @lines;

	print STDERR "Processing information for $name\n" if $VERBOSE;
	for my $line (@lines)  {
		if ($line =~ m/^Inst\s+(\S+)\s+/) {
			my $package = $1;
			if ($line =~ m/^Inst\s+\S+\s+.*security/i) {
				push @$updates_security, $package.($name ne '/' ? "($name)" : '');
			} else {
				push @$updates_other, $package.($name ne '/' ? "($name)" : '');
			};
		}
	}
}

my $VERSION = '0.0.3 - $Rev: 352 $';
my $use_sudo = 1;
my $params;

# nagios exit codes
my $OK = 0;
my $WARNING = 1;
my $CRITICAL = 2;
my $UNKNOWN = 3;

$params->{'chroots'} = [];
$params->{'vservers'} = [];
$params->{'timeout'} = 20;
Getopt::Long::config('bundling');
if (!GetOptions (
	'--help'		=> \$params->{'help'},
	'--version'		=> \$params->{'version'},
	'--sudo'		=> \$params->{'sudo'},
	'--noupdate'		=> \$params->{'noupdate'},
	'--nosudo'		=> \$params->{'nosudo'},
	'--verbose'		=> \$params->{'verbose'},
	'--warnifupdates'	=> \$params->{'warnifupdates'},
	'--timeout=i'		=> \$params->{'timeout'},
	'--chroot=s'		=> $params->{'chroots'},
	'--vserver=s'		=> $params->{'vservers'}
	)) {
	die ("Usage: $PROGRAM_NAME [--help|--version] [--sudo|--nosudo] [--timeout=<timeout>] [--verbose]\n");
};
if ($params->{'help'}) {
	print "nagios-check-apt-updates $VERSION\n";
	print "Usage: $PROGRAM_NAME [--help|--version] [--sudo|--nosudo] [--verbose]\n";
	print "Reports packages to upgrade, updating the list if necessary.\n";
	print "\n";
	print "  --help              Print this short help.\n";
	print "  --version           Report version number.\n";
	print "  --sudo              Use sudo to call apt-get (default).\n";
	print "  --noupdate          Do not run apt-get update first.\n";
	print "  --nosudo            Do not use sudo to call apt-get.\n";
	print "  --warnifupdates     Exit with a WARNING status if any updates are available.\n";
	print "  --timeout=<timeout> Timeout in seconds for each of the two apt-get runs.\n";
	print "  --verbose           Be a little verbose.\n";
	print "  --chroot=<path>     Run check in path.\n";
	print "  --vserver=<vserver> Run check in vserver.\n";
	print "\n";
	print "Note that for --sudo (default) you will need entries in /etc/sudoers like these:\n";
	print "nagios  ALL=(ALL) NOPASSWD: /usr/bin/apt-get update\n";
	print "nagios  ALL=(ALL) NOPASSWD: /usr/bin/apt-get --simulate upgrade\n";
	print "nagios  ALL=(ALL) NOPASSWD: /usr/sbin/chroot /chroot-ia32 /usr/bin/apt-get update\n";
	print "nagios  ALL=(ALL) NOPASSWD: /usr/sbin/chroot /chroot-ia32 /usr/bin/apt-get --simulate upgrade\n";
	print "nagios  ALL=(ALL) NOPASSWD: /usr/sbin/vserver phpserver exec /usr/bin/apt-get update\n";
	print "nagios  ALL=(ALL) NOPASSWD: /usr/sbin/vserver phpserver exec /usr/bin/apt-get --simulate upgrade\n";
	print "\n";
	exit (0);
};
if ($params->{'version'}) {
	print "nagios-check-apt-updates $VERSION\n";
	print "nagios check for availability of debian (security) updates\n";
	print "Copyright (c) 2004 SILVER SERVER Gmbh\n";
	print "Copyright (c) 2004,2005 Peter Palfrader <peter\@palfrader.org>\n";
	exit (0);
};
if ($params->{'sudo'} && $params->{'nosudo'}) {
	die ("$PROGRAM_NAME: --sudo and --nosudo are mutually exclusive.\n");
};
if ($params->{'sudo'}) {
	$use_sudo = 1;
};
if ($params->{'nosudo'}) {
	$use_sudo = 0;
};
if (scalar @{$params->{'chroots'}} == 0 && scalar @{$params->{'vservers'}} == 0) {
	$params->{'chroots'} = ['/'];
};
$VERBOSE = $params->{'verbose'};


$SIG{'__DIE__'} = sub {
	print STDERR @_;
	exit $UNKNOWN;
};

my @updates_security;
my @updates_other;

# Make sure chroot paths are nice;
my @chroots = ();
for my $root (@{$params->{'chroots'}}) {
	if ($root =~ m#^(/[a-zA-Z0-9/.-]*)$#) {
		push @chroots, $1;
	} else {
		die ("Chroot path $root is not nice.\n");
	};
};
for my $root (@chroots) {
	my @pre_command = ();
	unshift @pre_command, 'chroot', $root if ($root ne '/');
	unshift @pre_command, 'sudo' if $use_sudo;
	do_check(\@pre_command, $params->{'timeout'}, $params->{'noupdate'}, $root, \@updates_security, \@updates_other);
}

# Make sure vserver names are nice;
my @vservers = ();
for my $vserver (@{$params->{'vservers'}}) {
	if ($vserver =~ m#^([a-zA-Z0-9.-]+)$#) {
		push @vservers, $1;
	} else {
		die ("Vserver name $vserver is not nice.\n");
	};
};
for my $vserver (@vservers) {
	my @pre_command = ();
	unshift @pre_command, '/usr/sbin/vserver', $vserver, 'exec';
	unshift @pre_command, 'sudo' if $use_sudo;
	do_check(\@pre_command, $params->{'timeout'}, $params->{'noupdate'}, $vserver, \@updates_security, \@updates_other);
}

my $exit = $OK;

my $updateinfo;
if (@updates_security) {
	$updateinfo .= 'Security updates ('.(scalar @updates_security).'): '.join(', ', @updates_security)."; ";
	$exit = $CRITICAL;
}
if (@updates_other) {
	$updateinfo .= 'Other Updates ('.(scalar @updates_other).'): '.join(', ', @updates_other)."; ";
	$exit = $WARNING if ($params->{'warnifupdates'} and $exit == $OK);
};
$updateinfo = 'No updates available' unless defined $updateinfo;

print $updateinfo,"\n";
exit $exit;
