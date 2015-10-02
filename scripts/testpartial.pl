use strict;
use warnings;

use Text::Handlebars;

my $template = q[<table>
	{{#each people}}
	<tr>{{>person}}</tr>
	{{/each}}
</table>
];

my $personpartial = q[{{firstname}} {{lastname}}];

print Text::Handlebars->new(
	path => [ {'person.tx' => $personpartial} ],
)->render_string(
	$template,
	{
		people => [
			{
				firstname	=> 'hello',
				lastname	=> 'world',
			},
			{
				firstname	=> 'goodbye',
				lastname	=> 'moon',
			},
			{
				firstname	=> 'welcome',
				lastname	=> 'sun',
			},
		],
	},
);

