package PayDerbyDues::WorkFlows::All;

use strict;
use warnings;

use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::Auth::Data;
use PayDerbyDues::Constants;
use Plack::Request;
use Plack::Response;

# each takes in ($match, $env) and returns $body #

sub rollout {
	PayDerbyDues::View::render_layout('rollout', {
		title => 'rollout',
		rollout => 1,
		loggedinas => $PayDerbyDues::RequestGlobalData::userid,
	});
}

sub who {
	PayDerbyDues::View::render_layout('who', {
		title => 'who',
		who => 1,
		loggedinas => $PayDerbyDues::RequestGlobalData::userid,
	});
}

sub badlogin {
	my ($match, $env) = @_;

	# TODO: should this really be success?
	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body('bad login!');
	return $res->finalize;
}

sub goodlogin {
	my ($match, $env) = @_;

	# TODO: should this really be success?
	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body('good login, but unknown redirect!');
	return $res->finalize;
}

sub email_ed {
	my ($match, $env) = @_;

	require PayDerbyDues::Utilities::Messaging;
	require Data::Dumper;

	my $args = +{
		TOADDRESS => q/eden.hochbaum@gmail.com/,
		TONAME => q/eden/,
		TOLEAGUE => q/Bar League/,
	};

	my $r = PayDerbyDues::Utilities::Messaging::SendWelcomeEmail($args);

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/plain');

	$res->body(Data::Dumper::Dumper($r));
	return $res->finalize;
}

sub fee_schedule_admin {
	my ($match, $env) = @_;

	my $dbh = $PayDerbyDues::RequestGlobalData::dbh;

	require Plack::Request;
	my $req = Plack::Request->new($env);
	my $parameters = $req->parameters;

	if ($parameters->{nextoperation} eq 'Add') {
		my $sth = $dbh->prepare('insert into feeschedule (leagueid, name, value) values (1, ?, ?)')
			or die "failed to prepare statement: " . $dbh->errstr;

		$sth->execute($parameters->{name}, $parameters->{value})
			or die "failed to execute statement: " . $sth->errstr;
	}

	my $sqlquery = "select * from feeschedule";
	my $sth = $dbh->prepare($sqlquery);
	$sth->execute();

	my $data = $sth->fetchall_arrayref; # array ref of array refs

	@$data = map {;
		my $tmp = +{};
		@{$tmp}{qw(id name leagueid value)} = @{$_};
		$tmp;
	} @$data;

	return PayDerbyDues::View::render_layout('feescheduleadmin', {
		title => 'fee schedule admin',
		feescheduleadmin => 1,
		loggedinas => $PayDerbyDues::RequestGlobalData::userid,
	}, {
		rows => $data,
	});
}

sub index {
	my ($match, $env) = @_;

	my $userid = $PayDerbyDues::RequestGlobalData::userid;
	my $loggedin = $userid ? 1 : 0;
	my $userinfo = { realname => 'foo', email => 'bar' };
	#my $userinfo = get_user($userid);

	PayDerbyDues::View::render('index', {
	    realname => $userinfo->{realname},
	    email => $userinfo->{email},
	    loggedin => $loggedin,
	});
}

sub learnmore {
	PayDerbyDues::View::render_layout('learnmore', {
		title => 'learnmore',
		learnmore => 1,
		loggedinas => $PayDerbyDues::RequestGlobalData::userid,
	});
}

sub login {
    my ($match, $env) = @_;

    my $req = Plack::Request->new($env);

    my %config = (
	unknownredirect => '/',
	badloginredirect => '/badlogin',
    );

    my $dbh = $PayDerbyDues::RequestGlobalData::dbh;

    my $auth = PayDerbyDues::Auth::Data->new($dbh);
    my $user = $req->parameters->{email};
    my $pass = $req->parameters->{password};
    my $token = $auth->auth($user, $pass);
    my $res = Plack::Response->new;

    if (!$token) {
	$res->redirect($config{badloginredirect});
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

sub logout {
    my ($match, $env) = @_;

    my $req = Plack::Request->new($env);

    my $dbh = $PayDerbyDues::RequestGlobalData::dbh;
    my $auth = PayDerbyDues::Auth::Data->new($dbh);
    my $token = $req->cookies->{s};
    $auth->logout($token);

    my $res = Plack::Response->new();
    $res->cookies->{s} = '';
    $res->redirect('/');

    return $res->finalize();
}

sub _redirect_target
{
    my ($req, %config) = @_;
    return $req->query_parameters->{redirect_to} || $config{unknownredirect};
}

sub newuser {
    my ($match, $env) = @_;

    my %config = (
    	newuserredirect => '/userdashboard',
    );

    my $dbh = $PayDerbyDues::RequestGlobalData::dbh;

    my $req = Plack::Request->new($env);
    my $parameters = $req->parameters;

	if ($parameters->{nextoperation}) {
		my ($username, $password) = ($parameters->{inputEmail}, $parameters->{inputPassword});

		my $auth = PayDerbyDues::Auth::Data->new($dbh);
		my $status = $auth->newuser($username, $password);

		my $res = Plack::Response->new;
		$res->redirect($config{newuserredirect} || '/');

		return $res->finalize;
	}
	else {
		return PayDerbyDues::View::render_layout('newuser', {
			message => 'lorem ipsum',
			title => 'new user',
			newuser => 1,
			loggedinas => $PayDerbyDues::RequestGlobalData::userid,
		});
	}
}

sub userdashboard {
	PayDerbyDues::View::render_layout('userdashboard', {
		title => 'userdashboard',
		userdashboard => 1,
		loggedinas => $PayDerbyDues::RequestGlobalData::userid,
	}, {
		userid => $PayDerbyDues::RequestGlobalData::userid,
	});
}

sub arcady {
	my ($match, $env) = @_;

	require PayDerbyDues::DerbyDues;
	return PayDerbyDues::DerbyDues::request($env);
}

1;
