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

use PayDerbyDues::Utilities::Validation;

sub SendWelcomeEmail {
	my ($args) = @_;

	use Data::Dumper;
	warn Dumper($args);
	va($args, [qw(TOADDRESS TONAME TOLEAGUE)], [qw(SUBJECT BODY)]);

	my ($toaddress, $toname, $toleague, $subject, $body) = @{$args}{qw(TOADDRESS TONAME TOLEAGUE SUBJECT BODY)};

	Carp::Assert::assert(Mail::RFC822::Address::valid($toaddress));

	$subject	||= _WelcomeSubject({});
	$body		||= _WelcomeBody({
		TONAME => $toname,
		TOLEAGUE => $toleague,
	});

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
	my ($args) = @_;

	va($args, [], []);

	return "Activate your account at PayDerbyDues!";
}

sub _WelcomeBody {
	my ($args) = @_;

	va($args, [qw(TONAME TOLEAGUE)], [qw(INVITEDBY)]);

	my ($name, $league, $invitedby) = @{$args}{qw(TONAME TOLEAGUE INVITEDBY)};
	$invitedby ||= q/Eden Hochbaum/;

	my $WELCOMETEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/emails/welcome.hbs');

	Carp::Assert::assert($WELCOMETEMPLATE);

	my $handlebars = Text::Handlebars->new();

	# FIXME: implement this as handlebars template, with real copy
	return $handlebars->render_string($WELCOMETEMPLATE, {
		name => $name,
		league => $league,
		invitedby => $invitedby,
	});
}

1;
