# PayDerbyDues::WorkFlows::Payment - controllers associated with paying dues
# Contains: league dashboard, user dashboard, user charge form, payment form
# and a smattering of utility functions to deal with money and payments.
package PayDerbyDues::WorkFlows::Payment;

use strict;
use warnings;

use PayDerbyDues::Data;
use PayDerbyDues::RequestGlobalData;

use Plack::Request;
use Plack::Response;

# league dashboard page
sub leaguedashboard {
    my ($match, $env) = @_;
    my $leagueid = $match->{leagueid};
    my $dbh = $PayDerbyDues::RequestGlobalData::dbh; 
    
    if (!PayDerbyDues::Data::check_admin(
             $dbh,
             $PayDerbyDues::RequestGlobalData::user->{USERID},
             $leagueid)) {
        return [403, [], ["You need to be an admin to see this page"]];
    }

    my $leaguemembers = PayDerbyDues::Data::get_league_members($dbh, $leagueid);
    for my $member (@$leaguemembers) {
        my $dues = PayDerbyDues::Data::get_dues($dbh, $member->{id});
        $member->{amountdue} = _format_money($dues->{due});
        $member->{chargeurl} = "/user/$member->{id}/charge"; # TODO: write R()
    }
    
    return PayDerbyDues::View::render('leaguedashboard', {
        leagueid => $leagueid,
        members => $leaguemembers,
    });
}

# parse a user-inputted amount into a Stripe amount (# of cents)
# go from "20.17" to 2017, from "17" to "1700"
sub _parse_amount {
    my $amt = shift;

    $amt =~ /^\s*(\d+)(?:\.(\d{2}))?\s*/ or die "Couldn't parse money";
    return $1 * 100 + $2
}

# go from stripe amount (of cents) to human-readable form
sub _format_money {
    my $amt = shift;

    return '$' . ($amt / 100);
}

# user charge page
sub usercharge {
    my ($match, $env) = @_;
    my $req = Plack::Request->new($env);
    my $leaguememberid = $match->{leaguememberid};
    my $paymentamount;
    my $dbh = $PayDerbyDues::RequestGlobalData::dbh; 

    my $leaguemember = PayDerbyDues::Data::get_leaguemember($dbh, $leaguememberid);
    my $leagueid = $leaguemember->{leagueid};
    
    if (!PayDerbyDues::Data::check_admin(
             $dbh,
             $PayDerbyDues::RequestGlobalData::user->{USERID},
             $leagueid)) {
        return [403, [], ["You need to be an admin to see this page"]];
    }

    if ($req->method eq 'POST') {
        my $type = $req->parameters->{type};
        my $amount = _parse_amount($req->parameters->{amount});
        my $description = $req->parameters->{description};
        $paymentamount = _format_money();

        if ($type eq 'charge') {
            PayDerbyDues::Data::add_invoiceitem($dbh, $leaguememberid, $amount,
                                                $description);
        } elsif ($type eq 'credit') {
            PayDerbyDues::Data::add_payment($dbh, $leaguememberid, $amount,
                                            $description);
        }
            
    }
    PayDerbyDues::View::render('usercharge', {
        leagueid => $leagueid,
        leaguemember => $leaguemember,
    });        
}

1;
