#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 7;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
}


my $t1 = new DR::DateTime time;
my $t2 = new DR::DateTime time - 3600;

cmp_ok $t1, '>', $t2, 'overload <=>';
cmp_ok $t1, 'ge', $t2, 'overload cmp';
ok !!$t1, 'overload bool';
is int $t1, $t1->epoch, 'overload int';
is int $t2, $t2->epoch, 'overload int';
is "$t1" => $t1->strftime('%F %T%z'), 'overload ""';
