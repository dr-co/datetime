use utf8;
use strict;
use warnings;

package DR::DateTime::Defaults;
use POSIX ();

our $TZ     = POSIX::strftime '%z', localtime;

1;

__END__

=head1 NAME

DR::DateTime::Defaults - Default variables for L<DR::DateTime>.

=head1 SYNOPSIS

    use DR::DateTime::Defaults;


    $http_server->hook(before_dispatch => sub {
        $DR::DateTime::Defaults::TZ = '+0300';
    });

=head1 DESCRIPTION

The module contains variables that uses in L<DR::DateTime> as defaults.

=head2 $TZ

Default value is C<+DDDD> (Your local timezone).

=cut
