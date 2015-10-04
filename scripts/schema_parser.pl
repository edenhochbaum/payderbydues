use strict;
use warnings;

use SQL::Translator;
use SQL::Translator::Schema;
use SQL::Translator::Schema::Table;
use SQL::Translator::Schema::Field;
use SQL::Translator::Producer::PostgreSQL;
use SQL::Translator::Schema::Constraint;

use JSON ();
use JSON::Schema;

use File::Slurp ();

my $rdsschemaschemafilename = q{/home/ec2-user/payderbydues/schema/rds_schema_schema.json};
my $rdsschemafilename = q{/home/ec2-user/payderbydues/schema/rds_schema.json};

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
	producer => 'PostgreSQL',
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

			foreach my $column (@{$table->{columns}}) {
				my $field = SQL::Translator::Schema::Field->new(
					name => $column->{name},
				);

				if (defined($column->{datatype})) {
					$field->data_type($column->{datatype});
				}

				if (defined($column->{foreigntablename})) {
					$field->data_type('integer'); # TODO: construction of SQL::Translator::Schema::Constraint
					$field->is_foreign_key(1);
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
