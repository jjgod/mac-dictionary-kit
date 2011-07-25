#!/usr/bin/perl
#
# Extract index data. 
#
# extract_index.pl <xml files>
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
my $index_ndnm					= "index";
# attribute name
my $id_atnm						= "id";
my $parental_control_atnm		= "parental-control";
my $priority_atnm				= "priority";
my $value_atnm					= "value";
my $title_atnm					= "title";
my $yomi_atnm					= "yomi";
my $anchor_atnm					= "anchor";

my $priority_max				= 9;
my $priority_shift				= 1;	# Use bit 1-4 from LSB.
										# Bit 0 at LSB is for parental-control.

my $warn_msg_count_for_missing_entry_title	= 0;

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
	
	my $entry_tag;
	my $entry_id;
	my $entry_parental_flag		= 0;
	my $entry_title;
	my $entry_yomi;
	
	if ( $entry =~ /^(<$ns$entry_ndnm$reqsp[^<]+>)/ )
	{
		$entry_tag	= $1;
	}
	else
	{
		die "No entry tag ** [$entry] **";
	}
	
	if ( $entry_tag =~ /$reqsp$id_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$entry_id	= $2;
	}
		
	if ( ! defined( $entry_id ) || ( $entry_id eq '' ) )
	{
		die "No entry id in entry tag ** [$entry_tag] **";
	}
	
	# Check parental-control attr in the entry.
	if ( $entry_tag =~ /$reqsp$ns$parental_control_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$entry_parental_flag	= $2;
	}
	
	
	# Check entry_title (title attr in the entry).
	if ( $entry_tag =~ /$reqsp$ns$title_atnm$optsp=$optsp($qattr)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		if ( defined( $2 ) && $2 ne '' )
		{
			$entry_title	= $2;
		}
	}
	if ( ! defined( $entry_title ) )
	{
		$entry_title = '';
		
		$warn_msg_count_for_missing_entry_title++;
		if ( $warn_msg_count_for_missing_entry_title <= 100 )
		{
			printf STDERR "** No title for entry[$entry_tag].  Proceeding with empty title.\n";
			if ( $warn_msg_count_for_missing_entry_title == 100 )
			{
				printf STDERR "** Maybe more...\n";
			}
		}
	}
	$entry_title = decode_xml_char( $entry_title );
	
	# Check yomi attr in the entry.
	if ( $entry_tag =~ /$reqsp$ns$yomi_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$entry_yomi	= $2;
	}
	
	
	my $entry_flags	= $entry_parental_flag;
	# printf "-- [%s][%s]\n", $entry_id, $entry_flags;			# 
	my $text = $entry;
	while ( $text =~ /(<$ns$index_ndnm$reqsp[^<]+\/>|<$ns$index_ndnm$reqsp[^<]+>$optsp<\/d:index>)/ )
	{
		my $index	= $1;
		$text		= $';	#'
		process_an_index( $entry_id, $entry_flags, $index, 
										$entry_title, $entry_yomi );
	}
}


# =============================================================
# process_an_index
# =============================================================
sub process_an_index
{
	my ( $entry_id, $entry_flags, $index, 
						$entry_title, $entry_yomi ) = @_;
	# printf "[%s][%s]\n", $entry_id, $index;			# 
	
	my $value;
	my $title;
	my $index_parental_flag = 0;
	my $index_priority_flag = 0;
	my $index_flags			= 0;
	my $anchor				="";
	my $yomi;
	
	
	# printf STDERR "[%s][%s]\n", $entry_id, $index;			# 
	
	if ( $index =~ /$reqsp$ns$value_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$value	= $2;
	}
	
	if ( $index =~ /$reqsp$ns$title_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$title	= $2;
	}
	if ( ! defined( $title ) )
	{
		$title = $value;
	}
	
	# parental-control (optional)
	if ( $index =~ /$reqsp$ns$parental_control_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$index_parental_flag	= $2;
	}
	if ( $index_parental_flag > 0 )
	{
		$index_flags = $index_flags | $index_parental_flag;	
		# flags contains parental-control-flag only, now.
	}
	else
	{
		$index_flags = $entry_flags;
	}
	
	# priority (optional)
	if ( $index =~ /$reqsp$ns$priority_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$index_priority_flag	= $2;
	}
	if ( defined( $index_priority_flag ) && $index_priority_flag > 0 )
	{
		if ( $index_priority_flag > $priority_max )
		{
			printf STDERR "*** Invalid priority. Ignored -- entry[$entry_id] index[$index]\n";
		}
		else
		{
			$index_priority_flag = $index_priority_flag << $priority_shift;	# 
			$index_flags = $index_flags | $index_priority_flag;
		}
		
	}
	
	# anchor (optional)
	if ( $index =~ /$reqsp$ns$anchor_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$anchor	= $2;
	}
	
	# yomi (optional)
	if ( $index =~ /$reqsp$ns$yomi_atnm$optsp=$optsp($qattr_ne)/ )
	{
		$1 =~ /^(["']{1})([^\1]*)\1$/;
		$yomi	= $2;
	}
	if ( ! defined( $yomi ) )
	{
		if ( defined( $entry_yomi ) )
		{
			$yomi = $entry_yomi;
		}
		else
		{
			$yomi = "";
		}
	}
	
	if ( defined( $value ) && defined( $title ) )
	{
		$value = decode_xml_char( $value );
		$title = decode_xml_char( $title );
		$yomi = decode_xml_char( $yomi );
		# Not decode $entry_id. It should not contain such chracter entities.
		# Not decode $entry_id. It is already decoded in the caller.
		if ( $entry_title eq $title )
		{
			$entry_title = '';		# Put it only when it is different from $title.
		}
		printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", 
			$value, $entry_id, $index_flags, $title, $anchor, $yomi, $entry_title;
	}
	else
	{
		printf STDERR "*** Invalid index. Skipped -- entry[$entry_id] index[$index]\n";
		# die "Invalid index ** entry[$entry_id] index[$index] **";
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
