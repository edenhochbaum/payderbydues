#!/usr/bin/env perl

use strict;
use warnings;

use PayDerbyDues::Utilities::DBConnect;

my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH;

# set up the interval table, used to calculate whether customer has been
# billed recently enough
my $sth = $dbh->prepare('insert into interval (id, interval, unit) values (?,?)');
$sth->execute(0, '1000 years', undef);
$sth->execute(1, '1 year', 'year');
$sth->execute(2, '1 month', 'month');
$sth->execute(3, '1 week', 'week');
$sth->execute(4, '1 day', 'day');

$sth = $dbh->prepare('insert into role (id, name) values (?, ?)');
$sth->execute(0, 'League admin');
