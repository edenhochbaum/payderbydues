package PayDerbyDues::GlobalRouter;

use strict;
use warnings;

use PayDerbyDues::WorkFlows::All;
use PayDerbyDues::DerbyDues;

{
my $GlobalRouter = '';

sub _GetGlobalRouter {
	return $GlobalRouter if ($GlobalRouter);

	$GlobalRouter = Router::Simple->new();

	# REQUIRE AUTHORIZATION #
	$GlobalRouter->connect('/feescheduleadmin', { func => \&PayDerbyDues::WorkFlows::All::fee_schedule_admin, requires_auth => 1, dont_finalize => 1 });
	$GlobalRouter->connect('/emailed', { func => \&PayDerbyDues::WorkFlows::All::email_ed, requires_auth => 1, dont_finalize => 1 });
	$GlobalRouter->connect('/arcady', { func => \&PayDerbyDues::WorkFlows::All::arcady, requires_auth => 1, dont_finalize => 1 });

	# OPEN TO THE WORLD #
	$GlobalRouter->connect('/rollout', { func => \&PayDerbyDues::WorkFlows::All::rollout, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/who', { func => \&PayDerbyDues::WorkFlows::All::who, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/learnmore', { func => \&PayDerbyDues::WorkFlows::All::learnmore, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/', { func => \&PayDerbyDues::WorkFlows::All::index, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/login', { func => \&PayDerbyDues::WorkFlows::All::login, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/newuser', { func => \&PayDerbyDues::WorkFlows::All::newuser, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/badlogin', { func => \&PayDerbyDues::WorkFlows::All::badlogin, requires_auth => '', dont_finalize => 1 });
	$GlobalRouter->connect('/goodlogin', { func => \&PayDerbyDues::WorkFlows::All::goodlogin, requires_auth => '', dont_finalize => 1 });

	return $GlobalRouter;
}
}

1;
