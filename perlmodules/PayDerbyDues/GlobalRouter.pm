package PayDerbyDues::GlobalRouter;

use strict;
use warnings;

use PayDerbyDues::WorkFlows::All;
use PayDerbyDues::DerbyDues;
use PayDerbyDues::Auth::Middleware; # ugh

{
my $GlobalRouter = '';

sub _GetGlobalRouter {
	return $GlobalRouter if ($GlobalRouter);

	$GlobalRouter = Router::Simple->new();

	# all these require authorization
	$GlobalRouter->connect('/feescheduleadmin', { func => \&PayDerbyDues::WorkFlows::All::fee_schedule_admin, requires_auth => 1 });
	$GlobalRouter->connect('/emailed', { func => \&PayDerbyDues::WorkFlows::All::email_ed, requires_auth => 1 });
	$GlobalRouter->connect('/arcady', { func => \&_arcady, requires_auth => 1 });

# these are open to the world
	$GlobalRouter->connect('/rollout', { func => \&PayDerbyDues::WorkFlows::All::rollout, requires_auth => '' });
	$GlobalRouter->connect('/who', { func => \&PayDerbyDues::WorkFlows::All::who, requires_auth => '' });
	$GlobalRouter->connect('/learnmore', { func => \&PayDerbyDues::WorkFlows::All::learnmore, requires_auth => '' });
	$GlobalRouter->connect('/', { func => \&PayDerbyDues::WorkFlows::All::index, requires_auth => '' });
	$GlobalRouter->connect('/login', { func => \&PayDerbyDues::WorkFlows::All::login, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/newuser', { func => \&PayDerbyDues::WorkFlows::All::newuser, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/badlogin', { func => \&PayDerbyDues::WorkFlows::All::badlogin, requires_auth => '' });
	$GlobalRouter->connect('/goodlogin', { func => \&PayDerbyDues::WorkFlows::All::goodlogin, requires_auth => '' });
}
}

sub _arcady {
	my ($match, $env) = @_;

	return PayDerbyDues::DerbyDues::request($env);
}

1;
