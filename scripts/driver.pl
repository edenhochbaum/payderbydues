use strict;
use warnings;

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

use Data::Dumper;
print Data::Dumper::Dumper($dbh);

my $sqlquery = "select * from company";

my $sth = $dbh->prepare($sqlquery);

$sth->execute();

while(my @row = $sth->fetchrow_array) {
	print Data::Dumper::Dumper(\@row);
}
