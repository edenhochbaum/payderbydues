package PayDerbyDues::Auth::Middleware;

use strict;
use warnings;

use Plack::Request;

use PayDerbyDues::Auth::Data;

# just returns a userid, or undef if not authenticated
sub check_auth
{
    my ($env, $dbh) = @_;

    my $req = Plack::Request->new($env);
    my $auth = PayDerbyDues::Auth::Data->new($dbh);
    my $userid = $auth->check($req->cookies->{s});

    return $userid;
}

1;
