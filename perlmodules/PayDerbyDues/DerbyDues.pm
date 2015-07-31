package PayDerbyDues::DerbyDues;

use strict;
use warnings;

use Net::Stripe;
use Plack::Request;

use PayDerbyDues::Utilities::DBConnect;
use PayDerbyDues::View;

sub table_hash
{
    my ($dbh, $sql, @binds) = @_;

    $dbh->selectall_arrayref($sql, { Slice => {} }, @binds);
}

sub get_member
{
    my ($dbh, $userid, $leaguename) = @_;

    return @{table_hash($dbh, q{
        select member.legalname,
               member.derbyname,
               league.name leaguename
        from member, leaguemember, league
        where member.id = leaguemember.memberid and member.userid = ? and
              leaguemember.leagueid = league.id}, $userid) || [] }[0];
}

sub home
{
    my ($dbh, $req) = @_;

    my $paid = 0;
    if ($req->method eq 'POST') {
        my $postparams = $req->body_parameters();
        my $stripe = Net::Stripe->new(api_key => $ENV{STRIPE_TEST_KEY});
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
    my $userid = 3;#'bob@rodney.com';#$req->env->{_auth_username};
    my $memberrec = get_member($dbh, $userid);
    # TODO: amount owed

    if ($memberrec->{adminlevel}) {
        # TODO: link to league summary
    }

    my $handlebars = Text::Handlebars->new();

    return PayDerbyDues::View::render('paymentform.hbs', {
        publishable_key => $ENV{STRIPE_TEST_PUBKEY},
        leaguename => $memberrec->{leaguename},
        username => $memberrec->{derbyname},
        amountowed => '$42.00',
        paid => $paid,
        acctinfo => {
            name => $memberrec->{realname}
        }
    });
}

sub request
{
    my $env = shift;
    my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();
    my $request = Plack::Request->new($env);

    return home($dbh, $request);

}

1;
