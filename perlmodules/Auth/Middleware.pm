package Auth::Middleware;

use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Router::Simple;

use PayDerbyDues::Utilities::DBConnect;
use Auth::Data;

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
    
    my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();
    
    return sub {
        my $env = shift;

	if (my $p = $router->match($env)) {
	    my $req = Plack::Request->new($env);
	    return $p->{func}->($req, $dbh, %config);
	} elsif ($config{authpaths} && $config{authpaths}->match($env)) {
	    return check_auth($app, $env, $dbh, %config);
        } else {
            return $app->($env);
        }
    };
}

sub check_auth
{
    my ($app, $env, $dbh, %config) = @_;

    my $req = Plack::Request->new($env);
    my $auth = Auth::Data->new($dbh);
    my $username = $auth->check($req->cookies->{s});

    if (!$username) {
        my $res = Plack::Response->new;
        $res->redirect($config{unauthredirect});

	warn "Unauthenticated user detected";
        return $res->finalize;
    }

    warn "Authenticated as $username";
    local $env->{_auth_username} = $username;
    return $app->($env);
}

sub login
{
    my ($req, $dbh, %config) = @_;

    my $auth = Auth::Data->new($dbh);
    my $user = $req->parameters->{email};
    my $pass = $req->parameters->{password};
    my $token = $auth->auth($user, $pass);
    my $res = Plack::Response->new;

    if (!$token) {
        $res->redirect($config{unauthredirect});
        $res->cookies->{s} = '';

        return $res->finalize;
    }
    else {
        my $redirect = _redirect_target($req, %config);
        $res->redirect($redirect);
        $res->cookies->{s} = $token;

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
