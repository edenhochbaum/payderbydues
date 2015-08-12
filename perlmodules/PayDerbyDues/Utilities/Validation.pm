package PayDerbyDues::Utilities::Validation;

use strict;
use warnings;

use Carp;

use Exporter 'import';

our @EXPORT = qw(
	va
);

# validate args
sub va {
	my ($arghash, $requiredexisting, $allowedexisting) = @_;

	Carp::confess('need void context') if (defined(wantarray));

	my %requiredhash;
	my %allowedhash;
	eval {
		@requiredhash{@$requiredexisting} = ('1') x scalar(@$requiredexisting);
		@allowedhash{@$allowedexisting} = ('1') x scalar(@$allowedexisting);
	};
	Carp::confess($@) if ($@);

	use Data::Dumper;
	print Dumper(\%requiredhash);

	foreach my $key (keys %$arghash) {
		next if (delete $requiredhash{$key});
		Carp::confess(sprintf('invalid key [%s]', $key)) unless ($allowedhash{$key});
	}

	if (%requiredhash) {
		Carp::confess(sprintf('failed to find existing required fields [%s]', join(', ', keys(%requiredhash))));
	}

	return;
}

1;
