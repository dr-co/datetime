#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);

use Test::More tests    => 39;
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
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0000', gmtime $now),
        'strftime';
}
for my $t (DR::DateTime->parse(strftime '%F %T+0100', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now - 3600, 'epoch';
    is $t->tz, '+0100', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0100', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %T -1', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed tz 1 length';
    is $t->epoch, $now + 3600, 'epoch';
    is $t->tz, '-0100', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T-0100', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %T', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed';
    is $t->epoch, $now, 'epoch';
    is $t->tz, '+0000', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0000', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %H:%M', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed GMT';
    is $t->epoch, $now - $now % 60, 'epoch';
    is $t->tz, '+0000', 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %H:%M:00+0000', gmtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%F %T %z', localtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed local tz';
    is $t->epoch, $now, 'epoch';
    is $t->tz, strftime('%z', localtime $now), 'tz';
    is $t->strftime("%F %T%z"),
        strftime('%F %T%z', localtime $now), 'strftime';
}

for my $t (DR::DateTime->parse(strftime '%FT%T.1234567 %z', localtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed float';
    is $t->epoch, $now + .1234567, 'epoch';
    is $t->tz, strftime('%z', localtime $now), 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T%z', localtime $now),
        'strftime';
    is $t->strftime('%N'),
        int(1_000_000_000 * ($now + '.1234567' - $now)),
        'nanoseconds'
}

for my $t (DR::DateTime->parse(strftime '%d.%m.%Y %T.1234567 %z', localtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed float';
    is $t->epoch, $now + .1234567, 'epoch';
    is $t->tz, strftime('%z', localtime $now), 'tz';
    is $t->strftime('%F %T%z'),
        strftime('%F %T%z', localtime $now),
        'strftime';
}

for my $t (DR::DateTime->parse(strftime '%d.%m.%Y %T.1234567', gmtime $now)) {
    isa_ok $t => DR::DateTime::, 'parsed float russian format';
    is $t->epoch, $now + .1234567, 'epoch';
    is $t->tz, '+0000', 'tz';
    
    is $t->strftime('%F %T%z'),
        strftime('%F %T+0000', gmtime $now),
        'strftime';
}


