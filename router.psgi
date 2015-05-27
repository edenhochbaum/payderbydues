use Router::Simple;
use Text::Handlebars;
use Data::Dumper;
use Utilities::DBConnect;

my $router = Router::Simple->new();

$router->connect('/', { method => \&_index });
$router->connect('/getenv', { method => \&_get_env });
$router->connect('/foo', { method => \&_foo });
$router->connect('/hello', { method => \&_hello });

my $app = sub {
	my $env = shift;

	if (my $match = $router->match($env)) {
		return [
			200,
			[ 'Content-Type' => 'text/html' ], 
			$match->{method}->($match, $env),
		];
	}

	return [
		404,
		[],
		['not found'],
	];
};

sub _get_env {
	my ($match, $env) = @_;

	print Dumper(\%ENV);
}

sub _foo {
	my ($match, $env) = @_;

	require File::Slurp;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/handlebarstemplates/foo.handlebars');

	my $dbh = Utilities::DBConnect::GetDBH();
	my $sqlquery = "select * from company";
	my $sth = $dbh->prepare($sqlquery);
	$sth->execute();

	my $data = $sth->fetchall_arrayref; # array ref of array refs

	@$data = map {;+{bar => join(', ', @$_)}} @$data;

	my $vars = {
		rows => $data,
	};

	return [$handlebars->render_string($TEMPLATE, $vars)];
}


sub _hello {
	my ($match, $env) = @_;

	return [ 'in hello with match and environment: ' . Dumper([$match, $env])],
}

sub _index {
	my ($match, $env) = @_;

	return [ q{<font color="green">Hello World payderbydues</font>} ],
}
