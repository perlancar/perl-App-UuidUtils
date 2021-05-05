package App::UuidUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{gen_uuid} = {
    v => 1.1,
    summary => 'Generate UUID, with several options',
    description => <<'_',

This utility is meant to generate one or several UUIDs with several options,
like "version", backend, etc.

_
    args => {
        uuid_version => {
            schema => ['str*', in=>[qw/1 v1 4 v4 random/]],
            default => 'random',
            cmdline_aliases => {
                random => {is_flag=>1, summary=>'Shortcut for --uuid-version=random'     , code=>sub{ $_[0]{uuid_version} = 'random'}},
                R      => {is_flag=>1, summary=>'Shortcut for --uuid-version=random'     , code=>sub{ $_[0]{uuid_version} = 'random'}},
                v1     => {is_flag=>1, summary=>'Shortcut for --uuid-version=v1'         , code=>sub{ $_[0]{uuid_version} = 'v1'}},
                v4     => {is_flag=>1, summary=>'Shortcut for --uuid-version=v4 (random)', code=>sub{ $_[0]{uuid_version} = 'v4'}},
            },
        },
        backend => {
            summary => 'Choose a specific backend, if unspecified one will be chosen',
            schema => ['str*', in=>[qw/Data::UUID UUID::Tiny Crypt::Misc UUID::Random::Secure UUID::FFI/]],
            description => <<'_',

Note that not all backends support every version of UUID.

_
        },
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
            pos => 0,
        },
    },
};
sub gen_uuid {
    my %args = @_;

    my $num     = $args{num} // 1;
    my $version = $args{uuid_version} // 'random';
    my $backend = $args{backend};

    my $res = [200, "OK"];
    if ($num > 1) { $res->[2] = [] }

    my $code_gen;
    if ($version =~ /\A(v?1)\z/) {
      CHOOSE_BACKEND: {
            if (!$backend || $backend eq 'Data::UUID') {
                eval {
                    require Data::UUID;
                    log_trace "Picking Data::UUID as backend";
                    my $ug = Data::UUID->new;
                    $code_gen = sub {
                        lc( $ug->to_string( $ug->create ) );
                    };
                };
                log_trace "Can't load Data::UUID: $@" if $@;
                last if $code_gen;
            }
            if (!$backend || $backend eq 'UUID::Tiny') {
                eval {
                    require UUID::Tiny;
                    log_trace "Picking UUID::Tiny as backend";
                    $code_gen = sub {
                        UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V1());
                    };
                };
                log_trace "Can't load UUID::Tiny: $@" if $@;
                last if $code_gen;
            }
            if (!$backend || $backend eq 'UUID::FFI') {
                eval {
                    require UUID::FFI;
                    log_trace "Picking UUID::FFI as backend";
                    $code_gen = sub {
                        UUID::FFI->new_time->as_hex;
                    };
                };
                log_trace "Can't load UUID::FFI: $@" if $@;
                last if $code_gen;
            }
        }
        die [412, "Can't use any suitable backend to generate v1 UUID"]
            unless $code_gen;
    } elsif ($version =~ /\A(v?3)\z/) {
      CHOOSE_BACKEND: {
            if (!$backend || $backend eq 'UUID::Tiny') {
                eval {
                    require UUID::Tiny;
                    log_trace "Picking UUID::Tiny as backend";
                    $code_gen = sub {
                        UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V3());
                    };
                };
                log_trace "Can't load UUID::Tiny: $@" if $@;
                last if $code_gen;
            }
        }
        die [412, "Can't use any suitable backend to generate v3 UUID"]
            unless $code_gen;
    } elsif ($version =~ /\A(v?5)\z/) {
      CHOOSE_BACKEND: {
            if (!$backend || $backend eq 'UUID::Tiny') {
                eval {
                    require UUID::Tiny;
                    log_trace "Picking UUID::Tiny as backend";
                    $code_gen = sub {
                        UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_V5());
                    };
                };
                log_trace "Can't load UUID::Tiny: $@" if $@;
                last if $code_gen;
            }
        }
        die [412, "Can't use any suitable backend to generate v5 UUID"]
            unless $code_gen;
    } else {
        # v4, random
      CHOOSE_BACKEND: {
            if (!$backend || $backend eq 'Crypt::Misc') {
                eval {
                    require Crypt::Misc;
                    log_trace "Picking Crypt::Misc as backend";
                    $code_gen = sub {
                        Crypt::Misc::random_v4uuid();
                    };
                };
                log_trace "Can't load Crypt::Misc: $@" if $@;
                last if $code_gen;
            }
            if (!$backend || $backend eq 'UUID::Random::Secure') {
                eval {
                    require UUID::Random::Secure;
                    log_trace "Picking UUID::Random::Secure as backend";
                    $code_gen = sub {
                        UUID::Random::Secure::generate_rfc();
                    };
                };
                log_trace "Can't load UUID::Random::Secure: $@" if $@;
                last if $code_gen;
            }
            if (!$backend || $backend eq 'UUID::FFI') {
                eval {
                    require UUID::FFI;
                    log_trace "Picking UUID::FFI as backend";
                    $code_gen = sub {
                        UUID::FFI->new_random->as_hex;
                    };
                };
                log_trace "Can't load UUID::FFI: $@" if $@;
                last if $code_gen;
            }
        }
        die [412, "Can't use any suitable backend to generate v4 UUID"]
            unless $code_gen;
    }

    for (1..$num) {
        my $uuid = $code_gen->();
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
