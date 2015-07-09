package PayDerbyDues::Utilities::Messaging;

use strict;
use warnings;

use Carp::Assert ();
use Mail::RFC822::Address ();
use Text::Handlebars;

use Paws;
use Paws::SES::Destination;
use Paws::SES::Content;
use Paws::SES::Body;
use Paws::SES::Message;

sub SendWelcomeEmail {
	my ($args) = @_;
	my ($toaddress, $toname, $toleague) = @{$args}{qw(TOADDRESS TONAME TOLEAGUE)};

	Carp::Assert::assert(Mail::RFC822::Address::valid($toaddress));

	my $subject = _WelcomeSubject();
	my $body = _WelcomeBody($args);

	# FIXME: shouldn't hard-code region
	my $ses = Paws->service('SES', region => 'us-west-2');

	# FIXME: should log message id to db
	return $ses->SendEmail(
		Destination => Paws::SES::Destination->new(
			ToAddresses => [$toaddress],
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

	my $WELCOMETEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/emails/welcome.hbs');

	Carp::Assert::assert($WELCOMETEMPLATE);

	my $handlebars = Text::Handlebars->new();

	# FIXME: implement this as handlebars template, with real copy
	return $handlebars->render_string($WELCOMETEMPLATE, {
		name => $args->{TONAME},
		league => $args->{TOLEAGUE},
		invitedby => 'Eden Hochbaum',
	});
}

1;
