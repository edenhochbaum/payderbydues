use strict;
use warnings;

use SQL::Translator;
use SQL::Translator::Schema;
use SQL::Translator::Schema::Table;
use SQL::Translator::Schema::Field;
use SQL::Translator::Producer::PostgreSQL;
use SQL::Translator::Schema::Constraint;

use JSON ();
use JSON::Schema ();
use Getopt::Long ();
use File::Slurp ();

use Carp;

use constant DEFAULT_RDS_SCHEMA_SCHEMA_FILE_NAME => q{/home/ec2-user/payderbydues/schema/rds_schema_schema.json};

use constant DEFAULT_RDS_SCHEMA_FILE_NAME => q{/home/ec2-user/payderbydues/schema/rds_schema.json};

use constant SUPPORTED_PRODUCERS => qw(
	PostgreSQL
	GraphViz
	YAML
);

use constant PRODUCER_ARGS => +{
	GraphViz => +{
		bgcolor => 'lightgoldenrodyellow',
		show_constraints => 1,
		show_datatypes => 1,
		edge => {dir => 'back'},
	},
};

use constant MANUAL => <<EOF;
	perl $0
		--rdsschemaschemafilename <rdsschemaschemafilename>
		--rdsschemafilename <rdsschemafilename>
		--producer <producer>
EOF

Getopt::Long::GetOptions(
	"rdsschemaschemafilename=s"	=> \my $rdsschemaschemafilename,
	"rdsschemafilename=s"		=> \my $rdsschemafilename,
	"producer=s"			=> \my $producer,
	"help!"				=> \my $help,
) or die MANUAL();

if ($help) {
	print MANUAL();
	exit;
};

$producer ||= (SUPPORTED_PRODUCERS())[0];

Carp::confess(sprintf(
	'producer [%s] not one of supported producers [%s]',
	$producer,
	join(', ', SUPPORTED_PRODUCERS()),
)) unless (grep { $producer eq $_ } SUPPORTED_PRODUCERS());

my $rdsschemaschemajson = File::Slurp::read_file($rdsschemaschemafilename || DEFAULT_RDS_SCHEMA_SCHEMA_FILE_NAME());
my $rdsschemajson = File::Slurp::read_file($rdsschemafilename || DEFAULT_RDS_SCHEMA_FILE_NAME());

unless (my $result = JSON::Schema->new($rdsschemaschemajson)->validate($rdsschemajson)) {
	require Data::Dumper;
	die 'error validating rds schema against rds schema schema: ' . Data::Dumper::Dumper([$result->errors]);
}

my $translator = SQL::Translator->new(
	show_warnings => 1,
	producer => $producer,
	producer_args => PRODUCER_ARGS->{$producer} || +{},
	parser => 'PayDerbyDues::Utilities::Schema::CustomFormatParser',
);

my $output = $translator->translate(\$rdsschemajson);

print $output;
