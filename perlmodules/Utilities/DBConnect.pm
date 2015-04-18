package Utilities::DBConnect;

use strict;
use warnings;

use DBI;

sub GetDBH {
	return DBI->connect("dbi:Pg:dbname=$ENV{DBNAME};host=$ENV{DBHOST}", $ENV{DBUSERNAME}, $ENV{DBPASSWORD}, {
		AutoCommit => 1,
		RaiseError => 1,
		PrintError => 1,
	});
}

1;
