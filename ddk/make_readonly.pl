#!/usr/bin/perl
#
# 
#
# make_readonly.pl
#

use strict;
use utf8;
use open ':utf8';
use open ':std';


#
#
#
my $content = get_content();

$content =~ s/<key>IDXIndexWritable<\/key>[[:blank:]\n]*<true\/>/<key>IDXIndexWritable<\/key>\n\t\t\t<false\/>/g;

print $content;
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
