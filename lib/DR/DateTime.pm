package DR::DateTime;
use DR::DateTime::Defaults;

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.01';
use Carp;

use Data::Dumper;

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

sub epoch   { shift->[0] }
sub tz      { shift->[1] // $DR::DateTime::Defaults::TZ }

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
