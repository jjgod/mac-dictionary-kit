#!/usr/bin/perl -w
#
# Normalize key_text
#
# normalize_key_text.pl < infile > outfile
#

use strict;
use utf8;
use open ':utf8';
use open ':std';
# require bytes;


# =============================================================
# main
# =============================================================

while ( my $record = <stdin> )
{
	chomp $record;
	if ( $record =~ /^$/ )
	{
		next;
	}
	
	my ( $key_text, $body_id, $flags, $title, $anchor, $yomi, $entry_title ) = split /\t/, $record;
	if ( not defined $anchor )
	{
		printf STDERR "*** Unknown format. Skipped [%s]\n", $record;
		next;
	}
	
	my $normalized_key = createSearchKey( $key_text );
	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
		$normalized_key, $body_id, $flags, $title, $anchor, $yomi, $entry_title;
}
exit 0;


#
sub createSearchKey
{
	$_ = lc shift;
	#tr/àáâãäåāăçćčèéêëęěíîïłñńňóôõöøřśşšţùúûüýź/aaaaaaaaccceeeeeeiiilnnnooooorssstuuuuyz/;
	#s/[Æ]/AE/g;
	s/[æ]/ae/g;
	s/[œ]/oe/g;
	s/–/-/g;
	s/‛/'/g;
	s/“/"/g;
	s/”/"/g;
	s/’/'/g;
	#s/^-//;
	s/й/и/g;
	s/ё/е/g;
	return $_;
}
