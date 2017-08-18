package DR::DateTime;
use DR::DateTime::Defaults;

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.01';
use Carp;

use Data::Dumper ();
use POSIX ();
use Time::Local ();
use Time::Zone ();
use feature 'state';

sub new {
    my ($self, $stamp, $tz) = @_;
    $stamp //= time;

    if (defined $tz) {
        $tz =~ /^([+-])?(\d{2})(\d{2})?$/;
        croak "Wrong timezone format" unless defined $2;

        $tz = join '',
                $1 // '+',
                $2,
                $3 // '00';
    }

    bless [ $stamp, $tz // () ] => ref($self) || $self;
}

sub parse {
    my ($class, $str, $default_tz, $nocheck) = @_;
    return undef unless defined $str;
    my ($y, $m, $d, $H, $M, $S, $ns, $z);

    for ($str) {
        if (/^(\d{4})-(\d{2})-(\d{2})(?:\s+|T)(\d{2}):(\d{2}):(\d{2})(\.\d+)?\s*(\S+)?$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($1, $2, $3, $4, $5, $6, $7, $8 // '+0000');
            goto PARSED;
        }
        
        if (/^(\d{4})-(\d{2})-(\d{2})(?:\s+|T)(\d{2}):(\d{2})$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($1, $2, $3, $4, $5, 0, 0, '+0000');
            goto PARSED;
        }
        
        if (/^(\d{4})-(\d{2})-(\d{2})$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($1, $2, $3, 0, 0, 0, 0, '+0000');
            goto PARSED;
        }

        if (/^(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})(\.\d+)\s*(\S+)?$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($3, $2, $1, $4, $5, $6, $7, $8 // '+0000');
            goto PARSED;
        }

        return undef;
    }


    PARSED:

        $z //= $default_tz // $DR::DateTime::Defaults::TZ;
        for ($z) {
            if (/^[+-]\d{1,4}$/) {
                s/^([+-])(\d|\d{3})$/${1}0$2/;
                s/^([+-])(\d{2})$/${1}${2}00/;
            } else {
                croak "Wrong time zone format: '$z'";
            }
        }
        for ($m) {
            s/^0//;
            $_--;
        }
        for ($d, $H, $M, $S) {
            s/^0//;
        }
        $y -= 1900;

        $ns //= 0;
        my $stamp = eval {
            local $SIG{__DIE__} = sub {}; # Ick!
            return Time::Local::timegm_nocheck($S,$M,$H,$d,$m,$y) if $nocheck;
            Time::Local::timegm($S,$M,$H,$d,$m,$y);
        };
        $stamp += $ns;

        my $offset = Time::Zone::tz_offset($z, $stamp);
        $class->new($stamp - $offset, $z);
}

sub fepoch  { shift->[0] }
sub epoch   { POSIX::floor(shift->[0]) }
sub tz      { shift->[1] // $DR::DateTime::Defaults::TZ }

sub strftime :method {
    my ($self, $format) = @_;
    croak 'Invalid format' unless $format;
    my $offset = Time::Zone::tz_offset($self->tz, $self->epoch);
    my $stamp = $self->epoch + $offset;
    my $fstamp = $self->fepoch + $offset;

    state $patterns;
    unless ($patterns) {
        $patterns = {
            '%'     => sub { '%' },
            'z'     => sub { shift->tz },
            'Z'     => sub { shift->tz },
            'N'     => sub {
                int(1_000_000_000 * abs($_[2] - $_[1])) }

        };
        for my $sp (split //, 'aAbBcCdDeEFgGhHIjklmMnOpPrRsStTuUVwWxXyY') {
            $patterns->{$sp} = sub { POSIX::strftime "%$sp", gmtime $_[1] }
        }
    }

    $format =~ s{%([a-zA-Z%])}
        { $patterns->{$1} ? $patterns->{$1}->($self, $stamp, $fstamp) : "%$1" }sgex;

    $format;
}


sub year { shift->strftime('%Y') }

sub month {
    for my $m (shift->strftime('%m')) {
        $m =~ s/^0//;
        return $m;
    }
}

sub day {
    for my $d (shift->strftime('%d')) {
        $d =~ s/^0//;
        return $d;
    }
}

sub day_of_week { shift->strftime('%u') }

sub quarter { POSIX::ceil(shift->month / 3) }

sub hour {
    for my $h (shift->strftime('%H')) {
        $h =~ s/^0//;
        return $h;
    }
}

sub minute {
    for my $m (shift->strftime('%M')) {
        $m =~ s/^0//;
        return $m;
    }
}
sub second {
    for my $s (shift->strftime('%S')) {
        $s =~ s/^0//;
        return $s;
    }
}

sub nanosecond { shift->strftime('%N') }

sub hms {
    my ($self, $sep) = @_;
    $sep //= ':';
    for ($sep) {
        s/%/%%/g;
    }
    $self->strftime("%H$sep%M$sep%S");
}

sub datetime {
    my ($self) = @_;
    return join 'T', $self->ymd, $self->hms;
}

sub ymd {
    my ($self, $sep) = @_;
    $sep //= ':';
    for ($sep) {
        s/%/%%/g;
    }
    $self->strftime("%Y$sep%m$sep%d");
}

sub time_zone { goto \&tz   }
sub hires_epoch { goto \&fepoch }
sub _fix_date_after_arith_month {
    my ($self, $new) = @_;
    return $new->fepoch if $self->day == $new->day;
    if ($new->day < $self->day) {
        $new->[0] -= 86400;
    }
    $new->fepoch;
}
sub add {
    my ($self, %set) = @_;
    
    for my $n (delete $set{nanosecond}) {
        last unless defined $n;
        $self->[0] += $n / 1_000_000_000;
    }

    for my $s (delete $set{second}) {
        last unless defined $s;
        $self->[0] += $s;
    }

    for my $m (delete $set{minute}) {
        last unless defined $m;
        $self->[0] += $m * 60;
    }
    
    for my $h (delete $set{hour}) {
        last unless defined $h;
        $self->[0] += $h * 3600;
    }

    for my $d (delete $set{day}) {
        last unless defined $d;
        $self->[0] += $d * 86400;
    }

    for my $m (delete $set{month}) {
        last unless defined $m;
        my $nm = $self->month + $m;

        $set{year} //= 0;
        while ($nm > 12) {
            $nm -= 12;
            $set{year}++;
        }

        while ($nm < 1) {
            $nm += 12;
            $set{year}--;
        }
        my $str = $self->strftime('%F %T.%N %z');
        $str =~ s/(\d{4})-\d{2}-/sprintf "%s-%02d-", $1, $nm/e;
        $self->[0] =
            $self->_fix_date_after_arith_month($self->parse($str, undef, 1));
    }

    for my $y (delete $set{year}) {
        last unless defined $y;
        $y += $self->year;
        my $str = $self->strftime('%F %T.%N %z');
        $str =~ s/^\d{4}/$y/;
        $self->[0] =
            $self->_fix_date_after_arith_month($self->parse($str, undef, 1));
    }
    $self;
}

sub subtract {
    my ($self, %set) = @_;

    my %sub;
    while (my ($k, $v) = each %set) {
        $sub{$k} = -$v;
    }
    $self->add(%sub);
}

sub truncate {
    my ($self, %opts) = @_;

    my $to = $opts{to} // 'second';

    my $str;
    if ($to eq 'second') {
        $str = $self->strftime('%F %H:%M:%S%z');
        goto PARSE;
        return;
    }

    if ($to eq 'minute') {
        $str = $self->strftime('%F %H:%M:00%z');
        goto PARSE;
    }

    if ($to eq 'hour') {
        $str = $self->strftime('%F %H:00:00%z');
        goto PARSE;
    }
    
    if ($to eq 'day') {
        $str = $self->strftime('%F 00:00:00%z');
        goto PARSE;
    }

    if ($to eq 'month') {
        $str = $self->strftime('%Y-%m-01 00:00:00%z');
        goto PARSE;
    }
    
    if ($to eq 'year') {
        $str = $self->strftime('%Y-01-01 00:00:00%z');
        goto PARSE;
    }

    croak "Can not truncate the datetime to '$to'";

    PARSE:
        $self->[0] = $self->parse($str)->epoch;
        $self;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

DR::DateTime - Perl extension for blah blah blah

=head1 SYNOPSIS

  use DR::DateTime;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for DR::DateTime, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
