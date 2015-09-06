package PayDerbyDues::Utilities::DBConnect;

use strict;
use warnings;

use DBI;

sub GetDBH {
	my $connstring;
	if (exists $ENV{DBHOST}) {
            $connstring = "dbi:Pg:dbname=$ENV{DBNAME};host=$ENV{DBHOST}";
        } else {
            $connstring = "dbi:Pg:dbname=payderbydues";
        }
	return DBI->connect($connstring, $ENV{DBUSERNAME}, $ENV{DBPASSWORD}, {
		AutoCommit => 1,
		RaiseError => 1,
		PrintError => 1,
	});
}

1;
