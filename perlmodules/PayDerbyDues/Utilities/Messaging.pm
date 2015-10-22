package PayDerbyDues::Utilities::Messaging;

use strict;
use warnings;

use Carp::Assert ();
use Mail::RFC822::Address ();
use Text::Handlebars;
use File::Slurp;

use PayDerbyDues::Utilities::Validation;

sub _send_with_paws {
	my ($toaddress, $subject, $body) = @_;

	require Paws;
	require Paws::SES::Destination;
	require Paws::SES::Content;
	require Paws::SES::Body;
	require Paws::SES::Message;

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

sub send_welcome_email {
	my ($args) = @_;

	use Data::Dumper;
	warn Dumper($args);
	va($args, [qw(TOADDRESS TONAME TOLEAGUE LINK)], [qw(SUBJECT BODY INVITEDBY)]);

	my ($toaddress, $toname, $toleague, $subject, $body, $link, $invitedby) = @{$args}{qw(TOADDRESS TONAME TOLEAGUE SUBJECT BODY LINK INVITEDBY)};

	Carp::Assert::assert(Mail::RFC822::Address::valid($toaddress));

	$subject	||= _welcome_subject({});
	$body		||= _welcome_body({
		TONAME => $toname,
		INVITEDBY => $invitedby,
		TOLEAGUE => $toleague,
		LINK => $link,
	});

	if ($ENV{MAILOVERRIDE}) {
		open(my $fh, '|-', 'mail', '-s', $subject, 'arcady@localhost');
		print $fh $body;
	} else {
		_send_with_paws($toaddress, $subject, $body);
	}
}

sub _welcome_subject {
	my ($args) = @_;

	va($args, [], []);

	return "Activate your account at PayDerbyDues!";
}

sub _welcome_body {
	my ($args) = @_;

	va($args, [qw(TONAME TOLEAGUE LINK)], [qw(INVITEDBY)]);

	my ($name, $league, $invitedby, $link) = @{$args}{qw(TONAME TOLEAGUE INVITEDBY LINK)};
	$invitedby ||= q/Eden Hochbaum/;

	my $WELCOMETEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/emails/welcome.hbs');

	Carp::Assert::assert($WELCOMETEMPLATE);

	my $handlebars = Text::Handlebars->new();

	# FIXME: implement this as handlebars template, with real copy
	return $handlebars->render_string($WELCOMETEMPLATE, {
		name => $name,
		league => $league,
		invitedby => $invitedby,
		link => $link,
	});
}

1;
