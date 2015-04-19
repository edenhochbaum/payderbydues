use strict;
use warnings;

BEGIN {
	$\ = "\n";
<<<<<<< HEAD
=======

	# change to PERL5LIB
	push(@INC, "$ENV{HOME}/perl5/lib/perl5/x86_64-linux-thread-multi/", "$ENV{PAYDERBYDUESHOME}/perlmodules/");
>>>>>>> 2fab95e8b90698e12b699756c6ad2a845217dec8
}

use Utilities::DBConnect;

my $dbh = Utilities::DBConnect::GetDBH();
<<<<<<< HEAD

use Data::Dumper;
print Data::Dumper::Dumper($dbh);

my $sqlquery = "select * from company";

my $sth = $dbh->prepare($sqlquery);

$sth->execute();

while(my @row = $sth->fetchrow_array) {
	print Data::Dumper::Dumper(\@row);
}

=======

use Data::Dumper;
print Data::Dumper::Dumper($dbh);

my $sqlquery = "select * from company";

my $sth = $dbh->prepare($sqlquery);

$sth->execute();

while(my @row = $sth->fetchrow_array) {
	print Data::Dumper::Dumper(\@row);
}
>>>>>>> 2fab95e8b90698e12b699756c6ad2a845217dec8

