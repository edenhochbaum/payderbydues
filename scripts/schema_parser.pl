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

my @supportedproducers = ('PostgreSQL', 'GraphViz');

Getopt::Long::GetOptions(
	"rdsschemaschemafilename=s" => \my $rdsschemaschemafilename,
	"rdsschemafilename=s" => \my $rdsschemafilename,
	"producer=s" => \my $producer,
);

$producer ||= 'PostgreSQL';

Carp::confess(sprintf(
	'producer [%s] not one of supported producers [%s]',
	$producer,
	join(', ', @supportedproducers),
)) unless (grep { $producer eq $_ } @supportedproducers);

my $producerargs = 'GraphViz' eq $producer
	? +{
		bgcolor => 'lightgoldenrodyellow',
		show_constraints => 1,
		show_datatypes => 1,
		edge => {dir => 'back'},
	}
	: {};

$rdsschemaschemafilename ||= q{/home/ec2-user/payderbydues/schema/rds_schema_schema.json};
$rdsschemafilename ||= q{/home/ec2-user/payderbydues/schema/rds_schema.json};

my $rdsschemaschemajson = File::Slurp::read_file($rdsschemaschemafilename);
my $rdsschemajson = File::Slurp::read_file($rdsschemafilename);

my $jsonvalidator = JSON::Schema->new($rdsschemaschemajson);

my $result = $jsonvalidator->validate($rdsschemajson);

unless ($result) {
	require Data::Dumper;
	die 'error validating rds schema against rds schema schema: ' . Data::Dumper::Dumper([$result->errors]);
}

my $translator = SQL::Translator->new(
	show_warnings => 1,
	producer => $producer,
	producer_args => $producerargs,
	parser => sub {
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
				name => 'pk',
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

					$translatortable->add_constraint(
						type => 'foreign_key',
						name => sprintf('fk_%s', $column->{name}),
						fields => $field, # field in referring table
						reference_fields => 'id',
						reference_table => $column->{foreigntablename},
						match_type => 'full',
						on_delete => 'cascade',
						on_update => '',
					);

				}

				$translatortable->add_field($field);
			}

			$tr->schema->add_table($translatortable);

		}

		1;
	},
);

my $output = $translator->translate(\$rdsschemajson);

print $output;
