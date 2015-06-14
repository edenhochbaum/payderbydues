package Auth::Middleware;

use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Router::Simple;

my %defconfig = (
    unauthredirect => '/',
    timeout_sec => 30 * 60,
    );

sub wrap
{
    my ($app, %userconfig) = @_;

    my %config = (%defconfig, %userconfig);
    my $router = Router::Simple->new();
    $router->connect('/login', { func => \&login }, { method => 'POST' });
    $router->connect('/newuser', { func => \&newuser }, { method => 'POST' });

    return sub {
        my $env = shift;

        require PathDerbyDues::Utilities::DBConnect;
	my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

	if (my $p = $router->match($env)) {
	    my $req = Plack::Request->new($env);
	    return $p->{func}->($req, $dbh, %config);
	} elsif (!$config{authpaths} || $config{authpaths}->match($env)) {
	    return dispatch($app, $env, $dbh, %config);
        } else {
            return $app->($env);
        }
    };
}

sub dispatch
{
    my ($app, $env, $dbh, %config) = @_;

    my $req = Plack::Request->new($env);
    my $s = $req->cookies->{s};
    my $auth = Auth::Data->new($dbh);
    my $username = $auth->check($s);

    if (!$username) {
        my $res = Plack::Response->new;
        $res->redirect($config{unauthredirect});

        return $res->finalize;
    }

    local $env->{_auth_username} = $username;
    return $app->($env);
}

sub login
{
    my ($req, $dbh, %config) = @_;

    my $auth = Auth::Data->new($dbh);
    my $user = $req->query_parameters->{username};
    my $pass = $req->query_parameters->{password};
    my $token = $auth->auth($user, $pass);
    my $res = Plack::Response->new;

    if (!$token) {
        $res->redirect('/login?badpassword=1');
        $res->cookies->{s} = '';

        return $res->finalize;
    }
    else {
        my $redirect = _redirect_target($req, %config);
        $res->redirect($redirect);
        $res->cookies->{s} = {
            value => $token,
            expires => time + $config{timeout_sec},
            secure => 1,
        };
        return $res->finalize;
    }
}

sub _redirect_target
{
    my ($req, %config) = @_;
    return $req->query_parameters->{redirect_to} || $config{unauthredirect};
}

sub newuser
{
    my ($req, $dbh, %config) = @_;

    if ($req->method eq 'POST') {
        my $auth = Auth::Data->new($dbh);
        my $params = $req->body_parameters();
        my $status = $auth->newuser($params->{username}, $params->{password});
        my $res = Plack::Response->new;
        $res->redirect($config{newuserredirect} || '/');

        return $res->finalize;
    }
}

1;
