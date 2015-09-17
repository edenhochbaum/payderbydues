#!/usr/bin/perl
use strict;
use warnings;

use Crypt::Bcrypt::Easy;
use Getopt::Long;
use MIME::Base64;

use PayDerbyDues::Utilities::DBConnect;

my ($email, $password);
GetOptions('email=s', \$email,
           'password=s', \$password);

if (!$email) {
    print 'Usage: pwreset.pl --email foo@bar.com [--password newpassword]';
    exit 1;
}

my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

my $user = $dbh->selectall_arrayref('select id, email, password from users where email = ?', { Slice => {} }, $email);

if (!$password) {
    my $bytes;
    open(my $random, '<', '/dev/urandom');
    binmode($random);
    read $random, $bytes, 6;
    $password = encode_base64($bytes);
}


my $crypted = bcrypt->crypt( text => $password, cost => 12);

if (!@$user) {
    print STDERR "User $email not found";
    exit 1;
} else {
    $dbh->do(q{update users set password = ? where email = ?}, {},
             $crypted, $email);
}

print "User $email password updated to $password\n";
