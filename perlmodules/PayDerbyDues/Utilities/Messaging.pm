package PayDerbyDues::Utilities::Messaging;

use strict;
use warnings;

use Carp::Assert ();

use Paws;
use Paws::SES::Destination;
use Paws::SES::Content;
use Paws::SES::Body;
use Paws::SES::Message;

sub SendWelcomeEmail {
	my ($args) = @_;
	my ($toaddress, $toname, $toleague) = @{$args}{qw(TOADDRESS TONAME TOLEAGUE)};

	Carp::Assert::assert($toaddress);

	my $subject = _WelcomeSubject();
	my $body = _WelcomeBody($args);

	# FIXME: shouldn't hard-code region
	my $ses = Paws->service('SES', region => 'us-west-2');

	# FIXME: should log message id to db
	return $ses->SendEmail(
		Destination => Paws::SES::Destination->new(
			ToAddresses => [q/eden.hochbaum@gmail.com/],
		),
		Message => Paws::SES::Message->new(
			Body => Paws::SES::Body->new(
				Text => Paws::SES::Content->new(
					Data => $body,
				),
			),
			Subject => Paws::SES::Content->new(
				Data => $subject,
			),

		),
		Source => q/info@payderbydues.com/, 
	);
}

sub _WelcomeSubject {
	q/welcome to pdd subject/;
}

sub _WelcomeBody {
	my ($args) = @_;

	require Data::Dumper;

	# FIXME: implement this as handlebars template, with real copy
	return sprintf('hello world welcome body to args: %s', Data::Dumper::Dumper($args));
}


1;
