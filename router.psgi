use Router::Simple;
use Text::Handlebars;
use Data::Dumper;
use Plack::Request;
use File::Slurp;

use PayDerbyDues::Auth::Middleware;
use PayDerbyDues::Utilities::DBConnect;

my $HTML_HEADERS = [ 'Content-Type' => 'text/html' ];
my $PLAIN_HEADER = [ 'Content-Type' => 'text/plain' ];
my $SUCCESS_STATUS = 200;

my $router = Router::Simple->new();

$router->connect('/', { method => \&_index });
$router->connect('/arcady', { method => \&_arcady });

## $router->connect('/getenv', { method => \&_get_env });


# templates
$router->connect('/rollout', { method => \&_rollout });
$router->connect('/who', { method => \&_who });
$router->connect('/learnmore', { method => \&_learnmore });
$router->connect('/feescheduleadmin', { method => \&_fee_schedule_admin });
$router->connect('/emailed', { method => \&_email_ed });

my $app = sub {
	my $env = shift;
	my ($status, $headers, $body);

	if (my $match = $router->match($env)) {
		eval {
			($status, $headers, $body) = @{ $match->{method}->($match, $env) };
		};
		if ($@) {
			$status = 500;
			$headers = [ 'Content-Type' => 'text/plain' ];
			$body = "ERROR!!! $@";
		}
	}
	else {
		($status, $headers, $body) = (
			404,
			[],
			Text::Handlebars->new()->render_string(
				File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/404.hbs'),
				{},
			),
		);
	}

	return [
		$status,
		$headers,
		[$body],
	];
};

my $authroutes = Router::Simple->new();
$authroutes->connect('/getenv', {});
PayDerbyDues::Auth::Middleware::wrap($app, authpaths => $authroutes);

# note, we've de-activated routing to this!
sub _get_env {
	my ($match, $env) = @_;

	return [
		200,
		$HTML_HEADERS,
		Dumper(\%ENV),
	];
}

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

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		Data::Dumper::Dumper($r),
	];
}

sub _rollout {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/rollout.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($LAYOUT, {
			title => 'rollout',
			rollout => 1,
			container => $container_contents,
		}),
	];
}

sub _who {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/who.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($LAYOUT, {
			title => 'who',
			who => 1,
			container => $container_contents,
		}),
	];
}

sub _learnmore {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/learnmore.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($LAYOUT, {
			title => 'learnmore',
			learnmore => 1,
			container => $container_contents,
		}),
	];
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

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($LAYOUT, {
			title => 'fee schedule admin',
			feescheduleadmin => 1,
			container => $container_contents,
		}),
	];
}

sub _index {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/index.hbs');

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($TEMPLATE, {}),
	];
}

sub _arcady {
	my ($match, $env) = @_;

	require PayDerbyDues::DerbyDues;

	$headers = [ 'Content-Type' => 'text/html'];

	eval {
		$body = PayDerbyDues::DerbyDues::request($env);
		$status = 200;
	};
	if ($@) {
		$status = 500;
		$body = "ERROR!!! $@";
	}

	return [ $status, $headers, $body ];
}
