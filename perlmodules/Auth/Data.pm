package Auth::Data;

use v5.20;
use feature 'signatures';

use strict;
use warnings;
no warnings 'experimental::signatures';

use Crypt::Bcrypt::Easy;

sub new($class, $dbh)
{
    bless {
        dbh => $dbh,
    }, $class;
}

sub _clean_tokens($self, $date)
{
    $self->dbh->do(qq{
        DELETE FROM tokens WHERE expires < datetime(now)
    });
}

sub _gen_token
{
    open(my $random, '<', "/dev/urandom") or die "No entropy source!";
    binmode $random;

    my $token;
    my $len = read $random, $token, 16;
    die if ($len != 16);

    close($random);
    return $token;
}

sub _set_token($self, $user, $validity)
{
    my $token = _gen_token();
    $self->dbh->do(q{
        INSERT INTO tokens (username, token, expires) VALUES (?, ?, now() + ?))
    }, {}, $user, $token, "$validity");
    
    return join("", unpack('h*', $token));
}

sub auth($self, $user, $pass, $validity = '1 day')
{
    my $dbpass = $self->dbh->selectcol_arrayref(q{SELECT password FROM users WHERE username = ?}, {}, $user);
    if (!$dbpass || @$dbpass != 1) {
        die "no such user!";
    }

    if (bcrypt->compare(text => $pass, crypt => $dbpass)) {
        return $self->_set_token($user, $validity);
    }
    else {
        return 0;
    }
}

sub check($self, $token)
{
    my $packedtoken = pack('h*', split '', $token);
    my $usernames = $self->dbh->selectcol_arrayref(q{SELECT username FROM tokens WHERE token = ? AND expires >= now()}, {}, );
    if (@$usernames == 1) {
        return $usernames->[0];
    }
    else {
        return undef;
    };
}

sub newuser($self, $username, $password)
{
    my $crypted = bcrypt->crypt(text => $password, cost => 12);

    $self->dbh->do(qq{INSERT INTO users (username, password) VALUES (?, ?)}, {},
                   $username, $crypted);    
}

1;
