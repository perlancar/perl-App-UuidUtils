package App::UuidUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{gen_uuids} = {
    v => 1.1,
    summary => 'Generate UUIDs, with several options',
    description => <<'_',

This utility is meant to generate one or several UUIDs with several options,
like algorithm

_
    args => {
        algorithm => {
            schema => ['str*', in=>[qw/random/]],
            default => 'random',
            cmdline_aliases => {a=>{}},
        },
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
        },
    },
};
sub gen_uuids {
    my %args = @_;

    my $num  = $args{num} // 1;
    my $algo = $args{algorithm} // 'random';

    my $res = [200, "OK"];
    if ($num > 1) { $res->[2] = [] }

    # currently the only available algorithm
    require UUID::Random;

    for (1..$num) {
        my $uuid = UUID::Random::generate();
        if ($num > 1) {
            push @{ $res->[2] }, $uuid;
        } else {
            $res->[2] = $uuid;
        }
    }

    $res;
}

1;
# ABSTRACT: Command-line utilities related to UUIDs

=head1 DESCRIPTION

This distribution contains command-line utilities related to UUIDs:

#INSERT_EXECS_LIST

=cut
