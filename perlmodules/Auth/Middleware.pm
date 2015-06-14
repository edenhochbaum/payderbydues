package Auth::Middleware;

use v5.20;
use feature 'signatures';
use strict;
use warnings;
no warnings 'experimental::signatures';

use Plack::Request;
use Plack::Response;

my %routes;

my %defconfig = (
    unauthredirect => '/',
    timeout_sec => 30 * 60,
    );

sub dispatch($app, $env, $dbh, %config)
{
    my $req = Plack::Request->new($env);
    if (exists $routes{$req->path}) {
        return $routes{$req->path}->($req, $dbh, %config);
    } elsif (exists $config{noauthpaths}->{$req->path}) {
        return $app->($env);
    } else {
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
}

sub login($req, $dbh, %config)
{
    if ($req->method eq 'POST') {
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
    else {
        my %args;
        if (exists $req->query_parameters->{badpassword}) {
            $args{badpassword} = 1;
        }
        my $body = Auth::View->login_page(%args);
        return [200, ['Content-Type' => 'text/html'], $body ];
    }
}

sub _redirect_target($req, %config)
{
    return $req->query_parameters->{redirect_to} || $config{unauthredirect};
}

sub newuser($req, $dbh, %config)
{
    if ($req->method eq 'POST') {
        my $auth = Auth::Data->new($dbh);
        my $params = $req->body_parameters();
        my $status = $auth->newuser($params->{username}, $params->{password});
        my $res = Plack::Response->new;
        $res->redirect($config{newuserredirect} || '/');
            
        return $res->finalize;
    } else {
        return [405, [], 'This is a POST-only URL'];
    }
}

sub wrap($app, %userconfig)
{
    my %config = (%defconfig, %userconfig);
    
    return sub {
        my $env = shift;

        require PathDerbyDues::Utilities::DBConnect;
	my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();
        
        dispatch($app, $env, $dbh, %config);
    };
}

%routes = (
    '/login' => \&login,
    '/confirm' => \&confirm,
    '/newuser' => \&newuser,
);


1;
