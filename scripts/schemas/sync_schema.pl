use strict;
use warnings;

use constant DEFAULT_RDS_SCHEMA_FILE_NAME => q{/home/ec2-user/payderbydues/schema/rds_schema.json};

# TODO: validate rds_schema, validate 

use Getopt::Long (); # TODO
use File::Slurp ();

use SQL::Translator;
use SQL::Translator::Diff;

use PayDerbyDues::Utilities::DBConnect;

local $ENV{DBHOST} = q{foxtest.cdcnwhesdbho.us-west-2.rds.amazonaws.com};
my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

my $translator = SQL::Translator->new(
	show_warnings => 1,
	parser => 'DBI',
	parser_args => +{
		dbh => $dbh,
	},
);
$translator->translate() or die $translator->error;

my $production_schema = $translator->schema or die $translator->error;

$translator = SQL::Translator->new(
	show_warnings => 1,
	parser => 'PayDerbyDues::Utilities::Schema::CustomFormatParser',
);


my $rdsschemajson = File::Slurp::read_file(DEFAULT_RDS_SCHEMA_FILE_NAME());

$translator->translate(\$rdsschemajson);
my $aspirational_schema = $translator->schema or die $translator->error;

my $diff = SQL::Translator::Diff->new({
	output_db	=> 'PostgreSQL',
	source_schema	=> $production_schema,
	target_schema	=> $aspirational_schema,
})->compute_differences->produce_diff_sql;

print $diff;

