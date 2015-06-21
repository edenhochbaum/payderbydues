use Router::Simple;
use Text::Handlebars;
use Data::Dumper;
use Plack::Request;
use File::Slurp;

use Auth::Middleware;
use PayDerbyDues::Utilities::DBConnect;

my $HTML_HEADERS = [ 'Content-Type' => 'text/html' ];
my $PLAIN_HEADER = [ 'Content-Type' => 'text/plain' ];
my $SUCCESS_STATUS = 200;

my $router = Router::Simple->new();

$router->connect('/', { method => \&_index });
#$router->connect('/getenv', { method => \&_get_env });
$router->connect('/foo', { method => \&_foo });
$router->connect('/feescheduleadmin', { method => \&_fee_schedule_admin });
$router->connect('/hello', { method => \&_hello });
$router->connect('/arcady', { method => \&_arcady });
$router->connect('/test', { method => \&_test });

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
Auth::Middleware::wrap($app, authpaths => $authroutes);

sub _get_env {
	my ($match, $env) = @_;

	return [
		200,
		$HTML_HEADERS,
		Dumper(\%ENV),
	];
}

sub _test {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/test.hbs');

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($TEMPLATE, {}),
	];
}

sub _foo {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/foo.hbs');

	my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();
	my $sqlquery = "select * from company";
	my $sth = $dbh->prepare($sqlquery);
	$sth->execute();

	my $data = $sth->fetchall_arrayref; # array ref of array refs

	@$data = map {;+{bar => join(', ', @$_)}} @$data;

	my $vars = {
		rows => $data,
	};

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($TEMPLATE, $vars),
	];
}

sub _fee_schedule_admin {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/feescheduleadmin.hbs');

	my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

	my $req = Plack::Request->new($env);
	my $query_parameters = $req->query_parameters;

	my $sth = $dbh->prepare('insert into feeschedule (leagueid, name, value) values (1, ?, ?)')
		or die "failed to prepare statement: " . $dbh->errstr;

	$sth->execute($query_parameters->{name}, $query_parameters->{value})
		or die "failed to execute statement: " . $sth->errstr;

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

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		$handlebars->render_string($TEMPLATE, $vars),
	];
}



sub _hello {
	my ($match, $env) = @_;

	return [
		$SUCCESS_STATUS,
		$HTML_HEADERS,
		'in hello with match and environment: ' . Dumper([$match, $env]),
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
