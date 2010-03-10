#!/usr/bin/perl -w
#
#
# replace_entryid_bodyid.pl
#

use strict;
use utf8;
use open ':utf8';
use open ':std';


# =============================================================
my %entryToBodyHash;
# =============================================================



# =============================================================
# main
# =============================================================

if ( $#ARGV != 0 )
{
	print STDERR "Usage: replaceEntryIdByBodyId.pl entry_body_list < key_entry_list > key_body_list\n";
	print STDERR "    Input data format\n";
	print STDERR "        entry_body_list: entry_id<tab>body_id\n";
	print STDERR "        key_entry_list : key_text<tab>entry_id<tab>flags<tab>title<tab>anchor<tab>yomi<tab>entry_title\n";
	print STDERR "    Output data format\n";
	print STDERR "        key_body_list  : key_text<tab>body_id<tab>flags<tab>title<tab>anchor<tab>yomi<tab>entry_title\n";
	exit 2;
}
my $matching_table_file_path = $ARGV[0];
readMatchingTable( $matching_table_file_path );
replaceEntryIdByBodyId();
exit 0;


# =============================================================
# replaceEntryIdByBodyId
# =============================================================
sub replaceEntryIdByBodyId
{
	while ( my $record = <stdin> )
	{
		chomp $record;
		if ( $record =~ /^$/ )
		{
			next;
		}
		
		my ( $key_text, $entry_id, $flags, $title, $anchor, $yomi, $entry_title ) = split /\t/, $record;
		if ( not defined $entry_title )
		{
			printf STDERR "*** Unknown format. Skipped [%s]\n", $record;
			next;
		}
		
		my $body_id = $entryToBodyHash{ $entry_id };
		if ( not defined $body_id )
		{
			printf STDERR "*** No corresponding body_id. Skipped [%s]\n", $record;
			next;
		}
		
		printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
			$key_text, $body_id, $flags, $title, $anchor, $yomi, $entry_title;
	}
}


# =============================================================
# readMatchingTable
# =============================================================
sub readMatchingTable
{
	my ( $file_path ) = @_;
	open( ENTRY_TO_BODY, $file_path )
		or die "*** Not found: $file_path";
	
	while( <ENTRY_TO_BODY> ) {
		chomp;
		my ( $entry_id, $body_id ) = split /\t/;
		if ( defined $entry_id and defined $body_id )
		{
			if ( defined( $entryToBodyHash{ $entry_id } ) )
			{
				die "*** Duplicate entry_id: [$entry_id]";
			}
			$entryToBodyHash{ $entry_id } = $body_id;
		}
	}
	
	close ENTRY_TO_BODY;
}


