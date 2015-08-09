package PayDerbyDues::WorkFlows::All;

use strict;
use warnings;

use File::Slurp;
use Text::Handlebars;

use PayDerbyDues::RequestGlobalData;

my $LAYOUT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/layout.hbs');

# each takes in ($match, $env) and returns $body #

sub rollout {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/rollout.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return $handlebars->render_string($LAYOUT, {
			title => 'rollout',
			rollout => 1,
			container => $container_contents,
	}),
}

sub who {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/who.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return $handlebars->render_string($LAYOUT, {
		title => 'who',
		who => 1,
		container => $container_contents,
	});
}

sub email_ed {
	my ($match, $env) = @_;

	my $args = +{
		TOADDRESS => q/eden.hochbaum@gmail.com/,
		TONAME => q/eden/,
		TOLEAGUE => q/Bar League/,
	};

	require PayDerbyDues::Utilities::Messaging;
	my $r = PayDerbyDues::Utilities::Messaging::SendWelcomeEmail($args);

	require Data::Dumper;

	Data::Dumper::Dumper($r),
}

sub fee_schedule_admin {
	my ($match, $env) = @_;

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

	return $handlebars->render_string($LAYOUT, {
		title => 'fee schedule admin',
		feescheduleadmin => 1,
		container => $container_contents,
	});
}

sub index {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();
	my $TEMPLATE = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/index.hbs');

	return $handlebars->render_string($TEMPLATE, {}),
}

sub learnmore {
	my ($match, $env) = @_;

	my $handlebars = Text::Handlebars->new();

	my $CONTENT = File::Slurp::read_file('/home/ec2-user/payderbydues/www/handlebarstemplates/learnmore.hbs');
	my $container_contents = $handlebars->render_string($CONTENT, {});

	return $handlebars->render_string($LAYOUT, {
		title => 'learnmore',
		learnmore => 1,
		container => $container_contents,
	});
}

1;
