#!/usr/bin/perl -w
#
# Remove duplicate key record
#
# remove_duplicate_key.pl < infile > outfile
#

use strict;
use utf8;
use open ':utf8';
use open ':std';


# =============================================================
my %keyBodyHash;
# =============================================================


# =============================================================
# main
# =============================================================

my $cur_body_id	= '';

while ( my $record = <stdin> )
{
	chomp $record;
	if ( $record =~ /^$/ )
	{
		next;
	}
	
	my ( $key_text, $body_id, $flags, $title, $anchor, $yomi, $entry_title ) = split /\t/, $record;
	
	if ( ( not defined( $entry_title ) ) or ( not defined( $body_id ) ) )
	{
		printf STDERR "*** Unknown format. Skipped [%s]\n", $record;
		next;
	}
	
	if ( $body_id eq $cur_body_id )	# Another key for current entry.
	{
		# If this is a new one for the entry, 
		# remember the record, and output it.
		if ( not defined( $keyBodyHash{ $record } ) )
		{
			$keyBodyHash{ $record } = $record;
			printf "%s\n", $record;
		}
		else
		{
			printf STDERR "* Duplicate index. Skipped [%s]\n", $record;
		}
	}
	else	# Next entry.
	{
		# Clear hash, remember the record, and output it.
		$cur_body_id = $body_id;
		%keyBodyHash = ();
		$keyBodyHash{ $record } = $record;
		printf "%s\n", $record;
	}
}

exit 0;
