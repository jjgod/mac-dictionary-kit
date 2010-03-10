#!/usr/bin/perl
#
# 
#
# extract_front_matter_id.pl
#

use strict;
use utf8;
use open ':utf8';
use open ':std';


#
#
#
my $content = get_content();

if ( $content =~ /<key>DCSDictionaryFrontMatterReferenceID<\/key>[[:blank:]\n]*<string>(.*?)<\/string>/ )
{
	my $front_matter_id	= $1;
	printf "%s\n", $front_matter_id;
}

exit(0);


#
#
#
sub get_content
{
	my $content_lines;
	while ( my $line = <> ) {
		$content_lines = $content_lines . $line;
	}
	# printf "content_lines [%s]\n", $content_lines;
	
	return $content_lines;
}
