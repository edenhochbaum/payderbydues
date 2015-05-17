package DerbyDues;

use v5.20;
use feature 'signatures';
use strict;
use warnings;
no warnings 'experimental::signatures';

use DBI;
use File::Slurp::Tiny;
use Plack::Request;
use Net::Stripe;
use View;

sub htmlhash($hash) {
    my $ret = '<dl>';
    for my $key (sort keys %$hash) {
	$ret .= "<dt>$key</dt><dd>$hash->{$key}</dd>\n"

    }
    return $ret . "</dl>\n";
}

sub table_hash($dbh, $sql, @binds)
{
    $dbh->selectall_arrayref($sql, { Slice => {} }, @binds);
}

sub get_member($dbh, $username, $leaguename = undef)
{
    return @{table_hash($dbh, q{
        select member.username, member.id, member.id, member.realname, member.derbyname,
               member.dob, member.active, leaguemember.memberclassid, leaguemember.adminlevel, league.name leaguename
        from member, leaguemember, league
        where member.id = leaguemember.memberid and member.username = ? and
              leaguemember.leagueid = league.id}, $username) || [] }[0];
}

sub get_ledger($dbh, $username)
{

}

sub get_league_summary($dbh, $leagueid)
{
    #($dbh, 'select -sum(amount), memberid from ledger where leagueid = ? group by memberid')->[0];
}

sub home($dbh, $req)
{
    my $paid = 0;
    if ($req->method eq 'POST') {
        my $postparams = $req->body_parameters();
        my $stripe = Net::Stripe->new(api_key => $ENV{STRIPE_SECRET_KEY});
        my $token = $postparams->{stripeToken};
        my $charge = $stripe->post_charge(
            amount => 4200,
            currency => 'USD', # TODO: fetch from league
            card => $token,
            description => 'Derby dues',
            # application_fee => ...,
        );
        if ($charge->paid) {
            $paid = '$42.00';
        }
    }
    my $username = 'bob@rodney.com';#$req->env->{_auth_username};
    my $memberrec = get_member($dbh, $username);
    # TODO: amount owed

    my $ledger = get_ledger($dbh, $username);
    
    if ($memberrec->{adminlevel}) {
        # TODO: link to league summary
    }
    return View::render('views/paymentform.hbs', {
        publishable_key => 'pk_test_oLIm1R9BjDo6ymTGBemqbK1A',
        leaguename => $memberrec->{leaguename},
        username => $memberrec->{derbyname},
        amountowed => '$42.00',
        paid => $paid,
        acctinfo => {
            name => $memberrec->{realname}
        }
    });
}

my %routes = (
    '/' => \&home,
    '/home' => \&home,
    );


sub dbconnect
{
    my $filename = 'data.db';
    my $needtocreateschema;
    if (!-e $filename) {
        $needtocreateschema = 1;
    }

    my $dbh = DBI->connect("dbi:SQLite:$filename");
    if ($needtocreateschema) {
        my $schema = File::Slurp::Tiny::read_file('schema.sql');
        eval {
            $dbh->do($schema);
        };
        if ($@) {
            unlink $filename;
            die "Could not create schema: $@";
        }
    }
    return $dbh;

}

sub request($env)
{
    my $req = Plack::Request->new($env);

    my $dbh = dbconnect();
    my $route = $routes{$req->path};
    die [404, "bad route"] unless $route;

    return $route->($dbh, $req);
}


1;
