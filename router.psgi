use strict;
use warnings;

use Router::Simple;
use Text::Handlebars;
use File::Slurp;

use PayDerbyDues::Auth::Middleware;
use PayDerbyDues::Utilities::DBConnect;
use PayDerbyDues::DerbyDues;
use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::Constants;
use PayDerbyDues::WorkFlows::All;

my $router = Router::Simple->new();

$router->connect('/', { themethod => \&PayDerbyDues::WorkFlows::All::index });
$router->connect('/arcady', { themethod => \&_arcady });
$router->connect('/rollout', { themethod => \&PayDerbyDues::WorkFlows::All::rollout });
$router->connect('/who', { themethod => \&PayDerbyDues::WorkFlows::All::who });
$router->connect('/learnmore', { themethod => \&PayDerbyDues::WorkFlows::All::learnmore });
$router->connect('/feescheduleadmin', { themethod => \&PayDerbyDues::WorkFlows::All::fee_schedule_admin });
$router->connect('/emailed', { themethod => \&PayDerbyDues::WorkFlows::All::email_ed });

my $app = sub {
	my $env = shift;

	$PayDerbyDues::RequestGlobalData::dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

	if (my $match = $router->match($env)) {
		my $rv = eval {
			return [
				$PayDerbyDues::Constants::HTTP_SUCCESS_STATUS,
				$PayDerbyDues::Constants::HTML_CONTENT_TYPE_HEADER,
				[ $match->{themethod}->($match, $env) ],
			];
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
};

my $authroutes = Router::Simple->new();
$authroutes->connect('/arcady', {});
PayDerbyDues::Auth::Middleware::wrap($app, authpaths => $authroutes);

sub _arcady {
	my ($match, $env) = @_;

	return PayDerbyDues::DerbyDues::request($env);
}
