package PayDerbyDues::DerbyDues;

use strict;
use warnings;

use Net::Stripe;
use Plack::Request;

#use View;

sub table_hash
{
    my ($dbh, $sql, @binds) = @_;

    $dbh->selectall_arrayref($sql, { Slice => {} }, @binds);
}

sub get_member
{
    my ($dbh, $username, $leaguename) = @_;

    return @{table_hash($dbh, q{
        select member.username, member.id, member.id, member.realname, member.derbyname,
               member.dob, member.active, leaguemember.memberclassid, leaguemember.adminlevel, league.name leaguename
        from member, leaguemember, league
        where member.id = leaguemember.memberid and member.username = ? and
              leaguemember.leagueid = league.id}, $username) || [] }[0];
}

sub home
{
    my ($dbh, $req) = @_;

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

    if ($memberrec->{adminlevel}) {
        # TODO: link to league summary
    }
    return View::render('views/paymentform.hbs', {
        publishable_key => 'pk_test_oLIm1R9BjDo6ymTGBemqbK1',
        leaguename => $memberrec->{leaguename},
        username => $memberrec->{derbyname},
        amountowed => '$42.00',
        paid => $paid,
        acctinfo => {
            name => $memberrec->{realname}
        }
    });
}

1;
