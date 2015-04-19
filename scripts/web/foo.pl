#!/usr/bin/perl

use strict;
use warnings;

use Text::Handlebars;
use Data::Dumper;

use Utilities::DBConnect;

print "Content-type: text/html\n\n";

my $dbh = Utilities::DBConnect::GetDBH();

my $sqlquery = "select * from company";

my $sth = $dbh->prepare($sqlquery);

$sth->execute();

my $data = $sth->fetchall_arrayref; # array ref of array refs

@$data = map {;+{bar => join(', ', @$_)}} @$data;

my $handlebars = Text::Handlebars->new(
      helpers => {
		# define various helper subs here
      },
);

my $vars = {
	rows => $data,
};

my $TEMPLATE = qq!
<html>
  <table>
	{{#each rows}}
	<tr><td>foo <td>{{bar}} </tr>
	{{/each}}
  </table>
</html>
!;

print $handlebars->render_string($TEMPLATE, $vars);

