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

sub _parser {
	my ($tr, $validatedrdsschemajson) = @_;

	my $rdsschemaobj = JSON::decode_json($validatedrdsschemajson);

	$tr->schema->name('payderbydues');

	foreach my $table (@$rdsschemaobj) {
		my $translatortable = SQL::Translator::Schema::Table->new(
			name => $table->{name},
		);

		my $primarykey = SQL::Translator::Schema::Field->new(
			name => 'id',
		);
		$primarykey->is_auto_increment(1);
		$primarykey->is_primary_key(1);
		$primarykey->size(10);

		$translatortable->add_field($primarykey);

		$translatortable->add_constraint(
			name => sprintf('pk_%s', $table->{name}),
			type => 'primary_key',
			fields => [$primarykey],
		);

		foreach my $column (@{$table->{columns}}) {
			my $field = SQL::Translator::Schema::Field->new(
				name => $column->{name},
			);

			if (defined($column->{datatype})) {
				$field->data_type($column->{datatype});
			}

			if (defined($column->{foreigntablename})) {
				$field->is_foreign_key(1);
				$field->data_type('integer');

				$translatortable->add_constraint(
					type => 'foreign_key',
					name => sprintf('fk_%s', $column->{name}),
					fields => $field, # field in referring table
					reference_fields => 'id',
					reference_table => $column->{foreigntablename},
					on_delete => 'cascade',
					on_update => '',
				);

			}

			$translatortable->add_field($field);
		}

		$tr->schema->add_table($translatortable);

	}

	1;
}

my $translator = SQL::Translator->new(
	show_warnings => 1,
	producer => $producer,
	producer_args => PRODUCER_ARGS->{$producer} || +{},
	parser => \&_parser,
);

my $output = $translator->translate(\$rdsschemajson);

print $output;
