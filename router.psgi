use strict;
use warnings;

use Router::Simple;
use Text::Handlebars;
use Data::Dumper;
use Plack::Request;
use File::Slurp;

use PayDerbyDues::Auth::Middleware;
use PayDerbyDues::Utilities::DBConnect;
use PayDerbyDues::DerbyDues;
use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::Constants;
use PayDerbyDues::WorkFlows::All;

my $router = Router::Simple->new();

$router->connect('/', { method => \&_index });
$router->connect('/arcady', { method => \&_arcady });

# templates
$router->connect('/rollout', { method => \&_rollout });
$router->connect('/who', { method => \&_who });
$router->connect('/learnmore', { method => \&_learnmore });
$router->connect('/feescheduleadmin', { method => \&_fee_schedule_admin });
$router->connect('/emailed', { method => \&_email_ed });

my $app = sub {
	my $env = shift;

	if (my $match = $router->match($env)) {
		my $rv = eval {
			return [
				$PayDerbyDues::Constants::HTTP_SUCCESS_STATUS,
				$PayDerbyDues::Constants::HTML_CONTENT_TYPE_HEADER,
				[ $match->{method}->($match, $env) ],
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
$authroutes->connect('/getenv', {});
$authroutes->connect('/arcady', {});
PayDerbyDues::Auth::Middleware::wrap($app, authpaths => $authroutes);

sub _email_ed {
	my ($match, $env) = @_;

	my $args = +{
		TOADDRESS => q/eden.hochbaum@gmail.com/,
		TONAME => q/eden/,
		TOLEAGUE => q/Bar League/,
	};

	require PayDerbyDues::Utilities::Messaging;
	my $r = PayDerbyDues::Utilities::Messaging::SendWelcomeEmail($args);

	require Data::Dumper;

	Data::Dumper::Dumper($r),
}

sub _rollout {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/rollout.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return $handlebars->render_string($LAYOUT, {
			title => 'rollout',
			rollout => 1,
			container => $container_contents,
	}),
}

sub _who {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/who.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return $handlebars->render_string($LAYOUT, {
		title => 'who',
		who => 1,
		container => $container_contents,
	});
}

sub _learnmore {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/learnmore.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return $handlebars->render_string($LAYOUT, {
		title => 'learnmore',
		learnmore => 1,
		container => $container_contents,
	});
}

sub _fee_schedule_admin {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/feescheduleadmin.hbs');

	my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

	my $req = Plack::Request->new($env);
	my $parameters = $req->parameters;

	if ($parameters->{nextoperation} eq 'Add') {
		my $sth = $dbh->prepare('insert into feeschedule (leagueid, name, value) values (1, ?, ?)')
			or die "failed to prepare statement: " . $dbh->errstr;

		$sth->execute($parameters->{name}, $parameters->{value})
			or die "failed to execute statement: " . $sth->errstr;
	}

	my $sqlquery = "select * from feeschedule";
	my $sth = $dbh->prepare($sqlquery);
	$sth->execute();

	my $data = $sth->fetchall_arrayref; # array ref of array refs

	@$data = map {;
		my $tmp = +{};
		@{$tmp}{qw(id name leagueid value)} = @{$_};
		$tmp;
	} @$data;

	my $vars = {
		rows => $data,
	};

	my $container_contents = $handlebars->render_string($TEMPLATE, $vars);

	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	return $handlebars->render_string($LAYOUT, {
		title => 'fee schedule admin',
		feescheduleadmin => 1,
		container => $container_contents,
	});
}

sub _index {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/index.hbs');

	return $handlebars->render_string($TEMPLATE, {}),
}

sub _arcady {
	my ($match, $env) = @_;

	return PayDerbyDues::DerbyDues::request($env);
}
