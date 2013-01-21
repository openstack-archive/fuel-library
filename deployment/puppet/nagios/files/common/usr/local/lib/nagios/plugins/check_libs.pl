#!/usr/bin/perl -Tw

# Copyright (C) 2005, 2006, 2007, 2008 Peter Palfrader <peter@palfrader.org>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

use strict;
use English;
use Getopt::Long;

$ENV{'PATH'} = '/bin:/sbin:/usr/bin:/usr/sbin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

my $LSOF = '/usr/bin/lsof';
my $VERSION = '0.0.0';

# nagios exit codes
my $OK = 0;
my $WARNING = 1;
my $CRITICAL = 2;
my $UNKNOWN = 3;

my $params;

Getopt::Long::config('bundling');

sub dief {
	print STDERR @_;
	exit $UNKNOWN;
}

if (!GetOptions (
	'--help'	=> \$params->{'help'},
	'--version'	=> \$params->{'version'},
	'--verbose'	=> \$params->{'verbose'},
	)) {
	dief ("$PROGRAM_NAME: Usage: $PROGRAM_NAME [--help|--version] [--verbose]\n");
};
if ($params->{'help'}) {
	print "$PROGRAM_NAME: Usage: $PROGRAM_NAME [--help|--version] [--verbose]\n";
	print "Reports processes that are linked against libraries that no longer exist.\n";
	exit (0);
};
if ($params->{'version'}) {
	print "nagios-check-libs $VERSION\n";
	print "nagios check for availability of debian (security) updates\n";
	print "Copyright (c) 2005 Peter Palfrader <peter\@palfrader.org>\n";
	exit (0);
};

my %processes;

sub getPIDs($$) {
	my ($user, $process) = @_;
	return join(', ', sort keys %{ $processes{$user}->{$process} });
};
sub getProcs($) {
	my ($user) = @_;

	return join(', ', map { $_.' ('.getPIDs($user, $_).')' } (sort {$a cmp $b} keys %{ $processes{$user} }));
};
sub getUsers() {
	return join('; ', (map { $_.': '.getProcs($_) } (sort {$a cmp $b} keys %processes)));
};
sub inVserver() {
	my ($f, $key);
	if (-e "/proc/self/vinfo" ) {
		$f = "/proc/self/vinfo";
		$key = "XID";
	} else {
		$f = "/proc/self/status";
		$key = "s_context";
	};
	open(F, "< $f") or return 0;
	while (<F>) {
		my ($k, $v) = split(/: */, $_, 2);
		if ($k eq $key) {
			close F;
			return ($v > 0);
		};
	};
	close F;
	return 0;
}

my $INVSERVER = inVserver();

print STDERR "Running $LSOF -n\n" if $params->{'verbose'};
open (LSOF, "$LSOF -n|") or dief ("Cannot run $LSOF -n: $!\n");
my @lsof=<LSOF>;
close LSOF;
if ($CHILD_ERROR) { # program failed
	dief("$LSOF -n returned with non-zero exit code: ".($CHILD_ERROR / 256)."\n");
};

for my $line (@lsof)  {
	if ($line =~ m/\.dpkg-/ || $line =~ m/path inode=/) {
		my ($process, $pid, $user, undef, undef, undef, undef, $path, $rest) = split /\s+/, $line;
		next if $path =~ m#^/proc/#;
		next if $path =~ m#^/var/tmp/#;
		next if ($INVSERVER && ($process eq 'init') && ($pid == 1) && ($user eq 'root'));
		#$processes{$user}->{$process} = [] unless defined $processes{$user}->{$process};
		$processes{$user}->{$process}->{$pid} = 1;
	};
};

my $message;
my $exit = $OK;
if (keys %processes) {
	$exit = $WARNING;
	$message = 'The following processes have libs linked that were upgraded: '. getUsers();
} else {
	$message = 'No upgraded libs linked in running processes';
};

print $message,"\n";
exit $exit;
