#!/usr/bin/perl
#
# Create dictionary body and offset/size file. 
#
# make_body.pl xml_file
# It makes 2 files.
# - "objects_dir/dict.body"
# - "objects_dir/dict.offsets"
#

use strict;
use utf8;
use open ':utf8';
use open ':std';
require bytes;

# separator
my $sp			= "[[:blank:]\n]";		# 
my $reqsp		= "[[:blank:]\n]+";		# required space
my $optsp		= "[[:blank:]\n]*";		# optional space

my $qattr		= "(\"[^\"]*\"|'[^']*')";	# quoted attribute value
my $qattr_ne	= "(\"[^\"]+\"|'[^']+')";	# quoted attribute value (non-empty)

# namespace
my $ns							= "d:";
# node name
my $index_ndnm					= "index";


my $objects_dir = $ENV{ 'DICT_DEV_KIT_OBJ_DIR' };
if ( ! defined( $objects_dir ) )
{
	print STDERR "  * No environment variable 'DICT_DEV_KIT_OBJ_DIR'.\n";
	$objects_dir = "objects";
	printf STDERR "  * Using '%s'.\n", $objects_dir;
}

open( BODY,  ">$objects_dir/dict.body") or die "*** Can't open $objects_dir/dict.body\n";
open( INDEX, ">$objects_dir/dict.offsets") or die "*** Can't open $objects_dir/dict.offsets\n";

my $offset = 0;
# my $serial = 1;

# Skip other lines that does not begin with <entry>.
my $lastPos;
while (<>) {
	last if /<${ns}entry/;
	$lastPos = tell;
# 	chomp;
# 	print $_,"\n";
}
seek ARGV, $lastPos, 0;


$/ = "</${ns}entry>\n";
while (<>) {
	# printf "[%s]\n", $_;
	next unless /^<${ns}entry/;
	
	s|^<${ns}entry|<${ns}entry xmlns:d="http://www.apple.com/DTDs/DictionaryService-1.0.rng"|;
	
	# Remove <d:index>.
	s/<$ns$index_ndnm$reqsp[^<]+\/>|<$ns$index_ndnm$reqsp[^<]+>$optsp<\/d:index>//g;
	s/\n[[:blank:]\t]*\n/\n/g;
	
	print BODY $_;
	
	my $bytesize = bytes::length($_);
	die "No ID ** [$_] **" unless /^<${ns}entry [^<]+?id$optsp=$optsp($qattr_ne)/;	# "
	$1 =~ /^(["']{1})([^\1]*)\1$/;
	my $entry_id = $2;
	print INDEX "$entry_id\t$offset\t$bytesize\n";
	# ++$serial;
	$offset += $bytesize;
}

close INDEX;
close BODY;
exit(0);
