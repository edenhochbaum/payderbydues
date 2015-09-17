#!/usr/bin/env/perl
use strict;
use warnings;

use Getopt::Long;
use PayDerbyDues::Utilities::DBConnect;

my ($password, $name, $email, $league);

GetOptions('league=s' => \$league,
           'email=s' => \$email,
           'password=s' => \$password,
           'name=s' => \$name);

if (!$email) {
    print 'Usage: adduser.pl --email email [--league id] [--name name] [--password pw]\n';
    exit 1;
}
my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH;
my $sth = $dbh->prepare('insert into users (email, legalname) values (?, ?) returning id');
$sth->execute($email, $name);
my $userid = $sth->fetch()->[0];

system('./pwreset.pl', '--email', $email,
       $password ? ('--password', $password) : ());

if ($league) {
    $dbh->execute('insert into leagemember (leagueid, userid) values (?, ?)',
                  $league, $userid);
}

print "Created user $userid ($email)\n";
