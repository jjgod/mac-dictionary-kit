#!/usr/bin/perl -w
#
# Output entry_id lines that are referred in the dictionary.
#
# pick_used_reference_id.pl < entry_body_list.txt > reduced_entry_body_list.txt
#

use strict;
use utf8;
use open ':utf8';
use open ':std';


# =============================================================
my %referred_id_hash;
# =============================================================


# =============================================================
# main
# =============================================================

if ( $#ARGV != 0 )
{
	print STDERR "Usage: pick_used_reference_id.pl referred_id_list < entry_body_list > referred_entry_body_list\n";
	exit 2;
}
my $matching_table_file_path = $ARGV[0];
readUsedIdList( $matching_table_file_path );
pickUsedId();
exit 0;


# =============================================================
# pickUsedId
# =============================================================
sub pickUsedId
{
	while ( my $record = <stdin> )
	{
		chomp $record;
		if ( $record =~ /^$/ )
		{
			next;
		}
		
		my ( $entry_id, $body_id ) = split /\t/, $record;
		if ( not defined $body_id )
		{
			printf STDERR "*** Unknown format. Skipped [%s]\n", $record;
			next;
		}
	
		my $used = $referred_id_hash{ $entry_id };
		if ( defined $used && $used > 0 )
		{
			printf "%s\n", $record;
		}
	}
}


# =============================================================
# readUsedIdList
# =============================================================
sub readUsedIdList
{
	my ( $file_path ) = @_;
	open( REFERRED_ID_LIST, $file_path )
		or die "*** Not found: $file_path";

	
	while( <REFERRED_ID_LIST> ) {
		chomp;
		my ( $entry_id ) = $_;
		if ( defined $entry_id )
		{
			$referred_id_hash{ $entry_id } = 1;
		}
	}
	
	close REFERRED_ID_LIST;
}
