package PayDerbyDues::RequestGlobalData;

use strict;
use warnings;

use PayDerbyDues::Utilities::Validation;

# TODO: will have to clear these on page load on transition from cgi to pre-fork!

our $dbh;

our $user = +{
	USERID => undef,
	USERLEGALNAME => undef,
	USERDERBYNAME => undef,
};

sub InitializeRequestGlobalData {
	my $args = shift;
	va($args, [qw(DBH MEMBERID)], []);

	$PayDerbyDues::RequestGlobalData::dbh = $args->{DBH};
	$PayDerbyDues::RequestGlobalData::user->{USERID} = $args->{MEMBERID};

	# initialize user request global data details
	if ($PayDerbyDues::RequestGlobalData::user->{USERID}) {
		@{$PayDerbyDues::RequestGlobalData::user}{qw(
			USERLEGALNAME
			USERDERBYNAME
		)} = $dbh->selectrow_array(q{
			SELECT
				legalname, derbyname
			FROM
				member
			WHERE
				id = ?
		}, undef, $args->{MEMBERID});
	}
}


1;
