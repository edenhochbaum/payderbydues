use strict;
use warnings;

use Test::Simple tests => 3;

use PayDerbyDues::Utilities::ValidateArgs;

ok( # passes
	sub {
		va({ foo => q/goodbye/, bar => q/hello/ }, ['foo'], ['bar']);
		1;
	}->()
);

ok( # fails because required buz isn't an argument
	sub {
		eval {
			va({ foo => q/goodbye/, bar => q/hello/ }, ['foo', 'buz'], ['bar']);
		};
		return $@ && 1;
	}->()
);

ok( # fails because argument buz isn't required or allowed
	sub {
		eval {
			va({ foo => q/goodbye/, buz => q/hello/ }, ['foo'], ['bar']);
		};
		return $@ && 1;
	}->()
);
