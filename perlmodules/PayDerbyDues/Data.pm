# PayDerbyDues::Data - database access for PDD.
# This file contains functions to read from and save to the database.
# By convention, all functions in this file take a database handle
# as the first argument.

package PayDerbyDues::Data;

# get_dues($dbh, $leaguememberid) -> { 'overdue' => int , 'due' => int }
sub get_dues {
    my ($dbh, $leaguememberid) = @_;

    my ($pastdue) = $dbh->selectrow_array(
        q{select coalesce(sum(amount),0)
          from invoiceitem
          where leaguememberid = ? and duedate < date 'today'},
        {}, $leaguememberid);
    my ($due) = $dbh->selectrow_array(
        q{select coalesce(sum(amount),0)
          from invoiceitem
          where leaguememberid = ? and duedate >= date 'today'},
        {}, $leaguememberid);
    my ($paid) = $dbh->selectrow_array(
        q{select coalesce(sum(amount),0)
          from payment
          where leaguememberid = ?},
        {}, $leaguememberid);

    my $overdue = $pastdue - $paid > 0 ? $pastdue - $paid : 0;
    return {
        overdue => $overdue,
        due => $pastdue + $due - $paid,
    };
}

# get_league_members($dbh, $leagueid) -> [ { ... } ]
# Get all the league members of a given league
# returns an array of hashes, each containing:
#   id => the leaguememberid
#   legalname
#   derbyname
#   email
sub get_league_members {
    my ($dbh, $leagueid) = @_;

    $dbh->selectall_arrayref(q{
        select leaguemember.id id, legalname, derbyname, email
        from leaguemember, users
        where users.id = leaguemember.userid
          and leaguemember.leagueid = ?}, { Slice => {} }, $leagueid);
}

# get_league_members($dbh, $leagueid) -> { ... }
# Get detailed info on one league member
# returns a hash containing:
#   id => the leaguememberid
#   legalname
#   derbyname
#   email
#   leagueid
sub get_leaguemember {
    my ($dbh, $leaguememberid) = @_;

    $dbh->selectrow_hashref(q{
        select leaguemember.id id, legalname, derbyname, email, leagueid
        from leaguemember, users
        where users.id = leaguemember.userid
          and leaguemember.id = ?}, {}, $leaguememberid);
}

# add_invoiceitem($dbh, $leaguememberid, $amount, $description) -> $id
# Add an invoice item to a leaguemember's account
# Takes the leaguemember id, amount (in the stripe currency unit), and an
# optional description. The resulting item will be due tomorrow.
# Returns the invoice item id
sub add_invoiceitem {
    my ($dbh, $leaguememberid, $amount, $description) = @_;

    my $sth = $dbh->prepare(q{insert into invoiceitem (leaguememberid, amount, description, duedate) values (?, ?, ?, date 'today' + 1) returning id});
    $sth->execute($leaguememberid, $amount, $description);
    return $sth->fetch()->[0];
}

# add_payment($leaguememberid, $amount, $description) -> $id
# Add an invoice item to a leaguemember's account
# Takes the leaguemember id, amount (in the stripe currency unit), and an
# optional description.
# Returns the payment id
sub add_payment {
    my ($leaguememberid, $amount, $description) = @_;
    my $dbh = $PayDerbyDues::RequestGlobalData::dbh;

    my $sth = $dbh->prepare(q{insert into payment (leaguememberid, amount, description) values (?, ?, ?) returning id});
    $sth->execute($leaguememberid, $amount, $description);
    return $sth->fetch()->[0];
}

1;
