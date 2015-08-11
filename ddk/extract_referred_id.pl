#!/usr/bin/perl
#
# Extract referred ID
#
# extract_referred_id.pl <xml files>
#

use strict;
use utf8;
use open ':utf8';
use open ':std';

# separator
my $sp			= "[[:blank:]\n]";		# 
my $reqsp		= "[[:blank:]\n]+";		# required space
my $optsp		= "[[:blank:]\n]*";		# optional space

my $qattr		= "(\"[^\"]*\"|'[^']*')";	# quoted attribute value
my $qattr_ne	= "(\"[^\"]+\"|'[^']+')";	# quoted attribute value (non-empty)

# namespace
my $ns							= "d:";
# node name
my $entry_ndnm					= "entry";
# attribute name
my $a_ndnm						= "a";
my $href						= "href";
my $xdict						= "x-dictionary";


# =============================================================
# main
# =============================================================
# Skip other lines that does not begin with <d:entry>.
my $lastPos;
while (<>) {
	last if /<$ns$entry_ndnm/;
	$lastPos = tell;
# 	chomp;
# 	print $_,"\n";
}
seek ARGV, $lastPos, 0;

$/ = "</$ns$entry_ndnm>\n";
while ( <> )
{
	next unless /^<$ns$entry_ndnm/;
	process_an_entry( $_ );
}
exit( 0 );


# =============================================================
# process_an_entry
# =============================================================
sub process_an_entry
{
	my ( $entry ) = @_;
	# printf "== [%s]\n", $entry;
	
	my $text = $entry;
	
	while ( $text =~ /((<$a_ndnm$reqsp[^>]+>).*?<\/$a_ndnm>)/ )
	{
		$text			= $';	#'
		#my $reference	= $1;
		my $a_open_tag	= $2;
		if ( $a_open_tag =~ /$reqsp$href$optsp=$optsp($qattr_ne)/ )
		{
			$1 =~ /^(["']{1})([^\1]*)\1$/;
			my $referred_url	= $2;
			process_a_referred_url( $referred_url );
		}
	}
}


# =============================================================
# process_a_referred_url
# =============================================================
sub process_a_referred_url
{
	my ( $referred_url ) = @_;
	
	# printf "[%s]\n", $referred_url;			# 
	# This contains entry_id and dict_bundle_id formally.
	# The dict_bundle_id can be omitted.
	
	my $referred_id			= '';
	my $dict_bundle_id		= '';
	if ( $referred_url =~ /^$optsp$xdict:r:(.*?)$optsp$/ )
	{
		$referred_id	= $1;
		
		if ( $referred_id ne "" )
		{
			# Remove dict_bundle_id part.
			if ( $referred_id =~ /^([^:]+):(.*?)$/ )
			{
				$referred_id	= $1;
				$dict_bundle_id	= $2;
			}
		}
	}
	
	if ( $referred_id ne "" )
	{
		$referred_id = decode_xml_char( $referred_id );
		# printf "%s\t%s\n", $referred_id, $dict_bundle_id;
		printf "%s\n", $referred_id;
	}
}


# =============================================================
# decode_xml_char
# =============================================================
sub decode_xml_char
{
	my ( $text ) = @_;
	
	if ( defined( $text ) && ( $text ne '' ) )
	{		
		$text =~ s/&lt;/</g;
		$text =~ s/&gt;/>/g;
		$text =~ s/&quot;/\"/g;
		$text =~ s/&apos;/\'/g;
		$text =~ s/&amp;/&/g;		# "&amp;" should be the last.
	}
	return $text;
}
