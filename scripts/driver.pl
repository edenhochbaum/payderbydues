use strict;
use warnings;

BEGIN {
	$\ = "\n";
	push(@INC, "$ENV{HOME}/source/payderbydues/perlmodules/");
}

use Utilities::DBConnect;
use List::Util;
use DBD::Pg;

Utilities::DBConnect::HelloWorld();

print join("\n", @INC);

my $val = List::Util::max (5, 10, 100, 45);

print $val;
