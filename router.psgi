use strict;
use warnings;

use Plack::Builder;

use Router::Simple;
use Text::Handlebars;
use File::Slurp;

use PayDerbyDues::Auth::Middleware;
use PayDerbyDues::Utilities::DBConnect;
use PayDerbyDues::DerbyDues;
use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::Constants;
use PayDerbyDues::WorkFlows::All;
use PayDerbyDues::GlobalRouter;

# constant
my $router = PayDerbyDues::GlobalRouter::_GetGlobalRouter();

my $app = sub {
	my $env = shift;

	if (my $match = $router->match($env)) {
		my $rv = eval {
			$match->{func}->($match, $env);
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

# add authentication middleware wrapper
my $app2 = sub {
	my $env = shift;

	my %config = (
	    unauthredirect => '/',
	    timeout_sec => 30 * 60,
	);

	# TODO: no need to re-run routing logic at each layer of middleware
	my $match = $router->match($env) || die 'too late not to have a match'; 

	# TODO: also set $PayDerbyDues::RequestGlobal::Data::username here?
	if ($match->{requires_auth}) {
		$PayDerbyDues::RequestGlobalData::userid = PayDerbyDues::Auth::Middleware::check_auth($env, $PayDerbyDues::RequestGlobalData::dbh, %config);
		unless ($PayDerbyDues::RequestGlobalData::userid) {
			my $res = Plack::Response->new;
			$res->redirect($config{unauthredirect});

			warn "Unauthenticated user detected";
			return $res->finalize;
		}

    		warn "Authenticated as [$PayDerbyDues::RequestGlobalData::userid]";
	}

	return $app->($env);
};

# add $dbh-creation middleware wrapper
my $app3 = sub {
	my $env = shift;
	$PayDerbyDues::RequestGlobalData::dbh = PayDerbyDues::Utilities::DBConnect::GetDBH(); 
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
	return $app3->($env);
};
