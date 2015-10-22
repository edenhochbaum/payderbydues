#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use PayDerbyDues::Utilities::Messaging;

my ($name, $email, $league, $link, $invitedby);
GetOptions('email=s', \$email,
           'name=s', \$name,
           'league=s', \$league,
           'link=s', \$link,
           'invitedby=s', \$invitedby);

PayDerbyDues::Utilities::Messaging::send_welcome_email({
    TONAME => $name,
    TOADDRESS => $email,
    TOLEAGUE => $league,
    LINK => $link,
    INVITEDBY => $invitedby,
});
