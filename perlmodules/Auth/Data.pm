package Auth::Data;

use strict;
use warnings;

use Crypt::Bcrypt::Easy;

sub new
{
    my ($class, $dbh) = @_;
    bless {
        dbh => $dbh,
    }, $class;
}

sub _clean_tokens
{
    my ($self, $date) = @_;

    $self->{dbh}->do(qq{DELETE FROM tokens WHERE expires < datetime(now)});
}

sub _gen_token
{
    open(my $random, '<', "/dev/urandom") or die "No entropy source!";
    binmode $random;

    my $token;
    my $len = read $random, $token, 16;
    die if ($len != 16);

    close($random);
    return join("", unpack('h*', $token));
}

sub _set_token
{
    my ($self, $userid, $validity) = @_;

    my $token = _gen_token();
    $self->{dbh}->do(q{
        INSERT INTO tokens (userid, token, expires) VALUES (?, ?, now() + ?)
    }, {}, $userid, $token, "$validity");
    
    return $token;
}

sub _getdbrow
{
    my ($dbh, $sql, @binds) = @_;

    my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @binds);
    return unless @$rows == 1;
    return $rows->[0];
}

sub auth
{
    my ($self, $user, $pass, $validity) = @_;
    $validity //= '1 day';

    my $userrow = _getdbrow($self->{dbh},
			    q{SELECT id, password FROM users WHERE email = ?},
			    $user);
    die "no such user $user" unless $userrow;

    if (bcrypt->compare(text => $pass, crypt => $userrow->{password})) {
        return $self->_set_token($userrow->{id}, $validity);
    }
    else {
        return 0;
    }
}

sub check
{
    my ($self, $token) = @_;

    my $usernames = $self->{dbh}->selectcol_arrayref(q{
        SELECT users.email
        FROM users, tokens
        WHERE users.id = tokens.userid
          AND token = ?
          AND expires >= now()
        }, {}, $token);

    return @$usernames == 1 ? $usernames->[0] : undef;
}

sub newuser
{
    my ($self, $email, $password) = @_;

    my $crypted = bcrypt->crypt(text => $password, cost => 12);
    $self->{dbh}->do(qq{INSERT INTO users (email, password) VALUES (?, ?)}, {},
                     $email, $crypted);
}

1;
