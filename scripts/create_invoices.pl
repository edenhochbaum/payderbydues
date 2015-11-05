#!/usr/bin/env perl

use strict;
use warnings;

use PayDerbyDues::Utilities::DBConnect;

my $dbh = PayDerbyDues::Utilities::DBConnect::GetDBH();

my $sql = q{
INSERT INTO invoiceitem 
   (amount, duedate, created, description, feescheduleid, leaguememberid)
   SELECT feeschedule.amount, date_trunc(interval.unit, 
           date 'today' + interval.interval), now(),
           'Scheduled bill for ' || feeschedule.name,
           leaguemember.feescheduleid, leaguemember.id
    FROM leaguemember, feeschedule, interval
    WHERE leaguemember.feescheduleid = feeschedule.id
      AND feeschedule.amount > 0
      AND feeschedule.intervalid = interval.id
      AND NOT EXISTS (
        SELECT 1 FROM invoiceitem
        WHERE invoiceitem.leaguememberid = leaguemember.id
          AND invoiceitem.feescheduleid = feeschedule.id
          AND age(invoiceitem.duedate) < interval.interval)
};

my $rows = int $dbh->do($sql);
print "$rows rows inserted\n";

