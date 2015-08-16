package PayDerbyDues::WorkFlows::All;

use strict;
use warnings;

use File::Slurp;
use Text::Handlebars;

use PayDerbyDues::RequestGlobalData;
use PayDerbyDues::Auth::Data;
use PayDerbyDues::Constants;
use Plack::Response;

my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

# each takes in ($match, $env) and returns $body #

sub rollout {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/rollout.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body($handlebars->render_string($LAYOUT, {
		title => 'rollout',
		rollout => 1,
		container => $container_contents,
	}));

	return $res->finalize;
}

sub who {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/who.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body($handlebars->render_string($LAYOUT, {
		title => 'who',
		who => 1,
		container => $container_contents,
	}));

	return $res->finalize;
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

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	my $handlebars = Text::Handlebars->new();

	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/feescheduleadmin.hbs');

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

	my $vars = {
		rows => $data,
	};

	my $container_contents = $handlebars->render_string($TEMPLATE, $vars);

	$res->body($handlebars->render_string($LAYOUT, {
		title => 'fee schedule admin',
		feescheduleadmin => 1,
		container => $container_contents,
	}));

	return $res->finalize;
}

sub index {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/index.hbs');

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body($handlebars->render_string($TEMPLATE, {}));
	return $res->finalize;
}

sub learnmore {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/learnmore.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body($handlebars->render_string($LAYOUT, {
		title => 'learnmore',
		learnmore => 1,
		container => $container_contents,
	}));

	return $res->finalize;
}

sub login {
    my ($match, $env) = @_;

    my $req = Plack::Request->new($env);

    my %config = (
	unknownredirect => '/goodlogin',
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
		my $handlebars = Text::Handlebars->new();

		my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/newuser.hbs');
		my $container_contents = $handlebars->render_string($CONTENT, {
			message => 'lorem ipsum',
		});

		my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
		$res->content_type('text/html');

		$res->body($handlebars->render_string($LAYOUT, {
			title => 'new user',
			newuser => 1,
			container => $container_contents,
		}));

		return $res->finalize;
	}
}

sub userdashboard {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/userdashboard.hbs');

	my $container_contents = $handlebars->render_string($CONTENT, {
		userid => $PayDerbyDues::RequestGlobalData::userid,
	});

	my $res = Plack::Response->new($PayDerbyDues::Constants::HTTP_SUCCESS_STATUS);
	$res->content_type('text/html');

	$res->body($handlebars->render_string($LAYOUT, {
		title => 'learnmore',
		userdashboard => 1,
		container => $container_contents,
	}));

	return $res->finalize;

}

sub arcady {
	my ($match, $env) = @_;

	require PayDerbyDues::DerbyDues;
	return PayDerbyDues::DerbyDues::request($env);
}


1;
