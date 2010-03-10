#!/usr/bin/perl -w
#
# make_line.pl
#
# this script does and should do just the following:
#	1) top level elements under <dictionary> have line feed after them.
#	2) remove spaces before/after those elements.
#

use strict;
use utf8;
use open ':utf8';
use open ':std';

my $ns = "d:";

makeLines();
exit 0;

# =============================================================
#
# =============================================================
sub makeLines
{
	my $lastPos;
	
	# Skip other elements than <entry>.
	$/ = '>';
	while (<>) {
		next if /^\n$/;
		last if /<${ns}entry/;
		$lastPos = tell;
		s/^[[:blank:]\n]*//;
		s/[[:blank:]\n]*$//;
		print $_,"\n";
		# printf "[%s]\n", $_;
	}
	seek ARGV, $lastPos, 0;
	die unless /<${ns}entry/;
	print "\n";
	
	# Process all entries.
	# my $entry = "entry";
	$/ = "</${ns}entry>";
	while(<>) {
		next if /^\n$/;
		# last unless s/^[[:blank:]\n]*<${ns}entry/<${ns}entry/;
		last unless s/.*?<${ns}entry/<${ns}entry/s;
		die unless s|</${ns}entry>$|</${ns}entry>|;
		$lastPos = tell;
		print $_,"\n";				# an entry
		#print $_,"\n\n";
		# printf "[%s]\n", $_;
	}
	seek ARGV, $lastPos, 0;
	
	# Skip other elements than <entry>.
	$/ = '>';
	while (<>) {
		s/^[[:blank:]\n]*//;
		s/[[:blank:]\n]*$//;
		print $_,"\n";
		# printf "[%s]\n", $_;
	}
}
