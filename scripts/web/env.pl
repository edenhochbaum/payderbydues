#!/usr/bin/perl

use strict;
use warnings;

use constant CGI_HEADER => "Content-type: text/html\n\n";

use Data::Dumper;

print CGI_HEADER;

print "Perl $]<br>\n";
print Dumper(\%ENV);


