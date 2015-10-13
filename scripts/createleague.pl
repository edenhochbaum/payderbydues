#!/usr/bin/env perl

use strict;
use warnings;

use PayDerbyDues::Utilities::DBConnect;
use DBI;
use Getopt::Long;

my ($leaguename, $adminemail);

GetOptions('leaguename=s' => \$leaguename,
           'adminemail=s' => \$adminemail);

if (!$adminemail || !$leaguename) {
    print 'Usage: createleague.pl --leaguename "Toaster City" --adminemail bob@example.com\n';
    exit 1;
}

my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH;

my $admins = $dbh->selectcol_arrayref('select id from member where email = ?',
                                      {}, $adminemail);
my $userid;

if (@$admins) {
    $userid = $admins->[0];
} else {
    print "User with email $adminemail not found in database\n";
    exit 2;
}

my $sth = $dbh->prepare(q{insert into league (name) values (?) returning id});
$sth->execute($leaguename);
my $leagueid = $sth->fetch()->[0];

$sth = $dbh->prepare(q{insert into leaguemember (leagueid, memberid)
                  values (?, ?) returning id});
$sth->execute($leagueid, $userid);
my $leaguememberid = $sth->fetch()->[0];
$dbh->do(q{insert into leaguememberrole (leaguememberid, roleid)
           values (?, 0)}, {}, $leaguememberid);
