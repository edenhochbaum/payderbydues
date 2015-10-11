package PayDerbyDues::Auth::Data;

use strict;
use warnings;

use Crypt::Bcrypt::Easy;

sub new
{
    my ($class, $dbh) = @_;

    # TODO: remove this unnec db hit
    die 'bad dbh' unless ($dbh->ping);

    bless {
        dbh => $dbh,
    }, $class;
}

# just deletes all tokens that have expired
sub _clean_tokens
{
    my ($self) = @_;

    $self->{dbh}->do(qq{DELETE FROM token WHERE expires < datetime(now)});
}

# token is just 16 bytes streamed from /dev/urandom returned in hex (so 32 hex digits)
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

# generates a token
# adds token to token table for $userid, setting expiration for postgres system now() + $validity
# returns the generated token
#
# see: http://www.postgresql.org/docs/8.0/static/functions-datetime.html
sub _set_token
{
    my ($self, $userid, $validity) = @_;

    my $token = _gen_token();
    $self->{dbh}->do(q{
        INSERT INTO token (memberid, value, expires) VALUES (?, ?, now() + ?)
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

# takes a $user email address, a $pass, and [optional] $validity interval
# throws exception on unrecognized $user
# compares crypto hash of $pass to stored crypto hash of true password
# 	if failed match, returns 0
# 	if match, generates a new token for the user, and returns it
sub auth
{
    my ($self, $user, $pass, $validity) = @_;
    $validity //= '1 day';

    my $userrow = _getdbrow($self->{dbh},
			    q{SELECT id, password FROM member WHERE email = ?},
			    $user);
    die "no such user $user" unless $userrow;

    if (bcrypt->compare(text => $pass, crypt => $userrow->{password})) {
        return $self->_set_token($userrow->{id}, $validity);
    }
    else {
        return 0;
    }
}

# returns user (email address) corresponding to valid token
# returns undef if token not recognized, or token expired
sub check
{
    my ($self, $token) = @_;

    my $userids = $self->{dbh}->selectcol_arrayref(q{
        SELECT member.id
        FROM member, token
        WHERE member.id = token.memberid
          AND value = ?
          AND expires >= now()
        }, {}, $token);

    return @$userids == 1 ? $userids->[0] : undef;
}

# adds a new user to member table
sub newuser
{
    my ($self, $email, $password) = @_;

    my $crypted = bcrypt->crypt(text => $password, cost => 12);
    $self->{dbh}->do(qq{INSERT INTO member (email, password) VALUES (?, ?)}, {},
                     $email, $crypted);
}

sub logout
{
    my ($self, $token) = @_;

    $self->{dbh}->do(qq{DELETE FROM token WHERE value = ?}, {}, $token);
}
1;
