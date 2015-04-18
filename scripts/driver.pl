use strict;
use warnings;

BEGIN {
	$\ = "\n";

	# change to PERL5LIB
	push(@INC, "$ENV{HOME}/perl5/lib/perl5/x86_64-linux-thread-multi/", "$ENV{PAYDERBYDUESHOME}/perlmodules/");
}

use Utilities::DBConnect;

my $dbh = Utilities::DBConnect::GetDBH();

use Data::Dumper;
print Data::Dumper::Dumper($dbh);

my $sqlquery = "select * from company";

my $sth = $dbh->prepare($sqlquery);

$sth->execute();

while(my @row = $sth->fetchrow_array) {
	print Data::Dumper::Dumper(\@row);
}

