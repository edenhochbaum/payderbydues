#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
	$\ = "\n";
}

use constant CGI_HEADER => "Content-type: text/html\n\n";

use Data::Dumper;
use Utilities::DBConnect;

my $dbh = Utilities::DBConnect::GetDBH();

print CGI_HEADER;

my $sqlquery = "select * from company";

my $sth = $dbh->prepare($sqlquery);

$sth->execute();

while(my @row = $sth->fetchrow_array) {
	print Data::Dumper::Dumper(\@row);
}


