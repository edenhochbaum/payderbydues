package PayDerbyDues::Auth::Middleware;

use strict;
use warnings;

use Plack::Request;
use Plack::Response;
use Router::Simple;

use PayDerbyDues::Auth::Data;
use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::GlobalRouter;

my $router = PayDerbyDues::GlobalRouter::_GetGlobalRouter();

my %defconfig = (
    unauthredirect => '/',
    timeout_sec => 30 * 60,
);

sub wrap {
    my ($app, %userconfig) = @_;

    my %config = (%defconfig, %userconfig);

    my $dbh = $PayDerbyDues::RequestGlobalData::dbh;

    return sub {
        my $env = shift;

	my $p = $router->match($env) || {};
	if ($p->{requires_auth}) {
		$PayDerbyDues::RequestGlobalData::userid = check_auth($app, $env, $dbh, %config);

		unless ($PayDerbyDues::RequestGlobalData::userid) {
			my $res = Plack::Response->new;
			$res->redirect($config{unauthredirect});

			warn "Unauthenticated user detected";
			return $res->finalize;
		}

    		warn "Authenticated as [$PayDerbyDues::RequestGlobalData::userid]";
	}

    	return $app->($env);
    }
}

sub check_auth
{
    my ($app, $env, $dbh, %config) = @_;

    my $req = Plack::Request->new($env);
    my $auth = PayDerbyDues::Auth::Data->new($dbh);
    my $userid = $auth->check($req->cookies->{s});

    if (!$userid) {
        my $res = Plack::Response->new;
        $res->redirect($config{unauthredirect});

        return $res->finalize;
    }

    return $app->($env);
}

1;
