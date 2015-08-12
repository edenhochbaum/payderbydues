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
			if($match->{dont_finalize}) {
				$match->{func}->($match, $env);
			}
			else {
				[
					$PayDerbyDues::Constants::HTTP_SUCCESS_STATUS,
					$PayDerbyDues::Constants::HTML_CONTENT_TYPE_HEADER,
					[ $match->{func}->($match, $env) ],
				];
			}
		};

		if ($@) {
			return [
				$PayDerbyDues::Constants::HTTP_INTERNAL_ERROR_STATUS,
				$PayDerbyDues::Constants::PLAIN_CONTENT_TYPE_HEADER,
				["ERROR!!! $@"],
			];
		}

		return $rv;
	}

};

# add authentication wrapper
my $app2 = PayDerbyDues::Auth::Middleware::wrap($app);

# add global request middleware wrapper
# this just creates a $dbh for now
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
