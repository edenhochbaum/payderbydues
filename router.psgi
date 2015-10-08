use strict;
use warnings;

use Plack::Builder;

use Router::Simple;
use Text::Handlebars;
use File::Slurp;

use PayDerbyDues::Auth::Middleware;
use PayDerbyDues::Utilities::DBConnect;
use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::Constants;
use PayDerbyDues::GlobalRouter;

my $router = PayDerbyDues::GlobalRouter::_GetGlobalRouter();
my $dbh;

# add wrapper to engage the resource-specific logic
my $app = sub {
	my $env = shift;

	if ($env->{match}) {
		my $rv = eval {
			$env->{match}{func}->($env->{$match}, $env);
		};

		if ($@) {
			$rv = [
				$PayDerbyDues::Constants::HTTP_INTERNAL_ERROR_STATUS,
				$PayDerbyDues::Constants::PLAIN_CONTENT_TYPE_HEADER,
				["ERROR!!! $@"],
			];
		}

		return $rv;
	}
};

# add global request data initialization wrapper
my $app1 = sub {
	my $env = shift;

	PayDerbyDues::RequestGlobalData::InitializeRequestGlobalData({
		DBH => $dbh,
		USERID => $env->{userid},
	});

	return $app->($env);
};

# add authentication middleware wrapper
my $app2 = sub {
	my $env = shift;

	my %config = (
	    unauthredirect => '/',
	    timeout_sec => 30 * 60,
	);

        $env->{userid} = eval { PayDerbyDues::Auth::Middleware::check_auth($env, $dbh, %config) };

	if ($env->{match}{requires_auth}) {
		unless (defined($env->{userid})) {
			my $res = Plack::Response->new;
			$res->redirect($config{unauthredirect});

			warn "Unauthenticated user detected";
			return $res->finalize;
		}
	}

	return $app1->($env);
};

# add $dbh-creation middleware wrapper
my $app3 = sub {
	my $env = shift;
	$dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();
	return $app2->($env);
};

# add 404 middleware wrapper
my $app4 = sub {
	my $env = shift;
	my $match = $router->match($env);

	unless ($match) {
		return [
			$PayDerbyDues::Constants::HTTP_NOT_FOUND_STATUS,
			$PayDerbyDues::Constants::HTML_CONTENT_TYPE_HEADER,
			[
				Text::Handlebars->new()->render_string(
					File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/404.hbs'),
					{},
				),
			]
		];
	}

	$env->{match} = $match;
	return $app3->($env);
};
