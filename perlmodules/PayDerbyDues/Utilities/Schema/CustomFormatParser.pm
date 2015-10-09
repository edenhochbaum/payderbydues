package PayDerbyDues::Utilities::Schema::CustomFormatParser;

use strict;
use warnings;

# This module defines the logic engaged by the SQL::Translator framework to parse
# PDD's custom rds schema definitions.
#
# See:
# 	payderbydues/schema/rds_schema_schema.json
# 	payderbydues/schema/rds_schema.json
# 	http://search.cpan.org/~ilmari/SQL-Translator-0.11021/lib/SQL/Translator.pm

use JSON;
use SQL::Translator::Schema::Table;
use SQL::Translator::Schema::Field;

sub parse {
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

1;
