#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 14;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::DateTime';
    use_ok 'POSIX', 'strftime';
}

my $now = time;

for my $t (DR::DateTime->parse(strftime '%F %T+0000', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now, 'epoch';
    is $t->tz, '+0000', 'tz';
}
for my $t (DR::DateTime->parse(strftime '%F %T+0100', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now - 3600, 'epoch';
    is $t->tz, '+0100', 'tz';
}

for my $t (DR::DateTime->parse(strftime '%F %T', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now, 'epoch';
    is $t->tz, '+0000', 'tz';
}

for my $t (DR::DateTime->parse(strftime '%F %H:%M', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now - $now % 60, 'epoch';
    is $t->tz, '+0000', 'tz';
}
